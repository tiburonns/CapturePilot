import SwiftUI

struct FrameGuideOverlay: View {
    let guide: AppSettings.FrameGuide

    var body: some View {
        GeometryReader { geometry in
            if let ratio = guide.aspectRatio {
                let isLandscape = geometry.size.width >= geometry.size.height
                let targetRatio = isLandscape ? ratio : 1.0 / ratio
                let rect = fittedRect(
                    targetRatio: targetRatio,
                    in: CGRect(origin: .zero, size: geometry.size)
                )

                Canvas { context, size in
                    var mask = Path()
                    mask.addRect(CGRect(origin: .zero, size: size))
                    mask.addRect(rect)

                    context.fill(
                        mask,
                        with: .color(.black.opacity(0.34)),
                        style: FillStyle(eoFill: true)
                    )

                    var border = Path()
                    border.addRect(rect)
                    context.stroke(
                        border,
                        with: .color(.white.opacity(0.72)),
                        style: StrokeStyle(lineWidth: 0.9, dash: [6, 4])
                    )
                }

                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: Capsule())
                    .position(x: rect.midX, y: max(14, rect.minY + 13))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var label: String {
        switch guide {
        case .none: ""
        case .square: "1:1"
        case .fourThree: "4:3"
        case .threeTwo: "3:2"
        case .sixteenNine: "16:9"
        case .cinema239: "2.39:1"
        }
    }

    private func fittedRect(
        targetRatio: Double,
        in bounds: CGRect
    ) -> CGRect {
        let availableRatio = Double(bounds.width / max(1, bounds.height))

        if availableRatio > targetRatio {
            let height = bounds.height
            let width = height * CGFloat(targetRatio)
            return CGRect(
                x: bounds.midX - width / 2,
                y: bounds.minY,
                width: width,
                height: height
            )
        }

        let width = bounds.width
        let height = width / CGFloat(targetRatio)
        return CGRect(
            x: bounds.minX,
            y: bounds.midY - height / 2,
            width: width,
            height: height
        )
    }
}
