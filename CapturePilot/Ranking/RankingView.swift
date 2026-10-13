import ImageIO
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
                    PhotoImportView { items in
                        startImport(items)
                    }
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

    private func startImport(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        importCompleted = 0
        importTotal = items.count
        importImported = 0
        importDuplicates = 0
        importFailed = 0
        importWasCancelled = false
        isImportingPhotos = true

        importTask = Task { @MainActor in
            for item in items {
                guard !Task.isCancelled else {
                    importWasCancelled = true
                    break
                }

                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        importFailed += 1
                        importCompleted += 1
                        continue
                    }

                    let result = await rankingStore.ingest(
                        data: data,
                        source: .importPhoto,
                        assetIdentifier: item.itemIdentifier
                    )

                    switch result {
                    case .imported:
                        importImported += 1
                    case .duplicate:
                        importDuplicates += 1
                    case .failed:
                        importFailed += 1
                    }
                } catch {
                    importFailed += 1
                }

                importCompleted += 1
            }

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

private struct PendingPhoto: Identifiable {
    let id: UUID
    let item: PhotosPickerItem

    init(item: PhotosPickerItem) {
        id = UUID()
        self.item = item
    }
}

private struct PhotoImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let onImport: ([PhotosPickerItem]) -> Void

    @State private var selection: [PhotosPickerItem] = []
    @State private var pendingPhotos: [PendingPhoto] = []

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 140), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                PhotosPicker(
                    selection: $selection,
                    selectionBehavior: .ordered,
                    matching: .images
                ) {
                    Label(
                        localized("Choose photos from Library", "Elegir fotos de la fototeca"),
                        systemImage: "photo.on.rectangle.angled"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                HStack {
                    Text(localized(
                        "\(pendingPhotos.count) selected",
                        "\(pendingPhotos.count) seleccionadas"
                    ))
                    .font(.subheadline.weight(.semibold))

                    Spacer()

                    if !pendingPhotos.isEmpty {
                        Button(localized("Clear", "Limpiar"), role: .destructive) {
                            selection = []
                            pendingPhotos = []
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)

                if pendingPhotos.isEmpty {
                    ContentUnavailableView(
                        localized("No photos selected", "No hay fotos seleccionadas"),
                        systemImage: "photo.stack",
                        description: Text(localized(
                            "Choose any number of images, review the selection, then import. No artificial 50-photo cap is applied.",
                            "Elige tantas imágenes como necesites, revisa la selección e impórtalas. No se impone un límite artificial de 50 fotos."
                        ))
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(pendingPhotos) { photo in
                                PhotoImportThumbnail(photo: photo) {
                                    pendingPhotos.removeAll { $0.id == photo.id }
                                    selection = pendingPhotos.map(\.item)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }

                Button {
                    let selected = pendingPhotos.map(\.item)
                    dismiss()
                    onImport(selected)
                } label: {
                    Label(
                        localized("Import \(pendingPhotos.count) photos", "Importar \(pendingPhotos.count) fotos"),
                        systemImage: "square.and.arrow.down"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pendingPhotos.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle(localized("Review import", "Revisar importación"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localized("Cancel", "Cancelar")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selection) { _, items in
            let previousByItem = Dictionary(
                uniqueKeysWithValues: pendingPhotos.map { ($0.item, $0) }
            )
            pendingPhotos = items.map { item in
                previousByItem[item] ?? PendingPhoto(item: item)
            }
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

private struct PhotoImportThumbnail: View {
    @EnvironmentObject private var settings: AppSettings

    let photo: PendingPhoto
    let onRemove: () -> Void

    @State private var thumbnailData: Data?
    @State private var failedToLoad = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let thumbnailData, let image = UIImage(data: thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if failedToLoad {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 104)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.75))
                    .padding(3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localized("Remove selected photo", "Quitar foto seleccionada"))
        }
        .task(id: photo.id) {
            await loadThumbnail()
        }
        .onDisappear {
            thumbnailData = nil
        }
    }

    private func loadThumbnail() async {
        do {
            guard let data = try await photo.item.loadTransferable(type: Data.self) else {
                failedToLoad = true
                return
            }

            let preview = await Task.detached(priority: .utility) {
                Self.makeThumbnailData(from: data)
            }.value

            guard !Task.isCancelled else { return }
            if let preview {
                thumbnailData = preview
            } else {
                failedToLoad = true
            }
        } catch {
            failedToLoad = true
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

    private static func makeThumbnailData(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 160
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: 0.65] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
