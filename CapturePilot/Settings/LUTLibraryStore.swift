import Foundation

enum LUTLibrarySource: String, Equatable {
    case capturePilot
    case external
}

struct LUTProfile: Equatable {
    let warmth: Double
    let contrast: Double
    let saturation: Double
    let shadowLift: Double
    let highlightCompression: Double
    let strength: Double
}

struct LUTLibraryEntry: Identifiable, Equatable {
    let id: String
    let source: LUTLibrarySource
    let relativePath: String
    let displayName: String
    let dimension: Int
    let profile: LUTProfile
}

private struct LUTScanResult {
    let entries: [LUTLibraryEntry]
    let invalidCount: Int
    let errorDescription: String?
    let succeeded: Bool
}

private struct LUTBookmarkResolution {
    let url: URL?
    let isStale: Bool
    let errorDescription: String?
}

private final class LUTFolderPresenter: NSObject, NSFilePresenter {
    var presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue
    var onChange: (() -> Void)?

    init(url: URL, onChange: @escaping () -> Void) {
        presentedItemURL = url
        self.onChange = onChange
        presentedItemOperationQueue = OperationQueue()
        presentedItemOperationQueue.maxConcurrentOperationCount = 1
        presentedItemOperationQueue.qualityOfService = .utility
        super.init()
    }

    func presentedItemDidChange() { onChange?() }
    func presentedSubitemDidAppear(at url: URL) { onChange?() }
    func presentedSubitemDidChange(at url: URL) { onChange?() }

    func accommodatePresentedSubitemDeletion(
        at url: URL,
        completionHandler: @escaping (Error?) -> Void
    ) {
        onChange?()
        completionHandler(nil)
    }
}

@MainActor
final class LUTLibraryStore: ObservableObject {
    @Published private(set) var entries: [LUTLibraryEntry] = []
    @Published private(set) var folderDisplayName: String?
    @Published private(set) var activeEntryID: String?
    @Published private(set) var activeDisplayName: String?
    @Published private(set) var activeSource: LUTLibrarySource?
    @Published private(set) var invalidFileCount = 0
    @Published private(set) var scanErrorDescription: String?

    private let defaults = UserDefaults.standard
    private let bookmarkKey = "lutLibrary.folderBookmark.v1"
    private let folderNameKey = "lutLibrary.folderDisplayName.v1"
    private let activeIDKey = "lutLibrary.activeEntryID.v1"
    private let activeNameKey = "lutLibrary.activeDisplayName.v1"
    private let activeSourceKey = "lutLibrary.activeSource.v1"

    private var monitoredURL: URL?
    private var didStartSecurityAccess = false
    private var presenter: LUTFolderPresenter?
    private var refreshTask: Task<Void, Never>?
    private var folderResolutionTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?
    private var monitorGeneration = 0
    private var scanGeneration = 0

    init() {
        Self.ensureLocalFolder()
        folderDisplayName = defaults.string(forKey: folderNameKey)
        activeEntryID = defaults.string(forKey: activeIDKey)
        activeDisplayName = defaults.string(forKey: activeNameKey)
        activeSource = LUTLibrarySource(
            rawValue: defaults.string(forKey: activeSourceKey) ?? ""
        )
    }

    deinit {
        refreshTask?.cancel()
        folderResolutionTask?.cancel()
        scanTask?.cancel()
        if let presenter {
            NSFileCoordinator.removeFilePresenter(presenter)
        }
        if didStartSecurityAccess {
            monitoredURL?.stopAccessingSecurityScopedResource()
        }
    }

    var hasFolder: Bool {
        defaults.data(forKey: bookmarkKey) != nil
    }

    var localFolderName: String {
        "CapturePilot/LUTs"
    }

    var activeLUTURL: URL? {
        let url = Self.activeCacheURL
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func setFolder(_ url: URL) throws {
        stopMonitoring()

        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let data = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(data, forKey: bookmarkKey)
        defaults.set(url.lastPathComponent, forKey: folderNameKey)
        folderDisplayName = url.lastPathComponent

        startMonitoring()
    }

    func clearFolder() {
        let shouldClearActive = activeSource == .external

        stopMonitoring()
        defaults.removeObject(forKey: bookmarkKey)
        defaults.removeObject(forKey: folderNameKey)
        folderDisplayName = nil
        scanErrorDescription = nil

        if shouldClearActive {
            clearActiveLUT()
        }

        refresh()
    }

    func startMonitoring() {
        Self.ensureLocalFolder()

        // Local LUTs can refresh immediately, but the actual disk work happens
        // off the main actor so launch never waits on file enumeration/parsing.
        refresh()

        guard monitoredURL == nil,
              let bookmarkData = defaults.data(forKey: bookmarkKey) else {
            return
        }

        folderResolutionTask?.cancel()
        monitorGeneration += 1
        let generation = monitorGeneration

        folderResolutionTask = Task.detached(priority: .utility) { [weak self] in
            let resolution = Self.resolveBookmarkData(bookmarkData)

            await MainActor.run {
                guard let self,
                      generation == self.monitorGeneration,
                      !Task.isCancelled else {
                    return
                }

                guard let url = resolution.url else {
                    self.scanErrorDescription =
                        resolution.errorDescription
                        ?? "CapturePilot could not reopen the selected external LUT folder."
                    return
                }

                let accessed = url.startAccessingSecurityScopedResource()
                guard accessed else {
                    self.scanErrorDescription =
                        "CapturePilot could not access the selected external LUT folder."
                    return
                }

                self.didStartSecurityAccess = true
                self.monitoredURL = url
                self.folderDisplayName = url.lastPathComponent
                self.defaults.set(url.lastPathComponent, forKey: self.folderNameKey)

                let presenter = LUTFolderPresenter(url: url) { [weak self] in
                    Task { @MainActor in
                        self?.scheduleRefresh()
                    }
                }
                self.presenter = presenter
                NSFileCoordinator.addFilePresenter(presenter)

                if resolution.isStale {
                    self.refreshStoredBookmark(for: url)
                }

                self.refresh()
            }
        }
    }

    func stopMonitoring() {
        refreshTask?.cancel()
        refreshTask = nil

        folderResolutionTask?.cancel()
        folderResolutionTask = nil
        scanTask?.cancel()
        scanTask = nil

        monitorGeneration += 1
        scanGeneration += 1

        if let presenter {
            NSFileCoordinator.removeFilePresenter(presenter)
            self.presenter = nil
        }

        if didStartSecurityAccess {
            monitoredURL?.stopAccessingSecurityScopedResource()
        }

        didStartSecurityAccess = false
        monitoredURL = nil
    }

    func refresh() {
        Self.ensureLocalFolder()

        scanTask?.cancel()
        scanGeneration += 1
        let generation = scanGeneration
        let externalRoot = monitoredURL
        let presenterSnapshot = presenter

        scanTask = Task.detached(priority: .utility) { [weak self] in
            let local = Self.scan(
                root: Self.localFolderURL,
                source: .capturePilot,
                presenter: nil
            )

            let external: LUTScanResult?
            if let externalRoot {
                external = Self.scan(
                    root: externalRoot,
                    source: .external,
                    presenter: presenterSnapshot
                )
            } else {
                external = nil
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self,
                      generation == self.scanGeneration,
                      !Task.isCancelled else {
                    return
                }

                var combined = local.entries
                var invalidCount = local.invalidCount
                var errors: [String] = []

                if let error = local.errorDescription {
                    errors.append(error)
                }

                var externalSucceeded = false
                if let external {
                    combined.append(contentsOf: external.entries)
                    invalidCount += external.invalidCount
                    externalSucceeded = external.succeeded

                    if let error = external.errorDescription {
                        errors.append(error)
                    }
                }

                self.entries = combined.sorted {
                    if $0.displayName == $1.displayName {
                        return $0.source.rawValue < $1.source.rawValue
                    }
                    return $0.displayName.localizedStandardCompare(
                        $1.displayName
                    ) == .orderedAscending
                }
                self.invalidFileCount = invalidCount
                self.scanErrorDescription =
                    errors.isEmpty ? nil : errors.joined(separator: "\n")

                if let activeEntryID = self.activeEntryID,
                   !self.entries.contains(where: { $0.id == activeEntryID }) {
                    switch self.activeSource {
                    case .capturePilot:
                        if local.succeeded { self.clearActiveLUT() }
                    case .external:
                        if externalSucceeded { self.clearActiveLUT() }
                    case .none:
                        break
                    }
                }
            }
        }
    }

    func activate(_ entry: LUTLibraryEntry) throws {
        let root: URL
        let presenterForRead: NSFilePresenter?
        var shouldStopAccess = false

        switch entry.source {
        case .capturePilot:
            root = Self.localFolderURL
            presenterForRead = nil

        case .external:
            guard let externalRoot = monitoredURL ?? resolvedFolderURL() else {
                throw RawShareProcessingError.invalidLUT
            }

            root = externalRoot
            presenterForRead = presenter

            if monitoredURL == nil {
                let accessed = root.startAccessingSecurityScopedResource()
                guard accessed else { throw RawShareProcessingError.invalidLUT }
                shouldStopAccess = true
            }
        }

        defer {
            if shouldStopAccess {
                root.stopAccessingSecurityScopedResource()
            }
        }

        let sourceURL = root.appendingPathComponent(entry.relativePath)
        var coordinationError: NSError?
        var operationError: Error?

        let coordinator = NSFileCoordinator(filePresenter: presenterForRead)
        coordinator.coordinate(
            readingItemAt: sourceURL,
            options: .withoutChanges,
            error: &coordinationError
        ) { coordinatedURL in
            do {
                _ = try CubeLUT(url: coordinatedURL)
                let data = try Data(contentsOf: coordinatedURL)
                let directory = Self.activeCacheURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                try data.write(to: Self.activeCacheURL, options: .atomic)
            } catch {
                operationError = error
            }
        }

        if let coordinationError { throw coordinationError }
        if let operationError { throw operationError }

        activeEntryID = entry.id
        activeDisplayName = entry.displayName
        activeSource = entry.source
        defaults.set(entry.id, forKey: activeIDKey)
        defaults.set(entry.displayName, forKey: activeNameKey)
        defaults.set(entry.source.rawValue, forKey: activeSourceKey)
    }

    func clearActiveLUT() {
        try? FileManager.default.removeItem(at: Self.activeCacheURL)
        activeEntryID = nil
        activeDisplayName = nil
        activeSource = nil
        defaults.removeObject(forKey: activeIDKey)
        defaults.removeObject(forKey: activeNameKey)
        defaults.removeObject(forKey: activeSourceKey)
    }

    func entry(withID id: String?) -> LUTLibraryEntry? {
        guard let id else { return nil }
        return entries.first(where: { $0.id == id })
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    private func resolvedFolderURL() -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else { return nil }
        return Self.resolveBookmarkData(data).url
    }

    private func refreshStoredBookmark(for url: URL) {
        let key = bookmarkKey
        Task.detached(priority: .utility) { [weak self] in
            guard let fresh = try? url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) else {
                return
            }

            await MainActor.run {
                self?.defaults.set(fresh, forKey: key)
            }
        }
    }

    nonisolated private static func resolveBookmarkData(
        _ data: Data
    ) -> LUTBookmarkResolution {
        var stale = false

        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )

            return LUTBookmarkResolution(
                url: url,
                isStale: stale,
                errorDescription: nil
            )
        } catch {
            return LUTBookmarkResolution(
                url: nil,
                isStale: false,
                errorDescription: error.localizedDescription
            )
        }
    }

    nonisolated private static func scan(
        root: URL,
        source: LUTLibrarySource,
        presenter: NSFilePresenter?
    ) -> LUTScanResult {
        var coordinationError: NSError?
        var scanned: [LUTLibraryEntry] = []
        var invalidCount = 0
        var scanError: String?
        var succeeded = false

        let coordinator = NSFileCoordinator(filePresenter: presenter)
        coordinator.coordinate(
            readingItemAt: root,
            options: .withoutChanges,
            error: &coordinationError
        ) { coordinatedRoot in
            let keys: [URLResourceKey] = [
                .isRegularFileKey
            ]

            guard let enumerator = FileManager.default.enumerator(
                at: coordinatedRoot,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                scanError = "CapturePilot could not enumerate a LUT folder."
                return
            }

            succeeded = true

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension.lowercased() == "cube" else { continue }

                do {
                    let values = try fileURL.resourceValues(forKeys: Set(keys))
                    guard values.isRegularFile == true else { continue }

                    let lut = try CubeLUT(url: fileURL)
                    let relative = relativePath(of: fileURL, from: coordinatedRoot)
                    scanned.append(
                        LUTLibraryEntry(
                            id: "\(source.rawValue):\(relative.lowercased())",
                            source: source,
                            relativePath: relative,
                            displayName: lut.title
                                ?? fileURL.deletingPathExtension().lastPathComponent,
                            dimension: lut.dimension,
                            profile: LUTProfileAnalyzer.profile(for: lut)
                        )
                    )
                } catch {
                    invalidCount += 1
                }
            }
        }

        if let coordinationError {
            scanError = coordinationError.localizedDescription
        }

        return LUTScanResult(
            entries: scanned,
            invalidCount: invalidCount,
            errorDescription: scanError,
            succeeded: succeeded && coordinationError == nil
        )
    }

    nonisolated private static func relativePath(of fileURL: URL, from rootURL: URL) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path

        guard filePath.hasPrefix(rootPath) else {
            return fileURL.lastPathComponent
        }

        let start = filePath.index(filePath.startIndex, offsetBy: rootPath.count)
        return String(filePath[start...]).trimmingCharacters(
            in: CharacterSet(charactersIn: "/")
        )
    }

    nonisolated private static func ensureLocalFolder() {
        try? FileManager.default.createDirectory(
            at: localFolderURL,
            withIntermediateDirectories: true
        )
    }

    nonisolated private static var localFolderURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return documents.appendingPathComponent("LUTs", isDirectory: true)
    }

    nonisolated private static var activeCacheURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent("CapturePilot", isDirectory: true)
            .appendingPathComponent("LUTs", isDirectory: true)
            .appendingPathComponent("LibraryActive.cube")
    }
}

enum LUTProfileAnalyzer {
    static func profile(for lut: CubeLUT) -> LUTProfile {
        let dark = lut.sample(r: 0.12, g: 0.12, b: 0.12)
        let mid = lut.sample(r: 0.50, g: 0.50, b: 0.50)
        let bright = lut.sample(r: 0.88, g: 0.88, b: 0.88)

        let warmth = clamp(
            (Double(mid.x) - Double(mid.z)) * 2.2,
            -1,
            1
        )

        let inputContrast = 0.76
        let outputContrast = luminance(bright) - luminance(dark)
        let contrast = clamp(
            (outputContrast - inputContrast) / 0.30,
            -1,
            1
        )

        let saturatedSamples: [SIMD3<Float>] = [
            lut.sample(r: 0.82, g: 0.18, b: 0.18),
            lut.sample(r: 0.18, g: 0.82, b: 0.18),
            lut.sample(r: 0.18, g: 0.18, b: 0.82)
        ]

        let outputSaturation = saturatedSamples.map { sample in
            let maximum = max(sample.x, max(sample.y, sample.z))
            let minimum = min(sample.x, min(sample.y, sample.z))
            return Double(maximum - minimum)
        }.reduce(0, +) / Double(saturatedSamples.count)

        let saturation = clamp((outputSaturation - 0.64) / 0.32, -1, 1)
        let shadowLift = clamp((luminance(dark) - 0.12) / 0.20, -1, 1)
        let highlightCompression = clamp((0.88 - luminance(bright)) / 0.20, -1, 1)

        let probes: [(Double, Double, Double)] = [
            (0.2, 0.2, 0.2),
            (0.5, 0.5, 0.5),
            (0.8, 0.8, 0.8),
            (0.8, 0.2, 0.2),
            (0.2, 0.8, 0.2),
            (0.2, 0.2, 0.8)
        ]

        let strength = clamp(
            probes.map { r, g, b in
                let output = lut.sample(r: r, g: g, b: b)
                let dr = Double(output.x) - r
                let dg = Double(output.y) - g
                let db = Double(output.z) - b
                return sqrt(dr * dr + dg * dg + db * db)
            }.reduce(0, +) / Double(probes.count) / 0.35,
            0,
            1
        )

        return LUTProfile(
            warmth: warmth,
            contrast: contrast,
            saturation: saturation,
            shadowLift: shadowLift,
            highlightCompression: highlightCompression,
            strength: strength
        )
    }

    private static func luminance(_ color: SIMD3<Float>) -> Double {
        0.2126 * Double(color.x)
            + 0.7152 * Double(color.y)
            + 0.0722 * Double(color.z)
    }

    private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }
}
