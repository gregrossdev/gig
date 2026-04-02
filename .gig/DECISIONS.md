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

## 2026-04-02 — Govern: Proposal step placement

**Decision:** Add milestone proposal step after Auto-Complete step 6 (push), before the final message.
**Rationale:** Proposals happen after everything is committed. Last thing before prompting the user.
**Alternatives considered:** Before push (proposals could reference uncommitted state). In a separate command (adds friction).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Govern: Assessment depth

**Decision:** Quick scan of existing state files (ARCHITECTURE.md, BACKLOG.md, ISSUES.md, ROADMAP.md) — no subagent launch.
**Rationale:** Keeps govern fast. State files already contain enough context from prior research.
**Alternatives considered:** Full 3-agent research (too slow for govern). No assessment (misses opportunities).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Govern: Preserve existing entries

**Decision:** Preserve existing Upcoming Milestones entries. Only fill empty slots up to 3 total.
**Rationale:** User may have manually added proposals — don't overwrite.
**Alternatives considered:** Replace all (loses user input). Append beyond 3 (breaks the 3-cap rule).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Govern: Proposal format

**Decision:** Same format as Upcoming Milestones table: `| # | Name | Description |` numbered from next milestone MINOR.
**Rationale:** Consistent with what /gig:milestone reads.
**Alternatives considered:** Free-form bullet points (inconsistent). Separate proposals file (over-engineering).
**Status:** ACTIVE
**ID:** D-1.4
