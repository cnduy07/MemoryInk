# Task 3: Weekly Recap — Full Screen Redesign

**Date:** 2026-05-21
**Priority:** High

---

## Context

`RecapView.swift` currently shows a plain eyebrow label, an 8pt mood dot grid, a simple amber-bar narrative card, and a generate button. The user wants it to look "awesome" — immersive, data-rich, and emotional. This task redesigns the view in-place with no new files or packages.

---

## File

| File | Action |
|------|--------|
| `MemoryInk/Features/Recap/RecapView.swift` | **rewrite** |

No other files change.

---

## Data Available (do NOT add new service calls)

- `recapService.latestRecap: WeeklyRecap?` — `recap: String`, `generatedAt: Date`, `entryIds: [UUID]`
- `recapService.errorMessage: String?`
- `repository.entriesSince(_ date: Date) -> [JournalEntry]` — use this to get the last-7-days entries
- `JournalEntry` properties: `.mood: MoodType`, `.thumbnailPath: String?`, `.aiNarrative: String?`, `.createdAt: Date`
- `ImagePipelineService.image(forRelativePath: entry.thumbnailPath)` — static call, returns `UIImage?`
- `MoodType.CaseIterable` — 6 cases: peaceful, nostalgic, happy, proud, sad, reflective — each has `.tint: Color`, `.title: String`
- `router.path.append(.memoryViewer(entryId: entry.id))` — navigate to full-screen viewer (Task 2 already done)
- Colors: `MemoryInkColors.parchment`, `.paper`, `.paperWarm`, `.ink`, `.secondaryInk`, `.tertiaryInk`, `.hairline`, `.amber`, `.sage`
- Typography: `MemoryInkTypography.eyebrow`, `.narrative`, `.narrativeCompact`, `.badge`, `.timestamp`, `.subtitle`

---

## New Design Layout

The view is a `ScrollView` (no navigation title — remove `.navigationTitle` and use a custom header). Structure from top to bottom:

### 1 — Hero Header Card

Full-width card with:
- Gradient background: `LinearGradient(colors: [dominantMood.tint.opacity(0.65), dominantMood.tint.opacity(0.18), MemoryInkColors.parchment], startPoint: .topLeading, endPoint: .bottomTrailing)`
- Top-left: "WEEKLY REFLECTION" in `MemoryInkTypography.eyebrow`
- Center: Week range label — format both ends of the 7-day window: `"May 14 – May 21"` using `.dateTime.month(.wide).day()` for start and `.day()` for end
- Bottom-left: Entry count badge — `"\(weekEntries.count) memories"` in `.badge` font, `.ultraThinMaterial` background, capsule-clipped
- Bottom-right: Dominant mood badge — `dominantMood.title` in `.badge` font, tinted with `dominantMood.tint.opacity(0.30)` background, `.ultraThinMaterial`, capsule-clipped
- Card height: `160`
- Corner radius: `MemoryInkSpacing.cardCornerRadius + 4`
- Overlay stroke: `MemoryInkColors.hairline.opacity(0.18)`
- Shadow: `dominantMood.tint.opacity(0.18)`, radius 24, y 12
- Padding: `.horizontal(22).vertical(22)` inside the card

When no entries this week: use `MemoryInkColors.secondaryInk` as dominantMood fallback (use a computed var that returns `.peaceful` if empty, so `.tint` still works).

### 2 — Memory Strip (horizontal scroll)

Only shown when `weekEntries.count > 0`. A `ScrollView(.horizontal, showsIndicators: false)` containing an `HStack(spacing: 10)` of thumbnail tiles. Show up to 7 entries.

Each tile:
- Size: `80 × 100` 
- Content: `ZStack` — photo via `ImagePipelineService.image(forRelativePath: entry.thumbnailPath)` scaled to fill, or `LinearGradient(colors: [entry.mood.tint, entry.mood.tint.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)` if no image
- Overlay: bottom scrim `LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)`
- Overlay bottom-left: entry day number `entry.createdAt.formatted(.dateTime.day())` in `.system(size: 11, weight: .bold)`, white, 6pt padding
- `.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`
- `.shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)`
- `onTapGesture`: `router.path.append(.memoryViewer(entryId: entry.id))`
- First tile has `.padding(.leading, 22)`, last has `.padding(.trailing, 22)`, others no extra padding

### 3 — Mood Distribution Bar

Only shown when `weekEntries.count > 0`. A `VStack(alignment: .leading, spacing: 10)` with:
- Section label: `"THIS WEEK'S MOOD"` in `.eyebrow`
- For each `MoodType.allCases` where count > 0: a horizontal bar row

Each bar row is an `HStack(spacing: 10)`:
- Mood title: fixed width `Text(mood.title)` in `.timestamp`, `foregroundStyle(.secondaryInk)`, `.frame(width: 80, alignment: .trailing)`
- Bar: `GeometryReader` → `RoundedRectangle(cornerRadius: 4)` with `mood.tint`, height 8, width = `max(8, proxy.size.width * fraction)` where `fraction = Double(count) / Double(weekEntries.count)`. Animate the bar appearing: use `@State private var barsVisible = false` set to `true` in `.onAppear`, animate with `.animation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.08), value: barsVisible)`. Width multiplied by `barsVisible ? 1.0 : 0.0`.
- Count: `Text("\(count)")` in `.timestamp`, `.tertiaryInk`, after the bar
- `GeometryReader` for the bar should have `.frame(height: 8)`

Wrap the whole bar chart in `.padding(.horizontal, 22)`.

Sort mood rows by count descending. Skip moods with count == 0.

### 4 — AI Recap Card

Shown when `recapService.latestRecap != nil`. A styled card:

```
ZStack(alignment: .topLeading) {
    // warm gradient background
    LinearGradient(
        colors: [MemoryInkColors.paper, MemoryInkColors.paperWarm],
        startPoint: .top,
        endPoint: .bottomTrailing
    )
    
    // decorative corner mark
    Text("✦")
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(MemoryInkColors.tertiaryInk.opacity(0.50))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(18)
    
    VStack(alignment: .leading, spacing: 16) {
        // amber accent bar + label
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MemoryInkColors.amber)
                .frame(width: 3, height: 18)
            Text("Your Week")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
        }
        
        // recap text
        Text(recap.recap)
            .font(MemoryInkTypography.narrative)
            .foregroundStyle(MemoryInkColors.ink)
            .lineSpacing(7)
            .fixedSize(horizontal: false, vertical: true)
        
        // date
        Text("Week of \(recap.generatedAt.formatted(.dateTime.month(.wide).day()))")
            .font(MemoryInkTypography.timestamp)
            .foregroundStyle(MemoryInkColors.tertiaryInk)
        
        // cached badge if recap.cached == true
        if recap.cached {
            Text("From earlier this week")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk.opacity(0.60))
        }
    }
    .padding(22)
}
```

Card styling: `.clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous))`, overlay stroke `MemoryInkColors.hairline.opacity(0.22)` lineWidth 0.7, shadow `MemoryInkColors.amber.opacity(0.10)` radius 20 y 10.

Padding: `.horizontal(22)`.

### 5 — Empty / Loading / Error States

When `recapService.latestRecap == nil`:
- If `isGenerating`:
  - Show a pulsing placeholder card instead of the recap card:
    ```
    RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius + 4, style: .continuous)
        .fill(MemoryInkColors.paper.opacity(0.60))
        .frame(height: 160)
        .overlay {
            VStack(spacing: 10) {
                ProgressView()
                    .tint(MemoryInkColors.amber)
                Text("Writing your reflection...")
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
            }
        }
    ```
  - Padding `.horizontal(22)`

- If `recapService.errorMessage != nil` (and not generating): use the existing `EmptyStateView(message: errorMessage, actionLabel: "Try again", isActionDisabled: false)` with the retry action

- If neither (no recap, no error, not generating): use `EmptyStateView(message: "Your weekly recap will appear when there's enough to reflect on.")`

### 6 — Generate Button

Shown when `recapService.latestRecap == nil && !isGenerating`. Place at bottom of scroll content:

```swift
Button {
    Task { await generateRecap() }
} label: {
    HStack(spacing: 8) {
        Image(systemName: "sparkles")
            .font(.system(size: 14, weight: .medium))
        Text("Reflect on this week")
            .font(MemoryInkTypography.narrativeCompact.weight(.semibold))
    }
    .foregroundStyle(MemoryInkColors.ink)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(
        LinearGradient(
            colors: [MemoryInkColors.amber.opacity(0.18), MemoryInkColors.amber.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(MemoryInkColors.amber.opacity(0.35), lineWidth: 0.8)
    }
}
.buttonStyle(.plain)
.padding(.horizontal, 22)
```

---

## State Variables

```swift
@State private var isGenerating = false
@State private var barsVisible = false
```

---

## Computed Properties

```swift
private var weekEntries: [JournalEntry] {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    return repository.entriesSince(weekAgo)
}

private var dominantMood: MoodType {
    let counts = Dictionary(grouping: weekEntries, by: \.mood).mapValues(\.count)
    return counts.max(by: { $0.value < $1.value })?.key ?? .peaceful
}

private var moodCounts: [(mood: MoodType, count: Int)] {
    let counts = Dictionary(grouping: weekEntries, by: \.mood).mapValues(\.count)
    return MoodType.allCases
        .compactMap { mood in
            let count = counts[mood, default: 0]
            return count > 0 ? (mood: mood, count: count) : nil
        }
        .sorted { $0.count > $1.count }
}
```

---

## View Assembly

```swift
var body: some View {
    ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 22) {
            heroHeader
                .padding(.horizontal, 22)
            
            if !weekEntries.isEmpty {
                memoryStrip  // full-bleed horizontal scroll, no horizontal padding
            }
            
            if !weekEntries.isEmpty {
                moodDistributionBars
            }
            
            if let recap = recapService.latestRecap {
                recapCard(recap)
            } else if isGenerating {
                loadingCard
                    .padding(.horizontal, 22)
            } else if let error = recapService.errorMessage {
                EmptyStateView(
                    message: error,
                    actionLabel: "Try again",
                    isActionDisabled: false
                ) {
                    Task { await generateRecap() }
                }
                .padding(.horizontal, 22)
            } else {
                EmptyStateView(
                    message: "Your weekly recap will appear when there's enough to reflect on."
                )
                .padding(.horizontal, 22)
            }
            
            if recapService.latestRecap == nil && !isGenerating {
                generateButton
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 48)
    }
    .background(MemoryInkColors.parchment.ignoresSafeArea())
    .navigationTitle("Weekly Recap")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            barsVisible = true
        }
    }
    .task {
        analyticsService.track(.recapOpened)
    }
}
```

---

## Constraints

- [ ] No new Swift Package
- [ ] No CoreData schema changes
- [ ] No new service methods — only use what already exists
- [ ] Keep `generateRecap()` private func unchanged
- [ ] Keep `analyticsService.track(.recapOpened)` in `.task`
- [ ] `navigationTitle("Weekly Recap")` kept (inline display mode)
- [ ] `@EnvironmentObject private var router: AppRouter` added (needed for thumbnail taps)

---

## Success Criteria

- [ ] Hero card shows correct week date range, entry count, dominant mood
- [ ] Memory strip shows up to 7 thumbnails, tappable → MemoryViewerView
- [ ] Mood bars animate in on appear, sorted by frequency
- [ ] AI recap card renders with amber accent bar and narrative text
- [ ] "Reflect on this week" button triggers generation
- [ ] Loading state shows spinner card during generation
- [ ] Xcode compiles without errors

Save report to `tasks/summary.md`.
