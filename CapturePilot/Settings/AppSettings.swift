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

    enum PeakingColor: String, CaseIterable, Identifiable {
        case red, green, blue, yellow, cyan, white
        var id: String { rawValue }
    }

    enum ShareJPEGResolution: Int, CaseIterable, Identifiable {
        case mp12 = 12
        case mp24 = 24
        case mp48 = 48

        var id: Int { rawValue }
        var label: String { "\(rawValue) MP" }
    }

    enum FrameGuide: String, CaseIterable, Identifiable {
        case none, square, fourThree, threeTwo, sixteenNine, cinema239
        var id: String { rawValue }

        var aspectRatio: Double? {
            switch self {
            case .none: nil
            case .square: 1.0
            case .fourThree: 4.0 / 3.0
            case .threeTwo: 3.0 / 2.0
            case .sixteenNine: 16.0 / 9.0
            case .cinema239: 2.39
            }
        }
    }

    private enum Key {
        static let language = "settings.language"
        static let grid = "settings.grid"
        static let coachIntensity = "settings.coachIntensity"
        static let sceneCoach = "settings.sceneCoach"
        static let zebraLevel = "settings.monitoring.zebraLevel"
        static let zebraLowLevel = "settings.monitoring.zebraLowLevel"
        static let dualZebra = "settings.monitoring.dualZebra"
        static let peakingThreshold = "settings.monitoring.peakingThreshold"
        static let peakingColor = "settings.monitoring.peakingColor"
        static let frameGuide = "settings.frameGuide"
        static let rawShareEnabled = "settings.rawShare.enabled"
        static let shareJPEGResolution = "settings.rawShare.jpegResolution"
        static let lutEnabled = "settings.rawShare.lutEnabled"
        static let lutIntensity = "settings.rawShare.lutIntensity"
        static let lutDisplayName = "settings.rawShare.lutDisplayName"
        static let lutCoachRecommendations = "settings.rawShare.lutCoachRecommendations"
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

    @Published var zebraLevel: Double {
        didSet { UserDefaults.standard.set(zebraLevel, forKey: Key.zebraLevel) }
    }

    @Published var zebraLowLevel: Double {
        didSet { UserDefaults.standard.set(zebraLowLevel, forKey: Key.zebraLowLevel) }
    }

    @Published var dualZebra: Bool {
        didSet { UserDefaults.standard.set(dualZebra, forKey: Key.dualZebra) }
    }

    @Published var peakingThreshold: Double {
        didSet { UserDefaults.standard.set(peakingThreshold, forKey: Key.peakingThreshold) }
    }

    @Published var peakingColor: PeakingColor {
        didSet { UserDefaults.standard.set(peakingColor.rawValue, forKey: Key.peakingColor) }
    }

    @Published var frameGuide: FrameGuide {
        didSet { UserDefaults.standard.set(frameGuide.rawValue, forKey: Key.frameGuide) }
    }

    @Published var rawShareEnabled: Bool {
        didSet { UserDefaults.standard.set(rawShareEnabled, forKey: Key.rawShareEnabled) }
    }

    @Published var shareJPEGResolution: ShareJPEGResolution {
        didSet {
            UserDefaults.standard.set(
                shareJPEGResolution.rawValue,
                forKey: Key.shareJPEGResolution
            )
        }
    }

    @Published var lutEnabled: Bool {
        didSet { UserDefaults.standard.set(lutEnabled, forKey: Key.lutEnabled) }
    }

    @Published var lutIntensity: Double {
        didSet { UserDefaults.standard.set(lutIntensity, forKey: Key.lutIntensity) }
    }

    @Published private(set) var lutDisplayName: String? {
        didSet { UserDefaults.standard.set(lutDisplayName, forKey: Key.lutDisplayName) }
    }

    @Published var lutCoachRecommendations: Bool {
        didSet {
            UserDefaults.standard.set(
                lutCoachRecommendations,
                forKey: Key.lutCoachRecommendations
            )
        }
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
        let savedZebra = defaults.object(forKey: Key.zebraLevel) != nil
            ? defaults.double(forKey: Key.zebraLevel)
            : 95
        zebraLevel = min(max(savedZebra, 75), 100)

        let savedLowZebra = defaults.object(forKey: Key.zebraLowLevel) != nil
            ? defaults.double(forKey: Key.zebraLowLevel)
            : 70
        zebraLowLevel = min(max(savedLowZebra, 50), 95)
        dualZebra = Self.boolValue(defaults, key: Key.dualZebra, defaultValue: true)

        let savedPeakingThreshold = defaults.object(forKey: Key.peakingThreshold) != nil
            ? defaults.double(forKey: Key.peakingThreshold)
            : 54
        peakingThreshold = min(max(savedPeakingThreshold, 20), 140)
        peakingColor = PeakingColor(
            rawValue: defaults.string(forKey: Key.peakingColor) ?? ""
        ) ?? .red

        frameGuide = FrameGuide(
            rawValue: defaults.string(forKey: Key.frameGuide) ?? ""
        ) ?? .none

        rawShareEnabled = Self.boolValue(
            defaults,
            key: Key.rawShareEnabled,
            defaultValue: false
        )

        let savedShareMP = defaults.integer(forKey: Key.shareJPEGResolution)
        shareJPEGResolution = ShareJPEGResolution(rawValue: savedShareMP) ?? .mp12

        lutEnabled = Self.boolValue(
            defaults,
            key: Key.lutEnabled,
            defaultValue: false
        )

        let savedLUTIntensity = defaults.object(forKey: Key.lutIntensity) != nil
            ? defaults.double(forKey: Key.lutIntensity)
            : 1
        lutIntensity = min(max(savedLUTIntensity, 0), 1)
        lutDisplayName = defaults.string(forKey: Key.lutDisplayName)
        lutCoachRecommendations = Self.boolValue(
            defaults,
            key: Key.lutCoachRecommendations,
            defaultValue: true
        )

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

    func peakingColorName(_ color: PeakingColor) -> String {
        switch color {
        case .red: text(.colorRed)
        case .green: text(.colorGreen)
        case .blue: text(.colorBlue)
        case .yellow: text(.colorYellow)
        case .cyan: text(.colorCyan)
        case .white: text(.colorWhite)
        }
    }

    func rawShareConfiguration(
        libraryLUTURL: URL? = nil
    ) -> RawShareCaptureConfiguration? {
        guard rawShareEnabled else { return nil }

        let lutURL = libraryLUTURL ?? selectedLUTURL

        return RawShareCaptureConfiguration(
            targetMegapixels: shareJPEGResolution.rawValue,
            lutURL: lutEnabled ? lutURL : nil,
            lutIntensity: lutEnabled ? lutIntensity : 0
        )
    }

    var selectedLUTURL: URL? {
        let url = Self.lutStorageURL
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func importLUT(from sourceURL: URL) throws {
        guard sourceURL.pathExtension.lowercased() == "cube" else {
            throw RawShareProcessingError.invalidLUT
        }

        let scoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if scoped { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: sourceURL)
        let directory = Self.lutStorageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let temporaryURL = directory.appendingPathComponent("validation.cube")
        try data.write(to: temporaryURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        _ = try CubeLUT(url: temporaryURL)
        try data.write(to: Self.lutStorageURL, options: .atomic)
        lutDisplayName = sourceURL.deletingPathExtension().lastPathComponent
        lutEnabled = true
    }

    func removeLUT() {
        try? FileManager.default.removeItem(at: Self.lutStorageURL)
        lutDisplayName = nil
        lutEnabled = false
    }

    func frameGuideName(_ guide: FrameGuide) -> String {
        switch guide {
        case .none: text(.off)
        case .square: text(.frameSquare)
        case .fourThree: text(.frameFourThree)
        case .threeTwo: text(.frameThreeTwo)
        case .sixteenNine: text(.frameSixteenNine)
        case .cinema239: text(.frameCinema239)
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

    private static var lutStorageURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent("CapturePilot", isDirectory: true)
            .appendingPathComponent("LUTs", isDirectory: true)
            .appendingPathComponent("Selected.cube")
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
    case monitoring, zebra, zebraLevel, zebraLowLevel, zebraHighLevel, dualZebra, zebraDetail
    case histogram, histogramRGB, histogramDetail
    case falseColor, falseColorDetail, waveform, rgbParade, vectorscope, scopesDetail
    case peakingThreshold, peakingColor, peakingDetail
    case afaeLock, afaeLocked, afaeUnlocked
    case clippingWarnings, shadowsClipped, highlightsClipped
    case frameGuide, frameGuideDetail, frameSquare, frameFourThree, frameThreeTwo
    case frameSixteenNine, frameCinema239
    case colorRed, colorGreen, colorBlue, colorYellow, colorCyan, colorWhite
    case rawShare, rawShareDetail, rawShareUnavailable, shareJPEGResolution
    case lut, importLUT, removeLUT, lutIntensity, noLUT, shareJPEG, shareReady
    case lutLibrary, chooseLUTFolder, changeLUTFolder, removeLUTFolder, rescanLUTs
    case lutFolderDetail, activeLUT, lutCount, invalidLUTCount, externalLUTFolder
    case lutCoachRecommendations, recommendedLUT, applyLUT, lutActive
    case lutReasonPortrait, lutReasonHighlights, lutReasonShadows, lutReasonNight
    case lutReasonLandscape, lutReasonArchitecture, lutReasonAutomotive
    case lutReasonStreet, lutReasonMacro, lutReasonGeneral

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
            .proControls: "Controles Pro",
            .monitoring: "Monitoreo", .zebra: "Cebras",
            .zebraLevel: "Nivel de cebra",
            .zebraDetail: "Marca con líneas diagonales las zonas que alcanzan o superan el nivel seleccionado.",
            .histogram: "Histograma", .histogramRGB: "Histograma RGB",
            .histogramDetail: "Histograma RGB del preview YCbCr. Sirve para exposición y clipping; no representa el histograma del archivo RAW final.",
            .zebraLowLevel: "Cebra baja", .zebraHighLevel: "Cebra alta",
            .dualZebra: "Cebra dual",
            .falseColor: "False Color",
            .falseColorDetail: "Mapa de exposición por color derivado de la luminancia del preview; no es una medición IRE calibrada del sensor.",
            .waveform: "Waveform Luma", .rgbParade: "RGB Parade",
            .vectorscope: "Vectorscope",
            .scopesDetail: "Scopes derivados del preview para evaluar exposición, distribución tonal y balance de color antes de capturar.",
            .peakingThreshold: "Umbral de Peaking", .peakingColor: "Color de Peaking",
            .peakingDetail: "Un umbral menor resalta más bordes; uno mayor exige más microcontraste.",
            .afaeLock: "Bloqueo AF/AE", .afaeLocked: "AF/AE bloqueado",
            .afaeUnlocked: "AF/AE automático",
            .clippingWarnings: "Avisos de clipping",
            .shadowsClipped: "Sombras recortadas", .highlightsClipped: "Luces recortadas",
            .frameGuide: "Guía de formato",
            .frameGuideDetail: "Previsualiza proporciones de recorte para fotografía sin cambiar la resolución del archivo capturado.",
            .frameSquare: "1:1 Cuadrado", .frameFourThree: "4:3",
            .frameThreeTwo: "3:2", .frameSixteenNine: "16:9",
            .frameCinema239: "2.39:1",
            .colorRed: "Rojo", .colorGreen: "Verde", .colorBlue: "Azul",
            .colorYellow: "Amarillo", .colorCyan: "Cian", .colorWhite: "Blanco",
            .rawShare: "RAW + JPEG para compartir",
            .rawShareDetail: "Captura RAW/ProRAW a máxima resolución y crea un JPEG del mismo disparo con LUT opcional. El JPEG puede salir a 12, 24 o 48 MP sin hacer upscale.",
            .rawShareUnavailable: "RAW + JPEG requiere una lente/configuración con RAW y resolución máxima suficiente.",
            .shareJPEGResolution: "Resolución del JPEG",
            .lut: "LUT", .importLUT: "Importar LUT .cube",
            .removeLUT: "Eliminar LUT", .lutIntensity: "Intensidad del LUT",
            .noLUT: "Sin LUT", .shareJPEG: "JPEG para compartir",
            .shareReady: "JPEG listo para compartir",
            .lutLibrary: "Biblioteca de LUTs",
            .chooseLUTFolder: "Conectar carpeta adicional",
            .changeLUTFolder: "Cambiar carpeta adicional",
            .removeLUTFolder: "Desconectar carpeta",
            .rescanLUTs: "Actualizar biblioteca",
            .lutFolderDetail: "Copia LUTs en Archivos → En mi iPhone → CapturePilot → LUTs. También puedes conectar una carpeta adicional de iCloud Drive, almacenamiento externo u otro proveedor. CapturePilot reescanea al volver a la app.",
            .externalLUTFolder: "Carpeta adicional",
            .activeLUT: "LUT activo", .lutCount: "LUTs detectados",
            .invalidLUTCount: "LUTs omitidos",
            .lutCoachRecommendations: "Sugerencias de LUT del Coach",
            .recommendedLUT: "LUT sugerido", .applyLUT: "Usar LUT",
            .lutActive: "LUT activo",
            .lutReasonPortrait: "Look cálido/suave compatible con retrato.",
            .lutReasonHighlights: "Favorece una curva de luces más contenida; no recupera clipping.",
            .lutReasonShadows: "Favorece sombras más abiertas; no sustituye una exposición correcta.",
            .lutReasonNight: "Favorece sombras legibles y luces controladas.",
            .lutReasonLandscape: "Favorece color y contraste para paisaje.",
            .lutReasonArchitecture: "Favorece contraste con color relativamente neutro.",
            .lutReasonAutomotive: "Favorece contraste y separación de color.",
            .lutReasonStreet: "Favorece estructura y contraste para calle.",
            .lutReasonMacro: "Favorece separación de color y microcontraste.",
            .lutReasonGeneral: "Look equilibrado para la escena actual."
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
            .proControls: "Pro controls",
            .monitoring: "Monitoring", .zebra: "Zebras",
            .zebraLevel: "Zebra level",
            .zebraDetail: "Draws diagonal lines over areas that reach or exceed the selected level.",
            .histogram: "Histogram", .histogramRGB: "RGB histogram",
            .histogramDetail: "RGB histogram derived from the YCbCr preview stream. It is useful for exposure and clipping, but is not the final RAW-file histogram.",
            .zebraLowLevel: "Low zebra", .zebraHighLevel: "High zebra",
            .dualZebra: "Dual zebra",
            .falseColor: "False Color",
            .falseColorDetail: "Color exposure map derived from preview luminance; it is not a sensor-calibrated IRE measurement.",
            .waveform: "Luma Waveform", .rgbParade: "RGB Parade",
            .vectorscope: "Vectorscope",
            .scopesDetail: "Preview-derived scopes for evaluating exposure, tonal distribution, and color balance before capture.",
            .peakingThreshold: "Peaking threshold", .peakingColor: "Peaking color",
            .peakingDetail: "A lower threshold highlights more edges; a higher threshold requires stronger micro-contrast.",
            .afaeLock: "AF/AE Lock", .afaeLocked: "AF/AE locked",
            .afaeUnlocked: "AF/AE automatic",
            .clippingWarnings: "Clipping warnings",
            .shadowsClipped: "Shadows clipped", .highlightsClipped: "Highlights clipped",
            .frameGuide: "Frame guide",
            .frameGuideDetail: "Preview photographic crop ratios without changing the captured file resolution.",
            .frameSquare: "1:1 Square", .frameFourThree: "4:3",
            .frameThreeTwo: "3:2", .frameSixteenNine: "16:9",
            .frameCinema239: "2.39:1",
            .colorRed: "Red", .colorGreen: "Green", .colorBlue: "Blue",
            .colorYellow: "Yellow", .colorCyan: "Cyan", .colorWhite: "White",
            .rawShare: "RAW + Share JPEG",
            .rawShareDetail: "Captures RAW/ProRAW at maximum resolution and creates a JPEG from the same shot with an optional LUT. The JPEG can target 12, 24, or 48 MP without upscaling.",
            .rawShareUnavailable: "RAW + Share JPEG requires a lens/configuration with RAW support and sufficient maximum resolution.",
            .shareJPEGResolution: "Share JPEG resolution",
            .lut: "LUT", .importLUT: "Import .cube LUT",
            .removeLUT: "Remove LUT", .lutIntensity: "LUT intensity",
            .noLUT: "No LUT", .shareJPEG: "Share JPEG",
            .shareReady: "JPEG ready to share",
            .lutLibrary: "LUT Library",
            .chooseLUTFolder: "Connect additional folder",
            .changeLUTFolder: "Change additional folder",
            .removeLUTFolder: "Disconnect folder",
            .rescanLUTs: "Refresh library",
            .lutFolderDetail: "Drop LUTs into Files → On My iPhone → CapturePilot → LUTs. You can also connect an additional iCloud Drive, external-storage, or File Provider folder. CapturePilot rescans when you return to the app.",
            .externalLUTFolder: "Additional folder",
            .activeLUT: "Active LUT", .lutCount: "Detected LUTs",
            .invalidLUTCount: "Skipped LUTs",
            .lutCoachRecommendations: "Coach LUT suggestions",
            .recommendedLUT: "Suggested LUT", .applyLUT: "Use LUT",
            .lutActive: "LUT active",
            .lutReasonPortrait: "Warm/soft profile suited to portrait.",
            .lutReasonHighlights: "Favors a gentler highlight curve; it cannot recover clipping.",
            .lutReasonShadows: "Favors more open shadows; it does not replace correct exposure.",
            .lutReasonNight: "Favors readable shadows and controlled highlights.",
            .lutReasonLandscape: "Favors color and contrast for landscape.",
            .lutReasonArchitecture: "Favors contrast with relatively neutral color.",
            .lutReasonAutomotive: "Favors contrast and color separation.",
            .lutReasonStreet: "Favors structure and contrast for street.",
            .lutReasonMacro: "Favors color separation and microcontrast.",
            .lutReasonGeneral: "Balanced look for the current scene."
        ]

        return (language == .spanish ? es : en)[self] ?? String(describing: self)
    }
}
