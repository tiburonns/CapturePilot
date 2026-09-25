import SwiftUI

struct FalseColorOverlay: View {
    let image: CGImage?
    let isEnabled: Bool

    var body: some View {
        GeometryReader { geometry in
            if isEnabled, let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
