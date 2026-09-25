import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Vision

final class PostShotAnalyzer {
    func analyze(
        data: Data,
        sceneHint: PhotoCategory?
    ) throws -> PostShotAnalysisResult {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(
                domain: "CapturePilot.PostShotAnalyzer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The image could not be decoded."]
            )
        }

        let classifications = classify(image)
        let faceQuality = detectFaceQuality(image)
        let saliencyCenter = detectSaliencyCenter(image)
        let pixelMetrics = samplePixels(image)

        let category = resolveCategory(
            sceneHint: sceneHint,
            classifications: classifications,
            hasFace: faceQuality != nil,
            metrics: pixelMetrics
        )

        let aesthetics: Double?
        let utility: Bool
        if #available(iOS 18.0, *) {
            let result = aestheticsScore(image)
            aesthetics = result.score
            utility = result.isUtility
        } else {
            aesthetics = nil
            utility = false
        }

        let exposure = exposureScore(metrics: pixelMetrics)
        let composition = compositionScore(center: saliencyCenter)
        let detail = min(100, max(0, pixelMetrics.edgeEnergy * 260))

        var weighted: [(Double, Double)] = [
            (exposure, 0.34),
            (composition, 0.38),
            (detail, 0.28)
        ]

        if let faceQuality, category == .portrait {
            weighted = weighted.map { ($0.0, $0.1 * 0.86) }
            weighted.append((faceQuality, 0.14))
        }

        var overall = weighted.reduce(0) { $0 + $1.0 * $1.1 }
        if utility { overall -= 4 }
        overall = min(100, max(0, overall))

        let score = CoachScoreBreakdown(
            overall: overall,
            aesthetics: aesthetics,
            exposure: exposure,
            composition: composition,
            detail: detail,
            portraitQuality: faceQuality
        )

        let recommendations = buildRecommendations(
            category: category,
            metrics: pixelMetrics,
            saliencyCenter: saliencyCenter,
            faceQuality: faceQuality,
            score: score
        )

        let tags = classifications.prefix(6).map {
            $0.identifier.replacingOccurrences(of: "_", with: " ")
        }

        guard let thumbnailData = makeThumbnailData(source: source) else {
            throw NSError(
                domain: "CapturePilot.PostShotAnalyzer",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "The ranking thumbnail could not be created."]
            )
        }

        return PostShotAnalysisResult(
            category: category,
            score: score,
            recommendations: recommendations,
            tags: tags,
            thumbnailData: thumbnailData,
            usedVisionAesthetics: aesthetics != nil
        )
    }

    static func fingerprint(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func classify(_ image: CGImage) -> [VNClassificationObservation] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            return Array((request.results ?? []).prefix(12))
        } catch {
            return []
        }
    }

    private func detectFaceQuality(_ image: CGImage) -> Double? {
        let request = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            let values = (request.results ?? []).compactMap {
                $0.faceCaptureQuality.map(Double.init)
            }
            guard let best = values.max() else { return nil }
            return min(100, max(0, best * 100))
        } catch {
            return nil
        }
    }

    private func detectSaliencyCenter(_ image: CGImage) -> CGPoint? {
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let box = request.results?.first?.salientObjects?.first?.boundingBox else {
                return nil
            }
            return CGPoint(x: box.midX, y: box.midY)
        } catch {
            return nil
        }
    }

    @available(iOS 18.0, *)
    private func aestheticsScore(_ image: CGImage) -> (score: Double?, isUtility: Bool) {
        let request = VNCalculateImageAestheticsScoresRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                return (nil, false)
            }

            let normalized = (Double(observation.overallScore) + 1) * 50
            return (min(100, max(0, normalized)), observation.isUtility)
        } catch {
            return (nil, false)
        }
    }

    private struct PixelMetrics {
        let averageLuma: Double
        let highlightRatio: Double
        let shadowRatio: Double
        let edgeEnergy: Double
    }

    private func samplePixels(_ image: CGImage) -> PixelMetrics {
        let width = 128
        let height = 128
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return PixelMetrics(
                averageLuma: 0.5,
                highlightRatio: 0,
                shadowRatio: 0,
                edgeEnergy: 0.25
            )
        }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let count = Double(pixels.count)
        let sum = pixels.reduce(0) { $0 + Int($1) }
        let highlights = pixels.filter { $0 >= 248 }.count
        let shadows = pixels.filter { $0 <= 14 }.count

        var edgeTotal = 0.0
        var edgeCount = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = y * width + x
                let horizontal = abs(Int(pixels[i + 1]) - Int(pixels[i - 1]))
                let vertical = abs(Int(pixels[i + width]) - Int(pixels[i - width]))
                edgeTotal += Double(horizontal + vertical) / 510.0
                edgeCount += 1
            }
        }

        return PixelMetrics(
            averageLuma: Double(sum) / count / 255.0,
            highlightRatio: Double(highlights) / count,
            shadowRatio: Double(shadows) / count,
            edgeEnergy: edgeCount > 0 ? edgeTotal / Double(edgeCount) : 0
        )
    }

    private func exposureScore(metrics: PixelMetrics) -> Double {
        let midPenalty = abs(metrics.averageLuma - 0.50) * 82
        let highlightPenalty = min(42, metrics.highlightRatio * 360)
        let shadowPenalty = min(34, metrics.shadowRatio * 180)
        return min(100, max(0, 100 - midPenalty - highlightPenalty - shadowPenalty))
    }

    private func compositionScore(center: CGPoint?) -> Double {
        guard let center else { return 58 }

        let points = [
            CGPoint(x: 1.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 1.0 / 3.0, y: 2.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 2.0 / 3.0)
        ]

        let nearest = points.map {
            hypot(center.x - $0.x, center.y - $0.y)
        }.min() ?? 0.5

        let thirds = max(0, 100 - nearest * 220)
        let centerDistance = hypot(center.x - 0.5, center.y - 0.5)
        let centered = max(0, 84 - centerDistance * 150)

        return min(100, max(thirds, centered))
    }

    private func resolveCategory(
        sceneHint: PhotoCategory?,
        classifications: [VNClassificationObservation],
        hasFace: Bool,
        metrics: PixelMetrics
    ) -> PhotoCategory {
        if let sceneHint, sceneHint != .general {
            return sceneHint
        }

        if hasFace { return .portrait }
        if metrics.averageLuma < 0.18 { return .night }

        let identifiers = classifications.prefix(8)
            .map { $0.identifier.lowercased() }
            .joined(separator: " ")

        func contains(_ words: [String]) -> Bool {
            words.contains { identifiers.contains($0) }
        }

        if contains(["car", "vehicle", "automobile", "truck", "motorcycle"]) {
            return .automotive
        }
        if contains(["building", "architecture", "tower", "bridge", "church", "house"]) {
            return .architecture
        }
        if contains(["mountain", "landscape", "seashore", "valley", "lake", "forest"]) {
            return .landscape
        }
        if contains(["insect", "flower", "plant", "spider", "butterfly", "macro"]) {
            return .macro
        }
        if contains(["street", "traffic", "sidewalk", "pedestrian"]) {
            return .street
        }

        return .general
    }

    private func buildRecommendations(
        category: PhotoCategory,
        metrics: PixelMetrics,
        saliencyCenter: CGPoint?,
        faceQuality: Double?,
        score: CoachScoreBreakdown
    ) -> [RankingRecommendation] {
        var result: [RankingRecommendation] = []

        if metrics.highlightRatio > 0.035 || metrics.averageLuma > 0.78 {
            result.append(.lowerHighlights)
        }
        if metrics.averageLuma < 0.17 && category != .night {
            result.append(.raiseExposure)
        }
        if score.detail < 48 {
            result.append(.stabilizeAndRefocus)
        }

        if let aesthetics = score.aesthetics, aesthetics < 45 {
            result.append(.tryDifferentViewpoint)
        }

        if let center = saliencyCenter {
            let nearestThird = [
                CGPoint(x: 1.0 / 3.0, y: 1.0 / 3.0),
                CGPoint(x: 2.0 / 3.0, y: 1.0 / 3.0),
                CGPoint(x: 1.0 / 3.0, y: 2.0 / 3.0),
                CGPoint(x: 2.0 / 3.0, y: 2.0 / 3.0)
            ].map { hypot(center.x - $0.x, center.y - $0.y) }.min() ?? 0

            if nearestThird > 0.17 && hypot(center.x - 0.5, center.y - 0.5) > 0.16 {
                result.append(.moveTowardStrongPoint)
            }
        }

        if category == .portrait, let faceQuality, faceQuality < 55 {
            result.append(.improvePortraitQuality)
        }

        switch category {
        case .architecture:
            result.append(score.composition < 72 ? .strengthenSymmetry : .useLeadingLines)
        case .automotive:
            result.append(.lowerCameraAngle)
        case .macro:
            result.append(.useNegativeSpace)
        case .street:
            result.append(.waitForSeparation)
        case .landscape:
            result.append(.addForegroundLayer)
        case .night:
            result.append(.protectNightHighlights)
        case .portrait:
            result.append(.simplifyBackground)
        case .general:
            result.append(.tryDifferentViewpoint)
        }

        var unique: [RankingRecommendation] = []
        for item in result where !unique.contains(item) {
            unique.append(item)
            if unique.count == 4 { break }
        }
        return unique
    }

    private func makeThumbnailData(source: CGImageSource) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 720,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(
            destination,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
