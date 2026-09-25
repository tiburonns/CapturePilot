import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hud: HUDLayoutStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(settings.text(.language)) {
                    Picker(settings.text(.language), selection: $settings.language) {
                        Text(settings.text(.system)).tag(AppSettings.Language.system)
                        Text(settings.text(.english)).tag(AppSettings.Language.english)
                        Text(settings.text(.spanish)).tag(AppSettings.Language.spanish)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle(settings.text(.landscape), isOn: $settings.allowLandscape)
                    Toggle(settings.text(.upsideDown), isOn: $settings.allowUpsideDown)

                    Text(settings.text(.orientationDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(settings.text(.orientation))
                }

                Section {
                    Button {
                        hud.isEditing = true
                        dismiss()
                    } label: {
                        Label(settings.text(.customizeHUD), systemImage: "rectangle.3.group")
                    }

                    Text(settings.text(.hudDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(settings.text(.hud))
                }

                Section(settings.text(.grid)) {
                    Picker(settings.text(.grid), selection: $settings.grid) {
                        Text(settings.text(.off)).tag(AppSettings.Grid.none)
                        Text("⅓").tag(AppSettings.Grid.thirds)
                        Text("φ").tag(AppSettings.Grid.goldenRatio)
                        Text(settings.text(.goldenSpiral)).tag(AppSettings.Grid.goldenSpiral)
                        Text(settings.text(.goldenTriangle)).tag(AppSettings.Grid.goldenTriangle)
                        Text("+").tag(AppSettings.Grid.crosshair)
                    }
                }

                Section(settings.text(.coach)) {
                    Picker(settings.text(.coach), selection: $settings.coachIntensity) {
                        Text(settings.text(.subtle)).tag(AppSettings.CoachIntensity.subtle)
                        Text(settings.text(.balanced)).tag(AppSettings.CoachIntensity.balanced)
                        Text(settings.text(.teaching)).tag(AppSettings.CoachIntensity.teaching)
                    }

                    Picker(settings.text(.scene), selection: $settings.sceneCoach) {
                        ForEach(AppSettings.SceneCoach.allCases) { scene in
                            Text(settings.sceneName(scene)).tag(scene)
                        }
                    }
                }

                Section {
                    HStack {
                        Text(settings.text(.zebraLevel))
                        Spacer()
                        Text("\(Int(settings.zebraLevel.rounded()))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $settings.zebraLevel,
                        in: 75...100,
                        step: 1
                    )

                    Text(settings.text(.zebraDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(settings.text(.histogramDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(settings.text(.monitoring))
                }

                Section(settings.text(.privacy)) {
                    Text(settings.text(.privacyDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent(
                        settings.text(.version),
                        value: versionAndBuild
                    )
                }
            }
            .navigationTitle(settings.text(.settings))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.text(.done)) { dismiss() }
                }
            }
        }
    }

    private var versionAndBuild: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "4"
        return "\(version) (\(build))"
    }
}
