import CoreImage
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum LUTProcessor {
    private static let context = CIContext(options: [
        .cacheIntermediates: false
    ])

    static func makeJPEG(
        from processedData: Data,
        metadata: [String: Any],
        lut: LUTCube,
        targetMegapixels: Int,
        quality: CGFloat = 0.94
    ) -> Data? {
        guard var image = CIImage(
            data: processedData,
            options: [.applyOrientationProperty: true]
        ) else {
            return nil
        }

        image = normalizeDomain(image, cube: lut)

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            return nil
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(lut.dimension, forKey: "inputCubeDimension")
        filter.setValue(lut.data, forKey: "inputCubeData")
        filter.setValue(CGColorSpace(name: CGColorSpace.sRGB), forKey: "inputColorSpace")

        guard var output = filter.outputImage else { return nil }

        let sourcePixels = output.extent.width * output.extent.height
        let requestedPixels = CGFloat(max(1, targetMegapixels)) * 1_000_000

        if sourcePixels > requestedPixels {
            let scale = sqrt(requestedPixels / sourcePixels)
            if let scaler = CIFilter(name: "CILanczosScaleTransform") {
                scaler.setValue(output, forKey: kCIInputImageKey)
                scaler.setValue(scale, forKey: kCIInputScaleKey)
                scaler.setValue(1.0, forKey: kCIInputAspectRatioKey)
                if let scaled = scaler.outputImage {
                    output = scaled
                }
            }
        }

        let extent = output.extent.integral
        guard let cgImage = context.createCGImage(output, from: extent) else {
            return nil
        }

        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        var properties = metadata
        properties[kCGImageDestinationLossyCompressionQuality as String] = quality
        properties[kCGImagePropertyOrientation as String] = 1

        CGImageDestinationAddImage(
            destination,
            cgImage,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else { return nil }
        return destinationData as Data
    }

    private static func normalizeDomain(_ image: CIImage, cube: LUTCube) -> CIImage {
        let minValue = cube.domainMin
        let maxValue = cube.domainMax
        let range = maxValue - minValue

        guard abs(minValue.x) > 0.0001
                || abs(minValue.y) > 0.0001
                || abs(minValue.z) > 0.0001
                || abs(maxValue.x - 1) > 0.0001
                || abs(maxValue.y - 1) > 0.0001
                || abs(maxValue.z - 1) > 0.0001 else {
            return image
        }

        guard range.x > 0, range.y > 0, range.z > 0,
              let matrix = CIFilter(name: "CIColorMatrix") else {
            return image
        }

        let sx = CGFloat(1 / range.x)
        let sy = CGFloat(1 / range.y)
        let sz = CGFloat(1 / range.z)

        matrix.setValue(image, forKey: kCIInputImageKey)
        matrix.setValue(CIVector(x: sx, y: 0, z: 0, w: 0), forKey: "inputRVector")
        matrix.setValue(CIVector(x: 0, y: sy, z: 0, w: 0), forKey: "inputGVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: sz, w: 0), forKey: "inputBVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        matrix.setValue(
            CIVector(
                x: CGFloat(-minValue.x / range.x),
                y: CGFloat(-minValue.y / range.y),
                z: CGFloat(-minValue.z / range.z),
                w: 0
            ),
            forKey: "inputBiasVector"
        )

        return matrix.outputImage ?? image
    }
}
