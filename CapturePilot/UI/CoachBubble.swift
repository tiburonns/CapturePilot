import SwiftUI

struct CoachBubble: View {
    @EnvironmentObject private var settings: AppSettings
    let state: CoachState

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 7) {
                Image(systemName: iconName)
                    .font(.caption.weight(.bold))
                Text(settings.text(state.primaryMessage))
                    .font(.system(.headline, design: .rounded, weight: .semibold))
            }

            if settings.coachIntensity == .teaching, let secondary = state.secondaryMessage {
                Text(settings.text(secondary))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch state.severity {
        case .neutral: return "viewfinder"
        case .positive: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        }
    }
}
