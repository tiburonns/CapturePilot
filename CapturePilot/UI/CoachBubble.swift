import SwiftUI

struct CoachBubble: View {
    @EnvironmentObject private var settings: AppSettings
    let state: CoachState

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 24, height: 24)
                    .background(accentColor.opacity(0.14), in: Circle())

                Text(settings.text(.coach))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer(minLength: 4)

                statusDot
            }

            Text(settings.text(state.primaryMessage))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .contentTransition(.interpolate)
                .animation(.smooth(duration: 0.22), value: state.primaryMessage)

            if settings.coachIntensity == .teaching,
               let secondary = state.secondaryMessage {
                Text(settings.text(secondary))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: 320, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .animation(.smooth(duration: 0.22), value: state.severity)
        .accessibilityElement(children: .combine)
    }

    private var statusDot: some View {
        Circle()
            .fill(accentColor)
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    private var accentColor: Color {
        switch state.severity {
        case .neutral:
            .white
        case .positive:
            .green
        case .caution:
            .orange
        }
    }

    private var iconName: String {
        switch state.severity {
        case .neutral:
            return "viewfinder"
        case .positive:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        }
    }
}
