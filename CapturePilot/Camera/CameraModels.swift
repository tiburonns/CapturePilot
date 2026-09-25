import AVFoundation

struct CameraLens: Identifiable, Hashable {
    let id: String
    let title: String
    let deviceType: AVCaptureDevice.DeviceType
}

enum PhotoFormat: String, CaseIterable, Identifiable {
    case heif
    case jpeg
    case raw

    var id: String { rawValue }
    var shortLabel: String { rawValue.uppercased() }
}
