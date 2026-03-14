---
name: gig:milestone
description: Create and complete milestones, manage ROADMAP.md, tag releases.
user-invocable: true
argument-hint: "[create | complete | view]"
---

# /gig:milestone Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and `.gig/ROADMAP.md`.
Display: `Version: {version} | Milestone: {name} v{target}`

## Step 1 — Determine Action

Use AskUserQuestion to present options:

1. **Create new milestone** — set up a new milestone.
2. **Complete current milestone** — verify all phases done, tag, and archive.
3. **View roadmap** — show milestone/phase overview.

## Step 2a — Create New Milestone

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
   - Clear Phases table.

4. Update `.gig/STATE.md` Working Memory with milestone context.

5. Say: "Milestone created. Run `/gig:gather` to start the first phase."

## Step 2b — Complete Current Milestone

1. **Verify completion:**
   - Read ROADMAP.md phases table.
   - All phases must be "complete" or "verified".
   - If incomplete, list them and STOP.

2. **If all phases complete:**
   - Ask user to confirm: "Ready to complete milestone {name} v{version}?"

3. **After confirmation:**
   - If in a git repo: create annotated tag on main:
     ```
     git tag -a v{version} -m "Milestone: {name}"
     ```
     Reference: `.gig/GIT-STRATEGY.md` for full conventions. Never move or delete tags.
   - Move Current Milestone to Completed Milestones in ROADMAP.md:
     ```
     ### v{version} — {Name} (completed {TODAY'S DATE})
     {Description}
     Phases: {list of phase names from phases/ directory}
     ```
   - Clear Current Milestone section.
   - Update STATE.md: set status to `IDLE`, clear phase/batch.

4. Say: "Milestone v{version} complete. Run `/gig:milestone` to create the next one."

## Step 2c — View Roadmap

1. Read `.gig/ROADMAP.md`.
2. Also list `.gig/phases/` directory for archived phase history.
3. Present formatted summary:
   ```
   Current Milestone: {name} v{version} ({status})

   Phases:
     {list from roadmap table}

   Archived:
     {list from .gig/phases/ directory}

   Completed Milestones:
     v{X.Y} — {name} ({date})
   ```
4. Offer: "What would you like to do next?"
