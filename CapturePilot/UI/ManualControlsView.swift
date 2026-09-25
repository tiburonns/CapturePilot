import SwiftUI

struct ManualControlsView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var camera: CameraService

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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

                controlCard(title: settings.text(.exposure), value: camera.manualExposure ? "M" : "A") {
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
                                set: { camera.setManualExposure(enabled: true, iso: Float($0), shutter: camera.shutterSeconds) }
                            ),
                            in: Double(camera.minISO)...Double(camera.maxISO)
                        )
                        .frame(width: 150)
                    }

                    controlCard(title: settings.text(.shutter), value: shutterLabel(camera.shutterSeconds)) {
                        Slider(
                            value: Binding(
                                get: { log10(max(camera.shutterSeconds, camera.minShutterSeconds)) },
                                set: { camera.setManualExposure(enabled: true, iso: camera.iso, shutter: pow(10, $0)) }
                            ),
                            in: log10(camera.minShutterSeconds)...log10(camera.maxShutterSeconds)
                        )
                        .frame(width: 150)
                    }
                }

                controlCard(
                    title: settings.text(.focus),
                    value: camera.manualFocus ? String(format: "%.2f", camera.focusPosition) : "AF"
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
                                    set: { camera.setManualFocus(enabled: true, position: Float($0)) }
                                ),
                                in: 0...1
                            )
                            .frame(width: 150)
                        }
                    }
                }

                controlCard(
                    title: settings.text(.whiteBalance),
                    value: camera.manualWhiteBalance ? "\(Int(camera.whiteBalanceTemperature))K" : "AWB"
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
                                    set: { camera.setWhiteBalance(enabled: true, temperature: Float($0)) }
                                ),
                                in: 2500...9000,
                                step: 100
                            )
                            .frame(width: 150)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func controlCard<Content: View>(title: String, value: String, @ViewBuilder content: () -> Content) -> some View {
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
        if seconds >= 1 {
            return String(format: "%.1fs", seconds)
        }
        return "1/\(max(1, Int((1 / seconds).rounded())))"
    }
}
