import SwiftUI

struct MoodPickerView: View {
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
                        selectedMood = mood
                    } label: {
                        Text(mood.title)
                            .font(MemoryInkTypography.badge)
                            .foregroundStyle(selectedMood == mood ? MemoryInkColors.ink : MemoryInkColors.secondaryInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.88)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(mood.tint.opacity(selectedMood == mood ? 0.22 : 0.10))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(
                                        selectedMood == mood ? mood.tint.opacity(0.34) : MemoryInkColors.hairline.opacity(0.24),
                                        lineWidth: 0.8
                                    )
                            }
                    }
                    .buttonStyle(.plain)
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
