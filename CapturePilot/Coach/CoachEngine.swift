import AVFoundation
import CoreGraphics
import QuartzCore
import Vision

final class CoachEngine {
    private var isProcessing = false
    private var lastProcessTime: CFTimeInterval = 0
    private let minimumInterval: CFTimeInterval = 0.28

    private var candidateMessage: LocalizedKey = .ready
    private var candidateCount = 0
    private var publishedMessage: LocalizedKey = .ready

    var onUpdate: ((CoachState) -> Void)?

    func process(
        sampleBuffer: CMSampleBuffer,
        intensity: AppSettings.CoachIntensity,
        scene: AppSettings.SceneCoach
    ) {
        let now = CACurrentMediaTime()
        guard now - lastProcessTime >= minimumInterval, !isProcessing else { return }
        lastProcessTime = now
        isProcessing = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }

        defer { isProcessing = false }

        var state = CoachState()
        analyzeLuminance(pixelBuffer, state: &state)

        let faceRequest = VNDetectFaceRectanglesRequest()
        let humanRequest = VNDetectHumanRectanglesRequest()
        humanRequest.upperBodyOnly = false
        let horizonRequest = VNDetectHorizonRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([faceRequest, humanRequest, horizonRequest, saliencyRequest])

            if let horizon = horizonRequest.results?.first as? VNHorizonObservation {
                state.horizonAngleDegrees = Double(horizon.angle) * 180 / .pi
            }

            if let face = faceRequest.results?.first {
                state.subjectRect = face.boundingBox
                state.hasPerson = true
                state.hasSubject = true
            } else if let human = humanRequest.results?.first {
                state.subjectRect = human.boundingBox
                state.hasPerson = true
                state.hasSubject = true
            }

            if let saliency = saliencyRequest.results?.first as? VNSaliencyImageObservation,
               let salient = saliency.salientObjects,
               let strongest = salient.max(by: { $0.confidence < $1.confidence }) {
                state.saliencyCenter = CGPoint(
                    x: strongest.boundingBox.midX,
                    y: strongest.boundingBox.midY
                )
                state.hasSubject = true
                if state.subjectRect == nil {
                    state.subjectRect = strongest.boundingBox
                }
            } else if let rect = state.subjectRect {
                state.saliencyCenter = CGPoint(x: rect.midX, y: rect.midY)
            }
        } catch {
            // Luminance and geometric analysis remain available for this frame.
        }

        analyzeComposition(pixelBuffer, state: &state)
        classifyCompositionPoints(state: &state)
        chooseGuidance(state: &state, intensity: intensity, scene: scene)
        stabilizeMessage(state: &state)

        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(state)
        }
    }

    private func chooseGuidance(
        state: inout CoachState,
        intensity: AppSettings.CoachIntensity,
        scene: AppSettings.SceneCoach
    ) {
        let horizonLimit: Double
        switch scene {
        case .architecture, .landscape:
            horizonLimit = intensity == .subtle ? 2.2 : 1.2
        default:
            horizonLimit = intensity == .subtle ? 3.5 : 2.0
        }

        if abs(state.horizonAngleDegrees) > horizonLimit {
            state.primaryMessage = .levelCamera
            state.secondaryMessage = state.highlightClipRatio > 0.05 ? .tooBright : nil
            state.severity = .caution
            return
        }

        if state.highlightClipRatio > 0.07 || state.averageLuma > 0.82 {
            state.primaryMessage = .tooBright
            state.severity = .caution
            return
        }

        if scene != .night,
           (state.shadowClipRatio > 0.32 || state.averageLuma < 0.16) {
            state.primaryMessage = .tooDark
            state.severity = .caution
            return
        }

        if scene == .night {
            if state.averageLuma < 0.07 {
                state.primaryMessage = .tooDark
                state.severity = .caution
                return
            }
            if state.detailScore < 0.12 {
                state.primaryMessage = .stabilizeCamera
                state.secondaryMessage = .protectHighlights
                state.severity = .neutral
                return
            }
        }

        guard intensity != .subtle else {
            state.primaryMessage = .ready
            state.severity = .neutral
            return
        }

        switch scene {
        case .portrait:
            if state.hasPerson,
               let subject = state.subjectRect,
               subject.maxY < 0.76 {
                state.primaryMessage = .reduceHeadroom
                state.secondaryMessage = state.isNearThird ? .subjectOnThird : nil
                return
            }
            applySubjectPlacementGuidance(state: &state)

        case .architecture:
            if state.symmetryScore > 0.86 {
                state.primaryMessage = .symmetryStrong
                state.secondaryMessage = state.vanishingPoint == nil ? nil : .vanishingPointFound
                state.severity = .positive
            } else if state.vanishingPoint != nil {
                state.primaryMessage = .vanishingPointFound
                state.secondaryMessage = .alignSymmetry
            } else {
                state.primaryMessage = .alignSymmetry
                state.secondaryMessage = state.leadingLinesScore > 0.35 ? .followLeadingLines : nil
            }

        case .automotive:
            if state.leadingLinesScore > 0.35 {
                state.primaryMessage = .followLeadingLines
                state.secondaryMessage = state.vanishingPoint == nil ? nil : .vanishingPointFound
            } else if state.negativeSpaceRatio > 0.60 {
                state.primaryMessage = .useNegativeSpace
                state.secondaryMessage = .subjectOnThird
            } else {
                applySubjectPlacementGuidance(state: &state)
            }

        case .macro:
            if state.detailScore < 0.14 {
                state.primaryMessage = .refineFocus
                state.secondaryMessage = .stabilizeCamera
            } else if state.isNearGoldenSpiralPoint {
                state.primaryMessage = .goldenSpiralBalance
                state.severity = .positive
            } else {
                state.primaryMessage = .moveTowardGoldenPoint
                state.secondaryMessage = .refineFocus
            }

        case .street:
            if state.leadingLinesScore > 0.32 {
                state.primaryMessage = .followLeadingLines
                state.secondaryMessage = .useNegativeSpace
            } else if state.negativeSpaceRatio > 0.58 {
                state.primaryMessage = .useNegativeSpace
                state.secondaryMessage = state.isNearThird ? .subjectOnThird : nil
            } else {
                applySubjectPlacementGuidance(state: &state)
            }

        case .landscape:
            if state.isNearGoldenTrianglePoint {
                state.primaryMessage = .goldenTriangleBalance
                state.secondaryMessage = state.leadingLinesScore > 0.30 ? .followLeadingLines : nil
                state.severity = .positive
            } else if state.leadingLinesScore > 0.34 {
                state.primaryMessage = .followLeadingLines
                state.secondaryMessage = .goldenTriangleBalance
            } else if state.negativeSpaceRatio > 0.60 {
                state.primaryMessage = .useNegativeSpace
            } else {
                applySubjectPlacementGuidance(state: &state)
            }

        case .night:
            if state.leadingLinesScore > 0.32 {
                state.primaryMessage = .followLeadingLines
                state.secondaryMessage = .stabilizeCamera
            } else {
                state.primaryMessage = .stabilizeCamera
                state.secondaryMessage = .protectHighlights
            }

        case .general:
            if state.symmetryScore > 0.90 {
                state.primaryMessage = .symmetryStrong
                state.severity = .positive
            } else if state.leadingLinesScore > 0.42 {
                state.primaryMessage = .followLeadingLines
                state.secondaryMessage = state.vanishingPoint == nil ? nil : .vanishingPointFound
            } else {
                applySubjectPlacementGuidance(state: &state)
            }
        }
    }

    private func applySubjectPlacementGuidance(state: inout CoachState) {
        guard state.hasSubject else {
            state.primaryMessage = .ready
            state.severity = .neutral
            return
        }

        if state.isNearThird {
            state.primaryMessage = .subjectOnThird
            state.secondaryMessage = .goodBalance
            state.severity = .positive
            return
        }

        let point = state.saliencyCenter
        let thirds = [
            CGPoint(x: 1.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 1.0 / 3.0, y: 2.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 2.0 / 3.0)
        ]
        let nearest = thirds.min { distance(point, $0) < distance(point, $1) } ?? thirds[0]
        let dx = nearest.x - point.x
        let dy = nearest.y - point.y

        if abs(dx) > abs(dy) {
            state.primaryMessage = dx > 0 ? .moveRight : .moveLeft
        } else {
            state.primaryMessage = dy > 0 ? .moveUp : .moveDown
        }
        state.secondaryMessage = .goodBalance
        state.severity = .neutral
    }

    private func classifyCompositionPoints(state: inout CoachState) {
        let point = state.saliencyCenter
        let thirds = [
            CGPoint(x: 1.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 1.0 / 3.0),
            CGPoint(x: 1.0 / 3.0, y: 2.0 / 3.0),
            CGPoint(x: 2.0 / 3.0, y: 2.0 / 3.0)
        ]
        state.isNearThird = thirds.contains { distance(point, $0) < 0.115 }

        let goldenPoints = [
            CGPoint(x: 0.382, y: 0.382),
            CGPoint(x: 0.618, y: 0.382),
            CGPoint(x: 0.382, y: 0.618),
            CGPoint(x: 0.618, y: 0.618)
        ]
        state.isNearGoldenSpiralPoint = goldenPoints.contains {
            distance(point, $0) < 0.105
        }

        let trianglePoints = [
            CGPoint(x: 0.25, y: 0.25),
            CGPoint(x: 0.75, y: 0.75),
            CGPoint(x: 0.25, y: 0.75),
            CGPoint(x: 0.75, y: 0.25)
        ]
        state.isNearGoldenTrianglePoint = trianglePoints.contains {
            distance(point, $0) < 0.13
        }

        if let rect = state.subjectRect {
            state.negativeSpaceRatio = max(0, min(1, 1 - Double(rect.width * rect.height)))
        }
    }

    private func stabilizeMessage(state: inout CoachState) {
        if state.primaryMessage == candidateMessage {
            candidateCount += 1
        } else {
            candidateMessage = state.primaryMessage
            candidateCount = 1
        }

        guard candidateCount >= 2 else {
            state.primaryMessage = publishedMessage
            state.secondaryMessage = nil
            return
        }

        publishedMessage = state.primaryMessage
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func analyzeLuminance(_ pixelBuffer: CVPixelBuffer, state: inout CoachState) {
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let pointer = base.assumingMemoryBound(to: UInt8.self)

        let stepX = max(1, width / 80)
        let stepY = max(1, height / 120)
        var sum = 0.0
        var count = 0
        var highlights = 0
        var shadows = 0

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let luma = Int(pointer[y * bytesPerRow + x])
                sum += Double(luma) / 255.0
                if luma >= 248 { highlights += 1 }
                if luma <= 14 { shadows += 1 }
                count += 1
                x += stepX
            }
            y += stepY
        }

        guard count > 0 else { return }
        state.averageLuma = sum / Double(count)
        state.highlightClipRatio = Double(highlights) / Double(count)
        state.shadowClipRatio = Double(shadows) / Double(count)
    }

    private struct HoughLine {
        let theta: Double
        let rho: Double
        let strength: Double
    }

    private func analyzeComposition(_ pixelBuffer: CVPixelBuffer, state: inout CoachState) {
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }

        let sourceWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let sourceHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let sourceStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let pointer = base.assumingMemoryBound(to: UInt8.self)

        let width = 64
        let height = 48
        var grid = Array(repeating: 0.0, count: width * height)

        for y in 0..<height {
            let sourceY = min(sourceHeight - 1, y * sourceHeight / height)
            for x in 0..<width {
                let sourceX = min(sourceWidth - 1, x * sourceWidth / width)
                grid[y * width + x] =
                    Double(pointer[sourceY * sourceStride + sourceX]) / 255.0
            }
        }

        var symmetryDifference = 0.0
        var symmetrySamples = 0
        for y in 0..<height {
            for x in 0..<(width / 2) {
                let a = grid[y * width + x]
                let b = grid[y * width + (width - 1 - x)]
                symmetryDifference += abs(a - b)
                symmetrySamples += 1
            }
        }
        if symmetrySamples > 0 {
            state.symmetryScore = max(
                0,
                min(1, 1 - symmetryDifference / Double(symmetrySamples))
            )
        }

        let thetaBins = 36
        let rhoBins = 64
        let maxRho = sqrt(0.5)
        var accumulator = Array(repeating: 0.0, count: thetaBins * rhoBins)
        var edgeEnergy = 0.0
        var edgeCount = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let gx = grid[y * width + x + 1] - grid[y * width + x - 1]
                let gy = grid[(y + 1) * width + x] - grid[(y - 1) * width + x]
                let magnitude = hypot(gx, gy)
                guard magnitude > 0.12 else { continue }

                edgeEnergy += magnitude
                edgeCount += 1

                var theta = atan2(gy, gx)
                if theta < 0 { theta += .pi }
                if theta >= .pi { theta -= .pi }

                let thetaIndex = min(
                    thetaBins - 1,
                    max(0, Int(theta / .pi * Double(thetaBins)))
                )
                let nx = Double(x) / Double(width - 1) - 0.5
                let ny = Double(y) / Double(height - 1) - 0.5
                let rho = nx * cos(theta) + ny * sin(theta)
                let normalizedRho = (rho + maxRho) / (2 * maxRho)
                let rhoIndex = min(
                    rhoBins - 1,
                    max(0, Int(normalizedRho * Double(rhoBins - 1)))
                )
                accumulator[thetaIndex * rhoBins + rhoIndex] += magnitude
            }
        }

        state.detailScore = min(
            1,
            edgeEnergy / max(1, Double((width - 2) * (height - 2))) * 12
        )

        var candidates: [HoughLine] = []
        let peak = accumulator.max() ?? 0
        guard peak > 0 else {
            state.negativeSpaceRatio = state.subjectRect.map {
                max(0, min(1, 1 - Double($0.width * $0.height)))
            } ?? 1
            return
        }

        var mutable = accumulator
        for _ in 0..<5 {
            guard let maxIndex = mutable.indices.max(by: { mutable[$0] < mutable[$1] }),
                  mutable[maxIndex] > peak * 0.24 else { break }

            let thetaIndex = maxIndex / rhoBins
            let rhoIndex = maxIndex % rhoBins
            let theta = (Double(thetaIndex) + 0.5) / Double(thetaBins) * .pi
            let rho = Double(rhoIndex) / Double(rhoBins - 1) * 2 * maxRho - maxRho
            let strength = mutable[maxIndex] / peak
            candidates.append(HoughLine(theta: theta, rho: rho, strength: strength))

            for dt in -2...2 {
                for dr in -3...3 {
                    var t = thetaIndex + dt
                    if t < 0 { t += thetaBins }
                    if t >= thetaBins { t -= thetaBins }
                    let r = rhoIndex + dr
                    if r >= 0, r < rhoBins {
                        mutable[t * rhoBins + r] = 0
                    }
                }
            }
        }

        state.leadingLines = candidates.compactMap(lineSegment(from:)).prefix(4).map { $0 }

        var bestPairScore = 0.0
        var bestVanishingPoint: CGPoint?

        for i in candidates.indices {
            for j in candidates.indices where j > i {
                let a = candidates[i]
                let b = candidates[j]
                let separation = angularSeparation(a.theta, b.theta)
                guard separation > (.pi / 10), separation < (.pi * 0.9) else { continue }
                guard let point = intersection(a, b) else { continue }
                guard (-0.35...1.35).contains(point.x),
                      (-0.35...1.35).contains(point.y) else { continue }

                let score = min(a.strength, b.strength)
                if score > bestPairScore {
                    bestPairScore = score
                    bestVanishingPoint = CGPoint(x: point.x, y: 1 - point.y)
                }
            }
        }

        state.leadingLinesScore = min(1, bestPairScore)
        state.vanishingPoint = bestVanishingPoint

        if state.subjectRect == nil {
            let density = Double(edgeCount) / Double((width - 2) * (height - 2))
            state.negativeSpaceRatio = max(0, min(1, 1 - density * 2.2))
        }
    }

    private func angularSeparation(_ a: Double, _ b: Double) -> Double {
        let difference = abs(a - b)
        return min(difference, .pi - difference)
    }

    private func intersection(_ a: HoughLine, _ b: HoughLine) -> CGPoint? {
        let a1 = cos(a.theta)
        let b1 = sin(a.theta)
        let a2 = cos(b.theta)
        let b2 = sin(b.theta)
        let determinant = a1 * b2 - a2 * b1
        guard abs(determinant) > 0.001 else { return nil }

        let x = (a.rho * b2 - b.rho * b1) / determinant
        let y = (a1 * b.rho - a2 * a.rho) / determinant
        return CGPoint(x: x + 0.5, y: y + 0.5)
    }

    private func lineSegment(from line: HoughLine) -> NormalizedLine? {
        let c = cos(line.theta)
        let s = sin(line.theta)
        var points: [CGPoint] = []

        if abs(s) > 0.0001 {
            for x in [-0.5, 0.5] {
                let y = (line.rho - x * c) / s
                if (-0.5...0.5).contains(y) {
                    points.append(CGPoint(x: x + 0.5, y: 0.5 - y))
                }
            }
        }

        if abs(c) > 0.0001 {
            for y in [-0.5, 0.5] {
                let x = (line.rho - y * s) / c
                if (-0.5...0.5).contains(x) {
                    points.append(CGPoint(x: x + 0.5, y: 0.5 - y))
                }
            }
        }

        guard points.count >= 2 else { return nil }
        return NormalizedLine(
            start: points[0],
            end: points[1],
            strength: line.strength
        )
    }
}
