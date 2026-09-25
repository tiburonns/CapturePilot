import AVFoundation
import CoreGraphics
import Foundation
import QuartzCore

struct HistogramSnapshot: Equatable {
    var red: [Double]
    var green: [Double]
    var blue: [Double]
    var luma: [Double]
    var redShadowClipRatio: Double
    var greenShadowClipRatio: Double
    var blueShadowClipRatio: Double
    var redHighlightClipRatio: Double
    var greenHighlightClipRatio: Double
    var blueHighlightClipRatio: Double
    var sampleCount: Int

    static let empty = HistogramSnapshot(
        red: Array(repeating: 0, count: 256),
        green: Array(repeating: 0, count: 256),
        blue: Array(repeating: 0, count: 256),
        luma: Array(repeating: 0, count: 256),
        redShadowClipRatio: 0,
        greenShadowClipRatio: 0,
        blueShadowClipRatio: 0,
        redHighlightClipRatio: 0,
        greenHighlightClipRatio: 0,
        blueHighlightClipRatio: 0,
        sampleCount: 0
    )

    var hasHighlightClipping: Bool {
        max(redHighlightClipRatio, greenHighlightClipRatio, blueHighlightClipRatio) > 0.002
    }

    var hasShadowClipping: Bool {
        max(redShadowClipRatio, greenShadowClipRatio, blueShadowClipRatio) > 0.01
    }
}

final class ProfessionalMonitoringEngine {
    var onZebraUpdate: ((CGImage?) -> Void)?
    var onHistogramUpdate: ((HistogramSnapshot) -> Void)?

    private var lastZebraTime: CFTimeInterval = 0
    private var lastHistogramTime: CFTimeInterval = 0
    private let zebraInterval: CFTimeInterval = 0.12
    private let histogramInterval: CFTimeInterval = 0.14

    func process(
        pixelBuffer: CVPixelBuffer,
        zebraEnabled: Bool,
        zebraLevel: Double,
        histogramEnabled: Bool
    ) {
        let now = CACurrentMediaTime()
        let needsZebra = zebraEnabled && now - lastZebraTime >= zebraInterval
        let needsHistogram = histogramEnabled && now - lastHistogramTime >= histogramInterval

        guard needsZebra || needsHistogram else { return }
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        var zebraImage: CGImage?
        var histogram: HistogramSnapshot?

        if needsZebra {
            zebraImage = makeZebraImage(pixelBuffer: pixelBuffer, level: zebraLevel)
            lastZebraTime = now
        }

        if needsHistogram {
            histogram = makeHistogram(pixelBuffer: pixelBuffer)
            lastHistogramTime = now
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        if needsZebra {
            DispatchQueue.main.async { [weak self] in
                self?.onZebraUpdate?(zebraImage)
            }
        }

        if let histogram {
            DispatchQueue.main.async { [weak self] in
                self?.onHistogramUpdate?(histogram)
            }
        }
    }

    private func makeZebraImage(pixelBuffer: CVPixelBuffer, level: Double) -> CGImage? {
        guard let lumaBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }

        let sourceWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let sourceHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let luma = lumaBase.assumingMemoryBound(to: UInt8.self)

        let sampleStep = max(1, sourceWidth / 480)
        let outputWidth = max(2, sourceWidth / sampleStep)
        let outputHeight = max(2, sourceHeight / sampleStep)
        let threshold = UInt8(
            min(255, max(0, Int((min(max(level, 0), 100) / 100 * 255).rounded())))
        )

        var rgba = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        for outputY in 0..<outputHeight {
            let sourceY = min(sourceHeight - 1, outputY * sampleStep)
            let sourceRow = sourceY * sourceBytesPerRow

            for outputX in 0..<outputWidth {
                let sourceX = min(sourceWidth - 1, outputX * sampleStep)
                guard luma[sourceRow + sourceX] >= threshold else { continue }

                let stripePhase = (outputX + outputY) % 16
                guard stripePhase < 7 else { continue }

                let index = (outputY * outputWidth + outputX) * 4
                rgba[index] = 255
                rgba[index + 1] = 255
                rgba[index + 2] = 255
                rgba[index + 3] = 210
            }
        }

        return makeRGBAImage(rgba: rgba, width: outputWidth, height: outputHeight)
    }

    private func makeHistogram(pixelBuffer: CVPixelBuffer) -> HistogramSnapshot {
        guard let lumaBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return .empty
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let luma = lumaBase.assumingMemoryBound(to: UInt8.self)

        let hasChroma = CVPixelBufferGetPlaneCount(pixelBuffer) > 1
        let chromaBase = hasChroma ? CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) : nil
        let chromaBytesPerRow = hasChroma ? CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) : 0
        let chromaHeight = hasChroma ? CVPixelBufferGetHeightOfPlane(pixelBuffer, 1) : 0
        let chroma = chromaBase?.assumingMemoryBound(to: UInt8.self)

        var redCounts = [Int](repeating: 0, count: 256)
        var greenCounts = [Int](repeating: 0, count: 256)
        var blueCounts = [Int](repeating: 0, count: 256)
        var lumaCounts = [Int](repeating: 0, count: 256)

        let sampleStep = max(2, width / 220)
        var sampleCount = 0

        var y = 0
        while y < height {
            let lumaRow = y * lumaBytesPerRow
            var x = 0

            while x < width {
                let yValue = Int(luma[lumaRow + x])
                let rgb: (Int, Int, Int)

                if let chroma, chromaHeight > 0, chromaBytesPerRow >= 2 {
                    let chromaY = min(chromaHeight - 1, y / 2)
                    let pairOffset = min(max(0, chromaBytesPerRow - 2), (x / 2) * 2)
                    let chromaRow = chromaY * chromaBytesPerRow
                    let cb = Double(Int(chroma[chromaRow + pairOffset]) - 128)
                    let cr = Double(Int(chroma[chromaRow + pairOffset + 1]) - 128)
                    let yf = Double(yValue)

                    rgb = (
                        clampByte(yf + 1.5748 * cr),
                        clampByte(yf - 0.1873 * cb - 0.4681 * cr),
                        clampByte(yf + 1.8556 * cb)
                    )
                } else {
                    rgb = (yValue, yValue, yValue)
                }

                redCounts[rgb.0] += 1
                greenCounts[rgb.1] += 1
                blueCounts[rgb.2] += 1
                lumaCounts[yValue] += 1
                sampleCount += 1
                x += sampleStep
            }

            y += sampleStep
        }

        guard sampleCount > 0 else { return .empty }

        let globalMaximum = max(
            1,
            redCounts.max() ?? 1,
            greenCounts.max() ?? 1,
            blueCounts.max() ?? 1,
            lumaCounts.max() ?? 1
        )

        func normalize(_ values: [Int]) -> [Double] {
            values.map { Double($0) / Double(globalMaximum) }
        }

        func ratio(_ values: [Int], _ range: ClosedRange<Int>) -> Double {
            Double(range.reduce(0) { $0 + values[$1] }) / Double(sampleCount)
        }

        return HistogramSnapshot(
            red: normalize(redCounts),
            green: normalize(greenCounts),
            blue: normalize(blueCounts),
            luma: normalize(lumaCounts),
            redShadowClipRatio: ratio(redCounts, 0...2),
            greenShadowClipRatio: ratio(greenCounts, 0...2),
            blueShadowClipRatio: ratio(blueCounts, 0...2),
            redHighlightClipRatio: ratio(redCounts, 253...255),
            greenHighlightClipRatio: ratio(greenCounts, 253...255),
            blueHighlightClipRatio: ratio(blueCounts, 253...255),
            sampleCount: sampleCount
        )
    }

    private func clampByte(_ value: Double) -> Int {
        min(255, max(0, Int(value.rounded())))
    }

    private func makeRGBAImage(rgba: [UInt8], width: Int, height: Int) -> CGImage? {
        let data = Data(rgba)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
