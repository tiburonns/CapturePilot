import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct PhotoCategoryTests {
    static func main() {
        let darkCar = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "sports car", confidence: 0.82),
                PhotoCategoryEvidence(label: "night", confidence: 0.08)
            ],
            faceArea: nil,
            averageLuma: 0.07,
            sceneHint: nil
        )
        require(darkCar == .automotive, "low luminance alone must not turn a car photo into night")

        let darkWithoutEvidence = PhotoCategoryClassifier.classify(
            observations: [],
            faceArea: nil,
            averageLuma: 0.04,
            sceneHint: nil
        )
        require(darkWithoutEvidence == .general, "darkness alone must not assign night")

        let closePortrait = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "person", confidence: 0.45),
                PhotoCategoryEvidence(label: "outdoor", confidence: 0.78)
            ],
            faceArea: 0.08,
            averageLuma: 0.32,
            sceneHint: nil
        )
        require(closePortrait == .portrait, "a large close face should provide strong portrait evidence")

        let landscapeWithWeakStreetSignal = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "mountain", confidence: 0.79),
                PhotoCategoryEvidence(label: "street", confidence: 0.12)
            ],
            faceArea: nil,
            averageLuma: 0.48,
            sceneHint: nil
        )
        require(
            landscapeWithWeakStreetSignal == .landscape,
            "strong landscape evidence should beat a weak unrelated label"
        )

        let ambiguousScene = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "outdoor", confidence: 0.19),
                PhotoCategoryEvidence(label: "building", confidence: 0.18)
            ],
            faceArea: nil,
            averageLuma: 0.42,
            sceneHint: .architecture
        )
        require(ambiguousScene == .architecture, "a selected scene should resolve ambiguous evidence")

        let ambiguousWithoutHint = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "outdoor", confidence: 0.19),
                PhotoCategoryEvidence(label: "building", confidence: 0.18)
            ],
            faceArea: nil,
            averageLuma: 0.42,
            sceneHint: nil
        )
        require(ambiguousWithoutHint == .general, "uncertain photos should fall back to General")

        let explicitCarOverPortraitHint = PhotoCategoryClassifier.classify(
            observations: [
                PhotoCategoryEvidence(label: "sports car", confidence: 0.88)
            ],
            faceArea: nil,
            averageLuma: 0.42,
            sceneHint: .portrait
        )
        require(
            explicitCarOverPortraitHint == .automotive,
            "strong visual evidence should not be overridden by a conflicting scene hint"
        )

        print("PASS: confidence-aware photo category classification")
    }
}
