---
name: gig:govern
description: Verify, validate, track issues, archive iteration, summarize status, and suggest next iteration ideas.
user-invocable: true
---

# /gig:govern Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Read `.gig/STATE.md`, `.gig/PLAN.md`, and `.gig/DECISIONS.md`.

**If status is NOT "IMPLEMENTED" and NOT "IMPLEMENTING":**
Say: "Nothing to govern. Run `/gig:implement` first." STOP.

## Step 2 — Manual Verification

Before running automated checks, present a quick verification card so the user can manually confirm the latest work:

1. Read `.gig/PLAN.md` and identify the most recently completed batch(es).
2. For each, extract the test criteria and acceptance criteria.
3. Present a concise checklist:

```
### Quick Verify (optional)

The latest batch implemented: **{batch title}**

Try these to confirm it works:
- [ ] {Step derived from test criteria — something the user can do in 30 seconds}
- [ ] {Another step if applicable}

Reply **"verified"** or **"skip"** to continue with governance.
```

**If user says "verified":** Note it in the governance report and proceed.
**If user says "skip":** Proceed without manual verification.

Do NOT block on this — it's optional. If the user has already confirmed or the batch is trivial (docs, config), skip automatically and proceed.

## Step 3 — Run Automated Tests

Auto-detect project tooling and run test suites:

| Look for | Run tests | Run linter |
|----------|----------|------------|
| `package.json` | `npm test` | `npm run lint` |
| `Cargo.toml` | `cargo test` | `cargo clippy` |
| `pyproject.toml` | configured commands | configured commands |
| `Makefile` | `make test` | `make lint` |
| `deno.json` | `deno test` | `deno lint` |

If no tooling detected, note "No automated checks configured" and proceed.
Capture all results (pass/fail/warnings/error output).

## Step 4 — Validate Acceptance Criteria

For each batch in `.gig/PLAN.md`:
1. Read the acceptance criteria.
2. Check implementation against each criterion.
3. Mark each: PASS or FAIL with evidence.
4. Cross-reference with ACTIVE decisions — does implementation match?

## Step 5 — Decision Audit

Compare every ACTIVE decision against actual implementation:

| Decision ID | Decision | Matches? | Notes |
|------------|----------|----------|-------|

For mismatches:
- Determine if deviation was necessary (discovered during build).
- Propose either: fix code to match decision, OR revise the decision.

## Step 6 — User Acceptance Testing (UAT)

Present a guided UAT checklist from the plan's acceptance criteria.
For each item, ask the user to verify:

```
UAT-{N}: {Description}
Expected: {What should happen}
Result: [ PASS | FAIL | SKIP ]
Severity (if FAIL): [ Blocker | Major | Minor | Cosmetic ]
```

## Step 7 — Issue Tracking

For every failure discovered in Steps 3-6, log an issue in `.gig/ISSUES.md`.

Entry format:
```
## ISS-{N}: {Title}

**Severity:** Blocker | Major | Minor | Cosmetic
**Source:** UAT-{N} | Decision Audit | Automated Tests | Lint
**Iteration:** {current iteration number}
**Status:** OPEN
**Description:** {What's wrong}
**Evidence:** {Error output, failing test, mismatched behavior}
**Batch:** — (assigned when fix starts)
```

**Severity rules:**
- **Blocker** — Cannot ship. Must fix before iteration completes.
- **Major** — Significant issue. Should fix before iteration completes.
- **Minor** — Small issue. Can defer to a future iteration.
- **Cosmetic** — Polish item. Defer to a future iteration.

## Step 8 — Governance Report

Present a complete report AND write it to `.gig/GOVERNANCE.md`:

```markdown
# Governance Report

> Iteration {N} — {Name}
> Date: {today's date}
> Version: v0.{N}.{last-P}

## Test Results
Automated: {passed}/{total} tests  {PASS|FAIL}
Lint: {PASS|FAIL|N/A}

## Acceptance Criteria
{Each criterion with PASS or FAIL}

## Decision Audit
{Table from Step 5 — highlight deviations}

## UAT Results
{Summary: N passed, N failed, N skipped}

## Issues Found
| ID | Title | Severity | Status |
|----|-------|----------|--------|
{All issues from this governance round}

Blockers: {count}
Majors: {count}
Deferred (Minor/Cosmetic): {count}

## Verdict
{APPROVED | APPROVED WITH DEFERRALS | BLOCKED}
```

Write this report to `.gig/GOVERNANCE.md` (overwrite any existing content). This file will be archived with the iteration.

## Step 9 — Update State

Update `.gig/STATE.md`:
- Update batch history entries with final status.
- Update Working Memory with governance results.

## APPROVAL GATE

**If Blockers or Majors exist:**

Present the governance report, then:

> **Issues require attention.**
>
> - **Fix all** — I'll create unplanned batches for all Blocker/Major issues and go back to `/gig:implement`.
> - **Fix blockers only** — defer Majors to a future iteration.
> - **Defer all** — override severity and defer everything (not recommended for Blockers).
> - **Revise decisions** — reference by ID to update.

**STOP. Wait for user direction.**

After user chooses:
1. For issues being fixed:
   - Update issue status to `FIXING` in ISSUES.md.
   - Create unplanned batches in PLAN.md for each fix.
   - Update STATE.md status to `IMPLEMENTING`.
   - Say: "Fix batches created. Run `/gig:implement` to fix, then `/gig:govern` again."
   - STOP.

2. For issues being deferred:
   - Update issue status to `DEFERRED` in ISSUES.md.
   - These persist in ISSUES.md and carry forward to future iterations.

**If NO Blockers or Majors (or all resolved):**

Present the governance report, then:

> **Does this look good?**
>
> - **Approve** — reply "approve" to archive iteration and merge.
> - **Rollback** — revert specific batches or the entire iteration.

**STOP. Do not merge. Do not commit. Do not push. Wait for approval.**

## After Approval — Archive Iteration

### 1. Create Iteration Archive

Create directory: `.gig/iterations/v0.{N}-{iteration-name}/`

Copy into the archive:
- `.gig/PLAN.md` → `.gig/iterations/v0.{N}-{iteration-name}/PLAN.md` (frozen snapshot)
- Extract this iteration's decisions from `.gig/DECISIONS.md` → `.gig/iterations/v0.{N}-{iteration-name}/DECISIONS.md`
- Extract this iteration's resolved issues from `.gig/ISSUES.md` → `.gig/iterations/v0.{N}-{iteration-name}/ISSUES.md`
- `.gig/GOVERNANCE.md` → `.gig/iterations/v0.{N}-{iteration-name}/GOVERNANCE.md` (frozen snapshot)

### 2. Clear Active Files

- Reset `.gig/PLAN.md` to template state (no active iteration).
- Remove archived decisions from `.gig/DECISIONS.md` (keep the header/format comments).
- Remove RESOLVED issues from `.gig/ISSUES.md` (DEFERRED issues stay — they carry forward).
- Reset `.gig/GOVERNANCE.md` to template state (header and format comments only).

### 3. Git Merge & Tag (if in a git repo)

Reference: `.gig/GIT-STRATEGY.md` for full conventions.

1. **Prepare merge:**
   - Show files changed across all batch commits on the iteration branch.
   - Show the batch commit log: `git log main..HEAD --oneline`

2. **Execute merge (regular merge by default — do not prompt):**
   - Switch to main: `git checkout main`
   - Regular merge (preserves batch commits):
     ```
     git merge --no-ff feature/v0.{N}-{iteration-name}
     ```
   - Only use squash if the user explicitly requests it for this iteration.

3. **Update plugin manifest (if present):**
   - Check if `.claude-plugin/plugin.json` exists in the project root.
   - If yes, update the `"version"` field to `0.{N}.{last-P}` (the last batch version from STATE.md).
   - Stage and commit:
     ```
     git add .claude-plugin/plugin.json
     git commit -m "chore(v0.{N}.{last-P}): update plugin.json version"
     ```
   - If `.claude-plugin/plugin.json` does not exist, skip silently.

4. **Tag the iteration:**
   - Tag with the **actual last batch version** (not a reset):
     ```
     git tag -a v0.{N}.{last-P} -m "Iteration {N}: {iteration name}"
     ```
     Example: if last batch was `v0.7.4`, the tag is `v0.7.4`.
   - If this is also a milestone boundary (last iteration in milestone):
     ```
     git tag -a v{MAJOR}.0.0 -m "Milestone: {milestone name}"
     ```

5. **Cleanup:**
   - Delete feature branch: `git branch -d feature/v0.{N}-{iteration-name}`
   - Remove worktrees if any were created for team tasks.
   - Verify clean state: `git status`

6. **Push (if remote exists):**
   - Check: `git remote` — if output is non-empty, a remote is configured.
   - Push main and tags: `git push origin main --tags`
   - Report: "Pushed to origin." or note if push fails.
   - If no remote, skip silently.

7. **Never:**
   - Force-push
   - Rewrite history on main
   - Delete or move tags

### If NOT in a git repo:
- Skip merge/commit/tag steps.
- Still archive iteration files.

### 4. Final State Updates

1. Update `.gig/STATE.md`:
   - **Status:** `GOVERNED`
   - Version stays at the last batch version (e.g., `0.7.4`)
   - **Plugin Version:** if `.claude-plugin/plugin.json` was updated, set to the new version (e.g., `0.{N}.{last-P}`). Otherwise leave as `—`.
   - Next iteration will start at `0.{N+1}.1` when the first batch of that iteration completes

2. Update `.gig/ROADMAP.md`:
   - Mark iteration as `complete` in the iterations table.
   - Update version range with actual final version.

3. Update `.gig/.gig-version` with the current version (`0.{N}.{last-P}`). This tracks which gig version last touched this project's `.gig/` directory.

---

## Step 10 — Iteration Summary & Next Suggestions

After archiving, present a comprehensive summary:

```
## Iteration {N} Complete — {Iteration Name}

### What Was Built
- {Feature/capability 1}
- {Feature/capability 2}
- ...

### Key Decisions Made
{List ACTIVE decisions from the archived iteration — ID + one-liner}

### Issues
- Resolved this iteration: {count}
- Deferred to future: {count} {list if any}

### Version
Started: v0.{N}.0 → Ended: v0.{N}.{last-P}

### Current Project State
{Brief assessment of what the project can do now — working features, capabilities}
```

### Generate 3 Suggestions

Generate exactly 3 fresh iteration suggestions based on:
- **Open/deferred issues** in ISSUES.md (highest priority)
- **Roadmap gaps** — what the milestone needs that hasn't been built
- **Natural extensions** — what logically follows from what was just built
- **Quality improvements** — testing, refactoring, documentation, performance

```
### What's Next?

1. **{Iteration idea 1}** — {Why}
2. **{Iteration idea 2}** — {Why}
3. **{Iteration idea 3}** — {Why}

Or run `gather [your idea]` to start something else entirely.
```

### Write Suggestions to Roadmap

Present the 3 suggestions, then:
> "These will replace your upcoming iterations queue. Edit or remove any you don't want."

**If user edits:** Apply their changes and write the edited versions.
**Otherwise:** Write all 3 to ROADMAP.md.

**Clear** the entire Upcoming Iterations table in `.gig/ROADMAP.md`, then write the 3 new entries:
```
| {next iteration #} | {Iteration Name} | {One-line description} |
```

Number new suggestions starting after the highest existing iteration number (from both the Iterations table and Upcoming Iterations table).

**Hard rule:** The Upcoming Iterations table holds a maximum of 3 entries. Always replace, never append.

If additional ideas are worth noting but not immediately actionable, append them to `.gig/FUTURE.md` as bullet points. These are backlog items — no commitment, no priority.

Then say:

> "Iteration archived to `.gig/iterations/v0.{N}-{iteration-name}/`. Pick a direction and run `/gig:gather` to start the next iteration, or `/gig:milestone` to manage milestones."

Then add a context checkpoint:

> "Run `/gig:status` after clearing to resume where you left off."

## If Failures Need Fixing

If user chooses to fix issues:
1. Update STATE.md status to `IMPLEMENTING`.
2. Update issue statuses in ISSUES.md.
3. Say: "Run `/gig:implement` to fix issues, then `/gig:govern` again."

## Decision Revisions

If user or Claude proposes decision revisions:
1. Mark old entry as REVISED (Claude) or AMENDED (user).
2. Append new entry with status ACTIVE.
3. Assess impact on current and future work.
