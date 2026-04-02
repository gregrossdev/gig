# Plan

> Living document — reflects what was done, not just what was intended.
> This file tracks the ACTIVE iteration only. Completed iterations are archived to `iterations/`.

---

## Active Iteration

### Milestone 119 — Fix Version Identity (v0.119.x)

> .gig-version tracks gig tool version, not project version. Init uses exact match for upgrade detection. Upgrade.sh migrates Upcoming Iterations → Milestones.

**Decisions:** D-1.1, D-1.2, D-1.3, D-1.4
**Type:** fix

| Batch | Version | Title | Delegation | Status |
|-------|---------|-------|------------|--------|
| 119.1 | `0.119.1` | Fix Version Identity | in-session | done |

**Iteration Acceptance Criteria:**
- [x] Init uses "does not match" instead of "older than" for version comparison
- [x] Init inline upgrade migrates Upcoming Iterations → Upcoming Milestones
- [x] Upgrade.sh has Step 2b for Upcoming Milestones migration
- [x] All tests pass (603/603)

---

## Plan Amendments

| Date | Version | Amendment | Reason |
|------|---------|-----------|--------|
| — | — | — | — |
