import AVFoundation
import CoreGraphics
import QuartzCore
import Vision

final class CoachEngine {
    private let visionQueue = DispatchQueue(label: "CapturePilot.CoachEngine", qos: .userInitiated)
    private var isProcessing = false
    private var lastProcessTime: CFTimeInterval = 0
    private let minimumInterval: CFTimeInterval = 0.28

    private var candidateMessage: LocalizedKey = .ready
    private var candidateCount = 0
    private var publishedMessage: LocalizedKey = .ready

    var onUpdate: ((CoachState) -> Void)?

    func process(sampleBuffer: CMSampleBuffer, intensity: AppSettings.CoachIntensity) {
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

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
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
                state.saliencyCenter = CGPoint(x: strongest.boundingBox.midX, y: strongest.boundingBox.midY)
                state.hasSubject = true
                if state.subjectRect == nil {
                    state.subjectRect = strongest.boundingBox
                }
            } else if let rect = state.subjectRect {
                state.saliencyCenter = CGPoint(x: rect.midX, y: rect.midY)
            }
        } catch {
            // Luminance feedback remains available if a Vision request fails for a frame.
        }

        chooseGuidance(state: &state, intensity: intensity)
        stabilizeMessage(state: &state)

        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(state)
        }
    }

    private func chooseGuidance(state: inout CoachState, intensity: AppSettings.CoachIntensity) {
        let horizonLimit = intensity == .subtle ? 3.5 : 2.0

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

        if state.shadowClipRatio > 0.32 || state.averageLuma < 0.16 {
            state.primaryMessage = .tooDark
            state.severity = .caution
            return
        }

        guard intensity != .subtle, state.hasSubject else {
            state.primaryMessage = .ready
            state.severity = .neutral
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
        state.isNearThird = distance(point, nearest) < 0.115

        if state.hasPerson, let subject = state.subjectRect, subject.maxY < 0.76 {
            state.primaryMessage = .reduceHeadroom
            state.secondaryMessage = state.isNearThird ? .subjectOnThird : nil
            state.severity = .neutral
            return
        }

        if state.isNearThird {
            state.primaryMessage = .subjectOnThird
            state.secondaryMessage = .goodBalance
            state.severity = .positive
            return
        }

        let dx = nearest.x - point.x
        let dy = nearest.y - point.y
        if abs(dx) > abs(dy) {
            state.primaryMessage = dx > 0 ? .moveLeft : .moveRight
        } else {
            state.primaryMessage = dy > 0 ? .moveDown : .moveUp
        }
        state.secondaryMessage = .goodBalance
        state.severity = .neutral
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
}
