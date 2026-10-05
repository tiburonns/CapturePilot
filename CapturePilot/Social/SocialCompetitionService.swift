import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn
import Security
import UIKit

struct SocialProfile: Identifiable, Hashable {
    let id: String
    let username: String
    let providerIDs: [String]

    var usesApple: Bool { providerIDs.contains("apple.com") }
    var usesGoogle: Bool { providerIDs.contains("google.com") }
}

struct SocialFriendRequest: Identifiable, Hashable {
    let id: String
    let requesterID: String
    let requesterUsername: String
}

struct SocialFriend: Identifiable, Hashable {
    let id: String
    let username: String
    let relationshipID: String
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
    enum BackendState: Equatable {
        case unprepared
        case notConfigured
        case ready
    }

    private enum AppleIntent {
        case signIn
        case link
        case deleteAccount
    }

    @Published private(set) var profile: SocialProfile?
    @Published private(set) var friends: [SocialFriend] = []
    @Published private(set) var incomingRequests: [SocialFriendRequest] = []
    @Published private(set) var leaderboard: [SocialScore] = []
    @Published private(set) var isBusy = false
    @Published private(set) var errorDescription: String?
    @Published private(set) var backendState: BackendState = .unprepared

    @Published var shareScores = false {
        didSet {
            guard let uid = profile?.id else { return }
            UserDefaults.standard.set(
                shareScores,
                forKey: Self.shareScoresKey(uid: uid)
            )
        }
    }

    var isAvailable: Bool { true }
    var isSignedIn: Bool { profile != nil }
    var isBackendConfigured: Bool { backendState == .ready }
    var appleSignInCapabilityAvailable: Bool {
        Self.hasAppleSignInEntitlement
    }

    private var database: Firestore?
    private var currentAppleNonce: String?
    private var appleIntent: AppleIntent = .signIn

    func prepareIfNeeded() {
        guard backendState == .unprepared else { return }

        guard let path = Bundle.main.path(
            forResource: "GoogleService-Info",
            ofType: "plist"
        ),
        let options = FirebaseOptions(contentsOfFile: path) else {
            backendState = .notConfigured
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }

        guard FirebaseApp.app() != nil else {
            backendState = .notConfigured
            return
        }

        database = Firestore.firestore()

        if let clientID = FirebaseApp.app()?.options.clientID,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                clientID: clientID
            )
        }

        backendState = .ready
    }

    func restoreIfPossible() async {
        prepareIfNeeded()
        guard backendState == .ready else { return }

        guard let user = Auth.auth().currentUser else {
            clearSession()
            return
        }

        await loadAccount(user)
    }

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest,
        linking: Bool = false,
        deleting: Bool = false
    ) {
        do {
            let nonce = try Self.randomNonceString()
            currentAppleNonce = nonce

            if deleting {
                appleIntent = .deleteAccount
            } else if linking {
                appleIntent = .link
            } else {
                appleIntent = .signIn
            }

            request.requestedScopes = [.email]
            request.nonce = Self.sha256(nonce)
        } catch {
            errorDescription = error.localizedDescription
        }
    }

    func completeAppleAuthorization(
        _ result: Result<ASAuthorization, Error>
    ) async {
        prepareIfNeeded()
        guard backendState == .ready else { return }

        isBusy = true
        defer {
            isBusy = false
            currentAppleNonce = nil
            appleIntent = .signIn
        }

        do {
            let authorization = try result.get()
            guard let appleCredential =
                    authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentAppleNonce,
                  let tokenData = appleCredential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                throw SocialAccountError.invalidAppleCredential
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: nil
            )

            switch appleIntent {
            case .signIn:
                let authResult = try await Auth.auth().signIn(
                    with: credential
                )
                await loadAccount(authResult.user)

            case .link:
                guard let user = Auth.auth().currentUser else {
                    throw SocialAccountError.notSignedIn
                }
                let authResult = try await user.link(with: credential)
                await loadAccount(authResult.user)

            case .deleteAccount:
                guard let user = Auth.auth().currentUser else {
                    throw SocialAccountError.notSignedIn
                }

                _ = try await user.reauthenticate(with: credential)

                guard let codeData = appleCredential.authorizationCode,
                      let authorizationCode = String(
                        data: codeData,
                        encoding: .utf8
                      ) else {
                    throw SocialAccountError.missingAppleAuthorizationCode
                }

                try await Auth.auth().revokeToken(
                    withAuthorizationCode: authorizationCode
                )
                try await deleteCurrentAccountDataAndAuth(user: user)
            }

            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    func signInWithGoogle(
        linking: Bool = false,
        deleting: Bool = false
    ) async {
        prepareIfNeeded()
        guard backendState == .ready else { return }

        guard let presenter = Self.topViewController() else {
            errorDescription = SocialAccountError.noPresentationContext.localizedDescription
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            guard GIDSignIn.sharedInstance.configuration != nil else {
                throw SocialAccountError.googleNotConfigured
            }

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenter
            )

            let googleUser = try await result.user.refreshTokensIfNeeded()

            guard let idToken = googleUser.idToken?.tokenString else {
                throw SocialAccountError.invalidGoogleCredential
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: googleUser.accessToken.tokenString
            )

            if deleting {
                guard let user = Auth.auth().currentUser else {
                    throw SocialAccountError.notSignedIn
                }

                _ = try await user.reauthenticate(with: credential)
                try await deleteCurrentAccountDataAndAuth(user: user)
            } else if linking {
                guard let user = Auth.auth().currentUser else {
                    throw SocialAccountError.notSignedIn
                }

                let authResult = try await user.link(with: credential)
                await loadAccount(authResult.user)
            } else {
                let authResult = try await Auth.auth().signIn(
                    with: credential
                )
                await loadAccount(authResult.user)
            }

            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            clearSession()
        } catch {
            errorDescription = accountError(error)
        }
    }

    func sendFriendRequest(username rawUsername: String) async {
        guard let me = profile, let db = database else { return }

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
            let snapshot = try await db.collection("users")
                .whereField("usernameNormalized", isEqualTo: username)
                .limit(to: 2)
                .getDocuments()

            guard let targetDocument = snapshot.documents.first,
                  let targetUsername = targetDocument.data()["username"] as? String else {
                throw SocialAccountError.usernameNotFound
            }

            let targetID = targetDocument.documentID
            let relationshipID = Self.relationshipID(me.id, targetID)
            let reference = db.collection("friendships").document(relationshipID)
            let existing = try await reference.getDocument()

            if existing.exists {
                let data = existing.data() ?? [:]
                let status = data["status"] as? String ?? "pending"
                let requesterID = data["requesterID"] as? String ?? ""

                if status == "accepted" {
                    errorDescription = nil
                    return
                }

                if requesterID == targetID {
                    try await reference.updateData([
                        "status": "accepted",
                        "updatedAt": Date()
                    ])
                    await refresh()
                    errorDescription = nil
                    return
                }

                errorDescription = nil
                return
            }

            try await reference.setData([
                "requesterID": me.id,
                "requesterUsername": me.username,
                "addresseeID": targetID,
                "addresseeUsername": targetUsername,
                "status": "pending",
                "createdAt": Date(),
                "updatedAt": Date()
            ])

            await refresh()
            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    func accept(_ request: SocialFriendRequest) async {
        guard let db = database else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            try await db.collection("friendships")
                .document(request.id)
                .updateData([
                    "status": "accepted",
                    "updatedAt": Date()
                ])

            await refresh()
            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    func remove(_ friend: SocialFriend) async {
        guard let db = database else { return }

        do {
            try await db.collection("friendships")
                .document(friend.relationshipID)
                .delete()
            await refresh()
        } catch {
            errorDescription = accountError(error)
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
        guard shareScores,
              let me = profile,
              let db = database else {
            return
        }

        let currentEntries = entries.filter {
            $0.scoreVersion == PhotoRankingEntry.currentScoreVersion
            && $0.source == .capture
        }

        var submissions: [(String, PhotoRankingEntry)] = []

        if let best = currentEntries.max(
            by: { $0.coachScore < $1.coachScore }
        ) {
            submissions.append(("overall", best))
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
                let recordID = Self.scoreID(me.id, category)
                try await db.collection("scores")
                    .document(recordID)
                    .setData([
                        "ownerID": me.id,
                        "username": me.username,
                        "category": category,
                        "score": entry.coachScore,
                        "capturedAt": entry.createdAt,
                        "scoreVersion": entry.scoreVersion,
                        "updatedAt": Date()
                    ], merge: true)
            }

            await loadLeaderboard()
            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    func refresh() async {
        guard profile != nil else { return }
        await loadFriendsAndRequests()
        await loadLeaderboard()
    }

    private func loadAccount(_ user: User) async {
        guard let db = database else { return }

        let username = Self.username(for: user.uid)
        let providers = Array(Set(user.providerData.map(\.providerID))).sorted()

        do {
            try await db.collection("users")
                .document(user.uid)
                .setData([
                    "username": username,
                    "usernameNormalized": username.uppercased(),
                    "createdAt": user.metadata.creationDate ?? Date(),
                    "updatedAt": Date()
                ], merge: true)

            profile = SocialProfile(
                id: user.uid,
                username: username,
                providerIDs: providers
            )

            shareScores = UserDefaults.standard.bool(
                forKey: Self.shareScoresKey(uid: user.uid)
            )

            await refresh()

            if shareScores {
                // Rankings sync is triggered by the view/store when entries are available.
            }

            errorDescription = nil
        } catch {
            errorDescription = accountError(error)
        }
    }

    private func loadFriendsAndRequests() async {
        guard let me = profile, let db = database else { return }

        do {
            let outgoing = try await db.collection("friendships")
                .whereField("requesterID", isEqualTo: me.id)
                .getDocuments()

            let incoming = try await db.collection("friendships")
                .whereField("addresseeID", isEqualTo: me.id)
                .getDocuments()

            var nextFriends: [String: SocialFriend] = [:]
            var nextRequests: [SocialFriendRequest] = []

            for document in outgoing.documents {
                let data = document.data()
                guard let otherID = data["addresseeID"] as? String,
                      let otherName = data["addresseeUsername"] as? String else {
                    continue
                }

                if (data["status"] as? String) == "accepted" {
                    nextFriends[otherID] = SocialFriend(
                        id: otherID,
                        username: otherName,
                        relationshipID: document.documentID
                    )
                }
            }

            for document in incoming.documents {
                let data = document.data()
                guard let otherID = data["requesterID"] as? String,
                      let otherName = data["requesterUsername"] as? String else {
                    continue
                }

                if (data["status"] as? String) == "accepted" {
                    nextFriends[otherID] = SocialFriend(
                        id: otherID,
                        username: otherName,
                        relationshipID: document.documentID
                    )
                } else {
                    nextRequests.append(
                        SocialFriendRequest(
                            id: document.documentID,
                            requesterID: otherID,
                            requesterUsername: otherName
                        )
                    )
                }
            }

            friends = nextFriends.values.sorted {
                $0.username < $1.username
            }
            incomingRequests = nextRequests.sorted {
                $0.requesterUsername < $1.requesterUsername
            }
        } catch {
            errorDescription = accountError(error)
        }
    }

    private func loadLeaderboard() async {
        guard let me = profile, let db = database else { return }

        let ownerIDs = [me.id] + friends.map(\.id)
        var nextScores: [SocialScore] = []

        do {
            for ownerID in ownerIDs {
                let snapshot = try await db.collection("scores")
                    .whereField("ownerID", isEqualTo: ownerID)
                    .getDocuments()

                for document in snapshot.documents {
                    let data = document.data()
                    guard let username = data["username"] as? String,
                          let category = data["category"] as? String,
                          let score = data["score"] as? NSNumber else {
                        continue
                    }

                    let capturedAt: Date
                    if let timestamp = data["capturedAt"] as? Timestamp {
                        capturedAt = timestamp.dateValue()
                    } else if let date = data["capturedAt"] as? Date {
                        capturedAt = date
                    } else {
                        capturedAt = .distantPast
                    }

                    nextScores.append(
                        SocialScore(
                            id: document.documentID,
                            ownerID: ownerID,
                            username: username,
                            category: category,
                            score: score.doubleValue,
                            capturedAt: capturedAt,
                            scoreVersion:
                                (data["scoreVersion"] as? NSNumber)?.intValue
                                ?? PhotoRankingEntry.currentScoreVersion
                        )
                    )
                }
            }

            leaderboard = nextScores.sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.capturedAt > rhs.capturedAt
                }
                return lhs.score > rhs.score
            }
        } catch {
            errorDescription = accountError(error)
        }
    }

    private func removeOwnScores() async {
        guard let me = profile, let db = database else { return }

        do {
            let snapshot = try await db.collection("scores")
                .whereField("ownerID", isEqualTo: me.id)
                .getDocuments()

            let batch = db.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()

            leaderboard.removeAll { $0.ownerID == me.id }
        } catch {
            errorDescription = accountError(error)
        }
    }

    private func deleteCurrentAccountDataAndAuth(user: User) async throws {
        guard let db = database else {
            throw SocialAccountError.backendUnavailable
        }

        let outgoing = try await db.collection("friendships")
            .whereField("requesterID", isEqualTo: user.uid)
            .getDocuments()
        let incoming = try await db.collection("friendships")
            .whereField("addresseeID", isEqualTo: user.uid)
            .getDocuments()
        let scores = try await db.collection("scores")
            .whereField("ownerID", isEqualTo: user.uid)
            .getDocuments()

        let batch = db.batch()
        var deletedRelationshipIDs = Set<String>()

        for document in outgoing.documents + incoming.documents {
            if deletedRelationshipIDs.insert(document.documentID).inserted {
                batch.deleteDocument(document.reference)
            }
        }

        for document in scores.documents {
            batch.deleteDocument(document.reference)
        }

        batch.deleteDocument(
            db.collection("users").document(user.uid)
        )

        try await batch.commit()
        try await user.delete()

        GIDSignIn.sharedInstance.signOut()
        clearSession()
    }

    private func clearSession() {
        profile = nil
        friends = []
        incomingRequests = []
        leaderboard = []
        shareScores = false
    }

    private func accountError(_ error: Error) -> String {
        if let accountError = error as? SocialAccountError {
            return accountError.localizedDescription
        }

        if let authError = error as NSError?,
           authError.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: authError.code) {
            case .credentialAlreadyInUse, .emailAlreadyInUse:
                return "This provider is already linked to another CapturePilot account. Sign in with that provider first, then link the other provider from the same account."
            case .requiresRecentLogin:
                return "For security, sign in again with a linked provider before deleting the account."
            default:
                break
            }
        }

        return error.localizedDescription
    }

    private static func shareScoresKey(uid: String) -> String {
        "social.shareScores.\(uid)"
    }

    private static func username(for uid: String) -> String {
        let digest = SHA256.hash(data: Data(uid.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return "PILOT-\(String(digest.prefix(12)).uppercased())"
    }

    private static func relationshipID(_ first: String, _ second: String) -> String {
        let pair = [first, second].sorted().joined(separator: "|")
        return SHA256.hash(data: Data(pair.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func scoreID(_ uid: String, _ category: String) -> String {
        let input = "\(uid)|\(category)"
        return SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)

        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            randomBytes.count,
            &randomBytes
        )

        guard status == errSecSuccess else {
            throw SocialAccountError.nonceGenerationFailed
        }

        let charset = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )

        return String(
            randomBytes.map { charset[Int($0) % charset.count] }
        )
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static var hasAppleSignInEntitlement: Bool {
        guard let task = SecTaskCreateFromSelf(nil),
              let value = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.applesignin" as CFString,
                nil
              ) else {
            return false
        }

        if let values = value as? [String] {
            return !values.isEmpty
        }

        return false
    }

    private static func topViewController(
        from root: UIViewController? = nil
    ) -> UIViewController? {
        let base: UIViewController?

        if let root {
            base = root
        } else {
            base = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }

        if let navigation = base as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(from: presented)
        }

        return base
    }
}

private enum SocialAccountError: LocalizedError {
    case backendUnavailable
    case googleNotConfigured
    case invalidGoogleCredential
    case invalidAppleCredential
    case missingAppleAuthorizationCode
    case nonceGenerationFailed
    case noPresentationContext
    case notSignedIn
    case usernameNotFound

    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            "The CapturePilot account backend is unavailable."
        case .googleNotConfigured:
            "Google sign-in is not configured for this build."
        case .invalidGoogleCredential:
            "Google did not return a usable identity token."
        case .invalidAppleCredential:
            "Apple did not return a usable identity credential."
        case .missingAppleAuthorizationCode:
            "Apple did not return the authorization code required for account deletion."
        case .nonceGenerationFailed:
            "CapturePilot could not create a secure Apple sign-in nonce."
        case .noPresentationContext:
            "CapturePilot could not present the account sign-in screen."
        case .notSignedIn:
            "Sign in to a CapturePilot account first."
        case .usernameNotFound:
            "That CapturePilot username was not found."
        }
    }
}
