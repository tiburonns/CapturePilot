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

enum PhotoIngestResult: Equatable {
    case imported
    case duplicate
    case failed
}

struct PhotoVisualSignature: Hashable {
    let hash: String
    let aspectRatio: Double
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
    var category: PhotoCategory
    var categoryOverride: PhotoCategory? = nil
    let score: CoachScoreBreakdown
    let recommendations: [RankingRecommendation]
    let tags: [String]
    let thumbnailFilename: String
    let fingerprint: String
    var assetIdentifier: String? = nil
    var perceptualFingerprint: String? = nil
    var aspectRatio: Double? = nil
    let usedVisionAesthetics: Bool
    let scoreVersion: Int

    var coachScore: Double { score.overall }
    var hasManualCategory: Bool { categoryOverride != nil }
}

struct PostShotAnalysisResult {
    let category: PhotoCategory
    let score: CoachScoreBreakdown
    let recommendations: [RankingRecommendation]
    let tags: [String]
    let thumbnailData: Data
    let usedVisionAesthetics: Bool
}


struct PhotoCategoryEvidence {
    let label: String
    let confidence: Double
}

enum PhotoCategoryClassifier {
    static func classify(
        observations: [PhotoCategoryEvidence],
        faceArea: Double?,
        averageLuma: Double,
        sceneHint: PhotoCategory?
    ) -> PhotoCategory {
        let keywords: [PhotoCategory: [String]] = [
            .portrait: [
                "portrait", "selfie", "human face", "person", "people",
                "man", "woman", "child", "baby", "headshot"
            ],
            .architecture: [
                "architecture", "building", "skyscraper", "bridge", "church",
                "house", "tower", "facade", "castle", "lighthouse", "interior"
            ],
            .automotive: [
                "sports car", "race car", "car", "automobile", "vehicle",
                "motorcycle", "truck", "bus", "bicycle", "car wheel"
            ],
            .macro: [
                "macro", "close up", "flower", "petal", "insect", "butterfly",
                "spider", "bee", "mushroom", "plant", "leaf"
            ],
            .street: [
                "street photography", "city street", "street", "sidewalk",
                "pedestrian", "crosswalk", "traffic", "urban scene", "market"
            ],
            .landscape: [
                "landscape", "mountain", "valley", "seashore", "beach",
                "lake", "waterfall", "forest", "desert", "meadow", "waterfront"
            ],
            .night: [
                "night sky", "city at night", "night", "stars", "moon",
                "fireworks", "star trail", "nightscape", "aurora"
            ],
            .general: []
        ]

        var evidence: [PhotoCategory: Double] = [:]
        for observation in observations.prefix(12) {
            let label = observation.label
                .lowercased()
                .replacingOccurrences(of: "_", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let confidence = min(max(observation.confidence, 0), 1)

            for (category, categoryKeywords) in keywords {
                guard let matched = categoryKeywords.first(where: { keyword in
                    label == keyword
                        || label.hasPrefix(keyword + " ")
                        || label.hasSuffix(" " + keyword)
                        || label.contains(" " + keyword + " ")
                }) else {
                    continue
                }

                let tokenCount = matched.split(separator: " ").count
                let specificity = tokenCount > 1 ? 1.08 : 1.0
                evidence[category] = max(
                    evidence[category, default: 0],
                    confidence * specificity
                )
            }
        }

        // A large, close face is useful portrait evidence; a tiny face in a
        // street or landscape image should not dominate the scene category.
        if let faceArea, faceArea >= 0.045 {
            evidence[.portrait] = max(evidence[.portrait, default: 0], 0.72)
        }

        // Darkness alone is not enough to label an image as night.
        if averageLuma < 0.18, evidence[.night, default: 0] >= 0.20 {
            evidence[.night, default: 0] *= 1.12
        }

        let ranked = evidence
            .filter { $0.key != .general }
            .sorted { lhs, rhs in lhs.value > rhs.value }

        if let best = ranked.first {
            let second = ranked.dropFirst().first?.value ?? 0
            let margin = best.value - second
            if best.value >= 0.24 && margin >= 0.035 {
                return best.key
            }
        }

        // Scene selection is a fallback, not an unconditional override of
        // strong visual evidence.
        if let sceneHint, sceneHint != .general {
            let hintScore = evidence[sceneHint, default: 0]
            let bestScore = ranked.first?.value ?? 0
            if bestScore < 0.34 || hintScore >= bestScore - 0.05 {
                return sceneHint
            }
        }

        return .general
    }
}
