import CoreVideo
import Foundation
import Vision

final class CreativeSparkEngine {
    private let queue = DispatchQueue(
        label: "CapturePilot.CreativeSpark",
        qos: .userInitiated
    )

    func scan(
        pixelBuffer: CVPixelBuffer,
        coachState: CoachState,
        scene: AppSettings.SceneCoach,
        completion: @escaping (CreativeSparkResult) -> Void
    ) {
        queue.async {
            var candidates: [(CGPoint, CreativeSparkKind, Double)] = []

            let saliency = VNGenerateAttentionBasedSaliencyImageRequest()
            let face = VNDetectFaceRectanglesRequest()
            let human = VNDetectHumanRectanglesRequest()
            let rectangles = VNDetectRectanglesRequest()
            rectangles.maximumObservations = 5
            rectangles.minimumConfidence = 0.55
            rectangles.minimumSize = 0.12

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )

            do {
                try handler.perform([saliency, face, human, rectangles])

                if let observations = saliency.results?.first?.salientObjects {
                    let sorted = observations.sorted { $0.confidence > $1.confidence }

                    for observation in sorted.prefix(3) {
                        let box = observation.boundingBox
                        candidates.append((
                            CGPoint(x: box.midX, y: 1 - box.midY),
                            scene == .macro ? .detail : .subject,
                            Double(observation.confidence)
                        ))
                    }
                }

                if let rectangleResults = rectangles.results {
                    for rectangle in rectangleResults.prefix(3) {
                        let box = rectangle.boundingBox
                        let area = box.width * box.height

                        guard area > 0.07, area < 0.72 else { continue }

                        candidates.append((
                            CGPoint(x: box.midX, y: 1 - box.midY),
                            .frame,
                            min(0.90, max(0.58, Double(rectangle.confidence)))
                        ))
                    }
                }

                if let faceBox = face.results?.first?.boundingBox {
                    candidates.insert((
                        CGPoint(x: faceBox.midX, y: 1 - faceBox.midY),
                        .subject,
                        1
                    ), at: 0)
                } else if let humanBox = human.results?.first?.boundingBox {
                    candidates.insert((
                        CGPoint(x: humanBox.midX, y: 1 - humanBox.midY),
                        .subject,
                        0.95
                    ), at: 0)
                }
            } catch {
                // Coach geometry still provides useful creative anchors.
            }

            if let point = coachState.vanishingPoint,
               (-0.05...1.05).contains(point.x),
               (-0.05...1.05).contains(point.y) {
                candidates.append((point, .depth, 0.88))
            }

            if let longest = coachState.leadingLines.max(by: {
                Self.lineLength($0) < Self.lineLength($1)
            }) {
                candidates.append((
                    CGPoint(
                        x: (longest.start.x + longest.end.x) / 2,
                        y: (longest.start.y + longest.end.y) / 2
                    ),
                    .leadingLine,
                    min(0.92, max(0.55, coachState.leadingLinesScore))
                ))
            }

            if coachState.symmetryScore > 0.84 {
                candidates.append((
                    CGPoint(x: 0.5, y: 0.5),
                    .symmetry,
                    coachState.symmetryScore
                ))
            }

            if let lightPoint = Self.interestingLightPoint(in: pixelBuffer) {
                candidates.append((lightPoint, .light, 0.72))
            }

            if coachState.negativeSpaceRatio > 0.52 {
                let subject = CGPoint(
                    x: coachState.saliencyCenter.x,
                    y: 1 - coachState.saliencyCenter.y
                )
                let point = CGPoint(
                    x: subject.x < 0.5 ? 0.78 : 0.22,
                    y: subject.y < 0.5 ? 0.72 : 0.30
                )
                candidates.append((point, .negativeSpace, 0.66))
            }

            if [.landscape, .street, .architecture, .automotive, .general]
                .contains(scene),
               let foregroundPoint = Self.foregroundDetailPoint(in: pixelBuffer) {
                candidates.append((
                    foregroundPoint,
                    .foreground,
                    0.60
                ))
            }

            let points = Self.selectDistinctPoints(candidates)
            let ideas = Self.buildIdeas(
                points: points,
                scene: scene,
                coachState: coachState
            )

            let sourceWidth = max(1, CVPixelBufferGetWidth(pixelBuffer))
            let sourceHeight = max(1, CVPixelBufferGetHeight(pixelBuffer))

            completion(
                CreativeSparkResult(
                    points: points,
                    ideas: ideas,
                    sourceAspectRatio:
                        CGFloat(sourceWidth) / CGFloat(sourceHeight),
                    scannedAt: Date()
                )
            )
        }
    }

    private static func selectDistinctPoints(
        _ candidates: [(CGPoint, CreativeSparkKind, Double)]
    ) -> [CreativeInterestPoint] {
        let sorted = candidates.sorted { lhs, rhs in
            if lhs.2 == rhs.2 {
                return priority(lhs.1) > priority(rhs.1)
            }
            return lhs.2 > rhs.2
        }

        var selected: [(CGPoint, CreativeSparkKind, Double)] = []

        for candidate in sorted {
            let position = CGPoint(
                x: min(max(candidate.0.x, 0.06), 0.94),
                y: min(max(candidate.0.y, 0.08), 0.92)
            )

            let tooClose = selected.contains {
                hypot($0.0.x - position.x, $0.0.y - position.y) < 0.12
            }
            guard !tooClose else { continue }

            selected.append((position, candidate.1, candidate.2))
            if selected.count == 4 { break }
        }

        return selected.enumerated().map { offset, item in
            CreativeInterestPoint(
                id: "spark-\(offset)-\(item.1.rawValue)",
                index: offset + 1,
                position: item.0,
                kind: item.1,
                confidence: item.2
            )
        }
    }

    private static func buildIdeas(
        points: [CreativeInterestPoint],
        scene: AppSettings.SceneCoach,
        coachState: CoachState
    ) -> [CreativeSparkIdea] {
        var ideas: [CreativeSparkIdea] = []

        func add(_ prompt: CreativeSparkPrompt, point: CreativeInterestPoint?) {
            guard !ideas.contains(where: { $0.prompt == prompt }) else { return }
            ideas.append(
                CreativeSparkIdea(
                    id: "idea-\(ideas.count)-\(prompt.rawValue)",
                    pointIndex: point?.index,
                    prompt: prompt
                )
            )
        }

        for point in points {
            switch point.kind {
            case .subject:
                if scene == .macro {
                    add(.isolateDetail, point: point)
                } else if scene == .automotive {
                    add(.lowerAngle, point: point)
                } else {
                    add(.makeAnchor, point: point)
                }

            case .depth:
                add(.useConvergence, point: point)

            case .leadingLine:
                add(.followLine, point: point)

            case .light:
                add(.exposeForLight, point: point)

            case .negativeSpace:
                add(.leaveSpace, point: point)

            case .foreground:
                add(.addForeground, point: point)

            case .frame:
                add(.frameWithinFrame, point: point)

            case .symmetry:
                add(.breakSymmetry, point: point)

            case .detail:
                add(.isolateDetail, point: point)
            }

            if ideas.count == 3 { break }
        }

        if ideas.count < 3 {
            switch scene {
            case .portrait:
                add(.changeHeight, point: points.first)
            case .architecture:
                add(.layerDepth, point: points.first(where: { $0.kind == .depth }))
            case .automotive:
                add(.lowerAngle, point: points.first)
            case .macro:
                add(.moveCloser, point: points.first)
            case .street:
                add(.changeHeight, point: points.first)
            case .landscape:
                add(.layerDepth, point: points.first)
            case .night:
                add(.exposeForLight, point: points.first(where: { $0.kind == .light }))
            case .general:
                if coachState.symmetryScore > 0.80 {
                    add(.breakSymmetry, point: points.first(where: { $0.kind == .symmetry }))
                } else {
                    add(.changeHeight, point: points.first)
                }
            }
        }

        if ideas.count < 3 {
            add(.moveCloser, point: points.first)
        }

        return Array(ideas.prefix(3))
    }

    private static func priority(_ kind: CreativeSparkKind) -> Int {
        switch kind {
        case .subject: 8
        case .depth: 7
        case .leadingLine: 6
        case .light: 5
        case .detail: 5
        case .negativeSpace: 4
        case .symmetry: 3
        case .frame: 5
        case .foreground: 2
        }
    }

    private static func lineLength(_ line: NormalizedLine) -> CGFloat {
        hypot(line.end.x - line.start.x, line.end.y - line.start.y)
    }

    private static func foregroundDetailPoint(
        in pixelBuffer: CVPixelBuffer
    ) -> CGPoint? {
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let pointer = base.assumingMemoryBound(to: UInt8.self)

        guard width > 8, height > 8 else { return nil }

        let columns = 8
        let rows = 4
        let startY = Int(Double(height) * 0.62)
        let scanHeight = max(1, height - startY)

        var samples: [(energy: Double, column: Int, row: Int)] = []
        var totalEnergy = 0.0

        for row in 0..<rows {
            for column in 0..<columns {
                let x = min(
                    width - 2,
                    max(
                        1,
                        (column * 2 + 1) * width / (columns * 2)
                    )
                )
                let y = min(
                    height - 2,
                    max(
                        1,
                        startY
                            + (row * 2 + 1) * scanHeight / (rows * 2)
                    )
                )

                let center = Int(pointer[y * stride + x])
                let left = Int(pointer[y * stride + x - 1])
                let right = Int(pointer[y * stride + x + 1])
                let up = Int(pointer[(y - 1) * stride + x])
                let down = Int(pointer[(y + 1) * stride + x])

                let localContrast =
                    abs(right - left)
                    + abs(down - up)
                    + abs(center - left)
                    + abs(center - right)

                let energy = Double(localContrast) / (255.0 * 4.0)
                samples.append((energy, column, row))
                totalEnergy += energy
            }
        }

        guard !samples.isEmpty else { return nil }

        let average = totalEnergy / Double(samples.count)
        guard let strongest = samples.max(by: { $0.energy < $1.energy }),
              strongest.energy > max(0.12, average * 1.45) else {
            return nil
        }

        let normalizedX =
            (Double(strongest.column) + 0.5) / Double(columns)
        let normalizedY =
            Double(startY) / Double(height)
            + (
                (Double(strongest.row) + 0.5) / Double(rows)
                * Double(scanHeight) / Double(height)
            )

        return CGPoint(
            x: min(max(normalizedX, 0.08), 0.92),
            y: min(max(normalizedY, 0.64), 0.92)
        )
    }

    private static func interestingLightPoint(
        in pixelBuffer: CVPixelBuffer
    ) -> CGPoint? {
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let pointer = base.assumingMemoryBound(to: UInt8.self)

        let columns = 8
        let rows = 10
        var cells: [(Double, Int, Int)] = []
        var total = 0.0

        for row in 0..<rows {
            for column in 0..<columns {
                let x = min(width - 1, (column * 2 + 1) * width / (columns * 2))
                let y = min(height - 1, (row * 2 + 1) * height / (rows * 2))
                let value = Double(pointer[y * stride + x]) / 255.0
                cells.append((value, column, row))
                total += value
            }
        }

        guard !cells.isEmpty else { return nil }
        let average = total / Double(cells.count)

        guard let best = cells
            .filter({ $0.0 < 0.96 && $0.0 > average + 0.10 })
            .max(by: { $0.0 < $1.0 }) else {
            return nil
        }

        return CGPoint(
            x: (Double(best.1) + 0.5) / Double(columns),
            y: (Double(best.2) + 0.5) / Double(rows)
        )
    }
}
