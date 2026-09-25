import SwiftUI

enum HUDItem: String, CaseIterable, Codable, Identifiable {
    case pro
    case language
    case settings
    case lenses
    case scene
    case coach
    case metrics
    case photoFormat
    case shutter
    case grid
    case focusPeaking

    var id: String { rawValue }

    var canHide: Bool {
        switch self {
        case .settings, .shutter:
            return false
        default:
            return true
        }
    }

    var localizedKey: LocalizedKey {
        switch self {
        case .pro: return .proControls
        case .language: return .language
        case .settings: return .settings
        case .lenses: return .lenses
        case .scene: return .scene
        case .coach: return .coach
        case .metrics: return .metrics
        case .photoFormat: return .photoFormat
        case .shutter: return .shutterButton
        case .grid: return .gridButton
        case .focusPeaking: return .focusPeakingQuick
        }
    }
}

struct HUDNormalizedPoint: Codable, Equatable {
    var x: Double
    var y: Double
}

struct HUDItemConfiguration: Codable, Equatable {
    var visible: Bool
    var portrait: HUDNormalizedPoint
    var landscape: HUDNormalizedPoint
}

private struct HUDLayoutSnapshot: Codable {
    var items: [String: HUDItemConfiguration]
}

@MainActor
final class HUDLayoutStore: ObservableObject {
    @Published private(set) var configurations: [HUDItem: HUDItemConfiguration]
    @Published var isEditing = false

    private let defaults = UserDefaults.standard
    private let storageKey = "hud.layout.v1"

    init() {
        let baseline = Self.defaultConfigurations()

        if let data = defaults.data(forKey: storageKey),
           let snapshot = try? JSONDecoder().decode(HUDLayoutSnapshot.self, from: data) {
            var merged = baseline
            for item in HUDItem.allCases {
                if let saved = snapshot.items[item.rawValue] {
                    merged[item] = saved
                }
            }
            configurations = merged
        } else {
            configurations = baseline
        }
    }

    func isVisible(_ item: HUDItem) -> Bool {
        configurations[item]?.visible ?? true
    }

    func setVisible(_ item: HUDItem, _ visible: Bool) {
        guard item.canHide || visible else { return }
        guard var config = configurations[item] else { return }
        config.visible = item.canHide ? visible : true
        configurations[item] = config
        save()
    }

    func point(for item: HUDItem, isLandscape: Bool) -> HUDNormalizedPoint {
        guard let config = configurations[item] else {
            return HUDNormalizedPoint(x: 0.5, y: 0.5)
        }
        return isLandscape ? config.landscape : config.portrait
    }

    func setPoint(_ point: HUDNormalizedPoint, for item: HUDItem, isLandscape: Bool) {
        guard var config = configurations[item] else { return }
        let normalized = HUDNormalizedPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )

        if isLandscape {
            config.landscape = normalized
        } else {
            config.portrait = normalized
        }

        configurations[item] = config
        save()
    }

    func reset() {
        configurations = Self.defaultConfigurations()
        save()
    }

    private func save() {
        let raw = Dictionary(
            uniqueKeysWithValues: configurations.map { ($0.key.rawValue, $0.value) }
        )
        let snapshot = HUDLayoutSnapshot(items: raw)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func defaultConfigurations() -> [HUDItem: HUDItemConfiguration] {
        func config(
            _ visible: Bool = true,
            portrait: (Double, Double),
            landscape: (Double, Double)
        ) -> HUDItemConfiguration {
            HUDItemConfiguration(
                visible: visible,
                portrait: HUDNormalizedPoint(x: portrait.0, y: portrait.1),
                landscape: HUDNormalizedPoint(x: landscape.0, y: landscape.1)
            )
        }

        return [
            .pro: config(portrait: (0.08, 0.07), landscape: (0.06, 0.10)),
            .language: config(portrait: (0.72, 0.07), landscape: (0.76, 0.10)),
            .settings: config(portrait: (0.93, 0.07), landscape: (0.95, 0.10)),
            .lenses: config(portrait: (0.50, 0.15), landscape: (0.48, 0.11)),
            .scene: config(portrait: (0.86, 0.16), landscape: (0.90, 0.20)),
            .coach: config(portrait: (0.50, 0.68), landscape: (0.50, 0.55)),
            .metrics: config(portrait: (0.50, 0.75), landscape: (0.50, 0.67)),
            .photoFormat: config(portrait: (0.12, 0.92), landscape: (0.18, 0.87)),
            .shutter: config(portrait: (0.50, 0.91), landscape: (0.50, 0.84)),
            .grid: config(portrait: (0.88, 0.92), landscape: (0.82, 0.87)),
            .focusPeaking: config(false, portrait: (0.94, 0.50), landscape: (0.96, 0.50))
        ]
    }
}
