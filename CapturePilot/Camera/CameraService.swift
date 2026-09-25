import AVFoundation
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
    @Published private(set) var supportsRawShareWorkflow = false
    @Published private(set) var lastShareJPEGURL: URL?
    @Published private(set) var lastShareJPEGDimensions: CGSize?
    @Published private(set) var lastShareLUTName: String?

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
    private let rawShareProcessor = RawShareProcessor()
    private let photoProcessingQueue = DispatchQueue(
        label: "CapturePilot.PhotoProcessing",
        qos: .userInitiated
    )

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
    private var rawShareMaxDimensions = CMVideoDimensions(width: 0, height: 0)

    private struct PendingRawShareCapture {
        var rawData: Data?
        var processedData: Data?
        let configuration: RawShareCaptureConfiguration
    }

    private var pendingRawShareCaptures: [Int64: PendingRawShareCapture] = [:]

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
            rawShareMaxDimensions = maximum
        } else {
            rawShareMaxDimensions = CMVideoDimensions(width: 0, height: 0)
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

        let selectedID = "\(captureDimensions.width)x\(captureDimensions.height)"
        let maxMegapixels = resolutions.last?.megapixels ?? 0
        let rawShareSupported =
            (hasBayer || hasProRAW)
            && maxMegapixels >= 40
            && self.photoOutput.availablePhotoCodecTypes.contains(.jpeg)

        DispatchQueue.main.async {
            self.availableResolutions = resolutions
            self.selectedResolutionID = selectedID
            self.availablePhotoFormats = formats
            self.supportsHEVC = hevc
            self.supportsProRAW = hasProRAW
            self.supportsRawShareWorkflow = rawShareSupported
            if !formats.contains(self.photoFormat) {
                self.photoFormat = hevc ? .heif : .jpeg
            }
            self.publishManualCapabilities(for: device)
        }
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

    func capturePhoto(
        rawShareConfiguration: RawShareCaptureConfiguration? = nil
    ) {
        let requestedFormat = photoFormat

        DispatchQueue.main.async { [weak self] in
            self?.lastSaveSucceeded = nil
            self?.clearShareJPEG()
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            if let rawShareConfiguration {
                guard self.supportsRawShareWorkflow,
                      self.rawShareMaxDimensions.width > 0,
                      self.rawShareMaxDimensions.height > 0,
                      let rawType = self.preferredRawSharePixelFormat() else {
                    DispatchQueue.main.async { self.lastSaveSucceeded = false }
                    return
                }

                let settings = AVCapturePhotoSettings(
                    rawPixelFormatType: rawType,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )
                settings.maxPhotoDimensions = self.rawShareMaxDimensions
                settings.photoQualityPrioritization = .quality
                settings.flashMode = .off
                settings.isAutoStillImageStabilizationEnabled = false

                self.photoProcessingQueue.sync {
                    self.pendingRawShareCaptures[settings.uniqueID] =
                        PendingRawShareCapture(
                            rawData: nil,
                            processedData: nil,
                            configuration: rawShareConfiguration
                        )
                }

                self.photoOutput.capturePhoto(with: settings, delegate: self)
                return
            }

            let settings: AVCapturePhotoSettings

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
            }

            if self.captureDimensions.width > 0, self.captureDimensions.height > 0 {
                settings.maxPhotoDimensions = self.captureDimensions
            }

            settings.photoQualityPrioritization = .quality
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func preferredRawSharePixelFormat() -> OSType? {
        let types = photoOutput.availableRawPhotoPixelFormatTypes

        if photoOutput.isAppleProRAWEnabled,
           let proRAW = types.first(where: AVCapturePhotoOutput.isAppleProRAWPixelFormat) {
            return proRAW
        }

        return types.first(where: AVCapturePhotoOutput.isBayerRAWPixelFormat)
    }

    private func clearShareJPEG() {
        if let url = lastShareJPEGURL {
            try? FileManager.default.removeItem(at: url)
        }
        lastShareJPEGURL = nil
        lastShareJPEGDimensions = nil
        lastShareLUTName = nil
    }

    private func processCompletedRawShareCapture(
        rawData: Data,
        processedData: Data,
        configuration: RawShareCaptureConfiguration
    ) {
        do {
            let result = try rawShareProcessor.process(
                processedPhotoData: processedData,
                configuration: configuration
            )
            let shareURL = try writeTemporaryShareJPEG(result.data)

            DispatchQueue.main.async {
                self.lastShareJPEGURL = shareURL
                self.lastShareJPEGDimensions = CGSize(
                    width: result.width,
                    height: result.height
                )
                self.lastShareLUTName = result.appliedLUTName
            }

            saveRawShareAsset(
                rawData: rawData,
                jpegData: result.data
            )
        } catch {
            DispatchQueue.main.async {
                self.runtimeErrorDescription = error.localizedDescription
                self.lastSaveSucceeded = false
            }
        }
    }

    private func writeTemporaryShareJPEG(_ data: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CapturePilotShare", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let url = directory.appendingPathComponent(
            "CapturePilot-Share-\(UUID().uuidString).jpg"
        )
        try data.write(to: url, options: .atomic)
        return url
    }

    private func saveRawShareAsset(
        rawData: Data,
        jpegData: Data
    ) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self else { return }

            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self.lastSaveSucceeded = false }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()

                let jpegOptions = PHAssetResourceCreationOptions()
                jpegOptions.originalFilename = "CapturePilot-Share.jpg"
                request.addResource(
                    with: .photo,
                    data: jpegData,
                    options: jpegOptions
                )

                let rawOptions = PHAssetResourceCreationOptions()
                rawOptions.originalFilename = "CapturePilot-RAW.dng"
                request.addResource(
                    with: .alternatePhoto,
                    data: rawData,
                    options: rawOptions
                )
            } completionHandler: { success, _ in
                if success {
                    DispatchQueue.main.async { self.lastSaveSucceeded = true }
                } else {
                    self.saveRawShareAsSeparateAssets(
                        rawData: rawData,
                        jpegData: jpegData
                    )
                }
            }
        }
    }

    private func saveRawShareAsSeparateAssets(
        rawData: Data,
        jpegData: Data
    ) {
        PHPhotoLibrary.shared().performChanges {
            let jpegRequest = PHAssetCreationRequest.forAsset()
            jpegRequest.addResource(with: .photo, data: jpegData, options: nil)

            let rawRequest = PHAssetCreationRequest.forAsset()
            rawRequest.addResource(with: .photo, data: rawData, options: nil)
        } completionHandler: { [weak self] success, _ in
            DispatchQueue.main.async { self?.lastSaveSucceeded = success }
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
        let uniqueID = photo.resolvedSettings.uniqueID

        if error != nil {
            photoProcessingQueue.async { [weak self] in
                self?.pendingRawShareCaptures.removeValue(forKey: uniqueID)
            }
            DispatchQueue.main.async { self.lastSaveSucceeded = false }
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { self.lastSaveSucceeded = false }
            return
        }

        let isPendingRawShare = photoProcessingQueue.sync {
            pendingRawShareCaptures[uniqueID] != nil
        }

        guard isPendingRawShare else {
            savePhotoData(data)
            return
        }

        photoProcessingQueue.async { [weak self] in
            guard let self,
                  var pending = self.pendingRawShareCaptures[uniqueID] else { return }

            if photo.isRawPhoto {
                pending.rawData = data
            } else {
                pending.processedData = data
            }

            if let rawData = pending.rawData,
               let processedData = pending.processedData {
                self.pendingRawShareCaptures.removeValue(forKey: uniqueID)
                self.processCompletedRawShareCapture(
                    rawData: rawData,
                    processedData: processedData,
                    configuration: pending.configuration
                )
            } else {
                self.pendingRawShareCaptures[uniqueID] = pending
            }
        }
    }
}
