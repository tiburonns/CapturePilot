import CoreImage
import Foundation

struct LUTCube: Identifiable, Hashable {
    let id: String
    let name: String
    let dimension: Int
    let data: Data
    let domainMin: SIMD3<Float>
    let domainMax: SIMD3<Float>
    let isImported: Bool

    static func == (lhs: LUTCube, rhs: LUTCube) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
final class LUTStore: ObservableObject {
    private enum Key {
        static let selectedID = "settings.quickShare.selectedLUT"
    }

    @Published private(set) var cubes: [LUTCube] = []
    @Published var selectedID: String {
        didSet { UserDefaults.standard.set(selectedID, forKey: Key.selectedID) }
    }
    @Published private(set) var lastImportError: String?

    private let fileManager = FileManager.default

    init() {
        let saved = UserDefaults.standard.string(forKey: Key.selectedID)
        selectedID = saved ?? "builtin.capturepilot-natural"
        reload()
    }

    var selectedCube: LUTCube {
        cubes.first(where: { $0.id == selectedID })
            ?? cubes.first
            ?? Self.identityCube()
    }

    var importedCubes: [LUTCube] {
        cubes.filter(\.isImported)
    }

    func reload() {
        var loaded = Self.builtInCubes()

        if let directory = try? lutDirectory() {
            let urls = (try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []

            for url in urls where url.pathExtension.lowercased() == "cube" {
                if let cube = try? Self.parseCube(at: url, imported: true) {
                    loaded.append(cube)
                }
            }
        }

        loaded.sort {
            if $0.isImported != $1.isImported {
                return !$0.isImported
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        cubes = loaded

        if !cubes.contains(where: { $0.id == selectedID }) {
            selectedID = cubes.first?.id ?? "builtin.capturepilot-natural"
        }
    }

    func importCubeFiles(_ urls: [URL]) {
        lastImportError = nil
        var failures: [String] = []

        guard let directory = try? lutDirectory() else {
            lastImportError = "Unable to create LUT directory."
            return
        }

        for sourceURL in urls {
            let accessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessing { sourceURL.stopAccessingSecurityScopedResource() }
            }

            do {
                _ = try Self.parseCube(at: sourceURL, imported: true)

                let baseName = sourceURL.deletingPathExtension().lastPathComponent
                let safeName = sanitizedFileName(baseName)
                var destination = directory
                    .appendingPathComponent(safeName)
                    .appendingPathExtension("cube")

                var suffix = 2
                while fileManager.fileExists(atPath: destination.path) {
                    destination = directory
                        .appendingPathComponent("\(safeName)-\(suffix)")
                        .appendingPathExtension("cube")
                    suffix += 1
                }

                try fileManager.copyItem(at: sourceURL, to: destination)
            } catch {
                failures.append(sourceURL.lastPathComponent)
            }
        }

        reload()

        if !failures.isEmpty {
            lastImportError = "Could not import: " + failures.joined(separator: ", ")
        }
    }

    func removeImportedCube(_ cube: LUTCube) {
        guard cube.isImported,
              let directory = try? lutDirectory() else { return }

        let candidate = directory.appendingPathComponent(cube.id)
        if fileManager.fileExists(atPath: candidate.path) {
            try? fileManager.removeItem(at: candidate)
        } else {
            let urls = (try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )) ?? []
            if let match = urls.first(where: {
                "imported." + $0.lastPathComponent == cube.id
            }) {
                try? fileManager.removeItem(at: match)
            }
        }

        reload()
    }

    private func lutDirectory() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base
            .appendingPathComponent("CapturePilot", isDirectory: true)
            .appendingPathComponent("LUTs", isDirectory: true)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func sanitizedFileName(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-_ "))
        let scalars = input.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(String(scalar)) : "-"
        }
        let result = String(scalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "Imported-LUT" : result
    }

    private static func builtInCubes() -> [LUTCube] {
        [
            makeBuiltIn(
                id: "builtin.capturepilot-natural",
                name: "CapturePilot Natural"
            ) { r, g, b in
                let contrast: (Float) -> Float = { value in
                    let centered = (value - 0.5) * 1.06 + 0.5
                    return min(1, max(0, centered))
                }
                let rr = contrast(r)
                let gg = contrast(g)
                let bb = contrast(b)
                let luma = rr * 0.2126 + gg * 0.7152 + bb * 0.0722
                let saturation: Float = 1.035
                return SIMD3<Float>(
                    luma + (rr - luma) * saturation + 0.006,
                    luma + (gg - luma) * saturation + 0.002,
                    luma + (bb - luma) * saturation - 0.003
                ).clamped01
            },
            makeBuiltIn(
                id: "builtin.capturepilot-clean",
                name: "CapturePilot Clean"
            ) { r, g, b in
                let curve: (Float) -> Float = { value in
                    let x = min(1, max(0, value))
                    return min(1, max(0, x * x * (3 - 2 * x)))
                }
                return SIMD3<Float>(curve(r), curve(g), curve(b)).clamped01
            },
            makeBuiltIn(
                id: "builtin.capturepilot-warm",
                name: "CapturePilot Warm"
            ) { r, g, b in
                SIMD3<Float>(
                    r * 1.035 + 0.008,
                    g * 1.005 + 0.002,
                    b * 0.965
                ).clamped01
            },
            identityCube()
        ]
    }

    private static func identityCube() -> LUTCube {
        makeBuiltIn(
            id: "builtin.neutral",
            name: "Neutral"
        ) { r, g, b in
            SIMD3<Float>(r, g, b)
        }
    }

    private static func makeBuiltIn(
        id: String,
        name: String,
        dimension: Int = 17,
        transform: (Float, Float, Float) -> SIMD3<Float>
    ) -> LUTCube {
        var values = [Float]()
        values.reserveCapacity(dimension * dimension * dimension * 4)
        let denominator = Float(max(1, dimension - 1))

        for b in 0..<dimension {
            for g in 0..<dimension {
                for r in 0..<dimension {
                    let inputR = Float(r) / denominator
                    let inputG = Float(g) / denominator
                    let inputB = Float(b) / denominator
                    let output = transform(inputR, inputG, inputB).clamped01
                    values.append(contentsOf: [output.x, output.y, output.z, 1])
                }
            }
        }

        return LUTCube(
            id: id,
            name: name,
            dimension: dimension,
            data: values.withUnsafeBytes { Data($0) },
            domainMin: SIMD3<Float>(repeating: 0),
            domainMax: SIMD3<Float>(repeating: 1),
            isImported: false
        )
    }

    private static func parseCube(at url: URL, imported: Bool) throws -> LUTCube {
        let text = try String(contentsOf: url, encoding: .utf8)
        var dimension: Int?
        var title: String?
        var domainMin = SIMD3<Float>(repeating: 0)
        var domainMax = SIMD3<Float>(repeating: 1)
        var triples: [SIMD3<Float>] = []

        for rawLine in text.components(separatedBy: .newlines) {
            let noComment = rawLine.split(separator: "#", maxSplits: 1).first.map(String.init) ?? ""
            let line = noComment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("TITLE") {
                if let firstQuote = line.firstIndex(of: "\""),
                   let lastQuote = line.lastIndex(of: "\""),
                   firstQuote < lastQuote {
                    title = String(line[line.index(after: firstQuote)..<lastQuote])
                }
                continue
            }

            if line.hasPrefix("LUT_1D_SIZE") {
                throw LUTError.unsupported1D
            }

            if line.hasPrefix("LUT_3D_SIZE") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count == 2, let value = Int(parts[1]), (2...128).contains(value) {
                    dimension = value
                    triples.reserveCapacity(value * value * value)
                } else {
                    throw LUTError.invalidSize
                }
                continue
            }

            if line.hasPrefix("DOMAIN_MIN") {
                domainMin = try parseVector(line)
                continue
            }

            if line.hasPrefix("DOMAIN_MAX") {
                domainMax = try parseVector(line)
                continue
            }

            if line.hasPrefix("LUT_3D_INPUT_RANGE") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                guard parts.count == 3,
                      let low = Float(parts[1]),
                      let high = Float(parts[2]) else {
                    throw LUTError.invalidDomain
                }
                domainMin = SIMD3<Float>(repeating: low)
                domainMax = SIMD3<Float>(repeating: high)
                continue
            }

            let parts = line.split(whereSeparator: { $0.isWhitespace })
            if parts.count >= 3,
               let r = Float(parts[0]),
               let g = Float(parts[1]),
               let b = Float(parts[2]) {
                triples.append(SIMD3<Float>(r, g, b))
            }
        }

        guard let dimension else { throw LUTError.missingSize }
        guard triples.count == dimension * dimension * dimension else {
            throw LUTError.invalidEntryCount
        }

        guard domainMax.x > domainMin.x,
              domainMax.y > domainMin.y,
              domainMax.z > domainMin.z else {
            throw LUTError.invalidDomain
        }

        var rgba = [Float]()
        rgba.reserveCapacity(triples.count * 4)
        for triple in triples {
            let output = triple.clamped01
            rgba.append(contentsOf: [output.x, output.y, output.z, 1])
        }

        return LUTCube(
            id: imported ? "imported." + url.lastPathComponent : url.lastPathComponent,
            name: title?.isEmpty == false
                ? title!
                : url.deletingPathExtension().lastPathComponent,
            dimension: dimension,
            data: rgba.withUnsafeBytes { Data($0) },
            domainMin: domainMin,
            domainMax: domainMax,
            isImported: imported
        )
    }

    private static func parseVector(_ line: String) throws -> SIMD3<Float> {
        let parts = line.split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 4,
              let x = Float(parts[1]),
              let y = Float(parts[2]),
              let z = Float(parts[3]) else {
            throw LUTError.invalidDomain
        }
        return SIMD3<Float>(x, y, z)
    }

    private enum LUTError: Error {
        case unsupported1D
        case invalidSize
        case missingSize
        case invalidEntryCount
        case invalidDomain
    }
}

private extension SIMD3 where Scalar == Float {
    var clamped01: SIMD3<Float> {
        SIMD3<Float>(
            min(1, max(0, x)),
            min(1, max(0, y)),
            min(1, max(0, z))
        )
    }
}
