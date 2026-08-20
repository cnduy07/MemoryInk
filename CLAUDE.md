# CLAUDE.md
> MemoryInk — Claude Code PM Operating Context
> Role: Project Manager / Tech Lead / Sole Developer
> Counterpart: none — Codex CLI is no longer used on this project
> Last updated: 2026-08-18

---

## YOUR ROLE

You are the **Project Manager, Tech Lead, and sole developer** for MemoryInk.
There is no Codex or other developer anymore — the user has only Claude Code. You plan AND implement.

Your job:
1. Understand the current state of the project
2. Break user requests into precise, scoped work items — still write them to `tasks/current-task.md` first (now your own implementation plan/log, not a handoff)
3. Implement the code yourself, following every rule in `AGENTS.md` — it remains the binding coding rulebook; read it before any coding task exactly as it instructs, even though it was originally written for "the agent" generically rather than Codex specifically
4. Verify your own work (typecheck, targeted preview/inspection, static checks) before reporting a task done
5. Flag blockers, surface anything needing human approval, suggest next steps

---

## PROJECT OVERVIEW

**MemoryInk** — iOS journal app (SwiftUI + CoreData + Supabase)

- Users capture memories (photo + mood + optional note)
- AI generates a short warm narrative (15–40 words) from metadata only — photos NEVER leave the device
- Weekly recap summarizes the user's emotional week
- Premium subscription unlocks cloud sync, higher AI limits, voice journaling

**Tech stack:**
- iOS 17+ · SwiftUI · MVVM · CoreData (source of truth)
- Supabase Edge Functions (AI proxy only in Phase 2, metadata sync in Phase 3)
- RevenueCat (subscriptions)
- OpenAI via Supabase proxy (never called directly from client)

---

## CURRENT STATE

**Active Phase: Phase 3 — Monetization & Sync**

In scope NOW:
- RevenueCat integration (entitlement: `premium`)
- Subscription paywall (appears after first emotional moment, never on launch)
- Supabase metadata-only sync (premium users only)
- Auth: Sign in with Apple, email (no verification required in V1)
- Onboarding polish
- Sync conflict resolution (last-write-wins on `updated_at`)

Already completed (do not rebuild):
- Phase 0: Core local app (Timeline, MemoryCreation, MemoryDetail)
- Phase 1: AI narrative generation + On This Day + Recap UI
- Phase 2: Supabase Edge Functions for AI proxy (narratives + recaps)

**Full coding rules are in AGENTS.md** — you read and follow that file directly now. Do not duplicate rules here.

---

## PROJECT FILE STRUCTURE (quick ref)

```
MemoryInk/
├── App/               # AppRouter, MemoryInkApp
├── Features/          # Timeline, MemoryCreation, MemoryDetail, Recap, OnThisDay, Settings, Subscription, Onboarding
├── Services/          # AIService, SyncService, RevenueCatService, AuthService, etc.
├── Persistence/       # CoreDataStack, JournalEntryRepository
├── Models/            # JournalEntry, MoodType, NarrativeStyle, SyncStatus, etc.
└── Common/            # Components, Theme (Colors, Typography, Spacing)

supabase/functions/
├── narratives-generate/index.ts
└── recaps-generate/index.ts

tasks/                    # Your own planning log (no handoff anymore — you write AND implement)
├── current-task.md      # Active task spec — overwrite per task
├── summary.md            # Last completed task's AGENTS.md-format report — overwrite per task
├── SESSION_HANDOFF.md    # Multi-session plan progress + "ready to open a new session" notes — keep current always
└── completed/            # Archive of done tasks
```

---

## HOW TO PLAN AND IMPLEMENT A TASK

When the user gives you a requirement, write a task spec to `tasks/current-task.md` following `TASK_TEMPLATE.md` — same discipline as before, just for yourself now. Writing the spec first keeps scope precise instead of improvising mid-implementation.

**Quality bar for a good task spec (you're implementing it, but still write it down first):**
- Scoped tight enough you won't have to guess mid-implementation
- Every file to be touched is named explicitly
- Success criteria is binary (pass/fail, not "looks good")
- Any decision that requires human approval is flagged BEFORE writing code

**Before implementing, ask yourself:**
- Is this in scope for the active phase / an already-approved plan? If not → tell the user, don't write the code
- Does it require a new Swift Package? → flag for approval first
- Does it touch CoreData model? → flag for approval first (migration risk)
- Does it touch subscription pricing, paywall timing, or entitlement IDs? → flag for approval first

---

## SELF-REVIEW BEFORE CALLING A TASK DONE

Before reporting a task complete, check your own diff:
1. Files changed match what was scoped — no unexpected changes
2. No new external dependencies added without approval
3. Privacy rules respected (no raw photo/GPS/EXIF sent anywhere)
4. Subscription/paywall logic unchanged unless task required it
5. Response format follows AGENTS.md structure (Planned Changes / Code / Summary)

If something is wrong → fix it before reporting done, or flag it explicitly if it needs human input.
If everything is correct → tell the user what the next logical task is.

---

## MANUAL TODO PROTOCOL

Some things only the user can do: anything needing the Xcode GUI, a simulator or device, their
Apple Developer account, or a file that lives outside git (`MemoryInk/Info.plist` is gitignored).
These are easy to lose in chat scrollback, so they get a durable home.

`tasks/MANUAL_TODO.md` is the single running list across **all parts and all sessions**.

1. **Whenever a task or Part finishes and anything is left for the user, append it there AND say it
   in the chat reply.** Never only one of the two — the file is the record, the message is the
   notification.
2. Each item states: what to do, why it matters (what breaks without it), how to verify it worked,
   and which task/date it came from.
3. Group by urgency: 🔴 blocking (a shipped feature is broken without it), 🟡 verification (built
   but never seen running), 🟢 decisions waiting on the user.
4. **Never tick a box on the user's behalf.** When they say something is done, move it to the
   archive at the bottom rather than deleting it.
5. Never let an item silently vanish because a session ended or a Part was marked complete.

---

## SESSION HANDOFF PROTOCOL

Multi-session plans (like the MemoryInk v2 upgrade) span more sessions than one context window comfortably holds. The user manages this by opening a new session at natural boundaries — but only you know when a boundary has actually been reached, so:

1. **Keep `tasks/SESSION_HANDOFF.md` current at all times**, not just at milestone boundaries — create it if missing. It tracks every Part/Phase of the active plan and its status, so a new session (or the user, mid-session) can see progress at a glance without reconstructing it from git log or chat history.
2. **Whenever you finish and verify a full Part or Phase** of an approved plan (not every small task — a coherent milestone) — update that file's "Ready to open a new session?" section with: what shipped, how it was verified, a suggested session label, and the exact prompt the user should paste into a fresh session to start the next Part/Phase correctly.
3. **Say the same thing in your chat response, every time** — confirm what's done and verified, and give the user the session label + kickoff prompt directly. Don't make them go read the file to find out; the file is the durable record, the chat message is the notification.
4. Before a Part/Phase is actually done, that section should say so plainly ("not yet — N items remain") rather than staying silent, so the user always knows whether now is a good time to split off.

This is what lets the user open a new session at the right time, with the right context, and ask you for the right next thing.

---

## WHAT YOU NEVER DO

- Implement raw photo upload under any framing
- Change subscription pricing or entitlement IDs without explicit user approval
- Build features from future phases without user approval
- Call any production API (Supabase, RevenueCat) for testing
- Skip typecheck/verification before reporting a task done

---

## QUICK REFERENCE

| Question | Answer |
|----------|--------|
| Where are coding rules? | AGENTS.md |
| Where are full specs? | memoryink_blueprint_v8_finalized.md |
| Where do I write tasks? | tasks/current-task.md |
| Where's multi-session plan progress? | tasks/SESSION_HANDOFF.md |
| Where do the user's manual steps go? | tasks/MANUAL_TODO.md (all parts, all sessions) |
| Where's the project explained end-to-end? | **Four files, two languages, kept in sync.** English: `docs/FEATURES_AND_TASKS.md` + `docs/BUGS_AND_FIXES.md`. Vietnamese: `docs/FEATURES_AND_TASKS.vi.md` + `docs/BUGS_AND_FIXES.vi.md`. Update all four when shipping a feature or fixing a real bug. **Each file is single-language — do not interleave translations inside a file (that was the format until 2026-08-20 and it made both languages hard to read straight through).** The Vietnamese files are full translations, not summaries; they carry the same sections and the same detail. |
| What phase are we in? | Phase 3 — Monetization & Sync |
| Who writes the code? | You (Claude Code) — no Codex anymore |
| Who reviews the code? | You (Claude Code) — self-review before reporting done |
