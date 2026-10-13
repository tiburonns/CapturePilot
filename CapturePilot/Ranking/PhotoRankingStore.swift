import Foundation

@MainActor
final class PhotoRankingStore: ObservableObject {
    @Published private(set) var entries: [PhotoRankingEntry] = []
    @Published private(set) var isAnalyzing = false
    @Published private(set) var lastError: String?

    private let encoder: JSONEncoder
    private var loadTask: Task<Void, Never>?
    private var activeAnalysisCount = 0
    private var knownFingerprints = Set<String>()
    private var knownAssetIdentifiers = Set<String>()
    private var visualSignaturesByFingerprint: [String: PhotoVisualSignature] = [:]
    private var visualHashBuckets: [String: Set<String>] = [:]
    private var inFlightFingerprints = Set<String>()
    private var inFlightAssetIdentifiers = Set<String>()
    private var inFlightVisualSignatures: [String: PhotoVisualSignature] = [:]

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        loadTask = Task { [weak self] in
            let loaded = await Task.detached(
                priority: .utility
            ) {
                Self.loadEntriesFromDisk()
            }.value

            guard let self, let loaded else { return }
            self.entries = loaded.sorted { $0.coachScore > $1.coachScore }
            self.rebuildDuplicateIndexes()
        }
    }

    @discardableResult
    func ingest(
        data: Data,
        source: RankingSource,
        sceneHint: PhotoCategory? = nil,
        assetIdentifier: String? = nil
    ) async -> PhotoIngestResult {
        if let loadTask {
            await loadTask.value
        }

        let fingerprint = PostShotAnalyzer.fingerprint(data)
        let visualSignature = await Task.detached(priority: .utility) {
            PostShotAnalyzer.visualSignature(data)
        }.value

        guard !isDuplicate(
            fingerprint: fingerprint,
            assetIdentifier: assetIdentifier,
            visualSignature: visualSignature
        ) else {
            return .duplicate
        }

        inFlightFingerprints.insert(fingerprint)
        if let assetIdentifier {
            inFlightAssetIdentifiers.insert(assetIdentifier)
        }
        if let visualSignature {
            inFlightVisualSignatures[fingerprint] = visualSignature
        }

        activeAnalysisCount += 1
        isAnalyzing = true
        defer {
            inFlightFingerprints.remove(fingerprint)
            if let assetIdentifier {
                inFlightAssetIdentifiers.remove(assetIdentifier)
            }
            if visualSignature != nil {
                inFlightVisualSignatures.removeValue(forKey: fingerprint)
            }
            activeAnalysisCount = max(0, activeAnalysisCount - 1)
            isAnalyzing = activeAnalysisCount > 0
        }

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
                assetIdentifier: assetIdentifier,
                perceptualFingerprint: visualSignature?.hash,
                aspectRatio: visualSignature?.aspectRatio,
                usedVisionAesthetics: result.usedVisionAesthetics,
                scoreVersion: PhotoRankingEntry.currentScoreVersion
            )

            entries.append(entry)
            entries.sort { $0.coachScore > $1.coachScore }
            knownFingerprints.insert(fingerprint)
            if let assetIdentifier {
                knownAssetIdentifiers.insert(assetIdentifier)
            }
            if let visualSignature {
                registerVisualSignature(visualSignature, fingerprint: fingerprint)
            }
            save()
            lastError = nil
            return .imported
        } catch {
            lastError = error.localizedDescription
            return .failed
        }
    }

    func updateCategory(for entryID: UUID, to category: PhotoCategory) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
            return
        }

        entries[index].category = category
        entries[index].categoryOverride = category
        entries.sort { $0.coachScore > $1.coachScore }
        save()
    }

    func delete(_ entry: PhotoRankingEntry) {
        entries.removeAll { $0.id == entry.id }
        try? FileManager.default.removeItem(at: thumbnailURL(for: entry))
        rebuildDuplicateIndexes()
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

    private func isDuplicate(
        fingerprint: String,
        assetIdentifier: String?,
        visualSignature: PhotoVisualSignature?
    ) -> Bool {
        if inFlightFingerprints.contains(fingerprint) || knownFingerprints.contains(fingerprint) {
            return true
        }

        if let assetIdentifier,
           inFlightAssetIdentifiers.contains(assetIdentifier)
            || knownAssetIdentifiers.contains(assetIdentifier) {
            return true
        }

        if let visualSignature {
            let indexedCandidates = visualCandidateSignatures(for: visualSignature)
            if matchesVisualDuplicate(
                visualSignature,
                storedSignatures: indexedCandidates
            ) {
                return true
            }

            if matchesVisualDuplicate(
                visualSignature,
                storedSignatures: Array(inFlightVisualSignatures.values)
            ) {
                return true
            }
        }

        return false
    }

    private func visualCandidateSignatures(
        for candidate: PhotoVisualSignature
    ) -> [PhotoVisualSignature] {
        guard let value = UInt64(candidate.hash, radix: 16) else { return [] }

        var fingerprints = Set<String>()
        for chunkIndex in 0..<4 {
            let shift = chunkIndex * 16
            let component = UInt16((value >> shift) & 0xFFFF)
            fingerprints.formUnion(
                visualHashBuckets["\(chunkIndex):\(component)"] ?? []
            )
        }

        return fingerprints.compactMap { visualSignaturesByFingerprint[$0] }
    }

    private func registerVisualSignature(
        _ signature: PhotoVisualSignature,
        fingerprint: String
    ) {
        guard let value = UInt64(signature.hash, radix: 16) else { return }
        visualSignaturesByFingerprint[fingerprint] = signature

        // With a 64-bit hash split into four 16-bit chunks, any pair of hashes
        // at Hamming distance <= 2 shares at least one unchanged chunk. These
        // buckets avoid a full-library linear scan for every imported photo.
        for chunkIndex in 0..<4 {
            let shift = chunkIndex * 16
            let component = UInt16((value >> shift) & 0xFFFF)
            visualHashBuckets["\(chunkIndex):\(component)", default: []]
                .insert(fingerprint)
        }
    }

    private func rebuildDuplicateIndexes() {
        knownFingerprints = Set(entries.map(\.fingerprint))
        knownAssetIdentifiers = Set(entries.compactMap(\.assetIdentifier))
        visualSignaturesByFingerprint.removeAll(keepingCapacity: true)
        visualHashBuckets.removeAll(keepingCapacity: true)

        for entry in entries {
            guard let hash = entry.perceptualFingerprint,
                  let aspectRatio = entry.aspectRatio else {
                continue
            }

            registerVisualSignature(
                PhotoVisualSignature(hash: hash, aspectRatio: aspectRatio),
                fingerprint: entry.fingerprint
            )
        }
    }

    private func matchesVisualDuplicate(
        _ candidate: PhotoVisualSignature,
        storedSignatures: [PhotoVisualSignature]
    ) -> Bool {
        storedSignatures.contains { stored in
            let scale = max(max(abs(candidate.aspectRatio), abs(stored.aspectRatio)), 1)
            let ratioDifference = abs(candidate.aspectRatio - stored.aspectRatio) / scale
            guard ratioDifference <= 0.015 else { return false }

            guard let distance = PostShotAnalyzer.visualDistance(
                candidate.hash,
                stored.hash
            ) else {
                return false
            }

            // Conservative threshold avoids discarding distinct burst frames
            // that happen to share a broadly similar composition.
            return distance <= 2
        }
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

    nonisolated private static func loadEntriesFromDisk()
        -> [PhotoRankingEntry]? {
        guard let data = try? Data(contentsOf: Self.indexURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([PhotoRankingEntry].self, from: data)
    }

    nonisolated private static var rootDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent("CapturePilot", isDirectory: true)
            .appendingPathComponent("Rankings", isDirectory: true)
    }

    nonisolated private static var thumbnailDirectory: URL {
        rootDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    nonisolated private static var indexURL: URL {
        rootDirectory.appendingPathComponent("ranking.json")
    }
}
