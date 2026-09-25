import SwiftUI

struct CompositionOverlay: View {
    let grid: AppSettings.Grid
    let horizonAngle: Double
    let saliencyCenter: CGPoint
    let showSubjectMarker: Bool
    let leadingLines: [NormalizedLine]
    let vanishingPoint: CGPoint?
    let showAnalysisGeometry: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gridPath(in: geometry.size)
                    .stroke(.white.opacity(0.34), lineWidth: 0.7)

                if showAnalysisGeometry {
                    leadingLinePath(in: geometry.size)
                        .stroke(
                            .yellow.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )

                    if let vanishingPoint,
                       (-0.05...1.05).contains(vanishingPoint.x),
                       (-0.05...1.05).contains(vanishingPoint.y) {
                        Circle()
                            .stroke(.yellow.opacity(0.75), lineWidth: 1)
                            .frame(width: 14, height: 14)
                            .position(
                                x: geometry.size.width * vanishingPoint.x,
                                y: geometry.size.height * vanishingPoint.y
                            )
                    }
                }

                if showSubjectMarker {
                    Circle()
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                        .frame(width: 18, height: 18)
                        .position(
                            x: geometry.size.width * saliencyCenter.x,
                            y: geometry.size.height * (1 - saliencyCenter.y)
                        )
                }

                HStack(spacing: 5) {
                    Rectangle().frame(width: 42, height: 1)
                    Circle().frame(width: 5, height: 5)
                    Rectangle().frame(width: 42, height: 1)
                }
                .foregroundStyle(abs(horizonAngle) < 1.0 ? .green : .white)
                .rotationEffect(.degrees(-horizonAngle))
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.54)
            }
        }
        .allowsHitTesting(false)
    }

    private func leadingLinePath(in size: CGSize) -> Path {
        Path { path in
            for line in leadingLines {
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
                    path.move(to: CGPoint(x: size.width * fraction, y: 0))
                    path.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
                    path.move(to: CGPoint(x: 0, y: size.height * fraction))
                    path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                }

            case .goldenRatio:
                for fraction in [0.382, 0.618] {
                    path.move(to: CGPoint(x: size.width * fraction, y: 0))
                    path.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
                    path.move(to: CGPoint(x: 0, y: size.height * fraction))
                    path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
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
