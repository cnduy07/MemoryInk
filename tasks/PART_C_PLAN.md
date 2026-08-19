# Part C — Cinematic Dark: UI/UX Rebuild

> **Status:** planned, not started · **Branch:** `memoryink-v2-part-c` (to be created off `main`)
> **Direction chosen by you, 2026-08-19:** Cinematic dark
> **Ships as:** v3. v2 (2.0, build 5) is on `main` and goes to the App Store first.

---

## The direction in one paragraph

The photo is the only bright object on screen. Everything else — ground, chrome, labels —
recedes into near-black and low-contrast grey, so colour enters the app *only* through the
user's own photograph. No filter stack, no decorative gradients, no competing accents. The
feeling to aim at is a darkened room with one lit print on the wall.
References: Apple Photos Memories, Halide, Kino, Arc Search.

---

## Why this is smaller than "rebuild the whole UI"

Part A consolidated every colour behind `MemoryInkColors.*`. There are **484 colour references
across the app and every one goes through that single file.** So the palette rebuild is one file
plus a short list of places that paint effects by hand — not an 18-screen rewrite.

The measured distribution also shows the app already *has* a dominant accent, it just never
committed to it:

| Token | Uses | Fate under Cinematic Dark |
|---|---:|---|
| `secondaryInk` / `ink` / `tertiaryInk` | 219 | Keep as roles; invert the ramp for dark-first |
| `paper` / `paperWarm` / `parchment` / `parchmentDeep` | 97 | Become elevated near-black surfaces |
| `hairline` | 45 | Keep; drop to ~8% white |
| **`amber`** | **43** | **Promote to the single accent, retuned for black** |
| `sunlit` `rosewood` `sage` `orchid` `ocean` `mistBlue` `coral` `twilight` `teal` `gold` `taupe` | 62 | Collapse — these survive only as mood marks (C.3) |

That long tail of nine barely-used accents is most of why the current UI reads as unfocused.

---

## Items

Each item is independently buildable and verifiable. Do them in order — later items depend on
the palette existing.

### C.1 — Dark-first palette
Rewrite `Common/Theme/Colors.swift`. Design the **dark** values first and derive light from them
(today it is the reverse, which is why dark mode reads as "light mode dimmed").
- Ground: true near-black `#0B0B0C`-ish, one elevated surface, one raised surface
- Text: near-white primary → two grey steps, hitting WCAG AA on the ground colour
- One accent (amber, retuned so it doesn't glow against black)
- Delete the nine long-tail accents from the public API
- **Files:** `Colors.swift` only. Nothing else changes yet; the app should still build and run,
  just darker and flatter.

### C.2 — Strip the photo effect stack
`TimelineCard.imageArea` / `placeholderImage` currently layer: radial light leak, mood tint
gradient, `.screen` blend mode, subtle grain, vignette, and a masked accent gradient — six
effects on one photograph. Against black, all of them fight the image.
- Remove all six. The photo gets a clean edge and nothing else.
- Retire `TimelineMemory.lightLeak` and its `lightLeak(for:)` factory in `TimelineViewModel`
- **Files:** `TimelineCard.swift`, `TimelineViewModel.swift`

### C.3 — Demote mood from surface treatment to a mark
Mood currently tints whole cards through `MoodType.tint` / `secondaryTint` / `palette`. Under
this direction mood becomes a small, precise signal: a coloured dot and label, nothing more.
- Keep the six mood hues (they carry real meaning) but restrict them to badge-scale use
- **Files:** `MoodType.swift`, `TimelineCard.swift`, `MoodPickerView.swift`

### C.4 — Ambient backdrop
`MemoryInkAmbientBackdrop` paints mood-derived gradients app-wide. Replace with a near-black
ground carrying at most a very faint luminance falloff.
- **Files:** `CinematicVisualSystem.swift`

### C.5 — Typography scale
Today: Spectral SemiBold titles, then system 12–20 with almost no weight contrast.
- Move the serif onto the *narrative* (the emotional content), not just headers
- Larger sizes, lighter weights, more line-height; metadata drops to small tight grey
- Define a 5-step scale so screens stop inventing sizes
- **Files:** `Typography.swift`, then the screens that hardcode fonts

### C.6 — Motion pass
Current motion is scale + opacity springs. This direction wants slow fades and depth-of-field.
- Standard transition becomes opacity + a small blur ramp; drop scale from most transitions
- Keep every `reduceMotion` branch working — it is already wired throughout
- **Files:** `CinematicVisualSystem.swift`, then transition call sites

### C.7 — Screen sweep (18 views)
Apply the new system screen by screen. Suggested batches, biggest-impact first:
1. Timeline, TimelineCard, MemoryDetail *(the app's core loop)*
2. MemoryCreation, MoodPicker, MemoryViewer
3. OnThisDay, Recap, Calendar, YearlyReview, EmotionGraph
4. Settings, Subscription, Onboarding ×3, AppLock, Browse, SlideshowPicker

### C.8 — Downstream re-tuning
Two things bake the old palette into rendered output and will look wrong until redone:
- **Themed share cards** (`MemoryShareRenderer`) — four hand-drawn themes on parchment
- **Home/Lock Screen widgets** — separate target, own colour usage
Both were device-verified last session; both need re-verifying after this.

---

## Decisions

**1. Light mode stays — assumed, tell me if wrong.** "Dark-first" here means the dark palette is
designed first and light is derived from it, *not* that light mode is dropped. Removing it would
regress anyone who prefers light and anyone in bright sun. I will build both unless you say
dark-only.

**2. `AGENTS.md` product identity needs your sign-off.** It currently reads *"Color: warm
neutrals, film tones · ❌ neon, oversaturated"* and the blueprint §11 design tokens say the same.
Part C deliberately departs from that. Unless those lines are updated, a future session will read
them as law and quietly undo this work. I will not edit the identity section without you saying so.

**3. Re-verification cost is real.** The v2 device pass you just cleared covered the *current*
look. Part C invalidates the visual half of it — share cards especially, since they are
hand-placed drawing code. Budget for a second pass.

---

## Success criteria

- [ ] Zero references to the nine retired accent tokens remain
- [ ] No gradient, blend mode, grain, or vignette is painted over a user photo anywhere
- [ ] Every text/ground pair in the dark palette meets WCAG AA
- [ ] Light mode still renders correctly on every screen
- [ ] `xcodebuild` Release → BUILD SUCCEEDED after each item
- [ ] Every `reduceMotion` branch still resolves to a non-animating path
