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
        ([redHighlightClipRatio, greenHighlightClipRatio, blueHighlightClipRatio].max() ?? 0) > 0.002
    }

    var hasShadowClipping: Bool {
        ([redShadowClipRatio, greenShadowClipRatio, blueShadowClipRatio].max() ?? 0) > 0.01
    }
}

final class ProfessionalMonitoringEngine {
    var onZebraUpdate: ((CGImage?) -> Void)?
    var onHistogramUpdate: ((HistogramSnapshot) -> Void)?
    var onFalseColorUpdate: ((CGImage?) -> Void)?
    var onWaveformUpdate: ((CGImage?) -> Void)?
    var onRGBParadeUpdate: ((CGImage?) -> Void)?
    var onVectorscopeUpdate: ((CGImage?) -> Void)?

    private var lastZebraTime: CFTimeInterval = 0
    private var lastHistogramTime: CFTimeInterval = 0
    private var lastFalseColorTime: CFTimeInterval = 0
    private var lastWaveformTime: CFTimeInterval = 0
    private var lastRGBParadeTime: CFTimeInterval = 0
    private var lastVectorscopeTime: CFTimeInterval = 0

    private let zebraInterval: CFTimeInterval = 0.12
    private let histogramInterval: CFTimeInterval = 0.14
    private let falseColorInterval: CFTimeInterval = 0.13
    private let scopeInterval: CFTimeInterval = 0.16

    func process(
        pixelBuffer: CVPixelBuffer,
        zebraEnabled: Bool,
        zebraLevel: Double,
        zebraLowLevel: Double,
        dualZebraEnabled: Bool,
        histogramEnabled: Bool,
        falseColorEnabled: Bool,
        waveformEnabled: Bool,
        rgbParadeEnabled: Bool,
        vectorscopeEnabled: Bool
    ) {
        let now = CACurrentMediaTime()

        let needsZebra = zebraEnabled && now - lastZebraTime >= zebraInterval
        let needsHistogram = histogramEnabled && now - lastHistogramTime >= histogramInterval
        let needsFalseColor =
            falseColorEnabled && now - lastFalseColorTime >= falseColorInterval
        let needsWaveform =
            waveformEnabled && now - lastWaveformTime >= scopeInterval
        let needsRGBParade =
            rgbParadeEnabled && now - lastRGBParadeTime >= scopeInterval
        let needsVectorscope =
            vectorscopeEnabled && now - lastVectorscopeTime >= scopeInterval

        guard needsZebra
                || needsHistogram
                || needsFalseColor
                || needsWaveform
                || needsRGBParade
                || needsVectorscope else { return }

        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        var zebraImage: CGImage?
        var histogram: HistogramSnapshot?
        var falseColorImage: CGImage?
        var waveformImage: CGImage?
        var paradeImage: CGImage?
        var vectorscopeImage: CGImage?

        if needsZebra {
            zebraImage = makeZebraImage(
                pixelBuffer: pixelBuffer,
                highLevel: zebraLevel,
                lowLevel: zebraLowLevel,
                dualEnabled: dualZebraEnabled
            )
            lastZebraTime = now
        }

        if needsHistogram {
            histogram = makeHistogram(pixelBuffer: pixelBuffer)
            lastHistogramTime = now
        }

        if needsFalseColor {
            falseColorImage = makeFalseColorImage(pixelBuffer: pixelBuffer)
            lastFalseColorTime = now
        }

        if needsWaveform {
            waveformImage = makeWaveformImage(pixelBuffer: pixelBuffer)
            lastWaveformTime = now
        }

        if needsRGBParade {
            paradeImage = makeRGBParadeImage(pixelBuffer: pixelBuffer)
            lastRGBParadeTime = now
        }

        if needsVectorscope {
            vectorscopeImage = makeVectorscopeImage(pixelBuffer: pixelBuffer)
            lastVectorscopeTime = now
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

        if needsFalseColor {
            DispatchQueue.main.async { [weak self] in
                self?.onFalseColorUpdate?(falseColorImage)
            }
        }

        if needsWaveform {
            DispatchQueue.main.async { [weak self] in
                self?.onWaveformUpdate?(waveformImage)
            }
        }

        if needsRGBParade {
            DispatchQueue.main.async { [weak self] in
                self?.onRGBParadeUpdate?(paradeImage)
            }
        }

        if needsVectorscope {
            DispatchQueue.main.async { [weak self] in
                self?.onVectorscopeUpdate?(vectorscopeImage)
            }
        }
    }

    private func makeZebraImage(
        pixelBuffer: CVPixelBuffer,
        highLevel: Double,
        lowLevel: Double,
        dualEnabled: Bool
    ) -> CGImage? {
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
        let highThreshold = UInt8(
            min(255, max(0, Int((min(max(highLevel, 0), 100) / 100 * 255).rounded())))
        )
        let lowThreshold = UInt8(
            min(
                Int(highThreshold),
                max(0, Int((min(max(lowLevel, 0), 100) / 100 * 255).rounded()))
            )
        )

        var rgba = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        for outputY in 0..<outputHeight {
            let sourceY = min(sourceHeight - 1, outputY * sampleStep)
            let sourceRow = sourceY * sourceBytesPerRow

            for outputX in 0..<outputWidth {
                let sourceX = min(sourceWidth - 1, outputX * sampleStep)
                let value = luma[sourceRow + sourceX]
                let index = (outputY * outputWidth + outputX) * 4

                if value >= highThreshold {
                    let stripePhase = (outputX + outputY) % 14
                    guard stripePhase < 7 else { continue }
                    rgba[index] = 255
                    rgba[index + 1] = 70
                    rgba[index + 2] = 55
                    rgba[index + 3] = 220
                } else if dualEnabled, value >= lowThreshold {
                    let stripePhase = (outputX - outputY + 1024) % 16
                    guard stripePhase < 7 else { continue }
                    rgba[index] = 255
                    rgba[index + 1] = 230
                    rgba[index + 2] = 70
                    rgba[index + 3] = 205
                }
            }
        }

        return makeRGBAImage(rgba: rgba, width: outputWidth, height: outputHeight)
    }

    private func makeFalseColorImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
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
        var rgba = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        for outputY in 0..<outputHeight {
            let sourceY = min(sourceHeight - 1, outputY * sampleStep)
            let row = sourceY * sourceBytesPerRow

            for outputX in 0..<outputWidth {
                let sourceX = min(sourceWidth - 1, outputX * sampleStep)
                let value = Double(luma[row + sourceX]) / 255.0
                let color = falseColor(for: value)
                let index = (outputY * outputWidth + outputX) * 4

                rgba[index] = color.0
                rgba[index + 1] = color.1
                rgba[index + 2] = color.2
                rgba[index + 3] = 224
            }
        }

        return makeRGBAImage(rgba: rgba, width: outputWidth, height: outputHeight)
    }

    private func falseColor(for value: Double) -> (UInt8, UInt8, UInt8) {
        switch value {
        case ..<0.05:
            return (90, 25, 140)
        case ..<0.18:
            return (30, 75, 205)
        case ..<0.32:
            return (0, 175, 220)
        case ..<0.48:
            return (25, 205, 120)
        case ..<0.62:
            return (130, 130, 130)
        case ..<0.74:
            return (245, 125, 175)
        case ..<0.88:
            return (255, 215, 30)
        case ..<0.97:
            return (255, 120, 20)
        default:
            return (255, 25, 25)
        }
    }

    private func makeHistogram(pixelBuffer: CVPixelBuffer) -> HistogramSnapshot {
        guard let planes = planeAccess(for: pixelBuffer) else { return .empty }

        var redCounts = [Int](repeating: 0, count: 256)
        var greenCounts = [Int](repeating: 0, count: 256)
        var blueCounts = [Int](repeating: 0, count: 256)
        var lumaCounts = [Int](repeating: 0, count: 256)

        let sampleStep = max(2, planes.width / 220)
        var sampleCount = 0

        var y = 0
        while y < planes.height {
            var x = 0
            while x < planes.width {
                let yValue = Int(planes.luma[y * planes.lumaBytesPerRow + x])
                let rgb = rgbValues(
                    x: x,
                    y: y,
                    yValue: yValue,
                    planes: planes
                )

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

        let globalMaximum = [
            1,
            redCounts.max() ?? 1,
            greenCounts.max() ?? 1,
            blueCounts.max() ?? 1,
            lumaCounts.max() ?? 1
        ].max() ?? 1

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

    private func makeWaveformImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
        guard let planes = planeAccess(for: pixelBuffer) else { return nil }

        let outputWidth = 256
        let outputHeight = 128
        var density = [UInt16](repeating: 0, count: outputWidth * outputHeight)
        let sampleStep = max(2, planes.width / 360)

        var y = 0
        while y < planes.height {
            var x = 0
            while x < planes.width {
                let lumaValue = Int(planes.luma[y * planes.lumaBytesPerRow + x])
                let scopeX = min(
                    outputWidth - 1,
                    Int(Double(x) / Double(max(1, planes.width - 1)) * Double(outputWidth - 1))
                )
                let scopeY = min(
                    outputHeight - 1,
                    max(
                        0,
                        outputHeight - 1
                            - Int(Double(lumaValue) / 255.0 * Double(outputHeight - 1))
                    )
                )
                let index = scopeY * outputWidth + scopeX
                if density[index] < UInt16.max { density[index] += 1 }
                x += sampleStep
            }
            y += sampleStep
        }

        return makeDensityImage(
            density: density,
            width: outputWidth,
            height: outputHeight,
            channel: .luma
        )
    }

    private func makeRGBParadeImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
        guard let planes = planeAccess(for: pixelBuffer) else { return nil }

        let panelWidth = 96
        let outputWidth = panelWidth * 3
        let outputHeight = 128
        var redDensity = [UInt16](repeating: 0, count: panelWidth * outputHeight)
        var greenDensity = [UInt16](repeating: 0, count: panelWidth * outputHeight)
        var blueDensity = [UInt16](repeating: 0, count: panelWidth * outputHeight)
        let sampleStep = max(2, planes.width / 300)

        var y = 0
        while y < planes.height {
            var x = 0
            while x < planes.width {
                let yValue = Int(planes.luma[y * planes.lumaBytesPerRow + x])
                let rgb = rgbValues(
                    x: x,
                    y: y,
                    yValue: yValue,
                    planes: planes
                )
                let panelX = min(
                    panelWidth - 1,
                    Int(Double(x) / Double(max(1, planes.width - 1)) * Double(panelWidth - 1))
                )

                accumulate(value: rgb.0, x: panelX, width: panelWidth, height: outputHeight, density: &redDensity)
                accumulate(value: rgb.1, x: panelX, width: panelWidth, height: outputHeight, density: &greenDensity)
                accumulate(value: rgb.2, x: panelX, width: panelWidth, height: outputHeight, density: &blueDensity)
                x += sampleStep
            }
            y += sampleStep
        }

        let redMax = max(1, Int(redDensity.max() ?? 1))
        let greenMax = max(1, Int(greenDensity.max() ?? 1))
        let blueMax = max(1, Int(blueDensity.max() ?? 1))
        var rgba = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        for y in 0..<outputHeight {
            for x in 0..<panelWidth {
                writeDensityPixel(
                    density: Int(redDensity[y * panelWidth + x]),
                    maximum: redMax,
                    rgba: &rgba,
                    index: (y * outputWidth + x) * 4,
                    color: (255, 70, 70)
                )
                writeDensityPixel(
                    density: Int(greenDensity[y * panelWidth + x]),
                    maximum: greenMax,
                    rgba: &rgba,
                    index: (y * outputWidth + panelWidth + x) * 4,
                    color: (80, 255, 110)
                )
                writeDensityPixel(
                    density: Int(blueDensity[y * panelWidth + x]),
                    maximum: blueMax,
                    rgba: &rgba,
                    index: (y * outputWidth + panelWidth * 2 + x) * 4,
                    color: (80, 135, 255)
                )
            }
        }

        return makeRGBAImage(rgba: rgba, width: outputWidth, height: outputHeight)
    }

    private func makeVectorscopeImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
        guard let planes = planeAccess(for: pixelBuffer),
              let chroma = planes.chroma,
              planes.chromaBytesPerRow >= 2,
              planes.chromaHeight > 0 else { return nil }

        let size = 192
        var density = [UInt16](repeating: 0, count: size * size)
        let sampleStep = max(2, planes.width / 260)

        var y = 0
        while y < planes.height {
            var x = 0
            while x < planes.width {
                let chromaY = min(planes.chromaHeight - 1, y / 2)
                let pairOffset = min(
                    max(0, planes.chromaBytesPerRow - 2),
                    (x / 2) * 2
                )
                let row = chromaY * planes.chromaBytesPerRow
                let cb = Int(chroma[row + pairOffset])
                let cr = Int(chroma[row + pairOffset + 1])

                let scopeX = min(
                    size - 1,
                    max(0, Int(Double(cb) / 255.0 * Double(size - 1)))
                )
                let scopeY = min(
                    size - 1,
                    max(0, size - 1 - Int(Double(cr) / 255.0 * Double(size - 1)))
                )
                let index = scopeY * size + scopeX
                if density[index] < UInt16.max { density[index] += 1 }
                x += sampleStep
            }
            y += sampleStep
        }

        return makeDensityImage(
            density: density,
            width: size,
            height: size,
            channel: .vectorscope
        )
    }

    private enum DensityChannel {
        case luma
        case vectorscope
    }

    private func makeDensityImage(
        density: [UInt16],
        width: Int,
        height: Int,
        channel: DensityChannel
    ) -> CGImage? {
        let maximum = max(1, Int(density.max() ?? 1))
        var rgba = [UInt8](repeating: 0, count: width * height * 4)

        for index in density.indices {
            let count = Int(density[index])
            guard count > 0 else { continue }
            let normalized = sqrt(Double(count) / Double(maximum))
            let alpha = UInt8(min(255, max(35, Int(normalized * 255))))
            let pixel = index * 4

            switch channel {
            case .luma:
                rgba[pixel] = 225
                rgba[pixel + 1] = 245
                rgba[pixel + 2] = 225
            case .vectorscope:
                rgba[pixel] = 105
                rgba[pixel + 1] = 245
                rgba[pixel + 2] = 205
            }
            rgba[pixel + 3] = alpha
        }

        return makeRGBAImage(rgba: rgba, width: width, height: height)
    }

    private func accumulate(
        value: Int,
        x: Int,
        width: Int,
        height: Int,
        density: inout [UInt16]
    ) {
        let scopeY = min(
            height - 1,
            max(0, height - 1 - Int(Double(value) / 255.0 * Double(height - 1)))
        )
        let index = scopeY * width + x
        if density[index] < UInt16.max { density[index] += 1 }
    }

    private func writeDensityPixel(
        density: Int,
        maximum: Int,
        rgba: inout [UInt8],
        index: Int,
        color: (UInt8, UInt8, UInt8)
    ) {
        guard density > 0 else { return }
        let normalized = sqrt(Double(density) / Double(maximum))
        rgba[index] = color.0
        rgba[index + 1] = color.1
        rgba[index + 2] = color.2
        rgba[index + 3] = UInt8(min(255, max(35, Int(normalized * 255))))
    }

    private struct PlaneAccess {
        let width: Int
        let height: Int
        let luma: UnsafeMutablePointer<UInt8>
        let lumaBytesPerRow: Int
        let chroma: UnsafeMutablePointer<UInt8>?
        let chromaBytesPerRow: Int
        let chromaHeight: Int
    }

    private func planeAccess(for pixelBuffer: CVPixelBuffer) -> PlaneAccess? {
        guard let lumaBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let luma = lumaBase.assumingMemoryBound(to: UInt8.self)

        let hasChroma = CVPixelBufferGetPlaneCount(pixelBuffer) > 1
        let chromaBase = hasChroma
            ? CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
            : nil

        return PlaneAccess(
            width: width,
            height: height,
            luma: luma,
            lumaBytesPerRow: lumaBytesPerRow,
            chroma: chromaBase?.assumingMemoryBound(to: UInt8.self),
            chromaBytesPerRow:
                hasChroma
                ? CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
                : 0,
            chromaHeight:
                hasChroma
                ? CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
                : 0
        )
    }

    private func rgbValues(
        x: Int,
        y: Int,
        yValue: Int,
        planes: PlaneAccess
    ) -> (Int, Int, Int) {
        guard let chroma = planes.chroma,
              planes.chromaHeight > 0,
              planes.chromaBytesPerRow >= 2 else {
            return (yValue, yValue, yValue)
        }

        let chromaY = min(planes.chromaHeight - 1, y / 2)
        let pairOffset = min(
            max(0, planes.chromaBytesPerRow - 2),
            (x / 2) * 2
        )
        let row = chromaY * planes.chromaBytesPerRow
        let cb = Double(Int(chroma[row + pairOffset]) - 128)
        let cr = Double(Int(chroma[row + pairOffset + 1]) - 128)
        let yf = Double(yValue)

        return (
            clampByte(yf + 1.5748 * cr),
            clampByte(yf - 0.1873 * cb - 0.4681 * cr),
            clampByte(yf + 1.8556 * cb)
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
