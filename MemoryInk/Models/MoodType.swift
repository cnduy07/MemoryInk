import SwiftUI

enum MoodType: String, CaseIterable, Identifiable {
    case peaceful
    case nostalgic
    case happy
    case proud
    case sad
    case reflective

    var id: String { rawValue }

    var title: String {
        switch self {
        case .peaceful:
            return "Peaceful"
        case .nostalgic:
            return "Nostalgic"
        case .happy:
            return "Happy"
        case .proud:
            return "Proud"
        case .sad:
            return "Sad"
        case .reflective:
            return "Reflective"
        }
    }

    var tint: Color {
        switch self {
        case .peaceful:
            return MemoryInkColors.sage
        case .nostalgic:
            return MemoryInkColors.amber
        case .happy:
            return MemoryInkColors.sunlit
        case .proud:
            return MemoryInkColors.rosewood
        case .sad:
            return MemoryInkColors.mistBlue
        case .reflective:
            return MemoryInkColors.taupe
        }
    }
}
