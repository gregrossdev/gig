---
name: gig:status
description: Show current state and suggest the ONE next action to take.
---

# /gig:status Skill

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
Phase:   {N} — {name}
Status:  {status}
Batch:   {last batch title}

Milestone: {name} v{target} ({status})
Phases:    {completed}/{total} complete

Open Issues: {count from ISSUES.md — OPEN or DEFERRED}

Archived phases:
  {list from .gig/phases/ or "None yet"}
```

## Step 3 — Suggest Next Action

Based on current status, suggest exactly ONE next action:

| Status | Suggestion |
|--------|-----------|
| `IDLE` (no milestone) | "Run `/gig:init` to initialize." |
| `IDLE` (has milestone) | "Run `/gig:gather` to start the next phase." |
| `GATHERING` | "Gathering in progress. Continue with `/gig:gather`." |
| `GATHERED` | "Run `/gig:implement` to start implementing." |
| `IMPLEMENTING` | "Run `/gig:implement` to continue — next batch: {title}." |
| `IMPLEMENTED` | "Run `/gig:govern` to validate the phase." |
| `GOVERNING` | "Governance in progress. Continue with `/gig:govern`." |
| `GOVERNED` | "Phase complete. Run `/gig:gather` for next phase or `/gig:milestone`." |

Say: "**Next:** {suggestion}"
