# Part C — Cinematic Dark: UI/UX Rebuild

> **Status:** ✅ **complete — C.1–C.8 done 2026-08-20** · **Branch:** `memoryink-v3-part-c`
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

### C.1 — Dark-first palette ✅ **done 2026-08-20**
Rewrote `Common/Theme/Colors.swift` dark-first: a four-step ground ramp that actually steps (the
old one spanned 0.89–0.99 lightness, which is why cards never separated from the background), three
text roles, and role-named aliases (`accent`, `success`, `destructive`, `accentBright`,
`neutralMark`) so screens stop picking colours by hue name.

**Three things the plan got wrong, corrected during the work:**

1. *"Delete the nine long-tail accents."* They are the **mood system** — `MoodType.tint` maps
   teal→peaceful, orchid→nostalgic, gold→happy, coral→proud, ocean→sad, twilight→reflective, with
   sage/rosewood/mistBlue carrying `SlideshowStyle`, plus `rosewood` = destructive and `sage` =
   success. Deleting them would have deleted the mood system C.3 exists to keep. The real defect
   was never the count: it was that tokens are **named by hue instead of by role**, so the same
   colour meant "mood: proud" on one screen and "vintage slideshow" on another. Hence the aliases.
2. *"Hues stay fixed so exports stay deterministic."* Impossible. For a colour to clear AA (4.5:1)
   on near-black it needs luminance ≥ 0.195; on white, ≤ 0.161. Those windows do not overlap, so
   **no fixed colour is accessible in both appearances** — arithmetic, not taste. Dropping to the
   3:1 graphical floor does admit fixed values, but only muddy ones (amber lands on a brown). So
   every hue adapts, and export determinism is solved where it belongs, by pinning the renderer.
3. *"Files: `Colors.swift` only."* Two companions were mandatory: `MemoryShareRenderer` (pinning)
   and `MemoryInkWidget` (its own hardcoded palette copy, no compiler link to the app's).

**Also fixed:** `UIColor(someColor)` silently flattens a dynamic colour, which made the first
version of the export pinning a no-op. The dynamic `UIColor` is now the source of truth
(`MemoryInkColors.Raw`) and `Color` values wrap it.

**Files:** `Colors.swift`, `MemoryShareRenderer.swift`, `MoodType.swift` (`tintRaw`),
`MemoryInkWidget.swift`, `MemoryInkTests/PaletteContrastTests.swift` (new, 5 tests).

**Verified:** 28 tests pass incl. contrast floors on every text role × every surface × both
appearances; Release `xcodebuild` → BUILD SUCCEEDED. **Not seen on screen.**

### C.2 — Strip the photo effect stack ✅
`TimelineCard.imageArea` / `placeholderImage` currently layer: radial light leak, mood tint
gradient, `.screen` blend mode, subtle grain, vignette, and a masked accent gradient — six
effects on one photograph. Against black, all of them fight the image.
- Remove all six. The photo gets a clean edge and nothing else.
- Retire `TimelineMemory.lightLeak` and its `lightLeak(for:)` factory in `TimelineViewModel`
- **Files:** `TimelineCard.swift`, `TimelineViewModel.swift`

### C.3 — Demote mood from surface treatment to a mark ✅
Mood currently tints whole cards through `MoodType.tint` / `secondaryTint` / `palette`. Under
this direction mood becomes a small, precise signal: a coloured dot and label, nothing more.
- Keep the six mood hues (they carry real meaning) but restrict them to badge-scale use
- **Files:** `MoodType.swift`, `TimelineCard.swift`, `MoodPickerView.swift`

### C.4 — Ambient backdrop ✅
`MemoryInkAmbientBackdrop` paints mood-derived gradients app-wide. Replace with a near-black
ground carrying at most a very faint luminance falloff.
- **Files:** `CinematicVisualSystem.swift`

### C.5 — Typography scale ✅
Today: Spectral SemiBold titles, then system 12–20 with almost no weight contrast.
- Move the serif onto the *narrative* (the emotional content), not just headers
- Larger sizes, lighter weights, more line-height; metadata drops to small tight grey
- Define a 5-step scale so screens stop inventing sizes
- **Files:** `Typography.swift`, then the screens that hardcode fonts

### C.6 — Motion pass ✅
Current motion is scale + opacity springs. This direction wants slow fades and depth-of-field.
- Standard transition becomes opacity + a small blur ramp; drop scale from most transitions
- Keep every `reduceMotion` branch working — it is already wired throughout
- **Files:** `CinematicVisualSystem.swift`, then transition call sites

### C.7 — Screen sweep ✅
Apply the new system screen by screen. Suggested batches, biggest-impact first:
1. Timeline, TimelineCard, MemoryDetail *(the app's core loop)*
2. MemoryCreation, MoodPicker, MemoryViewer
3. OnThisDay, Recap, Calendar, YearlyReview, EmotionGraph
4. Settings, Subscription, Onboarding ×3, AppLock, Browse, SlideshowPicker

### C.8 — Downstream re-tuning ✅
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


---

## What C.2–C.8 actually found

**The photo carried eight layers, not six.** The plan counted a light leak, a mood gradient, a
`.screen` blend, grain, a vignette and a masked accent. It missed three decorative "film strip"
capsules and a blurred lens-flare circle, and counted the blend mode as its own layer when it was
an attribute of two others. The important one: **two layers used `.screen`, which lifts blacks by
definition** — on a near-black ground that greyed out every photograph in the app. Removing them
also retired `TimelineMemory.palette`, `.lightLeak` and `.accent` and their three factories, since
this view was their only consumer.

**White text stopped working.** Every filled control in the app drew `.foregroundStyle(.white)` on
a hue background. That was safe while hues were dark; they invert now, so white-on-amber fell to
about 1.9:1 — failing and unpleasant. Added an `onAccent` role that flips opposite the fill
(near-black on bright dark-mode hues, near-white on deeper light-mode ones) and applied it to the
17 filled controls across 9 files. Two tests lock it in, one of which asserts that plain white
*would* fail — if that test ever passes, the palette has drifted back.

**Four mood chips were misdiagnosed.** They matched the "white on a hue" search but sit on
`.ultraThinMaterial` over a photo, where `onAccent` would have made them near-black on a dark chip.
They got the C.3 treatment instead — a dot plus an `ink` label — which also made the four screens
consistent with the Timeline for the first time.

**The share renderer had a live bug.** The `Parchment` theme has light artwork but took its ink
from the app palette, which after pinning resolved to near-white: pale text on pale parchment. Card
ink now follows the *artwork* it sits on, via two fixed constants, because a share card is a
picture and its background never adapts. The mood tint also now carries the badge on every theme
rather than falling back to flat white on light-ink ones.

**Only one Spectral weight is bundled.** C.5 was written assuming Regular and Medium existed.
`Font.custom` falls back to the system face *silently*, so requesting them would have removed the
serif from the app without any error. Sizes are now chosen for the semibold face that exists;
adding a lighter weight is queued as a decision in `MANUAL_TODO.md`.

**`MemoryInkAmbientBackdrop` kept its unused parameters.** Every screen passes `mood:` and
`intensity:`; churning all those call sites for a decision that may reverse was not worth it.

## Verified

- 30 tests pass, including 7 palette tests: text roles × 4 surfaces × 2 appearances, hue floors,
  ramp ordering, export determinism, `onAccent` on every hue, and the white-fails guard
- Release-configuration `xcodebuild` → BUILD SUCCEEDED
- `AGENTS.md` and blueprint §11 updated, with the superseded rule recorded rather than deleted

## Not verified

**Nothing here has been seen on a screen.** Contrast is arithmetic and it is proven; whether the
result feels calm is not something a test can answer. Queued in `MANUAL_TODO.md`, with light mode
called out as the likelier side to look wrong since it was derived rather than designed.
