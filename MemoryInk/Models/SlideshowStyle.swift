import SwiftUI

enum SlideshowStyle: String, CaseIterable, Identifiable {
    case natural
    case cinematic
    case vintage
    case minimalist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .natural:    return "Natural"
        case .cinematic:  return "Cinematic"
        case .vintage:    return "Vintage"
        case .minimalist: return "Minimalist"
        }
    }

    var icon: String {
        switch self {
        case .natural:    return "photo.fill"
        case .cinematic:  return "film.fill"
        case .vintage:    return "camera.filters"
        case .minimalist: return "square.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .natural:    return MemoryInkColors.sage
        case .cinematic:  return MemoryInkColors.amber
        case .vintage:    return MemoryInkColors.rosewood
        case .minimalist: return MemoryInkColors.mistBlue
        }
    }
}
