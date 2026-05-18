# Phase 3 Services Setup

MemoryInk must remain buildable and useful without external service credentials. All Phase 3 service integrations are currently isolated behind native placeholder layers.

## Required Config Keys

- `MemoryInkRevenueCatAPIKey`
- `MemoryInkSupabaseURL`
- `MemoryInkSupabaseAnonKey`
- `MemoryInkMixpanelToken`
- Google Sign-In client ID configuration, once the Google Sign-In SDK is approved
- Apple Developer Sign in with Apple capability, once account setup is complete

## RevenueCat

- Entitlement ID: `premium`
- Product IDs:
  - `memoryink_monthly`
  - `memoryink_yearly`
- Trial policy: 7-day free trial

The app uses one V1 entitlement: `premium`.

## Supabase Sync Boundary

Supabase sync is metadata-only. Never sync or upload:

- Original photos
- Thumbnails
- Medium previews
- EXIF metadata
- GPS coordinates
- Voice files

Core Data remains the source of truth. Supabase is only a premium metadata mirror.

## Auth

Supported V1 account options:

- Sign in with Apple
- Google Sign-In
- Simple email account

Email validation is format-only: `____@____.____`. V1 does not require email verification.

## Mixpanel

Approved event names only:

- `first_entry_created`
- `first_narrative_generated`
- `first_recap_opened`
- `entries_per_week`
- `on_this_day_opened`
- `recap_opened`
- `timeline_session_started`
- `paywall_shown`
- `trial_started`
- `monthly_converted`
- `yearly_converted`

Never track raw memory contents, photo data, voice content, or private reflections.
