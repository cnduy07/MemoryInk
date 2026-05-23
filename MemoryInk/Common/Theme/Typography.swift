import SwiftUI
import UIKit

enum MemoryInkTypography {
    private static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var title: Font {
        .system(size: isPad ? 44 : 36, weight: .semibold, design: .default)
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
