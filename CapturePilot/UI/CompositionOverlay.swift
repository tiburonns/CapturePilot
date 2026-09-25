import SwiftUI

struct CompositionOverlay: View {
    let grid: AppSettings.Grid
    let horizonAngle: Double
    let saliencyCenter: CGPoint
    let showSubjectMarker: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gridPath(in: geometry.size)
                    .stroke(.white.opacity(0.34), lineWidth: 0.7)

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

            case .crosshair:
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
        }
    }
}
