import CloudKit
import Foundation

struct SocialProfile: Identifiable, Hashable {
    let id: String
    let username: String
}

struct SocialFriendRequest: Identifiable, Hashable {
    let id: CKRecord.ID
    let requesterID: String
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
    let ownerID: String
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
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }

    private static let socialEnabledKey = "social.enabled"
    private static let shareScoresKey = "social.shareScores"
    private static let identityRecordID = CKRecord.ID(
        recordName: "capturepilot_social_identity_v1"
    )

    init() {
        shareScores = UserDefaults.standard.bool(forKey: Self.shareScoresKey)
    }

    func restoreIfPossible() async {
        guard UserDefaults.standard.bool(forKey: Self.socialEnabledKey) else {
            return
        }
        await connect(createIdentity: true)
    }

    func enableSocial() async {
        UserDefaults.standard.set(true, forKey: Self.socialEnabledKey)
        await connect(createIdentity: true)
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
                field: "requesterID",
                value: me.id
            )
            let incoming = try await friendRequests(
                field: "addresseeID",
                value: me.id
            )

            for request in outgoing {
                _ = try? await publicDatabase.deleteRecord(
                    withID: request.recordID
                )
            }

            for request in incoming {
                let acceptanceID = acceptanceRecordID(for: request.recordID)
                _ = try? await publicDatabase.deleteRecord(
                    withID: acceptanceID
                )
            }

            let profileID = CKRecord.ID(recordName: "profile_\(me.id)")
            _ = try? await publicDatabase.deleteRecord(withID: profileID)
            _ = try? await privateDatabase.deleteRecord(
                withID: Self.identityRecordID
            )

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
                field: "requesterID",
                value: me.id
            )
            if let existing = outgoing.first(
                where: { ($0["addresseeID"] as? String) == target.id }
            ) {
                errorDescription = nil
                return
            }

            let incoming = try await friendRequests(
                field: "addresseeID",
                value: me.id
            )
            if let existing = incoming.first(
                where: { ($0["requesterID"] as? String) == target.id }
            ) {
                try await setAcceptance(
                    for: existing,
                    addresseeID: me.id,
                    active: true
                )
                errorDescription = nil
                await refresh()
                return
            }

            let request = CKRecord(recordType: "FriendRequest")
            request["requesterID"] = me.id as CKRecordValue
            request["requesterUsername"] = me.username as CKRecordValue
            request["addresseeID"] = target.id as CKRecordValue
            request["createdAt"] = Date() as CKRecordValue
            _ = try await publicDatabase.save(request)

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
            let record = try await publicDatabase.record(for: request.id)
            try await setAcceptance(
                for: record,
                addresseeID: me.id,
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
                _ = try await publicDatabase.deleteRecord(
                    withID: friend.requestRecordID
                )
            } else {
                let request = try await publicDatabase.record(
                    for: friend.requestRecordID
                )
                try await setAcceptance(
                    for: request,
                    addresseeID: me.id,
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

        let currentEntries = entries.filter {
            $0.scoreVersion == PhotoRankingEntry.currentScoreVersion
        }

        var submissions: [(String, PhotoRankingEntry)] = []

        if let bestOverall = currentEntries.max(
            by: { $0.coachScore < $1.coachScore }
        ) {
            submissions.append(("overall", bestOverall))
        }

        for category in PhotoCategory.allCases {
            if let best = currentEntries
                .filter({ $0.category == category })
                .max(by: { $0.coachScore < $1.coachScore }) {
                submissions.append((category.rawValue, best))
            }
        }

        do {
            for (category, entry) in submissions {
                let id = CKRecord.ID(
                    recordName: "score_\(me.id)_\(category)"
                )
                let record = (try? await publicDatabase.record(for: id))
                    ?? CKRecord(recordType: "RankingScore", recordID: id)

                record["ownerID"] = me.id as CKRecordValue
                record["username"] = me.username as CKRecordValue
                record["category"] = category as CKRecordValue
                record["score"] = NSNumber(value: entry.coachScore)
                record["capturedAt"] = entry.createdAt as CKRecordValue
                record["scoreVersion"] = NSNumber(value: entry.scoreVersion)
                _ = try await publicDatabase.save(record)
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

    private func connect(createIdentity: Bool) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                throw CKError(.notAuthenticated)
            }

            let identity: CKRecord

            if let existing = try? await privateDatabase.record(
                for: Self.identityRecordID
            ) {
                identity = existing
            } else {
                guard createIdentity else { return }

                let socialID = UUID()
                    .uuidString
                    .replacingOccurrences(of: "-", with: "")
                    .lowercased()
                let username = "PILOT-\(String(socialID.prefix(12)).uppercased())"

                identity = CKRecord(
                    recordType: "SocialIdentity",
                    recordID: Self.identityRecordID
                )
                identity["socialID"] = socialID as CKRecordValue
                identity["username"] = username as CKRecordValue
                identity["createdAt"] = Date() as CKRecordValue
                _ = try await privateDatabase.save(identity)
            }

            guard let socialID = identity["socialID"] as? String else {
                throw NSError(
                    domain: "CapturePilot.Social",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "The private social identity is incomplete."
                    ]
                )
            }

            let fallbackUsername =
                "PILOT-\(String(socialID.prefix(12)).uppercased())"
            let username = identity["username"] as? String ?? fallbackUsername

            let publicProfileID = CKRecord.ID(
                recordName: "profile_\(socialID)"
            )
            let publicProfile: CKRecord

            if let existing = try? await publicDatabase.record(
                for: publicProfileID
            ) {
                publicProfile = existing
            } else {
                publicProfile = CKRecord(
                    recordType: "CapturePilotProfile",
                    recordID: publicProfileID
                )
                publicProfile["socialID"] = socialID as CKRecordValue
                publicProfile["username"] = username as CKRecordValue
                publicProfile["createdAt"] = Date() as CKRecordValue
                _ = try await publicDatabase.save(publicProfile)
            }

            let finalName =
                publicProfile["username"] as? String
                ?? username

            profile = SocialProfile(
                id: socialID,
                username: finalName
            )
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

        let result = try await publicDatabase.records(
            matching: query,
            resultsLimit: 5
        )

        for (_, recordResult) in result.matchResults {
            if let record = try? recordResult.get(),
               let id = record["socialID"] as? String,
               let name = record["username"] as? String {
                return SocialProfile(id: id, username: name)
            }
        }

        return nil
    }

    private func loadFriendsAndRequests() async {
        guard let me = profile else { return }

        do {
            let outgoing = try await friendRequests(
                field: "requesterID",
                value: me.id
            )
            let incoming = try await friendRequests(
                field: "addresseeID",
                value: me.id
            )

            var nextRequests: [SocialFriendRequest] = []
            var nextFriends: [String: SocialFriend] = [:]

            for request in incoming {
                guard let requesterID = request["requesterID"] as? String else {
                    continue
                }

                let acceptance = try await acceptance(
                    for: request.recordID
                )

                if acceptance.active {
                    let name = try await profileName(forID: requesterID)
                        ?? (request["requesterUsername"] as? String)
                        ?? "PILOT"

                    nextFriends[requesterID] = SocialFriend(
                        id: requesterID,
                        username: name,
                        requestRecordID: request.recordID,
                        initiatedByMe: false
                    )
                } else if !acceptance.exists {
                    let name =
                        request["requesterUsername"] as? String
                        ?? "PILOT"

                    nextRequests.append(
                        SocialFriendRequest(
                            id: request.recordID,
                            requesterID: requesterID,
                            requesterUsername: name
                        )
                    )
                }
            }

            for request in outgoing {
                guard let addresseeID = request["addresseeID"] as? String else {
                    continue
                }

                let acceptance = try await acceptance(
                    for: request.recordID
                )

                if acceptance.active {
                    let name =
                        try await profileName(forID: addresseeID)
                        ?? "PILOT"

                    nextFriends[addresseeID] = SocialFriend(
                        id: addresseeID,
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

        let result = try await publicDatabase.records(
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

    private func acceptance(
        for requestID: CKRecord.ID
    ) async throws -> (exists: Bool, active: Bool) {
        let id = acceptanceRecordID(for: requestID)

        guard let record = try? await publicDatabase.record(for: id) else {
            return (false, false)
        }

        let active =
            (record["active"] as? NSNumber)?.boolValue
            ?? false

        return (true, active)
    }

    private func setAcceptance(
        for request: CKRecord,
        addresseeID: String,
        active: Bool
    ) async throws {
        let id = acceptanceRecordID(for: request.recordID)
        let record = (try? await publicDatabase.record(for: id))
            ?? CKRecord(recordType: "FriendAcceptance", recordID: id)

        record["requestRecordName"] =
            request.recordID.recordName as CKRecordValue
        record["requesterID"] =
            (request["requesterID"] as? String ?? "") as CKRecordValue
        record["addresseeID"] = addresseeID as CKRecordValue
        record["active"] = NSNumber(value: active)
        record["updatedAt"] = Date() as CKRecordValue

        _ = try await publicDatabase.save(record)
    }

    private func profileName(forID id: String) async throws -> String? {
        let recordID = CKRecord.ID(recordName: "profile_\(id)")

        guard let record = try? await publicDatabase.record(
            for: recordID
        ) else {
            return nil
        }

        return record["username"] as? String
    }

    private func loadLeaderboard() async {
        guard let me = profile else { return }

        let ids = [me.id] + friends.map(\.id)

        do {
            let query = CKQuery(
                recordType: "RankingScore",
                predicate: NSPredicate(format: "ownerID IN %@", ids)
            )

            let result = try await publicDatabase.records(
                matching: query,
                resultsLimit: 400
            )

            leaderboard = result.matchResults.compactMap { id, item in
                guard let record = try? item.get(),
                      let ownerID = record["ownerID"] as? String,
                      let username = record["username"] as? String,
                      let category = record["category"] as? String,
                      let number = record["score"] as? NSNumber,
                      let version = record["scoreVersion"] as? NSNumber,
                      version.intValue
                        == PhotoRankingEntry.currentScoreVersion else {
                    return nil
                }

                return SocialScore(
                    id: id.recordName,
                    ownerID: ownerID,
                    username: username,
                    category: category,
                    score: number.doubleValue,
                    capturedAt:
                        record["capturedAt"] as? Date
                        ?? .distantPast,
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

        let categories =
            ["overall"]
            + PhotoCategory.allCases.map(\.rawValue)

        for category in categories {
            let id = CKRecord.ID(
                recordName: "score_\(me.id)_\(category)"
            )
            _ = try? await publicDatabase.deleteRecord(
                withID: id
            )
        }

        leaderboard.removeAll { $0.ownerID == me.id }
    }

    private func clearLocalSocialState() {
        UserDefaults.standard.set(
            false,
            forKey: Self.socialEnabledKey
        )
        UserDefaults.standard.set(
            false,
            forKey: Self.shareScoresKey
        )
        shareScores = false
        profile = nil
        friends = []
        incomingRequests = []
        leaderboard = []
        errorDescription = nil
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
