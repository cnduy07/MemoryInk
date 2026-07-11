# Task: Delete Account Reliably via Edge Function

**Phase:** Phase 3 — Monetization & Sync  
**Priority:** High  
**Scope:** Client account UI, authentication service, and one Supabase Edge Function

---

## Context

The Supabase GoTrue `DELETE /auth/v1/user` endpoint does not delete the current
user from the iOS client. Account deletion must go through an authenticated Edge
Function that verifies the caller and performs the admin deletion server-side.

Deletion must only be reported as successful after the server confirms it. A
network, authorization, configuration, or server failure must preserve the local
session so the user can retry.

---

## Files

| File | Action |
|------|--------|
| `supabase/functions/delete-account/index.ts` | Create the authenticated deletion endpoint |
| `MemoryInk/Services/AuthService.swift` | Call the endpoint and preserve the session on failure |
| `MemoryInk/Features/Settings/SettingsView.swift` | Confirm deletion and show success or failure feedback |

---

## Required behavior

### Edge Function

- Accept `DELETE` and `OPTIONS` only; return `405` for other methods.
- Require an `Authorization` header.
- Require `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_SERVICE_ROLE_KEY` from server-side environment variables.
- Verify the caller through `/auth/v1/user` using the caller's bearer token.
- Delete only that verified user through `/auth/v1/admin/users/{user_id}`.
- Never return or log tokens, keys, response bodies, or user data.
- Return `{ "success": true }` only after the admin deletion succeeds.

### iOS client

- Send `DELETE functions/v1/delete-account` with the current access token.
- Clear the stored session only after a `2xx` response.
- Preserve the signed-in session for transport, authorization, and server
  failures.
- Show `Couldn't delete account. Try again.` on failure.
- Show `Account deleted.` after confirmed deletion.
- Keep journal entries stored locally on the device.

---

## Constraints

- No new dependency.
- No production deployment or API call without explicit approval.
- Never expose the service-role key to the app.
- Do not delete local memories, photos, thumbnails, previews, or voice files.
- Do not change authentication providers or subscription behavior.

---

## Success criteria

- Non-`DELETE` requests receive `405`.
- Missing or invalid authorization receives `401`.
- Missing server configuration or admin deletion failure receives `500`.
- Client failures keep the user signed in and show retry feedback.
- Confirmed deletion clears the local session and shows success feedback.
- The iOS Simulator build completes without errors.
- No production endpoint is called during verification.
