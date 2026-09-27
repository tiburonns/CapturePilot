import SwiftUI

struct CreativeSparkOverlay: View {
    let result: CreativeSparkResult?

    var body: some View {
        GeometryReader { geometry in
            if let result {
                ForEach(result.points) { point in
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.62))
                            .frame(width: 31, height: 31)

                        Circle()
                            .stroke(.yellow.opacity(0.92), lineWidth: 1.4)
                            .frame(width: 31, height: 31)

                        Text("\(point.index)")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                    }
                    .position(
                        aspectFillPosition(
                            point.position,
                            sourceAspectRatio: result.sourceAspectRatio,
                            in: geometry.size
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func aspectFillPosition(
        _ normalized: CGPoint,
        sourceAspectRatio: CGFloat,
        in size: CGSize
    ) -> CGPoint {
        guard size.width > 0,
              size.height > 0,
              sourceAspectRatio > 0 else {
            return CGPoint(
                x: normalized.x * size.width,
                y: normalized.y * size.height
            )
        }

        let viewAspectRatio = size.width / size.height

        if sourceAspectRatio > viewAspectRatio {
            let scaledWidth = size.height * sourceAspectRatio
            let cropX = (scaledWidth - size.width) / 2

            return CGPoint(
                x: normalized.x * scaledWidth - cropX,
                y: normalized.y * size.height
            )
        }

        let scaledHeight = size.width / sourceAspectRatio
        let cropY = (scaledHeight - size.height) / 2

        return CGPoint(
            x: normalized.x * size.width,
            y: normalized.y * scaledHeight - cropY
        )
    }
}

struct CreativeSparkControl: View {
    let result: CreativeSparkResult?
    let isScanning: Bool
    let language: AppSettings.Language
    let onScan: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Button(action: onScan) {
                    Group {
                        if isScanning {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: result == nil ? "sparkles" : "sparkles.rectangle.stack.fill")
                        }
                    }
                    .frame(width: 44, height: 44)
                    .foregroundStyle(result == nil ? .white : .yellow)
                    .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(localized("Creative Spark", "Chispa creativa"))

                if let result, !isScanning {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(localized("Creative Spark", "Chispa creativa"))
                                .font(.caption.bold())

                            Spacer()

                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(result.ideas) { idea in
                            HStack(alignment: .top, spacing: 6) {
                                if let index = idea.pointIndex {
                                    Text("\(index)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.black)
                                        .frame(width: 18, height: 18)
                                        .background(.yellow, in: Circle())
                                } else {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.caption2)
                                        .frame(width: 18)
                                }

                                Text(promptText(idea.prompt))
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Button(action: onScan) {
                            Label(
                                localized("Scan again", "Escanear de nuevo"),
                                systemImage: "arrow.clockwise"
                            )
                            .font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.yellow)
                    }
                    .padding(10)
                    .frame(width: 270, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func promptText(_ prompt: CreativeSparkPrompt) -> String {
        let es = resolvedSpanish

        switch prompt {
        case .makeAnchor:
            return es
                ? "Haz de este punto el ancla y construye el encuadre alrededor."
                : "Make this point the anchor and build the frame around it."
        case .moveCloser:
            return es
                ? "Acércate y elimina elementos hasta que quede una idea más fuerte."
                : "Move closer and remove elements until one idea becomes stronger."
        case .useConvergence:
            return es
                ? "Muévete unos pasos y exagera la convergencia hacia este punto."
                : "Move a few steps and exaggerate the convergence toward this point."
        case .followLine:
            return es
                ? "Prueba colocar el sujeto donde esta línea conduzca la mirada."
                : "Try placing the subject where this line leads the eye."
        case .exposeForLight:
            return es
                ? "Haz de esta zona de luz el motivo; prueba exponer pensando en ella."
                : "Make this pocket of light the motif; try exposing around it."
        case .leaveSpace:
            return es
                ? "Deja este espacio vacío a propósito y úsalo como parte de la historia."
                : "Leave this area intentionally empty and make the space part of the story."
        case .addForeground:
            return es
                ? "Busca algo cerca de la cámara para crear una primera capa."
                : "Find something close to the camera to create a foreground layer."
        case .breakSymmetry:
            return es
                ? "La simetría es fuerte; prueba romperla con un solo elemento."
                : "The symmetry is strong; try breaking it with one element."
        case .lowerAngle:
            return es
                ? "Baja la cámara y mira si el sujeto gana presencia."
                : "Lower the camera and see whether the subject gains presence."
        case .changeHeight:
            return es
                ? "Cambia radicalmente la altura: suelo, cintura o por encima de los ojos."
                : "Change height deliberately: ground, waist, or above eye level."
        case .isolateDetail:
            return es
                ? "Aísla este detalle y prueba una versión más simple y cercana."
                : "Isolate this detail and try a simpler, closer version."
        case .layerDepth:
            return es
                ? "Construye tres capas: primer plano, sujeto y fondo."
                : "Build three layers: foreground, subject, and background."
        }
    }

    private var resolvedSpanish: Bool {
        switch language {
        case .spanish: true
        case .english: false
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
        }
    }

    private func localized(_ english: String, _ spanish: String) -> String {
        resolvedSpanish ? spanish : english
    }
}
