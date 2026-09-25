import AuthenticationServices
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

    private static let userIDKey = "social.appleUserID"
    private static let shareScoresKey = "social.shareScores"

    init() {
        shareScores = UserDefaults.standard.bool(forKey: Self.shareScoresKey)
    }

    func restoreIfPossible() async {
        guard let userID = UserDefaults.standard.string(forKey: Self.userIDKey) else {
            return
        }

        let state = await credentialState(for: userID)
        guard state == .authorized else {
            signOutLocal()
            return
        }

        await establishProfile(userID: userID)
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        UserDefaults.standard.set(credential.user, forKey: Self.userIDKey)
        await establishProfile(userID: credential.user)
    }

    func signOutLocal() {
        UserDefaults.standard.removeObject(forKey: Self.userIDKey)
        profile = nil
        friends = []
        incomingRequests = []
        leaderboard = []
        errorDescription = nil
    }

    func sendFriendRequest(username rawUsername: String) async {
        guard let me = profile else { return }
        let username = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    _ = try await database.save(existing)
                    await refresh()
                    return
                }
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

        let bestOverall = entries.max(by: { $0.coachScore < $1.coachScore })
        var bestByCategory: [PhotoCategory: PhotoRankingEntry] = [:]
        for category in PhotoCategory.allCases {
            bestByCategory[category] = entries
                .filter { $0.category == category }
                .max(by: { $0.coachScore < $1.coachScore })
        }

        var submissions: [(String, PhotoRankingEntry)] = []
        if let bestOverall {
            submissions.append(("overall", bestOverall))
        }
        submissions.append(
            contentsOf: bestByCategory.map { category, entry in
                (category.rawValue, entry)
            }
        )

        do {
            for (category, entry) in submissions {
                let id = CKRecord.ID(
                    recordName: "score_\(me.id)_\(category)"
                )

                let record = (try? await database.record(for: id))
                    ?? CKRecord(recordType: "RankingScore", recordID: id)

                record["ownerHash"] = me.id as CKRecordValue
                record["username"] = me.username as CKRecordValue
                record["category"] = category as CKRecordValue
                record["score"] = entry.coachScore as CKRecordValue
                record["capturedAt"] = entry.createdAt as CKRecordValue
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

    private func establishProfile(userID: String) async {
        isBusy = true
        defer { isBusy = false }

        let hash = stableHash(userID)
        let username = "Pilot-\(String(hash.prefix(10)).uppercased())"
        let recordID = CKRecord.ID(recordName: "profile_\(hash)")

        do {
            let record: CKRecord
            if let existing = try? await database.record(for: recordID) {
                record = existing
            } else {
                record = CKRecord(recordType: "CapturePilotProfile", recordID: recordID)
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
            profile = SocialProfile(id: hash, username: username)
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
            let incomingQuery = CKQuery(
                recordType: "FriendConnection",
                predicate: NSPredicate(
                    format: "addresseeHash == %@ AND status == %@",
                    me.id,
                    "pending"
                )
            )

            let incomingResult = try await database.records(
                matching: incomingQuery,
                resultsLimit: 100
            )

            incomingRequests = incomingResult.matchResults.compactMap { id, result in
                guard let record = try? result.get(),
                      let hash = record["requesterHash"] as? String,
                      let name = record["requesterUsername"] as? String else {
                    return nil
                }
                return SocialFriendRequest(
                    id: id,
                    requesterHash: hash,
                    requesterUsername: name
                )
            }
            .sorted { $0.requesterUsername < $1.requesterUsername }

            let fromMe = try await acceptedConnections(
                field: "requesterHash",
                value: me.id
            )
            let toMe = try await acceptedConnections(
                field: "addresseeHash",
                value: me.id
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

    private func acceptedConnections(
        field: String,
        value: String
    ) async throws -> [CKRecord] {
        let query = CKQuery(
            recordType: "FriendConnection",
            predicate: NSPredicate(
                format: "%K == %@ AND status == %@",
                field,
                value,
                "accepted"
            )
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
        guard !hashes.isEmpty else {
            leaderboard = []
            return
        }

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
                      let number = record["score"] as? NSNumber else {
                    return nil
                }

                return SocialScore(
                    id: id.recordName,
                    ownerHash: ownerHash,
                    username: username,
                    category: category,
                    score: number.doubleValue,
                    capturedAt: record["capturedAt"] as? Date ?? .distantPast
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

        await loadLeaderboard()
    }

    private func credentialState(
        for userID: String
    ) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(
                forUserID: userID
            ) { state, _ in
                continuation.resume(returning: state)
            }
        }
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
                return "iCloud is not available for social rankings."
            case .permissionFailure:
                return "CloudKit permissions are not configured for this build."
            default:
                return cloudError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
