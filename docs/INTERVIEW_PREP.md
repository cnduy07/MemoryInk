# MemoryInk — Interview Preparation

> Answers to the questions that are *about you*, not about the code: why you built this, what you
> learned, and what you learned about working with AI.
>
> Vietnamese edition: [`INTERVIEW_PREP.vi.md`](INTERVIEW_PREP.vi.md)
> Technical detail: [`FEATURES_AND_TASKS.md`](FEATURES_AND_TASKS.md) ·
> [`BUGS_AND_FIXES.md`](BUGS_AND_FIXES.md)
>
> **Last updated:** 2026-08-20

---

## How to use this file

The other two documents cover *what the project is*. This one covers *what you are*, which is what
actually decides interviews once the technical bar is cleared.

**One rule before anything else: do not memorise these as scripts.** A recited answer is audible,
and it collapses on the first follow-up question. Learn the *evidence* behind each answer — the
specific bug, the specific number, the specific decision — and let the sentences come out differently
every time. Evidence survives cross-examination; phrasing does not.

**Where you see 🔵, that is a blank only you can fill.** Those are facts about your own life and
motivation. If you recite something there that is not true, an interviewer who probes will find the
edge of it in two questions, and everything else you said becomes suspect.

---

## 1. "Why did you build this app?"

### Why this question is asked

It is almost never about the app. Interviewers use it to find out: do you build things because you
*want something to exist*, or because a tutorial told you to? Can you identify a problem worth
solving? Do you make decisions, or accept defaults?

A weak answer is "I wanted to practise SwiftUI." That says the app is a means to a résumé. A strong
answer names a real problem, a real person it is for, and a decision you made because of that.

### The shape of a strong answer

1. **The observation** — something you noticed about how people (or you) actually behave
2. **The gap** — why the existing options do not serve it
3. **The one constraint you refused to move on** — this is the part that makes it yours
4. **What it cost you** — evidence the constraint was real, not decorative

That fourth part is what most candidates miss. Anyone can claim a principle. Showing that a principle
*removed options* is what makes it believable.

### 🔵 Fill in: your actual reason

Write two or three honest sentences here in your own words. Prompts, if you need them:

- Do you keep photos you never look at again? Did that bother you?
- Did you try journalling apps and stop using them? What made you stop?
- Is there someone specific you imagined using this — you, family, a friend?
- Was there a moment that made you start, or did it accumulate?

> **Your answer:**
>
> _______________________________________________
>
> _______________________________________________

Whatever you write, it should be sayable in about twenty seconds and be *true*. Do not inflate it.
"I take a lot of photos and never look at them again, and the ones I do look at, I can't remember
what the day actually felt like" is a completely sufficient reason. It does not need to be a
tragedy.

### The raw material the codebase genuinely supports

These are all defensible, because the code proves them. Use whichever match your real motivation.

**The product is defined by a refusal, not a feature.** *"Photos never leave the device"* is a
sentence that removed options rather than adding them. It is why the AI works on Vision labels
instead of images, why there is an Edge Function proxy at all, why the widget reads a snapshot
instead of the database, and why the export contains file names rather than photos. One constraint,
five unrelated design consequences — that is what distinguishes a principle from a slogan.

**You said no to the thing that would have driven growth.** During v2 planning, a reference app was
studied that hooks users with couple-focused social features: a shared space, virtual pets, coins,
in-app messaging. All of it was rejected as gamified and social, because it conflicts with what the
product is for. That is a real trade — those mechanics are *known* to increase retention. Choosing
against them deliberately is a product judgement, and interviewers notice it.

**Milestones are explicitly not streaks.** A streak punishes you for missing a day. MemoryInk's
milestones are anniversaries measured from your first memory — nothing resets, nothing breaks,
nothing is scored. If the point is to make people feel calm about their own past, a mechanic that
makes them feel guilty is not a feature, it is a contradiction.

**There is no analytics SDK.** `AnalyticsService.track()` is a deliberate no-op: the event taxonomy
exists so the code is ready, but nothing transmits. In a journal app, the contents *are* the private
thing.

> **If the interviewer pushes: "isn't that bad for business?"** — take the question seriously rather
> than defending. The honest answer is that it is a real cost, accepted on purpose: without
> analytics you cannot see where users drop off, and without social mechanics you grow more slowly.
> The bet is that a product people trust with their private memories is worth more than one they
> uninstall after the novelty. Whether that bet pays is an open question — saying so is stronger
> than pretending there is no trade-off.

---

## 2. "What did you learn building this?"

Give **two or three** of these, with the specific evidence. Not all of them — a list sounds
rehearsed, depth sounds real.

### 2.1 Frameworks have contracts, not just APIs

The `matchedGeometryEffect` bug (BUGS §9.4) is the cleanest example. The API compiled, the
parameters were correct, and the result was completely wrong — because the effect assumes exactly
one source view is alive at a time, and the app's overlay keeps the Timeline mounted underneath.

**What changed in how you work:** before using an animation or layout API, ask what it *assumes
about your view hierarchy*, not just what arguments it takes. The signature tells you how to call
it; the contract tells you whether it will work.

### 2.2 Layout systems are negotiations

The horizontal overflow bug (BUGS §1) looked like a styling mistake and was not. SwiftUI proposes a
size to each child and asks what it wants; an unbounded proposal met `scaledToFill`, which answered
with the image's intrinsic size — and **`scaledToFill` scales but does not clip.**

**What changed:** when something is the wrong size, the question is never "which padding is wrong"
but "who proposed an unbounded dimension, and which child answered with its intrinsic size?"

### 2.3 Meter the outcome, not the attempt

The rate-limit bug (BUGS §6) charged users for AI generations that failed. One line moved, from
before the network call to after it.

**What changed:** any counter attached to something the user paid for belongs on the success path.
More broadly — when you write a limit, ask what happens when the thing being limited *fails*.

### 2.4 Never report a destructive action optimistically

"Delete Account" said success while the account still existed (BUGS §7), because the client called
an endpoint that could not work from a client context and treated "no error" as "done."

**What changed:** two habits. Privileged operations belong on a server that holds the privilege. And
"no error" is not "success" — confirm the outcome, especially when the user believes something
irreversible just happened.

### 2.5 Verify the real artifact, not a proxy for it

A task was reported complete after passing a typecheck. The next real build failed instantly, because
the new file had never been added to the Xcode target (BUGS §9.1). The check and the product were
looking at different sets of files.

**What changed:** the verification standard became a real `xcodebuild`, every time. And a broader
habit — periodically ask whether your *method of checking* could be wrong, because everything
downstream of a broken check is unverified, including the parts that passed.

### 2.6 If a property can be computed, compute it

Contrast was tuned by eye three times, passed inspection three times, and failed the arithmetic three
times: 4.23, 4.25, 4.28 against a 4.5 floor (BUGS §10.5). Each round measured against the standard
background, but the worst case is a different surface entirely.

**What changed:** accessibility, layout and performance constraints are frequently arithmetic. When
a correctness property can be computed, compute it — and put the computation where it will run
again, because it regresses silently otherwise.

### 2.7 Measurement turns an unbounded task into a bounded one

"The UI doesn't look good" is not actionable. Counting made it actionable: 484 colour references,
`amber` used 43 times, nine other accents sharing 62 between them. **The app already had a dominant
accent and had never committed to it.**

That reframed a suspected 18-screen rewrite into a change to one file plus a sweep.

**What changed:** when a task feels unbounded, look for something countable in it before starting.

### 2.8 Shipping is a separate skill from building

Three App Store rejections (BUGS §3) were all configuration: an alpha channel in the icon, a missing
iPad orientation declaration, malformed privacy strings. None were visible during development, and
each cost a full archive-and-upload cycle to discover.

**What changed:** anything the compiler cannot check and the simulator cannot show you needs a
written checklist, not better attention.

---

## 3. "What did you learn using AI to build this?"

This is the question with the most upside right now, because most candidates answer it badly — either
defensively ("I only used it for boilerplate") or credulously ("it's like having a senior engineer").
You have real evidence for a more interesting answer.

### The one-sentence version

> **AI moved the bottleneck from writing code to verifying it — and most of what I learned was about
> building verification that survives confident, plausible, wrong output.**

### 3.1 The failure mode is not bad code. It is *plausible* code

The Part C bugs are the whole argument. Every one of them compiled, passed review, and ran:

- `UIColor(Color).resolvedColor(with:)` — looked like it pinned export colours to a fixed
  appearance. It silently did nothing, because the conversion flattens the dynamic colour first. A
  share card would have followed whichever appearance the sender's phone was in.
- `Font.custom("Spectral-Regular")` — would have removed the serif typeface from every screen in the
  app, because `Font.custom` falls back to the system font *silently* when a name is missing. Green
  build. Passing tests. No warning.

**The lesson:** the risk profile changed. Traditional bad code fails loudly — it crashes, it does not
compile, it throws. AI-assisted code tends to fail *quietly*, because it is pattern-correct. It
looks exactly like the code that works.

That means "it compiles and looks right" stopped being evidence of anything, and I had to replace it
with measurement.

### 3.2 Plans are confidently wrong, and the fix is evidence, not argument

The Part C plan — which I wrote and approved before implementation — contained two errors:

1. *"Delete the nine redundant accent colours."* They were the mood system. `MoodType` maps six of
   them to moods; `rosewood` was also the destructive colour and `sage` the success colour. Deleting
   them would have deleted the feature a later step was meant to preserve.
2. *"Keep the hues fixed so exported images stay deterministic."* Arithmetically impossible. Clearing
   AA contrast on near-black needs luminance ≥ 0.195; on white, ≤ 0.161. The windows do not overlap.

Neither error was caught by reading the plan again. Both were caught by *checking against the actual
codebase and the actual maths.*

**The lesson:** a confident plan is not a verified plan. Before executing one, check its claims
against the repository — grep for what it says is unused, compute what it says is possible.

### 3.3 Write the constraints down, because context does not persist

The project has a rulebook (`AGENTS.md`) stating things that must never change: photos never leave
the device, no analytics SDK, pricing and entitlement IDs need explicit approval, no features from
future phases.

This exists because an AI session has no memory of yesterday's reasoning. Constraints that live only
in your head get quietly violated by the next session, which will produce something reasonable-looking
that breaks a rule nobody restated.

Concrete example: when Part C changed the palette, the rulebook still said *"Color: warm neutrals,
film tones."* That line was updated **and the superseded rule was recorded rather than deleted**, so
a future session cannot restore the old palette from an old document and think it is fixing a
regression.

**The lesson:** with AI in the loop, undocumented constraints are not constraints. Writing the rule
down is part of enforcing it.

### 3.4 Specify before generating, or scope drifts

Every task started as a written spec: files to be touched named explicitly, binary success criteria,
and anything needing approval flagged *before* code was written.

Without that, the natural failure is a task that quietly grows — you ask for a bug fix and get a
refactor of three neighbouring files, all of it plausible, none of it requested.

**The lesson:** the specification is where you exercise judgement. Generation is cheap; deciding what
should exist is not.

### 3.5 Cheap implementation changes what is worth building

The palette contrast suite tests every text role against every surface in both appearances, plus hue
floors, ramp ordering, export determinism, and a guard asserting that plain white *would* fail. By
hand, that is tedious enough that most projects check a few colours and move on.

**The lesson:** when implementation gets cheaper, the correct amount of verification goes *up*, not
down. The tempting conclusion is "I can build more features now." The more useful one is "I can
afford rigour that used to be impractical."

### 3.6 What AI could not do, and what that clarified

Worth being precise here, because it is the part that shows judgement:

- **It could not tell whether the app felt calm.** Contrast is arithmetic and it is proven. Whether
  the result feels like the product it is supposed to be needed a human looking at a screen.
- **It could not make the product decisions.** Rejecting the reference app's gamification, choosing
  milestones over streaks, deciding not to ship analytics — none of those are technical questions,
  and all of them define what the app is.
- **It could not catch the hero transition bug** (BUGS §9.4). Build passed, typecheck passed, the
  code was valid. It took using the app on a device.

**The lesson:** the work that stayed human was direction, judgement, and confirmation against
reality. That is a smaller share of the keystrokes and a larger share of what determines whether the
product is any good.

---

## 4. "Did you write this yourself, or did AI write it?"

You will get some version of this. Answer it directly and without apology.

### What not to do

**Do not minimise** ("I only used it for autocomplete") — it is easy to disprove, and it makes the
one honest thing you said the thing that was false.

**Do not overclaim in the other direction** either. "AI wrote it" throws away everything you actually
did.

### The honest, strong framing

> "I used Claude Code as the implementer, and I acted as the engineer directing it — I set the
> constraints, wrote the specs, made the product decisions, and verified the output. That last part
> turned out to be most of the work, because the failure mode isn't broken code, it's code that
> compiles and looks right and silently does nothing."

Then give one concrete example. The `UIColor(Color)` flattening bug is the best one, because it
proves the point in thirty seconds: the fix compiled, looked correct in review, ran without error,
and did nothing at all. A test measuring actual output values is what caught it.

### Why this answer works

It is verifiable — the repository has the specs, the rulebook, the test suites, the bug write-ups
where plans were wrong and got corrected. And it answers the question the interviewer is actually
asking, which is not "did you type every character" but **"if this codebase breaks, can you fix
it?"**

The evidence that you can: you found bugs the tools did not, you rejected two plans that were
confidently wrong, and you can explain any decision in the codebase down to the arithmetic.

### If they seem hostile to AI use

Do not argue about whether AI is legitimate. Move to ground that is not in dispute:

> "Fair — the way I'd judge it is whether I understand the system well enough to change it. Pick any
> file and ask me why it's built that way."

That is an offer very few candidates can safely make, and making it is worth more than any argument.

---

## 5. Other questions worth having ready

### "What's the most difficult technical decision you made?"

The widget data path. Two options: move the Core Data store into the App Group container so the
widget reads live data, or write a small snapshot file the widget reads instead.

Moving the store is architecturally cleaner — one source of truth, always current. It also requires
migrating **every existing user's journal**, and a migration bug in a journal app costs people their
memories.

The snapshot won, because the widget only needs a mood, a thumbnail, and a day count. The cleaner
architecture bought nothing that mattered here, and the risk was unbounded. **The store never moves.**

Good answer because the reasoning is about *risk versus benefit*, not about which design is prettier.

### "What would you do differently?"

Test coverage of the UI layer, and earlier. The palette, export and milestone logic are covered; the
SwiftUI views are verified by building and looking at them.

The Part C bugs are exactly what that gap lets through — a plausible-but-wrong colour looks fine to
anyone who does not already know what it should be. The response was to automate what could be
automated rather than promise to look harder, but that only happened after three rounds of hand-tuned
values failed the arithmetic.

### "How do you handle a bug you can't reproduce?"

Use the hero transition (BUGS §9.4) — it was reproducible, but the diagnosis is the interesting part.
The clue was the *absence* of something: there was no animation at all. A transition that merely ends
in the wrong place still animates. That single observation redirected the whole investigation from
"why is the destination wrong" to "is a transition running at all?"

The transferable idea: pay attention to what is *missing* from a symptom, not just what is wrong
about it.

### "How do you decide what not to build?"

Concrete answer available: the reference app's social and gamification features, all deliberately
rejected during v2 planning despite being the mechanics most likely to drive retention.

The test used was whether a feature fits what the product is *for*. A journal that makes you feel
guilty for missing a day is working against its own purpose, no matter what it does to the metrics.

### "Tell me about a time you were wrong."

Part C, twice in one task (see §3.2 above). Both errors were mine, both were caught by measuring
rather than by opinion, and both are written into the project's documentation rather than quietly
corrected.

The last part matters — the docs record *"the plan said X, here is why X was wrong."* That is a habit
worth demonstrating.

### "How do you work with people who disagree with you?"

If you have no team example, be honest and use the closest real thing: when a plan and the evidence
disagreed, the evidence won, and it was written down so the reasoning outlived the disagreement.

Do not invent a team conflict. A fabricated example is worse than no example, and this question is
usually followed by "what did they say next?"

### "Why should we hire you?"

Do not answer with adjectives. Answer with the shape of what you did:

> "I shipped a real product to the App Store alone — design, iOS, a backend proxy, subscriptions,
> and the App Store process. And I can show you the parts where I was wrong and how I found out,
> which I think matters more than the parts that went well."

---

## 6. Questions to ask them

Asking nothing suggests you do not care. Ask two or three of these — and listen to the answer rather
than waiting to talk.

- **"How do you verify work here?"** Tests, review, QA, staging? You have a real opinion on this now
  and it opens a genuine conversation.
- **"What does your team's stance on AI-assisted development look like in practice?"** Not "do you
  allow it" — how the review process actually changed, if it did.
- **"What's the last bug that took someone more than a day, and what made it hard?"** Tells you more
  about the codebase than any architecture question.
- **"What would I own in the first six months?"** Filters real roles from vague ones.
- **"What does someone who succeeds here do differently from someone who struggles?"** Often
  produces an unusually honest answer.

---

## 7. Traps to avoid

**Do not claim you built it without AI.** It is unnecessary, it is disprovable, and it converts a
strength into a lie.

**Do not present a bug as harder than it was.** If you inflate one, the follow-up questions get
uncomfortable fast. The rate-limit bug is one line — say so. Its value is the reasoning, not the
difficulty.

**Do not say "no bugs" or "nothing I'd change."** You have four documented Part C bugs and an honest
weakest-part answer. Use them. Candidates with no failures read as either inexperienced or
uninterested in their own work.

**Do not recite architecture as a list.** "SwiftUI, MVVM, Core Data, Supabase" tells them nothing.
"Core Data is the source of truth because a sync bug in a journal app losing entries would be
unforgivable" tells them how you think.

**Do not oversell the scale.** It is a solo project: 78 files, ~14,100 lines, one third-party
dependency, live on the App Store. That is genuinely respectable. Inflating it invites scrutiny it
does not need.

**Do not skip the privacy story.** It is the strongest structural thing about the project — one
constraint visibly shaping five unrelated decisions — and it is easy to forget because it feels
obvious to you now.

---

## 8. The thirty-second version

If you get one chance to describe the project:

> "MemoryInk is a private iOS journal — you save a photo and a mood, and AI writes a short reflection
> about that moment. The constraint that defines it is that photos never leave your device, so the AI
> works from on-device Vision labels and metadata, never the image. It's live on the App Store,
> built solo in SwiftUI with Core Data as the source of truth and a Supabase Edge Function so the
> API key never ships in the app. The part I find most interesting to talk about is the bugs that
> compiled and looked correct and did nothing."

That last sentence is bait, and it is bait for a conversation you are well prepared to have.
