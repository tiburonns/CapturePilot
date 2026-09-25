import SwiftUI

struct FocusPeakingOverlay: View {
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
                    .opacity(0.92)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
