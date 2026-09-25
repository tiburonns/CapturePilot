import AVFoundation
import Photos
import SwiftUI

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let coach = CoachEngine()

    @Published private(set) var isConfigured = false
    @Published private(set) var permissionDenied = false
    @Published private(set) var cameraUnavailable = false
    @Published private(set) var availableLenses: [CameraLens] = []
    @Published private(set) var selectedLensID: String = "wide"
    @Published private(set) var availablePhotoFormats: [PhotoFormat] = [.heif, .jpeg]
    @Published var photoFormat: PhotoFormat = .heif

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

    private let sessionQueue = DispatchQueue(label: "CapturePilot.CameraSession", qos: .userInitiated)
    private let videoQueue = DispatchQueue(label: "CapturePilot.VideoFrames", qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()

    private var currentInput: AVCaptureDeviceInput?
    private var coachIntensity: AppSettings.CoachIntensity = .balanced

    override init() {
        super.init()
        coach.onUpdate = { [weak self] state in
            self?.coachState = state
        }
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
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
            DispatchQueue.main.async {
                self.permissionDenied = true
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func setCoachIntensity(_ intensity: AppSettings.CoachIntensity) {
        videoQueue.async { [weak self] in
            self?.coachIntensity = intensity
        }
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

        let lenses = discoverLenses()
        DispatchQueue.main.async {
            self.availableLenses = lenses
        }

        guard let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: wide),
              session.canAddInput(input) else {
            DispatchQueue.main.async {
                self.cameraUnavailable = true
            }
            return
        }

        session.addInput(input)
        currentInput = input

        guard session.canAddOutput(photoOutput) else {
            DispatchQueue.main.async {
                self.cameraUnavailable = true
            }
            return
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        DispatchQueue.main.async {
            self.isConfigured = true
            self.selectedLensID = "wide"
            self.syncDeviceValues(wide)
            self.refreshPhotoFormats()
        }
    }

    private func discoverLenses() -> [CameraLens] {
        var result: [CameraLens] = []

        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
            result.append(CameraLens(id: "ultra", title: "0.5×", deviceType: .builtInUltraWideCamera))
        }
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil {
            result.append(CameraLens(id: "wide", title: "1×", deviceType: .builtInWideAngleCamera))
        }
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil {
            result.append(CameraLens(id: "tele", title: "Tele", deviceType: .builtInTelephotoCamera))
        }

        return result
    }

    func selectLens(_ lens: CameraLens) {
        sessionQueue.async { [weak self] in
            guard let self,
                  lens.id != self.selectedLensID,
                  let device = AVCaptureDevice.default(lens.deviceType, for: .video, position: .back),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }

            let oldInput = self.currentInput
            self.session.beginConfiguration()

            if let oldInput {
                self.session.removeInput(oldInput)
            }

            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
            } else if let oldInput, self.session.canAddInput(oldInput) {
                self.session.addInput(oldInput)
                self.currentInput = oldInput
            }

            self.session.commitConfiguration()

            guard self.currentInput === newInput else { return }
            DispatchQueue.main.async {
                self.selectedLensID = lens.id
                self.manualExposure = false
                self.manualFocus = false
                self.manualWhiteBalance = false
                self.syncDeviceValues(device)
                self.refreshPhotoFormats()
            }
        }
    }

    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
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
                }
            } catch {
                // Keep the current focus/exposure state if configuration locking fails.
            }
        }
    }

    func setExposureBias(_ value: Float) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            let clamped = min(max(value, device.minExposureTargetBias), device.maxExposureTargetBias)
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clamped)
                device.unlockForConfiguration()
                DispatchQueue.main.async {
                    self.exposureBias = clamped
                }
            } catch { }
        }
    }

    func setManualExposure(enabled: Bool, iso requestedISO: Float? = nil, shutter requestedShutter: Double? = nil) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
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
                    }
                } else if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                    DispatchQueue.main.async {
                        self.manualExposure = false
                    }
                }

                device.unlockForConfiguration()
            } catch { }
        }
    }

    func setManualFocus(enabled: Bool, position: Float? = nil) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            do {
                try device.lockForConfiguration()

                if enabled, device.isFocusModeSupported(.locked) {
                    let requested = position ?? self.focusPosition
                    let clamped = min(max(requested, 0), 1)
                    device.setFocusModeLocked(lensPosition: clamped, completionHandler: nil)
                    DispatchQueue.main.async {
                        self.focusPosition = clamped
                        self.manualFocus = true
                    }
                } else if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    DispatchQueue.main.async {
                        self.manualFocus = false
                    }
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
                    let values = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: clampedTemperature, tint: 0)
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
                    DispatchQueue.main.async {
                        self.manualWhiteBalance = false
                    }
                }

                device.unlockForConfiguration()
            } catch { }
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let settings: AVCapturePhotoSettings
            switch self.photoFormat {
            case .raw:
                guard let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first else {
                    DispatchQueue.main.async {
                        self.photoFormat = .heif
                        self.lastSaveSucceeded = false
                    }
                    return
                }
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawType)

            case .jpeg:
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

            case .heif:
                let codec: AVVideoCodecType = self.photoOutput.availablePhotoCodecTypes.contains(.hevc) ? .hevc : .jpeg
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: codec])
            }

            settings.photoQualityPrioritization = .quality
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func savePhotoData(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self?.lastSaveSucceeded = false
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    self?.lastSaveSucceeded = success
                }
            }
        }
    }

    private func refreshPhotoFormats() {
        var formats: [PhotoFormat] = [.heif, .jpeg]
        if !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
            formats.append(.raw)
        }
        availablePhotoFormats = formats
        if !formats.contains(photoFormat) {
            photoFormat = .heif
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
        minShutterSeconds = max(0.000001, CMTimeGetSeconds(device.activeFormat.minExposureDuration))
        maxShutterSeconds = max(minShutterSeconds, CMTimeGetSeconds(device.activeFormat.maxExposureDuration))
        let whiteBalance = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
        whiteBalanceTemperature = whiteBalance.temperature
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        coach.process(sampleBuffer: sampleBuffer, intensity: coachIntensity)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.lastSaveSucceeded = false
            }
            return
        }
        savePhotoData(data)
    }
}
