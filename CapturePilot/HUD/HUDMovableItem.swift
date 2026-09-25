import SwiftUI

struct HUDMovableItem<Content: View>: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var store: HUDLayoutStore

    let item: HUDItem
    let safeRect: CGRect
    let isLandscape: Bool
    @ViewBuilder let content: () -> Content

    @State private var itemSize = CGSize(width: 44, height: 44)
    @State private var dragTranslation: CGSize = .zero

    var body: some View {
        Group {
            if store.isEditing {
                renderedContent
                    .gesture(dragGesture)
            } else {
                renderedContent
            }
        }
    }

    private var renderedContent: some View {
        content()
            .allowsHitTesting(!store.isEditing)
            .opacity(store.isVisible(item) ? 1 : (store.isEditing ? 0.28 : 0))
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: HUDItemSizePreferenceKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(HUDItemSizePreferenceKey.self) { itemSize = $0 }
            .overlay {
                if store.isEditing {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            store.isVisible(item) ? Color.yellow : Color.secondary,
                            style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                        )
                        .padding(-5)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                if store.isEditing {
                    Text(settings.text(item.localizedKey))
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: Capsule())
                        .offset(y: -24)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .position(displayPoint)
            .zIndex(store.isEditing ? 100 : 1)
    }

    private var basePoint: CGPoint {
        let point = store.point(for: item, isLandscape: isLandscape)
        return CGPoint(
            x: safeRect.minX + safeRect.width * point.x,
            y: safeRect.minY + safeRect.height * point.y
        )
    }

    private var displayPoint: CGPoint {
        clamp(
            CGPoint(
                x: basePoint.x + dragTranslation.width,
                y: basePoint.y + dragTranslation.height
            )
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                dragTranslation = value.translation
            }
            .onEnded { value in
                let finalPoint = clamp(
                    CGPoint(
                        x: basePoint.x + value.translation.width,
                        y: basePoint.y + value.translation.height
                    )
                )

                let normalized = HUDNormalizedPoint(
                    x: safeRect.width > 0 ? (finalPoint.x - safeRect.minX) / safeRect.width : 0.5,
                    y: safeRect.height > 0 ? (finalPoint.y - safeRect.minY) / safeRect.height : 0.5
                )

                store.setPoint(normalized, for: item, isLandscape: isLandscape)
                dragTranslation = .zero
            }
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        let halfWidth = min(itemSize.width / 2 + 5, safeRect.width / 2)
        let halfHeight = min(itemSize.height / 2 + 5, safeRect.height / 2)

        let minX = safeRect.minX + halfWidth
        let maxX = safeRect.maxX - halfWidth
        let minY = safeRect.minY + halfHeight
        let maxY = safeRect.maxY - halfHeight

        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }
}

struct HUDCustomizationToolbar: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var store: HUDLayoutStore

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(HUDItem.allCases) { item in
                    if item.canHide {
                        Button {
                            store.setVisible(item, !store.isVisible(item))
                        } label: {
                            Label(
                                settings.text(item.localizedKey),
                                systemImage: store.isVisible(item) ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    } else {
                        Label(
                            settings.text(item.localizedKey) + " · " + settings.text(.required),
                            systemImage: "lock.fill"
                        )
                    }
                }
            } label: {
                Label(settings.text(.hudElements), systemImage: "square.grid.2x2")
            }

            Button {
                store.reset()
            } label: {
                Label(settings.text(.resetHUD), systemImage: "arrow.counterclockwise")
            }

            Button {
                store.isEditing = false
            } label: {
                Label(settings.text(.done), systemImage: "checkmark")
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct HUDItemSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = CGSize(width: 44, height: 44)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
