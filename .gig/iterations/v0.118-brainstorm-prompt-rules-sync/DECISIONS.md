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

## 2026-04-02 — Milestone: Offer brainstorm after creation

**Decision:** Offer `/gig:design` alongside `/gig:gather` in milestone Step 3a.6 ending message.
**Rationale:** User wants a brainstorm prompt before jumping to technical decisions.
**Alternatives considered:** Auto-launch design (too aggressive). Only suggest gather (current — misses brainstorm).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Rules: Sync via reinstall

**Decision:** User re-runs install.sh to sync global rules. Source (docs/RULES.md) is already updated.
**Rationale:** install.sh already handles copying. No code change needed.
**Alternatives considered:** Auto-sync mechanism (over-engineering for a one-time sync).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Repo: Update test count

**Decision:** Update "80+ tests" to "600+ tests" in .claude/CLAUDE.md.
**Rationale:** Stale number from early versions.
**Alternatives considered:** N/A.
**Status:** ACTIVE
**ID:** D-1.3
