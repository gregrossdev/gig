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
6. Read `.gig/SPEC.md` if it exists — this is the spec for the current milestone.
7. Read `.gig/DESIGN.md` if it exists — UI/UX design decisions and Figma prototype links.
8. Read `.gig/DEBT.md` if it exists — structural debt from prior iterations.

**If `.gig/SPEC.md` exists and has content beyond the template:** Use it as the foundation for decisions. Every decision should trace to a requirement in the spec.

**If `.gig/SPEC.md` does not exist or is empty:** Print: "No spec found. Consider running `/gig:spec` first for complex features." Then proceed as normal.

**If `.gig/DESIGN.md` exists and has content:** Use it as design context for decisions. Reference Figma designs when making UI-related decisions. Link decisions to design screens where applicable.

**If `.gig/DESIGN.md` does not exist:** Proceed normally. Design is optional.

**If `.gig/DEBT.md` exists and has entries:** Note outstanding debt items. Surface them in Step 2 if relevant to the iteration goal.

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

If `.gig/DEBT.md` has OPEN or TRACKED entries and the iteration goal involves refactoring or structural work, surface relevant debt items:
"Outstanding technical debt: {list DEBT IDs and titles}. Want to include any of these in the refactor scope?"

Do NOT ask follow-up questions — Claude researches and decides in Steps 3-4.

### Step 2b — Docs/Config Detection

Before launching deep research, assess whether this is a docs/config iteration:

**Indicators (any match triggers lightweight mode):**
- User args contain: "docs", "config", "readme", "update docs", "documentation"
- Iteration name contains: "docs", "config", "readme"
- All spec requirements reference only documentation files (no code changes)

**If lightweight mode detected:**
Say: "Docs/config iteration — using lightweight research path."
- **Skip Step 3** (deep subagent research) — use direct file reads from Step 1 context instead.
- **Skip Step 3a** (architecture audit) — note: "Docs/config iteration — no architectural assessment needed."
- **Skip Step 3b** (diagrams) — note: "No diagram changes — docs/config only."
- Proceed directly to Step 4 (Present Decisions).

**If the user says "do full research":** Override and run the standard path.
**If work turns out to involve code changes:** Escalate to the full path mid-gather.

### Step 3 — Deep Research

Before making ANY decisions, research thoroughly:

Launch 3 Explore agents in parallel (Agent tool, subagent_type "Explore"), one per profile:

- **Architecture Agent** — Investigate structure, stack, dependencies, frameworks, file layout, and pattern consistency. Receives: `.gig/ARCHITECTURE.md`, package/config files, iteration goal.
- **Quality Agent** — Investigate tests, lint, coverage, code patterns, tech debt, and error handling. Receives: test files, lint config, `.gig/ISSUES.md`, iteration goal.
- **Discovery Agent** — Investigate patterns, themes, cross-cutting concerns, git history, and iteration trends. Receives: `.gig/ROADMAP.md`, `.gig/BACKLOG.md`, `.gig/SPEC.md`, iteration goal.

All agents also receive working memory from `.gig/STATE.md`.

For projects with iteration history, launch all 3 agents. For new projects with minimal codebase, launch 2 minimum (Architecture + Discovery).

If the goal involves external libraries or APIs, add WebSearch calls in the same parallel block as the agents.

Synthesize findings from all agents before proceeding to Step 3a. Identify unknowns, ambiguities, and areas with multiple valid approaches.

Do NOT skip this step. Do NOT guess. Decision quality depends on thorough research. **Exception:** docs/config iterations use the lightweight path from Step 2b instead.

### Step 3a — Architecture Audit Log

After research completes, append an architecture assessment to `.gig/ARCHITECTURE.md` under the `## Audit Log` section:

```
### Iteration {N} — {date}
{2-3 line assessment of structural health based on research findings: patterns observed, consistency with ARCHITECTURE.md, any concerns or drift}
```

This builds a running record of architectural observations across iterations.

### Step 3b — System Diagrams

After research and before presenting decisions, generate Mermaid diagrams to model the system:

1. Create `.gig/design/` directory if it doesn't exist. If existing `.mmd` files are present, read them — these are living diagrams that evolve across iterations. Update and extend them based on research findings rather than replacing them.
2. Generate diagrams as appropriate for the iteration scope:
   - **Architecture diagram** (`.gig/design/architecture.mmd`) — system components and relationships
   - **Data flow diagram** (`.gig/design/data-flow.mmd`) — how data moves through the system
   - **Sequence diagram** (`.gig/design/sequence.mmd`) — key interaction sequences
   - **Entity relationship diagram** (`.gig/design/er.mmd`) — data models and relationships
3. Only generate diagrams that are relevant to the current iteration. Not every iteration needs all types.
4. If `.gig/DESIGN.md` exists, reference Figma prototypes in the diagrams where UI components interact with the system.
5. Present the diagrams in the conversation for review. The user can view rendered output in VS Code with a Mermaid preview extension.
6. After updating diagrams, summarize changes in the conversation before presenting decisions:
   - **Updated:** {list of modified .mmd files with one-line change description}
   - **Added:** {list of new .mmd files created this iteration}
   - **Unchanged:** {list of .mmd files that didn't need changes}

These diagrams inform decisions in Step 4 and are referenced in the plan.

### Step 4 — Present Decisions

Ask yourself every question that needs answering. For each, make a decision.
Organize into a single batch of 3-7 decisions.

**Per decision:**
- Be opinionated. Make a clear choice. Do not hedge.
- Reference specific research findings.
- Each decision is atomic — one choice per entry.
- Use ID format: `D-{batch}.{num}` (e.g., D-1.1, D-1.2)
- **If a spec exists:** link each decision to its requirement ID (REQ column). Decisions that can't trace to a requirement should be flagged — either the spec needs amending or the decision is out of scope.
- **If DESIGN.md exists:** reference relevant Figma screens in rationale for UI-related decisions. Use format: "See design: {screen name} ({Figma link})".
- **If Mermaid diagrams were generated:** reference them in rationale for architectural decisions. Use format: "See diagram: `.gig/design/{filename}`".

If more than 7 decisions are needed, split into multiple batches and present sequentially.

Update `.gig/STATE.md`:
- Set **Iteration** to the goal/topic being decided on.
- Set **Status** to `GATHERING`.

**Do NOT write to DECISIONS.md yet.** Present decisions in chat only.

**If a spec exists:** Include `**Spec:** v{X.Y}` (read from the SPEC.md version header) when presenting the decision batch.

### APPROVAL GATE 1 — Decisions

**Present the following table in full. Do not abbreviate, inline, or collapse into prose.**

| ID | REQ | Decision | Choice | Rationale (1-line) |
|----|-----|----------|--------|-------------------|

If no spec exists, omit the REQ column.

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
**Spec:** v{X.Y}
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
**Type:** {feature | refactor}
**Spec:** v{X.Y}
**Files:** {files to create or modify}
**Work:** {What to do}
**Test criteria:** {specific verification — command, file check, behavior}
**Acceptance:** {What "done" looks like}
```

Default type is `feature`. Set to `refactor` when the iteration goal is structural work or driven by DEBT.md items.

**Delegation defaults:**
- `team` — Independent batches with no dependency between them. **This is the default for implementation.** When 2+ batches have no dependency chain, mark them all as `team` so they execute in parallel via worktrees.
- `subagent` — Research/exploration feeding other tasks.
- `in-session` — Sequential, needs shared context or depends on another batch.

**Hard rule:** Every implementation batch MUST have test criteria.

Tag dependencies explicitly: "Depends on Batch X.Y".

### APPROVAL GATE 2 — Plan (via Plan Mode)

**Present the following plan in full with the batch table. Do not abbreviate or collapse into prose.**
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
**Type:** {feature | refactor}
**Spec:** v{X.Y}

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
