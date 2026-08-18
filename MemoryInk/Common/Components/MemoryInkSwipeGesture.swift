import SwiftUI

/// Shared swipe-to-commit gesture logic.
///
/// Extracted because `TimelineCard` (row swipe-to-favorite/share, snaps back in place)
/// and `CardBrowseView` (full-card swipe, flies off screen) independently built nearly
/// identical drag-tracking + "projected translation vs threshold" commit math. Each
/// screen's actual post-commit behavior (snap back vs fly away, its own state, its own
/// visual hints) stays local — only the gesture recognition itself is shared here.
enum MemoryInkSwipeDirection {
    case left
    case right
}

struct MemoryInkSwipeGestureConfig {
    var minimumDistance: CGFloat = 10
    /// Use `.global` when the gesture lives inside a scroll view and needs a stable
    /// coordinate space; `.local` otherwise.
    var useGlobalCoordinateSpace: Bool = false
    /// Only commit horizontal swipes when the drag is clearly more horizontal than
    /// vertical — needed when the view also sits inside a vertically scrolling list.
    var requireHorizontalDominance: Bool = false
    var predictionWeight: Double = 0.25
    var threshold: CGFloat = 100
}

func memoryInkSwipeGesture(
    _ config: MemoryInkSwipeGestureConfig,
    onChanged: @escaping (CGSize) -> Void,
    onCommit: @escaping (MemoryInkSwipeDirection) -> Void,
    onCancel: @escaping () -> Void
) -> some Gesture {
    let base = config.useGlobalCoordinateSpace
        ? DragGesture(minimumDistance: config.minimumDistance, coordinateSpace: .global)
        : DragGesture(minimumDistance: config.minimumDistance, coordinateSpace: .local)

    return base
        .onChanged { value in
            if config.requireHorizontalDominance {
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                guard horizontal > vertical * 1.2 else { return }
            }
            onChanged(value.translation)
        }
        .onEnded { value in
            if config.requireHorizontalDominance {
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                guard horizontal > vertical else {
                    onCancel()
                    return
                }
            }
            let projected = value.translation.width + value.predictedEndTranslation.width * config.predictionWeight
            if projected > config.threshold {
                onCommit(.right)
            } else if projected < -config.threshold {
                onCommit(.left)
            } else {
                onCancel()
            }
        }
}
