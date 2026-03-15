---
name: gig:govern
description: Verify, validate, track issues, archive phase, summarize status, and suggest next phase ideas.
user-invocable: true
---

# /gig:govern Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Phase: {phase} | Status: {status}`

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
**Phase:** {current phase number}
**Status:** OPEN
**Description:** {What's wrong}
**Evidence:** {Error output, failing test, mismatched behavior}
**Batch:** — (assigned when fix starts)
```

**Severity rules:**
- **Blocker** — Cannot ship. Must fix before phase completes.
- **Major** — Significant issue. Should fix before phase completes.
- **Minor** — Small issue. Can defer to a future phase.
- **Cosmetic** — Polish item. Defer to a future phase.

## Step 8 — Governance Report

Present a complete report:

```
### Test Results
Automated: {passed}/{total} tests  {PASS|FAIL}
Lint: {PASS|FAIL|N/A}

### Acceptance Criteria
{Each criterion with PASS or FAIL}

### Decision Audit
{Table from Step 4 — highlight deviations}

### UAT Results
{Summary: N passed, N failed, N skipped}

### Issues Found
| ID | Title | Severity | Status |
|----|-------|----------|--------|
{All issues from this governance round}

Blockers: {count}
Majors: {count}
Deferred (Minor/Cosmetic): {count}
```

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
> - **Fix blockers only** — defer Majors to a future phase.
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
   - These persist in ISSUES.md and carry forward to future phases.

**If NO Blockers or Majors (or all resolved):**

Present the governance report, then:

> **Does this look good?**
>
> - **Approve** — reply "approve" to archive phase and merge.
> - **Rollback** — revert specific batches or the entire phase.

**STOP. Do not merge. Do not commit. Do not push. Wait for approval.**

## After Approval — Archive Phase

### 1. Create Phase Archive

Create directory: `.gig/phases/v0.{N}-{phase-name}/`

Copy into the archive:
- `.gig/PLAN.md` → `.gig/phases/v0.{N}-{phase-name}/PLAN.md` (frozen snapshot)
- Extract this phase's decisions from `.gig/DECISIONS.md` → `.gig/phases/v0.{N}-{phase-name}/DECISIONS.md`
- Extract this phase's resolved issues from `.gig/ISSUES.md` → `.gig/phases/v0.{N}-{phase-name}/ISSUES.md`

### 2. Clear Active Files

- Reset `.gig/PLAN.md` to template state (no active phase).
- Remove archived decisions from `.gig/DECISIONS.md` (keep the header/format comments).
- Remove RESOLVED issues from `.gig/ISSUES.md` (DEFERRED issues stay — they carry forward).

### 3. Git Merge & Tag (if in a git repo)

Reference: `.gig/GIT-STRATEGY.md` for full conventions.

1. **Prepare merge:**
   - Show files changed across all batch commits on the phase branch.
   - Show the batch commit log: `git log main..HEAD --oneline`

2. **Execute merge (regular merge by default — do not prompt):**
   - Switch to main: `git checkout main`
   - Regular merge (preserves batch commits):
     ```
     git merge --no-ff feature/v0.{N}-{phase-name}
     ```
   - Only use squash if the user explicitly requests it for this phase.

3. **Tag the phase:**
   - Tag with the **actual last batch version** (not a reset):
     ```
     git tag -a v0.{N}.{last-P} -m "Phase {N}: {phase name}"
     ```
     Example: if last batch was `v0.7.4`, the tag is `v0.7.4`.
   - If this is also a milestone boundary (last phase in milestone):
     ```
     git tag -a v{MAJOR}.0.0 -m "Milestone: {milestone name}"
     ```

4. **Cleanup:**
   - Delete feature branch: `git branch -d feature/v0.{N}-{phase-name}`
   - Remove worktrees if any were created for team tasks.
   - Verify clean state: `git status`

5. **Never:**
   - Force-push
   - Rewrite history on main
   - Delete or move tags

### If NOT in a git repo:
- Skip merge/commit/tag steps.
- Still archive phase files.

### 4. Final State Updates

1. Update `.gig/STATE.md`:
   - **Status:** `GOVERNED`
   - Version stays at the last batch version (e.g., `0.7.4`)
   - Next phase will start at `0.{N+1}.1` when the first batch of that phase completes

2. Update `.gig/ROADMAP.md`:
   - Mark phase as `complete` in the phases table.
   - Update version range with actual final version.

---

## Step 10 — Phase Summary & Next Suggestions

After archiving, present a comprehensive summary:

```
## Phase {N} Complete — {Phase Name}

### What Was Built
- {Feature/capability 1}
- {Feature/capability 2}
- ...

### Key Decisions Made
{List ACTIVE decisions from the archived phase — ID + one-liner}

### Issues
- Resolved this phase: {count}
- Deferred to future: {count} {list if any}

### Version
Started: v0.{N}.0 → Ended: v0.{N}.{last-P}

### Current Project State
{Brief assessment of what the project can do now — working features, capabilities}
```

Check `.gig/ROADMAP.md` for an Upcoming Phases section.

**If an upcoming phase exists**, show it prominently:

```
> **Next up:** {name} — {description}
> Run `gather` to start.
```

Then suggest 1-2 additional alternatives below it.

**If no upcoming phases**, suggest 2-3 potential next phases:

```
### Suggested Next Phases

Based on the current state, open issues, and roadmap:

1. **{Phase idea 1}** — {Why: addresses deferred issues, natural next step, etc.}
2. **{Phase idea 2}** — {Why: extends what was built, fills a gap, etc.}
3. **{Phase idea 3}** — {Why: improves quality, adds tests, refactors, etc.}
```

Derive suggestions from:
- **Open/deferred issues** in ISSUES.md (highest priority)
- **Roadmap gaps** — what the milestone needs that hasn't been built
- **Natural extensions** — what logically follows from what was just built
- **Quality improvements** — testing, refactoring, documentation, performance

Then say:

> "Phase archived to `.gig/phases/v0.{N}-{phase-name}/`. Pick a direction and run `/gig:gather` to start the next phase, or `/gig:milestone` to manage milestones."

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
