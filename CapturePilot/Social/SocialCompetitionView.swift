import SwiftUI

struct SocialCompetitionView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore
    @EnvironmentObject private var social: SocialCompetitionService
    @Environment(\.dismiss) private var dismiss

    @State private var friendUsername = ""
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let profile = social.profile {
                    signedIn(profile)
                } else {
                    enableSocial
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
            .alert(
                localized("Delete social profile?", "¿Eliminar perfil social?"),
                isPresented: $showingDeleteConfirmation
            ) {
                Button(localized("Cancel", "Cancelar"), role: .cancel) { }
                Button(localized("Delete", "Eliminar"), role: .destructive) {
                    Task { await social.deleteSocialProfile() }
                }
            } message: {
                Text(localized(
                    "CapturePilot will delete your synced profile, shared scores, and friend connections it can remove. Your local photo rankings remain on this device.",
                    "CapturePilot eliminará tu perfil sincronizado, scores compartidos y relaciones de amistad que pueda borrar. Tu ranking local de fotos permanecerá en este dispositivo."
                ))
            }
        }
        .preferredColorScheme(.dark)
    }

    private var enableSocial: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.system(size: 54))

            Text(localized(
                "Friends rankings use your signed-in iCloud account to create a private CapturePilot identity.",
                "El ranking de amigos usa la cuenta de iCloud iniciada en el dispositivo para crear una identidad privada de CapturePilot."
            ))
            .multilineTextAlignment(.center)

            Text(localized(
                "CapturePilot never receives your Apple Account email or password. It derives an automatic Pilot username from CloudKit's private user record identifier.",
                "CapturePilot nunca recibe el correo ni la contraseña de tu cuenta Apple. El usuario Pilot se deriva del identificador privado que CloudKit asigna a esta app."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button {
                Task { await social.enableSocial() }
            } label: {
                Label(
                    localized("Enable Friends Rankings", "Activar ranking de amigos"),
                    systemImage: "icloud.and.arrow.up"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)

            if social.isBusy {
                ProgressView()
            }

            if let error = social.errorDescription {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
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
                    "Only the Pilot username, category, score, and capture date are synced. Photos and ranking thumbnails stay on this device.",
                    "Sólo se sincronizan usuario Pilot, categoría, score y fecha de captura. Las fotos y miniaturas del ranking permanecen en este dispositivo."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section(localized("Add friend", "Agregar amigo")) {
                TextField("PILOT-XXXXXXXXXX", text: $friendUsername)
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
                    ForEach(
                        Array(social.leaderboard.prefix(50).enumerated()),
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
                            await social.syncBestScores(entries: rankingStore.entries)
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
                        "Delete social profile",
                        "Eliminar perfil social"
                    ))
                }

                Text(localized(
                    "Deleting the social profile does not delete your local photos or local Rankings database.",
                    "Eliminar el perfil social no borra tus fotos ni la base local de Ranking."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
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

        switch PhotoCategory(rawValue: raw) {
        case .portrait: return localized("Portrait", "Retrato")
        case .architecture: return localized("Architecture", "Arquitectura")
        case .automotive: return localized("Automotive", "Automotriz")
        case .macro: return "Macro"
        case .street: return localized("Street", "Calle")
        case .landscape: return localized("Landscape", "Paisaje")
        case .night: return localized("Night", "Noche")
        case .general, .none: return localized("General", "General")
        }
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
