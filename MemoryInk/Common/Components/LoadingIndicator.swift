import SwiftUI

struct LoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(MemoryInkColors.tertiaryInk)
                    .frame(width: 6, height: 6)
                    .opacity(isAnimating ? 0.34 : 1)
                    .animation(
                        .easeInOut(duration: 0.64)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
