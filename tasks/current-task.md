# Task: UI Polish Sprint — Timeline & Settings

**Date:** 2026-05-21
**Phase:** V1.1 Polish
**Priority:** High
**Estimated scope:** Medium (4 files)

---

## Context

Screenshots of the live app reveal four clear visual gaps:

1. **Timeline header wastes space** — "Private timeline" eyebrow is redundant with the app title. No sense of the user's journaling momentum (streak, memory count) is shown near the title. The "MemoryInk+" upgrade prompt is invisible plain text.
2. **Grid cards are bare** — no date stamp, so every card is anonymous. The mood badge looks dark/gray because the tint opacity is too low.
3. **Settings feels flat and cold** — section cards have no warmth gradient. Auth status says "Sync unavailable: configuration missing" — developer jargon the user should never see. The plan value ("Free") is just plain text with no visual weight.
4. **No journaling streak** — there is no feedback loop telling users they're building a habit.

---

## Objective

Polish the Timeline and Settings screens with targeted improvements. Add a journaling streak to the repository and surface it in the UI.

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/Persistence/JournalEntryRepository.swift` | modify | Add `currentStreak: Int` computed property |
| `MemoryInk/Features/Timeline/TimelineView.swift` | modify | Header cleanup, streak + count display, styled upgrade CTA |
| `MemoryInk/Features/Timeline/TimelineCard.swift` | modify | Date stamp on grid cards, stronger mood badge tint |
| `MemoryInk/Features/Settings/SettingsView.swift` | modify | Gradient card background, softer status text, plan badge |

---

## Implementation spec

### Step 1 — `JournalEntryRepository.swift`: add `currentStreak`

Add this computed property after the existing `entries` property:

```swift
var currentStreak: Int {
    guard !entries.isEmpty else { return 0 }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Unique journaling days, most-recent first
    let days = Array(
        Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
    ).sorted(by: >)

    guard let mostRecent = days.first else { return 0 }

    // Streak is 0 if the user didn't journal today or yesterday
    let gap = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
    guard gap <= 1 else { return 0 }

    var streak = 1
    for i in 0..<days.count - 1 {
        let diff = calendar.dateComponents([.day], from: days[i + 1], to: days[i]).day ?? 0
        if diff == 1 {
            streak += 1
        } else {
            break
        }
    }
    return streak
}
```

`JournalEntry.createdAt` is the existing CoreData `createdAt: Date` field. Do not change the schema.

---

### Step 2 — `TimelineView.swift`: header cleanup + streak + upgrade CTA

#### 2a — Remove the "Private timeline" eyebrow

Find this block in `header(isCompact:)`:

```swift
HStack {
    Text("Private timeline")
        .font(MemoryInkTypography.eyebrow)
        .foregroundStyle(MemoryInkColors.tertiaryInk)
        .textCase(.uppercase)

    Spacer()

    Button { ... } // grid toggle
    Button { ... } // calendar
    Button { ... } // gear
    Button { ... } // search
}
```

Replace `Text("Private timeline")` + `Spacer()` with just a plain `Spacer()` — keep the icon buttons in the same `HStack`. The row becomes a right-aligned icon strip.

#### 2b — Add memory count + streak below the subtitle

Directly after:
```swift
Text("Small moments, held quietly.")
    .font(MemoryInkTypography.subtitle)
    .foregroundStyle(MemoryInkColors.secondaryInk)
```

Add:
```swift
if repository.entries.count >= 1 {
    HStack(spacing: 8) {
        let count = repository.entries.count
        Text("\(count) \(count == 1 ? "memory" : "memories")")
            .font(MemoryInkTypography.timestamp)
            .foregroundStyle(MemoryInkColors.tertiaryInk)

        let streak = repository.currentStreak
        if streak >= 2 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("\(streak)-day streak")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
            }
            .foregroundStyle(MemoryInkColors.amber)
        }
    }
    .padding(.top, 3)
}
```

#### 2c — Replace plain "MemoryInk+" text with a styled upgrade capsule

Find and replace:
```swift
if subscriptionManager.isPaywallEligible && !subscriptionManager.hasPremiumEntitlement {
    Button("MemoryInk+") {
        router.path.append(.subscription)
    }
    .font(MemoryInkTypography.timestamp.weight(.medium))
    .foregroundStyle(MemoryInkColors.tertiaryInk)
    .buttonStyle(.plain)
    .padding(.top, 2)
}
```

With:
```swift
if subscriptionManager.isPaywallEligible && !subscriptionManager.hasPremiumEntitlement {
    Button {
        router.path.append(.subscription)
    } label: {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
            Text("Go Premium")
                .font(MemoryInkTypography.timestamp.weight(.semibold))
        }
        .foregroundStyle(MemoryInkColors.ink)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.sunlit.opacity(0.42),
                    MemoryInkColors.amber.opacity(0.30)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(MemoryInkColors.amber.opacity(0.24), lineWidth: 0.8)
        }
    }
    .buttonStyle(.plain)
    .padding(.top, 4)
}
```

---

### Step 3 — `TimelineCard.swift`: grid card date stamp + mood badge

#### 3a — Date stamp on grid cards

In `gridBody`, add a `.overlay(alignment: .bottomLeading)` for the date stamp, alongside the existing `.overlay(alignment: .bottomTrailing)` for the favorite badge:

```swift
private var gridBody: some View {
    imageArea
        .overlay(alignment: .bottomLeading) {
            dateStamp
                .padding(10)
        }
        .overlay(alignment: .bottomTrailing) {
            if memory.isFavorite {
                favoriteBadge
                    .padding(10)
            }
        }
        .shadow(...)
        .contentShape(...)
        .onTapGesture { ... }
        .accessibilityElement(...)
        .accessibilityLabel(...)
}
```

Add this private computed property:

```swift
private var dateStamp: some View {
    VStack(alignment: .center, spacing: -1) {
        Text(memory.timestamp.formatted(.dateTime.day()))
            .font(.system(size: 17, weight: .bold, design: .default))
        Text(memory.timestamp.formatted(.dateTime.month(.abbreviated)).uppercased())
            .font(.system(size: 9, weight: .semibold))
            .kerning(0.5)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 9)
    .padding(.vertical, 7)
    .background(.ultraThinMaterial)
    .background(memory.mood.tint.opacity(0.22))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
}
```

#### 3b — Stronger mood badge tint

In `moodBadge`, change `memory.mood.tint.opacity(0.12)` to `memory.mood.tint.opacity(0.28)`:

```swift
// Before:
.background(memory.mood.tint.opacity(0.12))

// After:
.background(memory.mood.tint.opacity(0.28))
```

No other changes to `moodBadge`.

---

### Step 4 — `SettingsView.swift`: warmth + softer status text + plan badge

#### 4a — Gradient on section cards

In the `section(_:content:)` helper, change the card background fill from:
```swift
.fill(MemoryInkColors.paper.opacity(0.88))
```
to:
```swift
.fill(
    LinearGradient(
        colors: [
            MemoryInkColors.paper.opacity(0.92),
            MemoryInkColors.paperWarm.opacity(0.80)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
```

#### 4b — Soften raw config error text

In `accountStatusText`, change:
```swift
case .unavailableMissingConfig:
    return "Sync unavailable: configuration missing"
```
to:
```swift
case .unavailableMissingConfig:
    return "Offline mode"
```

In `syncDescription`, change:
```swift
case .notConfigured:
    return "Sync unavailable: configuration missing"
```
to:
```swift
case .notConfigured:
    return "Local only"
```

#### 4c — Plan badge in Subscription section

Replace:
```swift
infoRow("Plan", subscriptionManager.plan.title, icon: "sparkles")
```
with:
```swift
HStack(spacing: 10) {
    Image(systemName: "sparkles")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(MemoryInkColors.tertiaryInk)
        .frame(width: 22, height: 22)
        .background(MemoryInkColors.parchment.opacity(0.70))
        .clipShape(Circle())

    Text("Plan")
        .font(MemoryInkTypography.narrativeCompact)
        .foregroundStyle(MemoryInkColors.secondaryInk)

    Spacer()

    Text(subscriptionManager.plan.title)
        .font(MemoryInkTypography.timestamp.weight(.semibold))
        .foregroundStyle(subscriptionManager.hasPremiumEntitlement ? MemoryInkColors.amber : MemoryInkColors.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            subscriptionManager.hasPremiumEntitlement
                ? MemoryInkColors.sunlit.opacity(0.28)
                : MemoryInkColors.parchment.opacity(0.60)
        )
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(
                    subscriptionManager.hasPremiumEntitlement
                        ? MemoryInkColors.amber.opacity(0.24)
                        : MemoryInkColors.hairline.opacity(0.22),
                    lineWidth: 0.7
                )
        }
}
```

---

## Constraints

- [ ] No new Swift Package
- [ ] No CoreData schema changes — `currentStreak` is a computed property on the existing `entries` array
- [ ] No subscription pricing, entitlement ID, or product ID changes
- [ ] No photo data sent anywhere
- [ ] Do not change the Apple Sign In button color — it must stay black per Apple HIG
- [ ] `currentStreak` only counts unique calendar days — one entry per day counts as 1

## Success criteria

- [ ] "Private timeline" eyebrow text is gone from the header
- [ ] Memory count ("N memories") appears below the subtitle
- [ ] A flame icon + "N-day streak" appears in amber when streak ≥ 2
- [ ] "Go Premium" capsule with amber gradient replaces the plain "MemoryInk+" text
- [ ] Grid cards show a date stamp (day number + month abbreviation) in bottom-left
- [ ] Mood badge background tint is visibly more colorful (0.28 opacity)
- [ ] Settings section cards have a warm gradient background
- [ ] "Sync unavailable: configuration missing" is never shown — replaced by "Offline mode" / "Local only"
- [ ] Plan row in Settings shows "Free" or "Monthly"/"Yearly" as a styled capsule badge
- [ ] Xcode compiles without errors
