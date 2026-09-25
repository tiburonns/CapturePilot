import AVFoundation
import ImageIO
import Photos
import SwiftUI

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let coach = CoachEngine()
    let focusPeaking = FocusPeakingEngine()
    let monitoring = ProfessionalMonitoringEngine()

    @Published private(set) var isConfigured = false
    @Published private(set) var permissionDenied = false
    @Published private(set) var cameraUnavailable = false
    @Published private(set) var sessionInterrupted = false
    @Published private(set) var runtimeErrorDescription: String?

    @Published private(set) var availableLenses: [CameraLens] = []
    @Published private(set) var selectedLensID: String = ""
    @Published private(set) var availablePhotoFormats: [PhotoFormat] = [.jpeg]
    @Published var photoFormat: PhotoFormat = .heif

    @Published private(set) var availableResolutions: [PhotoResolutionOption] = []
    @Published private(set) var selectedResolutionID: String = ""

    @Published private(set) var supportsExposureBias = false
    @Published private(set) var supportsManualExposure = false
    @Published private(set) var supportsManualFocus = false
    @Published private(set) var supportsManualWhiteBalance = false
    @Published private(set) var supportsAFAELock = false
    @Published private(set) var supportsHEVC = false
    @Published private(set) var supportsProRAW = false
    @Published private(set) var shareJPEGOptions: [Int] = [12]
    @Published private(set) var selectedShareJPEGMegapixels: Int = 12
    @Published private(set) var rawMasterRequestedDimensions = CMVideoDimensions(width: 0, height: 0)
    @Published private(set) var lastResolvedRawDimensions = CMVideoDimensions(width: 0, height: 0)
    @Published private(set) var lastResolvedShareDimensions = CMVideoDimensions(width: 0, height: 0)
    @Published private(set) var lastShareJPEGURL: URL?

    @Published var exposureBias: Float = 0
    @Published private(set) var minExposureBias: Float = -2
    @Published private(set) var maxExposureBias: Float = 2

    @Published var manualExposure = false
    @Published var iso: Float = 100
    @Published var shutterSeconds: Double = 1.0 / 120.0
    @Published private(set) var minISO: Float = 25
    @Published private(set) var maxISO: Float = 1600
    @Published private(set) var minShutterSeconds: Double = 1.0 / 8000.0
    @Published private(set) var maxShutterSeconds: Double = 1.0

    @Published var focusPosition: Float = 0.5
    @Published var manualFocus = false
    @Published var whiteBalanceTemperature: Float = 5000
    @Published var manualWhiteBalance = false

    @Published var coachState = CoachState()
    @Published var lastSaveSucceeded: Bool? = nil
    @Published private(set) var isFocusPeakingEnabled = false
    @Published private(set) var focusPeakingImage: CGImage? = nil
    @Published private(set) var isZebraEnabled = false
    @Published private(set) var zebraImage: CGImage? = nil
    @Published private(set) var histogramSnapshot: HistogramSnapshot = .empty
    @Published private(set) var isFalseColorEnabled = false
    @Published private(set) var falseColorImage: CGImage? = nil
    @Published private(set) var waveformImage: CGImage? = nil
    @Published private(set) var rgbParadeImage: CGImage? = nil
    @Published private(set) var vectorscopeImage: CGImage? = nil
    @Published private(set) var isAFAELocked = false

    private let sessionQueue = DispatchQueue(label: "CapturePilot.CameraSession", qos: .userInitiated)
    private let videoQueue = DispatchQueue(label: "CapturePilot.VideoFrames", qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoProcessingQueue = DispatchQueue(
        label: "CapturePilot.PhotoProcessing",
        qos: .userInitiated
    )
    private let pendingCaptureLock = NSLock()

    private var currentInput: AVCaptureDeviceInput?
    private var observerTokens: [NSObjectProtocol] = []
    private var coachIntensity: AppSettings.CoachIntensity = .balanced
    private var coachScene: AppSettings.SceneCoach = .general
    private var focusPeakingRequested = false
    private var zebraRequested = false
    private var histogramRequested = false
    private var falseColorRequested = false
    private var waveformRequested = false
    private var rgbParadeRequested = false
    private var vectorscopeRequested = false
    private var zebraLevel: Double = 95
    private var zebraLowLevel: Double = 70
    private var dualZebra = true
    private var peakingThreshold = 54
    private var peakingColor: (UInt8, UInt8, UInt8) = (255, 80, 30)
    private var afaeLockGeneration = 0
    private var captureDimensions = CMVideoDimensions(width: 0, height: 0)
    private var pendingDualCaptures: [Int64: PendingDualCapture] = [:]

    private struct PendingDualCapture {
        let lut: LUTCube
        let targetMegapixels: Int
        var rawData: Data?
        var processedData: Data?
        var processedMetadata: [String: Any] = [:]
        var rawDimensions = CMVideoDimensions(width: 0, height: 0)
        var processedDimensions = CMVideoDimensions(width: 0, height: 0)

        var isComplete: Bool {
            rawData != nil && processedData != nil
        }
    }

    private var captureRotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var captureRotationObservation: NSKeyValueObservation?

    override init() {
        super.init()

        coach.onUpdate = { [weak self] state in
            self?.coachState = state
        }

        focusPeaking.onUpdate = { [weak self] image in
            guard let self, self.isFocusPeakingEnabled else { return }
            self.focusPeakingImage = image
        }

        monitoring.onZebraUpdate = { [weak self] image in
            guard let self, self.isZebraEnabled else { return }
            self.zebraImage = image
        }

        monitoring.onHistogramUpdate = { [weak self] snapshot in
            self?.histogramSnapshot = snapshot
        }

        monitoring.onFalseColorUpdate = { [weak self] image in
            guard let self, self.isFalseColorEnabled else { return }
            self.falseColorImage = image
        }

        monitoring.onWaveformUpdate = { [weak self] image in
            self?.waveformImage = image
        }

        monitoring.onRGBParadeUpdate = { [weak self] image in
            self?.rgbParadeImage = image
        }

        monitoring.onVectorscopeUpdate = { [weak self] image in
            self?.vectorscopeImage = image
        }

        registerSessionObservers()
    }

    deinit {
        observerTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func start() {
        resumeIfPossible()
    }

    func resumeIfPossible() {
        runtimeErrorDescription = nil

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                }
                if granted {
                    self?.configureAndStart()
                }
            }
        default:
            permissionDenied = true
        }
    }

    func stop() {
        setFocusPeakingEnabled(false)

        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func setCoachIntensity(_ intensity: AppSettings.CoachIntensity) {
        videoQueue.async { [weak self] in self?.coachIntensity = intensity }
    }

    func setCoachScene(_ scene: AppSettings.SceneCoach) {
        videoQueue.async { [weak self] in self?.coachScene = scene }
    }

    func toggleZebra() {
        setZebraEnabled(!isZebraEnabled)
    }

    func setZebraEnabled(_ enabled: Bool) {
        if enabled, isFalseColorEnabled {
            setFalseColorEnabled(false)
        }

        isZebraEnabled = enabled
        if !enabled {
            zebraImage = nil
        }

        videoQueue.async { [weak self] in
            self?.zebraRequested = enabled
        }
    }

    func setZebraConfiguration(
        lowLevel: Double,
        highLevel: Double,
        dualEnabled: Bool
    ) {
        let low = min(max(lowLevel, 50), 95)
        let high = min(max(highLevel, 75), 100)

        videoQueue.async { [weak self] in
            self?.zebraLowLevel = min(low, high)
            self?.zebraLevel = max(low, high)
            self?.dualZebra = dualEnabled
        }
    }

    func setHistogramEnabled(_ enabled: Bool) {
        if !enabled {
            histogramSnapshot = .empty
        }
        videoQueue.async { [weak self] in
            self?.histogramRequested = enabled
        }
    }

    func toggleFalseColor() {
        setFalseColorEnabled(!isFalseColorEnabled)
    }

    func setFalseColorEnabled(_ enabled: Bool) {
        if enabled, isZebraEnabled {
            setZebraEnabled(false)
        }

        isFalseColorEnabled = enabled
        if !enabled {
            falseColorImage = nil
        }

        videoQueue.async { [weak self] in
            self?.falseColorRequested = enabled
        }
    }

    func setWaveformEnabled(_ enabled: Bool) {
        if !enabled { waveformImage = nil }
        videoQueue.async { [weak self] in self?.waveformRequested = enabled }
    }

    func setRGBParadeEnabled(_ enabled: Bool) {
        if !enabled { rgbParadeImage = nil }
        videoQueue.async { [weak self] in self?.rgbParadeRequested = enabled }
    }

    func setVectorscopeEnabled(_ enabled: Bool) {
        if !enabled { vectorscopeImage = nil }
        videoQueue.async { [weak self] in self?.vectorscopeRequested = enabled }
    }

    func setFocusPeakingConfiguration(
        threshold: Double,
        color: AppSettings.PeakingColor
    ) {
        let clamped = min(max(Int(threshold.rounded()), 20), 140)
        let rgb: (UInt8, UInt8, UInt8)

        switch color {
        case .red: rgb = (255, 70, 55)
        case .green: rgb = (70, 255, 95)
        case .blue: rgb = (70, 135, 255)
        case .yellow: rgb = (255, 225, 40)
        case .cyan: rgb = (30, 235, 245)
        case .white: rgb = (255, 255, 255)
        }

        videoQueue.async { [weak self] in
            self?.peakingThreshold = clamped
            self?.peakingColor = rgb
        }
    }

    func toggleFocusPeaking() {
        setFocusPeakingEnabled(!isFocusPeakingEnabled)
    }

    func setFocusPeakingEnabled(_ enabled: Bool) {
        isFocusPeakingEnabled = enabled
        if !enabled {
            focusPeakingImage = nil
        }

        videoQueue.async { [weak self] in
            self?.focusPeakingRequested = enabled
        }
    }

    private func registerSessionObservers() {
        let center = NotificationCenter.default

        observerTokens.append(center.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.sessionInterrupted = true
        })

        observerTokens.append(center.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.sessionInterrupted = false
            self?.resumeIfPossible()
        })

        observerTokens.append(center.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError
            self.runtimeErrorDescription = error?.localizedDescription ?? "Camera session error"

            if error?.code == AVError.Code.mediaServicesWereReset.rawValue {
                self.resumeIfPossible()
            }
        })
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureSession()
            }
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        let devices = rearCameraDevices()
        let lenses = makeLensModels(from: devices)
        DispatchQueue.main.async { self.availableLenses = lenses }

        guard let wide = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }),
              let input = try? AVCaptureDeviceInput(device: wide),
              session.canAddInput(input) else {
            DispatchQueue.main.async { self.cameraUnavailable = true }
            return
        }

        session.addInput(input)
        currentInput = input

        guard session.canAddOutput(photoOutput) else {
            DispatchQueue.main.async { self.cameraUnavailable = true }
            return
        }

        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        configureCapturePipeline(for: wide)
        configureCaptureRotation(for: wide)

        DispatchQueue.main.async {
            self.isConfigured = true
            self.cameraUnavailable = false
            self.selectedLensID = wide.uniqueID
            self.syncDeviceValues(wide)
        }
    }

    private func rearCameraDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInUltraWideCamera,
                .builtInWideAngleCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .back
        ).devices
    }

    private func makeLensModels(from devices: [AVCaptureDevice]) -> [CameraLens] {
        guard let wide = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) else {
            return []
        }

        let wideFOV = bestPhotoFormat(for: wide)?.videoFieldOfView
            ?? wide.activeFormat.videoFieldOfView

        return devices.map { device in
            let fov = bestPhotoFormat(for: device)?.videoFieldOfView
                ?? device.activeFormat.videoFieldOfView
            let scale = opticalScale(wideFOV: wideFOV, lensFOV: fov)
            return CameraLens(
                id: device.uniqueID,
                title: lensTitle(scale: scale),
                deviceType: device.deviceType,
                opticalScale: scale
            )
        }
        .sorted { $0.opticalScale < $1.opticalScale }
    }

    private func opticalScale(wideFOV: Float, lensFOV: Float) -> Double {
        let wideRadians = Double(wideFOV) * .pi / 180
        let lensRadians = Double(lensFOV) * .pi / 180
        guard wideRadians > 0, lensRadians > 0 else { return 1 }
        return tan(wideRadians / 2) / tan(lensRadians / 2)
    }

    private func lensTitle(scale: Double) -> String {
        let common = [0.5, 1.0, 2.0, 3.0, 5.0]
        if let nearest = common.min(by: { abs($0 - scale) < abs($1 - scale) }),
           abs(nearest - scale) < 0.38 {
            return nearest == floor(nearest)
                ? "\(Int(nearest))×"
                : String(format: "%.1f×", nearest)
        }
        return String(format: "%.1f×", scale)
    }

    func selectLens(_ lens: CameraLens) {
        sessionQueue.async { [weak self] in
            guard let self,
                  lens.id != self.currentInput?.device.uniqueID,
                  let device = self.rearCameraDevices().first(where: { $0.uniqueID == lens.id }),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }

            let wasRunning = self.session.isRunning
            if wasRunning { self.session.stopRunning() }

            let oldInput = self.currentInput
            self.session.beginConfiguration()

            if let oldInput { self.session.removeInput(oldInput) }

            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
                self.configureCapturePipeline(for: device)
            } else if let oldInput, self.session.canAddInput(oldInput) {
                self.session.addInput(oldInput)
                self.currentInput = oldInput
                self.configureCapturePipeline(for: oldInput.device)
            }

            self.session.commitConfiguration()

            if wasRunning { self.session.startRunning() }

            guard self.currentInput === newInput else { return }
            self.configureCaptureRotation(for: device)

            DispatchQueue.main.async {
                self.selectedLensID = lens.id
                self.manualExposure = false
                self.manualFocus = false
                self.manualWhiteBalance = false
                self.isAFAELocked = false
                self.syncDeviceValues(device)
            }
        }
    }

    private func bestPhotoFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        device.formats.max { lhs, rhs in
            let lhsPixels = maximumPixels(in: lhs)
            let rhsPixels = maximumPixels(in: rhs)
            if lhsPixels == rhsPixels {
                if lhs.isHighestPhotoQualitySupported != rhs.isHighestPhotoQualitySupported {
                    return !lhs.isHighestPhotoQualitySupported
                }
                return lhs.videoFieldOfView > rhs.videoFieldOfView
            }
            return lhsPixels < rhsPixels
        }
    }

    private func maximumPixels(in format: AVCaptureDevice.Format) -> Int64 {
        format.supportedMaxPhotoDimensions
            .map { Int64($0.width) * Int64($0.height) }
            .max() ?? 0
    }

    private func configureCapturePipeline(for device: AVCaptureDevice) {
        if let best = bestPhotoFormat(for: device), best !== device.activeFormat {
            do {
                try device.lockForConfiguration()
                device.activeFormat = best
                device.unlockForConfiguration()
            } catch {
                // Continue with the active format if a format switch is rejected.
            }
        }

        let supportedDimensions = device.activeFormat.supportedMaxPhotoDimensions
            .filter { $0.width > 0 && $0.height > 0 }
            .sorted {
                Int64($0.width) * Int64($0.height)
                    < Int64($1.width) * Int64($1.height)
            }

        if let maximum = supportedDimensions.last {
            photoOutput.maxPhotoDimensions = maximum
        }

        photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported

        let options = supportedDimensions.map {
            PhotoResolutionOption(width: $0.width, height: $0.height)
        }

        let preferred =
            options.first(where: { abs($0.megapixels - 24) < 3.5 })
            ?? options.first(where: { abs($0.megapixels - 12) < 2.5 })
            ?? options.last

        if !supportedDimensions.contains(where: {
            $0.width == captureDimensions.width && $0.height == captureDimensions.height
        }), let preferred {
            captureDimensions = preferred.dimensions
        }

        refreshPhotoCapabilities(for: device, resolutions: options)

        let maximumDimensions = supportedDimensions.last
            ?? CMVideoDimensions(width: 0, height: 0)
        let maxMP = Double(maximumDimensions.width)
            * Double(maximumDimensions.height)
            / 1_000_000.0
        let quickSizes = [12, 24, 48].filter {
            Double($0) <= maxMP + 3.0
        }
        let resolvedQuickSizes = quickSizes.isEmpty
            ? [max(1, Int(maxMP.rounded()))]
            : quickSizes

        DispatchQueue.main.async {
            self.rawMasterRequestedDimensions = maximumDimensions
            self.shareJPEGOptions = resolvedQuickSizes

            if !resolvedQuickSizes.contains(self.selectedShareJPEGMegapixels) {
                self.selectedShareJPEGMegapixels =
                    resolvedQuickSizes.contains(24)
                    ? 24
                    : (resolvedQuickSizes.last ?? 12)
            }
        }

        prepareHighResolutionCaptureSettings()
    }

    private func refreshPhotoCapabilities(
        for device: AVCaptureDevice,
        resolutions: [PhotoResolutionOption]
    ) {
        let hevc = photoOutput.availablePhotoCodecTypes.contains(.hevc)
        let rawTypes = photoOutput.availableRawPhotoPixelFormatTypes
        let hasBayer = rawTypes.contains(where: AVCapturePhotoOutput.isBayerRAWPixelFormat)
        let hasProRAW = photoOutput.isAppleProRAWEnabled
            && rawTypes.contains(where: AVCapturePhotoOutput.isAppleProRAWPixelFormat)

        var formats: [PhotoFormat] = [.jpeg]
        if hevc { formats.insert(.heif, at: 0) }
        if hasBayer { formats.append(.raw) }
        if hasProRAW { formats.append(.proRAW) }
        if hasBayer || hasProRAW { formats.append(.rawPlusJPEG) }

        let selectedID = "\(captureDimensions.width)x\(captureDimensions.height)"

        DispatchQueue.main.async {
            self.availableResolutions = resolutions
            self.selectedResolutionID = selectedID
            self.availablePhotoFormats = formats
            self.supportsHEVC = hevc
            self.supportsProRAW = hasProRAW
            if !formats.contains(self.photoFormat) {
                self.photoFormat = hevc ? .heif : .jpeg
            }
            self.publishManualCapabilities(for: device)
        }
    }

    func selectShareJPEGMegapixels(_ megapixels: Int) {
        guard shareJPEGOptions.contains(megapixels) else { return }
        selectedShareJPEGMegapixels = megapixels
    }

    func selectResolution(_ option: PhotoResolutionOption) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            let supported = device.activeFormat.supportedMaxPhotoDimensions
            guard supported.contains(where: {
                $0.width == option.width && $0.height == option.height
            }) else { return }

            self.captureDimensions = option.dimensions
            DispatchQueue.main.async {
                self.selectedResolutionID = option.id
            }
        }
    }

    private func preferredRawPixelFormatType() -> OSType? {
        let available = photoOutput.availableRawPhotoPixelFormatTypes

        if photoOutput.isAppleProRAWEnabled,
           let proRAW = available.first(where: AVCapturePhotoOutput.isAppleProRAWPixelFormat) {
            return proRAW
        }

        return available.first(where: AVCapturePhotoOutput.isBayerRAWPixelFormat)
    }

    private func prepareHighResolutionCaptureSettings() {
        let dimensions = photoOutput.maxPhotoDimensions
        guard dimensions.width > 0, dimensions.height > 0 else { return }

        var settingsToPrepare: [AVCapturePhotoSettings] = []

        let jpeg = AVCapturePhotoSettings(
            format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
        )
        jpeg.maxPhotoDimensions = dimensions
        jpeg.photoQualityPrioritization = .quality
        settingsToPrepare.append(jpeg)

        if let rawType = preferredRawPixelFormatType() {
            let dual = AVCapturePhotoSettings(
                rawPixelFormatType: rawType,
                processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )
            dual.maxPhotoDimensions = dimensions
            dual.photoQualityPrioritization = .quality
            settingsToPrepare.append(dual)
        }

        photoOutput.setPreparedPhotoSettingsArray(settingsToPrepare) { _, _ in }
    }

    private func publishManualCapabilities(for device: AVCaptureDevice) {
        supportsExposureBias = device.minExposureTargetBias < device.maxExposureTargetBias
        supportsManualExposure = device.isExposureModeSupported(.custom)
        supportsManualFocus = device.isFocusModeSupported(.locked)
        supportsManualWhiteBalance = device.isWhiteBalanceModeSupported(.locked)
        supportsAFAELock =
            device.isFocusModeSupported(.locked)
            && device.isExposureModeSupported(.locked)
    }

    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            self.afaeLockGeneration += 1

            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    } else if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    }
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.manualFocus = false
                    self.manualExposure = false
                    self.isAFAELocked = false
                }
            } catch { }
        }
    }

    func toggleAFAELock(at point: CGPoint? = nil) {
        if isAFAELocked {
            unlockAFAE()
        } else {
            lockAFAE(at: point)
        }
    }

    func lockAFAE(at point: CGPoint?) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.currentInput?.device,
                  device.isFocusModeSupported(.locked),
                  device.isExposureModeSupported(.locked) else { return }

            self.afaeLockGeneration += 1
            let generation = self.afaeLockGeneration

            do {
                try device.lockForConfiguration()

                if let point, device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                }
                if let point, device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                }

                if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                } else if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }

                if device.isExposureModeSupported(.autoExpose) {
                    device.exposureMode = .autoExpose
                } else if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }

                device.unlockForConfiguration()
            } catch {
                return
            }

            self.sessionQueue.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self,
                      generation == self.afaeLockGeneration,
                      let device = self.currentInput?.device else { return }

                do {
                    try device.lockForConfiguration()

                    if device.isFocusModeSupported(.locked) {
                        device.setFocusModeLocked(
                            lensPosition: device.lensPosition,
                            completionHandler: nil
                        )
                    }

                    if device.isExposureModeSupported(.locked) {
                        device.exposureMode = .locked
                    }

                    device.unlockForConfiguration()

                    DispatchQueue.main.async {
                        self.manualFocus = false
                        self.manualExposure = false
                        self.isAFAELocked = true
                    }
                } catch { }
            }
        }
    }

    func unlockAFAE() {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            self.afaeLockGeneration += 1

            do {
                try device.lockForConfiguration()

                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.isAFAELocked = false
                    self.manualFocus = false
                    self.manualExposure = false
                }
            } catch { }
        }
    }

    func setExposureBias(_ value: Float) {
        guard supportsExposureBias else { return }

        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            let clamped = min(max(value, device.minExposureTargetBias), device.maxExposureTargetBias)

            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clamped)
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.exposureBias = clamped }
            } catch { }
        }
    }

    func setManualExposure(
        enabled: Bool,
        iso requestedISO: Float? = nil,
        shutter requestedShutter: Double? = nil
    ) {
        if isAFAELocked {
            unlockAFAE()
        }

        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            self.afaeLockGeneration += 1

            do {
                try device.lockForConfiguration()

                if enabled, device.isExposureModeSupported(.custom) {
                    let format = device.activeFormat
                    let newISO = min(max(requestedISO ?? self.iso, format.minISO), format.maxISO)
                    let minSeconds = max(0.000001, CMTimeGetSeconds(format.minExposureDuration))
                    let maxSeconds = max(minSeconds, CMTimeGetSeconds(format.maxExposureDuration))
                    let newShutter = min(max(requestedShutter ?? self.shutterSeconds, minSeconds), maxSeconds)
                    let duration = CMTimeMakeWithSeconds(newShutter, preferredTimescale: 1_000_000_000)
                    device.setExposureModeCustom(duration: duration, iso: newISO, completionHandler: nil)

                    DispatchQueue.main.async {
                        self.iso = newISO
                        self.shutterSeconds = newShutter
                        self.manualExposure = true
                        self.isAFAELocked = false
                    }
                } else if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                    DispatchQueue.main.async { self.manualExposure = false }
                }

                device.unlockForConfiguration()
            } catch { }
        }
    }

    func setManualFocus(enabled: Bool, position: Float? = nil) {
        if isAFAELocked {
            unlockAFAE()
        }

        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            self.afaeLockGeneration += 1

            do {
                try device.lockForConfiguration()

                if enabled, device.isFocusModeSupported(.locked) {
                    let clamped = min(max(position ?? self.focusPosition, 0), 1)
                    device.setFocusModeLocked(lensPosition: clamped, completionHandler: nil)

                    DispatchQueue.main.async {
                        self.focusPosition = clamped
                        self.manualFocus = true
                        self.isAFAELocked = false
                    }
                } else if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    DispatchQueue.main.async { self.manualFocus = false }
                }

                device.unlockForConfiguration()
            } catch { }
        }
    }

    func setWhiteBalance(enabled: Bool, temperature: Float? = nil) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }

            do {
                try device.lockForConfiguration()

                if enabled, device.isWhiteBalanceModeSupported(.locked) {
                    let requested = temperature ?? self.whiteBalanceTemperature
                    let clampedTemperature = min(max(requested, 2500), 9000)
                    let values = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                        temperature: clampedTemperature,
                        tint: 0
                    )
                    var gains = device.deviceWhiteBalanceGains(for: values)
                    gains.redGain = min(max(1, gains.redGain), device.maxWhiteBalanceGain)
                    gains.greenGain = min(max(1, gains.greenGain), device.maxWhiteBalanceGain)
                    gains.blueGain = min(max(1, gains.blueGain), device.maxWhiteBalanceGain)
                    device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)

                    DispatchQueue.main.async {
                        self.whiteBalanceTemperature = clampedTemperature
                        self.manualWhiteBalance = true
                    }
                } else if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                    DispatchQueue.main.async { self.manualWhiteBalance = false }
                }

                device.unlockForConfiguration()
            } catch { }
        }
    }

    func capturePhoto(lut: LUTCube? = nil) {
        let requestedFormat = photoFormat
        let quickShareMP = selectedShareJPEGMegapixels

        DispatchQueue.main.async {
            self.lastSaveSucceeded = nil
            if requestedFormat != .rawPlusJPEG {
                self.lastShareJPEGURL = nil
            }
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let settings: AVCapturePhotoSettings
            var isDualCapture = false

            switch requestedFormat {
            case .raw:
                guard let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first(
                    where: AVCapturePhotoOutput.isBayerRAWPixelFormat
                ) else {
                    DispatchQueue.main.async { self.lastSaveSucceeded = false }
                    return
                }
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawType)

            case .proRAW:
                guard self.photoOutput.isAppleProRAWEnabled,
                      let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first(
                        where: AVCapturePhotoOutput.isAppleProRAWPixelFormat
                      ) else {
                    DispatchQueue.main.async { self.lastSaveSucceeded = false }
                    return
                }
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawType)

            case .jpeg:
                settings = AVCapturePhotoSettings(
                    format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )

            case .heif:
                guard self.photoOutput.availablePhotoCodecTypes.contains(.hevc) else {
                    DispatchQueue.main.async {
                        self.photoFormat = .jpeg
                        self.lastSaveSucceeded = false
                    }
                    return
                }
                settings = AVCapturePhotoSettings(
                    format: [AVVideoCodecKey: AVVideoCodecType.hevc]
                )

            case .rawPlusJPEG:
                guard let rawType = self.preferredRawPixelFormatType(),
                      let lut else {
                    DispatchQueue.main.async { self.lastSaveSucceeded = false }
                    return
                }

                settings = AVCapturePhotoSettings(
                    rawPixelFormatType: rawType,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )
                isDualCapture = true

                let masterDimensions = self.photoOutput.maxPhotoDimensions
                if masterDimensions.width > 0, masterDimensions.height > 0 {
                    settings.maxPhotoDimensions = masterDimensions
                }

                self.pendingCaptureLock.lock()
                self.pendingDualCaptures[settings.uniqueID] = PendingDualCapture(
                    lut: lut,
                    targetMegapixels: quickShareMP
                )
                self.pendingCaptureLock.unlock()
            }

            if !isDualCapture,
               self.captureDimensions.width > 0,
               self.captureDimensions.height > 0 {
                settings.maxPhotoDimensions = self.captureDimensions
            }

            settings.photoQualityPrioritization = .quality
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func savePhotoData(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self?.lastSaveSucceeded = false }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { self?.lastSaveSucceeded = success }
            }
        }
    }

    private func finishDualCapture(_ pending: PendingDualCapture) {
        guard let rawData = pending.rawData,
              let processedData = pending.processedData else {
            DispatchQueue.main.async { self.lastSaveSucceeded = false }
            return
        }

        photoProcessingQueue.async { [weak self] in
            guard let self,
                  let jpegData = LUTProcessor.makeJPEG(
                    from: processedData,
                    metadata: pending.processedMetadata,
                    lut: pending.lut,
                    targetMegapixels: pending.targetMegapixels
                  ) else {
                DispatchQueue.main.async { self?.lastSaveSucceeded = false }
                return
            }

            let shareURL = self.writeQuickShareJPEG(
                jpegData,
                lutName: pending.lut.name
            )

            DispatchQueue.main.async {
                self.lastResolvedRawDimensions = pending.rawDimensions
                self.lastResolvedShareDimensions = self.imageDimensions(from: jpegData)
                self.lastShareJPEGURL = shareURL
            }

            self.saveRAWJPEGPair(
                jpegData: jpegData,
                rawData: rawData,
                lutName: pending.lut.name
            )
        }
    }

    private func saveRAWJPEGPair(
        jpegData: Data,
        rawData: Data,
        lutName: String
    ) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self,
                  status == .authorized || status == .limited else {
                DispatchQueue.main.async { self?.lastSaveSucceeded = false }
                return
            }

            let timestamp = Int(Date().timeIntervalSince1970)
            let jpegOptions = PHAssetResourceCreationOptions()
            jpegOptions.originalFilename = "CapturePilot-\(timestamp)-\(self.fileSafe(lutName)).jpg"

            let rawOptions = PHAssetResourceCreationOptions()
            rawOptions.originalFilename = "CapturePilot-\(timestamp)-RAW.dng"

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(
                    with: .photo,
                    data: jpegData,
                    options: jpegOptions
                )
                request.addResource(
                    with: .alternatePhoto,
                    data: rawData,
                    options: rawOptions
                )
            } completionHandler: { success, _ in
                if success {
                    DispatchQueue.main.async { self.lastSaveSucceeded = true }
                } else {
                    self.saveRAWJPEGAsSeparateAssets(
                        jpegData: jpegData,
                        rawData: rawData,
                        jpegOptions: jpegOptions,
                        rawOptions: rawOptions
                    )
                }
            }
        }
    }

    private func saveRAWJPEGAsSeparateAssets(
        jpegData: Data,
        rawData: Data,
        jpegOptions: PHAssetResourceCreationOptions,
        rawOptions: PHAssetResourceCreationOptions
    ) {
        PHPhotoLibrary.shared().performChanges {
            let jpegRequest = PHAssetCreationRequest.forAsset()
            jpegRequest.addResource(
                with: .photo,
                data: jpegData,
                options: jpegOptions
            )

            let rawRequest = PHAssetCreationRequest.forAsset()
            rawRequest.addResource(
                with: .photo,
                data: rawData,
                options: rawOptions
            )
        } completionHandler: { [weak self] success, _ in
            DispatchQueue.main.async { self?.lastSaveSucceeded = success }
        }
    }

    private func writeQuickShareJPEG(_ data: Data, lutName: String) -> URL? {
        if let oldURL = lastShareJPEGURL {
            try? FileManager.default.removeItem(at: oldURL)
        }

        let name = "CapturePilot-QuickShare-\(fileSafe(lutName))-\(UUID().uuidString.prefix(8)).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func fileSafe(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
    }

    private func imageDimensions(from data: Data) -> CMVideoDimensions {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return CMVideoDimensions(width: 0, height: 0)
        }

        return CMVideoDimensions(width: Int32(width), height: Int32(height))
    }

    private func syncDeviceValues(_ device: AVCaptureDevice) {
        exposureBias = device.exposureTargetBias
        minExposureBias = device.minExposureTargetBias
        maxExposureBias = device.maxExposureTargetBias
        focusPosition = device.lensPosition
        iso = device.iso
        shutterSeconds = max(0.000001, CMTimeGetSeconds(device.exposureDuration))
        minISO = device.activeFormat.minISO
        maxISO = device.activeFormat.maxISO
        minShutterSeconds = max(
            0.000001,
            CMTimeGetSeconds(device.activeFormat.minExposureDuration)
        )
        maxShutterSeconds = max(
            minShutterSeconds,
            CMTimeGetSeconds(device.activeFormat.maxExposureDuration)
        )

        let whiteBalance = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
        whiteBalanceTemperature = whiteBalance.temperature
        publishManualCapabilities(for: device)
    }

    private func configureCaptureRotation(for device: AVCaptureDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.captureRotationObservation = nil

            let coordinator = AVCaptureDevice.RotationCoordinator(
                device: device,
                previewLayer: nil
            )
            self.captureRotationCoordinator = coordinator

            self.captureRotationObservation = coordinator.observe(
                \.videoRotationAngleForHorizonLevelCapture,
                options: [.initial, .new]
            ) { [weak self] coordinator, _ in
                self?.applyCaptureRotation(
                    coordinator.videoRotationAngleForHorizonLevelCapture
                )
            }
        }
    }

    private func applyCaptureRotation(_ angle: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if let videoConnection = self.videoOutput.connection(with: .video),
               videoConnection.isVideoRotationAngleSupported(angle) {
                videoConnection.videoRotationAngle = angle
            }

            if let photoConnection = self.photoOutput.connection(with: .video),
               photoConnection.isVideoRotationAngleSupported(angle) {
                photoConnection.videoRotationAngle = angle
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            if focusPeakingRequested {
                focusPeaking.process(
                    pixelBuffer: pixelBuffer,
                    threshold: peakingThreshold,
                    color: peakingColor
                )
            }

            if zebraRequested
                || histogramRequested
                || falseColorRequested
                || waveformRequested
                || rgbParadeRequested
                || vectorscopeRequested {
                monitoring.process(
                    pixelBuffer: pixelBuffer,
                    zebraEnabled: zebraRequested,
                    zebraLevel: zebraLevel,
                    zebraLowLevel: zebraLowLevel,
                    dualZebraEnabled: dualZebra,
                    histogramEnabled: histogramRequested,
                    falseColorEnabled: falseColorRequested,
                    waveformEnabled: waveformRequested,
                    rgbParadeEnabled: rgbParadeRequested,
                    vectorscopeEnabled: vectorscopeRequested
                )
            }
        }

        coach.process(
            sampleBuffer: sampleBuffer,
            intensity: coachIntensity,
            scene: coachScene
        )
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { self.lastSaveSucceeded = false }
            return
        }

        let captureID = photo.resolvedSettings.uniqueID

        pendingCaptureLock.lock()
        if var pending = pendingDualCaptures[captureID] {
            if photo.isRawPhoto {
                pending.rawData = data
                pending.rawDimensions = photo.resolvedSettings.rawPhotoDimensions
            } else {
                pending.processedData = data
                pending.processedMetadata = photo.metadata
                pending.processedDimensions = photo.resolvedSettings.photoDimensions
            }

            if pending.isComplete {
                pendingDualCaptures.removeValue(forKey: captureID)
                pendingCaptureLock.unlock()
                finishDualCapture(pending)
            } else {
                pendingDualCaptures[captureID] = pending
                pendingCaptureLock.unlock()
            }
            return
        }
        pendingCaptureLock.unlock()

        savePhotoData(data)
    }
}
