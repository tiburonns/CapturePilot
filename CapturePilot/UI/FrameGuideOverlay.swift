import SwiftUI

struct FrameGuideOverlay: View {
    let guide: AppSettings.FrameGuide
    let showOutsideFrame: Bool

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
                    if !showOutsideFrame {
                        fillOutsideFrameBlack(
                            context: &context,
                            size: size,
                            frame: rect
                        )
                    }

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

    private func fillOutsideFrameBlack(
        context: inout GraphicsContext,
        size: CGSize,
        frame: CGRect
    ) {
        let black = GraphicsContext.Shading.color(.black)

        if frame.minY > 0 {
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: frame.minY)),
                with: black
            )
        }

        if frame.maxY < size.height {
            context.fill(
                Path(CGRect(
                    x: 0,
                    y: frame.maxY,
                    width: size.width,
                    height: size.height - frame.maxY
                )),
                with: black
            )
        }

        if frame.minX > 0 {
            context.fill(
                Path(CGRect(
                    x: 0,
                    y: frame.minY,
                    width: frame.minX,
                    height: frame.height
                )),
                with: black
            )
        }

        if frame.maxX < size.width {
            context.fill(
                Path(CGRect(
                    x: frame.maxX,
                    y: frame.minY,
                    width: size.width - frame.maxX,
                    height: frame.height
                )),
                with: black
            )
        }
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
