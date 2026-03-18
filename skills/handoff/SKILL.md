---
name: gig:handoff
description: Create or restore a session handoff for context continuity across sessions.
user-invocable: true
argument-hint: "[create | restore]"
---

# /gig:handoff Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

## Step 2 — Determine Action

If user says "handoff", "pause", "save session", or similar: **Create handoff**.
If user says "resume", "restore", "continue", or similar: **Restore handoff**.

If ambiguous, ask: "Create a handoff or restore one?"

## Step 3a — Create Handoff

1. Read `.gig/STATE.md`, `.gig/PLAN.md`, `.gig/DECISIONS.md`.

2. Gather changed files from git (if in a git repo):
   - If on a feature branch: `git diff main..HEAD --name-only`
   - If on main: `git diff HEAD~5 --name-only`
   - If not in a git repo: skip this section

3. Write `.gig/HANDOFF.md`:

```markdown
# Session Handoff

**Created:** {today's date and time}
**Version:** {current version}
**Iteration:** {current iteration}
**Status:** {current status}

## What Was Done This Session

{Summary of batches completed, decisions made, changes applied}

## Current State

{Key context — what's in progress, what's next}

## Open Items

{Anything unresolved, flagged, or needing attention}

## Key Files Modified

{List from git diff — authoritative, not from memory}

## Next Steps

{What the next session should pick up — specific batch or action}

## Working Memory Snapshot

{Important context that might not be obvious from state files alone}
```

4. Say: "Handoff saved to `.gig/HANDOFF.md`. Next session: run `/gig:handoff restore`, or just run `/gig:status`."

## Step 3b — Restore Handoff

> **Note:** If the SessionStart hook (`load-gig-state.sh`) is installed, STATE.md is already loaded into context on session start. Restore adds the richer handoff context — session summary, open items, next steps — on top of the baseline state.

1. Check if `.gig/HANDOFF.md` exists.
   - If not: "No handoff file found. Run `/gig:status` to see current state." STOP.

2. Read `.gig/HANDOFF.md`, `.gig/STATE.md`, `.gig/PLAN.md`.

3. Present a recovery summary:
   ```
   Restored from handoff ({date}).

   Version: {version}
   Iteration: {iteration} — {name}
   Status: {status}

   Last session: {what was done}
   Next: {what to pick up}

   Open items: {any flags}
   ```

4. Suggest next action (same logic as `/gig:status`).

5. Say: "Context restored. Ready to continue."
