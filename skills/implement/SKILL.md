---
name: gig:implement
description: Execute the approved plan batch by batch with team-first parallel execution and human-in-the-loop checkpoints.
user-invocable: true
argument-hint: "[batch number]"
---

# /gig:implement Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Read `.gig/STATE.md` and `.gig/PLAN.md`.

**If status is NOT "GATHERED" and NOT "IMPLEMENTING":**
Say: "No approved plan found. Run `/gig:gather` first." STOP.

**If all batches in the active iteration are done:**
Say: "All batches complete. Run `/gig:govern` to validate." STOP.

## Step 2 — Set Up Git Branch

Reference: `.gig/GIT-STRATEGY.md` for full conventions.

If in a git repository and no feature branch exists for this iteration:
1. Ensure `main` is clean (`git status` — no uncommitted changes).
2. Create branch from main: `git checkout -b feature/v0.{N}-{iteration-name}`
3. If not a git repo, skip git operations but continue with state tracking.

If feature branch already exists (resuming), switch to it:
`git checkout feature/v0.{N}-{iteration-name}`

## Step 3 — Analyze Batch Dependencies

Before executing, scan all pending batches and classify:

- **Independent batches** — no dependency chain between them → candidates for parallel team execution.
- **Dependent batches** — must execute sequentially (in-session).

If 2+ independent batches are ready simultaneously, proceed with team mode (Step 4a).
Otherwise, execute the next batch in-session (Step 4c).

## Step 4 — Execute Based on Delegation Mode

### 4a — Team Mode (Parallel)

When 2+ independent batches are ready:

1. For each independent batch, use the Agent tool with `isolation: "worktree"`.
   Each agent receives a prompt containing:
   - The batch description and work items from PLAN.md
   - Relevant ACTIVE decisions from DECISIONS.md
   - Working memory from STATE.md
2. Each agent works on an isolated branch: `feature/v0.{N}-{iteration-name}/batch-{P}`
3. After all agents complete, merge each task branch into the iteration branch:
   `git merge feature/v0.{N}-{iteration-name}/batch-{P}` — resolve conflicts if any.
4. Delete task branches after merge.

If only 1 batch is ready, execute it in-session instead.

### 4b — Subagent Mode (Research)

- Use Agent tool with appropriate subagent_type.
- Feed findings into STATE.md working memory or dependent batches.

### 4c — In-Session Mode (Sequential)

- Work directly in the current session.

## Step 5 — Batch Verification

After completing a batch:
1. Run the batch's test criteria.
2. Check acceptance criteria.
3. If passes: mark batch done.
4. If fails: report what failed, ask user how to proceed (fix/skip/stop).

## Step 6 — Batch Commit

If in a git repo and verification passed:
1. Stage specific files by name (never `git add -A` or `git add .`).
2. Commit with conventional format:
   ```
   {type}(v0.{N}.{P}): {batch description}
   ```
   For unplanned batches, add `[UNPLANNED]` to the commit body:
   ```
   fix(v0.{N}.{P}): {description}

   [UNPLANNED] — inserted during iteration {N} implement.
   ```
3. Per-batch commits give granular rollback.
4. Never force-push. Never rewrite history.

If not in a git repo, skip commit but still update state.

## Step 7 — Update State

After each batch:

1. Update `.gig/STATE.md`:
   - **Version:** increment PATCH (`0.{N}.{P}`)
   - **Status:** `IMPLEMENTING`
   - **Last Batch:** batch title
   - **Last Updated:** today's date
   - Add to **Batch History**
   - Update **Working Memory** with discoveries

2. Update batch status in `.gig/PLAN.md` from `pending` to `done`.

## Step 8 — Batch Checkpoint

Present a checkpoint to the user:
- What was done
- Test criteria results
- What's next

Then say:

> **Checkpoint.** Batch {N}.{P} complete — version `0.{N}.{P}`.
>
> - **Continue** — `next` to proceed to next batch.
> - **Pause** — save state and stop here.
> - **Fix [thing]** — insert unplanned work as next batch.
> - **Revise decision** — reference by ID if something needs to change.

**If user says `fix [thing]`:**
1. Increment PATCH version.
2. Tag as `[UNPLANNED]` in batch history and PLAN.md.
3. Execute the fix.
4. Insert retroactively into PLAN.md so the plan reflects reality.
5. Shift subsequent planned batch versions forward.
6. Resume normal flow.

**If user revises a decision:**
- Update `.gig/DECISIONS.md`: mark old entry AMENDED, append new as ACTIVE.
- Assess impact on remaining batches and adjust if needed.

**If user says continue:** go back to Step 3 for next batch.
**If user says pause:** update STATE and stop.

## Step 9 — Iteration Complete

When all batches are done:
1. Update `.gig/STATE.md`: set **Status** to `IMPLEMENTED`.
2. Say: "All batches implemented. Run `/gig:govern` to validate and complete the iteration."
