import SwiftUI

struct ClippingWarningView: View {
    @EnvironmentObject private var settings: AppSettings
    let snapshot: HistogramSnapshot

    var body: some View {
        HStack(spacing: 8) {
            warning(
                icon: "arrowtriangle.down.fill",
                label: settings.text(.shadowsClipped),
                active: snapshot.hasShadowClipping,
                channels: shadowChannels
            )

            warning(
                icon: "arrowtriangle.up.fill",
                label: settings.text(.highlightsClipped),
                active: snapshot.hasHighlightClipping,
                channels: highlightChannels
            )
        }
        .padding(.horizontal, 9)
        .frame(height: 36)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func warning(
        icon: String,
        label: String,
        active: Bool,
        channels: String
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(channels.isEmpty ? "—" : channels)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(active ? Color.white : Color.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(active ? channels : settings.text(.off))
    }

    private var shadowChannels: String {
        channelString(
            red: snapshot.redShadowClipRatio > 0.01,
            green: snapshot.greenShadowClipRatio > 0.01,
            blue: snapshot.blueShadowClipRatio > 0.01
        )
    }

    private var highlightChannels: String {
        channelString(
            red: snapshot.redHighlightClipRatio > 0.002,
            green: snapshot.greenHighlightClipRatio > 0.002,
            blue: snapshot.blueHighlightClipRatio > 0.002
        )
    }

    private func channelString(red: Bool, green: Bool, blue: Bool) -> String {
        var value = ""
        if red { value += "R" }
        if green { value += "G" }
        if blue { value += "B" }
        return value
    }
}
