# MemoryInk — Production Blueprint
> VERSION: V8 | PLATFORM: iOS 16+ | OPTIMIZED FOR: AI-assisted engineering

---

## ⚡ ACTIVE PHASE

**Phase 3 — Monetization & Sync**

| Status | Scope |
|--------|-------|
| ✅ IN SCOPE | RevenueCat, subscription state, paywall, 7-day free trial configuration placeholder, premium entitlement check, Supabase metadata-only sync, auth, Mixpanel analytics, onboarding polish, sync conflict handling |
| ❌ OUT OF SCOPE | CloudKit, photo sync, voice sync, realtime collaboration, social features, AI chat, embeddings, vector search, raw media upload |

> Agent must not build anything outside active phase scope without explicit approval.
> To change the active phase, the human must update this section.

---

## DECISION LOG

| Topic | Decision | Status |
|-------|----------|--------|
| iOS minimum | iOS 16+ | ✅ Decided |
| Architecture | MVVM + feature folders | ✅ Decided |
| Navigation | NavigationStack, path-based, AppRouter | ✅ Decided |
| Local persistence | Core Data, file paths only (no blobs) | ✅ Decided |
| Image storage directories | /Documents/originals, /thumbnails, /medium, /voice | ✅ Decided |
| AI model | GPT-4o mini via Supabase Edge Function proxy | ✅ Decided |
| Subscription platform | RevenueCat | ✅ Decided |
| Analytics | Mixpanel, snake_case event names | ✅ Decided |
| CloudKit sync | Not used in V1, deferred to future phase | ✅ Decided |
| Photo upload policy | Photos never leave the device | ✅ Decided |
| Supabase in Phase 0–1 | No Supabase calls whatsoever | ✅ Decided |
| Bundle identifier | com.memoryink.app | ✅ Decided |
| Xcode project name | MemoryInk | ✅ Decided |
| Onboarding screens | 3 screens: Welcome, Privacy, Mood intro | ✅ Decided |
| Design tokens | Use values defined in Section 11 until overridden | ✅ Decided |
| Paywall copy | Use copy defined in Section 16 until overridden | ✅ Decided |
| App icon / brand assets | Provided by human | ✅ Decided |
| AI proxy API contract | Defined in Section 18A | ✅ Decided |
| Supabase schema | Defined in Section 18B | ✅ Decided |
| RevenueCat entitlement IDs | premium entitlement with monthly/yearly products; defined in Section 18C | ✅ Decided |

> Agent: if a task requires anything marked ⏳ Needs input, stop and ask the human before proceeding.

---

## 1. PRODUCT THESIS

MemoryInk is:
> A calm emotional memory product powered subtly by AI.

It transforms photos, voice memos, notes, and emotional reflections into meaningful narratives, emotional recaps, and cinematic timelines.

**MemoryInk is NOT:** a productivity app, second-brain, AI assistant, social network, chat app, or AI workspace.

**The product succeeds through:** emotional atmosphere, visual quality, subtle AI, premium UX, calm interaction design.

**Not through:** feature quantity, AI complexity, or technical impressiveness.

---

## 2. PLATFORM & TECH STACK

### Target
- iOS 16+ minimum
- Must feel premium on: iPhone 11, iPhone SE 3, A13/A14 devices

### Frontend

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Architecture | MVVM |
| Navigation | NavigationStack |
| Persistence | Core Data |
| Async | Swift Concurrency (async/await) |
| Animations | Native SwiftUI |
| Haptics | UIKit feedback generators |
| Image Processing | Native image pipeline |

### Apple Frameworks

| Framework | Usage | Phase |
|-----------|-------|-------|
| Vision | Scene labeling for AI payload | Phase 2 |
| Speech | Voice transcription | Phase 1 |
| NaturalLanguage | Lightweight sentiment support | Phase 2 |
| BackgroundTasks | Recap generation | Phase 2 |
| StoreKit 2 | Subscriptions | Phase 3 |
| CloudKit | Future sync — DO NOT use in V1 | Future |

### Backend (Phase 2+)

| Layer | Technology |
|-------|------------|
| Backend | Supabase |
| Auth | Free users: no sign-in. Premium sync: Sign in with Apple, Google/Gmail, or email account |
| Database | PostgreSQL |
| AI Proxy | Supabase Edge Functions |
| Analytics | Mixpanel |
| Subscriptions | RevenueCat |

### AI
- Model: **GPT-4o mini**
- Rationale: low latency, affordable at scale, excellent short-form emotional writing quality

---

## 3. PROJECT STRUCTURE

```
MemoryInk/
├── App/
│   ├── MemoryInkApp.swift              # App entry point
│   └── AppRouter.swift                 # Centralized NavigationStack router
├── Features/
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── TimelineViewModel.swift
│   │   └── TimelineCard.swift          # Card component, 4:5 ratio
│   ├── MemoryCreation/
│   │   ├── MemoryCreationView.swift
│   │   ├── MemoryCreationViewModel.swift
│   │   └── MoodPickerView.swift
│   ├── MemoryDetail/
│   │   ├── MemoryDetailView.swift
│   │   └── MemoryDetailViewModel.swift
│   ├── Recap/
│   │   ├── RecapView.swift
│   │   └── RecapViewModel.swift
│   ├── OnThisDay/
│   │   ├── OnThisDayView.swift
│   │   └── OnThisDayViewModel.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   ├── Subscription/
│   │   └── SubscriptionView.swift
│   └── Onboarding/
│       ├── OnboardingView.swift
│       ├── PrivacyScreenView.swift     # REQUIRED: explain local-first storage
│       └── MoodIntroView.swift
├── Services/
│   ├── ImagePipelineService.swift      # Resize, compress, store images
│   ├── AIService.swift                 # GPT-4o mini proxy calls (Phase 2+)
│   ├── VoiceService.swift              # Speech recording + transcription
│   ├── NotificationService.swift       # Recap + On This Day notifications
│   └── SyncService.swift               # Supabase sync (Phase 3+ stub only)
├── Persistence/
│   ├── CoreDataStack.swift
│   ├── JournalEntryRepository.swift
│   └── MemoryInk.xcdatamodeld
├── Models/
│   ├── JournalEntry.swift
│   ├── MoodType.swift
│   ├── NarrativeStyle.swift
│   └── SyncStatus.swift
└── Common/
    ├── Extensions/
    ├── Components/                     # Shared UI components
    └── Theme/
        ├── Typography.swift
        ├── Colors.swift
        └── Spacing.swift
```

> Agent: all new files must be placed in the correct location within this structure. Do not create new top-level folders without approval.

---

## 4. NAVIGATION ARCHITECTURE

### Pattern
- Path-based navigation with `NavigationStack`
- Typed destinations via `AppRoute` enum
- Centralized `AppRouter` object

### Routes
```swift
enum AppRoute: Hashable {
    case timeline
    case memoryDetail(id: UUID)
    case recap
    case onThisDay
    case settings
    case subscription
}
```

### Avoid
❌ Deeply nested NavigationLink chains
❌ Singleton routers
❌ View-driven navigation explosion
❌ Sheet-heavy navigation that bypasses the router

---

## 5. DATA MODELS

### JournalEntry (Core Data entity)

```swift
struct JournalEntry {
    let id: UUID
    let createdAt: Date
    let photoPath: String           // path to original
    let thumbnailPath: String       // path to thumbnail (300–500px)
    let mediumPreviewPath: String   // path to medium preview (1200–1600px)
    let rawNote: String?
    let voicePath: String?
    let aiNarrative: String?
    let mood: MoodType
    let narrativeStyle: NarrativeStyle
    let syncStatus: SyncStatus
    let aiGenerationDate: Date?
    let isFavorite: Bool
}
```

### Enums

```swift
enum MoodType: String, CaseIterable {
    case peaceful, nostalgic, happy, proud, sad, reflective
}

enum NarrativeStyle: String, CaseIterable {
    case warm, minimal, reflective
}

enum SyncStatus: String {
    case pending, syncing, completed, failed
}
```

---

## 6. FILE STORAGE STRATEGY

### Rule
**Never store image blobs in Core Data.** Core Data stores file path strings only.

### Directory Structure
```
/Documents/
    /originals/     ← full resolution, never uploaded
    /thumbnails/    ← 300–500px, used in Timeline
    /medium/        ← 1200–1600px, used in Detail view
    /voice/         ← voice memo files
```

### Image Pipeline (generate 3 versions per image on save)
1. **Original** → `/originals/{uuid}.heif` (or .jpg fallback)
2. **Thumbnail** → `/thumbnails/{uuid}.jpg` — 300–500px width
3. **Medium preview** → `/medium/{uuid}.jpg` — 1200–1600px width

### Compression
- Prefer HEIF; fallback to optimized JPEG

### Timeline Rule
**Timeline NEVER renders full-resolution images.** Always use thumbnails.

### Memory Management
- Lazy load all images
- Aggressively recycle memory
- Release offscreen assets
- Do not retain large UIImage instances

---

## 7. DATA BOUNDARY — Core Data vs Supabase

```
Core Data  =  source of truth at all times, across all phases.
Supabase   =  optional mirror, only when Phase 3+ AND syncStatus == .completed.

Phase 0:  No Supabase calls.
Phase 1:  No Supabase calls.
Phase 2:  AI proxy via Edge Function only — no user data sync.
Phase 3:  SyncService activated. Core Data interface remains unchanged.
```

> Agent: do not import the Supabase SDK or write any Supabase calls before Phase 3.

---

## 8. PRIVACY ARCHITECTURE

### Core Rule
```
User photos NEVER leave the device.
```

### AI Payload — ONLY send
✅ Vision labels (scene description)
✅ Semantic tags
✅ User note text
✅ Selected mood
✅ Lightweight contextual metadata

### NEVER send
❌ Original photos
❌ Full-resolution images
❌ EXIF metadata
❌ GPS coordinates
❌ Raw photo uploads of any kind

### Example Payload
```json
{
  "scene_labels": ["coffee", "friends", "sunset"],
  "mood": "nostalgic",
  "note": "Quiet evening with old friends",
  "narrative_style": "warm"
}
```

### Onboarding Privacy Screen (required copy)
```
Your photos stay on your device.
MemoryInk only sends lightweight text descriptions to generate narratives.
We never upload your original photos.
```

---

## 9. OFFLINE-FIRST SYSTEM

### Core Rule
```
Save first. AI later.
```

### Required Flow
```
User creates memory
→ Save locally immediately (Core Data + file system)
→ syncStatus = .pending
→ AI request queued async
→ Timeline updates softly when narrative is ready
```

### Offline Behavior
- Entry still saves
- Images still save
- Voice still saves
- AI generation deferred silently — no technical messaging shown to user

### Retry Strategy
- Retry silently and asynchronously
- Never block the UI
- Never surface technical error language

---

## 10. ERROR TAXONOMY

| Error Type | UX Behavior | Retry |
|------------|-------------|-------|
| Network offline | Silent. Show: "Your memory is saved." | Auto when back online |
| AI timeout (> 10s) | "Narrative generation is taking longer than expected." + "Try Again" button | Manual |
| AI rate limit reached | "You've reached today's AI limit." + "Upgrade" secondary CTA | No retry |
| Core Data failure | Log internally. Show nothing to user. | No retry |
| Image save failure | Alert: "Could not save memory. Please try again." | Manual |
| Generic service error | "Couldn't generate a narrative right now." | Manual |

### Never show
❌ Stack traces · ❌ API terminology · ❌ HTTP status codes · ❌ Any technical jargon

---

## 11. TIMELINE UI SYSTEM

### Philosophy
The Timeline IS the product. It is the most important screen.

### Card Structure — each entry contains ONLY
1. Photo (thumbnail, 4:5 ratio)
2. Mood badge
3. AI narrative
4. Timestamp

### Card Design Tokens

| Property | Value |
|----------|-------|
| Aspect ratio | 4:5 portrait |
| Corner radius | 20–24pt |
| Shadow | Soft, low-opacity |
| Vertical spacing between cards | 28–36pt |
| Internal padding | 16–20pt |

### Typography

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| Narrative text | 17–19pt | Medium | 1.3–1.45 |
| Timestamp | 12–13pt | Regular | — |
| Font | SF Pro Display / SF Pro Text | — | — |

### Color System
- Warm neutrals, soft grays, film-inspired tones
- ❌ Neon, oversaturated, social-media-style palettes

### Animation System

| Property | Value |
|----------|-------|
| Entry open | 220–280ms |
| Transition style | Fade + slight scale + blur |
| ❌ Avoid | Bounce springs, overshoot, TikTok-style pacing |

### Explicitly Avoid
❌ Likes, comments, counters, engagement metrics
❌ Giant AI buttons or AI status noise
❌ Any technical indicators

### Empty State Copy
```
Your memories will appear here ✨
```

---

## 12. MEMORY CREATION FLOW

### Target Experience
Frictionless, intimate, emotionally calm. No blocking loaders. No mandatory waiting.

### Flow
```
1. Select photo
2. Add optional note or voice
3. Select mood
4. → Save locally immediately
5. → AI narrative generates async (non-blocking)
6. → Timeline updates softly
```

### Mood Picker Design
- Mature, calm, minimal, subtle
- ❌ Giant emojis, childish UI, rainbow colors

### Available Moods
Peaceful · Nostalgic · Happy · Proud · Sad · Reflective

> User always has final control. AI may suggest or preselect a mood, but never decides.

---

## 13. AI NARRATIVE SYSTEM

### Quality Rules
- Grounded, concise, subtle, emotionally warm
- ❌ Dramatic, poetic essays, robotic, exaggerated
- ❌ Invent details, hallucinate, sound like therapy, overuse metaphors

### Length

| | Words |
|-|-------|
| Ideal | 15–40 |
| Absolute maximum | 60 |

### Style Modes
User selects one of: **Warm** · **Minimal** · **Reflective**
(Affects prompting only — same model, same endpoint)

### Prompt Template
```
Write a concise and emotionally grounded memory narrative.
Do not exaggerate. Do not invent details.
Maximum 40 words.
Tone: [warm / minimal / reflective] and human.

Scene: {scene_labels}
Mood: {mood}
Note: {user_note}
```

### Cache Strategy
```
Cache key:     SHA256(scene_labels + mood + narrativeStyle)
Storage:       Core Data — aiNarrative + aiGenerationDate fields
TTL:           None. Narratives never expire automatically.
Invalidation:  Only when user explicitly requests regeneration.
Rule:          If aiNarrative already exists → NEVER auto-regenerate.
```

---

## 14. WEEKLY RECAP SYSTEM

### Schedule
Every Monday via BackgroundTasks:
1. Select meaningful memories from the past week
2. Analyze emotional tone
3. Generate recap narrative
4. Surface emotional highlights

### Constraints

| | Value |
|-|-------|
| Length | 80–120 words |
| Tone | Grounded, warm, reflective, conversational |

### AI Rules
❌ Invent events · ❌ Exaggerate emotions · ❌ Write essays · ❌ Hallucinate

---

## 15. ON THIS DAY SYSTEM

### Logic
```
Daily: find entries matching current month/day from previous years
```

### Visual Style
- Nostalgic, cinematic, soft
- Faded film tones, softer contrast, subtle blur
  *(Superseded 2026-08-20 by Part C — Cinematic Dark. The photograph is the only bright object on
  screen; the app supplies near-black ground and grey chrome, and no filter, gradient, or grain is
  drawn over a user photo. See `tasks/PART_C_PLAN.md` and `MemoryInk/Common/Theme/Colors.swift`.)*

### Notification Limit
```
2–3 notifications per week maximum (Recap + On This Day combined)
```

### Avoid
❌ Streak systems · ❌ Guilt notifications · ❌ Dopamine tricks · ❌ Spam

---

## 16. SUBSCRIPTION STRATEGY

### Plans

| Plan | Price | AI Narratives/day | Features |
|------|-------|-------------------|----------|
| Free | — | 3/day | 30 entries/month, basic recap |
| Monthly | $5.99/month | 15/day | Voice journaling, premium recap styles |
| Yearly | $39.99/year | 30/day | All styles, priority generation |

### Paywall Timing
Paywall appears ONLY AFTER:
- First memory saved
- First AI narrative generated
- First delight experience

❌ NEVER show on app launch

### Copy Tone
Honest, premium, calm, trustworthy.
❌ Fake urgency · ❌ Scammy wording · ❌ Fake unlimited claims

### Trial Policy
```
7-day free trial.
```

---

## 17. PERFORMANCE TARGETS

| Metric | Target |
|--------|--------|
| Cold launch | < 2.5 seconds |
| Timeline scroll | Stable 60fps |
| Save perceived latency | < 300ms |
| AI generation average | < 5 seconds |
| AI generation worst case | < 10 seconds |
| Memory usage (large timeline) | < 200MB |

### Optimization Priority Order
1. Scrolling performance
2. Launch speed
3. Image rendering
4. Memory recycling

> Always optimize the above BEFORE adding features or increasing AI complexity.

---

## 18. AI COST CONTROL

- Cache aggressively — never regenerate identical narratives
- Keep outputs short (15–40 words target)
- Never upload original photos
- Send only: Vision labels + metadata + note + mood

---

## 18A. AI PROXY API CONTRACT (Phase 2 Requirement)

### Endpoint
```
POST /v1/narratives/generate
```

### Request Schema
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

### Success Response
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

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_REACHED",
    "message": "You've reached today's AI limit."
  }
}
```

### Error Codes
| Code | Meaning | App Behavior |
|------|---------|--------------|
| `RATE_LIMIT_REACHED` | User has reached the daily AI limit for the current plan | Show upgrade CTA, no retry |
| `NETWORK_UNAVAILABLE` | Device or backend cannot reach the AI proxy | Queue retry silently |
| `AI_TIMEOUT` | Narrative generation exceeded timeout | Show soft retry option |
| `VALIDATION_FAILED` | Request payload is invalid | Log internally, do not show technical details |
| `SERVICE_UNAVAILABLE` | AI service or proxy temporarily unavailable | Retry later |

### Rules
- Metadata-only payload
- Never upload photos
- Never upload voice files
- Never send EXIF or GPS data
- Retry asynchronously
- Cache narratives aggressively
- Deduplicate requests via `entry_id` when possible
- Narrative limits are enforced by subscription plan
- `locale` is included from the start to support localized narratives later
- `cached` must be returned so the client can distinguish cache hits from new generations

### Narrative Limits
| Plan | Limit |
|------|-------|
| Free | 3/day |
| Monthly | 15/day |
| Yearly | 30/day |

---

## 18A-2. RECAP API CONTRACT (Phase 2 Requirement)

### Endpoint
```
POST /v1/recaps/generate
```

### Request Schema
```json
{
  "recap_id": "uuid",
  "entry_ids": ["uuid"],
  "memories": [
    {
      "entry_id": "uuid",
      "created_at": "2026-05-18T10:00:00Z",
      "scene_labels": ["coffee", "friends", "sunset"],
      "mood": "nostalgic",
      "note": "Quiet evening with old friends",
      "ai_narrative": "A quiet evening with old friends, softened by the last light of sunset."
    }
  ],
  "locale": "en"
}
```

### Success Response
```json
{
  "success": true,
  "data": {
    "recap": "This week held a few quiet, meaningful moments — small gatherings, reflective pauses, and memories that felt warm without needing to be loud.",
    "generated_at": "2026-05-18T10:00:00Z",
    "model": "gpt-4o-mini",
    "cached": false
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Couldn't generate a recap right now."
  }
}
```

### Rules
- Weekly recap does not count toward daily narrative limits.
- Recap generation uses metadata and text only.
- Never upload photos, voice files, EXIF metadata, or GPS data.
- Keep recap output grounded, warm, and concise.

---

## 18B. SUPABASE SCHEMA (Phase 3 Requirement)

### Sync Philosophy
- Local-first architecture
- Core Data remains the source of truth
- Free users: local-only storage
- Paid users: metadata-only sync
- No realtime sync in V1
- No photo sync in V1
- No voice sync in V1
- Supabase mirrors metadata only; it does not replace local persistence

### Sign-in Rules
- Free users do not need to sign in.
- Premium sync requires an account.
- Supported account methods: Sign in with Apple, Google/Gmail, or email account.
- Email account creation does not require verification in V1.
- Email input must only pass a simple format validation: `____@____.____`.

### Sync Conflict Strategy
- Use last-write-wins based on `updated_at`.
- `deleted_at` wins over stale updates.
- Soft-deleted records must not be restored by older client updates.
- Core Data remains the source of truth on the current device.

### Tables

```sql
users
- id
- apple_user_id
- created_at

journal_entries
- id
- user_id

- created_at
- updated_at
- deleted_at

- raw_note
- mood
- narrative_style

- ai_narrative
- ai_generation_date

- is_favorite

- sync_status

- local_photo_exists
- local_voice_exists

ai_usage_daily
- user_id
- date
- narrative_count
- recap_count   -- track weekly recap generation; weekly recap does not count toward daily narrative limits
```

### Sync Status Values
```
pending
syncing
completed
failed
```

### Never Store On Supabase
- Original photos
- Thumbnails
- Medium previews
- EXIF metadata
- GPS coordinates
- Voice files

### Cost Control Rules
- Do not sync free-user memories to Supabase in V1
- Do not enable realtime subscriptions in V1
- Do not use Supabase Storage for photos or voice files in V1
- Keep sync metadata small and indexable
- Use soft delete via `deleted_at` for safe sync recovery
- Keep `recap_count` in `ai_usage_daily` for analytics and abuse prevention; weekly recap does not count toward daily narrative limits

---

## 18C. REVENUECAT CONFIGURATION (Phase 3 Requirement)

### Entitlement ID
```
premium
```

### Product IDs
```
memoryink_monthly
memoryink_yearly
```

### Product Mapping
```
memoryink_monthly → premium
memoryink_yearly  → premium
```

### Premium Features
- Metadata cloud sync
- Increased AI narrative limits
- Voice journaling
- Premium recap styles

### Trial Policy
```
7-day free trial.
```

### Rule
Use one entitlement only in V1. Do not create separate entitlements for cloud sync, AI limits, voice journaling, or recap styles unless the human explicitly approves a more complex monetization structure.

---

## 19. ANALYTICS (Phase 3+ only)

### Track only

**Activation:** first_entry_created · first_narrative_generated · first_recap_opened

**Retention:** entries_per_week · on_this_day_opened · recap_opened · timeline_session_started

**Monetization:** paywall_shown · trial_started · monthly_converted · yearly_converted

### Never Track
❌ Raw memory contents · ❌ Photo data · ❌ Voice content · ❌ Private reflections

---

## 20. DEVELOPMENT ROADMAP

### Phase 0 — UI Prototype ← CURRENT
Build ONLY: Timeline UI, animations, typography, spacing, transitions, haptics
Data: Fake/mock only. No backend. No real AI. No Core Data.

### Phase 1 — Local MVP
Build: Core Data, image pipeline, local persistence, timeline, voice notes, mood system, offline UX

### Phase 2 — AI Integration
Add: GPT-4o mini via proxy, async generation, recap systems, On This Day, retry systems

### Phase 3 — Monetization & Sync
Add: RevenueCat, Mixpanel analytics, onboarding polish, paywall optimization, Supabase sync

---

## 21. EXPLICITLY EXCLUDED FROM V1

❌ Social feeds · Comments · Likes · Follower systems
❌ AI chat · AI agents · Embeddings · Vector search · Local LLM inference
❌ Realtime collaboration · Gamification · Streak systems
❌ Desktop app · Android app · Overcomplicated cloud sync

---

## 22. UI COPY GUIDELINES

**Tone:** Warm, quiet, personal — like a friend gently surfacing a memory.

| ❌ Avoid | ✅ Use |
|----------|--------|
| "Error: AI generation failed" | "Narrative will appear shortly" |
| "Upload complete" | "Memory saved" |
| "No entries found" | "Your memories will appear here ✨" |
| "Retry failed. Try again later." | "Couldn't connect right now. Try again." |
| "AI limit reached" | "You've reached today's AI limit." |
| Any technical jargon | Plain, warm English |

---

## 23. PRODUCT PRINCIPLES

1. **Emotion > Features** — users remember the feeling, not the AI system
2. **UX > AI Complexity** — timeline quality matters more than advanced AI
3. **Calm Interaction** — never addictive, manipulative, or noisy
4. **Local-First** — memories belong to the user; privacy is a core feature
5. **AI is Subtle** — AI should never feel central to the experience

---

## 24. FINAL PRINCIPLE

> MemoryInk should feel **emotionally lightweight**, not **technically overwhelming**.

This is the deciding criterion for every design and engineering decision.
