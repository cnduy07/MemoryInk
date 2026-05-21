# Task: Phase 3 Integration Completion — Auto-Sync + Paywall Sheet

**Date:** 2026-05-21
**Phase:** Phase 3 — Monetization & Sync
**Priority:** Critical
**Estimated scope:** Small (3 files)

---

## Context

All 12 V1.1 feature tasks are complete. The Phase 3 services (RevenueCat, AuthService, SyncService, SubscriptionManager) are all implemented and wired in `MemoryInkApp`. However, three integration gaps remain before the app behaves correctly end-to-end:

1. **Sync never fires automatically.** `syncService.syncMetadataIfAllowed()` is only reachable via a manual button in Settings. Premium users' data is never synced on launch or after saving a new memory — the sync infrastructure exists but is never triggered.

2. **Paywall only appears as a tiny header button.** When `subscriptionManager.isPaywallEligible` becomes true (after first AI narrative), a small "MemoryInk+" text button appears in the timeline header. The product spec requires the paywall to *automatically* appear as a full sheet the first time the user becomes eligible — not wait for them to notice and tap a button.

3. **SubscriptionView has no close button.** When presented as a sheet, users must rely on swipe-to-dismiss. A close button is required for clarity and accessibility.

---

## Objective

Wire sync to fire automatically (on launch + on foreground return + after new memory saved). Auto-present `SubscriptionView` as a sheet the first time `isPaywallEligible` becomes true. Add a close button to `SubscriptionView`.

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/App/MemoryInkApp.swift` | modify | Trigger sync on launch and on app foreground |
| `MemoryInk/Features/Timeline/TimelineView.swift` | modify | Auto-present paywall sheet on first eligibility; trigger sync when entry count changes |
| `MemoryInk/Features/Subscription/SubscriptionView.swift` | modify | Add close/dismiss toolbar button |

---

## Implementation spec

### Step 1 — `MemoryInkApp.swift`: sync on launch + on foreground

**Launch sync:** In the existing `.task` block, after `subscriptionManager.refreshEntitlements()`, add:

```swift
await syncService.syncMetadataIfAllowed()
```

**Foreground sync:** In the `WindowGroup` body, add `@Environment(\.scenePhase) private var scenePhase` to the `App` struct and add:

```swift
.onChange(of: scenePhase) { phase in
    if phase == .active {
        Task { await syncService.syncMetadataIfAllowed() }
    }
}
```

Place the `.onChange` on the `Group` inside `WindowGroup`, alongside the existing `.environmentObject(...)` modifiers.

The full `.task` block after changes:

```swift
.task {
    await authService.restoreSession()
    await subscriptionManager.refreshEntitlements()
    await syncService.syncMetadataIfAllowed()
    onThisDayService.refresh()
    await notificationService.scheduleOnThisDayIfNeeded(entryCount: onThisDayService.entries.count)
}
```

---

### Step 2 — `TimelineView.swift`: auto-present paywall sheet + post-save sync

**Paywall sheet auto-present:**

Add two new state properties near the top of `TimelineView`:

```swift
@AppStorage("paywall_auto_shown") private var paywallAutoShown: Bool = false
@State private var showingPaywall: Bool = false
```

Add this `.onChange` modifier to the root view of `TimelineView` (on the `NavigationStack` or its outermost container):

```swift
.onChange(of: subscriptionManager.isPaywallEligible) { eligible in
    if eligible && !subscriptionManager.hasPremiumEntitlement && !paywallAutoShown {
        paywallAutoShown = true
        showingPaywall = true
    }
}
```

Add this `.sheet` modifier to the same root view:

```swift
.sheet(isPresented: $showingPaywall) {
    NavigationStack {
        SubscriptionView()
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
}
```

**Do not remove** the existing "MemoryInk+" header button — it remains as an upgrade reminder for users who dismiss the sheet without subscribing.

**Post-save sync:** Add `.onChange(of: repository.entries.count)` to the root view of `TimelineView`:

```swift
.onChange(of: repository.entries.count) { _ in
    Task { await syncService.syncMetadataIfAllowed() }
}
```

`syncService` is already available as `@EnvironmentObject private var syncService: SyncService` — confirm it is declared in `TimelineView`; add it if missing.

---

### Step 3 — `SubscriptionView.swift`: add close button

`SubscriptionView` uses `.navigationTitle("MemoryInk+")`. Add a dismiss button to its toolbar so it works correctly whether accessed via navigation push or sheet presentation:

```swift
@Environment(\.dismiss) private var dismiss
```

Add to the `body`'s modifier chain:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Close") {
            dismiss()
        }
        .font(MemoryInkTypography.timestamp.weight(.medium))
        .foregroundStyle(MemoryInkColors.secondaryInk)
    }
}
```

---

## Constraints

- [ ] No new Swift Package
- [ ] No CoreData schema changes
- [ ] `syncMetadataIfAllowed()` is already guarded — free users, signed-out users, and unconfigured Supabase will all short-circuit silently. Do not add redundant guards.
- [ ] Paywall sheet auto-presents only once ever (`paywallAutoShown` gate). After that, only the header button triggers it.
- [ ] `paywallAutoShown` uses `@AppStorage` — persists across launches.
- [ ] Do NOT change subscription pricing, entitlement IDs, or product IDs.

---

## Success criteria

- [ ] App launch calls `syncMetadataIfAllowed()` after entitlements refresh
- [ ] Returning to foreground calls `syncMetadataIfAllowed()`
- [ ] Saving a new memory calls `syncMetadataIfAllowed()`
- [ ] When first AI narrative generates and `isPaywallEligible` becomes true, `SubscriptionView` appears automatically as a sheet (not navigation push) — exactly once, ever
- [ ] `SubscriptionView` has a "Close" button in the top-right toolbar corner
- [ ] Existing "MemoryInk+" header button still works for subsequent accesses
- [ ] Xcode compiles without errors

---

## Out of scope

- Sync on every CoreData save (too frequent; entry count change is sufficient)
- Paywall A/B testing
- Push notifications for sync status
