# MemoryInk — Bugs & Fixes

> A record of every significant bug in the project: what went wrong, **why** it went wrong, how it
> was fixed, and what it teaches.
>
> Written to be explainable out loud. If someone asks "tell me about a tricky bug you fixed," the
> answer is in here — and so is the reasoning that got to it, which is the part interviewers
> actually want.
>
> Vietnamese edition: [`BUGS_AND_FIXES.vi.md`](BUGS_AND_FIXES.vi.md) · Companion documents:
> [`FEATURES_AND_TASKS.md`](FEATURES_AND_TASKS.md) · [`INTERVIEW_PREP.md`](INTERVIEW_PREP.md)
>
> **Last updated:** 2026-08-20

---

## How to use this in an interview

Interviewers rarely want a bug list. They want to see how you *think*. Every entry below is
therefore written in the same shape:

**Symptom** → what a user saw · **First theory** → what it looked like at first, including when
that was wrong · **Root cause** → the actual mechanism · **Fix** → what changed · **Lesson** →
the transferable idea.

The "first theory" line matters most. Anyone can narrate a fix after the fact. Being able to say
*"I thought it was X, here's what ruled that out"* is what separates someone who debugged it from
someone who read about it.

### The strongest stories here, in order

1. **The AI rate-limit bug (§6)** — a one-line move with real user-money consequences. The best
   "small change, big reasoning" story you have.
2. **The palette that couldn't exist (§10.2)** — you proved a requirement was impossible with
   arithmetic instead of arguing about it, then changed the design. Rare and memorable.
3. **Account deletion (§7)** — trust, server authority, and never lying to the user about success.
4. **The hero transition that never animated (§9.4)** — reading an API's *contract* rather than its
   signature. The diagnosis is the whole story.
5. **SwiftUI horizontal overflow (§1)** — shows you understand a layout *system*, not just its API.
6. **The build system lied to me (§9.1)** — you noticed your *verification* was wrong, which is
   rarer than noticing your code is wrong.

### If you only memorise one sentence per story

- §1 — "`scaledToFill` scales but does not clip, and an unbounded proposal makes the image's own
  size become the container's size."
- §6 — "Meter the outcome, not the attempt."
- §7 — "Never optimistically report a destructive action as done."
- §9.1 — "A typecheck is not a build; the file wasn't in the target."
- §9.4 — "`matchedGeometryEffect` needs the source view to go away, and mine never did."
- §10.1 — "`UIColor(Color)` flattens a dynamic colour, so my fix was a no-op that still compiled."
- §10.2 — "No fixed colour can meet contrast against both near-black and white. The windows don't
  overlap."

---

## 1. Horizontal overflow in Detail and Browse screens

**Commits:** `27d09c1`, `d19225c` (2026-05-21)

**Symptom.** The Memory Detail and Browse screens could be scrolled sideways. Content bled past the
right edge of the screen.

**First theory.** A styling glitch — a stray padding or a negative margin. That was wrong, and
chasing it wasted time. Nothing in the padding chain was unusual.

**Root cause.** `scaledToFill()` on an image inside a `ZStack` that received an *unbounded width
proposal*.

SwiftUI lays out by proposing a size to each child and asking what it wants. A `ZStack` with no
width constraint of its own passes the proposal straight down. `scaledToFill` answers with the
image's scaled intrinsic size — which for a 1600px preview is far wider than the phone. That answer
propagates back up and becomes the container's width.

The critical detail: **`scaledToFill` scales but does not clip.** It is happy to be enormous.

**Fix.** Constrain first, then clip, and order the modifiers so the `ZStack` gets a bounded
proposal to work with:

- `imageArea`: `.frame(height: 380).clipped()`, plus an explicit `UIScreen.main.bounds.width`
- Long narrative text: `.fixedSize(horizontal: false, vertical: true)` so it wraps instead of
  widening

**Lesson.** In SwiftUI, layout is a *negotiation*, not a set of style attributes. When something is
too wide, the question is never "which padding is wrong" but **"who proposed an unbounded width,
and which child answered with its intrinsic size?"**

Learn to read a view tree as a conversation and this class of bug becomes obvious rather than
mysterious.

---

## 2. iPad and small-iPhone adaptivity

**Commits:** `d8c33d7`, `6fac36c`, `4530edd` (2026-05-23) — three rounds, because each fix exposed
the next problem.

| Bug | Cause | Fix |
|---|---|---|
| "Done" button unreachable on iPhone SE | A `Spacer()` above it grew until the button was pushed off-screen | Cap the Spacer at 80pt; give the button `frame(maxWidth: .infinity, minHeight: 44)` |
| Photo-picker dialog anchored wrongly on iPad | `confirmationDialog` presents as a popover on iPad and needs an anchor it didn't have | Replaced with `Menu`, which anchors to its own label |
| Onboarding stretched edge-to-edge on iPad | No max width — a phone layout scaled up | Centered at max 560pt |
| Type too small on iPad | Font sizes were fixed constants | All styles compute at runtime from `UIDevice.userInterfaceIdiom`; iPad gets 13–20% larger |
| Timeline cards looked lost on iPad | Width capped at 430pt | 580pt when viewport width > 700 |
| **Regression:** tapping the empty photo card stopped opening the picker | When the dialog became a `Menu`, only the button was wrapped in it — not the empty state | Wrapped `photoPreview`'s empty state in the same `Menu` |

**Lesson.** "Universal app" is not a build setting, it is a design decision *per screen*.

Two things recur: **explicit max widths** (a phone layout stretched to iPad always looks wrong) and
**44pt minimum tap targets** (Apple's HIG).

Note the regression especially — **swapping a presentation API moves where the interaction lives.**
`confirmationDialog` attaches to a modifier; `Menu` attaches to its label. Changing one meant every
entry point had to be re-checked, and one was missed.

---

## 3. App Store submission rejections

**Commits:** `9115ce8`, `e4585c6`, `2acfcd4` (2026-05-23)

Three failures that only appear at upload time, never during development:

1. **App icon rejected.** The 1024×1024 icon had an alpha channel; App Store Connect rejects
   transparency in the large icon. *Fix:* stripped RGBA → RGB, composited on white (1.5MB → 920KB).
2. **Portrait-only rejected on iPad.** Apple requires an iPad app to support all four orientations
   *unless* it opts out of multitasking. *Fix:* `UIRequiresFullScreen = YES` in Debug and Release.
3. **Malformed privacy strings.** The usage-description strings contained stray quotes and a leading
   space, producing broken values in the built plist.

**Lesson.** Submission bugs are configuration bugs, and the feedback loop is brutally slow — you
find out after a full archive and upload, which can cost a day per rejection.

The response is a **pre-submission checklist**, not better luck. Anything the compiler cannot check
and the simulator cannot show you needs a written gate.

---

## 4. Slideshow video rendered upside down

**Commit:** `5f5c51a` (2026-05-23)

**Symptom.** Exported slideshow videos came out vertically flipped.

**Root cause.** A Y-axis flip applied during the `CVPixelBuffer` copy step.

CoreVideo pixel buffers and UIKit's drawing context have opposite Y origins, so a flip is sometimes
needed. Here the coordinate system had *already* been corrected upstream, and the second flip undid
the correction.

**Fix.** Removed the Y-flip from `renderFrame` and `renderImageFrame`.

**Lesson.** A classic double-correction bug. When bridging frameworks with different coordinate
conventions (UIKit ↔ CoreVideo ↔ AVFoundation), fix orientation in **exactly one place** and know
which one. Two correct-looking fixes in sequence produce a wrong result, and each one reviews well
on its own.

---

## 5. Gesture conflicts and a swipe crash

**Commit:** `7099052` (2026-05-21)

- **Swipe-to-favourite fought the scroll view.** A plain `.gesture` on the card competed with the
  parent ScrollView's pan. *Fix:* `simultaneousGesture` plus a directional guard, so the card only
  claims horizontal movement and vertical drags still scroll.
- **Crash on rapid swiping in Browse.** The card stack indexed into an array that mutated underneath
  the gesture — a fast swipe could read an index that no longer existed. *Fix:* bounds guard before
  access.
- **Browse couldn't be dismissed.** *Fix:* dismiss via `router.path.removeLast` rather than a local
  presentation flag, matching the app's single-source-of-truth navigation.

**Lesson.** Custom gestures inside scroll views need explicit coexistence rules. And any
gesture-driven index into a mutable collection is a crash waiting for a fast user — the bug is not
in the gesture or the array, it is in the assumption that they are in step.

---

## 6. ⭐ AI rate-limit bug — failed generations burned the user's daily quota

**Recorded in `AGENTS.md`; fix visible at `NarrativeGenerationService.swift:134`**

**Symptom.** Free users get 3 AI narratives a day (15 monthly, 30 yearly). If generation failed —
network drop, timeout, server error — the attempt *still* counted.

A user could lose their whole day's allowance without ever receiving a single narrative. On a paid
tier, that is charging someone for nothing.

**Root cause.** The usage counter was incremented when the request was *sent*, not when it
*succeeded*. It was metering the attempt instead of the outcome.

**Fix.** Move the increment to after the awaited call returns successfully:

```swift
let data = try await aiService.generateNarrative(request(for: entry))
usageTracker.recordNarrativeRequest()   // only after success — a failed call costs nothing
repository.updateNarrative(data.narrative, generatedAt: data.generatedAt, for: entry.id)
```

Because it sits after `try await`, a thrown error skips it entirely. No `catch` bookkeeping is
needed — the control flow does the work.

**Lesson.** **Meter the outcome, not the attempt.** Any counter tied to a limit the user paid for
belongs on the success path.

**Why this is a good interview story.** One line moved, with direct money and trust consequences.
It shows you reason about failure modes rather than only the happy path, and the fix is small
enough to explain completely in thirty seconds.

---

## 7. ⭐ Account deletion silently didn't delete

**Task:** `tasks/delete-account-task.md`; shipped in `91ada2f` (2026-07-11)

**Symptom.** "Delete Account" reported success, but the account still existed on the server.

**Root cause.** Supabase's GoTrue `DELETE /auth/v1/user` endpoint does **not** delete the calling
user from a client context. It needs the service-role key, which must never ship in an app binary.

So the client was calling an endpoint that could never work, and treating a non-error response as
confirmation. Two failures stacked: the wrong endpoint, and **treating "no error" as "success."**

**Fix.** A dedicated authenticated Edge Function (`supabase/functions/delete-account`) that:

- accepts only `DELETE` and `OPTIONS` (405 otherwise) and requires an `Authorization` header
- verifies the caller's identity server-side via `/auth/v1/user` with their bearer token
- deletes **only that verified user** via `/auth/v1/admin/users/{user_id}`, using a service-role key
  held in server-side environment variables
- reports success on the client **only after the server confirms**, and preserves the local session
  on any network, auth, config, or server failure so the user can retry

**Lesson.** Two things worth saying out loud:

1. **Privileged operations need a server that holds the privilege.** A client cannot be trusted
   with an admin key, so any design that requires one on-device is already wrong.
2. **Never optimistically report a destructive action as done.** A user who believes their account
   is deleted when it is not has been lied to by the software. That is a trust failure, not just a
   bug — and it is the kind regulators care about.

---

## 8. Shared image was missing the memory's photo

**Commit:** `487dbfa` (2026-05-23)

**Symptom.** Sharing a memory produced a card with the AI narrative on a plain gradient. The actual
photo was absent, which made the feature nearly pointless.

**Root cause.** Not a logic error: `MemoryShareRenderer.render` **had no photo parameter at all.**
The share card had been built as a text-and-gradient design and nobody had revisited it.

**Fix.** Optional photo drawn full-bleed with a dark gradient overlay and white text. Entries with
no photo (mood-backdrop and slideshow memories) keep the original gradient layout unchanged.

**Lesson.** The bug was in the *interface*, not the implementation.

"The function cannot express what the feature needs" is a whole category of bug, and it hides
extremely well **because every line of the existing code is correct.** Code review will not catch
it. Only using the feature will.

---

## 9. Bugs found during the v2 upgrade (2026-08)

### 9.1 ⭐ The verification method was lying

**Symptom.** A task was reported complete and verified. The next real build failed immediately with
missing-symbol errors.

**Root cause.** Verification had been a `swiftc`-based *typecheck* over a file list, not a real
build. A newly added file was never registered in the Xcode target, so:

- the typecheck passed, because it was handed the file explicitly
- the real build failed, because the target did not include it

The verification and the product were looking at two different sets of files.

**Fix.** Two changes. The verification standard became a **real `xcodebuild`**. And after adding any
new file, confirm it appears in the built target's `SwiftFileList` in DerivedData.

**Lesson.** **Verify the real artifact, not a proxy for it.** A proxy that is cheaper than the real
thing is usually cheaper because it skips the step that fails.

This is the rarer skill: noticing that your *method of checking* is wrong, not that your code is
wrong. Everything downstream of a broken check is unverified, including the things that passed.

### 9.2 Share preview re-rendered a 2160×2160 image on every layout pass

**Symptom.** Caught by reading the diff before calling the task done — never shipped.

The themed share sheet called `MemoryShareRenderer.render(...)` directly inside `body`. SwiftUI
re-evaluates `body` on every state change, so a full 2160×2160 image render ran on each pass.

**Fix.** Render once per theme, store it in `@State` via `.task(id: selectedThemeId)`, and disable
the share button until the image is ready.

**Lesson.** In SwiftUI, `body` runs far more often than you think. Anything expensive belongs in
state, keyed to whatever actually changes it. Treat `body` as a pure function that may be called at
any time, for any reason.

### 9.3 A patch script filed eight entries into the wrong place

**Symptom.** While adding the WidgetKit target by hand-editing `project.pbxproj` (no Xcode GUI
available), four files landed in the "Preview Content" group and four build entries in the Resources
phase instead of Sources.

**Root cause.** The script searched for `\t\t<UUID>` to find a definition — but a 4-tab *child
reference* line also contains that 2-tab substring.

**Fix.** Anchor on the definition line's full structure (`\n\t\t<UUID> ... = {`), and re-audit every
placement programmatically rather than by eye.

**Lesson.** When generating code or config by string matching, anchor on something **structurally
unique**, not merely present. And build immediately — a real build is the fastest way to find out a
mechanical edit went wrong.

### 9.4 ⭐ The hero transition pinned the photo wherever the card happened to be

**Fixed 2026-08-19, commit `7123b47`**

**Symptom.** Tapping a memory in the Timeline opened the detail overlay with the photo stuck at the
source card's position on screen: card scrolled to the top → the image sat at the top of the
overlay; card near the bottom → the image sat at the bottom. It was wrong the instant the overlay
appeared, and nothing animated.

**First theory — and the clue that killed it.** The obvious reading is "the transition ends in the
wrong place." But **a hero transition that merely lands wrong still animates.** This one never
moved. That single observation redirected the whole diagnosis: the question stopped being *"why is
the destination wrong"* and became *"is a transition running at all?"*

**Root cause.** `matchedGeometryEffect` is a **hand-off** API, not a "copy the frame once" API. It
assumes exactly one source view is alive at a time:

- the source publishes its frame
- the non-source view is laid out **at** that frame for as long as the source exists
- it only *reads* as a morph because the source then disappears and the non-source view relaxes
  into its own layout

MemoryInk's overlay breaks that assumption. Setting `selectedMemory` does not replace the Timeline —
it adds a layer on top inside the same `ZStack`, and the scroll view stays mounted the whole time,
merely blurred and `allowsHitTesting(false)`.

So the collapsed card (`isSource: true`) never left. The overlay card was not animating *from* the
card's frame; it was being laid out *at* it, permanently, its own centred layout overridden for as
long as the overlay was open. Hence no animation: there was no transition, just a geometry override
applied on the first frame.

**Fix.** Drop `matchedGeometryEffect` for this overlay entirely — the helper, the `@Namespace`, the
`namespace` parameter on `TimelineCard`, and all three call sites. The overlay already carried
`.transition(.opacity.combined(with: .scale(scale: 0.985)))` driven by `withAnimation`. With the
geometry override gone, that transition was simply free to run.

A correct matched-geometry hero here would need a `fullScreenCover`-style presentation where the
Timeline card is genuinely removed while the detail is up — a much bigger change to the overlay's
presentation model than the effect was worth.

**Lesson.** Before reaching for an animation API, check whether your view hierarchy satisfies **the
assumption it is built on**. `matchedGeometryEffect` needs the source to *go away*; an overlay that
keeps everything mounted underneath can never give it that.

And when a transition shows *no motion at all*, stop looking for a wrong destination and start
asking whether a transition is running in the first place.

**Caught by:** device testing by the user, on the app's most-used interaction. A build and a
typecheck both passed happily — the code was valid; the assumption was not.

---

## 10. Bugs found during Part C — the Cinematic Dark rebuild (2026-08-20)

Part C rewrote the app's colour, type and motion system for a dark-first design. Four of these bugs
share a trait worth naming: **they were all invisible to the compiler and to a passing build.**

### 10.1 ⭐ `UIColor(Color)` silently flattens a dynamic colour

**Symptom.** A contrast test reported all twelve mood hues as having *identical* luminance in light
and dark mode — a value of `0.1733` in both, which was exactly the light-mode target.

**Why that number was the clue.** Identical luminance in both appearances is only possible if the
adaptation had already been thrown away before the measurement. The colours were not failing to
adapt; they had been *flattened* somewhere upstream.

**Root cause.** The palette defines each colour as a dynamic `UIColor` (a closure resolved against
the trait collection), wrapped for SwiftUI as `Color(dynamicUIColor)`. Converting *back* with
`UIColor(someColor)` does not recover the closure — it resolves to whatever appearance is current
and returns a static colour. After that round-trip, `resolvedColor(with:)` is a **no-op**: it
returns the same value for both traits.

**What that broke in the product.** `MemoryShareRenderer` bakes mood colour into exported 1080×1080
PNGs. To keep a shared card looking the same for everyone, the renderer pinned colours to a fixed
appearance:

```swift
UIColor(mood.tint).resolvedColor(with: exportTraits)   // looked right, did nothing
```

Because of the flattening, this compiled, ran, and had no effect. A card exported from a phone in
light mode would carry different colours than the same memory exported from a phone in dark mode,
and the recipient would see whichever the sender happened to be in.

**Fix.** Make the dynamic `UIColor` the source of truth (`MemoryInkColors.Raw`) and let `Color`
values wrap *it*, never the reverse. Anything that renders to an image reaches for `Raw` and
resolves it explicitly. `MoodType` gained a `tintRaw: UIColor` for the same reason.

There is now a test asserting that the flattening **still happens** — so if Apple ever changes the
behaviour, the indirection can be removed rather than cargo-culted forever.

**Lesson.** A fix that compiles is not a fix. This one looked correct in review, in the diff, and in
the running app — the only thing that exposed it was measuring the actual output values.

Bridging between two type systems (SwiftUI `Color` ↔ UIKit `UIColor`) can be **lossy in one
direction**, and the loss is silent. Whenever you convert across such a boundary, ask what the
target type cannot represent.

### 10.2 ⭐ The palette requirement was arithmetically impossible

**Symptom.** The design goal was one fixed set of hues that works on both a near-black and a white
background. Every attempt either looked muddy or failed contrast.

**How it was settled.** Instead of continuing to tune by eye, the requirement was checked directly.
WCAG contrast is `(L1 + 0.05) / (L2 + 0.05)` on relative luminance, so the bounds can be solved:

- to clear AA (4.5:1) against the near-black ground, a colour needs luminance **≥ 0.195**
- to clear AA against white, it needs luminance **≤ 0.161**

Those windows **do not overlap**. No fixed colour is accessible in both appearances. It is
arithmetic, not taste, and no amount of tuning would ever have found a value.

Dropping to the 3:1 graphical floor *does* admit fixed values — but only muddy ones. Solving amber
into that window produces `0.59, 0.46, 0.27`, a brown, which defeats the entire design direction.

**Fix.** Every hue adapts: a bright variant for the dark ground, a deeper one for the light ground.
The export-determinism problem that fixed hues were meant to solve moved to where it belonged —
pinning the renderer (§10.1).

**A second bug fell out of the same maths.** Once the hues invert, every filled control in the app
broke. They all drew `.foregroundStyle(.white)` on a hue background, which was safe while hues were
dark. In dark mode a hue is now *bright* — amber sits at 0.51 luminance — so white-on-amber fell to
about **1.9:1**: failing, and painful to look at.

The fix was a new semantic role, `onAccent`, that flips **opposite the fill** rather than opposite
the background: near-black on bright dark-mode hues, near-white on deeper light-mode ones. It was
applied to 17 filled controls across 9 files.

**Lesson.** When a design requirement resists every attempt, check whether it is *satisfiable*
before tuning further. Constraints in accessibility, layout and performance are often arithmetic,
and arithmetic can be solved rather than argued about.

Also: a palette change is never local. Inverting the hues silently changed the correct text colour
for every filled control in the app, and nothing in the compiler knew.

### 10.3 The share theme with light artwork asked for the app's ink

**Symptom.** The `Parchment` share theme would have rendered near-white text on a pale parchment
background — effectively invisible.

**Root cause.** Share cards come in two kinds: scene-backed themes with fixed gradient artwork, and
Classic, which uses the app's own ground colour. The renderer chose ink with a single flag,
`usesLightInk`, falling back to the app palette's `ink` when false.

Once export was pinned to the dark appearance (§10.1), the palette's `ink` resolved to *near-white*.
The `Parchment` scene is light artwork with `usesLightInk: false`, so it asked for the palette ink
and got white.

The deeper error: **card ink was being derived from the app's appearance at all.** A share card is a
fixed picture. Its background is either hardcoded scene artwork or a pinned ground — neither follows
the user's light/dark setting, so neither should its text.

**Fix.** Two fixed constants, `inkOnDarkArtwork` and `inkOnLightArtwork`, chosen by the artwork the
text sits on and nothing else. Classic's flag was also corrected: since Part C its ground is
near-black, so it now truthfully declares that it needs light ink.

While in there, the mood tint was made to carry the badge on *every* theme. It had been falling back
to flat white on light-ink themes, quietly dropping the one piece of colour the card was built
around.

**Lesson.** Ask what a value should *follow*. Text on a rendered image follows the image; text in
the UI follows the UI. Sharing one token between them couples two things that only looked alike.

### 10.4 `Font.custom` fails silently, and nearly deleted the serif from the app

**Symptom.** None — caught before the build, by checking the bundle.

The new type scale was written assuming `Spectral-Regular` and `Spectral-Medium` existed, because a
lighter weight reads better for long-form narrative text. Only `Spectral-SemiBold.ttf` is bundled.

**Why it would not have been noticed.** `Font.custom` **falls back to the system face silently** when
a font name is missing. No crash, no warning, no log. Titles and narrative would simply have rendered
in SF Pro, and the "bundled display serif" the app had shipped two milestones earlier would have
vanished from every screen — with a green build and passing tests.

**Fix.** The helper takes no weight argument at all now; it can only request the face that exists.
Sizes were re-chosen for a semibold face, which reads heavier than a regular at the same point size.
Adding a lighter weight is queued as a real task, since font files also need an `Info.plist` entry
and that file is gitignored.

**Lesson.** Know which APIs fail loudly and which fail quietly. A silent fallback is a *feature* for
robustness and a *trap* for correctness — and it is worth grepping your own assumptions against the
bundle before trusting them.

### 10.5 Three rounds of contrast values that looked right and were not

**Symptom.** Text colours tuned by eye against the standard background passed inspection three times
and failed the arithmetic three times: **4.23:1**, then **4.25:1**, then **4.28:1** — all under the
4.5:1 floor.

**Root cause.** Each round measured the text against the *standard* ground only. But the app has
four surfaces — `parchmentDeep`, `parchment`, `paper`, `paperWarm` — and the worst case is not the
standard one. In dark mode the worst surface is `paperWarm` (the lightest dark surface); in light
mode it is `parchmentDeep` (the darkest light surface).

**Fix.** `tertiaryInk` was solved against the worst surface in each appearance rather than the
common one. The check became a permanent test suite (`PaletteContrastTests`) covering every text
role × every surface × both appearances, plus hue floors, ramp ordering, export determinism, and
`onAccent` on every hue.

**Lesson.** Contrast is not a property of a colour, it is a property of a **pair**. Checking against
the common case will pass while the real worst case fails.

More generally: three rounds of careful human judgement lost to one arithmetic check. When a
correctness property can be computed, compute it — and put the computation somewhere it will run
again, because it will regress silently otherwise.

---

## Patterns across all of these

| Pattern | Where it showed up |
|---|---|
| **Meter and report the outcome, not the attempt** | AI rate limit (§6), account deletion (§7) |
| **Layout systems need constraints, not styling** | Overflow (§1), iPad adaptivity (§2) |
| **Framework boundaries are where bugs live** | Video Y-flip (§4), gesture conflicts (§5), GoTrue client limits (§7), `Color` ↔ `UIColor` (§10.1) |
| **Config bugs surface late and cost the most** | App Store rejections (§3), pbxproj registration (§9.1, §9.3) |
| **Changing a presentation API moves the interaction** | Dialog → Menu regression (§2) |
| **Verify the real artifact, not a proxy** | §9.1, and why every v2/v3 task ends in a real `xcodebuild` |
| **An API's contract assumes a structure — check you provide it** | `matchedGeometryEffect` needing the source to unmount (§9.4) |
| **Silent failure is worse than loud failure** | `UIColor(Color)` flattening (§10.1), `Font.custom` fallback (§10.4) |
| **If a property can be computed, compute it** | Impossible palette (§10.2), contrast floors (§10.5) |

## How bugs actually got caught

1. **Device testing by the user** — every layout, tap-target and iPad bug, plus the hero transition
   (§9.4). No substitute for it.
2. **Automated measurement** — the entire §10 cluster. Three of those four were invisible to a
   build, a review, and a running app.
3. **App Store validation** — three config bugs nothing else would have found.
4. **A real build** — the pbxproj bugs; a typecheck missed one entirely.
5. **Targeted unit tests against real source files** — how the export's privacy guarantees (no photo
   bytes, no EXIF, no GPS) were verified before a test target existed.
6. **Reading your own diff before calling it done** — the 2160×2160 re-render (§9.2) never shipped.

Worth noticing how the mix shifted. Early bugs were caught by *looking* at the app. The Part C bugs
could not be caught that way at all — a wrong-but-plausible colour looks fine to anyone who does not
already know what it should be. As the failure modes got quieter, the verification had to get more
mechanical.
