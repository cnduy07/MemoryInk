import SwiftUI

struct ToastView: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isError ? MemoryInkColors.rosewood : MemoryInkColors.sage)

            Text(message)
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(isError ? MemoryInkColors.rosewood.opacity(0.12) : MemoryInkColors.sage.opacity(0.14))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(isError ? MemoryInkColors.rosewood.opacity(0.30) : MemoryInkColors.sage.opacity(0.34), lineWidth: 0.8)
        }
    }
}
