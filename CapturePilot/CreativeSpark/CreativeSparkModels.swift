import CoreGraphics
import Foundation

enum CreativeSparkKind: String, Equatable {
    case subject
    case depth
    case leadingLine
    case light
    case negativeSpace
    case foreground
    case symmetry
    case detail
}

struct CreativeInterestPoint: Identifiable, Equatable {
    let id: String
    let index: Int
    let position: CGPoint
    let kind: CreativeSparkKind
    let confidence: Double
}

enum CreativeSparkPrompt: String, Equatable {
    case makeAnchor
    case moveCloser
    case useConvergence
    case followLine
    case exposeForLight
    case leaveSpace
    case addForeground
    case breakSymmetry
    case lowerAngle
    case changeHeight
    case isolateDetail
    case layerDepth
}

struct CreativeSparkIdea: Identifiable, Equatable {
    let id: String
    let pointIndex: Int?
    let prompt: CreativeSparkPrompt
}

struct CreativeSparkResult: Equatable {
    let points: [CreativeInterestPoint]
    let ideas: [CreativeSparkIdea]
    let scannedAt: Date
}
