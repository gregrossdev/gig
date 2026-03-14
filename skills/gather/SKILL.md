---
name: gig:gather
description: Research the problem, make decisions, and build the implementation plan. Two approval gates, one command.
---

# /gig:gather Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Phase: {phase} | Status: {status}`

If status is "GATHERED" or later, warn: "Gathering already complete for current phase. Running `/gig:gather` will start a new round. Continue?"

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

**If present:**
1. Read `.gig/STATE.md` for current position.
2. Read `.gig/DECISIONS.md` for existing decisions.
3. Read `.gig/ARCHITECTURE.md` for structural context.
4. Read `.gig/ROADMAP.md` for milestone context.
5. Read `.gig/ISSUES.md` for open issues from prior phases.

---

## PHASE A — Decide

### Step 2 — Gather Intent

Ask the user ONE open-ended question: "What do you want to build or accomplish?"

If the user already stated their goal (same message or prior context), skip and proceed.

If there are open issues from `.gig/ISSUES.md` (deferred from prior phases), surface them:
"Open issues from prior phases: {list}. Want to address any of these?"

Do NOT ask follow-up questions — Claude researches and decides in Steps 3-4.

### Step 3 — Deep Research

Before making ANY decisions, research thoroughly:

- Use subagents (Agent tool, subagent_type "Explore") to investigate existing codebase, dependencies, patterns, constraints.
- If the goal involves external libraries or APIs, research with WebSearch or subagents.
- Read existing code, configs, tests, documentation.
- Identify unknowns, ambiguities, areas with multiple valid approaches.

Do NOT skip this step. Do NOT guess. Decision quality depends on thorough research.

### Step 4 — Generate Decision Batch

Ask yourself every question that needs answering. For each, make a decision.
Organize into a single batch of 3-7 decisions.

**Per decision:**
- Be opinionated. Make a clear choice. Do not hedge.
- Reference specific research findings.
- Each decision is atomic — one choice per entry.
- Use ID format: `D-{batch}.{num}` (e.g., D-1.1, D-1.2)

If more than 7 decisions are needed, split into multiple batches and present sequentially.

### Step 5 — Write Decisions

Write batch to `.gig/DECISIONS.md` (preserve existing entries).

Entry format:
```
## {TODAY'S DATE} — {Domain}: {Question}

**Decision:** {What was decided}
**Rationale:** {Why — reference research findings}
**Alternatives considered:** {What else was viable and why rejected}
**Status:** PROPOSED
**ID:** D-{batch}.{num}
```

### Step 6 — Update State

Update `.gig/STATE.md`:
- Set **Phase** to the goal/topic being decided on.
- Set **Status** to `GATHERING`.

### APPROVAL GATE 1 — Decisions

Present decisions as a clean summary table:

| ID | Decision | Choice | Rationale (1-line) |
|----|----------|--------|-------------------|

Then say:

> **Does this batch look good?**
>
> - **Approve** — reply "approve" or "looks good" to lock these in.
> - **Redline** — reference by ID (e.g., "D-1.3: use X instead").
> - **Ask questions** — about any decision before committing.

**STOP. Do not create a plan. Do not write code. Wait for approval.**

### After Gate 1 Approval

Once approved (with or without redlines):

1. For redlined decisions:
   - Change original entry's status from PROPOSED to AMENDED.
   - Append NEW entry with user's choice, status ACTIVE, note: "Overridden by user — original: {original choice}"

2. Change all remaining PROPOSED to ACTIVE.

3. Update `.gig/STATE.md`:
   - Active Decisions: list all ACTIVE decision IDs with one-line summaries.

4. Say: "Decisions locked. Building the plan..."

---

## PHASE B — Plan

### Step 7 — Determine Phase

Look at `.gig/ROADMAP.md` phases table and `.gig/phases/` directory.
- If no phases exist: phase number = `1`.
- Otherwise: increment from highest existing.

The phase version follows the batch versioning rule: **MINOR = phase number**.
- Phase 1 → version `0.1.x`
- Phase 2 → version `0.2.x`
- Phase N → version `0.N.x`

Derive phase name from the decisions context. Format: `v0.{N}-{kebab-case}`.

### Step 8 — Decompose Into Batches

Using ACTIVE decisions as requirements, break work into batches.
Each batch is a small, coherent unit:
- **1-5 files** created or modified
- **1 logical concern** addressed
- **Testable or verifiable** independently

For each batch:
```
### Batch {phase}.{N} — {Title}

**Delegation:** {team | subagent | in-session}
**Decisions:** {Decision IDs this implements, e.g., D-1.1, D-2.3}
**Files:** {files to create or modify}
**Work:** {What to do}
**Test criteria:** {specific verification — command, file check, behavior}
**Acceptance:** {What "done" looks like}
```

**Delegation defaults:**
- `team` — Independent batches with no dependency between them. **This is the default for implementation.** When 2+ batches have no dependency chain, mark them all as `team` so they execute in parallel via worktrees.
- `subagent` — Research/exploration feeding other tasks.
- `in-session` — Sequential, needs shared context or depends on another batch.

**Hard rule:** Every implementation batch MUST have test criteria.

Tag dependencies explicitly: "Depends on Batch X.Y".

### Step 9 — Write the Plan

Write the phase to `.gig/PLAN.md`, replacing the "Active Phase" section:

```markdown
## Active Phase

### Phase {N} — {Name} (v0.{N}.x)

> {One-paragraph goal derived from decisions}

**Decisions:** {list all ACTIVE decision IDs this phase implements}

| Batch | Version | Title | Delegation | Status |
|-------|---------|-------|------------|--------|
| {N}.1 | `0.{N}.1` | {title} | {mode} | pending |
| {N}.2 | `0.{N}.2` | {title} | {mode} | pending |
| ... | ... | ... | ... | ... |

{Full batch details from Step 8}

**Phase Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

**Completion triggers Phase {N+1} -> version `0.{N+1}.0`**
```

### Step 10 — Update State & Roadmap

Update `.gig/STATE.md`:
- **Version:** `0.{N}.0`
- **Phase:** {N} — {Name}
- **Status:** `GATHERED`
- **Last Batch:** — (not started)
- **Working Memory:** key context from the plan (file paths, naming, patterns)

Update `.gig/ROADMAP.md` phases table:
- Add row: `| {N} | {Name} | v0.{N}.x | planned |`

### APPROVAL GATE 2 — Plan

Present the plan:
1. Phase name and goal
2. Batch table with versions and delegation modes
3. Dependencies between batches
4. Which batches will run in parallel (team mode)
5. Test criteria summary
6. Total batch count

Then say:

> **Does this batch look good?**
>
> - **Approve** — reply "approve" to proceed to `/gig:implement`.
> - **Adjust** — suggest changes to batch breakdown or ordering.
> - **Revise decisions** — reference by ID if something needs to change.

**STOP. Do not implement. Do not create worktrees. Wait for approval.**
