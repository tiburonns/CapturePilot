import CloudKit
import CryptoKit
import Foundation

struct SocialProfile: Identifiable, Hashable {
    let id: String
    let username: String
}

struct SocialFriendRequest: Identifiable, Hashable {
    let id: CKRecord.ID
    let requesterHash: String
    let requesterUsername: String
}

struct SocialFriend: Identifiable, Hashable {
    let id: String
    let username: String
    let requestRecordID: CKRecord.ID
    let initiatedByMe: Bool
}

struct SocialScore: Identifiable, Hashable {
    let id: String
    let ownerHash: String
    let username: String
    let category: String
    let score: Double
    let capturedAt: Date
    let scoreVersion: Int
}

@MainActor
final class SocialCompetitionService: ObservableObject {
    @Published private(set) var profile: SocialProfile?
    @Published private(set) var friends: [SocialFriend] = []
    @Published private(set) var incomingRequests: [SocialFriendRequest] = []
    @Published private(set) var leaderboard: [SocialScore] = []
    @Published private(set) var isBusy = false
    @Published private(set) var errorDescription: String?

    @Published var shareScores: Bool {
        didSet {
            UserDefaults.standard.set(shareScores, forKey: Self.shareScoresKey)
        }
    }

    private let container = CKContainer(identifier: "iCloud.com.tiburonns.CapturePilot")
    private var database: CKDatabase { container.publicCloudDatabase }

    private static let socialEnabledKey = "social.enabled"
    private static let shareScoresKey = "social.shareScores"

    init() {
        shareScores = UserDefaults.standard.bool(forKey: Self.shareScoresKey)
    }

    func restoreIfPossible() async {
        guard UserDefaults.standard.bool(forKey: Self.socialEnabledKey) else {
            return
        }
        await connect(createProfile: true)
    }

    func enableSocial() async {
        UserDefaults.standard.set(true, forKey: Self.socialEnabledKey)
        await connect(createProfile: true)
    }

    func deleteSocialProfile() async {
        guard let me = profile else {
            clearLocalSocialState()
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            await removeOwnScores()

            let outgoing = try await friendRequests(
                field: "requesterHash",
                value: me.id
            )
            let incoming = try await friendRequests(
                field: "addresseeHash",
                value: me.id
            )

            for request in outgoing {
                _ = try? await database.deleteRecord(withID: request.recordID)
            }

            for request in incoming {
                let acceptanceID = acceptanceRecordID(for: request.recordID)
                _ = try? await database.deleteRecord(withID: acceptanceID)
            }

            let profileID = CKRecord.ID(recordName: "profile_\(me.id)")
            _ = try? await database.deleteRecord(withID: profileID)

            clearLocalSocialState()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func sendFriendRequest(username rawUsername: String) async {
        guard let me = profile else { return }

        let username = rawUsername
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !username.isEmpty,
              username.caseInsensitiveCompare(me.username) != .orderedSame else {
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            guard let target = try await findProfile(username: username) else {
                errorDescription = "Username not found."
                return
            }

            let outgoing = try await friendRequests(
                field: "requesterHash",
                value: me.id
            )
            if let existing = outgoing.first(
                where: { ($0["addresseeHash"] as? String) == target.id }
            ) {
                if try await acceptanceIsActive(for: existing.recordID) {
                    errorDescription = nil
                    return
                }

                errorDescription = nil
                return
            }

            let incoming = try await friendRequests(
                field: "addresseeHash",
                value: me.id
            )
            if let existing = incoming.first(
                where: { ($0["requesterHash"] as? String) == target.id }
            ) {
                try await setAcceptance(
                    for: existing,
                    addresseeHash: me.id,
                    active: true
                )
                errorDescription = nil
                await refresh()
                return
            }

            let request = CKRecord(recordType: "FriendRequest")
            request["requesterHash"] = me.id as CKRecordValue
            request["requesterUsername"] = me.username as CKRecordValue
            request["addresseeHash"] = target.id as CKRecordValue
            request["createdAt"] = Date() as CKRecordValue
            _ = try await database.save(request)

            errorDescription = nil
            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func accept(_ request: SocialFriendRequest) async {
        guard let me = profile else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            let record = try await database.record(for: request.id)
            try await setAcceptance(
                for: record,
                addresseeHash: me.id,
                active: true
            )
            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func remove(_ friend: SocialFriend) async {
        guard let me = profile else { return }

        do {
            if friend.initiatedByMe {
                _ = try await database.deleteRecord(
                    withID: friend.requestRecordID
                )
            } else {
                let request = try await database.record(
                    for: friend.requestRecordID
                )
                try await setAcceptance(
                    for: request,
                    addresseeHash: me.id,
                    active: false
                )
            }

            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func setScoreSharing(
        _ enabled: Bool,
        entries: [PhotoRankingEntry]
    ) async {
        shareScores = enabled

        if enabled {
            await syncBestScores(entries: entries)
        } else {
            await removeOwnScores()
        }
    }

    func syncBestScores(entries: [PhotoRankingEntry]) async {
        guard shareScores, let me = profile else { return }

        var submissions: [(String, PhotoRankingEntry)] = []

        if let bestOverall = entries
            .filter({ $0.scoreVersion == PhotoRankingEntry.currentScoreVersion })
            .max(by: { $0.coachScore < $1.coachScore }) {
            submissions.append(("overall", bestOverall))
        }

        for category in PhotoCategory.allCases {
            if let best = entries
                .filter({
                    $0.category == category
                    && $0.scoreVersion == PhotoRankingEntry.currentScoreVersion
                })
                .max(by: { $0.coachScore < $1.coachScore }) {
                submissions.append((category.rawValue, best))
            }
        }

        do {
            for (category, entry) in submissions {
                let id = CKRecord.ID(recordName: "score_\(me.id)_\(category)")
                let record = (try? await database.record(for: id))
                    ?? CKRecord(recordType: "RankingScore", recordID: id)

                record["ownerHash"] = me.id as CKRecordValue
                record["username"] = me.username as CKRecordValue
                record["category"] = category as CKRecordValue
                record["score"] = NSNumber(value: entry.coachScore)
                record["capturedAt"] = entry.createdAt as CKRecordValue
                record["scoreVersion"] = NSNumber(value: entry.scoreVersion)
                _ = try await database.save(record)
            }

            await loadLeaderboard()
            errorDescription = nil
        } catch {
            errorDescription = socialError(error)
        }
    }

    func refresh() async {
        guard profile != nil else { return }
        await loadFriendsAndRequests()
        await loadLeaderboard()
    }

    private func connect(createProfile: Bool) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let userRecordID = try await container.userRecordID()
            let hash = stableHash(userRecordID.recordName)
            let username = "PILOT-\(String(hash.prefix(10)).uppercased())"
            let profileID = CKRecord.ID(recordName: "profile_\(hash)")

            let record: CKRecord

            if let existing = try? await database.record(for: profileID) {
                record = existing
            } else {
                guard createProfile else { return }

                record = CKRecord(
                    recordType: "CapturePilotProfile",
                    recordID: profileID
                )
                record["userHash"] = hash as CKRecordValue
                record["username"] = username as CKRecordValue
                record["createdAt"] = Date() as CKRecordValue
                _ = try await database.save(record)
            }

            let finalName = record["username"] as? String ?? username
            profile = SocialProfile(id: hash, username: finalName)
            errorDescription = nil
            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    private func findProfile(username: String) async throws -> SocialProfile? {
        let query = CKQuery(
            recordType: "CapturePilotProfile",
            predicate: NSPredicate(format: "username == %@", username)
        )

        let result = try await database.records(
            matching: query,
            resultsLimit: 5
        )

        for (_, recordResult) in result.matchResults {
            if let record = try? recordResult.get(),
               let hash = record["userHash"] as? String,
               let name = record["username"] as? String {
                return SocialProfile(id: hash, username: name)
            }
        }

        return nil
    }

    private func loadFriendsAndRequests() async {
        guard let me = profile else { return }

        do {
            let outgoing = try await friendRequests(
                field: "requesterHash",
                value: me.id
            )
            let incoming = try await friendRequests(
                field: "addresseeHash",
                value: me.id
            )

            var nextRequests: [SocialFriendRequest] = []
            var nextFriends: [String: SocialFriend] = [:]

            for request in incoming {
                guard let requesterHash = request["requesterHash"] as? String else {
                    continue
                }

                let active = try await acceptanceIsActive(for: request.recordID)

                if active {
                    let name = try await profileName(forHash: requesterHash)
                        ?? (request["requesterUsername"] as? String)
                        ?? "PILOT"
                    nextFriends[requesterHash] = SocialFriend(
                        id: requesterHash,
                        username: name,
                        requestRecordID: request.recordID,
                        initiatedByMe: false
                    )
                } else if !(try await acceptanceExists(for: request.recordID)) {
                    let name = request["requesterUsername"] as? String ?? "PILOT"
                    nextRequests.append(
                        SocialFriendRequest(
                            id: request.recordID,
                            requesterHash: requesterHash,
                            requesterUsername: name
                        )
                    )
                }
            }

            for request in outgoing {
                guard let addresseeHash = request["addresseeHash"] as? String else {
                    continue
                }

                if try await acceptanceIsActive(for: request.recordID) {
                    let name = try await profileName(forHash: addresseeHash)
                        ?? "PILOT"
                    nextFriends[addresseeHash] = SocialFriend(
                        id: addresseeHash,
                        username: name,
                        requestRecordID: request.recordID,
                        initiatedByMe: true
                    )
                }
            }

            incomingRequests = nextRequests.sorted {
                $0.requesterUsername < $1.requesterUsername
            }
            friends = nextFriends.values.sorted {
                $0.username < $1.username
            }
        } catch {
            errorDescription = socialError(error)
        }
    }

    private func friendRequests(
        field: String,
        value: String
    ) async throws -> [CKRecord] {
        let query = CKQuery(
            recordType: "FriendRequest",
            predicate: NSPredicate(format: "%K == %@", field, value)
        )

        let result = try await database.records(
            matching: query,
            resultsLimit: 100
        )

        return result.matchResults.compactMap { _, item in
            try? item.get()
        }
    }

    private func acceptanceRecordID(
        for requestID: CKRecord.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "accept_\(requestID.recordName)"
        )
    }

    private func acceptanceExists(
        for requestID: CKRecord.ID
    ) async throws -> Bool {
        let id = acceptanceRecordID(for: requestID)
        return (try? await database.record(for: id)) != nil
    }

    private func acceptanceIsActive(
        for requestID: CKRecord.ID
    ) async throws -> Bool {
        let id = acceptanceRecordID(for: requestID)

        guard let record = try? await database.record(for: id) else {
            return false
        }

        return (record["active"] as? NSNumber)?.boolValue ?? false
    }

    private func setAcceptance(
        for request: CKRecord,
        addresseeHash: String,
        active: Bool
    ) async throws {
        let id = acceptanceRecordID(for: request.recordID)
        let record = (try? await database.record(for: id))
            ?? CKRecord(recordType: "FriendAcceptance", recordID: id)

        record["requestRecordName"] = request.recordID.recordName as CKRecordValue
        record["requesterHash"] =
            (request["requesterHash"] as? String ?? "") as CKRecordValue
        record["addresseeHash"] = addresseeHash as CKRecordValue
        record["active"] = NSNumber(value: active)
        record["updatedAt"] = Date() as CKRecordValue

        _ = try await database.save(record)
    }

    private func profileName(forHash hash: String) async throws -> String? {
        let id = CKRecord.ID(recordName: "profile_\(hash)")

        guard let record = try? await database.record(for: id) else {
            return nil
        }

        return record["username"] as? String
    }

    private func loadLeaderboard() async {
        guard let me = profile else { return }

        let hashes = [me.id] + friends.map(\.id)

        do {
            let query = CKQuery(
                recordType: "RankingScore",
                predicate: NSPredicate(format: "ownerHash IN %@", hashes)
            )

            let result = try await database.records(
                matching: query,
                resultsLimit: 400
            )

            leaderboard = result.matchResults.compactMap { id, item in
                guard let record = try? item.get(),
                      let ownerHash = record["ownerHash"] as? String,
                      let username = record["username"] as? String,
                      let category = record["category"] as? String,
                      let number = record["score"] as? NSNumber,
                      let version = record["scoreVersion"] as? NSNumber,
                      version.intValue == PhotoRankingEntry.currentScoreVersion else {
                    return nil
                }

                return SocialScore(
                    id: id.recordName,
                    ownerHash: ownerHash,
                    username: username,
                    category: category,
                    score: number.doubleValue,
                    capturedAt: record["capturedAt"] as? Date ?? .distantPast,
                    scoreVersion: version.intValue
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.capturedAt > rhs.capturedAt
                }
                return lhs.score > rhs.score
            }
        } catch {
            errorDescription = socialError(error)
        }
    }

    private func removeOwnScores() async {
        guard let me = profile else { return }

        let categories = ["overall"] + PhotoCategory.allCases.map(\.rawValue)

        for category in categories {
            let id = CKRecord.ID(recordName: "score_\(me.id)_\(category)")
            _ = try? await database.deleteRecord(withID: id)
        }

        leaderboard.removeAll { $0.ownerHash == me.id }
    }

    private func clearLocalSocialState() {
        UserDefaults.standard.set(false, forKey: Self.socialEnabledKey)
        UserDefaults.standard.set(false, forKey: Self.shareScoresKey)
        shareScores = false
        profile = nil
        friends = []
        incomingRequests = []
        leaderboard = []
        errorDescription = nil
    }

    private func stableHash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func socialError(_ error: Error) -> String {
        if let cloudError = error as? CKError {
            switch cloudError.code {
            case .notAuthenticated:
                return "Sign in to iCloud on this device to use friends rankings."
            case .permissionFailure:
                return "CloudKit permissions/schema are not configured for this build."
            default:
                return cloudError.localizedDescription
            }
        }

        return error.localizedDescription
    }
}
