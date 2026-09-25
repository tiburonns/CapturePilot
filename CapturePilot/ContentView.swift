import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hud: HUDLayoutStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var camera = CameraService()

    @State private var showingSettings = false
    @State private var showingProControls = false
    @State private var histogramExpanded = false
    @State private var waveformExpanded = false
    @State private var rgbParadeExpanded = false
    @State private var vectorscopeExpanded = false

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
            applyMonitoringSettings()
            syncMonitoringHUD()
            camera.resumeIfPossible()
            OrientationPolicy.applyCurrentPolicy()
        }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                applyMonitoringSettings()
                syncMonitoringHUD()
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
        .onChange(of: settings.zebraLevel) { _, value in
            if settings.dualZebra, settings.zebraLowLevel > value {
                settings.zebraLowLevel = value
            }
            applyMonitoringSettings()
        }
        .onChange(of: settings.zebraLowLevel) { _, value in
            if settings.dualZebra, value > settings.zebraLevel {
                settings.zebraLevel = value
            }
            applyMonitoringSettings()
        }
        .onChange(of: settings.dualZebra) { _, _ in
            applyMonitoringSettings()
        }
        .onChange(of: settings.peakingThreshold) { _, _ in
            applyMonitoringSettings()
        }
        .onChange(of: settings.peakingColor) { _, _ in
            applyMonitoringSettings()
        }
        .onChange(of: hud.configurations) { _, _ in
            syncMonitoringHUD()
        }
        .onChange(of: hud.isEditing) { _, editing in
            if editing {
                showingProControls = false
                histogramExpanded = false
                waveformExpanded = false
                rgbParadeExpanded = false
                vectorscopeExpanded = false
                camera.setFocusPeakingEnabled(false)
                camera.setZebraEnabled(false)
                camera.setFalseColorEnabled(false)
                camera.setHistogramEnabled(false)
                camera.setWaveformEnabled(false)
                camera.setRGBParadeEnabled(false)
                camera.setVectorscopeEnabled(false)
            } else {
                syncMonitoringHUD()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(hud)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                saveStatusOverlay
                sessionStatusOverlay
            }
        }
    }

    private var cameraSurface: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let safeRect = safeHUDRect(for: geometry)

            ZStack {
                CameraPreview(
                    session: camera.session,
                    onTapToFocus: { point in
                        guard !hud.isEditing else { return }
                        camera.focus(at: point)
                    },
                    onLongPressAFAE: { point in
                        guard !hud.isEditing else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        camera.toggleAFAELock(at: point)
                    }
                )
                .ignoresSafeArea()

                FalseColorOverlay(
                    image: camera.falseColorImage,
                    isEnabled: camera.isFalseColorEnabled
                )
                .ignoresSafeArea()

                ZebraOverlay(
                    image: camera.zebraImage,
                    isEnabled: camera.isZebraEnabled
                )
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
                    showSubjectMarker:
                        settings.coachIntensity == .teaching
                        && camera.coachState.hasSubject,
                    leadingLines: camera.coachState.leadingLines,
                    vanishingPoint: camera.coachState.vanishingPoint,
                    showAnalysisGeometry: settings.coachIntensity == .teaching
                )
                .ignoresSafeArea()

                FrameGuideOverlay(guide: settings.frameGuide)
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
                withAnimation(.snappy) { showingProControls.toggle() }
            } label: {
                Image(systemName: showingProControls ? "slider.horizontal.3" : "dial.medium")
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.pro))

        case .language:
            languageMenu

        case .settings:
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.settings))

        case .lenses:
            lensSelector

        case .scene:
            sceneMenu

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
            Button { cycleGrid() } label: {
                Image(systemName: "grid")
                    .frame(width: 58, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel(settings.text(.grid))

        case .focusPeaking:
            Button { camera.toggleFocusPeaking() } label: {
                Image(
                    systemName: camera.isFocusPeakingEnabled
                        ? "viewfinder.circle.fill"
                        : "viewfinder.circle"
                )
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    camera.isFocusPeakingEnabled ? peakingSwiftUIColor : .white
                )
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.focusPeaking))

        case .zebra:
            zebraControl

        case .histogram:
            HistogramView(
                snapshot: camera.histogramSnapshot,
                isExpanded: $histogramExpanded
            )

        case .falseColor:
            Button { camera.toggleFalseColor() } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(camera.isFalseColorEnabled ? .yellow : .white)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(settings.text(.falseColor))

        case .waveform:
            PhotoScopeView(
                kind: .waveform,
                image: camera.waveformImage,
                isExpanded: $waveformExpanded
            )

        case .rgbParade:
            PhotoScopeView(
                kind: .rgbParade,
                image: camera.rgbParadeImage,
                isExpanded: $rgbParadeExpanded
            )

        case .vectorscope:
            PhotoScopeView(
                kind: .vectorscope,
                image: camera.vectorscopeImage,
                isExpanded: $vectorscopeExpanded
            )

        case .afaeLock:
            Button {
                camera.toggleAFAELock()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: camera.isAFAELocked ? "lock.fill" : "lock.open")
                    Text("AF/AE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(camera.isAFAELocked ? .orange : .white)
                .padding(.horizontal, 9)
                .frame(height: 42)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel(settings.text(.afaeLock))
            .accessibilityValue(
                settings.text(camera.isAFAELocked ? .afaeLocked : .afaeUnlocked)
            )

        case .clippingWarnings:
            ClippingWarningView(snapshot: camera.histogramSnapshot)

        case .frameGuide:
            frameGuideMenu
        }
    }

    private var zebraControl: some View {
        HStack(spacing: 0) {
            Button {
                camera.toggleZebra()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.diagonal")
                    Text(zebraHUDLabel)
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                }
                .foregroundStyle(camera.isZebraEnabled ? .yellow : .white)
                .padding(.leading, 10)
                .padding(.trailing, 6)
                .frame(height: 44)
            }

            Menu {
                Button {
                    settings.dualZebra.toggle()
                } label: {
                    Label(
                        settings.text(.dualZebra),
                        systemImage: settings.dualZebra ? "checkmark" : "circle"
                    )
                }

                Divider()

                Button {
                    settings.dualZebra = true
                    settings.zebraLowLevel = 70
                    settings.zebraLevel = 95
                } label: {
                    Text("70 / 95")
                }

                Button {
                    settings.dualZebra = true
                    settings.zebraLowLevel = 75
                    settings.zebraLevel = 100
                } label: {
                    Text("75 / 100")
                }

                Button {
                    settings.dualZebra = true
                    settings.zebraLowLevel = 80
                    settings.zebraLevel = 95
                } label: {
                    Text("80 / 95")
                }

                Divider()

                ForEach([85, 90, 95, 100], id: \.self) { level in
                    Button {
                        settings.dualZebra = false
                        settings.zebraLevel = Double(level)
                    } label: {
                        Text("Z \(level)")
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .frame(width: 28, height: 44)
            }
        }
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel(settings.text(.zebra))
    }

    private var zebraHUDLabel: String {
        if settings.dualZebra {
            return "Z\(Int(settings.zebraLowLevel.rounded()))/\(Int(settings.zebraLevel.rounded()))"
        }
        return "Z\(Int(settings.zebraLevel.rounded()))"
    }

    private var frameGuideMenu: some View {
        Menu {
            ForEach(AppSettings.FrameGuide.allCases) { guide in
                Button {
                    settings.frameGuide = guide
                } label: {
                    if settings.frameGuide == guide {
                        Label(settings.frameGuideName(guide), systemImage: "checkmark")
                    } else {
                        Text(settings.frameGuideName(guide))
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.dashed")
                Text(frameGuideShortLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 9)
            .frame(height: 42)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel(settings.text(.frameGuide))
    }

    private var frameGuideShortLabel: String {
        switch settings.frameGuide {
        case .none: "OFF"
        case .square: "1:1"
        case .fourThree: "4:3"
        case .threeTwo: "3:2"
        case .sixteenNine: "16:9"
        case .cinema239: "2.39"
        }
    }

    private var peakingSwiftUIColor: Color {
        switch settings.peakingColor {
        case .red: .red
        case .green: .green
        case .blue: .blue
        case .yellow: .yellow
        case .cyan: .cyan
        case .white: .white
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
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(settings.text(.scene))
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
                        camera.selectedLensID == lens.id
                            ? .white
                            : .black.opacity(0.38),
                        in: Capsule()
                    )
                }
            }
            .padding(4)
        }
        .frame(maxWidth: 270)
        .fixedSize(horizontal: true, vertical: true)
        .background(.ultraThinMaterial, in: Capsule())
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
                .frame(width: 64, height: 44)
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
        .disabled(!camera.isConfigured || camera.sessionInterrupted)
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
        case .afaeLock:
            return camera.supportsAFAELock
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
            width: max(
                1,
                geometry.size.width - insets.leading - insets.trailing - margin * 2
            ),
            height: max(
                1,
                geometry.size.height - insets.top - insets.bottom - margin * 2
            )
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

    private func applyMonitoringSettings() {
        camera.setZebraConfiguration(
            lowLevel: settings.zebraLowLevel,
            highLevel: settings.zebraLevel,
            dualEnabled: settings.dualZebra
        )
        camera.setFocusPeakingConfiguration(
            threshold: settings.peakingThreshold,
            color: settings.peakingColor
        )
    }

    private func syncMonitoringHUD() {
        guard !hud.isEditing else { return }

        let needsHistogram =
            hud.isVisible(.histogram)
            || hud.isVisible(.clippingWarnings)

        camera.setHistogramEnabled(needsHistogram)
        camera.setWaveformEnabled(hud.isVisible(.waveform))
        camera.setRGBParadeEnabled(hud.isVisible(.rgbParade))
        camera.setVectorscopeEnabled(hud.isVisible(.vectorscope))

        if !hud.isVisible(.zebra) {
            camera.setZebraEnabled(false)
        }
        if !hud.isVisible(.falseColor) {
            camera.setFalseColorEnabled(false)
        }
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
