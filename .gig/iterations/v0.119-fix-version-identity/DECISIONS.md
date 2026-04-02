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

## 2026-04-02 — Init: Fix version comparison

**Decision:** Init runs upgrade when .gig-version doesn't exactly match plugin.json — not "older than", but "not equal."
**Rationale:** Handles both stale and project-version-polluted .gig-version files (like ssg's 0.128.4).
**Alternatives considered:** Semver comparison (complex, still breaks when project version > gig version). Always run upgrade (wasteful).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Upgrade: Add Upcoming Milestones migration

**Decision:** Add new step to upgrade.sh: rename "## Upcoming Iterations" → "## Upcoming Milestones" in ROADMAP.md.
**Rationale:** Existing projects have old headers that govern's proposal step can't write to.
**Alternatives considered:** Manual rename (user friction). Govern handles both headers (fragile).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Init: Update inline upgrade logic too

**Decision:** Add the same ROADMAP rename to init's inline fallback upgrade path.
**Rationale:** Script install users who don't have upgrade.sh need this migration.
**Alternatives considered:** Only fix upgrade.sh (misses script installs).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Govern: No change to plugin.json logic

**Decision:** Govern correctly writes the PROJECT's plugin.json version. No change needed.
**Rationale:** Project's own plugin.json is separate from gig's. .gig-version tracks gig tool version.
**Alternatives considered:** N/A.
**Status:** ACTIVE
**ID:** D-1.4
