import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        return "\(version) (\(build))"
    }
}
