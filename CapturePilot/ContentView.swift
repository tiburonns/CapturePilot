import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hud: HUDLayoutStore
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
            camera.start()
            OrientationPolicy.applyCurrentPolicy()
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: settings.coachIntensity) { _, newValue in
            camera.setCoachIntensity(newValue)
        }
        .onChange(of: hud.isEditing) { _, editing in
            if editing {
                showingProControls = false
                camera.setFocusPeakingEnabled(false)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(hud)
        }
        .overlay(alignment: .top) {
            saveStatusOverlay
        }
    }

    private var cameraSurface: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let safeRect = safeHUDRect(for: geometry)

            ZStack {
                CameraPreview(session: camera.session) { point in
                    guard !hud.isEditing else { return }
                    camera.focus(at: point)
                }
                .ignoresSafeArea()

                FocusPeakingOverlay(
                    image: camera.focusPeakingImage,
                    isEnabled: camera.isFocusPeakingEnabled
                )
                .ignoresSafeArea()

                CompositionOverlay(
                    grid: settings.grid,
                    horizonAngle: camera.coachState.horizonAngleDegrees,
                    saliencyCenter: camera.coachState.saliencyCenter,
                    showSubjectMarker: settings.coachIntensity == .teaching && camera.coachState.hasSubject
                )
                .ignoresSafeArea()

                ForEach(HUDItem.allCases) { item in
                    if shouldRender(item) {
                        HUDMovableItem(
                            store: hud,
                            item: item,
                            safeRect: safeRect,
                            isLandscape: isLandscape
                        ) {
                            hudElement(item)
                        }
                    }
                }

                if showingProControls && !hud.isEditing {
                    VStack {
                        Spacer()
                        ManualControlsView(camera: camera)
                            .padding(.bottom, max(82, geometry.safeAreaInsets.bottom + 72))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(50)
                }

                if hud.isEditing {
                    VStack {
                        Spacer()
                        HUDCustomizationToolbar(store: hud)
                            .padding(.horizontal, 12)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    }
                    .zIndex(500)
                }
            }
        }
    }

    @ViewBuilder
    private func hudElement(_ item: HUDItem) -> some View {
        switch item {
        case .pro:
            Button {
                withAnimation(.snappy) {
                    showingProControls.toggle()
                }
            } label: {
                Image(systemName: showingProControls ? "slider.horizontal.3" : "dial.medium")
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.pro))

        case .language:
            languageMenu

        case .settings:
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.settings))

        case .lenses:
            lensSelector

        case .coach:
            CoachBubble(state: camera.coachState)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)

        case .metrics:
            technicalReadout

        case .photoFormat:
            formatMenu

        case .shutter:
            shutterButton

        case .grid:
            Button {
                cycleGrid()
            } label: {
                Image(systemName: "grid")
                    .frame(width: 58, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel(settings.text(.grid))

        case .focusPeaking:
            Button {
                camera.toggleFocusPeaking()
            } label: {
                Image(systemName: camera.isFocusPeakingEnabled ? "viewfinder.circle.fill" : "viewfinder.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(camera.isFocusPeakingEnabled ? .orange : .white)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.focusPeaking))
        }
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
            .frame(minWidth: 56, minHeight: 44)
            .padding(.horizontal, 3)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel(settings.text(.language))
    }

    private var lensSelector: some View {
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
                        camera.selectedLensID == lens.id ? .white : .black.opacity(0.38),
                        in: Capsule()
                    )
                }
            }
            .padding(4)
        }
        .frame(maxWidth: 260)
        .fixedSize(horizontal: true, vertical: true)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var technicalReadout: some View {
        HStack(spacing: 8) {
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

    private var formatMenu: some View {
        Menu {
            ForEach(camera.availablePhotoFormats) { format in
                Button(format.shortLabel) {
                    camera.photoFormat = format
                }
            }
        } label: {
            Text(camera.photoFormat.shortLabel)
                .font(.caption.weight(.bold))
                .frame(width: 60, height: 44)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var shutterButton: some View {
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
    }

    private func shouldRender(_ item: HUDItem) -> Bool {
        if hud.isEditing { return true }
        if !hud.isVisible(item) { return false }

        switch item {
        case .metrics:
            return settings.coachIntensity != .subtle
        case .lenses:
            return !camera.availableLenses.isEmpty
        default:
            return true
        }
    }

    private func safeHUDRect(for geometry: GeometryProxy) -> CGRect {
        let margin: CGFloat = 10
        let insets = geometry.safeAreaInsets

        return CGRect(
            x: insets.leading + margin,
            y: insets.top + margin,
            width: max(1, geometry.size.width - insets.leading - insets.trailing - margin * 2),
            height: max(1, geometry.size.height - insets.top - insets.bottom - margin * 2)
        )
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
