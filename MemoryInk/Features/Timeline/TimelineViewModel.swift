import SwiftUI

struct TimelineMemory: Identifiable, Hashable {
    let id: UUID
    let mood: MoodType
    let narrative: String
    let narrativeState: NarrativeDisplayState
    let timestamp: Date
    let thumbnailPath: String?
    let palette: [Color]
    let lightLeak: Color
    let accent: Color
    let narrativeStyle: NarrativeStyle
    let isFavorite: Bool
}

extension TimelineMemory {
    static let preview = TimelineMemory(
        id: UUID(),
        mood: .peaceful,
        narrative: "The afternoon softened around the window, leaving everything warm and still for a little while.",
        narrativeState: .generated,
        timestamp: Date(),
        thumbnailPath: nil,
        palette: [
            Color(red: 0.68, green: 0.62, blue: 0.52),
            Color(red: 0.90, green: 0.80, blue: 0.64),
            Color(red: 0.42, green: 0.47, blue: 0.40)
        ],
        lightLeak: Color(red: 0.96, green: 0.70, blue: 0.44),
        accent: Color(red: 0.36, green: 0.42, blue: 0.34),
        narrativeStyle: .warm,
        isFavorite: true
    )
}

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var showingFavoritesOnly = false
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var activeMoodFilter: MoodType?
    @AppStorage("timeline_layout") var isGridLayout = false

    func memories(
        from entries: [JournalEntry],
        generationStates: [UUID: NarrativeDisplayState] = [:]
    ) -> [TimelineMemory] {
        let baseEntries = showingFavoritesOnly ? entries.filter(\.isFavorite) : entries
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchedEntries = trimmedQuery.isEmpty ? baseEntries : baseEntries.filter { entry in
            let lower = trimmedQuery.lowercased()
            return (entry.rawNote?.lowercased().contains(lower) == true) ||
                (entry.aiNarrative?.lowercased().contains(lower) == true)
        }
        let visibleEntries = activeMoodFilter == nil ? searchedEntries : searchedEntries.filter {
            $0.mood == activeMoodFilter
        }

        return visibleEntries.map { entry in
            let displayState = narrativeState(for: entry, generationStates: generationStates)

            return TimelineMemory(
                id: entry.id,
                mood: entry.mood,
                narrative: narrative(for: entry, state: displayState),
                narrativeState: displayState,
                timestamp: entry.createdAt,
                thumbnailPath: entry.thumbnailPath,
                palette: palette(for: entry.mood),
                lightLeak: lightLeak(for: entry.mood),
                accent: accent(for: entry.mood),
                narrativeStyle: entry.narrativeStyle,
                isFavorite: entry.isFavorite
            )
        }
    }

    private func narrativeState(
        for entry: JournalEntry,
        generationStates: [UUID: NarrativeDisplayState]
    ) -> NarrativeDisplayState {
        if let aiNarrative = entry.aiNarrative, !aiNarrative.isEmpty {
            return .generated
        }

        if let state = generationStates[entry.id] {
            return state
        }

        return .pending
    }

    private func narrative(for entry: JournalEntry, state: NarrativeDisplayState) -> String {
        if let aiNarrative = entry.aiNarrative, !aiNarrative.isEmpty {
            return aiNarrative
        }

        if let message = state.message {
            return message
        }

        return "Narrative will appear shortly."
    }

    private func palette(for mood: MoodType) -> [Color] {
        switch mood {
        case .peaceful:
            return [
                Color(red: 0.50, green: 0.55, blue: 0.45),
                Color(red: 0.86, green: 0.76, blue: 0.60),
                Color(red: 0.28, green: 0.34, blue: 0.30)
            ]
        case .nostalgic:
            return [
                Color(red: 0.38, green: 0.32, blue: 0.28),
                Color(red: 0.76, green: 0.58, blue: 0.40),
                Color(red: 0.22, green: 0.25, blue: 0.28)
            ]
        case .happy:
            return [
                Color(red: 0.76, green: 0.62, blue: 0.40),
                Color(red: 0.90, green: 0.78, blue: 0.56),
                Color(red: 0.42, green: 0.48, blue: 0.40)
            ]
        case .proud:
            return [
                Color(red: 0.30, green: 0.32, blue: 0.29),
                Color(red: 0.70, green: 0.49, blue: 0.39),
                Color(red: 0.90, green: 0.78, blue: 0.58)
            ]
        case .sad:
            return [
                Color(red: 0.34, green: 0.39, blue: 0.43),
                Color(red: 0.62, green: 0.58, blue: 0.52),
                Color(red: 0.78, green: 0.70, blue: 0.60)
            ]
        case .reflective:
            return [
                Color(red: 0.26, green: 0.29, blue: 0.34),
                Color(red: 0.52, green: 0.46, blue: 0.42),
                Color(red: 0.80, green: 0.70, blue: 0.56)
            ]
        }
    }

    private func lightLeak(for mood: MoodType) -> Color {
        switch mood {
        case .peaceful, .happy:
            return Color(red: 0.96, green: 0.70, blue: 0.44)
        case .nostalgic:
            return Color(red: 0.92, green: 0.58, blue: 0.34)
        case .proud:
            return Color(red: 0.78, green: 0.43, blue: 0.36)
        case .sad:
            return Color(red: 0.56, green: 0.62, blue: 0.66)
        case .reflective:
            return Color(red: 0.64, green: 0.55, blue: 0.45)
        }
    }

    private func accent(for mood: MoodType) -> Color {
        switch mood {
        case .peaceful:
            return Color(red: 0.36, green: 0.42, blue: 0.34)
        case .nostalgic:
            return Color(red: 0.62, green: 0.45, blue: 0.30)
        case .happy:
            return Color(red: 0.68, green: 0.52, blue: 0.32)
        case .proud:
            return Color(red: 0.54, green: 0.32, blue: 0.30)
        case .sad:
            return Color(red: 0.38, green: 0.45, blue: 0.50)
        case .reflective:
            return Color(red: 0.40, green: 0.45, blue: 0.50)
        }
    }
}
