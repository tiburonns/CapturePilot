import SwiftUI

struct LUTRecommendationView: View {
    @EnvironmentObject private var settings: AppSettings
    let recommendation: LUTRecommendation
    let isActive: Bool
    let onApply: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.filters")
                .font(.caption.weight(.bold))

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.text(.recommendedLUT))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(recommendation.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(settings.text(localizedReason))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button {
                onApply()
            } label: {
                Image(systemName: isActive ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(isActive)
            .accessibilityLabel(settings.text(isActive ? .lutActive : .applyLUT))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var localizedReason: LocalizedKey {
        switch recommendation.reason {
        case .portrait: .lutReasonPortrait
        case .protectHighlights: .lutReasonHighlights
        case .liftShadows: .lutReasonShadows
        case .night: .lutReasonNight
        case .landscape: .lutReasonLandscape
        case .architecture: .lutReasonArchitecture
        case .automotive: .lutReasonAutomotive
        case .street: .lutReasonStreet
        case .macro: .lutReasonMacro
        case .general: .lutReasonGeneral
        }
    }
}
