# AGENTS.md
> MemoryInk — AI Agent Operating Manual
> Version: V3 — synchronized with MemoryInk Production Blueprint V8 finalized
> Read this file BEFORE doing anything. This is behavioral law, not reference material.

---

## ⚡ ACTIVE PHASE

```
Phase 2 — AI Integration
```


**In scope NOW:**
AIService, Supabase Edge Function AI proxy contract, async narrative generation, retry logic, local AI cache behavior, weekly recap, On This Day, background task stubs, AI usage tracking logic

**Out of scope — do not build until phase changes:**
Supabase data sync, RevenueCat, Mixpanel, real authentication, cloud sync, subscription paywall, Phase 3 monetization

> To change the active phase, the human must update this section and the corresponding section in the blueprint.

---

## PRE-CODING CHECKLIST

Before writing any line of code, confirm in order:

- [ ] The requested task is within the **Active Phase** scope
- [ ] No new external dependency is required
- [ ] The files to be created or modified have been identified
- [ ] No part of the task touches an item marked ⏳ in the blueprint Decision Log

If any item fails → **stop and ask the human** before proceeding.

---

## APPROVAL REQUIRED vs. FREE TO PROCEED

### Agent may proceed without asking:
- Creating a new file in the correct location per the project structure
- Adding a UI component within the feature currently being built
- Refactoring within the scope of the file being worked on
- Writing fake / mock data for Phase 0

### Agent MUST ask the human first:
- Adding any new Swift Package or external dependency
- Changing the Core Data model (migration impact)
- Adding any API call outside the current active phase
- Adding any API call not already defined in the blueprint
- Calling any production API without explicit approval
- Deleting or renaming any existing file or folder
- Changing subscription pricing, trial policy, entitlement IDs, product IDs, or paywall logic
- Building any feature that belongs to a later phase
- Anything involving an item marked ⏳ in the blueprint Decision Log

---

## REQUIRED RESPONSE FORMAT

Every response for a coding task must follow this structure:

```
### Planned Changes
- [Filename] [create / modify / delete] — short reason

### Code
[Code here]

### Summary
- Files changed: [explicit list]
- Behavior change: [1–2 sentence description]
- Not verified: [anything not tested or confirmed]
- Needs human approval for next step: [yes / no + reason if yes]
```

---

## PRODUCT IDENTITY

Read this before writing any code or UI string.

**MemoryInk is:** a calm emotional memory product powered subtly by AI.

**MemoryInk is NOT:** a productivity app, second-brain, AI assistant, social network, or chat app.

**Product feel:** calm · emotional · cinematic · premium · private · Apple-quality

**Never:** noisy · technical · overwhelming · addictive · gamified · social-media-style

> If a feature, component, or copy string violates the above → refuse it and explain why.

---

## PROJECT STRUCTURE

All files must be created in the correct location. Do not create new top-level folders without approval.

```
MemoryInk/
├── App/
│   ├── MemoryInkApp.swift
│   └── AppRouter.swift
├── Features/
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── TimelineViewModel.swift
│   │   └── TimelineCard.swift
│   ├── MemoryCreation/
│   │   ├── MemoryCreationView.swift
│   │   ├── MemoryCreationViewModel.swift
│   │   └── MoodPickerView.swift
│   ├── MemoryDetail/
│   │   ├── MemoryDetailView.swift
│   │   └── MemoryDetailViewModel.swift
│   ├── Recap/
│   ├── OnThisDay/
│   ├── Settings/
│   ├── Subscription/
│   └── Onboarding/
│       ├── OnboardingView.swift
│       ├── PrivacyScreenView.swift
│       └── MoodIntroView.swift
├── Services/
│   ├── ImagePipelineService.swift
│   ├── AIService.swift
│   ├── VoiceService.swift
│   ├── NotificationService.swift
│   └── SyncService.swift
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
    ├── Components/
    └── Theme/
        ├── Typography.swift
        ├── Colors.swift
        └── Spacing.swift
```

---

## ARCHITECTURE RULES

**Use:**
- Pragmatic MVVM
- Feature folders
- Lightweight ViewModels
- Isolated Services
- Swift Concurrency (async/await)
- Native Apple frameworks first

**Do not use:**
- Excessive abstraction or generic layers
- Giant base classes
- Singleton-heavy design
- TCA, Composable Architecture, or any third-party architecture framework
- Local LLMs, embeddings, vector search, AI agent systems

**Navigation:**
- Path-based, typed destinations, AppRouter object
- ❌ Nested NavigationLink chains · ❌ Singleton routers · ❌ View-driven navigation

---

## PRIVACY RULES — NON-NEGOTIABLE

```
User photos NEVER leave the device.
```

**NEVER send:** original photos · full-resolution images · EXIF data · GPS · raw uploads

**Only send to AI:** Vision labels · semantic tags · user note text · selected mood · lightweight metadata

**The agent must not implement any feature that uploads raw user media.** If asked to do so, refuse and explain.

---

## DATA & STORAGE RULES

- Never store image blobs in Core Data — store file path strings only
- Every image must generate 3 versions on save: original · thumbnail (300–500px) · medium (1200–1600px)
- Timeline NEVER renders full-resolution — always use thumbnails
- Directories: `/Documents/originals` · `/thumbnails` · `/medium` · `/voice`
- Core Data is the source of truth. Supabase is a mirror for metadata sync in Phase 3+ only.
- **Phase 0–1:** no Supabase calls of any kind.
- **Phase 2:** Supabase Edge Functions are allowed only for AI proxy endpoints defined in the blueprint. No Supabase data sync.
- **Phase 3+:** Supabase metadata-only sync is allowed for premium users only.

---

## PHASED BACKEND RULES

### Phase 2 — AI Proxy Only
Allowed Supabase Edge Function endpoints:
- `POST /v1/narratives/generate`
- `POST /v1/recaps/generate`

Phase 2 must not implement Supabase database sync, RevenueCat purchases, Mixpanel analytics, or real authentication unless the active phase is explicitly changed and approved.

### Phase 3 — Monetization & Metadata Sync
Allowed only when active phase changes to Phase 3:
- RevenueCat integration
- Mixpanel analytics
- Sign-in for premium sync
- Supabase metadata-only sync

Do not upload photos, thumbnails, medium previews, voice files, EXIF metadata, or GPS data in any phase.

---

## OFFLINE-FIRST RULES

```
Save first. AI later.
```

Required flow:
1. User creates memory
2. Save locally immediately
3. Queue AI request async
4. Timeline updates softly

The user must NEVER wait for AI before the memory is saved.

---

## ERROR HANDLING RULES

See full Error Taxonomy in blueprint Section 10.

**Summary:**
- Network offline → silent save, auto retry
- AI timeout → "Try Again" button
- AI rate limit → upgrade prompt
- Core Data failure → log internally, show nothing
- Never show: stack traces · API terms · HTTP codes · technical jargon

---

## UI / UX RULES

See full design tokens in blueprint Section 11.

**Quick reference:**
- Card: 4:5 ratio · 20–24pt corner radius · soft shadow
- Spacing: 28–36pt between cards · 16–20pt internal padding
- Typography: SF Pro Display/Text · Narrative 17–19pt · Timestamp 12–13pt
- Animation: 220–280ms · fade + scale + blur · ❌ bounce springs
- Color: warm neutrals, film tones · ❌ neon, oversaturated

---

## UI COPY GUIDELINES

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

## AI NARRATIVE & RECAP RULES

### Narrative
- Endpoint: `POST /v1/narratives/generate`
- Ideal: 15–40 words · Maximum: 60 words
- Style modes: Warm · Minimal · Reflective (prompting only)
- Request payload must be metadata-only: Vision labels, semantic tags, note text, mood, narrative style, locale
- Response must include `cached` so the client can distinguish cache hits from new generations
- Error response must use the standardized `success: false` + `error.code` + `error.message` shape from the blueprint
- ❌ Invent details · ❌ Hallucinate · ❌ Sound like therapy · ❌ Overuse metaphors
- Cache rule: if `aiNarrative` already exists → NEVER auto-regenerate

### Weekly Recap
- Endpoint: `POST /v1/recaps/generate`
- Weekly recap does not count toward daily narrative limits
- `recap_count` may be tracked for analytics and abuse prevention only
- Recap generation uses metadata and text only
- Never upload photos, voice files, EXIF metadata, or GPS data

See full specifications in blueprint Sections 13, 18A, and 18A-2.

---

## SUBSCRIPTION & REVENUECAT RULES

Do not change any of the following without explicit approval:

| Plan | Price | AI narratives/day |
|------|-------|-------------------|
| Free | — | 3 |
| Monthly | $5.99/month | 15 |
| Yearly | $39.99/year | 30 |

### RevenueCat V1 Configuration
- Entitlement ID: `premium`
- Product IDs: `memoryink_monthly`, `memoryink_yearly`
- Product mapping: `memoryink_monthly → premium`, `memoryink_yearly → premium`
- Trial policy: 7-day free trial
- Use one entitlement only in V1

### Premium Unlocks
- Metadata cloud sync
- Increased AI narrative limits
- Voice journaling
- Premium recap styles

- Paywall appears ONLY AFTER first emotional moment — NEVER on launch
- ❌ Fake urgency · ❌ Scammy copy · ❌ Fake unlimited claims

---

## AUTH & SYNC RULES

### Sign-in
- Free users do not need to sign in.
- Premium sync requires an account.
- Supported account methods: Sign in with Apple, Google Sign-In, or email account.
- Google/Gmail in the blueprint means Google Sign-In, not Gmail API access.
- Email account creation does not require verification in V1.
- Email input must only pass simple format validation: `____@____.____`.

### Supabase Metadata Sync
- Phase 3+ only.
- Free users: local-only storage.
- Paid users: metadata-only sync.
- No realtime sync in V1.
- No photo sync in V1.
- No voice sync in V1.
- Never use Supabase Storage for photos or voice files in V1.

### Conflict Resolution
- Use last-write-wins based on `updated_at`.
- `deleted_at` wins over stale updates.
- Soft-deleted records must not be restored by older client updates.
- Core Data remains the source of truth on the current device.

---

## PERFORMANCE RULES

| Metric | Target |
|--------|--------|
| Cold launch | < 2.5s |
| Timeline scroll | 60fps stable |
| Save latency | < 300ms |
| AI generation | avg < 5s, max < 10s |
| Memory usage | < 200MB |

Performance is a product feature. Optimize scrolling and launch BEFORE adding features.

---

## ANALYTICS RULES (Phase 3+ only)

**Track only:** first_entry_created · first_narrative_generated · first_recap_opened · entries_per_week · on_this_day_opened · recap_opened · paywall_shown · trial_started · monthly_converted · yearly_converted

**Never track:** memory contents · photo data · voice · private reflections

---

## VALIDATION RULES

- Prefer: Swift compile check → targeted Xcode preview → static inspection → unit tests for isolated logic
- Do not run expensive workflows without approval
- Do not call any production API (AI, RevenueCat, Supabase, Mixpanel) without explicit approval, even if the code path is in scope
- Use fake data for all Phase 0 work

---

## SAFETY RULES

**Do not expose or modify:**
- API keys · Supabase keys · RevenueCat keys · Mixpanel tokens
- Apple credentials · signing certificates · provisioning profiles

**Do not perform without approval:**
- Deleting source folders · Resetting git · Force pushing
- Changing bundle identifier or signing configuration
- Destructive Core Data migrations · Deleting local user data

**Absolute prohibitions:**
- Implement raw photo upload under any circumstance
- Weaken any privacy constraint
- Change monetization limits or paywall timing without explicit approval

---

## EXPLICITLY EXCLUDED — DO NOT BUILD

❌ Social feeds · Comments · Likes · Follower systems
❌ AI chat · AI agents · Embeddings · Vector search · Local LLM inference
❌ Realtime collaboration · Gamification · Streak systems
❌ Desktop app · Android app · Overcomplicated cloud sync

---

## QUICK REFERENCE — WHERE TO FIND SPECS

Do not rely on memory for technical values. Always look them up in the blueprint.

| Need to know | Blueprint Section |
|--------------|-------------------|
| Design tokens (card, spacing, typography) | Section 11 |
| AI narrative constraints + prompt template | Section 13 |
| AI proxy contract | Section 18A |
| Recap API contract | Section 18A-2 |
| Supabase schema, sign-in, sync conflict | Section 18B |
| RevenueCat entitlement, products, trial | Section 18C |
| Subscription pricing + paywall rules | Section 16 |
| Performance targets | Section 17 |
| Error copy strings | Section 10 |
| Privacy rules + AI payload | Section 8 |
| Project structure | Section 3 |
| Data models | Section 5 |
| Roadmap + phase scope | Section 20 |

---

## AFTER CODING — REQUIRED SUMMARY

After every coding task, report:
1. **Files changed:** explicit list
2. **Behavior change:** short description
3. **Checks run:** what was verified
4. **Not verified:** what was not tested
5. **Next step needs approval:** yes / no + specific reason if yes
