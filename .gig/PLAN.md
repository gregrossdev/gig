# Plan

> Living document — reflects what was done, not just what was intended.
> This file tracks the ACTIVE iteration only. Completed iterations are archived to `iterations/`.

---

## Active Iteration

<!-- Populated by gig:gather. Cleared and archived by gig:govern on completion. -->

### Iteration 113 — Milestone Absorbs Spec (v0.113.x)

> Absorb spec elicitation into `/gig:milestone create`, eliminate `/gig:spec` as a standalone command, update all consumer skills, and streamline milestone lifecycle UX.

**Decisions:** D-1.1, D-1.2, D-1.3, D-1.4, D-1.5, D-1.6, D-1.7
**Type:** feature

| Batch | Version | Title | Delegation | Status |
|-------|---------|-------|------------|--------|
| 113.1 | `0.113.1` | Rewrite Milestone Skill | in-session | done |
| 113.2 | `0.113.2` | Remove Spec Skill + Update Install | team | done |
| 113.3 | `0.113.3` | Update Consumer Skills | team | done |
| 113.4 | `0.113.4` | Update Global Rules | team | done |
| 113.5 | `0.113.5` | Update Tests | in-session | done |

### Batch 113.1 — Rewrite Milestone Skill

**Delegation:** in-session
**Decisions:** D-1.1, D-1.4, D-1.5, D-1.6, D-1.7
**Type:** feature
**Files:** `skills/milestone/SKILL.md`
**Work:** Rewrite milestone skill to absorb spec elicitation into create flow. Add backlog seed, MVP flow, baseline flow, normal elicitation. Streamline complete flow.
**Test criteria:** Milestone skill has all 3 elicitation paths. Create flow produces SPEC.md. Complete flow has fewer confirmation steps.
**Acceptance:** Milestone create includes interactive spec elicitation with lock gate.

### Batch 113.2 — Remove Spec Skill + Update Install

**Delegation:** team
**Decisions:** D-1.2
**Type:** feature
**Depends on:** Batch 113.1
**Files:** `skills/spec/SKILL.md` (delete), `commands/spec.md` (delete), `install.sh`
**Work:** Delete spec skill and command stub. Remove "spec" from SKILLS list in install.sh.
**Test criteria:** `ls skills/spec/` fails. SPEC.md template still deployed.
**Acceptance:** Spec skill fully removed from distribution.

### Batch 113.3 — Update Consumer Skills

**Delegation:** team
**Decisions:** D-1.1, D-1.2, D-1.3
**Type:** feature
**Depends on:** Batch 113.1
**Files:** `skills/gather/SKILL.md`, `skills/govern/SKILL.md`, `skills/init/SKILL.md`, `skills/status/SKILL.md`, `skills/implement/SKILL.md`
**Work:** Replace all `/gig:spec` references with `/gig:milestone`. Update init auto-transition. Keep SPEC.md file references and amend logic.
**Test criteria:** `grep -r 'gig:spec' skills/` returns zero results. Init auto-transitions to milestone elicitation.
**Acceptance:** No skill references standalone spec command.

### Batch 113.4 — Update Global Rules

**Delegation:** team
**Decisions:** D-1.2
**Type:** feature
**Depends on:** Batch 113.1
**Files:** `CLAUDE.md`, `docs/RULES.md`
**Work:** Remove /gig:spec from workflow, skills list, natural language commands. Update to 4-phase workflow.
**Test criteria:** `grep 'gig:spec' CLAUDE.md` returns zero.
**Acceptance:** Global rules reflect milestone-driven workflow.

### Batch 113.5 — Update Tests

**Delegation:** in-session
**Decisions:** D-1.1, D-1.2
**Type:** feature
**Depends on:** Batches 113.2, 113.3, 113.4
**Files:** `test.sh`
**Work:** Rewrite 52+ spec-related test assertions for milestone-driven workflow. Remove spec command tests. Add milestone backlog-seed test.
**Test criteria:** `./test.sh` passes all tests.
**Acceptance:** All tests pass with no standalone spec command references.

**Iteration Acceptance Criteria:**
- [ ] `/gig:milestone create` includes interactive spec elicitation
- [ ] `/gig:milestone create` supports baseline and MVP flows
- [ ] `/gig:milestone create` can seed from BACKLOG.md entries
- [ ] `/gig:milestone complete` has streamlined confirmation flow
- [ ] `/gig:spec` skill and command stub are deleted
- [ ] No references to `gig:spec` as a standalone command in any skill
- [ ] SPEC.md still produced and consumed by gather/govern
- [ ] Init auto-transitions to milestone elicitation
- [ ] All tests pass

**Completion triggers Iteration 114 → version `0.114.0`**

---

## Plan Amendments

| Date | Version | Amendment | Reason |
|------|---------|-----------|--------|
| — | — | — | — |
