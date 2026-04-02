# Plan

> Living document — reflects what was done, not just what was intended.
> This file tracks the ACTIVE iteration only. Completed iterations are archived to `iterations/`.

---

## Active Iteration

<!-- Populated by gig:gather. Cleared and archived by gig:govern on completion. -->

### Iteration 114 — Milestone Resume & Status Integration (v0.114.x)

> Add SPECING resume guard to milestone skill, add SPECING suggestion to status skill, and surface spec progress (story/requirement counts and coverage) in the status display.

**Decisions:** D-1.1, D-1.2, D-1.3, D-1.4
**Type:** feature

| Batch | Version | Title | Delegation | Status |
|-------|---------|-------|------------|--------|
| 114.1 | `0.114.1` | Milestone Resume Guard + Status SPECING | in-session | done |
| 114.2 | `0.114.2` | Status Spec Progress Display | in-session | done |
| 114.3 | `0.114.3` | Update Tests | in-session | done |

### Batch 114.1 — Milestone Resume Guard + Status SPECING

**Delegation:** in-session
**Decisions:** D-1.1, D-1.2
**Type:** feature
**Files:** `skills/milestone/SKILL.md`, `skills/status/SKILL.md`
**Work:** Add SPECING resume guard between Step 1 and Step 2 in milestone. Add SPECING row to status suggestion table.
**Test criteria:** `grep -q 'SPECING' skills/status/SKILL.md` in suggestion table. Milestone has resume guard.
**Acceptance:** SPECING status handled in both skills.

### Batch 114.2 — Status Spec Progress Display

**Delegation:** in-session
**Decisions:** D-1.3, D-1.4
**Depends on:** Batch 114.1
**Type:** feature
**Files:** `skills/status/SKILL.md`
**Work:** Add SPEC.md reading to Step 1. Add spec progress and coverage lines to Step 2 display.
**Test criteria:** Status skill contains "stories", "requirements", "DRAFT", "LOCKED", "Coverage".
**Acceptance:** Status shows spec progress when SPEC.md has content.

### Batch 114.3 — Update Tests

**Delegation:** in-session
**Decisions:** D-1.1, D-1.2, D-1.3, D-1.4
**Depends on:** Batches 114.1, 114.2
**Type:** feature
**Files:** `test.sh`
**Work:** Add assertions for SPECING in status, resume guard in milestone, spec progress/coverage in status.
**Test criteria:** `./test.sh` passes all tests.
**Acceptance:** All tests pass.

**Iteration Acceptance Criteria:**
- [ ] Milestone detects SPECING status and offers resume vs. fresh
- [ ] Status skill has SPECING suggestion row
- [ ] Status shows spec progress (story/requirement counts) when SPEC.md has content
- [ ] Status shows coverage (covered/total) when requirements exist
- [ ] All tests pass

**Completion triggers Iteration 115 → version `0.115.0`**

---

## Plan Amendments

| Date | Version | Amendment | Reason |
|------|---------|-----------|--------|
| — | — | — | — |
