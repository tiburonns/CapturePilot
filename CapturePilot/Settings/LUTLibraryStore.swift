import Foundation

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
    let relativePath: String
    let displayName: String
    let dimension: Int
    let profile: LUTProfile
    let modifiedDate: Date?
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
    @Published private(set) var invalidFileCount = 0
    @Published private(set) var scanErrorDescription: String?

    private let defaults = UserDefaults.standard
    private let bookmarkKey = "lutLibrary.folderBookmark.v1"
    private let activeIDKey = "lutLibrary.activeEntryID.v1"
    private let activeNameKey = "lutLibrary.activeDisplayName.v1"

    private var monitoredURL: URL?
    private var didStartSecurityAccess = false
    private var presenter: LUTFolderPresenter?
    private var refreshTask: Task<Void, Never>?

    init() {
        activeEntryID = defaults.string(forKey: activeIDKey)
        activeDisplayName = defaults.string(forKey: activeNameKey)
        folderDisplayName = resolvedFolderURL()?.lastPathComponent
    }

    deinit {
        refreshTask?.cancel()
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
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(data, forKey: bookmarkKey)
        folderDisplayName = url.lastPathComponent

        startMonitoring()
    }

    func clearFolder() {
        stopMonitoring()
        defaults.removeObject(forKey: bookmarkKey)
        folderDisplayName = nil
        entries = []
        invalidFileCount = 0
        scanErrorDescription = nil
        clearActiveLUT()
    }

    func startMonitoring() {
        guard monitoredURL == nil, let url = resolvedFolderURL() else {
            if monitoredURL != nil { refresh() }
            return
        }

        let accessed = url.startAccessingSecurityScopedResource()
        guard accessed else {
            scanErrorDescription = "CapturePilot could not reopen the selected LUT folder."
            return
        }

        didStartSecurityAccess = true
        monitoredURL = url
        folderDisplayName = url.lastPathComponent

        let presenter = LUTFolderPresenter(url: url) { [weak self] in
            Task { @MainActor in
                self?.scheduleRefresh()
            }
        }
        self.presenter = presenter
        NSFileCoordinator.addFilePresenter(presenter)

        refresh()
    }

    func stopMonitoring() {
        refreshTask?.cancel()
        refreshTask = nil

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
        guard let root = monitoredURL ?? resolvedFolderURL() else {
            entries = []
            return
        }

        let temporaryAccess = monitoredURL == nil
        let accessed = temporaryAccess ? root.startAccessingSecurityScopedResource() : true

        guard accessed else {
            scanErrorDescription = "CapturePilot could not access the selected LUT folder."
            return
        }

        if temporaryAccess {
            defer { root.stopAccessingSecurityScopedResource() }
        }

        let coordinator = NSFileCoordinator(filePresenter: presenter)
        var coordinationError: NSError?
        var scanned: [LUTLibraryEntry] = []
        var invalidCount = 0
        var scanError: String?

        coordinator.coordinate(
            readingItemAt: root,
            options: .withoutChanges,
            error: &coordinationError
        ) { coordinatedRoot in
            let keys: [URLResourceKey] = [
                .isRegularFileKey,
                .contentModificationDateKey
            ]

            guard let enumerator = FileManager.default.enumerator(
                at: coordinatedRoot,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                scanError = "CapturePilot could not enumerate the LUT folder."
                return
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension.lowercased() == "cube" else { continue }

                do {
                    let values = try fileURL.resourceValues(forKeys: Set(keys))
                    guard values.isRegularFile == true else { continue }

                    let lut = try CubeLUT(url: fileURL)
                    let relative = Self.relativePath(of: fileURL, from: coordinatedRoot)
                    scanned.append(
                        LUTLibraryEntry(
                            id: relative.lowercased(),
                            relativePath: relative,
                            displayName: lut.title
                                ?? fileURL.deletingPathExtension().lastPathComponent,
                            dimension: lut.dimension,
                            profile: LUTProfileAnalyzer.profile(for: lut),
                            modifiedDate: values.contentModificationDate
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

        entries = scanned.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
        invalidFileCount = invalidCount
        scanErrorDescription = scanError

        if let activeEntryID,
           !entries.contains(where: { $0.id == activeEntryID }) {
            clearActiveLUT()
        }
    }

    func activate(_ entry: LUTLibraryEntry) throws {
        guard let root = monitoredURL ?? resolvedFolderURL() else {
            throw RawShareProcessingError.invalidLUT
        }

        let temporaryAccess = monitoredURL == nil
        let accessed = temporaryAccess ? root.startAccessingSecurityScopedResource() : true
        guard accessed else { throw RawShareProcessingError.invalidLUT }

        if temporaryAccess {
            defer { root.stopAccessingSecurityScopedResource() }
        }

        let sourceURL = root.appendingPathComponent(entry.relativePath)
        var coordinationError: NSError?
        var operationError: Error?

        let coordinator = NSFileCoordinator(filePresenter: presenter)
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
        defaults.set(entry.id, forKey: activeIDKey)
        defaults.set(entry.displayName, forKey: activeNameKey)
    }

    func clearActiveLUT() {
        try? FileManager.default.removeItem(at: Self.activeCacheURL)
        activeEntryID = nil
        activeDisplayName = nil
        defaults.removeObject(forKey: activeIDKey)
        defaults.removeObject(forKey: activeNameKey)
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

        var stale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )

            if stale {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed { url.stopAccessingSecurityScopedResource() }
                }

                if accessed,
                   let fresh = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                   ) {
                    defaults.set(fresh, forKey: bookmarkKey)
                }
            }

            return url
        } catch {
            return nil
        }
    }

    private static func relativePath(of fileURL: URL, from rootURL: URL) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path

        guard filePath.hasPrefix(rootPath) else {
            return fileURL.lastPathComponent
        }

        let start = filePath.index(filePath.startIndex, offsetBy: rootPath.count)
        return String(filePath[start...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private static var activeCacheURL: URL {
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

        let saturatedSamples: [(SIMD3<Float>, Double)] = [
            (lut.sample(r: 0.82, g: 0.18, b: 0.18), 0.64),
            (lut.sample(r: 0.18, g: 0.82, b: 0.18), 0.64),
            (lut.sample(r: 0.18, g: 0.18, b: 0.82), 0.64)
        ]

        let outputSaturation = saturatedSamples.map { sample, _ in
            Double(max(sample.x, sample.y, sample.z) - min(sample.x, sample.y, sample.z))
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
