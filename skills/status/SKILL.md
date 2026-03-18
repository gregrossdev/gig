---
name: gig:status
description: Show current state and suggest the ONE next action to take.
user-invocable: true
---

# /gig:status Skill

## Step 0 — Command Routing

If the user's message matches a natural language command, handle it directly.

For all routed commands below, first read `.gig/STATE.md` and display a context header:
`Version: {version} | Iteration: {iteration} | Status: {status}`

**"decisions"** — Read `.gig/DECISIONS.md` and display all ACTIVE entries as a summary table:
| ID | Decision | Status |
Then STOP.

**"issues"** — Read `.gig/ISSUES.md` and display all OPEN and DEFERRED entries:
| ID | Title | Severity | Status |
If none, say "No open issues." Then STOP.

**"history"** — Read `.gig/STATE.md` Batch History section and display the table as-is. Then STOP.

**"iteration done"** — Update `.gig/STATE.md`: set **Status** to `IMPLEMENTED`. Say: "Iteration marked done. Run `/gig:govern` to validate." Then STOP.

If no command match, proceed to Step 1.

## Step 1 — Read State

Check if `.gig/` exists.

**If NOT present:**
Say: "No gig context. Run `/gig:init` to start." STOP.

**If present:**
Read `.gig/STATE.md`, `.gig/PLAN.md`, `.gig/ROADMAP.md`, `.gig/ISSUES.md`.

## Step 2 — Display Status

Present a compact status block:

```
Version: {version}
Iteration: {N} — {name}
Status:  {status}
Batch:   {last batch title}

Milestone: {name} v{target} ({status})
Iterations: {completed}/{total} complete

Open Issues: {count from ISSUES.md — OPEN or DEFERRED}

Upcoming:
  {list iteration names from ROADMAP.md Upcoming Iterations table, or "None"}

Archived iterations:
  {list from .gig/iterations/ or "None yet"}
```

## Step 3 — Suggest Next Action

Based on current status, suggest exactly ONE next action:

| Status | Suggestion |
|--------|-----------|
| `IDLE` (no milestone) | "Run `/gig:milestone` to create a milestone." |
| `IDLE` (has milestone) | "Run `/gig:gather` to start the next iteration." |
| `GATHERING` | "Gathering in progress. Continue with `/gig:gather`." |
| `GATHERED` | "Run `/gig:implement` to start implementing." |
| `IMPLEMENTING` | "Run `/gig:implement` to continue — next batch: {title}." |
| `IMPLEMENTED` | "Run `/gig:govern` to validate the iteration." |
| `GOVERNING` | "Governance in progress. Continue with `/gig:govern`." |
| `GOVERNED` | "Iteration complete. Run `/gig:gather` for next iteration or `/gig:milestone`." |

Say: "**Next:** {suggestion}"
