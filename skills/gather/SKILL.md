---
name: gig:gather
description: Research the problem, make decisions, and build the implementation plan. Two approval gates, one command.
user-invocable: true
argument-hint: "[goal or topic]"
---

# /gig:gather Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

If status is "GATHERED" or later, warn: "Gathering already complete for current iteration. Running `/gig:gather` will start a new round. Continue?"

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

**If present:**
1. Read `.gig/STATE.md` for current position.
2. Read `.gig/DECISIONS.md` for existing decisions.
3. Read `.gig/ARCHITECTURE.md` for structural context.
4. Read `.gig/ROADMAP.md` for milestone context.
5. Read `.gig/ISSUES.md` for open issues from prior iterations.

---

## PART A — Decide

### Step 2 — Gather Intent

Check `.gig/ROADMAP.md` for an Upcoming Iterations section with entries.

**If user provided args:** Check if the args match an entry name in the Upcoming Iterations table (case-insensitive). If matched, consume that entry (see "Consuming an Upcoming Iteration" below). If no match, use the args as a freeform goal and skip to "After intent is set".

**If user did NOT provide args and the Upcoming Iterations table has entries:** Take the **first row** of the table.
1. Present: "Next planned iteration: **{name}** — {description}. Starting research on this. Say `skip` to choose something else."
2. If user says `skip`, ask: "What do you want to build or accomplish?"
3. Otherwise, consume that entry (see below).

**If no upcoming iterations and no user goal:** Ask the user ONE open-ended question: "What do you want to build or accomplish?"

If the user already stated their goal (same message or prior context), skip and proceed.

#### Consuming an Upcoming Iteration

When an iteration is selected from the Upcoming Iterations table:
1. **Remove** the entry's row from the Upcoming Iterations table in `.gig/ROADMAP.md`.
2. **Add** it to the Iterations table with status `planned`: `| {N} | {Name} | v0.{N}.x | planned |`
3. Use the iteration name and description as the goal for Steps 3-4.

#### After intent is set

If there are open issues from `.gig/ISSUES.md` (deferred from prior iterations), surface them:
"Open issues from prior iterations: {list}. Want to address any of these?"

Do NOT ask follow-up questions — Claude researches and decides in Steps 3-4.

### Step 3 — Deep Research

Before making ANY decisions, research thoroughly:

- Use subagents (Agent tool, subagent_type "Explore") to investigate existing codebase, dependencies, patterns, constraints.
- If the goal involves external libraries or APIs, research with WebSearch or subagents.
- Read existing code, configs, tests, documentation.
- Identify unknowns, ambiguities, areas with multiple valid approaches.

Do NOT skip this step. Do NOT guess. Decision quality depends on thorough research.

### Step 4 — Present Decisions

Ask yourself every question that needs answering. For each, make a decision.
Organize into a single batch of 3-7 decisions.

**Per decision:**
- Be opinionated. Make a clear choice. Do not hedge.
- Reference specific research findings.
- Each decision is atomic — one choice per entry.
- Use ID format: `D-{batch}.{num}` (e.g., D-1.1, D-1.2)

If more than 7 decisions are needed, split into multiple batches and present sequentially.

Update `.gig/STATE.md`:
- Set **Iteration** to the goal/topic being decided on.
- Set **Status** to `GATHERING`.

**Do NOT write to DECISIONS.md yet.** Present decisions in chat only.

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

### After Gate 1 Approval — Write Decisions

Once approved (with or without redlines), write all decisions to `.gig/DECISIONS.md` directly as **ACTIVE** entries:

```
## {TODAY'S DATE} — {Domain}: {Question}

**Decision:** {What was decided}
**Rationale:** {Why — reference research findings}
**Alternatives considered:** {What else was viable and why rejected}
**Status:** ACTIVE
**ID:** D-{batch}.{num}
```

For redlined decisions: write only the user's final choice as ACTIVE. Do not write the original proposal.

Update `.gig/STATE.md`:
- Active Decisions: list all ACTIVE decision IDs with one-line summaries.

Say: "Decisions locked. Building the plan..."

---

## PART B — Plan

### Enter Plan Mode

After decisions are locked, call `EnterPlanMode` to design the iteration plan. In plan mode, Claude explores the codebase and designs the batch breakdown — no writes to `.gig/` files yet.

### Step 7 — Determine Iteration

Look at `.gig/ROADMAP.md` iterations table and `.gig/iterations/` directory.
- If no iterations exist: iteration number = `1`.
- Otherwise: increment from highest existing.

The iteration version follows the batch versioning rule: **MINOR = iteration number**.
- Iteration 1 → version `0.1.x`
- Iteration 2 → version `0.2.x`
- Iteration N → version `0.N.x`

Derive iteration name from the decisions context. Format: `v0.{N}-{kebab-case}`.

### Step 8 — Decompose Into Batches

Using ACTIVE decisions as requirements, break work into batches.
Each batch is a small, coherent unit:
- **1-5 files** created or modified
- **1 logical concern** addressed
- **Testable or verifiable** independently

For each batch:
```
### Batch {iteration}.{N} — {Title}

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

### APPROVAL GATE 2 — Plan (via Plan Mode)

Present the plan in plan mode:
1. Iteration name and goal
2. Batch table with versions and delegation modes
3. Dependencies between batches
4. Which batches will run in parallel (team mode)
5. Test criteria summary
6. Total batch count

Then call `ExitPlanMode` for user approval.

**Do not write any `.gig/` files while in plan mode. Wait for approval.**

### After Plan Approval — Write State

Once the user approves the plan (exits plan mode):

**Step 9 — Write the Plan**

Write the iteration to `.gig/PLAN.md`, replacing the "Active Iteration" section:

```markdown
## Active Iteration

### Iteration {N} — {Name} (v0.{N}.x)

> {One-paragraph goal derived from decisions}

**Decisions:** {list all ACTIVE decision IDs this iteration implements}

| Batch | Version | Title | Delegation | Status |
|-------|---------|-------|------------|--------|
| {N}.1 | `0.{N}.1` | {title} | {mode} | pending |
| {N}.2 | `0.{N}.2` | {title} | {mode} | pending |
| ... | ... | ... | ... | ... |

{Full batch details from Step 8}

**Iteration Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

**Completion triggers Iteration {N+1} -> version `0.{N+1}.0`**
```

**Step 10 — Update State & Roadmap**

Update `.gig/STATE.md`:
- **Version:** `0.{N}.0`
- **Iteration:** {N} — {Name}
- **Status:** `GATHERED`
- **Last Batch:** — (not started)
- **Working Memory:** key context from the plan (file paths, naming, patterns)

Update `.gig/ROADMAP.md` iterations table:
- If the iteration was consumed from Upcoming Iterations in Step 2, it's already in the Iterations table — skip adding.
- Otherwise (freeform goal), add row: `| {N} | {Name} | v0.{N}.x | planned |`
