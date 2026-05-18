import SwiftUI

struct TimelineMemory: Identifiable, Hashable {
    let id: UUID
    let mood: MoodType
    let narrative: String
    let timestamp: Date
    let palette: [Color]
    let lightLeak: Color
    let accent: Color
    let narrativeStyle: NarrativeStyle
}

extension TimelineMemory {
    static let preview = TimelineMemory(
        id: UUID(),
        mood: .peaceful,
        narrative: "The afternoon softened around the window, leaving everything warm and still for a little while.",
        timestamp: Date(),
        palette: [
            Color(red: 0.68, green: 0.62, blue: 0.52),
            Color(red: 0.90, green: 0.80, blue: 0.64),
            Color(red: 0.42, green: 0.47, blue: 0.40)
        ],
        lightLeak: Color(red: 0.96, green: 0.70, blue: 0.44),
        accent: Color(red: 0.36, green: 0.42, blue: 0.34),
        narrativeStyle: .warm
    )
}

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var memories: [TimelineMemory] = TimelineViewModel.mockMemories

    private static let calendar = Calendar.current

    private static var mockMemories: [TimelineMemory] {
        [
            TimelineMemory(
                id: UUID(),
                mood: .peaceful,
                narrative: "The afternoon softened around the window, leaving everything warm and still for a little while.",
                timestamp: calendar.date(from: DateComponents(year: 2026, month: 5, day: 18, hour: 16, minute: 12)) ?? Date(),
                palette: [
                    Color(red: 0.50, green: 0.55, blue: 0.45),
                    Color(red: 0.86, green: 0.76, blue: 0.60),
                    Color(red: 0.28, green: 0.34, blue: 0.30)
                ],
                lightLeak: Color(red: 0.96, green: 0.70, blue: 0.44),
                accent: Color(red: 0.36, green: 0.42, blue: 0.34),
                narrativeStyle: .warm
            ),
            TimelineMemory(
                id: UUID(),
                mood: .nostalgic,
                narrative: "A small familiar corner held the whole day together, like a scene you did not know you would miss.",
                timestamp: calendar.date(from: DateComponents(year: 2026, month: 5, day: 16, hour: 9, minute: 38)) ?? Date(),
                palette: [
                    Color(red: 0.38, green: 0.32, blue: 0.28),
                    Color(red: 0.76, green: 0.58, blue: 0.40),
                    Color(red: 0.22, green: 0.25, blue: 0.28)
                ],
                lightLeak: Color(red: 0.92, green: 0.58, blue: 0.34),
                accent: Color(red: 0.62, green: 0.45, blue: 0.30),
                narrativeStyle: .reflective
            ),
            TimelineMemory(
                id: UUID(),
                mood: .proud,
                narrative: "There was a quiet kind of joy in seeing effort become something real, with no need to announce itself.",
                timestamp: calendar.date(from: DateComponents(year: 2026, month: 5, day: 12, hour: 18, minute: 4)) ?? Date(),
                palette: [
                    Color(red: 0.30, green: 0.32, blue: 0.29),
                    Color(red: 0.70, green: 0.49, blue: 0.39),
                    Color(red: 0.90, green: 0.78, blue: 0.58)
                ],
                lightLeak: Color(red: 0.78, green: 0.43, blue: 0.36),
                accent: Color(red: 0.54, green: 0.32, blue: 0.30),
                narrativeStyle: .minimal
            ),
            TimelineMemory(
                id: UUID(),
                mood: .reflective,
                narrative: "The evening arrived slowly, giving the moment enough room to become a memory before it passed.",
                timestamp: calendar.date(from: DateComponents(year: 2026, month: 5, day: 8, hour: 20, minute: 27)) ?? Date(),
                palette: [
                    Color(red: 0.26, green: 0.29, blue: 0.34),
                    Color(red: 0.52, green: 0.46, blue: 0.42),
                    Color(red: 0.80, green: 0.70, blue: 0.56)
                ],
                lightLeak: Color(red: 0.64, green: 0.55, blue: 0.45),
                accent: Color(red: 0.40, green: 0.45, blue: 0.50),
                narrativeStyle: .reflective
            )
        ]
    }
}
