---
name: gig:triage
description: Evaluate upcoming iterations — surface knowledge gaps, assess value, recommend priority order.
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
Read `.gig/STATE.md`, `.gig/ROADMAP.md`, `.gig/ARCHITECTURE.md`, `.gig/ISSUES.md`, `.gig/FUTURE.md`.

## Step 2 — Read the Queue

Extract the upcoming iterations from `.gig/ROADMAP.md` (Upcoming Iterations table).

**If no upcoming iterations:**
Say: "No upcoming iterations to triage. Run `/gig:govern` to generate suggestions, or `gather [your idea]` to start something." STOP.

Also read `.gig/FUTURE.md` for backlog ideas that might be worth promoting.

Present: "Triaging {N} upcoming iterations..."

## Step 3 — Research

For each upcoming iteration, launch an Explore subagent (Agent tool, subagent_type "Explore") **in parallel**. Each agent receives:

- The iteration name and description from ROADMAP.md
- The project's ARCHITECTURE.md for structural context
- Open/deferred issues from ISSUES.md

Each agent investigates:
1. **What files/skills/areas would this iteration touch?**
2. **What unknowns or ambiguities exist?** (unclear requirements, missing context, dependencies on external factors)
3. **What's the estimated scope?** (number of files, likely batch count)
4. **Are there blockers or prerequisites?**

Collect all findings.

## Step 4 — Assess

For each upcoming iteration, produce a triage card:

```
### {N} — {Iteration Name}

**Scope:** {files/skills affected, estimated batch count}
**Knowledge Gaps:** {unknowns, questions that need answering before gather}
**Value:** {what this unlocks, who benefits, why it matters now}
**Risk:** {what could go wrong, dependencies, complexity traps}
```

If an iteration has zero knowledge gaps, note: "Ready to gather — no unknowns."
If an iteration has significant gaps, note what research is needed first.

## Step 5 — Recommend

Present a ranked recommendation:

```
## Recommendation

1. **{Iteration Name}** — {one-line reason it should go first}
2. **{Iteration Name}** — {one-line reason}
3. **{Iteration Name}** — {one-line reason}

**Rationale:** {2-3 sentences explaining the ordering — dependencies, value sequencing, gap resolution}
```

Also surface any `.gig/FUTURE.md` backlog items worth promoting to the upcoming queue:

```
### Worth Promoting from Backlog
- {idea} — {why it's timely}
```

If nothing in FUTURE.md is worth promoting, skip this section.

## Step 6 — Reorder (optional)

Ask:

> "Want me to reorder the upcoming iterations queue based on this analysis?"
>
> - **"yes"** — rewrite the Upcoming Iterations table in ROADMAP.md with the recommended order.
> - **"no"** — leave the queue as-is.
> - **"swap X and Y"** — apply a specific reorder.

If the user approves a reorder, update `.gig/ROADMAP.md` Upcoming Iterations table accordingly.
