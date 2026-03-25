---
name: gig:triage
description: Research the codebase independently and propose what to work on next — a specialized analysis tool.
user-invocable: true
---

# /gig:triage Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

**If present:**
Read `.gig/STATE.md`, `.gig/ROADMAP.md`, `.gig/ARCHITECTURE.md`, `.gig/ISSUES.md`, `.gig/BACKLOG.md`.

## Step 2 — Research the Codebase

Launch 2-3 Explore subagents (Agent tool, subagent_type "Explore") **in parallel**, each with a different research focus. Every agent receives:

- The project's ARCHITECTURE.md for structural context
- Open/deferred issues from ISSUES.md
- The completed iterations list from ROADMAP.md (for historical context)

### Agent 1 — Quality & Coverage

Investigate:
1. **Test gaps** — untested skills, missing assertions, areas with no coverage
2. **Code quality** — lint issues, inconsistencies, error-prone patterns
3. **Broken or stale behavior** — features that don't work as documented

### Agent 2 — Consistency & Docs

Investigate:
1. **Skill/template drift** — do skills match their documented behavior? Do templates match skill expectations?
2. **Stale documentation** — README, ARCHITECTURE.md, GETTING-STARTED.md accuracy
3. **Naming inconsistencies** — terminology mismatches across files

### Agent 3 — Features & Architecture

Investigate:
1. **Missing capabilities** — gaps in the workflow that users would expect
2. **Incomplete features** — partially implemented or rough-edged functionality
3. **Architectural improvements** — structural issues, dependency problems, scalability

Each agent returns findings with **specific file references** and severity assessment.

Collect all findings and present: "Research complete. Analyzing {N} findings..."

## Step 3 — Read Current Queue + Backlog

Read the Upcoming Iterations table from `.gig/ROADMAP.md` and `.gig/BACKLOG.md` backlog items.

These are **context for comparison**, not the primary source of proposals. Note which queue items are supported or contradicted by research findings.

## Step 4 — Assess Findings

For each significant finding from research (limit to 5-7 top findings), produce a triage card:

**Present the following cards in full. Do not abbreviate, inline, or collapse into prose.**

```
### {Finding Name}

**Scope:** {files/areas affected, estimated batch count}
**Value:** {what this unlocks, why it matters now}
**Risk:** {what could go wrong, complexity}
**Evidence:** {specific files, lines, tests, or behaviors that surfaced this finding}
```

Prioritize findings by: blockers > user-facing issues > consistency > quality > nice-to-have.

## Step 5 — Compare & Recommend

### Research-Driven Recommendation

Present a ranked top 3 based on research findings:

```
## Recommendation

1. **{Iteration Name}** — {one-line reason it should go first}
2. **{Iteration Name}** — {one-line reason}
3. **{Iteration Name}** — {one-line reason}

**Rationale:** {2-3 sentences explaining the ordering — dependencies, value sequencing, evidence strength}
```

### Current Queue Assessment

If the Upcoming Iterations table has entries, compare each against research findings:

```
### Current Queue

| # | Name | Assessment |
|---|------|------------|
| {N} | {Name} | {Still valid / Superseded by X / Needs revision: Y} |
```

### In the Backlog

If `.gig/BACKLOG.md` has items relevant to the research findings, surface them:

```
### In the Backlog
- {idea} — {relevant because: connection to finding X}
```

If nothing in the backlog is relevant, skip this section. Do not propose backlog items as fresh recommendations.

## Step 6 — Reorder (optional)

Ask:

> "Want me to rewrite the upcoming iterations queue based on this analysis?"
>
> - **"yes"** — replace the Upcoming Iterations table in ROADMAP.md with the recommended top 3.
> - **"no"** — leave the queue as-is.
> - **"swap X and Y"** — apply a specific change.

If the user approves, update `.gig/ROADMAP.md` Upcoming Iterations table accordingly.
