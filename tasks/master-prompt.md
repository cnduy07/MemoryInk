# Codex Master Prompt — Tasks 2–12
> Generated: 2026-05-21
> Hand this entire file to Codex as its instruction set.

---

## Your role

You are the Senior Developer for MemoryInk, an iOS journaling app (SwiftUI + CoreData + Supabase). Read AGENTS.md for all coding rules before writing a single line of code. The full task specs are in `tasks/current-task.md`.

## What you must implement

Tasks 2 through 12 from `tasks/current-task.md`, in the exact order listed below. Task 1 is already complete — do not touch it.

**Implementation order:**

| Step | Task | Key constraint |
|------|------|----------------|
| 1 | Task 2: Search | Independent |
| 2 | Task 3: Reminder Notification | Independent — creates NotificationService needed by Task 9 |
| 3 | Task 4: Mood Filter + Trends | Independent |
| 4 | Task 5: Grid View Toggle | Independent |
| 5 | Task 6: Share as Image | Independent — add share to the ellipsis Menu in MemoryDetailView (alongside Edit/Delete already there) |
| 6 | Task 7: Random Memory | Independent |
| 7 | Task 8: Memory Milestones | Independent |
| 8 | Task 9: On This Day Notification | **Requires Task 3 (NotificationService) to be done first** |
| 9 | Task 10: Dark Mode | Independent |
| 10 | Task 11: Yearly Review | Independent (Task 3 already done at this point) |
| 11 | Task 12: Calendar View | Independent |

## Rules you must follow

### Planning
Before writing any code for a task:
1. Read every file listed in that task's "Files to modify" table
2. State in a comment block what you plan to change and why
3. Only then write the code

### Compile checkpoint (mandatory)
After completing each task, run:
```
xcodebuild -project MemoryInk.xcodeproj -scheme MemoryInk -destination 'generic/platform=iOS Simulator' build
```
**If it fails: stop. Fix the compile error. Do not proceed to the next task until the build is green.**

### Scope discipline
- Touch only the files listed in each task spec
- Do not refactor adjacent code that is not part of the task
- Do not add Swift Packages — all tasks use system frameworks only
- Do not modify CoreData schema under any circumstances
- Do not change subscription/entitlement logic unless the task explicitly requires it
- Do not send photos or raw image data to any network endpoint — ever

### Design system
All UI must use:
- `MemoryInkColors.*` for every color — no hardcoded hex or system colors
- `MemoryInkTypography.*` for every font
- `MemoryInkSpacing.*` for padding/corner radius constants
- Card treatment: `LinearGradient([paper, paperWarm])` background + hairline stroke overlay + optional mood-tint left-edge bar (2pt wide)

### Task 6 note — Share button placement
Task 1-CORRECTION already replaced the detail toolbar with a single `ellipsis.circle` Menu containing "Edit Memory" and "Delete Memory". When implementing Task 6, add "Share Memory" as a third item in that same Menu — do not add a separate toolbar button.

### Task 9 note — dependency
`NotificationService` created in Task 3 must exist before Task 9 modifies it. Since you are implementing them in order, this is automatically satisfied. Do not skip Task 3.

### Task 11 note — premium gate
Yearly Review is gated behind `subscriptionManager.hasPremiumEntitlement`. Free users must see an upgrade prompt, not the generate flow.

## Output format (after all tasks)

For each task, write a short block:

```
### Task N: <name>
- Files changed: <list>
- Behavior: <one sentence>
- Build: passed / failed (and error if failed)
```

Then a final summary of anything that requires manual testing or human review.
