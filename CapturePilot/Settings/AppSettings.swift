import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case system, english, spanish
        var id: String { rawValue }
    }

    enum Grid: String, CaseIterable, Identifiable {
        case none, thirds, goldenRatio, goldenSpiral, goldenTriangle, crosshair
        var id: String { rawValue }
    }

    enum CoachIntensity: String, CaseIterable, Identifiable {
        case subtle, balanced, teaching
        var id: String { rawValue }
    }

    enum SceneCoach: String, CaseIterable, Identifiable {
        case general, portrait, architecture, automotive, macro, street, landscape, night
        var id: String { rawValue }
    }

    private enum Key {
        static let language = "settings.language"
        static let grid = "settings.grid"
        static let coachIntensity = "settings.coachIntensity"
        static let sceneCoach = "settings.sceneCoach"
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

    @Published var sceneCoach: SceneCoach {
        didSet { UserDefaults.standard.set(sceneCoach.rawValue, forKey: Key.sceneCoach) }
    }

    @Published var allowLandscape: Bool {
        didSet {
            UserDefaults.standard.set(allowLandscape, forKey: OrientationPolicy.landscapeKey)
            OrientationPolicy.applyCurrentPolicy()
        }
    }

    @Published var allowUpsideDown: Bool {
        didSet {
            UserDefaults.standard.set(allowUpsideDown, forKey: OrientationPolicy.upsideDownKey)
            OrientationPolicy.applyCurrentPolicy()
        }
    }

    init() {
        let defaults = UserDefaults.standard
        language = Language(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system
        grid = Grid(rawValue: defaults.string(forKey: Key.grid) ?? "") ?? .thirds
        coachIntensity = CoachIntensity(rawValue: defaults.string(forKey: Key.coachIntensity) ?? "") ?? .balanced
        sceneCoach = SceneCoach(rawValue: defaults.string(forKey: Key.sceneCoach) ?? "") ?? .general
        allowLandscape = Self.boolValue(
            defaults,
            key: OrientationPolicy.landscapeKey,
            defaultValue: true
        )
        allowUpsideDown = Self.boolValue(
            defaults,
            key: OrientationPolicy.upsideDownKey,
            defaultValue: true
        )
    }

    func text(_ key: LocalizedKey) -> String {
        key.value(in: resolvedLanguage)
    }

    func languageName(_ language: Language) -> String {
        switch language {
        case .system: text(.system)
        case .english: text(.english)
        case .spanish: text(.spanish)
        }
    }

    func sceneName(_ scene: SceneCoach) -> String {
        switch scene {
        case .general: text(.sceneGeneral)
        case .portrait: text(.scenePortrait)
        case .architecture: text(.sceneArchitecture)
        case .automotive: text(.sceneAutomotive)
        case .macro: text(.sceneMacro)
        case .street: text(.sceneStreet)
        case .landscape: text(.sceneLandscape)
        case .night: text(.sceneNight)
        }
    }

    var languageBadge: String {
        switch language {
        case .system: "AUTO"
        case .english: "EN"
        case .spanish: "ES"
        }
    }

    private var resolvedLanguage: Language {
        guard language == .system else { return language }
        return Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
            ? .spanish
            : .english
    }

    private static func boolValue(
        _ defaults: UserDefaults,
        key: String,
        defaultValue: Bool
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}

enum LocalizedKey: Hashable {
    case coach, pro, capture, settings, grid, language, system, english, spanish, done, off
    case subtle, balanced, teaching, privacy, privacyDetail, version
    case auto, heif, jpeg, raw, proRAW, exposure, iso, shutter, whiteBalance, focus
    case resolution, scene
    case cameraPermission, openSettings, noCamera, saved, saveFailed, rawUnavailable
    case cameraInterrupted, cameraRuntimeError
    case levelCamera, moveLeft, moveRight, moveUp, moveDown, tooDark, tooBright
    case goodBalance, subjectOnThird, reduceHeadroom, ready, tapToFocus
    case followLeadingLines, symmetryStrong, alignSymmetry, vanishingPointFound
    case useNegativeSpace, goldenSpiralBalance, goldenTriangleBalance, moveTowardGoldenPoint
    case refineFocus, stabilizeCamera, protectHighlights
    case sceneGeneral, scenePortrait, sceneArchitecture, sceneAutomotive
    case sceneMacro, sceneStreet, sceneLandscape, sceneNight
    case goldenSpiral, goldenTriangle
    case orientation, landscape, upsideDown, orientationDetail
    case hud, customizeHUD, hudDetail, hudElements, resetHUD, required
    case focusPeaking, focusPeakingQuick, lenses, metrics, photoFormat
    case shutterButton, gridButton, proControls

    func value(in language: AppSettings.Language) -> String {
        let es: [LocalizedKey: String] = [
            .coach: "Coach", .pro: "Pro", .capture: "Captura", .settings: "Ajustes",
            .grid: "Guía", .language: "Idioma", .system: "Sistema", .english: "Inglés",
            .spanish: "Español", .done: "Listo", .off: "Desactivada",
            .subtle: "Sutil", .balanced: "Equilibrado", .teaching: "Didáctico",
            .privacy: "Privacidad",
            .privacyDetail: "El análisis del coach se realiza en el dispositivo. Sin cuenta, anuncios, analítica ni rastreadores.",
            .version: "Versión", .auto: "Auto", .heif: "HEIF", .jpeg: "JPEG",
            .raw: "RAW", .proRAW: "ProRAW", .exposure: "Exposición", .iso: "ISO",
            .shutter: "Obturación", .whiteBalance: "Balance de blancos", .focus: "Enfoque",
            .resolution: "Resolución", .scene: "Escena",
            .cameraPermission: "CapturePilot necesita acceso a la cámara para mostrar el visor, analizar la escena y tomar fotografías.",
            .openSettings: "Abrir Ajustes", .noCamera: "No se encontró una cámara trasera compatible.",
            .saved: "Foto guardada", .saveFailed: "No se pudo guardar la foto",
            .rawUnavailable: "RAW no está disponible con esta configuración.",
            .cameraInterrupted: "La cámara está temporalmente interrumpida.",
            .cameraRuntimeError: "La sesión de cámara tuvo un error. CapturePilot intentará recuperarla.",
            .levelCamera: "Nivela la cámara", .moveLeft: "Mueve el encuadre a la izquierda",
            .moveRight: "Mueve el encuadre a la derecha", .moveUp: "Sube ligeramente el encuadre",
            .moveDown: "Baja ligeramente el encuadre",
            .tooDark: "La escena está oscura: abre exposición o estabiliza",
            .tooBright: "Altas luces cerca del recorte: baja exposición",
            .goodBalance: "Buen equilibrio visual", .subjectOnThird: "El sujeto está cerca de un punto fuerte",
            .reduceHeadroom: "Reduce el aire sobre el sujeto", .ready: "Encuadre listo",
            .tapToFocus: "Toca el visor para enfocar",
            .followLeadingLines: "Usa las líneas para guiar la mirada",
            .symmetryStrong: "La simetría está bien definida",
            .alignSymmetry: "Centra o refuerza el eje de simetría",
            .vanishingPointFound: "El punto de fuga puede reforzar la profundidad",
            .useNegativeSpace: "Aprovecha el espacio negativo alrededor del sujeto",
            .goldenSpiralBalance: "El sujeto encaja bien con la espiral áurea",
            .goldenTriangleBalance: "La geometría encaja con el triángulo áureo",
            .moveTowardGoldenPoint: "Acerca el sujeto a un punto áureo",
            .refineFocus: "Refina el enfoque sobre el detalle principal",
            .stabilizeCamera: "Estabiliza la cámara antes de capturar",
            .protectHighlights: "Protege luces puntuales sin levantar demasiado las sombras",
            .sceneGeneral: "General", .scenePortrait: "Retrato",
            .sceneArchitecture: "Arquitectura", .sceneAutomotive: "Automotriz",
            .sceneMacro: "Macro", .sceneStreet: "Calle",
            .sceneLandscape: "Paisaje", .sceneNight: "Noche",
            .goldenSpiral: "Espiral áurea", .goldenTriangle: "Triángulo áureo",
            .orientation: "Orientación", .landscape: "Horizontal",
            .upsideDown: "Vertical invertido",
            .orientationDetail: "Vertical normal permanece siempre disponible. Puedes desactivar horizontal o vertical invertido de forma independiente.",
            .hud: "HUD", .customizeHUD: "Personalizar HUD",
            .hudDetail: "Mueve los elementos libremente dentro del área segura. Vertical y horizontal guardan posiciones independientes.",
            .hudElements: "Elementos", .resetHUD: "Restablecer HUD", .required: "Obligatorio",
            .focusPeaking: "Focus Peaking",
            .focusPeakingQuick: "Acceso rápido Focus Peaking",
            .lenses: "Lentes", .metrics: "Métricas", .photoFormat: "Formato",
            .shutterButton: "Disparador", .gridButton: "Botón de guía",
            .proControls: "Controles Pro"
        ]

        let en: [LocalizedKey: String] = [
            .coach: "Coach", .pro: "Pro", .capture: "Capture", .settings: "Settings",
            .grid: "Guide", .language: "Language", .system: "System", .english: "English",
            .spanish: "Spanish", .done: "Done", .off: "Off",
            .subtle: "Subtle", .balanced: "Balanced", .teaching: "Teaching",
            .privacy: "Privacy",
            .privacyDetail: "Coach analysis runs on-device. No account, ads, analytics, or trackers.",
            .version: "Version", .auto: "Auto", .heif: "HEIF", .jpeg: "JPEG",
            .raw: "RAW", .proRAW: "ProRAW", .exposure: "Exposure", .iso: "ISO",
            .shutter: "Shutter", .whiteBalance: "White balance", .focus: "Focus",
            .resolution: "Resolution", .scene: "Scene",
            .cameraPermission: "CapturePilot needs camera access to show the viewfinder, analyze the scene, and take photos.",
            .openSettings: "Open Settings", .noCamera: "No compatible rear camera was found.",
            .saved: "Photo saved", .saveFailed: "Could not save the photo",
            .rawUnavailable: "RAW is unavailable with this configuration.",
            .cameraInterrupted: "The camera is temporarily interrupted.",
            .cameraRuntimeError: "The camera session hit an error. CapturePilot will try to recover it.",
            .levelCamera: "Level the camera", .moveLeft: "Move the framing left",
            .moveRight: "Move the framing right", .moveUp: "Raise the framing slightly",
            .moveDown: "Lower the framing slightly",
            .tooDark: "Scene is dark: open exposure or stabilize",
            .tooBright: "Highlights are near clipping: lower exposure",
            .goodBalance: "Good visual balance", .subjectOnThird: "Subject is near a strong point",
            .reduceHeadroom: "Reduce headroom above the subject", .ready: "Frame ready",
            .tapToFocus: "Tap the viewfinder to focus",
            .followLeadingLines: "Use the lines to guide the viewer",
            .symmetryStrong: "Symmetry is well defined",
            .alignSymmetry: "Center or strengthen the symmetry axis",
            .vanishingPointFound: "The vanishing point can reinforce depth",
            .useNegativeSpace: "Use the negative space around the subject",
            .goldenSpiralBalance: "The subject fits the golden spiral well",
            .goldenTriangleBalance: "The geometry fits the golden triangle",
            .moveTowardGoldenPoint: "Move the subject toward a golden point",
            .refineFocus: "Refine focus on the main detail",
            .stabilizeCamera: "Stabilize the camera before capture",
            .protectHighlights: "Protect point highlights without lifting shadows too far",
            .sceneGeneral: "General", .scenePortrait: "Portrait",
            .sceneArchitecture: "Architecture", .sceneAutomotive: "Automotive",
            .sceneMacro: "Macro", .sceneStreet: "Street",
            .sceneLandscape: "Landscape", .sceneNight: "Night",
            .goldenSpiral: "Golden spiral", .goldenTriangle: "Golden triangle",
            .orientation: "Orientation", .landscape: "Landscape",
            .upsideDown: "Upside-down portrait",
            .orientationDetail: "Standard portrait always remains available. Landscape and upside-down portrait can be disabled independently.",
            .hud: "HUD", .customizeHUD: "Customize HUD",
            .hudDetail: "Move elements freely inside the safe area. Portrait and landscape keep independent positions.",
            .hudElements: "Elements", .resetHUD: "Reset HUD", .required: "Required",
            .focusPeaking: "Focus Peaking",
            .focusPeakingQuick: "Focus Peaking quick access",
            .lenses: "Lenses", .metrics: "Metrics", .photoFormat: "Format",
            .shutterButton: "Shutter", .gridButton: "Guide button",
            .proControls: "Pro controls"
        ]

        return (language == .spanish ? es : en)[self] ?? String(describing: self)
    }
}
