import SwiftUI

struct TimelineMemory: Identifiable, Hashable {
    let id: UUID
    let mood: MoodType
    let narrative: String
    let narrativeState: NarrativeDisplayState
    let timestamp: Date
    let thumbnailPath: String?
    let narrativeStyle: NarrativeStyle
    let isFavorite: Bool
    let voicePath: String?
}

struct TimelineInsight: Equatable {
    let mood: MoodType
    let message: String
}

extension TimelineMemory {
    static let preview = TimelineMemory(
        id: UUID(),
        mood: .peaceful,
        narrative: "The afternoon softened around the window, leaving everything warm and still for a little while.",
        narrativeState: .generated,
        timestamp: Date(),
        thumbnailPath: nil,
        narrativeStyle: .warm,
        isFavorite: true,
        voicePath: nil
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
                narrativeStyle: entry.narrativeStyle,
                isFavorite: entry.isFavorite,
                voicePath: entry.voicePath
            )
        }
    }

    func recentInsight(
        from entries: [JournalEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TimelineInsight? {
        guard let startDate = calendar.date(
            byAdding: .day,
            value: -6,
            to: calendar.startOfDay(for: now)
        ) else {
            return nil
        }

        let recentEntries = entries.filter {
            $0.createdAt >= startDate && $0.createdAt <= now
        }
        guard recentEntries.count >= 2 else { return nil }

        let moodCounts = Dictionary(grouping: recentEntries, by: \JournalEntry.mood)
            .mapValues(\.count)
        guard let dominantMood = MoodType.allCases.max(by: {
            moodCounts[$0, default: 0] < moodCounts[$1, default: 0]
        }) else {
            return nil
        }

        return TimelineInsight(
            mood: dominantMood,
            message: insightMessage(for: dominantMood)
        )
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

    private func insightMessage(for mood: MoodType) -> String {
        switch mood {
        case .peaceful:
            return "A quieter rhythm has been showing up lately."
        case .nostalgic:
            return "Familiar feelings have been gently resurfacing."
        case .happy:
            return "There has been a little more light lately."
        case .proud:
            return "A quiet sense of progress is coming through."
        case .sad:
            return "Some tender moments have been given space."
        case .reflective:
            return "Thoughtful moments have been gathering lately."
        }
    }



}
