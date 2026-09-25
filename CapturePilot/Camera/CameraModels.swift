import AVFoundation
import CoreMedia
import CoreGraphics

struct CameraLens: Identifiable, Hashable {
    let id: String
    let title: String
    let deviceType: AVCaptureDevice.DeviceType
    let opticalScale: Double
}

struct PhotoResolutionOption: Identifiable, Equatable {
    let width: Int32
    let height: Int32

    var id: String { "\(width)x\(height)" }
    var dimensions: CMVideoDimensions { CMVideoDimensions(width: width, height: height) }
    var megapixels: Double { Double(width) * Double(height) / 1_000_000.0 }

    var shortLabel: String {
        let mp = megapixels
        if abs(mp - 12) < 2.5 { return "12 MP" }
        if abs(mp - 24) < 3.5 { return "24 MP" }
        if abs(mp - 48) < 5.0 { return "48 MP" }
        return "\(Int(mp.rounded())) MP"
    }
}

enum PhotoFormat: String, CaseIterable, Identifiable {
    case heif
    case jpeg
    case raw
    case proRAW
    case rawPlusJPEG

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .heif: "HEIF"
        case .jpeg: "JPEG"
        case .raw: "RAW"
        case .proRAW: "ProRAW"
        case .rawPlusJPEG: "RAW+JPG"
        }
    }
}

struct NormalizedLine: Equatable {
    let start: CGPoint
    let end: CGPoint
    let strength: Double
}
