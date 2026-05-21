# Phase 2 Backend Setup

MemoryInk must continue to build and run without backend configuration. When the AI backend is not configured, local save behavior remains intact and narratives stay in a pending local state.

## Required Info.plist Keys

- `MemoryInkAIBaseURL`
- `MemoryInkAIAPIKey`

## Required Supabase Secrets

- `OPENAI_API_KEY`
- `AI_MODEL` optional, defaults to `gpt-4o-mini`
- `MEMORYINK_AI_API_KEY` optional shared client key. If set, iOS `MemoryInkAIAPIKey` must match it.

## Required Endpoints

- `POST /v1/narratives/generate`
- `POST /v1/recaps/generate`

## Supabase Edge Function URLs

Supabase Edge Functions are deployed by function slug, not by arbitrary nested `/v1/...` routes. The deployed URLs are:

- `https://<project-ref>.functions.supabase.co/narratives-generate`
- `https://<project-ref>.functions.supabase.co/recaps-generate`

For local Supabase development:

- `http://127.0.0.1:54321/functions/v1/narratives-generate`
- `http://127.0.0.1:54321/functions/v1/recaps-generate`

Set `MemoryInkAIBaseURL` to the Edge Functions base URL:

- hosted: `https://<project-ref>.functions.supabase.co`
- local: `http://127.0.0.1:54321/functions/v1`

The iOS app maps this base URL to the correct function slug. If a future gateway directly exposes the approved contract routes, `MemoryInkAIBaseURL` can instead point to that gateway base and the app will call `/v1/narratives/generate` and `/v1/recaps/generate`.

## Privacy Boundary

Never upload photos, thumbnails, medium previews, EXIF metadata, GPS data, or voice files.

The AI backend may receive text and lightweight metadata only.

## Narrative Request Payload

Expected fields:

```json
{
  "entry_id": "uuid",
  "scene_labels": ["coffee", "friends", "sunset"],
  "mood": "nostalgic",
  "note": "Quiet evening with old friends",
  "narrative_style": "warm",
  "locale": "en"
}
```

## Narrative Success Response

```json
{
  "success": true,
  "data": {
    "narrative": "A quiet evening with old friends, softened by the last light of sunset.",
    "generated_at": "2026-05-18T10:00:00Z",
    "model": "gpt-4o-mini",
    "cached": false
  }
}
```

## Error Response

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_REACHED",
    "message": "You've reached today's AI limit."
  }
}
```

Supported error codes:

- `RATE_LIMIT_REACHED`
- `INVALID_REQUEST`
- `UNAUTHORIZED`
- `AI_PROVIDER_ERROR`
- `INTERNAL_ERROR`
