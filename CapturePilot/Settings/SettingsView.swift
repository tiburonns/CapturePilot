import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var lutLibrary: LUTLibraryStore
    @State private var showingLUTImporter = false
    @State private var showingLUTFolderPicker = false
    @State private var lutImportError: String?
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

                Section {
                    Toggle(settings.text(.rawShare), isOn: $settings.rawShareEnabled)

                    Picker(
                        settings.text(.shareJPEGResolution),
                        selection: $settings.shareJPEGResolution
                    ) {
                        ForEach(AppSettings.ShareJPEGResolution.allCases) { resolution in
                            Text(resolution.label).tag(resolution)
                        }
                    }
                    .disabled(!settings.rawShareEnabled)

                    Toggle(settings.text(.lut), isOn: $settings.lutEnabled)
                        .disabled(
                            !settings.rawShareEnabled
                            || (
                                settings.selectedLUTURL == nil
                                && lutLibrary.activeLUTURL == nil
                            )
                        )

                    if let name = lutLibrary.activeDisplayName ?? settings.lutDisplayName {
                        LabeledContent(settings.text(.lut), value: name)

                        HStack {
                            Text(settings.text(.lutIntensity))
                            Spacer()
                            Text("\(Int((settings.lutIntensity * 100).rounded()))%")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: $settings.lutIntensity,
                            in: 0...1,
                            step: 0.05
                        )
                        .disabled(!settings.rawShareEnabled || !settings.lutEnabled)

                        if lutLibrary.activeLUTURL == nil {
                            Button(role: .destructive) {
                                settings.removeLUT()
                            } label: {
                                Label(settings.text(.removeLUT), systemImage: "trash")
                            }
                        }
                    } else {
                        Text(settings.text(.noLUT))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showingLUTImporter = true
                    } label: {
                        Label(settings.text(.importLUT), systemImage: "square.and.arrow.down")
                    }

                    Text(settings.text(.rawShareDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(settings.text(.rawShare))
                }

                Section {
                    Toggle(
                        settings.text(.lutCoachRecommendations),
                        isOn: $settings.lutCoachRecommendations
                    )
                    .disabled(lutLibrary.entries.isEmpty)

                    if let folder = lutLibrary.folderDisplayName {
                        LabeledContent(settings.text(.lutLibrary), value: folder)

                        LabeledContent(
                            settings.text(.lutCount),
                            value: "\(lutLibrary.entries.count)"
                        )

                        if lutLibrary.invalidFileCount > 0 {
                            LabeledContent(
                                settings.text(.invalidLUTCount),
                                value: "\(lutLibrary.invalidFileCount)"
                            )
                        }

                        Picker(
                            settings.text(.activeLUT),
                            selection: Binding<String?>(
                                get: { lutLibrary.activeEntryID },
                                set: { newID in
                                    do {
                                        if let newID,
                                           let entry = lutLibrary.entry(withID: newID) {
                                            try lutLibrary.activate(entry)
                                            settings.lutEnabled = true
                                        } else {
                                            lutLibrary.clearActiveLUT()
                                        }
                                    } catch {
                                        lutImportError = error.localizedDescription
                                    }
                                }
                            )
                        ) {
                            Text(settings.text(.noLUT)).tag(Optional<String>.none)

                            ForEach(lutLibrary.entries) { entry in
                                Text(entry.displayName)
                                    .tag(Optional(entry.id))
                            }
                        }

                        HStack {
                            Button(settings.text(.changeLUTFolder)) {
                                showingLUTFolderPicker = true
                            }

                            Spacer()

                            Button(settings.text(.rescanLUTs)) {
                                lutLibrary.refresh()
                            }
                        }

                        Button(role: .destructive) {
                            lutLibrary.clearFolder()
                        } label: {
                            Label(
                                settings.text(.removeLUTFolder),
                                systemImage: "folder.badge.minus"
                            )
                        }
                    } else {
                        Button {
                            showingLUTFolderPicker = true
                        } label: {
                            Label(
                                settings.text(.chooseLUTFolder),
                                systemImage: "folder.badge.plus"
                            )
                        }
                    }

                    if let scanError = lutLibrary.scanErrorDescription {
                        Text(scanError)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text(settings.text(.lutFolderDetail))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(settings.text(.lutLibrary))
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
        .fileImporter(
            isPresented: $showingLUTImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                try settings.importLUT(from: url)
                lutLibrary.clearActiveLUT()
            } catch {
                lutImportError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showingLUTFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                try lutLibrary.setFolder(url)
            } catch {
                lutImportError = error.localizedDescription
            }
        }
        .alert(
            settings.text(.lut),
            isPresented: Binding(
                get: { lutImportError != nil },
                set: { if !$0 { lutImportError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { lutImportError = nil }
        } message: {
            Text(lutImportError ?? "")
        }
    }

    private var versionAndBuild: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.7.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "7"
        return "\(version) (\(build))"
    }
}
