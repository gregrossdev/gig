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

**"amend [REQ-X]"** — Context-dependent spec amendment:
- Read `.gig/STATE.md` to check current status.
- **If status is GATHERING (Tier 2):** Read `.gig/SPEC.md`, increment the version header (e.g., `Spec v1.0` → `Spec v1.1`). Append amendment entry to `## Amendments`: `AMD-{N}: Tier 2 — {description}. Affected: {REQ IDs}. Reason: {why}.` Then scan `.gig/DECISIONS.md` for ACTIVE decisions referencing the affected REQ IDs, flag them for re-evaluation, and re-present the decision table for approval. Then STOP.
- **If status is IMPLEMENTING (Tier 3):** Say: "Tier 3 amendment — pausing implementation." Then follow the implement skill's `amend [REQ-X]` interrupt flow (impact analysis + 3 resolution options). Then STOP.
- **Otherwise:** Say: "Amendments are only available during gather or implement phases." Then STOP.

**"debt"** — Read `.gig/DEBT.md` and display all OPEN and TRACKED entries:
| ID | Title | Severity | Area | Status |
If none or file doesn't exist, say "No outstanding technical debt." Then STOP.

If no command match, proceed to Step 1.

## Step 1 — Read State

Check if `.gig/` exists.

**If NOT present:**
Say: "No gig context. Run `/gig:init` to start." STOP.

**If present:**
Read `.gig/STATE.md`, `.gig/PLAN.md`, `.gig/ROADMAP.md`, `.gig/ISSUES.md`, `.gig/SPEC.md` (if it exists).

## Step 2 — Display Status

Present a compact status block:

```
Version: {version}
Iteration: {N} — {name}
Status:  {status}
Batch:   {last batch title}

Milestone: {name} v{target} ({status})
Iterations: {completed}/{total} complete
{If SPEC.md exists and has content beyond the template:}
Spec: {N} stories, {M} requirements ({DRAFT if status is SPECING, LOCKED if SPECCED or later})
{If any requirements have Status=COVERED:}
Coverage: {covered}/{total} requirements

Open Issues: {count from ISSUES.md — OPEN or DEFERRED}
Debt: {count from DEBT.md — OPEN or TRACKED, omit if none}
Verify Later: {count of rows in Verify Later table in STATE.md, or omit if empty}
Backlog: {count of bullet points in BACKLOG.md, or omit line if empty/no file}

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
| `SPECING` | "Spec elicitation in progress. Continue with `/gig:milestone`." |
| `SPECCED` | "Run `/gig:design` for UI/UX prototypes, or `/gig:gather` to start making decisions." |
| `DESIGNING` | "Design in progress. Continue with `/gig:design`." |
| `DESIGNED` | "Run `/gig:gather` to start making decisions." |
| `GATHERING` | "Gathering in progress. Continue with `/gig:gather`." |
| `GATHERED` | "Run `/gig:implement` to start implementing." |
| `IMPLEMENTING` | "Run `/gig:implement` to continue — next batch: {title}." |
| `IMPLEMENTED` | "Run `/gig:govern` to validate the iteration." |
| `GOVERNING` | "Governance in progress. Continue with `/gig:govern`." |
| `GOVERNED` | "Iteration complete. Run `/gig:gather` for next iteration or `/gig:milestone`." |

Say: "**Next:** {suggestion}"
