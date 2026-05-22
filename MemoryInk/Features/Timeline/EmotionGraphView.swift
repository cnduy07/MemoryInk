import SwiftUI

struct EmotionGraphView: View {
    let entries: [JournalEntry]

    // Last 10 entries sorted oldest → newest
    private var dataPoints: [JournalEntry] {
        Array(entries.sorted { $0.createdAt < $1.createdAt }.suffix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mood journey")
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)

            if dataPoints.count >= 2 {
                GeometryReader { geo in
                    EmotionLineCanvas(entries: dataPoints, size: geo.size)
                }
                .frame(height: 80)
            } else if dataPoints.count == 1 {
                HStack {
                    Text(dataPoints[0].mood.emoji)
                        .font(.system(size: 22))
                    Text(dataPoints[0].mood.title)
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }
                .frame(height: 80)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MemoryInkColors.paper.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.22), lineWidth: 0.7)
        }
    }
}

// MARK: - Canvas

private struct EmotionLineCanvas: View {
    let entries: [JournalEntry]
    let size: CGSize

    @State private var drawProgress: CGFloat = 0

    private let maxValence: CGFloat = 5
    private let minValence: CGFloat = -5
    private let dotSize: CGFloat = 18
    private let hPad: CGFloat = 14
    private let vPad: CGFloat = 10

    private var drawWidth: CGFloat { max(size.width - hPad * 2, 1) }
    private var drawHeight: CGFloat { max(size.height - vPad * 2, 1) }

    // Convert valence (-5…+5) to Y position (top = positive)
    private func yPos(valence: Int) -> CGFloat {
        let norm = (CGFloat(valence) - minValence) / (maxValence - minValence)
        return vPad + (1 - norm) * drawHeight
    }

    // Convert entry index to X position
    private func xPos(index: Int) -> CGFloat {
        guard entries.count > 1 else { return size.width / 2 }
        return hPad + CGFloat(index) / CGFloat(entries.count - 1) * drawWidth
    }

    private var points: [CGPoint] {
        entries.enumerated().map { idx, entry in
            CGPoint(x: xPos(index: idx), y: yPos(valence: entry.mood.valence))
        }
    }

    private var midlineY: CGFloat { yPos(valence: 0) }

    var body: some View {
        ZStack {
            // Gradient fill between curve and midline
            fillShape
                .opacity(0.20)

            // Dashed midline
            Path { path in
                path.move(to: CGPoint(x: hPad, y: midlineY))
                path.addLine(to: CGPoint(x: size.width - hPad, y: midlineY))
            }
            .stroke(
                MemoryInkColors.hairline.opacity(0.55),
                style: StrokeStyle(lineWidth: 0.8, dash: [4, 4])
            )

            // Animated line
            EmotionCurveShape(points: points)
                .trim(from: 0, to: drawProgress)
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Emoji markers
            ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                let pt = points[idx]
                ZStack {
                    Circle()
                        .fill(entry.mood.tint.opacity(0.88))
                        .frame(width: dotSize, height: dotSize)
                    Text(entry.mood.emoji)
                        .font(.system(size: 9))
                }
                .position(x: pt.x, y: pt.y)
                .opacity(drawProgress > CGFloat(idx) / CGFloat(max(entries.count - 1, 1)) ? 1 : 0)
                .animation(.easeIn(duration: 0.15), value: drawProgress)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) {
                drawProgress = 1
            }
        }
    }

    // Gradient fill enclosed between curve and midline
    private var fillShape: some View {
        Path { path in
            guard points.count >= 2 else { return }
            // Draw the curve forward
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr,
                              control1: CGPoint(x: midX, y: prev.y),
                              control2: CGPoint(x: midX, y: curr.y))
            }
            // Close back along midline
            path.addLine(to: CGPoint(x: points.last!.x, y: midlineY))
            path.addLine(to: CGPoint(x: points.first!.x, y: midlineY))
            path.closeSubpath()
        }
        .fill(LinearGradient(
            colors: [lineColor.opacity(0.6), lineColor.opacity(0)],
            startPoint: averageValence >= 0 ? .top : .bottom,
            endPoint: averageValence >= 0 ? .bottom : .top
        ))
    }

    private var averageValence: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.mood.valence).reduce(0, +)) / Double(entries.count)
    }

    private var lineColor: Color {
        // Color of the dominant mood in the current set
        let counts = Dictionary(grouping: entries, by: \.mood).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key.tint ?? MemoryInkColors.sage
    }
}

// MARK: - Curve Shape

private struct EmotionCurveShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }
        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            path.addCurve(to: curr,
                          control1: CGPoint(x: midX, y: prev.y),
                          control2: CGPoint(x: midX, y: curr.y))
        }
        return path
    }
}
