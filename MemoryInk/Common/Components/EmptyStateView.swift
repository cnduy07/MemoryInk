import SwiftUI

struct EmptyStateView: View {
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    let isActionDisabled: Bool

    init(
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
        self.isActionDisabled = false
    }

    init(
        message: String,
        actionLabel: String?,
        isActionDisabled: Bool,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
        self.isActionDisabled = isActionDisabled
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(message)
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(7)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionLabel, let action {
                Button {
                    action()
                } label: {
                    Text(actionLabel)
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(MemoryInkColors.paper.opacity(0.72))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(MemoryInkColors.hairline.opacity(0.28), lineWidth: 0.7)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isActionDisabled)
                .opacity(isActionDisabled ? 0.52 : 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
