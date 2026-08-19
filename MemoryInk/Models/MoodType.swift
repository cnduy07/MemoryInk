import SwiftUI
import UIKit

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
            return MemoryInkColors.teal
        case .nostalgic:
            return MemoryInkColors.orchid
        case .happy:
            return MemoryInkColors.gold
        case .proud:
            return MemoryInkColors.coral
        case .sad:
            return MemoryInkColors.ocean
        case .reflective:
            return MemoryInkColors.twilight
        }
    }

    var secondaryTint: Color {
        switch self {
        case .peaceful:
            return MemoryInkColors.ocean
        case .nostalgic:
            return MemoryInkColors.coral
        case .happy:
            return MemoryInkColors.coral
        case .proud:
            return MemoryInkColors.gold
        case .sad:
            return MemoryInkColors.twilight
        case .reflective:
            return MemoryInkColors.orchid
        }
    }

    var gradientColors: [Color] {
        [tint, secondaryTint]
    }

    /// UIKit-side tint, for code that renders to an image rather than to a view.
    ///
    /// Not `UIColor(tint)` — that round-trip flattens the dynamic colour to whatever appearance is
    /// current and makes `resolvedColor(with:)` a no-op, which silently defeats pinning an export
    /// to a fixed appearance. See the note on `MemoryInkColors.Raw`.
    var tintRaw: UIColor {
        switch self {
        case .peaceful:
            return MemoryInkColors.Raw.teal
        case .nostalgic:
            return MemoryInkColors.Raw.orchid
        case .happy:
            return MemoryInkColors.Raw.gold
        case .proud:
            return MemoryInkColors.Raw.coral
        case .sad:
            return MemoryInkColors.Raw.ocean
        case .reflective:
            return MemoryInkColors.Raw.twilight
        }
    }

    var symbolName: String {
        switch self {
        case .peaceful:   return "leaf.fill"
        case .nostalgic:  return "moon.stars.fill"
        case .happy:      return "sun.max.fill"
        case .proud:      return "star.fill"
        case .sad:        return "cloud.rain.fill"
        case .reflective: return "sparkles"
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
