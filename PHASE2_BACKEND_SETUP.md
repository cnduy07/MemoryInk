# Phase 2 Backend Setup

MemoryInk must continue to build and run without backend configuration. When the AI backend is not configured, local save behavior remains intact and narratives stay in a pending local state.

## Required Info.plist Keys

- `MemoryInkAIBaseURL`
- `MemoryInkAIAPIKey`

## Required Endpoints

- `POST /v1/narratives/generate`
- `POST /v1/recaps/generate`

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
- `NETWORK_UNAVAILABLE`
- `AI_TIMEOUT`
- `VALIDATION_FAILED`
- `SERVICE_UNAVAILABLE`
