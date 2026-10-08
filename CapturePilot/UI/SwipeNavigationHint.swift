import SwiftUI

enum SwipeNavigationDirection {
    case left
    case right

    var iconName: String {
        switch self {
        case .left: "chevron.left.2"
        case .right: "chevron.right.2"
        }
    }
}

struct SwipeNavigationHint: View {
    let direction: SwipeNavigationDirection
    let progress: CGFloat

    var body: some View {
        HStack {
            if direction == .right {
                hint
                    .padding(.leading, 10)
                Spacer()
            } else {
                Spacer()
                hint
                    .padding(.trailing, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(min(max(progress, 0), 1))
        .allowsHitTesting(false)
    }

    private var hint: some View {
        Image(systemName: direction.iconName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 72)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .scaleEffect(0.88 + progress * 0.12)
    }
}
