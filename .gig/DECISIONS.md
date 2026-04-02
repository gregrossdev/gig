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

## 2026-04-02 — Milestone: Resume guard for SPECING status

**Decision:** Add resume guard after Step 1 — if status is SPECING, offer "Resume elicitation" or "Start fresh" before presenting Step 2 action menu.
**Rationale:** Prevents accidental overwrite of in-progress elicitation. Learn skill already uses this pattern ("If SPECING, allow resume").
**Alternatives considered:** No guard (user could accidentally restart). Auto-resume without asking (user might want to start fresh).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Status: Add SPECING suggestion

**Decision:** Add SPECING row to status suggestion table: "Spec elicitation in progress. Continue with `/gig:milestone`."
**Rationale:** Only missing status in the suggestion table — user gets no guidance when in SPECING state.
**Alternatives considered:** Combine with SPECCED row (different actions needed). Omit (leaves gap).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Status: Show spec progress

**Decision:** Add spec progress line when SPECING or SPECCED: "Spec: {N} stories, {M} requirements ({DRAFT|LOCKED})"
**Rationale:** Makes milestone progress visible without running milestone; reads SPEC.md story/requirement tables.
**Alternatives considered:** Only show after SPECCED (misses draft progress). Show in milestone only (status should surface key info).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Status: Show iteration coverage from spec

**Decision:** When spec exists and iterations are in progress, show: "Coverage: {covered}/{total} requirements"
**Rationale:** Surfaces what govern tracks (spec coverage) at a glance during the milestone.
**Alternatives considered:** Only show in govern report (not accessible at a glance). Show in ROADMAP.md (wrong place for runtime info).
**Status:** ACTIVE
**ID:** D-1.4
