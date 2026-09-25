import SwiftUI

struct HistogramView: View {
    let snapshot: HistogramSnapshot
    @Binding var isExpanded: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.66))

            Canvas { context, size in
                context.stroke(
                    channelPath(snapshot.luma, size: size),
                    with: .color(.white.opacity(0.20)),
                    lineWidth: isExpanded ? 1.2 : 0.8
                )
                context.stroke(
                    channelPath(snapshot.red, size: size),
                    with: .color(.red.opacity(0.86)),
                    lineWidth: isExpanded ? 1.35 : 0.9
                )
                context.stroke(
                    channelPath(snapshot.green, size: size),
                    with: .color(.green.opacity(0.82)),
                    lineWidth: isExpanded ? 1.35 : 0.9
                )
                context.stroke(
                    channelPath(snapshot.blue, size: size),
                    with: .color(.blue.opacity(0.90)),
                    lineWidth: isExpanded ? 1.35 : 0.9
                )
            }
            .padding(.horizontal, 6)
            .padding(.top, 20)
            .padding(.bottom, 6)

            HStack(spacing: 6) {
                Text("RGB")
                    .font(.caption2.weight(.bold))
                    .monospaced()
                Spacer(minLength: 4)
                clippingIndicators
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)
        }
        .frame(width: isExpanded ? 310 : 176, height: isExpanded ? 176 : 88)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.18), lineWidth: 0.7)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.snappy) { isExpanded.toggle() }
        }
        .accessibilityLabel("RGB histogram")
    }

    private var clippingIndicators: some View {
        HStack(spacing: 4) {
            if snapshot.hasShadowClipping {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.76))
            }

            channelIndicator(
                "R",
                active: snapshot.redHighlightClipRatio > 0.002 || snapshot.redShadowClipRatio > 0.01,
                color: .red
            )
            channelIndicator(
                "G",
                active: snapshot.greenHighlightClipRatio > 0.002 || snapshot.greenShadowClipRatio > 0.01,
                color: .green
            )
            channelIndicator(
                "B",
                active: snapshot.blueHighlightClipRatio > 0.002 || snapshot.blueShadowClipRatio > 0.01,
                color: .blue
            )

            if snapshot.hasHighlightClipping {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.76))
            }
        }
    }

    private func channelIndicator(_ label: String, active: Bool, color: Color) -> some View {
        Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(active ? color : .secondary)
    }

    private func channelPath(_ values: [Double], size: CGSize) -> Path {
        guard values.count > 1 else { return Path() }

        var path = Path()
        for index in values.indices {
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height * (1 - CGFloat(min(max(values[index], 0), 1)))

            if index == values.startIndex {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

}
