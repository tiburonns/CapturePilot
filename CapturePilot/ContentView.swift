import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
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
                cameraSurface
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            camera.setCoachIntensity(settings.coachIntensity)
            camera.setCoachScene(settings.sceneCoach)
            camera.resumeIfPossible()
        }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                camera.resumeIfPossible()
            case .inactive, .background:
                camera.stop()
            @unknown default:
                break
            }
        }
        .onChange(of: settings.coachIntensity) { _, value in
            camera.setCoachIntensity(value)
        }
        .onChange(of: settings.sceneCoach) { _, value in
            camera.setCoachScene(value)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                saveStatusOverlay
                sessionStatusOverlay
            }
        }
    }

    private var cameraSurface: some View {
        ZStack {
            CameraPreview(session: camera.session) { point in
                camera.focus(at: point)
            }
            .ignoresSafeArea()

            CompositionOverlay(
                grid: settings.grid,
                horizonAngle: camera.coachState.horizonAngleDegrees,
                saliencyCenter: camera.coachState.saliencyCenter,
                showSubjectMarker:
                    settings.coachIntensity == .teaching && camera.coachState.hasSubject,
                leadingLines: camera.coachState.leadingLines,
                vanishingPoint: camera.coachState.vanishingPoint,
                showAnalysisGeometry: settings.coachIntensity == .teaching
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                topChrome

                Spacer(minLength: 12)

                CoachBubble(state: camera.coachState)
                    .padding(.horizontal, 12)

                if settings.coachIntensity != .subtle {
                    technicalReadout
                }

                if showingProControls {
                    ManualControlsView(camera: camera)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                bottomControls
            }
            .safeAreaPadding(.top, 6)
            .safeAreaPadding(.bottom, 6)
        }
    }

    private var topChrome: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.snappy) {
                        showingProControls.toggle()
                    }
                } label: {
                    Image(systemName: showingProControls ? "slider.horizontal.3" : "dial.medium")
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(settings.text(.pro))

                Spacer(minLength: 8)

                sceneMenu
                languageMenu

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(settings.text(.settings))
            }

            if !camera.availableLenses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(camera.availableLenses) { lens in
                            Button(lens.title) {
                                camera.selectLens(lens)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(camera.selectedLensID == lens.id ? .black : .white)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(
                                camera.selectedLensID == lens.id
                                    ? .white
                                    : .black.opacity(0.38),
                                in: Capsule()
                            )
                        }
                    }
                    .padding(4)
                }
                .fixedSize(horizontal: false, vertical: true)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 14)
    }

    private var sceneMenu: some View {
        Menu {
            ForEach(AppSettings.SceneCoach.allCases) { scene in
                Button {
                    settings.sceneCoach = scene
                } label: {
                    if settings.sceneCoach == scene {
                        Label(settings.sceneName(scene), systemImage: "checkmark")
                    } else {
                        Text(settings.sceneName(scene))
                    }
                }
            }
        } label: {
            Image(systemName: "viewfinder")
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(settings.text(.scene))
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppSettings.Language.allCases) { language in
                Button {
                    settings.language = language
                } label: {
                    if settings.language == language {
                        Label(settings.languageName(language), systemImage: "checkmark")
                    } else {
                        Text(settings.languageName(language))
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "globe")
                Text(settings.languageBadge)
                    .font(.caption2.weight(.bold))
                    .monospaced()
            }
            .frame(minWidth: 54, minHeight: 42)
            .padding(.horizontal, 3)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel(settings.text(.language))
    }

    private var technicalReadout: some View {
        HStack(spacing: 8) {
            metric(
                icon: "angle",
                value: String(format: "%+.1f°", camera.coachState.horizonAngleDegrees)
            )
            metric(
                icon: "sun.max.fill",
                value: String(format: "%.0f%%", camera.coachState.averageLuma * 100)
            )

            if settings.coachIntensity == .teaching {
                metric(
                    icon: "rectangle.split.2x1",
                    value: String(format: "SYM %.0f", camera.coachState.symmetryScore * 100)
                )
                metric(
                    icon: "line.diagonal",
                    value: String(format: "LINE %.0f", camera.coachState.leadingLinesScore * 100)
                )
            }

            if camera.coachState.highlightClipRatio > 0.02 {
                metric(
                    icon: "exclamationmark.triangle.fill",
                    value: String(
                        format: "HL %.0f%%",
                        camera.coachState.highlightClipRatio * 100
                    )
                )
            }
        }
        .padding(.horizontal, 10)
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
                    .frame(width: 62, height: 42)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer(minLength: 12)

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
            .disabled(!camera.isConfigured || camera.sessionInterrupted)
            .accessibilityLabel(settings.text(.capture))

            Spacer(minLength: 12)

            Button {
                cycleGrid()
            } label: {
                Image(systemName: "grid")
                    .frame(width: 58, height: 42)
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
                .safeAreaPadding(.top, 8)
                .transition(.opacity)
                .task(id: saved) {
                    try? await Task.sleep(for: .seconds(1.5))
                    camera.lastSaveSucceeded = nil
                }
        }
    }

    @ViewBuilder
    private var sessionStatusOverlay: some View {
        if camera.sessionInterrupted {
            statusCapsule(settings.text(.cameraInterrupted))
        } else if camera.runtimeErrorDescription != nil {
            statusCapsule(settings.text(.cameraRuntimeError))
        }
    }

    private func statusCapsule(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.horizontal, 20)
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
        case .goldenRatio: settings.grid = .goldenSpiral
        case .goldenSpiral: settings.grid = .goldenTriangle
        case .goldenTriangle: settings.grid = .crosshair
        case .crosshair: settings.grid = .none
        }
    }
}
