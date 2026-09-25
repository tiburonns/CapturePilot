import CoreGraphics

enum CoachSeverity: Equatable {
    case neutral
    case positive
    case caution
}

struct CoachState: Equatable {
    var primaryMessage: LocalizedKey = .ready
    var secondaryMessage: LocalizedKey? = nil
    var severity: CoachSeverity = .neutral
    var horizonAngleDegrees: Double = 0
    var saliencyCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var subjectRect: CGRect? = nil
    var averageLuma: Double = 0.5
    var highlightClipRatio: Double = 0
    var shadowClipRatio: Double = 0
    var isNearThird: Bool = false
    var hasPerson: Bool = false
    var hasSubject: Bool = false
}
