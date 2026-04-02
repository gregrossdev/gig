# Decisions

> Append-only log. Never delete entries — amend or revise instead.
> Active decisions for the current iteration live here.
> When an iteration completes, its decisions are archived to `iterations/`.

<!-- Decision statuses:
  PROPOSED  — Claude's recommendation, awaiting user approval
  ACTIVE    — Approved and in effect
  AMENDED   — Overridden by user (original preserved, new entry appended)
  REVISED   — Claude revised based on new information (original preserved)
-->

## 2026-04-02 — Versioning: New model

**Decision:** MINOR = milestone number, PATCH = iteration within milestone. 0.X.0 = milestone start, 0.X.1 = first iteration, 0.X.2 = second, etc.
**Rationale:** Aligns version numbers with feature boundaries. Each milestone is one feature.
**Alternatives considered:** Keep current model (MINOR=iteration globally). Use MAJOR for milestones (breaks v1.0 guard).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Roadmap: Upcoming Milestones

**Decision:** Rename "Upcoming Iterations" to "Upcoming Milestones" everywhere — ROADMAP template, govern, gather, RULES.md, milestone skill.
**Rationale:** Milestones are the unit of work; the queue should propose features, not iterations.
**Alternatives considered:** Keep "Upcoming Iterations" name (confusing with new model). Remove queue entirely (loses planning value).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Govern: Prompt milestone completion

**Decision:** After archiving, default prompt = "Complete milestone with `/gig:milestone complete`" instead of auto-queuing iterations.
**Rationale:** User wants to close the feature and pick the next one, not chain iterations.
**Alternatives considered:** Auto-complete milestone (too aggressive). Keep iteration suggestions (user explicitly rejected this).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Gather: Version derivation

**Decision:** Iteration number = highest patch within current milestone + 1 (not global iteration count). Version = 0.{milestone}.{iteration}.
**Rationale:** Patches relative to current milestone's minor number.
**Alternatives considered:** Keep global counter (breaks new versioning model). Reset to 1 each milestone (that's what this does).
**Status:** ACTIVE
**ID:** D-1.4

## 2026-04-02 — Git: Branch naming

**Decision:** `feature/v0.{M}-{milestone-name}` stays as-is. Iterations within just bump patch on commits/tags.
**Rationale:** Branches already use the minor version. One branch per milestone, iterations are patches within it.
**Alternatives considered:** Branch per iteration (too many branches). Include patch in branch name (unnecessary granularity).
**Status:** ACTIVE
**ID:** D-1.5

## 2026-04-02 — Rules: Update versioning docs

**Decision:** Update RULES.md and CLAUDE.md: PATCH = iteration, MINOR = milestone, MAJOR = user-declared.
**Rationale:** Core documentation of the versioning model.
**Alternatives considered:** N/A — documentation must match implementation.
**Status:** ACTIVE
**ID:** D-1.6
