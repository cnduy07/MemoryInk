import SwiftUI
import UIKit

enum MemoryInkTypography {
    private static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Bundled display serif (Spectral SemiBold) used for titles/headers only —
    /// body text stays `.system` for legibility. Falls back to the system font
    /// automatically if the family name isn't registered for any reason.
    private static func serifTitle(size: CGFloat) -> Font {
        .custom("Spectral-SemiBold", size: size)
    }

    static var title: Font {
        serifTitle(size: isPad ? 44 : 36)
    }
    /// Same serif family as `title`, sized for the compact/shrunk header state
    /// (e.g. Timeline's scroll-collapsed app title).
    static var titleCompact: Font {
        serifTitle(size: 31)
    }
    static var eyebrow: Font {
        .system(size: isPad ? 13 : 12, weight: .medium, design: .default)
    }
    static var subtitle: Font {
        .system(size: isPad ? 17 : 15, weight: .regular, design: .default)
    }
    static var narrative: Font {
        .system(size: isPad ? 20 : 18, weight: .medium, design: .default)
    }
    static var narrativeCompact: Font {
        .system(size: isPad ? 19 : 17, weight: .medium, design: .default)
    }
    static var timestamp: Font {
        .system(size: isPad ? 14 : 12, weight: .regular, design: .default)
    }
    static var badge: Font {
        .system(size: isPad ? 14 : 12, weight: .medium, design: .default)
    }
}
