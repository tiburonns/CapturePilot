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

            let fromMe = try await connectionRecords(
                field: "requesterHash",
                value: me.id,
                status: nil
            )
            let toMe = try await connectionRecords(
                field: "addresseeHash",
                value: me.id,
                status: nil
            )

            var ids = Set(fromMe.map(\.recordID))
            ids.formUnion(toMe.map(\.recordID))

            for id in ids {
                _ = try? await database.deleteRecord(withID: id)
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

            let pair = [me.id, target.id].sorted()
            let recordID = CKRecord.ID(
                recordName: "friend_\(pair[0])_\(pair[1])"
            )

            if let existing = try? await database.record(for: recordID) {
                let status = existing["status"] as? String ?? ""
                if status == "accepted" {
                    errorDescription = nil
                    return
                }

                let addressee = existing["addresseeHash"] as? String ?? ""
                if addressee == me.id {
                    existing["status"] = "accepted" as CKRecordValue
                    existing["acceptedAt"] = Date() as CKRecordValue
                    _ = try await database.save(existing)
                    await refresh()
                    return
                }

                errorDescription = nil
                return
            }

            let record = CKRecord(recordType: "FriendConnection", recordID: recordID)
            record["requesterHash"] = me.id as CKRecordValue
            record["requesterUsername"] = me.username as CKRecordValue
            record["addresseeHash"] = target.id as CKRecordValue
            record["addresseeUsername"] = target.username as CKRecordValue
            record["status"] = "pending" as CKRecordValue
            record["createdAt"] = Date() as CKRecordValue
            _ = try await database.save(record)
            errorDescription = nil
            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func accept(_ request: SocialFriendRequest) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let record = try await database.record(for: request.id)
            record["status"] = "accepted" as CKRecordValue
            record["acceptedAt"] = Date() as CKRecordValue
            _ = try await database.save(record)
            await refresh()
        } catch {
            errorDescription = socialError(error)
        }
    }

    func remove(_ friend: SocialFriend) async {
        guard let me = profile else { return }
        let pair = [me.id, friend.id].sorted()
        let id = CKRecord.ID(recordName: "friend_\(pair[0])_\(pair[1])")

        do {
            _ = try await database.deleteRecord(withID: id)
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

        if let bestOverall = entries.max(by: { $0.coachScore < $1.coachScore }) {
            submissions.append(("overall", bestOverall))
        }

        for category in PhotoCategory.allCases {
            if let best = entries
                .filter({ $0.category == category })
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
            let incoming = try await connectionRecords(
                field: "addresseeHash",
                value: me.id,
                status: "pending"
            )

            incomingRequests = incoming.compactMap { record in
                guard let hash = record["requesterHash"] as? String,
                      let name = record["requesterUsername"] as? String else {
                    return nil
                }
                return SocialFriendRequest(
                    id: record.recordID,
                    requesterHash: hash,
                    requesterUsername: name
                )
            }
            .sorted { $0.requesterUsername < $1.requesterUsername }

            let fromMe = try await connectionRecords(
                field: "requesterHash",
                value: me.id,
                status: "accepted"
            )
            let toMe = try await connectionRecords(
                field: "addresseeHash",
                value: me.id,
                status: "accepted"
            )

            var merged: [String: SocialFriend] = [:]

            for record in fromMe {
                if let hash = record["addresseeHash"] as? String,
                   let name = record["addresseeUsername"] as? String {
                    merged[hash] = SocialFriend(id: hash, username: name)
                }
            }

            for record in toMe {
                if let hash = record["requesterHash"] as? String,
                   let name = record["requesterUsername"] as? String {
                    merged[hash] = SocialFriend(id: hash, username: name)
                }
            }

            friends = merged.values.sorted { $0.username < $1.username }
        } catch {
            errorDescription = socialError(error)
        }
    }

    private func connectionRecords(
        field: String,
        value: String,
        status: String?
    ) async throws -> [CKRecord] {
        let predicate: NSPredicate

        if let status {
            predicate = NSPredicate(
                format: "%K == %@ AND status == %@",
                field,
                value,
                status
            )
        } else {
            predicate = NSPredicate(format: "%K == %@", field, value)
        }

        let query = CKQuery(
            recordType: "FriendConnection",
            predicate: predicate
        )

        let result = try await database.records(
            matching: query,
            resultsLimit: 100
        )

        return result.matchResults.compactMap { _, item in
            try? item.get()
        }
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
