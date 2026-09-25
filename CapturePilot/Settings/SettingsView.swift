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

                    Picker(settings.text(.frameGuide), selection: $settings.frameGuide) {
                        ForEach(AppSettings.FrameGuide.allCases) { guide in
                            Text(settings.frameGuideName(guide)).tag(guide)
                        }
                    }

                    Text(settings.text(.frameGuideDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    Toggle(settings.text(.dualZebra), isOn: $settings.dualZebra)

                    HStack {
                        Text(settings.text(.zebraLowLevel))
                        Spacer()
                        Text("\(Int(settings.zebraLowLevel.rounded()))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $settings.zebraLowLevel,
                        in: 50...95,
                        step: 1
                    )
                    .disabled(!settings.dualZebra)

                    HStack {
                        Text(settings.text(.zebraHighLevel))
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

                    Divider()

                    HStack {
                        Text(settings.text(.peakingThreshold))
                        Spacer()
                        Text("\(Int(settings.peakingThreshold.rounded()))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $settings.peakingThreshold,
                        in: 20...140,
                        step: 1
                    )

                    Picker(settings.text(.peakingColor), selection: $settings.peakingColor) {
                        ForEach(AppSettings.PeakingColor.allCases) { color in
                            Text(settings.peakingColorName(color)).tag(color)
                        }
                    }

                    Text(settings.text(.peakingDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text(settings.text(.falseColorDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(settings.text(.histogramDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(settings.text(.scopesDetail))
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.5.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "5"
        return "\(version) (\(build))"
    }
}
