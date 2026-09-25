import AVFoundation
import CoreGraphics
import Foundation
import QuartzCore

final class FocusPeakingEngine {
    var onUpdate: ((CGImage?) -> Void)?

    private var lastProcessTime: CFTimeInterval = 0
    private let minimumInterval: CFTimeInterval = 0.12
    private let edgeThreshold = 54

    func process(pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        guard now - lastProcessTime >= minimumInterval else { return }
        lastProcessTime = now

        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }

        let sourceWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let sourceHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let luma = baseAddress.assumingMemoryBound(to: UInt8.self)

        let sampleStep = max(1, Int(ceil(Double(sourceWidth) / 360.0)))
        let outputWidth = max(2, sourceWidth / sampleStep)
        let outputHeight = max(2, sourceHeight / sampleStep)
        var rgba = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        guard outputWidth > 2, outputHeight > 2 else { return }

        for outputY in 1..<(outputHeight - 1) {
            let sourceY = min(sourceHeight - 2, outputY * sampleStep)
            let row = sourceY * sourceBytesPerRow

            for outputX in 1..<(outputWidth - 1) {
                let sourceX = min(sourceWidth - 2, outputX * sampleStep)

                let left = Int(luma[row + sourceX - 1])
                let right = Int(luma[row + sourceX + 1])
                let up = Int(luma[(sourceY - 1) * sourceBytesPerRow + sourceX])
                let down = Int(luma[(sourceY + 1) * sourceBytesPerRow + sourceX])

                let magnitude = abs(right - left) + abs(down - up)
                guard magnitude >= edgeThreshold else { continue }

                let index = (outputY * outputWidth + outputX) * 4
                rgba[index] = 255
                rgba[index + 1] = 80
                rgba[index + 2] = 30
                rgba[index + 3] = 235
            }
        }

        let data = Data(rgba)
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                width: outputWidth,
                height: outputHeight,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: outputWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(image)
        }
    }
}
