import SwiftUI

enum PhotoScopeKind: Equatable {
    case waveform
    case rgbParade
    case vectorscope

    var title: String {
        switch self {
        case .waveform: "WAVEFORM"
        case .rgbParade: "RGB PARADE"
        case .vectorscope: "VECTORSCOPE"
        }
    }

    var compactSize: CGSize {
        switch self {
        case .waveform, .rgbParade:
            CGSize(width: 182, height: 102)
        case .vectorscope:
            CGSize(width: 136, height: 136)
        }
    }

    var expandedSize: CGSize {
        switch self {
        case .waveform, .rgbParade:
            CGSize(width: 320, height: 184)
        case .vectorscope:
            CGSize(width: 248, height: 248)
        }
    }
}

struct PhotoScopeView: View {
    let kind: PhotoScopeKind
    let image: CGImage?
    @Binding var isExpanded: Bool

    var body: some View {
        let size = isExpanded ? kind.expandedSize : kind.compactSize

        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.72))

            scopeGrid

            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .padding(kind == .vectorscope ? 13 : 10)
            }

            scopeLabels
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.18), lineWidth: 0.7)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        }
        .accessibilityLabel(kind.title)
    }

    @ViewBuilder
    private var scopeGrid: some View {
        Canvas { context, size in
            var grid = Path()

            switch kind {
            case .waveform, .rgbParade:
                for fraction in [0.25, 0.5, 0.75] {
                    let y = size.height * fraction
                    grid.move(to: CGPoint(x: 7, y: y))
                    grid.addLine(to: CGPoint(x: size.width - 7, y: y))
                }

                if kind == .rgbParade {
                    for fraction in [1.0 / 3.0, 2.0 / 3.0] {
                        let x = size.width * fraction
                        grid.move(to: CGPoint(x: x, y: 16))
                        grid.addLine(to: CGPoint(x: x, y: size.height - 7))
                    }
                }

            case .vectorscope:
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.38
                grid.addEllipse(
                    in: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
                grid.move(to: CGPoint(x: center.x, y: 14))
                grid.addLine(to: CGPoint(x: center.x, y: size.height - 14))
                grid.move(to: CGPoint(x: 14, y: center.y))
                grid.addLine(to: CGPoint(x: size.width - 14, y: center.y))
            }

            context.stroke(
                grid,
                with: .color(.white.opacity(0.15)),
                lineWidth: 0.7
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var scopeLabels: some View {
        ZStack(alignment: .topLeading) {
            Text(kind.title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.leading, 7)
                .padding(.top, 5)

            switch kind {
            case .waveform:
                VStack {
                    Text("100")
                    Spacer()
                    Text("50")
                    Spacer()
                    Text("0")
                }
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(.white.opacity(0.52))
                .padding(.leading, 4)
                .padding(.vertical, 18)

            case .rgbParade:
                VStack {
                    Spacer()
                    HStack {
                        Text("R").foregroundStyle(.red)
                        Spacer()
                        Text("G").foregroundStyle(.green)
                        Spacer()
                        Text("B").foregroundStyle(.blue)
                    }
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 26)
                    .padding(.bottom, 4)
                }

            case .vectorscope:
                VStack {
                    HStack {
                        Spacer()
                        Text("R")
                        Spacer()
                        Text("M")
                        Spacer()
                        Text("B")
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("Y")
                        Spacer()
                        Text("C")
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text("G")
                        Spacer()
                    }
                }
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
                .padding(8)
            }
        }
        .allowsHitTesting(false)
    }
}
