import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var camera = CameraService()
    @State private var showingSettings = false
    @State private var showingProControls = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionDenied {
                permissionView
            } else if camera.cameraUnavailable {
                unavailableView
            } else {
                CameraPreview(session: camera.session) { point in
                    camera.focus(at: point)
                }
                .ignoresSafeArea()

                CompositionOverlay(
                    grid: settings.grid,
                    horizonAngle: camera.coachState.horizonAngleDegrees,
                    saliencyCenter: camera.coachState.saliencyCenter,
                    showSubjectMarker: settings.coachIntensity == .teaching && camera.coachState.hasSubject
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    topBar
                    Spacer()

                    CoachBubble(state: camera.coachState)

                    if settings.coachIntensity != .subtle {
                        technicalReadout
                    }

                    if showingProControls {
                        ManualControlsView(camera: camera)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    bottomControls
                }
                .padding(.top, 8)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            camera.setCoachIntensity(settings.coachIntensity)
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: settings.coachIntensity) { _, newValue in
            camera.setCoachIntensity(newValue)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .overlay(alignment: .top) {
            saveStatusOverlay
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.snappy) {
                    showingProControls.toggle()
                }
            } label: {
                Image(systemName: showingProControls ? "slider.horizontal.3" : "dial.medium")
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.pro))

            Spacer()

            HStack(spacing: 6) {
                ForEach(camera.availableLenses) { lens in
                    Button(lens.title) {
                        camera.selectLens(lens)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(camera.selectedLensID == lens.id ? .black : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        camera.selectedLensID == lens.id ? .white : .black.opacity(0.35),
                        in: Capsule()
                    )
                }
            }
            .padding(4)
            .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.settings))
        }
        .padding(.horizontal, 14)
    }

    private var technicalReadout: some View {
        HStack(spacing: 10) {
            metric(icon: "angle", value: String(format: "%+.1f°", camera.coachState.horizonAngleDegrees))
            metric(icon: "sun.max.fill", value: String(format: "%.0f%%", camera.coachState.averageLuma * 100))

            if camera.coachState.highlightClipRatio > 0.02 {
                metric(
                    icon: "exclamationmark.triangle.fill",
                    value: String(format: "HL %.0f%%", camera.coachState.highlightClipRatio * 100)
                )
            }
        }
    }

    private func metric(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value).monospacedDigit()
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.black.opacity(0.46), in: Capsule())
    }

    private var bottomControls: some View {
        HStack(alignment: .center) {
            Menu {
                ForEach(camera.availablePhotoFormats) { format in
                    Button(format.shortLabel) {
                        camera.photoFormat = format
                    }
                }
            } label: {
                Text(camera.photoFormat.shortLabel)
                    .font(.caption.weight(.bold))
                    .frame(width: 58, height: 40)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(.black.opacity(0.55), lineWidth: 2)
                        .frame(width: 62, height: 62)
                }
            }
            .disabled(!camera.isConfigured)
            .accessibilityLabel(settings.text(.capture))

            Spacer()

            Button {
                cycleGrid()
            } label: {
                Image(systemName: "grid")
                    .frame(width: 58, height: 40)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel(settings.text(.grid))
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var saveStatusOverlay: some View {
        if let saved = camera.lastSaveSucceeded {
            Text(settings.text(saved ? .saved : .saveFailed))
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 54)
                .transition(.opacity)
                .task(id: saved) {
                    try? await Task.sleep(for: .seconds(1.5))
                    camera.lastSaveSucceeded = nil
                }
        }
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
            Text(settings.text(.cameraPermission))
                .multilineTextAlignment(.center)
            Button(settings.text(.openSettings)) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
        .padding(30)
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            settings.text(.noCamera),
            systemImage: "camera.fill"
        )
        .foregroundStyle(.white)
    }

    private func cycleGrid() {
        switch settings.grid {
        case .none: settings.grid = .thirds
        case .thirds: settings.grid = .goldenRatio
        case .goldenRatio: settings.grid = .crosshair
        case .crosshair: settings.grid = .none
        }
    }
}
