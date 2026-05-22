import SwiftUI

enum MoodType: String, CaseIterable, Identifiable {
    case peaceful
    case nostalgic
    case happy
    case proud
    case sad
    case reflective

    var id: String { rawValue }

    var audioFileNames: [String] {
        ["audio_\(rawValue)_1"]
    }

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

    var valence: Int {
        switch self {
        case .happy:      return  5
        case .proud:      return  4
        case .peaceful:   return  3
        case .nostalgic:  return  1
        case .reflective: return  0
        case .sad:        return -4
        }
    }

    var emoji: String {
        switch self {
        case .happy:      return "😊"
        case .proud:      return "🌟"
        case .peaceful:   return "😌"
        case .nostalgic:  return "🌙"
        case .reflective: return "🤔"
        case .sad:        return "😔"
        }
    }
}
