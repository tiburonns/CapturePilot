import SwiftUI
import UIKit

struct ManualControlsView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var camera: CameraService
    let onOpenRankings: () -> Void
    let onOpenSettings: () -> Void
    let onClose: () -> Void

    @State private var hasSavedPreset = false
    @State private var presetStatus: String?

    private let presetKey = "capturePilot.manualControls.preset"

    var body: some View {
        VStack(spacing: 8) {
            header

            if let presetStatus {
                Text(presetStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .transition(.opacity)
            }

            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if !camera.availableResolutions.isEmpty {
                    controlCard(
                        title: settings.text(.resolution),
                        value: selectedResolutionLabel
                    ) {
                        Picker("", selection: resolutionBinding) {
                            ForEach(camera.availableResolutions) { option in
                                Text(option.shortLabel).tag(option.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                if camera.supportsExposureBias {
                    controlCard(title: "EV", value: String(format: "%+.1f", camera.exposureBias)) {
                        Slider(
                            value: Binding(
                                get: { Double(camera.exposureBias) },
                                set: { camera.setExposureBias(Float($0)) }
                            ),
                            in: Double(camera.minExposureBias)...Double(camera.maxExposureBias),
                            step: 0.1
                        )
                        .frame(width: 150)
                    }
                }

                if camera.supportsManualExposure {
                    controlCard(
                        title: settings.text(.exposure),
                        value: camera.manualExposure ? "M" : "A"
                    ) {
                        Toggle("", isOn: Binding(
                            get: { camera.manualExposure },
                            set: { camera.setManualExposure(enabled: $0) }
                        ))
                        .labelsHidden()
                    }

                    if camera.manualExposure {
                        controlCard(title: settings.text(.iso), value: "\(Int(camera.iso))") {
                            Slider(
                                value: Binding(
                                    get: { Double(camera.iso) },
                                    set: {
                                        camera.setManualExposure(
                                            enabled: true,
                                            iso: Float($0),
                                            shutter: camera.shutterSeconds
                                        )
                                    }
                                ),
                                in: Double(camera.minISO)...Double(camera.maxISO)
                            )
                            .frame(width: 150)
                        }

                        controlCard(
                            title: settings.text(.shutter),
                            value: shutterLabel(camera.shutterSeconds)
                        ) {
                            Slider(
                                value: Binding(
                                    get: { log10(max(camera.shutterSeconds, camera.minShutterSeconds)) },
                                    set: {
                                        camera.setManualExposure(
                                            enabled: true,
                                            iso: camera.iso,
                                            shutter: pow(10, $0)
                                        )
                                    }
                                ),
                                in: log10(camera.minShutterSeconds)...log10(camera.maxShutterSeconds)
                            )
                            .frame(width: 150)
                        }
                    }
                }

                if camera.supportsManualFocus {
                    controlCard(
                        title: settings.text(.focus),
                        value: camera.manualFocus
                            ? String(format: "%.2f", camera.focusPosition)
                            : "AF"
                    ) {
                        VStack(spacing: 4) {
                            Toggle("", isOn: Binding(
                                get: { camera.manualFocus },
                                set: { camera.setManualFocus(enabled: $0) }
                            ))
                            .labelsHidden()

                            if camera.manualFocus {
                                Slider(
                                    value: Binding(
                                        get: { Double(camera.focusPosition) },
                                        set: {
                                            camera.setManualFocus(
                                                enabled: true,
                                                position: Float($0)
                                            )
                                        }
                                    ),
                                    in: 0...1
                                )
                                .frame(width: 150)
                            }
                        }
                    }
                }

                if camera.supportsManualWhiteBalance {
                    controlCard(
                        title: settings.text(.whiteBalance),
                        value: camera.manualWhiteBalance
                            ? "\(Int(camera.whiteBalanceTemperature))K"
                            : "AWB"
                    ) {
                        VStack(spacing: 4) {
                            Toggle("", isOn: Binding(
                                get: { camera.manualWhiteBalance },
                                set: { camera.setWhiteBalance(enabled: $0) }
                            ))
                            .labelsHidden()

                            if camera.manualWhiteBalance {
                                Slider(
                                    value: Binding(
                                        get: { Double(camera.whiteBalanceTemperature) },
                                        set: {
                                            camera.setWhiteBalance(
                                                enabled: true,
                                                temperature: Float($0)
                                            )
                                        }
                                    ),
                                    in: 2500...9000,
                                    step: 100
                                )
                                .frame(width: 150)
                            }
                        }
                    }
                }
            }
                .padding(.horizontal, 14)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .onAppear {
            hasSavedPreset = UserDefaults.standard.data(forKey: presetKey) != nil
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Text(settings.text(.proControls))
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 2)

            if hasSavedPreset {
                Button(action: applySavedPreset) {
                    Label(localized("Apply", "Aplicar"), systemImage: "arrow.uturn.backward")
                }
                .accessibilityLabel(localized("Apply saved camera settings", "Aplicar ajustes guardados"))
            }

            Button(action: savePreset) {
                Label(
                    presetStatus == nil ? localized("Save", "Guardar") : localized("Saved", "Guardado"),
                    systemImage: "bookmark.fill"
                )
            }
            .accessibilityLabel(localized("Save camera settings", "Guardar ajustes de cámara"))

            Button(action: onOpenRankings) {
                Image(systemName: "trophy")
            }
            .accessibilityLabel(settings.text(.rankings))

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(settings.text(.settings))

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(localized("Close manual controls", "Cerrar controles manuales"))
        }
        .font(.caption2.weight(.medium))
        .buttonStyle(.bordered)
        .controlSize(.small)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 10)
    }

    private func savePreset() {
        let preset = ManualCameraPreset(
            exposureBias: Double(camera.exposureBias),
            manualExposure: camera.manualExposure,
            iso: Double(camera.iso),
            shutterSeconds: camera.shutterSeconds,
            manualFocus: camera.manualFocus,
            focusPosition: Double(camera.focusPosition),
            manualWhiteBalance: camera.manualWhiteBalance,
            whiteBalanceTemperature: Double(camera.whiteBalanceTemperature),
            resolutionID: camera.selectedResolutionID
        )

        guard let data = try? JSONEncoder().encode(preset) else {
            presetStatus = localized("Could not save the preset.", "No se pudo guardar el preajuste.")
            return
        }

        UserDefaults.standard.set(data, forKey: presetKey)
        hasSavedPreset = true
        withAnimation(.easeOut(duration: 0.2)) {
            presetStatus = localized("Camera settings saved.", "Ajustes de cámara guardados.")
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func applySavedPreset() {
        guard let data = UserDefaults.standard.data(forKey: presetKey),
              let preset = try? JSONDecoder().decode(ManualCameraPreset.self, from: data) else {
            hasSavedPreset = false
            presetStatus = localized("No saved preset was found.", "No se encontró un preajuste guardado.")
            return
        }

        camera.setExposureBias(Float(preset.exposureBias))
        camera.setManualExposure(
            enabled: preset.manualExposure,
            iso: Float(preset.iso),
            shutter: preset.shutterSeconds
        )
        camera.setManualFocus(
            enabled: preset.manualFocus,
            position: Float(preset.focusPosition)
        )
        camera.setWhiteBalance(
            enabled: preset.manualWhiteBalance,
            temperature: Float(preset.whiteBalanceTemperature)
        )

        if let resolution = camera.availableResolutions.first(
            where: { $0.id == preset.resolutionID }
        ) {
            camera.selectResolution(resolution)
        }

        withAnimation(.easeOut(duration: 0.2)) {
            presetStatus = localized("Saved camera settings applied.", "Se aplicaron los ajustes guardados.")
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        let spanishSelected = settings.language == .spanish
            || (
                settings.language == .system
                && Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
            )
        return spanishSelected ? spanish : english
    }

    private var selectedResolutionLabel: String {
        camera.availableResolutions
            .first(where: { $0.id == camera.selectedResolutionID })?
            .shortLabel ?? "—"
    }

    private var resolutionBinding: Binding<String> {
        Binding(
            get: { camera.selectedResolutionID },
            set: { id in
                guard let option = camera.availableResolutions.first(where: { $0.id == id }) else {
                    return
                }
                camera.selectResolution(option)
            }
        )
    }

    private func controlCard<Content: View>(
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 10)
                Text(value)
                    .font(.caption.monospacedDigit())
            }
            content()
        }
        .padding(10)
        .frame(minHeight: 62)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func shutterLabel(_ seconds: Double) -> String {
        if seconds >= 1 { return String(format: "%.1fs", seconds) }
        return "1/\(max(1, Int((1 / seconds).rounded())))"
    }
}


private struct ManualCameraPreset: Codable {
    let exposureBias: Double
    let manualExposure: Bool
    let iso: Double
    let shutterSeconds: Double
    let manualFocus: Bool
    let focusPosition: Double
    let manualWhiteBalance: Bool
    let whiteBalanceTemperature: Double
    let resolutionID: String
}
