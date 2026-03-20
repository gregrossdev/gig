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

If `.claude-plugin/plugin.json` exists, read the `name` and `version` fields and append to the header:
`| Plugin: {name} v{version}`

If `.claude-plugin/plugin.json` does not exist, skip silently.

## Step 1 — Guard Check

Read `.gig/STATE.md`, `.gig/PLAN.md`, and `.gig/DECISIONS.md`.

**If status is NOT "GATHERED" and NOT "IMPLEMENTING":**
Say: "No approved plan found. Run `/gig:gather` first." STOP.

**If all batches in the active iteration are done:**
Say: "All batches complete. Run `/gig:govern` to validate." STOP.

## Step 2 — Set Up Git Branch

Reference: `.gig/GIT-STRATEGY.md` for full conventions.

If in a git repository and no feature branch exists for this iteration:
1. Check `git status` for uncommitted changes.
   - **If dirty:** Say: "Working directory has uncommitted changes. Stash or commit them before proceeding." STOP.
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
   - Structural context from ARCHITECTURE.md (project stack, patterns, conventions)
   - Reference: `.gig/GIT-STRATEGY.md` for commit and branch conventions
2. Each agent works on an isolated branch: `feature/v0.{N}-{iteration-name}/batch-{P}`
3. After all agents complete, merge each task branch into the iteration branch:
   `git merge feature/v0.{N}-{iteration-name}/batch-{P}` — resolve conflicts if any.
4. Clean up after each merge:
   - Remove the worktree: `git worktree remove {worktree-path}`
   - Delete the task branch: `git branch -D feature/v0.{N}-{iteration-name}/batch-{P}`

**If a team agent fails:**
- Report the error and which batch failed.
- Ask the user:
  - **Retry** — relaunch the agent for that batch.
  - **Fix in-session** — execute the failed batch directly in the current session.
  - **Skip** — mark batch as skipped and continue (must address in governance).

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
   - **Plugin Version:** if `.claude-plugin/plugin.json` exists, read its `version` field and update this row. Otherwise leave as `—`.
   - Add to **Batch History**
   - Update **Working Memory** with discoveries

2. Update batch status in `.gig/PLAN.md` from `pending` to `done`.

## Step 8 — Auto-Continue

After a batch passes verification, show a brief status line and auto-continue to the next batch:

> `Batch {N}.{P} done — {batch title}. Continuing...`

**Do NOT stop. Do NOT prompt. Proceed directly to Step 3 for the next batch.**

The user can interrupt at any time by typing. If they do:
- **`fix [thing]`** — Increment PATCH, tag `[UNPLANNED]`, execute the fix, insert into PLAN.md, shift subsequent versions, resume.
- **`revise [decision ID]`** — Update DECISIONS.md (mark old AMENDED, append new as ACTIVE), assess impact on remaining batches.
- **`pause`** — Update STATE and stop.

**If verification FAILS (Step 5):** STOP and present the error:

> **Batch {N}.{P} failed verification.**
> {What failed and why}
>
> - **Fix** — attempt to fix the issue and re-verify.
> - **Skip** — mark batch as skipped (must address in governance).
> - **Stop** — save state and halt implementation.

Wait for user direction before proceeding.

## Step 9 — Iteration Complete

When all batches are done:
1. Update `.gig/STATE.md`: set **Status** to `IMPLEMENTED`.
2. Say: "All batches implemented. Run `/gig:govern` to validate and complete the iteration."
