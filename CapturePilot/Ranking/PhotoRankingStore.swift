import Foundation

@MainActor
final class PhotoRankingStore: ObservableObject {
    @Published private(set) var entries: [PhotoRankingEntry] = []
    @Published private(set) var isAnalyzing = false
    @Published private(set) var lastError: String?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    func ingest(
        data: Data,
        source: RankingSource,
        sceneHint: PhotoCategory? = nil
    ) async {
        let fingerprint = PostShotAnalyzer.fingerprint(data)
        guard !entries.contains(where: { $0.fingerprint == fingerprint }) else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try PostShotAnalyzer().analyze(data: data, sceneHint: sceneHint)
            }.value

            let id = UUID()
            let filename = "\(id.uuidString).jpg"
            let thumbnailURL = Self.thumbnailDirectory.appendingPathComponent(filename)
            try FileManager.default.createDirectory(
                at: Self.thumbnailDirectory,
                withIntermediateDirectories: true
            )
            try result.thumbnailData.write(to: thumbnailURL, options: .atomic)

            let entry = PhotoRankingEntry(
                id: id,
                createdAt: Date(),
                source: source,
                category: result.category,
                score: result.score,
                recommendations: result.recommendations,
                tags: result.tags,
                thumbnailFilename: filename,
                fingerprint: fingerprint,
                usedVisionAesthetics: result.usedVisionAesthetics,
                scoreVersion: PhotoRankingEntry.currentScoreVersion
            )

            entries.append(entry)
            entries.sort { $0.coachScore > $1.coachScore }
            save()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func delete(_ entry: PhotoRankingEntry) {
        entries.removeAll { $0.id == entry.id }
        try? FileManager.default.removeItem(at: thumbnailURL(for: entry))
        save()
    }

    func top(
        limit: Int,
        category: PhotoCategory?
    ) -> [PhotoRankingEntry] {
        let filtered = category == nil
            ? entries
            : entries.filter { $0.category == category }

        return Array(
            filtered.sorted { lhs, rhs in
                if lhs.coachScore == rhs.coachScore {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.coachScore > rhs.coachScore
            }.prefix(max(1, limit))
        )
    }

    func bestScoresByCategory() -> [PhotoCategory: PhotoRankingEntry] {
        Dictionary(
            uniqueKeysWithValues: PhotoCategory.allCases.compactMap { category in
                guard let best = entries
                    .filter({ $0.category == category })
                    .max(by: { $0.coachScore < $1.coachScore }) else {
                    return nil
                }
                return (category, best)
            }
        )
    }

    func thumbnailURL(for entry: PhotoRankingEntry) -> URL {
        Self.thumbnailDirectory.appendingPathComponent(entry.thumbnailFilename)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: Self.rootDirectory,
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(entries)
            try data.write(to: Self.indexURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.indexURL),
              let decoded = try? decoder.decode([PhotoRankingEntry].self, from: data) else {
            return
        }
        entries = decoded.sorted { $0.coachScore > $1.coachScore }
    }

    private static var rootDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent("CapturePilot", isDirectory: true)
            .appendingPathComponent("Rankings", isDirectory: true)
    }

    private static var thumbnailDirectory: URL {
        rootDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    private static var indexURL: URL {
        rootDirectory.appendingPathComponent("ranking.json")
    }
}
