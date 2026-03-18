---
name: gig:milestone
description: Create and complete milestones, manage ROADMAP.md, tag releases.
user-invocable: true
argument-hint: "[create | complete | view]"
---

# /gig:milestone Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and `.gig/ROADMAP.md`.
Display: `Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

## Step 2 — Determine Action

Use AskUserQuestion to present options:

1. **Create new milestone** — set up a new milestone.
2. **Complete current milestone** — verify all iterations done, tag, and archive.
3. **View roadmap** — show milestone/iteration overview.

## Step 3a — Create New Milestone

1. Ask for:
   - **Name:** short descriptive name
   - **Description:** one-line summary

2. **Propose a version** (do not ask — derive it):
   - Read Completed Milestones in `.gig/ROADMAP.md`.
   - No completed milestones: propose `v0.1.0`.
   - Otherwise: increment **minor** from highest completed (e.g., `0.1.0` → `0.2.0`).
   - Small scope (bug fixes, polish): increment **patch** instead (e.g., `0.2.0` → `0.2.1`).
   - **v1.0 guard:** NEVER propose `v1.0.0` or higher. Only the user may declare v1.0.
   - Present: `Proposed version: {version} — Reasoning: {why}`
   - User may adjust.

3. Update `.gig/ROADMAP.md`:
   - Set Current Milestone with name, version, status "in-progress", description.
   - Clear Iterations table.
   - **Preserve** the Upcoming Iterations table — existing entries may be pre-planned for the new milestone.

4. Update `.gig/STATE.md` Working Memory with milestone context.

5. Say: "Milestone created. Run `/gig:gather` to start the first iteration."

## Step 3b — Complete Current Milestone

1. **Verify completion:**
   - Read ROADMAP.md iterations table.
   - All iterations must be "complete" or "verified".
   - If incomplete, list them and STOP.

2. **Check Upcoming Iterations:**
   - Read the Upcoming Iterations table in ROADMAP.md.
   - If entries exist, warn: "Upcoming iterations still queued: {list names}. Complete milestone anyway?"
   - If user says no, STOP.

3. **If all iterations complete (and user confirmed if upcoming exist):**
   - Ask user to confirm: "Ready to complete milestone {name} v{version}?"

4. **After confirmation:**
   - If in a git repo: create annotated tag on main:
     ```
     git tag -a v{version} -m "Milestone: {name}"
     ```
     Reference: `.gig/GIT-STRATEGY.md` for full conventions. Never move or delete tags.
   - Move Current Milestone to Completed Milestones in ROADMAP.md using the rich format:
     ```
     ### v{version} — {Name} (completed {TODAY'S DATE})

     {Description}

     **Iterations:**
     {For each iteration in the Iterations table, format as:}
     {N}. {Name} (v0.{N}.{first-batch}–v0.{N}.{last-batch})
     ```
     Derive version ranges from the Iterations table's "Version Range" column.
   - Clear Current Milestone section.
   - Update STATE.md: set status to `IDLE`, clear iteration/batch.

5. **Push (if remote exists):**
   - Check: `git remote` — if output is non-empty, a remote is configured.
   - Push main and tags: `git push origin main --tags`
   - Report: "Pushed to origin." or note if push fails.
   - If no remote, skip silently.

6. Say: "Milestone v{version} complete. Run `/gig:milestone` to create the next one."

## Step 3c — View Roadmap

1. Read `.gig/ROADMAP.md`.
2. Also list `.gig/iterations/` directory for archived iteration history.
3. Present formatted summary:
   ```
   Current Milestone: {name} v{version} ({status})

   Iterations:
     {list from roadmap table}

   Upcoming:
     {list from Upcoming Iterations table, or "None"}

   Archived:
     {list from .gig/iterations/ directory}

   Completed Milestones:
     v{X.Y} — {name} ({date})
   ```
4. Offer: "What would you like to do next?"
