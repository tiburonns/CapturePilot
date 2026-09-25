import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case system, english, spanish
        var id: String { rawValue }
    }

    enum Grid: String, CaseIterable, Identifiable {
        case none, thirds, goldenRatio, crosshair
        var id: String { rawValue }
    }

    enum CoachIntensity: String, CaseIterable, Identifiable {
        case subtle, balanced, teaching
        var id: String { rawValue }
    }

    private enum Key {
        static let language = "settings.language"
        static let grid = "settings.grid"
        static let coachIntensity = "settings.coachIntensity"
    }

    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Key.language) }
    }

    @Published var grid: Grid {
        didSet { UserDefaults.standard.set(grid.rawValue, forKey: Key.grid) }
    }

    @Published var coachIntensity: CoachIntensity {
        didSet { UserDefaults.standard.set(coachIntensity.rawValue, forKey: Key.coachIntensity) }
    }

    init() {
        let defaults = UserDefaults.standard
        language = Language(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system
        grid = Grid(rawValue: defaults.string(forKey: Key.grid) ?? "") ?? .thirds
        coachIntensity = CoachIntensity(rawValue: defaults.string(forKey: Key.coachIntensity) ?? "") ?? .balanced
    }

    func text(_ key: LocalizedKey) -> String {
        key.value(in: resolvedLanguage)
    }

    private var resolvedLanguage: Language {
        guard language == .system else { return language }
        return Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true ? .spanish : .english
    }
}

enum LocalizedKey: Hashable {
    case coach, pro, capture, settings, grid, language, system, english, spanish, done, off
    case subtle, balanced, teaching, privacy, privacyDetail, version
    case auto, heif, jpeg, raw, exposure, iso, shutter, whiteBalance, focus
    case cameraPermission, openSettings, noCamera, saved, saveFailed, rawUnavailable
    case levelCamera, moveLeft, moveRight, moveUp, moveDown, tooDark, tooBright
    case goodBalance, subjectOnThird, reduceHeadroom, ready, tapToFocus

    func value(in language: AppSettings.Language) -> String {
        let es: [LocalizedKey: String] = [
            .coach: "Coach", .pro: "Pro", .capture: "Captura", .settings: "Ajustes",
            .grid: "Guía", .language: "Idioma", .system: "Sistema", .english: "Inglés", .spanish: "Español",
            .done: "Listo", .off: "Desactivada",
            .subtle: "Sutil", .balanced: "Equilibrado", .teaching: "Didáctico",
            .privacy: "Privacidad", .privacyDetail: "El análisis del coach se realiza en el dispositivo. Sin cuenta, anuncios ni rastreadores.",
            .version: "Versión", .auto: "Auto", .heif: "HEIF", .jpeg: "JPEG", .raw: "RAW",
            .exposure: "Exposición", .iso: "ISO", .shutter: "Obturación", .whiteBalance: "Balance de blancos", .focus: "Enfoque",
            .cameraPermission: "CapturePilot necesita acceso a la cámara para mostrar el visor, analizar la escena y tomar fotografías.",
            .openSettings: "Abrir Ajustes", .noCamera: "No se encontró una cámara trasera compatible.",
            .saved: "Foto guardada", .saveFailed: "No se pudo guardar la foto", .rawUnavailable: "RAW no está disponible con esta configuración.",
            .levelCamera: "Nivela la cámara", .moveLeft: "Muévete un poco a la izquierda", .moveRight: "Muévete un poco a la derecha",
            .moveUp: "Sube ligeramente el encuadre", .moveDown: "Baja ligeramente el encuadre",
            .tooDark: "La escena está oscura: abre exposición o estabiliza", .tooBright: "Altas luces cerca del recorte: baja exposición",
            .goodBalance: "Buen equilibrio visual", .subjectOnThird: "El sujeto está cerca de un punto fuerte",
            .reduceHeadroom: "Reduce el aire sobre el sujeto", .ready: "Encuadre listo", .tapToFocus: "Toca el visor para enfocar"
        ]

        let en: [LocalizedKey: String] = [
            .coach: "Coach", .pro: "Pro", .capture: "Capture", .settings: "Settings",
            .grid: "Guide", .language: "Language", .system: "System", .english: "English", .spanish: "Spanish",
            .done: "Done", .off: "Off",
            .subtle: "Subtle", .balanced: "Balanced", .teaching: "Teaching",
            .privacy: "Privacy", .privacyDetail: "Coach analysis runs on-device. No account, ads, or trackers.",
            .version: "Version", .auto: "Auto", .heif: "HEIF", .jpeg: "JPEG", .raw: "RAW",
            .exposure: "Exposure", .iso: "ISO", .shutter: "Shutter", .whiteBalance: "White balance", .focus: "Focus",
            .cameraPermission: "CapturePilot needs camera access to show the viewfinder, analyze the scene, and take photos.",
            .openSettings: "Open Settings", .noCamera: "No compatible rear camera was found.",
            .saved: "Photo saved", .saveFailed: "Could not save the photo", .rawUnavailable: "RAW is unavailable with this configuration.",
            .levelCamera: "Level the camera", .moveLeft: "Move slightly left", .moveRight: "Move slightly right",
            .moveUp: "Raise the framing slightly", .moveDown: "Lower the framing slightly",
            .tooDark: "Scene is dark: open exposure or stabilize", .tooBright: "Highlights are near clipping: lower exposure",
            .goodBalance: "Good visual balance", .subjectOnThird: "Subject is near a strong point",
            .reduceHeadroom: "Reduce headroom above the subject", .ready: "Frame ready", .tapToFocus: "Tap the viewfinder to focus"
        ]

        return (language == .spanish ? es : en)[self] ?? String(describing: self)
    }
}
