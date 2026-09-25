import PhotosUI
import SwiftUI
import UIKit

struct RankingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore
    @EnvironmentObject private var social: SocialCompetitionService
    @Environment(\.dismiss) private var dismiss

    @State private var topCount = 10
    @State private var category: PhotoCategory?
    @State private var searchText = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showingSocial = false

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

        return Array(
            filtered
                .sorted { lhs, rhs in
                    if lhs.coachScore == rhs.coachScore {
                        return lhs.createdAt > rhs.createdAt
                    }
                    return lhs.coachScore > rhs.coachScore
                }
                .prefix(topCount)
        )
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
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: 50,
                        matching: .images
                    ) {
                        Image(systemName: "photo.badge.plus")
                    }
                    .accessibilityLabel(localized("Import photos", "Importar fotos"))

                    Button {
                        showingSocial = true
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .accessibilityLabel(localized("Friends", "Amigos"))
                }
            }
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await rankingStore.ingest(
                                data: data,
                                source: .importPhoto
                            )
                        }
                    }
                    pickerItems = []
                }
            }
            .sheet(isPresented: $showingSocial) {
                SocialCompetitionView()
                    .environmentObject(settings)
                    .environmentObject(rankingStore)
                    .environmentObject(social)
            }
            .overlay(alignment: .bottom) {
                if rankingStore.isAnalyzing {
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
        .preferredColorScheme(.dark)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Top", selection: $topCount) {
                Text("Top 5").tag(5)
                Text("Top 10").tag(10)
                Text("Top 25").tag(25)
                Text("Top 50").tag(50)
            }
            .pickerStyle(.segmented)

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
                Text(entry.category.rawValue.capitalized)
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
}

private struct RankingDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var rankingStore: PhotoRankingStore

    let entry: PhotoRankingEntry
    let rank: Int

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
