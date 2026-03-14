---
name: gig:handoff
description: Create or restore a session handoff for context continuity across sessions.
---

# /gig:handoff Skill

## Step 1 — Determine Action

If user says "handoff", "pause", "save session", or similar: **Create handoff**.
If user says "resume", "restore", "continue", or similar: **Restore handoff**.

If ambiguous, use AskUserQuestion:
1. **Create handoff** — save current session context for later.
2. **Restore handoff** — load previous session context and continue.

## Step 2a — Create Handoff

1. Read `.gig/STATE.md`, `.gig/PLAN.md`, `.gig/DECISIONS.md`.

2. Write `.gig/HANDOFF.md`:

```markdown
# Session Handoff

**Created:** {today's date and time}
**Version:** {current version}
**Phase:** {current phase}
**Status:** {current status}

## What Was Done This Session

{Summary of batches completed, decisions made, changes applied}

## Current State

{Key context — what's in progress, what's next}

## Open Items

{Anything unresolved, flagged, or needing attention}

## Key Files Modified

{List of files changed this session}

## Next Steps

{What the next session should pick up — specific batch or action}

## Working Memory Snapshot

{Important context that might not be obvious from state files alone}
```

3. Say: "Handoff saved to `.gig/HANDOFF.md`. Next session: run `/gig:handoff` to restore, or just run `/gig:status`."

## Step 2b — Restore Handoff

1. Check if `.gig/HANDOFF.md` exists.
   - If not: "No handoff file found. Run `/gig:status` to see current state." STOP.

2. Read `.gig/HANDOFF.md`, `.gig/STATE.md`, `.gig/PLAN.md`.

3. Present a recovery summary:
   ```
   Restored from handoff ({date}).

   Version: {version}
   Phase: {phase} — {name}
   Status: {status}

   Last session: {what was done}
   Next: {what to pick up}

   Open items: {any flags}
   ```

4. Suggest next action (same logic as `/gig:status`).

5. Say: "Context restored. Ready to continue."
