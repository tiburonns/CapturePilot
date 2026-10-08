import SwiftUI

struct CompositionOverlay: View {
    let grid: AppSettings.Grid
    let coachIntensity: AppSettings.CoachIntensity
    let horizonAngle: Double
    let saliencyCenter: CGPoint
    let subjectRect: CGRect?
    let showSubjectMarker: Bool
    let leadingLines: [NormalizedLine]
    let vanishingPoint: CGPoint?
    let showAnalysisGeometry: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if grid != .none {
                    gridPath(in: geometry.size)
                        .stroke(
                            .white.opacity(gridOpacity),
                            style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
                        )
                }

                if showAnalysisGeometry {
                    leadingLinePath(in: geometry.size)
                        .stroke(
                            .yellow.opacity(leadingLineOpacity),
                            style: StrokeStyle(
                                lineWidth: 1.2,
                                lineCap: .round,
                                dash: [6, 5]
                            )
                        )

                    if let vanishingPoint,
                       (-0.05...1.05).contains(vanishingPoint.x),
                       (-0.05...1.05).contains(vanishingPoint.y) {
                        vanishingPointMarker(
                            at: vanishingPoint,
                            in: geometry.size
                        )
                    }
                }

                if showSubjectMarker {
                    subjectMarker(in: geometry.size)
                }

                horizonGuide(in: geometry.size)
            }
            .animation(.smooth(duration: 0.22), value: horizonAngle)
            .animation(.smooth(duration: 0.22), value: saliencyCenter)
            .animation(.smooth(duration: 0.22), value: leadingLines)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var gridOpacity: Double {
        switch coachIntensity {
        case .subtle: 0.18
        case .balanced: 0.27
        case .teaching: 0.34
        }
    }

    private var leadingLineOpacity: Double {
        switch coachIntensity {
        case .subtle: 0
        case .balanced: 0.34
        case .teaching: 0.52
        }
    }

    private var horizonThreshold: Double {
        switch coachIntensity {
        case .subtle: 1.8
        case .balanced: 1.0
        case .teaching: 0.45
        }
    }

    private var horizonColor: Color {
        let angle = abs(horizonAngle)
        if angle < 0.8 { return .green }
        if angle < 2.2 { return .orange }
        return .red
    }

    @ViewBuilder
    private func horizonGuide(in size: CGSize) -> some View {
        if coachIntensity != .subtle || abs(horizonAngle) > horizonThreshold {
            ZStack {
                HStack(spacing: 6) {
                    Rectangle()
                        .frame(width: 46, height: 1)
                    Circle()
                        .frame(width: 6, height: 6)
                    Rectangle()
                        .frame(width: 46, height: 1)
                }
                .foregroundStyle(horizonColor.opacity(0.88))
                .rotationEffect(.degrees(-horizonAngle))

                if abs(horizonAngle) > 0.8 {
                    Text(String(format: "%.1f°", abs(horizonAngle)))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(horizonColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.58), in: Capsule())
                        .offset(y: 22)
                }
            }
            .position(x: size.width / 2, y: size.height * 0.54)
        }
    }

    @ViewBuilder
    private func subjectMarker(in size: CGSize) -> some View {
        if let subjectRect {
            let rect = CGRect(
                x: subjectRect.minX * size.width,
                y: (1 - subjectRect.maxY) * size.height,
                width: subjectRect.width * size.width,
                height: subjectRect.height * size.height
            )

            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    .white.opacity(0.78),
                    style: StrokeStyle(lineWidth: 1.1, dash: [7, 5])
                )
                .frame(width: max(24, rect.width), height: max(24, rect.height))
                .position(x: rect.midX, y: rect.midY)

            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 5, height: 5)
                .position(
                    x: size.width * saliencyCenter.x,
                    y: size.height * (1 - saliencyCenter.y)
                )
        } else {
            Circle()
                .stroke(.white.opacity(0.78), lineWidth: 1)
                .frame(width: 18, height: 18)
                .position(
                    x: size.width * saliencyCenter.x,
                    y: size.height * (1 - saliencyCenter.y)
                )
        }
    }

    private func vanishingPointMarker(
        at point: CGPoint,
        in size: CGSize
    ) -> some View {
        ZStack {
            Circle()
                .stroke(.yellow.opacity(0.9), lineWidth: 1)
                .frame(width: 18, height: 18)

            Rectangle()
                .fill(.yellow.opacity(0.8))
                .frame(width: 1, height: 28)

            Rectangle()
                .fill(.yellow.opacity(0.8))
                .frame(width: 28, height: 1)
        }
        .position(
            x: size.width * point.x,
            y: size.height * point.y
        )
    }

    private func leadingLinePath(in size: CGSize) -> Path {
        Path { path in
            for line in leadingLines.prefix(3) where line.strength > 0.28 {
                path.move(to: CGPoint(
                    x: line.start.x * size.width,
                    y: line.start.y * size.height
                ))
                path.addLine(to: CGPoint(
                    x: line.end.x * size.width,
                    y: line.end.y * size.height
                ))
            }
        }
    }

    private func gridPath(in size: CGSize) -> Path {
        Path { path in
            switch grid {
            case .none:
                break

            case .thirds:
                for fraction in [1.0 / 3.0, 2.0 / 3.0] {
                    addGridCross(
                        to: &path,
                        fraction: fraction,
                        size: size
                    )
                }

            case .goldenRatio:
                for fraction in [0.382, 0.618] {
                    addGridCross(
                        to: &path,
                        fraction: fraction,
                        size: size
                    )
                }

            case .goldenSpiral:
                addGoldenSpiral(to: &path, size: size)

            case .goldenTriangle:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: size.height))

                let dx = size.width
                let dy = size.height
                let denominator = max(1, dx * dx + dy * dy)

                let topRight = CGPoint(x: size.width, y: 0)
                let t1 = (topRight.x * dx + topRight.y * dy) / denominator
                let projection1 = CGPoint(x: t1 * dx, y: t1 * dy)
                path.move(to: topRight)
                path.addLine(to: projection1)

                let bottomLeft = CGPoint(x: 0, y: size.height)
                let t2 = (bottomLeft.x * dx + bottomLeft.y * dy) / denominator
                let projection2 = CGPoint(x: t2 * dx, y: t2 * dy)
                path.move(to: bottomLeft)
                path.addLine(to: projection2)

            case .crosshair:
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
        }
    }

    private func addGridCross(
        to path: inout Path,
        fraction: Double,
        size: CGSize
    ) {
        path.move(to: CGPoint(x: size.width * fraction, y: 0))
        path.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
        path.move(to: CGPoint(x: 0, y: size.height * fraction))
        path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
    }

    private func addGoldenSpiral(to path: inout Path, size: CGSize) {
        let phi = (1 + sqrt(5.0)) / 2
        let b = log(phi) / (.pi / 2)
        let center = CGPoint(x: size.width * 0.382, y: size.height * 0.382)
        let maxRadius = min(size.width, size.height) * 0.78
        let endTheta = 3.25 * Double.pi
        let scale = maxRadius / exp(b * endTheta)

        var first = true
        for step in 0...180 {
            let theta = Double(step) / 180 * endTheta
            let radius = scale * exp(b * theta)
            let point = CGPoint(
                x: center.x + radius * cos(theta),
                y: center.y + radius * sin(theta)
            )
            if first {
                path.move(to: point)
                first = false
            } else {
                path.addLine(to: point)
            }
        }
    }
}
