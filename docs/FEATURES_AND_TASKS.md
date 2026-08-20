# MemoryInk — Features, Architecture & Delivery History

> What the product is, how it is built, why it is built that way, and what shipped when.
>
> Written so you can explain the project end-to-end without opening the code — and defend the
> decisions, which is the part that gets asked about.
>
> Vietnamese edition: [`FEATURES_AND_TASKS.vi.md`](FEATURES_AND_TASKS.vi.md) · Companion documents:
> [`BUGS_AND_FIXES.md`](BUGS_AND_FIXES.md) · [`INTERVIEW_PREP.md`](INTERVIEW_PREP.md)
>
> **Last updated:** 2026-08-20

---

## The one-paragraph version

**MemoryInk is a private iOS journal that turns a photo, a mood, and an optional note into a short
warm narrative written by AI — without the photo ever leaving the device.**

Users capture moments; the app writes a 15–40 word reflection from *metadata only* (vision labels,
semantic tags, note text, mood) and surfaces them back over time: a weekly recap, "On This Day", a
yearly review, milestones, a calendar.

It is live on the App Store, built in SwiftUI with Core Data as the source of truth, Supabase Edge
Functions as an AI proxy, and RevenueCat for subscriptions.

**Scale:** 78 Swift files · ~14,100 lines · 44 commits · 3 Supabase Edge Functions · 30 unit tests ·
**one** third-party dependency.

**App Store:** https://apps.apple.com/vn/app/memoryink-journal/id6770572153 · bundle
`com.memoryink.app`

---

## The defining constraint: privacy

Lead with this, because it shaped every other decision.

| Rule | How it is enforced |
|---|---|
| **Photos never leave the device** | No upload path exists anywhere in the codebase. Core Data stores *file path strings*, never image blobs. Supabase Storage is not used for media at all. |
| **AI sees metadata only** | The narrative request carries vision labels, semantic tags, note text, mood, style and locale. Never the image, never EXIF, never GPS. |
| **No analytics** | `AnalyticsService.track()` is a deliberate no-op — the event taxonomy exists, the transmission does not. No Mixpanel, no Firebase, no SDK. |
| **Export carries references, not content** | The backup file contains a photo's *file name* so a future import can re-link it — verified by test that the output has no image bytes, no directory structure, and no GPS/EXIF field. |
| **Widgets get a snapshot, not the journal** | The widget process reads a small JSON plus one thumbnail, never the Core Data store. |

> **If asked "how do you know?"** — the export rules are covered by assertions that run against the
> real `ExportService.swift` and fail if any of `gps`, `latitude`, `longitude`, `exif`, or a
> directory separator appears in the output. The guarantee is tested, not just intended.

**Why this is worth leading with.** Privacy here is not a marketing line bolted on at the end; it is
a *constraint that removed options*. It is the reason the AI works on metadata instead of images,
the reason there is an Edge Function proxy at all, the reason the widget reads a snapshot, and the
reason the export format looks the way it does. Being able to trace one constraint through five
unrelated design decisions is a strong thing to demonstrate.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI Views  ·  Features/ (12 screens)               │
├─────────────────────────────────────────────────────────┤
│  ViewModels  ·  lightweight, per-feature, @MainActor    │
├─────────────────────────────────────────────────────────┤
│  Services/ (15)  ·  AI · Sync · Auth · Images · Export  │
│                     Slideshow · Notifications · Lock    │
├─────────────────────────────────────────────────────────┤
│  Persistence/  ·  Core Data = SOURCE OF TRUTH           │
│                   JournalEntryRepository (@Published)   │
├─────────────────────────────────────────────────────────┤
│  Files on disk  ·  /originals /thumbnails /medium /voice│
└─────────────────────────────────────────────────────────┘
        │                          │
        │ metadata only            │ snapshot file
        ▼                          ▼
  Supabase Edge Functions    App Group container
  (AI proxy + delete)         → WidgetKit extension
```

**Stack:** iOS 16+ · SwiftUI · pragmatic MVVM · Core Data · Swift Concurrency (async/await) ·
WidgetKit · LocalAuthentication · AVFoundation · Vision · RevenueCat · Supabase Edge Functions
(Deno/TypeScript).

**Dependencies: exactly one.** RevenueCat, via SPM. Supabase is called with plain `URLSession` — no
SDK. Everything else is a first-party Apple framework.

This was deliberate: fewer dependencies means fewer supply-chain surprises, no version-lock when
Apple ships a new OS, and nothing to strip out later. The cost is writing your own networking layer,
which for three endpoints is a morning's work.

### Six decisions worth being able to defend

**1. Core Data is the source of truth; Supabase is a mirror.**

The app is fully functional offline and for users who never sign in. Sync is an *enhancement* for
premium users, not the storage layer.

Consequence: a sync failure can never cost a user their journal. The worst case is that the cloud
copy is stale.

**2. Save first, AI later.**

The required flow is: user creates a memory → **saved locally immediately** → AI request queued
async → timeline updates softly when it lands.

The user never waits on a network round-trip to keep a memory. Save latency target is <300ms; AI is
allowed up to 10s precisely because it is off the critical path.

**3. Last-write-wins on `updated_at`, with a delete rule.**

Conflict resolution is intentionally simple. This is a single-user journal, not a collaborative
document, so CRDTs or a merge UI would buy nothing and cost a great deal.

The one asymmetry: `deleted_at` beats a stale update, so a soft-deleted record can never be
resurrected by an older client.

**4. Three image sizes, generated once on save.**

Original, thumbnail (500px), medium (1600px), plus an in-memory cache. The timeline *never* renders
full resolution — that is what keeps scrolling at 60fps with hundreds of photo cards.

**5. The AI never regenerates over an existing narrative.**

If `aiNarrative` exists, it is kept. A user's memory should not quietly change wording because they
reopened a screen — and it caps cost. Regeneration is explicit: on edit, or on retry.

**6. Colour is named by role, not by hue.**

Introduced in Part C after the old palette failed. Screens ask for `accent`, `success`,
`destructive`, `onAccent`, `ink` — never `amber` or `teal`. The old scheme let the same hue mean
"mood: proud" on one screen and "vintage slideshow style" on another, so screens picked colours by
eye and nothing stayed consistent. Hue names now survive only for the mood system, where the hue
*is* the meaning.

---

## Feature inventory

### Capture
- **Memory creation** — photo (library or camera) *or* a mood backdrop for photo-less entries, mood
  picker, optional note, optional voice path support.
- **Image pipeline** — original + 500px thumbnail + 1600px medium written on save, JPEG q0.82/0.86,
  cached in memory.
- **Offline-first save** — the local write completes before anything else is attempted.

### AI
- **Narrative generation** — `POST /v1/narratives/generate` through a Supabase Edge Function, so the
  OpenAI key never ships in the app. 15–40 words ideal, 60 max. Three styles (Warm, Minimal,
  Reflective) implemented as prompting only. Responses carry a `cached` flag so the client can tell
  a cache hit from a fresh generation.
- **Weekly recap** — `POST /v1/recaps/generate`, summarises the emotional week. Does not count
  against the daily narrative limit.
- **Yearly review** — premium "Wrapped"-style annual retrospective with a thumbnail collage.
- **Rate limiting** — 3/day free, 15 monthly, 30 yearly, tracked per-day in `AIUsageTracker`.
  Counted only on success (see BUGS §6).

### Browse & resurface
- **Timeline** — list *or* grid layout (persisted), search over notes and narratives, mood filter,
  favourites filter, tap-to-expand detail overlay with a fade + defocus transition (BUGS §9.4
  explains why it is not matched-geometry).
- **Card Browse** — full-screen swipe deck.
- **Memory Viewer** — full-screen photo pager.
- **Calendar** — month grid with a **mood-density heatmap** (five intensity steps by entries/day)
  and day/month filtering.
- **On This Day+** — the same calendar date across past years, **grouped by year**, with an "Across
  the years" comparison strip and a "Day N of MemoryInk" journey counter.
- **Journey milestones** — 15 one-off moments: entry counts (10→500), days since the first memory
  (30/100/500/1000), anniversaries (1–5 years). Thresholds are `>=` so none can be missed, only the
  deepest shows when several land at once, and each fires exactly once, ever.
- **Surprise Me** — a random memory.

### Share & export
- **Share card** — a 1080×1080 image rendered on-device, with a live preview and **four themes**
  (Classic plus three gradient scenes). One shared component behind all four share entry points.
- **Slideshow export** — AVFoundation video with per-mood audio and background scenes.
- **Local backup** — dated JSON export of notes, moods, narratives and favourites, saved via the
  share sheet to Files. Free for everyone. Metadata only — photos are not in the file.

### Privacy & platform
- **Face ID / Touch ID / passcode lock** — optional, off by default, locks on backgrounding, starts
  locked so the journal never flashes at launch.
- **Home & Lock Screen widgets** — small, medium, circular, rectangular. Fed by a snapshot file in a
  shared App Group container.
- **Daily reminder + On This Day notifications** — local, via `UNUserNotificationCenter`.
- **Light and dark appearance** — a full adaptive palette with contrast floors enforced by tests,
  not a tint swap.

### Account & monetization
- **Sign in with Apple + email** (no verification in V1). Free users never need an account.
- **Metadata-only sync** for premium users; last-write-wins.
- **Account deletion** via an authenticated Edge Function (see BUGS §7).
- **Paywall** appears only *after* a first emotional moment — never on launch.

| Plan | Price | AI narratives/day |
|---|---|---|
| Free | — | 3 |
| Monthly | $5.99/mo | 15 |
| Yearly | $39.99/yr | 30 |

RevenueCat, one entitlement (`premium`), products `memoryink_monthly` / `memoryink_yearly`, 7-day
free trial. Premium unlocks cloud sync, higher AI limits, voice journaling and premium recap styles.

---

## Delivery history

| When | What |
|---|---|
| **2026-05-18** | **Phase 0** — timeline UI prototype. **Phase 1** — local MVP: capture, Core Data, image pipeline. **Phase 2** — AI integration behind Supabase Edge Functions. |
| **2026-05-19** | **Phase 3** — RevenueCat integration; Supabase auth + metadata sync wired and hardened. |
| **2026-05-21** | **V1.1 feature wave** — edit/delete, search, reminders, mood filters, grid toggle, share card, Surprise Me, milestones, dark mode, Yearly Review, Calendar. Then Memory Viewer, Recap redesign, Browse Mode, Background Scenes, and the overflow/gesture fixes. |
| **2026-05-23** | Slideshow video export. iPad + iPhone SE adaptivity (three rounds). App Store submission fixes. **Shipped to the App Store as 1.0.** |
| **2026-07-11** | UI revitalisation + hardened account lifecycle (Edge Function deletion). |
| **2026-08-18** | **v2 Part A — visual refresh (9/9).** Design-system consolidation: one ambient backdrop everywhere, a shared hero header, a spacing/radius scale, a bundled display serif (Spectral, SIL OFL), a hero transition into the detail overlay (later replaced — BUGS §9.4), an app-wide haptics sweep, four screens redesigned, and duplicated chart + swipe-gesture code extracted into shared components. |
| **2026-08-19** | **v2 Part B — new features (6/6).** On This Day+ & journey milestones · share card themes · local export · calendar heatmap · Face ID lock · Home/Lock Screen widgets. |
| **2026-08-19** | Device pass on Part B. One bug found across the whole batch: the Timeline hero transition (BUGS §9.4). Version bumped to **2.0 (build 5)**, merged to `main`, tagged `v2.0-appstore`. |
| **2026-08-20** | **v3 Part C — Cinematic Dark rebuild (8/8).** Dark-first palette with tested contrast floors, the photo stripped of all overlays, mood demoted to a mark, motion moved from scale to fade + defocus, the serif moved onto the narrative, and the widget + share renderer re-tuned. Four bugs found (BUGS §10). |

### How the v2 upgrade was scoped

It started as a research pass against a reference app (*Memories: My Love Days Counter*).

The finding that shaped everything: **MemoryInk's design system already existed but was applied to
only 3 of ~12 screens.** So Part A was consolidation, not invention — the highest-impact work was
making existing components universal.

Equally important was what got *excluded*. The reference app's real hook is couple-focused: a shared
space, virtual pets, coins, in-app messaging. All of it was rejected as social/gamified — it
conflicts with the product identity (*calm · private · personal*) and with explicit bans in the
project's own rulebook.

What carried over were **idea categories** — day counters, widgets, a private lock, shareable cards,
backup — reinterpreted for a solo journal.

> Worth saying in an interview: the milestone system is explicitly **not a streak**. Streaks punish
> you for missing a day; these are anniversaries measured from your first memory — nothing resets,
> nothing breaks, nothing is scored. That distinction is a product decision, not a technical one,
> and it is the kind of judgement that shows you understand who the product is for.

### How Part C was scoped

Part C began from a blunt piece of feedback: the UI did not look good. That is not actionable on its
own, so the first step was to make it measurable.

Counting colour usage found the real defect. There were 484 colour references, all funnelled through
one token file — and `amber` alone accounted for 43 of them while nine other accents shared 62
between them. **The app already had a dominant accent and had simply never committed to it.**

That reframed the work entirely. "The UI is ugly" sounds like a rewrite of 18 screens; "the palette
hedges across ten accents and the tokens are named by hue instead of role" is a change to one file
plus a sweep. Measuring turned an unbounded task into a bounded one.

Two of the plan's own assumptions then turned out to be wrong and had to be corrected mid-flight —
the "redundant" accents were the mood system, and fixed hues were mathematically impossible (BUGS
§10.2). Both are written up honestly rather than quietly fixed, because *changing a plan when the
evidence contradicts it* is the point.

---

## Notable engineering problems solved

**Shipping a WidgetKit extension without the Xcode GUI.**

The widget target — build phases, build configurations, target dependency, container proxy, and the
app's Embed Extensions phase — was written directly into `project.pbxproj`, then verified by checking
the target list, each target's compiled file list, and that the `.appex` was embedded at
`MemoryInk.app/PlugIns/` with the right extension point.

**Choosing a widget data path.**

Two options: move the Core Data store into the App Group container (one live store, but every
existing user's journal has to be migrated) or mirror a small snapshot file (no migration, slightly
stale).

The snapshot won — the widget only needs a mood, a thumbnail and a day count, so migration risk
bought nothing. **The store never moves.** This is a good example of choosing the boring option
because the expensive option's benefit did not apply.

**Making an accessibility requirement testable.**

Contrast is normally checked by eye or by a designer's spot check. Here it became arithmetic: a test
suite resolves every text role against every surface in both appearances and asserts the WCAG ratio.

That mattered because three rounds of hand-tuned values passed human inspection and failed the
maths (BUGS §10.5). The suite also encodes two facts that are easy to lose: that `UIColor(Color)`
flattens dynamic colours, and that plain white *would* fail on dark-mode hues — both asserted, so
the reasoning survives even if the person does not.

**One share component instead of four.**

The share card was being constructed at four separate call sites with slightly different inputs.
Adding themes was the moment to collapse them into a single component, so the preview and theme
choice are identical everywhere. Feature work is the cheapest time to pay down that kind of
duplication, because you are already touching every call site.

**Verifying privacy before a test target existed.**

`MilestoneService` and `ExportService` depend only on Foundation, so they compiled standalone
against stub models — assertions run against the real source files, covering the export's privacy
guarantees and the milestone state machine (fires-once, legacy key compatibility, clock skew). A
real test target now exists (30 tests), but the technique is worth knowing: pure-Foundation services
are testable long before the app's test infrastructure is.

---

## Questions you're likely to be asked

**"How does the AI work if photos never leave the device?"**

On-device Vision produces labels and semantic tags. Those, plus the note text, mood and style, go to
a Supabase Edge Function, which calls OpenAI. The proxy exists so the API key never ships in the
binary. The image itself is never in the payload.

**"Why Core Data instead of just syncing everything to a server?"**

Because the app has to work fully offline and for users who never create an account, and because a
journal is the kind of data where a sync bug losing entries would be unforgivable. The server is a
convenience mirror; the device is the truth.

**"How do you handle sync conflicts?"**

Last-write-wins on `updated_at`, with `deleted_at` beating stale updates. For a single-user journal
that is the right complexity level — anything more sophisticated would be solving a problem the
product does not have.

**"What was the hardest bug?"**

Pick by what the interviewer seems to want. BUGS §1 for a technical answer about layout systems, §6
for reasoning about failure modes, §9.1 for a process answer, §9.4 for reading an API's contract, or
§10.2 if you want to show you can prove a requirement impossible instead of grinding at it.

**"Tell me about a time you were wrong."**

Part C, twice in one task. The plan said to delete nine redundant accent colours — they turned out to
be the mood system. The plan also said to keep the hues fixed so exports stayed deterministic — that
is arithmetically impossible. Both were caught by measuring rather than by opinion, both are written
down in the docs rather than quietly corrected, and the export-determinism goal was met a different
way.

**"How do you know your accessibility work is correct?"**

It is asserted, not assumed: every text role against every surface in both appearances, at the WCAG
4.5:1 floor for body text and 3:1 for graphical elements. Worth adding that hand-tuning failed three
times before this existed — which is the honest reason the tests are there.

**"What would you do next?"**

Voice journaling and CloudKit are the two features consciously deferred. Nearer term: broaden the
test suite beyond the palette and the Foundation-only services — the SwiftUI layer is still verified
by hand on a device.

**"What's the weakest part of the codebase?"**

Test coverage of the UI layer. The palette, export and milestone logic are covered; SwiftUI views
are verified by building and looking. That is a deliberate trade for a solo project at this stage,
not something to defend as ideal.

The honest version of this answer is better than a fake weakness, and it pairs well with §10 — those
bugs are exactly what that gap lets through, and the response was to automate the checks that could
be automated rather than promise to look harder.
