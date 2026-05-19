# Supabase Setup

MemoryInk must continue to build and run without Supabase configuration. When configuration is missing, account and sync surfaces should stay calm and local-first.

## Required Info.plist Keys

- `SupabaseURL`
- `SupabaseAnonKey`

Use the project target's build settings or the app Info.plist to provide these values. Do not commit production secrets.

## Required Tables

### `journal_entries`

- `id` UUID primary key
- `user_id` UUID/Text matching the Supabase Auth user id
- `created_at` timestamp
- `updated_at` timestamp
- `deleted_at` timestamp nullable
- `raw_note` text nullable
- `mood` text
- `narrative_style` text
- `ai_narrative` text nullable
- `ai_generation_date` timestamp nullable
- `is_favorite` boolean
- `sync_status` text
- `local_photo_exists` boolean
- `local_voice_exists` boolean

### `ai_usage_daily`

- `user_id`
- `date`
- `narrative_count`
- `recap_count`

## RLS Policies

Enable Row Level Security. At a high level:

- Users may select, insert, update, and soft-delete only rows where `user_id` matches `auth.uid()`.
- Do not allow anonymous access to another user's rows.
- Use soft deletion with `deleted_at`; stale updates must not restore deleted rows.
- Keep `updated_at` current for last-write-wins conflict resolution.

## Auth Providers

Needed later:

- Email + password account auth
- Sign in with Apple
- Google Sign-In

V1 does not require email verification. Configure Supabase Auth accordingly before production testing.

## Metadata-Only Sync Rule

Supabase is a mirror for memory metadata only. Core Data remains the source of truth on the current device.

Never upload or store:

- Original photos
- Thumbnails
- Medium previews
- Local photo paths
- EXIF metadata
- GPS data
- Voice files
- Local voice paths
- Image blobs

Photos and voice files never leave the device.
