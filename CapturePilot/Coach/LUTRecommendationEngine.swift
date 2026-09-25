import Foundation

enum LUTRecommendationReason: Equatable {
    case portrait
    case protectHighlights
    case liftShadows
    case night
    case landscape
    case architecture
    case automotive
    case street
    case macro
    case general
}

struct LUTRecommendation: Equatable {
    let entryID: String
    let displayName: String
    let reason: LUTRecommendationReason
    let confidence: Double
}

enum LUTRecommendationEngine {
    static func recommend(
        entries: [LUTLibraryEntry],
        scene: AppSettings.SceneCoach,
        state: CoachState
    ) -> LUTRecommendation? {
        guard !entries.isEmpty else { return nil }

        let ranked = entries.map { entry -> (LUTLibraryEntry, Double, LUTRecommendationReason) in
            let exposure = exposureScore(profile: entry.profile, state: state)
            let sceneResult = sceneScore(profile: entry.profile, scene: scene)
            let score = exposure.score + sceneResult.score - entry.profile.strength * 0.08
            let reason = exposure.isDominant ? exposure.reason : sceneResult.reason
            return (entry, score, reason)
        }
        .sorted { $0.1 > $1.1 }

        guard let best = ranked.first else { return nil }

        let secondScore = ranked.dropFirst().first?.1 ?? best.1 - 0.25
        let separation = max(0, best.1 - secondScore)
        let confidence = min(
            max(0.30 + separation * 0.55 + min(entries.count, 8).doubleValue * 0.025, 0),
            0.92
        )

        return LUTRecommendation(
            entryID: best.0.id,
            displayName: best.0.displayName,
            reason: best.2,
            confidence: confidence
        )
    }

    private static func exposureScore(
        profile: LUTProfile,
        state: CoachState
    ) -> (score: Double, reason: LUTRecommendationReason, isDominant: Bool) {
        if state.highlightClipRatio > 0.025 || state.averageLuma > 0.78 {
            return (
                profile.highlightCompression * 1.45
                    - max(profile.contrast, 0) * 0.70
                    - max(profile.shadowLift, 0) * 0.15,
                .protectHighlights,
                true
            )
        }

        if state.shadowClipRatio > 0.18 || state.averageLuma < 0.20 {
            return (
                profile.shadowLift * 1.35
                    - max(profile.contrast, 0) * 0.75,
                .liftShadows,
                true
            )
        }

        return (0, .general, false)
    }

    private static func sceneScore(
        profile: LUTProfile,
        scene: AppSettings.SceneCoach
    ) -> (score: Double, reason: LUTRecommendationReason) {
        switch scene {
        case .portrait:
            return (
                profile.warmth * 0.70
                    - abs(profile.contrast) * 0.15
                    - max(profile.saturation - 0.45, 0) * 0.30,
                .portrait
            )
        case .architecture:
            return (
                max(profile.contrast, 0) * 0.65
                    - abs(profile.warmth) * 0.38
                    - abs(profile.saturation) * 0.10,
                .architecture
            )
        case .automotive:
            return (
                max(profile.contrast, 0) * 0.60
                    + max(profile.saturation, 0) * 0.36
                    - max(profile.shadowLift - 0.65, 0) * 0.08,
                .automotive
            )
        case .macro:
            return (
                max(profile.saturation, 0) * 0.55
                    + max(profile.contrast, 0) * 0.30,
                .macro
            )
        case .street:
            return (
                max(profile.contrast, 0) * 0.60
                    - profile.saturation * 0.18,
                .street
            )
        case .landscape:
            return (
                max(profile.saturation, 0) * 0.48
                    + max(profile.contrast, 0) * 0.36
                    + profile.highlightCompression * 0.18,
                .landscape
            )
        case .night:
            return (
                profile.shadowLift * 0.75
                    + profile.highlightCompression * 0.55
                    - max(profile.contrast, 0) * 0.40
                    - max(profile.warmth, 0) * 0.10,
                .night
            )
        case .general:
            return (
                max(profile.contrast, 0) * 0.20
                    + max(profile.saturation, 0) * 0.12
                    - abs(profile.warmth) * 0.08
                    - profile.strength * 0.12,
                .general
            )
        }
    }
}

private extension Int {
    var doubleValue: Double { Double(self) }
}
