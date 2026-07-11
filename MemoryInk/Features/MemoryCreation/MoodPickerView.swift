import SwiftUI
import UIKit

struct MoodPickerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedMood: MoodType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(MoodType.allCases) { mood in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(MemoryInkMotion.standard(reduceMotion: reduceMotion)) {
                            selectedMood = mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: mood.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 30, height: 30)

                                Image(systemName: mood.symbolName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            Text(mood.title)
                                .font(MemoryInkTypography.badge)
                                .foregroundStyle(MemoryInkColors.secondaryInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.80)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(.ultraThinMaterial)
                        .background(
                            LinearGradient(
                                colors: [
                                    mood.tint.opacity(selectedMood == mood ? 0.25 : 0.09),
                                    mood.secondaryTint.opacity(selectedMood == mood ? 0.15 : 0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    selectedMood == mood ? mood.tint.opacity(0.68) : MemoryInkColors.hairline.opacity(0.24),
                                    lineWidth: selectedMood == mood ? 1.2 : 0.8
                                )
                        }
                        .shadow(color: mood.tint.opacity(selectedMood == mood ? 0.16 : 0), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(MemoryInkPressStyle())
                    .accessibilityLabel(mood.title)
                    .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                }
            }
        }
    }
}

struct MoodPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MoodPickerView(selectedMood: .constant(.peaceful))
            .padding()
            .background(MemoryInkColors.parchment)
    }
}
