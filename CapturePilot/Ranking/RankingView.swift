import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct RankingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore
    @EnvironmentObject private var social: SocialCompetitionService
    @Environment(\.dismiss) private var dismiss

    @State private var topCount: Int? = 10
    @State private var category: PhotoCategory?
    @State private var searchText = ""
    @State private var activeSheet: RankingSheet?
    @State private var importTask: Task<Void, Never>?
    @State private var importCompleted = 0
    @State private var importTotal = 0
    @State private var importImported = 0
    @State private var importDuplicates = 0
    @State private var importFailed = 0
    @State private var importWasCancelled = false
    @State private var isImportingPhotos = false
    @State private var importSummary: String?
    @State private var showingImportSummary = false

    private var ranked: [PhotoRankingEntry] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let filtered = rankingStore.entries.filter { entry in
            let categoryMatches = category == nil || entry.category == category
            guard categoryMatches else { return false }

            guard !query.isEmpty else { return true }

            let searchable = (
                [entry.category.rawValue] + entry.tags
            )
            .joined(separator: " ")
            .lowercased()

            return searchable.contains(query)
        }

        let sorted = filtered.sorted { lhs, rhs in
            if lhs.coachScore == rhs.coachScore {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.coachScore > rhs.coachScore
        }

        guard let topCount else { return sorted }
        return Array(sorted.prefix(topCount))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                controls

                if rankingStore.entries.isEmpty {
                    ContentUnavailableView(
                        localized("No ranked photos", "Sin fotos clasificadas"),
                        systemImage: "trophy",
                        description: Text(
                            localized(
                                "Photos captured in CapturePilot are analyzed automatically. You can also import images without granting full Photo Library access.",
                                "Las fotos tomadas con CapturePilot se analizan automáticamente. También puedes importar imágenes sin conceder acceso completo a Fotos."
                            )
                        )
                    )
                    .padding()
                } else {
                    List {
                        ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                            NavigationLink {
                                RankingDetailView(
                                    entry: entry,
                                    rank: index + 1
                                )
                            } label: {
                                RankingRow(
                                    entry: entry,
                                    rank: index + 1,
                                    thumbnailURL: rankingStore.thumbnailURL(for: entry)
                                )
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                rankingStore.delete(ranked[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(localized("Rankings", "Ranking"))
            .searchable(
                text: $searchText,
                prompt: localized("Search category or tags", "Buscar categoría o etiquetas")
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localized("Done", "Listo")) { dismiss() }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .photoImport
                    } label: {
                        Image(systemName: "photo.badge.plus")
                    }
                    .accessibilityLabel(localized("Import photos", "Importar fotos"))

                    if social.isAvailable {
                        Button {
                            activeSheet = .social
                        } label: {
                            Image(systemName: "person.2.fill")
                        }
                        .accessibilityLabel(localized("Friends", "Amigos"))
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .social:
                    SocialCompetitionView()
                        .environmentObject(settings)
                        .environmentObject(rankingStore)
                        .environmentObject(social)
                case .photoImport:
                    PhotoImportView(
                        onImportAssets: { assets in
                            startImport(assets)
                        },
                        onImportFiles: { urls in
                            startImportFiles(urls)
                        }
                    )
                    .environmentObject(settings)
                }
            }
            .overlay(alignment: .bottom) {
                if isImportingPhotos {
                    HStack(spacing: 10) {
                        ProgressView()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localized("Importing photos", "Importando fotos"))
                                .font(.caption.weight(.semibold))

                            Text("\(importCompleted) / \(importTotal) · \(importDuplicates) \(localized("duplicates skipped", "duplicadas omitidas"))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            importTask?.cancel()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel(localized("Cancel import", "Cancelar importación"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                } else if rankingStore.isAnalyzing {
                    HStack {
                        ProgressView()
                        Text(localized("Coach is analyzing…", "El Coach está analizando…"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                }
            }
        }
        .alert(
            localized("Import summary", "Resumen de importación"),
            isPresented: $showingImportSummary
        ) {
            Button("OK", role: .cancel) { importSummary = nil }
        } message: {
            Text(importSummary ?? "")
        }
        .preferredColorScheme(.dark)
    }

    private func startImport(_ assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        beginImport(total: assets.count)

        importTask = Task { @MainActor in
            for asset in assets {
                guard !Task.isCancelled else {
                    importWasCancelled = true
                    break
                }

                do {
                    let data = try await loadAnalysisData(for: asset)
                    guard !Task.isCancelled else {
                        importWasCancelled = true
                        break
                    }

                    let result = await rankingStore.ingest(
                        data: data,
                        source: .importPhoto,
                        assetIdentifier: asset.localIdentifier
                    )
                    recordImportResult(result)
                } catch is CancellationError {
                    importWasCancelled = true
                    break
                } catch {
                    importFailed += 1
                }

                importCompleted += 1
            }

            finishImport()
        }
    }

    private func startImportFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        beginImport(total: urls.count)

        importTask = Task { @MainActor in
            for url in urls {
                guard !Task.isCancelled else {
                    importWasCancelled = true
                    break
                }

                let hasSecurityScope = url.startAccessingSecurityScopedResource()
                defer {
                    if hasSecurityScope {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    let data = try await Task.detached(priority: .utility) {
                        try Data(contentsOf: url, options: .mappedIfSafe)
                    }.value

                    guard !Task.isCancelled else {
                        importWasCancelled = true
                        break
                    }

                    let result = await rankingStore.ingest(
                        data: data,
                        source: .importPhoto
                    )
                    recordImportResult(result)
                } catch is CancellationError {
                    importWasCancelled = true
                    break
                } catch {
                    importFailed += 1
                }

                importCompleted += 1
            }

            finishImport()
        }
    }

    private func beginImport(total: Int) {
        importCompleted = 0
        importTotal = total
        importImported = 0
        importDuplicates = 0
        importFailed = 0
        importWasCancelled = false
        isImportingPhotos = true
    }

    private func recordImportResult(_ result: PhotoIngestResult) {
        switch result {
        case .imported:
            importImported += 1
        case .duplicate:
            importDuplicates += 1
        case .failed:
            importFailed += 1
        }
    }

    private func finishImport() {
        if Task.isCancelled {
            importWasCancelled = true
        }

        isImportingPhotos = false
        importTask = nil

        let cancelled = importWasCancelled
            ? localized(" · cancelled", " · cancelada")
            : ""
        importSummary = localized(
            "Imported: \(importImported) · duplicates skipped: \(importDuplicates) · failed: \(importFailed)\(cancelled)",
            "Importadas: \(importImported) · duplicadas omitidas: \(importDuplicates) · errores: \(importFailed)\(cancelled)"
        )
        showingImportSummary = true
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker(
                localized("Show", "Mostrar"),
                selection: $topCount
            ) {
                Text("Top 5").tag(Optional(5))
                Text("Top 10").tag(Optional(10))
                Text("Top 25").tag(Optional(25))
                Text("Top 50").tag(Optional(50))
                Text(localized("All", "Todas")).tag(Optional<Int>.none)
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(localized("Category", "Categoría"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button(localized("All", "Todas")) { category = nil }
                    Divider()
                    ForEach(PhotoCategory.allCases) { item in
                        Button(categoryName(item)) { category = item }
                    }
                } label: {
                    HStack {
                        Text(category.map(categoryName) ?? localized("All", "Todas"))
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func categoryName(_ value: PhotoCategory) -> String {
        switch value {
        case .general: localized("General", "General")
        case .portrait: localized("Portrait", "Retrato")
        case .architecture: localized("Architecture", "Arquitectura")
        case .automotive: localized("Automotive", "Automotriz")
        case .macro: localized("Macro", "Macro")
        case .street: localized("Street", "Calle")
        case .landscape: localized("Landscape", "Paisaje")
        case .night: localized("Night", "Noche")
        }
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        switch settings.language {
        case .english: english
        case .spanish: spanish
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
                ? spanish
                : english
        }
    }
}

private struct RankingRow: View {
    @EnvironmentObject private var settings: AppSettings

    let entry: PhotoRankingEntry
    let rank: Int
    let thumbnailURL: URL

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if let image = UIImage(contentsOfFile: thumbnailURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 86, height: 68)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                } else {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 86, height: 68)
                }

                Text("#\(rank)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.72), in: Capsule())
                    .padding(5)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName(entry.category))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f", entry.coachScore))
                    .font(.title3.monospacedDigit().bold())
                Text(entry.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func categoryName(_ category: PhotoCategory) -> String {
        switch category {
        case .general: localized("General", "General")
        case .portrait: localized("Portrait", "Retrato")
        case .architecture: localized("Architecture", "Arquitectura")
        case .automotive: localized("Automotive", "Automotriz")
        case .macro: localized("Macro", "Macro")
        case .street: localized("Street", "Calle")
        case .landscape: localized("Landscape", "Paisaje")
        case .night: localized("Night", "Noche")
        }
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        let useSpanish = settings.language == .spanish
            || (
                settings.language == .system
                && Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
            )
        return useSpanish ? spanish : english
    }
}

private struct RankingDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore

    let entry: PhotoRankingEntry
    let rank: Int

    @State private var selectedCategory: PhotoCategory
    @State private var categoryWasManuallyChanged: Bool

    init(entry: PhotoRankingEntry, rank: Int) {
        self.entry = entry
        self.rank = rank
        _selectedCategory = State(initialValue: entry.category)
        _categoryWasManuallyChanged = State(initialValue: entry.hasManualCategory)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let image = UIImage(
                    contentsOfFile: rankingStore.thumbnailURL(for: entry).path
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack {
                    Text("#\(rank)")
                        .font(.largeTitle.bold())
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", entry.coachScore))
                            .font(.largeTitle.monospacedDigit().bold())
                        Text(localized("Coach Score", "Coach Score"))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(localized("Photo category", "Categoría de la foto"))
                        .font(.headline)

                    Menu {
                        ForEach(PhotoCategory.allCases) { option in
                            Button {
                                selectedCategory = option
                                categoryWasManuallyChanged = true
                                rankingStore.updateCategory(for: entry.id, to: option)
                            } label: {
                                if selectedCategory == option {
                                    Label(categoryName(option), systemImage: "checkmark")
                                } else {
                                    Text(categoryName(option))
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Label(categoryName(selectedCategory), systemImage: "tag")
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Text(
                        categoryWasManuallyChanged
                            ? localized(
                                "Manual category. Your choice is saved and takes precedence over automatic categorization.",
                                "Categoría manual. Tu elección se guarda y prevalece sobre la clasificación automática."
                            )
                            : localized(
                                "Suggested automatically. Change it here if the photo was categorized incorrectly.",
                                "Sugerida automáticamente. Cámbiala aquí si la foto se clasificó incorrectamente."
                            )
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

                scoreCard(
                    localized("Exposure", "Exposición"),
                    entry.score.exposure
                )
                scoreCard(
                    localized("Composition", "Composición"),
                    entry.score.composition
                )
                scoreCard(
                    localized("Detail", "Detalle"),
                    entry.score.detail
                )

                if let aesthetics = entry.score.aesthetics {
                    scoreCard(
                        localized("Vision aesthetics", "Estética de Vision"),
                        aesthetics
                    )
                }

                if let portrait = entry.score.portraitQuality {
                    scoreCard(
                        localized("Portrait capture", "Captura de retrato"),
                        portrait
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(localized("Coach recommendations", "Recomendaciones del Coach"))
                        .font(.headline)

                    ForEach(entry.recommendations, id: \.self) { recommendation in
                        Label(
                            recommendationText(recommendation),
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

                if !entry.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localized("Detected tags", "Etiquetas detectadas"))
                            .font(.headline)
                        Text(entry.tags.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(
                    localized(
                        "Coach Score is a relative ranking aid. It combines explainable CapturePilot metrics and, on supported OS versions, Apple's Vision aesthetics signal. It is not an objective measure of artistic value.",
                        "Coach Score es una ayuda de ranking relativa. Combina métricas explicables de CapturePilot y, en sistemas compatibles, la señal estética de Vision de Apple. No es una medida objetiva del valor artístico."
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(localized("Photo review", "Revisión de foto"))
    }

    private func categoryName(_ category: PhotoCategory) -> String {
        switch category {
        case .general: localized("General", "General")
        case .portrait: localized("Portrait", "Retrato")
        case .architecture: localized("Architecture", "Arquitectura")
        case .automotive: localized("Automotive", "Automotriz")
        case .macro: localized("Macro", "Macro")
        case .street: localized("Street", "Calle")
        case .landscape: localized("Landscape", "Paisaje")
        case .night: localized("Night", "Noche")
        }
    }

    private func scoreCard(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.0f", value))
                    .monospacedDigit()
            }
            ProgressView(value: value, total: 100)
        }
    }

    private func recommendationText(_ item: RankingRecommendation) -> String {
        let es = isSpanish
        switch item {
        case .levelHorizon:
            return es ? "Nivela el horizonte; en esta categoría la inclinación resta fuerza al encuadre." : "Level the horizon; in this category the tilt weakens the frame."
        case .lowerHighlights:
            return es ? "Reduce un poco las altas luces; deja más margen antes del clipping." : "Reduce the highlights slightly and leave more headroom before clipping."
        case .raiseExposure:
            return es ? "Prueba una exposición algo mayor sin perder las luces." : "Try a slightly brighter exposure without sacrificing highlights."
        case .stabilizeAndRefocus:
            return es ? "Estabiliza y confirma el foco sobre el detalle principal." : "Stabilize and confirm focus on the main detail."
        case .simplifyBackground:
            return es ? "Busca más separación entre sujeto y fondo." : "Look for stronger separation between subject and background."
        case .moveTowardStrongPoint:
            return es ? "Prueba mover el encuadre hacia un punto compositivo fuerte." : "Try moving the framing toward a stronger compositional point."
        case .reduceHeadroom:
            return es ? "Reduce aire sobre el sujeto o ajusta ligeramente el punto de vista." : "Reduce headroom or adjust the viewpoint slightly."
        case .improvePortraitQuality:
            return es ? "Busca luz más limpia, confirma foco en los ojos y prueba una pose más estable." : "Look for cleaner light, confirm focus on the eyes, and try a steadier pose."
        case .strengthenSymmetry:
            return es ? "Refuerza el eje de simetría o rompe la simetría de forma intencional." : "Strengthen the symmetry axis or break symmetry deliberately."
        case .useLeadingLines:
            return es ? "Busca una posición donde las líneas conduzcan con más claridad al sujeto." : "Find a position where lines lead more clearly toward the subject."
        case .lowerCameraAngle:
            return es ? "Prueba un ángulo más bajo para dar presencia al vehículo." : "Try a lower camera angle to give the vehicle more presence."
        case .addForegroundLayer:
            return es ? "Añade un elemento de primer plano para crear profundidad." : "Add a foreground layer to create more depth."
        case .waitForSeparation:
            return es ? "Espera un instante con mejor separación o gesto entre los elementos." : "Wait for a moment with stronger separation or gesture between elements."
        case .useNegativeSpace:
            return es ? "Prueba más espacio negativo alrededor del detalle principal." : "Try more negative space around the main detail."
        case .protectNightHighlights:
            return es ? "Protege las luces puntuales y busca estabilidad antes de disparar." : "Protect point highlights and prioritize stability before shooting."
        case .tryDifferentViewpoint:
            return es ? "Prueba una altura o distancia distinta para hacer el encuadre menos predecible." : "Try a different height or distance to make the frame less predictable."
        }
    }

    private var isSpanish: Bool {
        switch settings.language {
        case .spanish: true
        case .english: false
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
        }
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        isSpanish ? spanish : english
    }
}


private enum RankingSheet: String, Identifiable {
    case social
    case photoImport

    var id: String { rawValue }
}

private enum PhotoLibraryThumbnailManager {
    static let shared = PHCachingImageManager()
}

private struct PhotoImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var settings: AppSettings

    let onImportAssets: ([PHAsset]) -> Void
    let onImportFiles: ([URL]) -> Void

    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var assets: [PHAsset] = []
    @State private var selectedIdentifiers = Set<String>()
    @State private var photoFilter: PhotoFilter = .all
    @State private var isLoadingAssets = false
    @State private var showingFileImporter = false
    @State private var fileImportError: String?
    @State private var showingFileImportError = false

    private let columns = [
        GridItem(.adaptive(minimum: 94, maximum: 144), spacing: 4)
    ]

    private var canBrowsePhotos: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    private enum PhotoFilter: String, CaseIterable, Identifiable {
        case all, favorites, screenshots
        var id: String { rawValue }
    }

    private var displayedAssets: [PHAsset] {
        switch photoFilter {
        case .all:
            assets
        case .favorites:
            assets.filter { $0.isFavorite }
        case .screenshots:
            assets.filter { $0.mediaSubtypes.contains(.photoScreenshot) }
        }
    }

    private var visibleSelectedCount: Int {
        displayedAssets.reduce(into: 0) { count, asset in
            if selectedIdentifiers.contains(asset.localIdentifier) { count += 1 }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                accessHeader

                if canBrowsePhotos {
                    selectionToolbar

                    if isLoadingAssets {
                        ProgressView(localized("Loading photo library…", "Cargando fototeca…"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !displayedAssets.isEmpty {
                        photoGrid(displayedAssets)
                    } else {
                        ContentUnavailableView(
                            localized("No photos found", "No se encontraron fotos"),
                            systemImage: "photo.on.rectangle.angled",
                            description: Text(
                                localized(
                                    "No images are available in the current photo-library access scope.",
                                    "No hay imágenes disponibles dentro del acceso actual a la fototeca."
                                )
                            )
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    noPhotoAccessContent
                }

                importActions
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(localized("Import photos", "Importar fotos"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localized("Done", "Listo")) { dismiss() }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .rawImage],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                guard !urls.isEmpty else { return }
                dismiss()
                onImportFiles(urls)
            case .failure(let error):
                fileImportError = error.localizedDescription
                showingFileImportError = true
            }
        }
        .alert(
            localized("Could not open files", "No se pudieron abrir los archivos"),
            isPresented: $showingFileImportError
        ) {
            Button(localized("OK", "Aceptar"), role: .cancel) {
                fileImportError = nil
            }
        } message: {
            Text(fileImportError ?? "")
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refreshAuthorization()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshAuthorization()
            }
        }
    }

    private var accessHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(
                    accessTitle,
                    systemImage: canBrowsePhotos ? "checkmark.shield.fill" : "photo.badge.exclamationmark"
                )
                .font(.subheadline.weight(.semibold))

                Spacer()

                if authorizationStatus != .notDetermined {
                    Button(localized("Manage access", "Administrar acceso")) {
                        openSettings()
                    }
                    .font(.caption.weight(.medium))
                }
            }

            Text(accessDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            if authorizationStatus == .limited {
                Text(
                    localized(
                        "Only approved photos appear below. Add more directly with iOS's limited-library picker or review access in Settings.",
                        "Abajo solo aparecen las fotos autorizadas. Añade más directamente con el selector limitado de iOS o revisa el acceso en Ajustes."
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                Button {
                    presentLimitedLibraryPicker()
                } label: {
                    Label(
                        localized("Add or remove allowed photos", "Añadir o quitar fotos permitidas"),
                        systemImage: "photo.badge.plus"
                    )
                }
                .font(.caption.weight(.medium))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var selectionToolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(localized(
                    "\(selectedIdentifiers.count) selected",
                    "\(selectedIdentifiers.count) seleccionadas"
                ))
                .font(.subheadline.weight(.semibold).monospacedDigit())

                Spacer()

                Button(
                    visibleSelectedCount == displayedAssets.count
                        ? localized("Clear visible", "Limpiar visibles")
                        : localized("Select all visible", "Seleccionar visibles")
                ) {
                    toggleSelectAll()
                }
                .font(.caption.weight(.medium))
                .disabled(displayedAssets.isEmpty)
            }

            Picker(localized("Show", "Mostrar"), selection: $photoFilter) {
                Text(localized("All", "Todas")).tag(PhotoFilter.all)
                Text(localized("Favorites", "Favoritas")).tag(PhotoFilter.favorites)
                Text(localized("Screenshots", "Capturas de pantalla")).tag(PhotoFilter.screenshots)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.white.opacity(0.04))
    }

    private func photoGrid(_ visibleAssets: [PHAsset]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(visibleAssets, id: \.localIdentifier) { asset in
                    let isSelected = selectedIdentifiers.contains(asset.localIdentifier)

                    Button {
                        toggleSelection(for: asset)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            PhotoLibraryThumbnail(
                                asset: asset,
                                targetSize: CGSize(
                                    width: 144 * displayScale,
                                    height: 144 * displayScale
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, isSelected ? Color.accentColor : Color.black.opacity(0.65))
                                .padding(6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        localized("Photo", "Foto")
                        + (isSelected ? localized(", selected", ", seleccionada") : localized(", not selected", ", no seleccionada"))
                    )
                    .id(asset.localIdentifier)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private var noPhotoAccessContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)

            Text(localized("Choose how CapturePilot can access photos", "Elige cómo puede acceder CapturePilot a tus fotos"))
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(
                localized(
                    "iOS will ask whether to allow full access or only selected photos. CapturePilot cannot change that permission without your approval.",
                    "iOS te preguntará si permites acceso completo o solo a las fotos seleccionadas. CapturePilot no puede cambiar ese permiso sin tu autorización."
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            if authorizationStatus == .notDetermined {
                Button {
                    requestPhotoAccess()
                } label: {
                    Label(
                        localized("Browse Photo Library", "Explorar fototeca"),
                        systemImage: "photo.on.rectangle.angled"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    openSettings()
                } label: {
                    Label(
                        localized("Open iOS Settings", "Abrir Ajustes de iOS"),
                        systemImage: "gear"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Text(
                localized(
                    "You can import from Files without granting Photo Library access.",
                    "Puedes importar desde Archivos sin conceder acceso a la fototeca."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var importActions: some View {
        VStack(spacing: 8) {
            Button {
                showingFileImporter = true
            } label: {
                Label(
                    localized("Import from Files", "Importar desde Archivos"),
                    systemImage: "folder"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text(
                localized(
                    "Choose multiple supported images or RAW files from On My iPhone, iCloud Drive, or connected file providers.",
                    "Selecciona varias imágenes o archivos RAW compatibles desde En mi iPhone, iCloud Drive u otros proveedores conectados."
                )
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            if canBrowsePhotos {
                Button {
                    let selected = selectedAssets()
                    guard !selected.isEmpty else { return }
                    dismiss()
                    onImportAssets(selected)
                } label: {
                    Label(
                        localized("Import \(selectedIdentifiers.count) photos", "Importar \(selectedIdentifiers.count) fotos"),
                        systemImage: "square.and.arrow.down"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIdentifiers.isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.black)
    }

    private var accessTitle: String {
        switch authorizationStatus {
        case .authorized:
            localized("Full Photo Library Access", "Acceso completo a Fotos")
        case .limited:
            localized("Limited Photo Library Access", "Acceso limitado a Fotos")
        case .notDetermined:
            localized("Photo Library Access Not Set", "Acceso a Fotos sin configurar")
        case .denied:
            localized("Photo Library Access Denied", "Acceso a Fotos denegado")
        case .restricted:
            localized("Photo Library Access Restricted", "Acceso a Fotos restringido")
        @unknown default:
            localized("Photo Library Access", "Acceso a Fotos")
        }
    }

    private var accessDescription: String {
        switch authorizationStatus {
        case .authorized:
            localized(
                "The custom CapturePilot grid can browse your full photo library.",
                "La cuadrícula propia de CapturePilot puede explorar toda tu fototeca."
            )
        case .limited:
            localized(
                "The custom CapturePilot grid shows only photos approved in iOS.",
                "La cuadrícula propia de CapturePilot muestra solo las fotos autorizadas en iOS."
            )
        case .notDetermined:
            localized(
                "Choose Photo Library to let iOS show the available permission options.",
                "Elige Fototeca para que iOS muestre las opciones de permiso disponibles."
            )
        case .denied, .restricted:
            localized(
                "Photo Library access is off. Open Settings to change it, or import from Files.",
                "El acceso a Fotos está desactivado. Cámbialo en Ajustes o importa desde Archivos."
            )
        @unknown default:
            localized(
                "Review CapturePilot's Photo Library permission in iOS Settings.",
                "Revisa el permiso de Fotos de CapturePilot en Ajustes de iOS."
            )
        }
    }

    private func refreshAuthorization() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let accessChanged = currentStatus != authorizationStatus
        authorizationStatus = currentStatus

        guard currentStatus == .authorized || currentStatus == .limited else {
            assets = []
            selectedIdentifiers.removeAll()
            return
        }

        if accessChanged {
            selectedIdentifiers.removeAll()
        }

        isLoadingAssets = true
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        let fetchedAssets = PHAsset.fetchAssets(with: .image, options: options)
        var all: [PHAsset] = []
        all.reserveCapacity(fetchedAssets.count)
        fetchedAssets.enumerateObjects { asset, _, _ in all.append(asset) }
        assets = all
        selectedIdentifiers.formIntersection(Set(all.map(\.localIdentifier)))
        isLoadingAssets = false
    }

    private func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                authorizationStatus = status
                refreshAuthorization()
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func presentLimitedLibraryPicker() {
        guard authorizationStatus == .limited,
              let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            openSettings()
            return
        }

        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter) { _ in
            DispatchQueue.main.async { refreshAuthorization() }
        }
    }

    private func toggleSelection(for asset: PHAsset) {
        if selectedIdentifiers.contains(asset.localIdentifier) {
            selectedIdentifiers.remove(asset.localIdentifier)
        } else {
            selectedIdentifiers.insert(asset.localIdentifier)
        }
    }

    private func toggleSelectAll() {
        let visibleIDs = Set(displayedAssets.map(\.localIdentifier))
        guard !visibleIDs.isEmpty else { return }

        if visibleIDs.isSubset(of: selectedIdentifiers) {
            selectedIdentifiers.subtract(visibleIDs)
        } else {
            selectedIdentifiers.formUnion(visibleIDs)
        }
    }

    private func selectedAssets() -> [PHAsset] {
        guard !selectedIdentifiers.isEmpty else { return [] }
        return assets.filter { selectedIdentifiers.contains($0.localIdentifier) }
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        switch settings.language {
        case .english: english
        case .spanish: spanish
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
                ? spanish
                : english
        }
    }
}

private struct PhotoLibraryThumbnail: View {
    let asset: PHAsset
    let targetSize: CGSize

    @StateObject private var loader: PhotoLibraryThumbnailLoader

    init(asset: PHAsset, targetSize: CGSize) {
        self.asset = asset
        self.targetSize = targetSize
        _loader = StateObject(
            wrappedValue: PhotoLibraryThumbnailLoader(
                asset: asset,
                targetSize: targetSize
            )
        )
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.failed {
                Image(systemName: "icloud.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.06))
            } else {
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .overlay {
                        ProgressView()
                            .controlSize(.small)
                    }
            }
        }
        .onAppear {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

@MainActor
private final class PhotoLibraryThumbnailLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var failed = false

    private let asset: PHAsset
    private let targetSize: CGSize
    private let manager = PhotoLibraryThumbnailManager.shared
    private var requestID: PHImageRequestID?

    init(asset: PHAsset, targetSize: CGSize) {
        self.asset = asset
        self.targetSize = targetSize
    }

    func load() {
        guard image == nil, requestID == nil else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.version = .current

        requestID = manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            DispatchQueue.main.async {
                guard let self else { return }

                if info?[PHImageCancelledKey] as? Bool == true {
                    self.requestID = nil
                    return
                }

                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool == true
                if let image {
                    self.image = image
                    if !isDegraded {
                        self.requestID = nil
                        self.failed = false
                    }
                } else if !isDegraded {
                    self.failed = true
                    self.requestID = nil
                }
            }
        }
    }

    func cancel() {
        if let requestID {
            manager.cancelImageRequest(requestID)
            self.requestID = nil
        }
        image = nil
        failed = false
    }
}

private enum PhotoAssetImportError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The photo could not be loaded. If it is stored in iCloud, check your connection and try again."
        }
    }
}

private final class PhotoAssetRequestCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var requestID: PHImageRequestID?
    private var cancelled = false

    func setRequestID(_ requestID: PHImageRequestID, manager: PHImageManager) {
        lock.lock()
        self.requestID = requestID
        let shouldCancel = cancelled
        lock.unlock()

        if shouldCancel, requestID != PHInvalidImageRequestID {
            manager.cancelImageRequest(requestID)
        }
    }

    func cancel(manager: PHImageManager) {
        lock.lock()
        cancelled = true
        let requestID = self.requestID
        lock.unlock()

        if let requestID, requestID != PHInvalidImageRequestID {
            manager.cancelImageRequest(requestID)
        }
    }
}

private func loadAnalysisData(for asset: PHAsset) async throws -> Data {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = true
    options.version = .current

    let cancellation = PhotoAssetRequestCancellation()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            let requestID = manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 2048, height: 2048),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if info?[PHImageCancelledKey] as? Bool == true {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                if info?[PHImageResultIsDegradedKey] as? Bool == true {
                    return
                }

                guard let image, let data = image.jpegData(compressionQuality: 0.9) else {
                    continuation.resume(throwing: PhotoAssetImportError.unavailable)
                    return
                }

                continuation.resume(returning: data)
            }
            cancellation.setRequestID(requestID, manager: manager)
        }
    } onCancel: {
        cancellation.cancel(manager: manager)
    }
}
