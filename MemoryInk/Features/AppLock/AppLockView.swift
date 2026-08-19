import SwiftUI

/// The screen that stands in front of the journal while it's locked.
///
/// Deliberately quiet: no alarm, no red, no "access denied" language — it should feel like a
/// closed book, not a security checkpoint.
struct AppLockView: View {
    @ObservedObject var service: AppLockService

    var body: some View {
        ZStack {
            MemoryInkAmbientBackdrop(mood: nil, intensity: 0.9)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "book.closed")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(MemoryInkColors.secondaryInk)

                Text("Your journal is closed")
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)
                    .multilineTextAlignment(.center)

                Text("Unlock with \(service.biometryName) to pick up where you left off.")
                    .font(MemoryInkTypography.subtitle)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let message = service.message {
                    Text(message)
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.rosewood)
                }

                Button {
                    MemoryInkHaptics.light()
                    Task { await service.unlock() }
                } label: {
                    Text(service.isAuthenticating ? "Unlocking…" : "Unlock")
                        .font(MemoryInkTypography.subtitle.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 52)
                        .background(MemoryInkColors.rosewood.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.radiusMedium, style: .continuous))
                        .shadow(color: MemoryInkColors.rosewood.opacity(0.24), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(MemoryInkPressStyle())
                .disabled(service.isAuthenticating)
                .padding(.top, 8)
            }
            .memoryInkEntrance()
        }
        .task {
            // Offer the prompt straight away — one less tap in the common case.
            await service.unlock()
        }
    }
}
