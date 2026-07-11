# Task: App Store Rejection Fix — Guideline 5.1.1(v) Registration Gate

**Date:** 2026-05-27
**Phase:** Phase 3 — Monetization & Sync
**Priority:** Critical (blocking App Store submission)
**Submission ID:** 75d79484-537e-4e04-864e-eec18557e4c9
**Scope:** 1 file, ~6 surgical changes

---

## Context

Apple rejected build 1.0 (3) on an iPad Air 11-inch (M3) citing Guideline 5.1.1(v):

> "The app requires users to register with personal information to purchase In-App Purchase products that are not account-based."

The reviewer tapped "Start" on a subscription plan and was blocked by an alert:
**"Please create an account or sign in before subscribing to MemoryInk+."**
The StoreKit purchase sheet never appeared.

---

## Root Cause

In `MemoryInk/Features/Subscription/SubscriptionView.swift`, the `planCard` function checks
`isSignedIn` before allowing a purchase. If the user is not signed in, it fires `showAuthAlert = true`
and returns — the purchase never reaches StoreKit.

```swift
// Current (violating) code — planCard action closure:
Button {
    guard !isDisabled else { return }
    guard isSignedIn else { showAuthAlert = true; return }   // ← hard block
    Task { await subscriptionManager.purchase(plan) }
} label: { ... }
```

MemoryInk+ includes features that have no account requirement (more AI narratives per day,
premium recap styles, voice journaling). Only metadata sync requires a Supabase account.
Apple's rule: registration cannot gate the entire purchase even if one feature is account-based.

---

## Objective

Any user — signed in or not — can reach the StoreKit payment sheet.
After a successful purchase, a non-signed-in user sees a one-tap-dismissible prompt
explaining they can sign in later to enable sync. Registration is never a blocker.

---

## Files to Modify

| File | Action |
|------|--------|
| `MemoryInk/Features/Subscription/SubscriptionView.swift` | See exact changes below |

**Do NOT touch:** any other file. No pricing changes. No entitlement ID changes. No paywall trigger changes. No CoreData changes.

---

## Exact Changes to `SubscriptionView.swift`

### Change 1 — Remove `showAuthAlert` state property

**Remove** this line (currently near line 9):
```swift
@State private var showAuthAlert = false
```

### Change 2 — Remove `isSignedIn` computed property

**Remove** this entire computed property (currently lines 13–16):
```swift
private var isSignedIn: Bool {
    if case .signedIn = authService.state { return true }
    return false
}
```

### Change 3 — Add new state property for post-purchase prompt

**Add** this line alongside the remaining `@State` declarations at the top of the struct:
```swift
@State private var showPostPurchaseSyncPrompt = false
```

### Change 4 — Remove the "Sign in required" alert modifier

**Remove** this entire `.alert` block from `body` (currently lines 43–47):
```swift
.alert("Sign in required", isPresented: $showAuthAlert) {
    Button("OK", role: .cancel) {}
} message: {
    Text("Please create an account or sign in before subscribing to MemoryInk+.")
}
```

### Change 5 — Add post-purchase sync prompt alert

**Add** this new `.alert` modifier in the same position in `body` (after `.task { ... }`):
```swift
.alert("Sync Available", isPresented: $showPostPurchaseSyncPrompt) {
    Button("Got it", role: .cancel) {}
} message: {
    Text("Sign in from Settings anytime to sync your memories across your devices.")
}
```

### Change 6 — Remove the sign-in gate from `planCard`

**Replace** the current `planCard` button action closure:

Current:
```swift
Button {
    guard !isDisabled else { return }
    guard isSignedIn else { showAuthAlert = true; return }
    Task { await subscriptionManager.purchase(plan) }
} label: {
```

Replace with:
```swift
Button {
    guard !isDisabled else { return }
    Task {
        let wasSubscribed = subscriptionManager.hasPremiumEntitlement
        await subscriptionManager.purchase(plan)
        guard !wasSubscribed, subscriptionManager.hasPremiumEntitlement else { return }
        if case .signedIn = authService.state { return }
        showPostPurchaseSyncPrompt = true
    }
} label: {
```

**Logic explanation:**
- `wasSubscribed` captures entitlement state before the purchase attempt.
- After `purchase()` returns, if the user was NOT subscribed before AND IS subscribed now, the purchase succeeded.
- If they are also not signed in, show the optional sync prompt.
- If the purchase was cancelled or failed, `hasPremiumEntitlement` stays false → no prompt, no state change.

---

## Constraints

- [ ] No new Swift packages
- [ ] No changes to pricing ($5.99, $39.99)
- [ ] No changes to entitlement ID (`"premium"`)
- [ ] Paywall trigger logic (first emotional moment) untouched
- [ ] `isSubscribed` display logic (header badge, plan cards, feature list) untouched
- [ ] The `authService` `@EnvironmentObject` stays — it is still used for the post-purchase state check
- [ ] No raw photo, GPS, or EXIF data sent anywhere

---

## Success Criteria

- [ ] A user who has never created an account can tap "Start" on either plan and the native StoreKit purchase sheet appears immediately — no alert, no redirect, no block
- [ ] After a successful purchase by a non-signed-in user, a dismissible alert appears: "Sign in from Settings anytime to sync your memories across your devices."
- [ ] Tapping "Got it" (or swiping away) dismisses the alert and the user has full access to premium features without signing in
- [ ] A user who is already signed in sees no post-purchase prompt (purchase proceeds silently as before)
- [ ] If the purchase is cancelled or fails, no post-purchase prompt appears
- [ ] Xcode compiles without errors or warnings introduced by these changes
- [ ] No files modified beyond `SubscriptionView.swift`

---

## Out of Scope

- Sign-in UX in SettingsView (already correct — sync is gated behind sign-in there)
- RevenueCatService purchase flow (no auth dependency, already correct)
- Supabase configuration changes (PM/user action)
- Any CoreData or data model changes
