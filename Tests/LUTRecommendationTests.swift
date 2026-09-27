import Foundation

enum AppSettings {
    enum SceneCoach {
        case general
        case portrait
        case architecture
        case automotive
        case macro
        case street
        case landscape
        case night
    }
}

struct CoachState {
    var averageLuma: Double = 0.5
    var highlightClipRatio: Double = 0
    var shadowClipRatio: Double = 0
}

struct LUTProfile: Equatable {
    let warmth: Double
    let contrast: Double
    let saturation: Double
    let shadowLift: Double
    let highlightCompression: Double
    let strength: Double
}

struct LUTLibraryEntry: Equatable {
    let id: String
    let displayName: String
    let profile: LUTProfile
}

private func entry(
    _ id: String,
    warmth: Double = 0,
    contrast: Double = 0,
    saturation: Double = 0,
    shadowLift: Double = 0,
    highlightCompression: Double = 0,
    strength: Double = 0.2
) -> LUTLibraryEntry {
    LUTLibraryEntry(
        id: id,
        displayName: id,
        profile: LUTProfile(
            warmth: warmth,
            contrast: contrast,
            saturation: saturation,
            shadowLift: shadowLift,
            highlightCompression: highlightCompression,
            strength: strength
        )
    )
}

private func require(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct LUTRecommendationTests {
    static func main() {
        let neutral = CoachState()

        require(
            LUTRecommendationEngine.recommend(
                entries: [],
                scene: .general,
                state: neutral
            ) == nil,
            "empty library must not produce a recommendation"
        )

        let clipped = CoachState(
            averageLuma: 0.84,
            highlightClipRatio: 0.08,
            shadowClipRatio: 0
        )
        require(
            LUTRecommendationEngine.recommend(
                entries: [entry("any")],
                scene: .general,
                state: clipped
            ) == nil,
            "severely clipped highlights must suppress LUT recommendations"
        )

        let portraitEntries = [
            entry(
                "warmPortrait",
                warmth: 0.75,
                contrast: 0.08,
                saturation: 0.18,
                strength: 0.18
            ),
            entry(
                "coldPunch",
                warmth: -0.65,
                contrast: 0.80,
                saturation: 0.65,
                strength: 0.35
            )
        ]
        let portrait = LUTRecommendationEngine.recommend(
            entries: portraitEntries,
            scene: .portrait,
            state: neutral
        )
        require(
            portrait?.entryID == "warmPortrait",
            "portrait scene should prefer the restrained warm LUT"
        )
        require(
            portrait?.reason == .portrait,
            "portrait recommendation should explain the scene reason"
        )

        let architectureEntries = [
            entry(
                "neutralContrast",
                warmth: 0,
                contrast: 0.82,
                saturation: 0.05,
                strength: 0.20
            ),
            entry(
                "warmContrast",
                warmth: 0.82,
                contrast: 0.82,
                saturation: 0.05,
                strength: 0.20
            )
        ]
        let architecture = LUTRecommendationEngine.recommend(
            entries: architectureEntries,
            scene: .architecture,
            state: neutral
        )
        require(
            architecture?.entryID == "neutralContrast",
            "architecture should penalize a strong color-temperature bias"
        )

        let brightButRecoverable = CoachState(
            averageLuma: 0.80,
            highlightClipRatio: 0.035,
            shadowClipRatio: 0
        )
        let highlightEntries = [
            entry(
                "compressHighlights",
                contrast: 0.05,
                highlightCompression: 0.85,
                strength: 0.20
            ),
            entry(
                "hardContrast",
                contrast: 0.85,
                highlightCompression: 0.05,
                strength: 0.30
            )
        ]
        let highlight = LUTRecommendationEngine.recommend(
            entries: highlightEntries,
            scene: .general,
            state: brightButRecoverable
        )
        require(
            highlight?.entryID == "compressHighlights",
            "recoverable bright scenes should prefer highlight compression"
        )
        require(
            highlight?.reason == .protectHighlights,
            "highlight-driven recommendation should explain highlight protection"
        )

        let darkButRecoverable = CoachState(
            averageLuma: 0.18,
            highlightClipRatio: 0,
            shadowClipRatio: 0.22
        )
        let shadowEntries = [
            entry(
                "liftShadows",
                contrast: 0.05,
                shadowLift: 0.80,
                strength: 0.20
            ),
            entry(
                "crushShadows",
                contrast: 0.85,
                shadowLift: -0.20,
                strength: 0.30
            )
        ]
        let shadows = LUTRecommendationEngine.recommend(
            entries: shadowEntries,
            scene: .general,
            state: darkButRecoverable
        )
        require(
            shadows?.entryID == "liftShadows",
            "recoverable dark scenes should prefer shadow lift"
        )
        require(
            shadows?.reason == .liftShadows,
            "shadow-driven recommendation should explain shadow lift"
        )

        let blackNight = CoachState(
            averageLuma: 0.05,
            highlightClipRatio: 0,
            shadowClipRatio: 0.2
        )
        require(
            LUTRecommendationEngine.recommend(
                entries: [entry("night")],
                scene: .night,
                state: blackNight
            ) == nil,
            "near-black night scenes must suppress speculative LUT advice"
        )

        if let confidence = portrait?.confidence {
            require(
                (0...0.92).contains(confidence),
                "confidence must remain in the documented bounded range"
            )
        } else {
            require(false, "portrait test should produce a confidence value")
        }

        print("PASS: deterministic LUT recommendation behavior")
    }
}
