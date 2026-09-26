import Foundation

enum PhotoCategory: String, CaseIterable, Codable, Identifiable {
    case general
    case portrait
    case architecture
    case automotive
    case macro
    case street
    case landscape
    case night

    var id: String { rawValue }
}

enum RankingSource: String, Codable {
    case capture
    case importPhoto
}

enum RankingRecommendation: String, Codable, CaseIterable {
    case levelHorizon
    case lowerHighlights
    case raiseExposure
    case stabilizeAndRefocus
    case simplifyBackground
    case moveTowardStrongPoint
    case reduceHeadroom
    case improvePortraitQuality
    case strengthenSymmetry
    case useLeadingLines
    case lowerCameraAngle
    case addForegroundLayer
    case waitForSeparation
    case useNegativeSpace
    case protectNightHighlights
    case tryDifferentViewpoint
}

struct CoachScoreBreakdown: Codable, Hashable {
    let overall: Double
    let aesthetics: Double?
    let exposure: Double
    let composition: Double
    let detail: Double
    let portraitQuality: Double?
}

struct PhotoRankingEntry: Identifiable, Codable, Hashable {
    static let currentScoreVersion = 1
    let id: UUID
    let createdAt: Date
    let source: RankingSource
    let category: PhotoCategory
    let score: CoachScoreBreakdown
    let recommendations: [RankingRecommendation]
    let tags: [String]
    let thumbnailFilename: String
    let fingerprint: String
    let usedVisionAesthetics: Bool
    let scoreVersion: Int

    var coachScore: Double { score.overall }
}

struct PostShotAnalysisResult {
    let category: PhotoCategory
    let score: CoachScoreBreakdown
    let recommendations: [RankingRecommendation]
    let tags: [String]
    let thumbnailData: Data
    let usedVisionAesthetics: Bool
}
