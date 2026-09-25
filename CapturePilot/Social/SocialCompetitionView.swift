import AuthenticationServices
import SwiftUI

struct SocialCompetitionView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore
    @EnvironmentObject private var social: SocialCompetitionService
    @Environment(\.dismiss) private var dismiss

    @State private var friendUsername = ""

    var body: some View {
        NavigationStack {
            Group {
                if let profile = social.profile {
                    signedIn(profile)
                } else {
                    signIn
                }
            }
            .navigationTitle(localized("Friends", "Amigos"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localized("Done", "Listo")) { dismiss() }
                }
            }
            .task {
                await social.restoreIfPossible()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var signIn: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.system(size: 54))
            Text(localized(
                "Sign in to create your private CapturePilot identity.",
                "Inicia sesión para crear tu identidad privada de CapturePilot."
            ))
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                guard case .success(let authorization) = result,
                      let credential = authorization.credential
                        as? ASAuthorizationAppleIDCredential else {
                    return
                }

                Task {
                    await social.handleAppleCredential(credential)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 48)
            .padding(.horizontal, 28)

            Text(localized(
                "CapturePilot receives a private Apple user identifier, not your Apple ID password. Your automatic username is derived from that identifier.",
                "CapturePilot recibe un identificador privado de usuario de Apple, no tu contraseña de Apple ID. El nombre automático se deriva de ese identificador."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func signedIn(_ profile: SocialProfile) -> some View {
        List {
            Section(localized("Profile", "Perfil")) {
                LabeledContent(
                    localized("Username", "Usuario"),
                    value: profile.username
                )

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
                    "Only username, category, score, and capture date are synced. Photos remain private on this version.",
                    "Sólo se sincronizan usuario, categoría, score y fecha de captura. Las fotos permanecen privadas en esta versión."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section(localized("Add friend", "Agregar amigo")) {
                TextField("Pilot-XXXXXXXXXX", text: $friendUsername)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button {
                    Task {
                        await social.sendFriendRequest(username: friendUsername)
                        friendUsername = ""
                    }
                } label: {
                    Label(
                        localized("Send request", "Enviar solicitud"),
                        systemImage: "person.badge.plus"
                    )
                }
                .disabled(friendUsername.trimmingCharacters(in: .whitespaces).isEmpty)
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
                if social.leaderboard.isEmpty {
                    Text(localized(
                        "No shared scores yet.",
                        "Aún no hay scores compartidos."
                    ))
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(social.leaderboard.prefix(50).enumerated()), id: \.element.id) { index, item in
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
                            await social.syncBestScores(entries: rankingStore.entries)
                        }
                        await social.refresh()
                    }
                }

                Button(role: .destructive) {
                    social.signOutLocal()
                } label: {
                    Text(localized("Sign out on this device", "Cerrar sesión en este dispositivo"))
                }
            }

            Section {
                Text(localized(
                    "Social rankings are friendly competition, not anti-cheat certified. CapturePilot does not upload friend photos in 0.8.",
                    "El ranking social es competencia amistosa, no un sistema anti-cheat certificado. CapturePilot no sube fotos de amigos en 0.8."
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

    private func categoryName(_ raw: String) -> String {
        if raw == "overall" {
            return localized("Overall", "General")
        }
        return raw.capitalized
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        switch settings.language {
        case .english: english
        case .spanish: spanish
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
                ? spanish
                : english
        }
    }
}
