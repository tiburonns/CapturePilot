import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct SocialCompetitionView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore
    @EnvironmentObject private var social: SocialCompetitionService
    @Environment(\.dismiss) private var dismiss

    @State private var friendUsername = ""
    @State private var leaderboardCategory = "overall"
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteReauth = false

    private var filteredLeaderboard: [SocialScore] {
        social.leaderboard.filter { $0.category == leaderboardCategory }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch social.backendState {
                case .unprepared:
                    ProgressView()
                        .task {
                            social.prepareIfNeeded()
                            await social.restoreIfPossible()
                        }

                case .notConfigured:
                    backendNotConfigured

                case .ready:
                    if let profile = social.profile {
                        signedIn(profile)
                    } else {
                        accountSignIn
                    }
                }
            }
            .navigationTitle(localized("Account & Friends", "Cuenta y amigos"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localized("Done", "Listo")) { dismiss() }
                }
            }
            .alert(
                localized("Delete CapturePilot account?", "¿Eliminar cuenta CapturePilot?"),
                isPresented: $showingDeleteConfirmation
            ) {
                Button(localized("Cancel", "Cancelar"), role: .cancel) { }
                Button(localized("Continue", "Continuar"), role: .destructive) {
                    showingDeleteReauth = true
                }
            } message: {
                Text(localized(
                    "For security, reauthenticate with a linked provider. This deletes your social profile, friendships, and shared scores. Local photos and local Rankings stay on this device.",
                    "Por seguridad, vuelve a autenticarte con un proveedor vinculado. Esto elimina tu perfil social, amistades y scores compartidos. Tus fotos y Rankings locales permanecen en este dispositivo."
                ))
            }
            .sheet(isPresented: $showingDeleteReauth) {
                deleteAccountSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backendNotConfigured: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 52))

            Text(localized(
                "Accounts are optional and are not configured in this build.",
                "Las cuentas son opcionales y no están configuradas en esta compilación."
            ))
            .font(.headline)
            .multilineTextAlignment(.center)

            Text(localized(
                "CapturePilot still opens directly to the camera. Coach, Creative Spark, LUTs, RAW/JPEG and private Rankings work without signing in. Add GoogleService-Info.plist and the provider configuration only when you want to enable Account & Friends.",
                "CapturePilot sigue abriendo directamente en la cámara. Coach, Chispa creativa, LUTs, RAW/JPEG y Rankings privados funcionan sin iniciar sesión. Agrega GoogleService-Info.plist y la configuración de proveedores sólo cuando quieras activar Cuenta y amigos."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(28)
    }

    private var accountSignIn: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))

                Text(localized(
                    "Sign in only if you want Friends Rankings.",
                    "Inicia sesión sólo si quieres usar el Ranking con amigos."
                ))
                .font(.headline)
                .multilineTextAlignment(.center)

                Text(localized(
                    "No account is required for the camera or your private Rankings. Signing in creates a CapturePilot account that can later have both Apple and Google linked to the same account.",
                    "No necesitas cuenta para la cámara ni para tus Rankings privados. Al iniciar sesión se crea una cuenta CapturePilot que después puede vincular Apple y Google a la misma cuenta."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                SignInWithAppleButton(.continue) { request in
                    social.configureAppleRequest(request)
                } onCompletion: { result in
                    Task { await social.completeAppleAuthorization(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 48)
                .disabled(!social.appleSignInCapabilityAvailable)
                .opacity(social.appleSignInCapabilityAvailable ? 1 : 0.45)

                if !social.appleSignInCapabilityAvailable {
                    Text(localized(
                        "Apple sign-in becomes available in a signed build with the Sign in with Apple capability.",
                        "El acceso con Apple estará disponible en una build firmada con la capability Sign in with Apple."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                GoogleSignInButton {
                    Task { await social.signInWithGoogle() }
                }
                .frame(height: 48)

                if social.isBusy {
                    ProgressView()
                }

                if let error = social.errorDescription {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Text(localized(
                    "The account screen is never shown automatically at launch.",
                    "La pantalla de cuenta nunca aparece automáticamente al iniciar la app."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }

    private func signedIn(_ profile: SocialProfile) -> some View {
        List {
            Section(localized("CapturePilot account", "Cuenta CapturePilot")) {
                LabeledContent(
                    localized("Username", "Usuario"),
                    value: profile.username
                )

                providerRow(
                    title: "Apple",
                    linked: profile.usesApple,
                    systemImage: "apple.logo"
                )

                providerRow(
                    title: "Google",
                    linked: profile.usesGoogle,
                    systemImage: "g.circle.fill"
                )

                if !profile.usesApple {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localized(
                            "Link Apple to use either provider for this same account.",
                            "Vincula Apple para poder usar cualquiera de los dos proveedores con esta misma cuenta."
                        ))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        SignInWithAppleButton(.continue) { request in
                            social.configureAppleRequest(
                                request,
                                linking: true
                            )
                        } onCompletion: { result in
                            Task {
                                await social.completeAppleAuthorization(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 44)
                        .disabled(!social.appleSignInCapabilityAvailable)
                    }
                }

                if !profile.usesGoogle {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localized(
                            "Link Google to use either provider for this same account.",
                            "Vincula Google para poder usar cualquiera de los dos proveedores con esta misma cuenta."
                        ))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        GoogleSignInButton {
                            Task {
                                await social.signInWithGoogle(linking: true)
                            }
                        }
                        .frame(height: 44)
                    }
                }

                Button(localized("Sign out", "Cerrar sesión")) {
                    social.signOut()
                }
            }

            Section(localized("Score sharing", "Compartir scores")) {
                Toggle(
                    localized(
                        "Share best scores with friends",
                        "Compartir mejores scores con amigos"
                    ),
                    isOn: Binding(
                        get: { social.shareScores },
                        set: { enabled in
                            Task {
                                await social.setScoreSharing(
                                    enabled,
                                    entries: rankingStore.entries
                                )
                            }
                        }
                    )
                )

                Text(localized(
                    "Only your automatic username, category, Coach Score, score version and capture date are synchronized. Photos and thumbnails stay local.",
                    "Sólo se sincronizan usuario automático, categoría, Coach Score, versión del score y fecha. Las fotos y miniaturas permanecen locales."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section(localized("Add friend", "Agregar amigo")) {
                TextField("PILOT-XXXXXXXXXXXX", text: $friendUsername)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button {
                    Task {
                        await social.sendFriendRequest(
                            username: friendUsername
                        )
                        friendUsername = ""
                    }
                } label: {
                    Label(
                        localized("Send request", "Enviar solicitud"),
                        systemImage: "person.badge.plus"
                    )
                }
                .disabled(
                    friendUsername
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                )
            }

            if !social.incomingRequests.isEmpty {
                Section(localized("Requests", "Solicitudes")) {
                    ForEach(social.incomingRequests) { request in
                        HStack {
                            Text(request.requesterUsername)
                            Spacer()
                            Button(localized("Accept", "Aceptar")) {
                                Task { await social.accept(request) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }

            Section(localized("Friends", "Amigos")) {
                if social.friends.isEmpty {
                    Text(localized(
                        "No friends yet.",
                        "Todavía no tienes amigos."
                    ))
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(social.friends) { friend in
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(friend.username)
                            Spacer()
                            Button(role: .destructive) {
                                Task { await social.remove(friend) }
                            } label: {
                                Image(systemName: "person.badge.minus")
                            }
                        }
                    }
                }
            }

            Section(localized("Friends leaderboard", "Ranking de amigos")) {
                Picker(
                    localized("Category", "Categoría"),
                    selection: $leaderboardCategory
                ) {
                    Text(localized("Overall", "General")).tag("overall")
                    ForEach(PhotoCategory.allCases) { category in
                        Text(categoryDisplayName(category))
                            .tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)

                if filteredLeaderboard.isEmpty {
                    Text(localized(
                        "No shared scores yet.",
                        "Aún no hay scores compartidos."
                    ))
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(
                        Array(filteredLeaderboard.prefix(50).enumerated()),
                        id: \.element.id
                    ) { index, item in
                        HStack {
                            Text("#\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 32, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.username)
                                    .font(.subheadline.bold())
                                Text(categoryName(item.category))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(String(format: "%.1f", item.score))
                                .font(.headline.monospacedDigit())
                        }
                    }
                }
            }

            if let error = social.errorDescription {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button(localized("Refresh", "Actualizar")) {
                    Task {
                        if social.shareScores {
                            await social.syncBestScores(
                                entries: rankingStore.entries
                            )
                        }
                        await social.refresh()
                    }
                }
            }

            Section(localized("Privacy", "Privacidad")) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text(localized(
                        "Delete CapturePilot account",
                        "Eliminar cuenta CapturePilot"
                    ))
                }

                Text(localized(
                    "Deleting the account does not delete local photos or local Rankings.",
                    "Eliminar la cuenta no borra fotos ni Rankings locales."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section {
                Text(localized(
                    "Friends Rankings are friendly competition, not anti-cheat certified. CapturePilot does not upload friend photos.",
                    "El Ranking con amigos es competencia amistosa, no un sistema anti-cheat certificado. CapturePilot no sube fotos de amigos."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .task {
            await social.refresh()
            if social.shareScores {
                await social.syncBestScores(entries: rankingStore.entries)
            }
        }
        .onChange(of: rankingStore.entries) { _, entries in
            guard social.shareScores else { return }
            Task { await social.syncBestScores(entries: entries) }
        }
    }

    private var deleteAccountSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 52))
                    .foregroundStyle(.red)

                Text(localized(
                    "Reauthenticate to delete the account",
                    "Vuelve a autenticarte para eliminar la cuenta"
                ))
                .font(.headline)
                .multilineTextAlignment(.center)

                if social.profile?.usesApple == true {
                    SignInWithAppleButton(.continue) { request in
                        social.configureAppleRequest(
                            request,
                            deleting: true
                        )
                    } onCompletion: { result in
                        Task {
                            await social.completeAppleAuthorization(result)
                            if social.profile == nil {
                                showingDeleteReauth = false
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                }

                if social.profile?.usesGoogle == true {
                    GoogleSignInButton {
                        Task {
                            await social.signInWithGoogle(deleting: true)
                            if social.profile == nil {
                                showingDeleteReauth = false
                            }
                        }
                    }
                    .frame(height: 48)
                }

                if let error = social.errorDescription {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Button(localized("Cancel", "Cancelar"), role: .cancel) {
                    showingDeleteReauth = false
                }
            }
            .padding(24)
            .navigationTitle(localized("Delete account", "Eliminar cuenta"))
        }
        .presentationDetents([.medium])
    }

    private func providerRow(
        title: String,
        linked: Bool,
        systemImage: String
    ) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(
                linked
                    ? localized("Linked", "Vinculado")
                    : localized("Not linked", "No vinculado")
            )
            .font(.caption)
            .foregroundStyle(linked ? .green : .secondary)
        }
    }

    private func categoryDisplayName(_ category: PhotoCategory) -> String {
        switch category {
        case .general: localized("General", "General")
        case .portrait: localized("Portrait", "Retrato")
        case .architecture: localized("Architecture", "Arquitectura")
        case .automotive: localized("Automotive", "Automotriz")
        case .macro: "Macro"
        case .street: localized("Street", "Calle")
        case .landscape: localized("Landscape", "Paisaje")
        case .night: localized("Night", "Noche")
        }
    }

    private func categoryName(_ raw: String) -> String {
        if raw == "overall" {
            return localized("Overall", "General")
        }

        guard let category = PhotoCategory(rawValue: raw) else {
            return raw.capitalized
        }

        return categoryDisplayName(category)
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        switch settings.language {
        case .english: english
        case .spanish: spanish
        case .system:
            Locale.preferredLanguages.first?
                .lowercased()
                .hasPrefix("es") == true
                ? spanish
                : english
        }
    }
}
