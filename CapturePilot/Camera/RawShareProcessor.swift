import CoreGraphics
import CoreImage
import Foundation
import ImageIO

struct RawShareCaptureConfiguration {
    let targetMegapixels: Int
    let lutURL: URL?
    let lutIntensity: Double
}

struct RawShareJPEGResult {
    let data: Data
    let width: Int
    let height: Int
    let appliedLUTName: String?
}

enum RawShareProcessingError: LocalizedError {
    case invalidImage
    case jpegEncodingFailed
    case invalidLUT
    case unsupportedLUTDomain
    case unsupportedLUTSize

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "The processed companion image could not be decoded."
        case .jpegEncodingFailed:
            "The share JPEG could not be encoded."
        case .invalidLUT:
            "The selected .cube LUT is invalid or incomplete."
        case .unsupportedLUTDomain:
            "CapturePilot currently supports .cube LUTs with a 0–1 input domain."
        case .unsupportedLUTSize:
            "CapturePilot supports 3D .cube LUTs from 2 to 65 points per axis."
        }
    }
}

struct CubeLUT {
    let title: String?
    let dimension: Int
    let cubeData: Data

    init(url: URL) throws {
        let raw = try Data(contentsOf: url)
        guard let text = String(data: raw, encoding: .utf8) else {
            throw RawShareProcessingError.invalidLUT
        }

        var title: String?
        var dimension: Int?
        var domainMin = SIMD3<Float>(repeating: 0)
        var domainMax = SIMD3<Float>(repeating: 1)
        var values: [SIMD3<Float>] = []

        for originalLine in text.components(separatedBy: .newlines) {
            let line = originalLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            let upper = line.uppercased()

            if upper.hasPrefix("TITLE ") {
                if let firstQuote = line.firstIndex(of: "\""),
                   let lastQuote = line.lastIndex(of: "\""),
                   firstQuote != lastQuote {
                    title = String(line[line.index(after: firstQuote)..<lastQuote])
                }
                continue
            }

            if upper.hasPrefix("LUT_3D_SIZE ") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 2 {
                    dimension = Int(parts[1])
                }
                continue
            }

            if upper.hasPrefix("LUT_1D_SIZE ") {
                throw RawShareProcessingError.invalidLUT
            }

            if upper.hasPrefix("DOMAIN_MIN ") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 4,
                   let r = Float(parts[1]),
                   let g = Float(parts[2]),
                   let b = Float(parts[3]) {
                    domainMin = SIMD3<Float>(r, g, b)
                }
                continue
            }

            if upper.hasPrefix("DOMAIN_MAX ") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 4,
                   let r = Float(parts[1]),
                   let g = Float(parts[2]),
                   let b = Float(parts[3]) {
                    domainMax = SIMD3<Float>(r, g, b)
                }
                continue
            }

            if upper.hasPrefix("LUT_3D_INPUT_RANGE ") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 3,
                   let minimum = Float(parts[1]),
                   let maximum = Float(parts[2]) {
                    domainMin = SIMD3<Float>(repeating: minimum)
                    domainMax = SIMD3<Float>(repeating: maximum)
                }
                continue
            }

            let parts = line.split(whereSeparator: { $0.isWhitespace })
            guard parts.count >= 3,
                  let r = Float(parts[0]),
                  let g = Float(parts[1]),
                  let b = Float(parts[2]) else {
                continue
            }

            values.append(SIMD3<Float>(r, g, b))
        }

        guard let dimension else {
            throw RawShareProcessingError.invalidLUT
        }
        guard (2...65).contains(dimension) else {
            throw RawShareProcessingError.unsupportedLUTSize
        }

        let epsilon: Float = 0.0001
        let standardDomain =
            abs(domainMin.x) < epsilon
            && abs(domainMin.y) < epsilon
            && abs(domainMin.z) < epsilon
            && abs(domainMax.x - 1) < epsilon
            && abs(domainMax.y - 1) < epsilon
            && abs(domainMax.z - 1) < epsilon

        guard standardDomain else {
            throw RawShareProcessingError.unsupportedLUTDomain
        }

        let expectedCount = dimension * dimension * dimension
        guard values.count == expectedCount else {
            throw RawShareProcessingError.invalidLUT
        }

        var rgba = [Float]()
        rgba.reserveCapacity(expectedCount * 4)

        for value in values {
            rgba.append(min(max(value.x, 0), 1))
            rgba.append(min(max(value.y, 0), 1))
            rgba.append(min(max(value.z, 0), 1))
            rgba.append(1)
        }

        self.title = title
        self.dimension = dimension
        self.cubeData = rgba.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }
}

final class RawShareProcessor {
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private let context = CIContext(options: [
        .cacheIntermediates: false,
        .highQualityDownsample: true
    ])

    func process(
        processedPhotoData: Data,
        configuration: RawShareCaptureConfiguration
    ) throws -> RawShareJPEGResult {
        guard var image = CIImage(
            data: processedPhotoData,
            options: [.applyOrientationProperty: true]
        ) else {
            throw RawShareProcessingError.invalidImage
        }

        var lutName: String?

        if let lutURL = configuration.lutURL,
           configuration.lutIntensity > 0 {
            let lut = try CubeLUT(url: lutURL)
            image = try apply(
                lut: lut,
                intensity: min(max(configuration.lutIntensity, 0), 1),
                to: image
            )
            lutName = lut.title ?? lutURL.deletingPathExtension().lastPathComponent
        }

        image = downsample(
            image,
            targetMegapixels: max(1, configuration.targetMegapixels)
        )

        let translated = image.transformed(
            by: CGAffineTransform(
                translationX: -image.extent.origin.x,
                y: -image.extent.origin.y
            )
        )

        let qualityKey = CIImageRepresentationOption(
            rawValue: kCGImageDestinationLossyCompressionQuality as String
        )

        guard let data = context.jpegRepresentation(
            of: translated,
            colorSpace: colorSpace,
            options: [qualityKey: 0.94]
        ) else {
            throw RawShareProcessingError.jpegEncodingFailed
        }

        return RawShareJPEGResult(
            data: data,
            width: Int(translated.extent.width.rounded()),
            height: Int(translated.extent.height.rounded()),
            appliedLUTName: lutName
        )
    }

    private func apply(
        lut: CubeLUT,
        intensity: Double,
        to image: CIImage
    ) throws -> CIImage {
        guard let cube = CIFilter(name: "CIColorCubeWithColorSpace") else {
            throw RawShareProcessingError.invalidLUT
        }

        cube.setValue(image, forKey: kCIInputImageKey)
        cube.setValue(Float(lut.dimension), forKey: "inputCubeDimension")
        cube.setValue(lut.cubeData, forKey: "inputCubeData")
        cube.setValue(colorSpace, forKey: "inputColorSpace")

        guard let transformed = cube.outputImage?.cropped(to: image.extent) else {
            throw RawShareProcessingError.invalidLUT
        }

        if intensity >= 0.999 {
            return transformed
        }

        guard let dissolve = CIFilter(name: "CIDissolveTransition") else {
            return transformed
        }

        dissolve.setValue(image, forKey: kCIInputImageKey)
        dissolve.setValue(transformed, forKey: "inputTargetImage")
        dissolve.setValue(intensity, forKey: kCIInputTimeKey)

        return dissolve.outputImage?.cropped(to: image.extent) ?? transformed
    }

    private func downsample(
        _ image: CIImage,
        targetMegapixels: Int
    ) -> CIImage {
        let currentPixels = max(1, image.extent.width * image.extent.height)
        let targetPixels = CGFloat(targetMegapixels) * 1_000_000

        guard targetPixels < currentPixels else { return image }

        let scale = sqrt(targetPixels / currentPixels)
        guard scale < 0.999 else { return image }

        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            return image.transformed(
                by: CGAffineTransform(scaleX: scale, y: scale)
            )
        }

        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0, forKey: kCIInputAspectRatioKey)
        return lanczos.outputImage ?? image
    }
}
