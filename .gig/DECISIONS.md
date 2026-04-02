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

## 2026-04-02 — Milestone Skill: Absorb spec elicitation

**Decision:** Absorb spec elicitation (stories, requirements, constraints, lock gate) into `/gig:milestone create` instead of keeping it as a separate `/gig:spec` command.
**Rationale:** Milestone is already the entry point for new work. Adding spec elicitation there eliminates a separate command invocation and reduces the user journey from 5 steps to 4.
**Alternatives considered:** Keep spec as optional shortcut (creates two paths to same artifact — confusing). Move elicitation into gather (wrong phase — gather should research, not elicit).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Spec Skill: Remove entirely

**Decision:** Remove `/gig:spec` as a standalone command — no alias, no alternative path.
**Rationale:** Two paths to the same artifact creates confusion. Gather's `amend` command already handles mid-flight spec changes (Tier 2/3). Spec elicitation moves into milestone create.
**Alternatives considered:** Keep as alias redirecting to milestone (adds dead code). Demote to "amend-only" (gather already does this).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — SPEC.md: Preserve as contract file

**Decision:** Keep SPEC.md as the inter-skill contract file. Gather and govern continue reading/writing it unchanged.
**Rationale:** SPEC.md is the bridge between milestone (producer) and gather/govern (consumers). Changing the producer doesn't require changing the consumers.
**Alternatives considered:** Embed spec in ROADMAP.md (too large, clutters roadmap). Per-milestone spec directories (over-engineering for current needs).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Milestone Create: New interactive flow

**Decision:** New milestone create flow: name → description → interactive elicitation (stories → requirements → constraints) → lock → write SPEC.md + ROADMAP.md.
**Rationale:** Same quality as spec elicitation but triggered from milestone create. One command, one flow, one approval gate.
**Alternatives considered:** Minimal milestone create + separate spec (current approach — too many steps). Auto-generate spec from description (loses the interactive elicitation value).
**Status:** ACTIVE
**ID:** D-1.4

## 2026-04-02 — MVP Product Discovery: Move into milestone create

**Decision:** Move MVP interview into milestone create as a routing option for new projects.
**Rationale:** New projects benefit from the 7-section MVP interview. It's just triggered during milestone create instead of a separate spec invocation.
**Alternatives considered:** Remove MVP entirely (loses value for greenfield projects). Keep MVP as separate command (same problem as spec — too many entry points).
**Status:** ACTIVE
**ID:** D-1.5

## 2026-04-02 — Milestone Complete: Streamline confirmations

**Decision:** Streamline milestone complete — remove redundant confirmations, auto-verify iteration status from govern results.
**Rationale:** Current flow double-checks what govern already verified. Reduce to single confirmation: "Ready to complete milestone X?"
**Alternatives considered:** Full automation (too risky — milestone completion is a significant event). Keep current flow (user explicitly said UX is unpleasant).
**Status:** ACTIVE
**ID:** D-1.6

## 2026-04-02 — Backlog: Feed into milestone creation

**Decision:** Milestone create can consume a backlog item as seed — offer backlog entries as starting points, pre-populate name/description.
**Rationale:** Backlog-driven roadmap means ideas flow naturally into milestones without manual re-entry.
**Alternatives considered:** Auto-create milestones from backlog (too aggressive — user should choose). Keep backlog disconnected (misses the workflow integration opportunity).
**Status:** ACTIVE
**ID:** D-1.7
