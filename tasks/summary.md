### Planned Changes
- Typography.swift modify — convert static lets to computed vars with isPad branching
- TimelineView.swift modify — lift 430pt card and detail caps to 580pt on iPad

### Code
```swift
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
```

```swift
let regularWidth = finiteDimension(min(availableWidth, viewportWidth > 700 ? 580 : 430))
let detailWidth = finiteDimension(min(availableDetailWidth, isCompact ? 304 : (viewportWidth > 700 ? 580 : 430)))
```

### Summary
- Files changed: MemoryInk/Common/Theme/Typography.swift; MemoryInk/Features/Timeline/TimelineView.swift; tasks/summary.md
- Behavior change: App typography now keeps the original iPhone sizes while scaling the existing seven font styles on iPad. Timeline cards and detail overlays now cap at 580pt when the viewport is wider than 700pt, while compact width remains 304pt.
- Checks run: `grep -n "static let" MemoryInk/Common/Theme/Typography.swift` produced no output; `grep -n "isPad" MemoryInk/Common/Theme/Typography.swift` returned 8 lines; `grep -n "isPad ? 44" MemoryInk/Common/Theme/Typography.swift` returned 1 match; `grep -n "isPad ? 20" MemoryInk/Common/Theme/Typography.swift` returned 1 match; `grep -n "isPad ? 14" MemoryInk/Common/Theme/Typography.swift` returned 2 matches because both `timestamp` and `badge` use the requested 14pt iPad size; `grep -n "580" MemoryInk/Features/Timeline/TimelineView.swift` returned 2 matches; `grep -n "304" MemoryInk/Features/Timeline/TimelineView.swift` returned 2 matches; `SDK=$(xcrun --sdk iphonesimulator --show-sdk-path) && xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios17.0-simulator -parse-as-library -module-cache-path /private/tmp/MemoryInkMC $(find MemoryInk -name "*.swift") 2>&1 | grep "error:"` produced no output; `ls "MemoryInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"` found the file.
- Not verified: No simulator UI pass was run.
- Needs human approval for next step: no
