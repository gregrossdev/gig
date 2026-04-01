---
name: gig:spec
description: Build a complete spec through interactive conversation so gather produces plans that execute cleanly.
user-invocable: true
argument-hint: "[topic or goal | baseline]"
---

# /gig:spec Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

**If present:**
Read `.gig/STATE.md` for current position.

**If status is GATHERING, IMPLEMENTING, or IMPLEMENTED:**
Say: "An iteration is in progress. Complete it before starting a new spec." STOP.

**If status is SPECCED:**

1. Read `.gig/SPEC.md` and check the `Status` column in the Requirements table.
2. **If ALL requirements have status `COVERED`:**
   - Auto-archive: copy `.gig/SPEC.md` to `.gig/iterations/SPEC-completed-{today's date}.md`
   - Say: "Previous spec fully covered — archived to `.gig/iterations/SPEC-completed-{date}.md`. Starting fresh elicitation."
   - Proceed to Step 2.
3. **If ANY requirements have status `NOT COVERED`:**
   - Warn: "Existing spec has uncovered requirements: {list REQ IDs with NOT COVERED status}. Archive incomplete spec and continue?"
   - If user says yes: copy `.gig/SPEC.md` to `.gig/iterations/SPEC-partial-{today's date}.md`, then proceed to Step 2.
   - If user says no: STOP.
4. **If SPEC.md is empty or template-only:** Proceed without archiving.

**If status is IDLE, GOVERNED, or SPECING (resuming):**
Proceed.

## Step 2 — Load Project Context

Read these files for background:
1. `.gig/ARCHITECTURE.md` — project structure, stack, patterns
2. `.gig/ROADMAP.md` — current milestone, completed iterations
3. `.gig/BACKLOG.md` — backlog ideas that might inform the spec
4. `.gig/ISSUES.md` — open/deferred issues
5. `.gig/SPEC.md` — if resuming a draft spec
6. `.gig/MVP.md` — if present, the MVP product discovery document

If `.gig/SPEC.md` exists and has content beyond the template, present it:
"Found existing spec draft. Resuming from where you left off."

If `.gig/MVP.md` exists and has content beyond the template, note it for use in Step 3:
"Found MVP discovery document. Will use it to pre-populate stories and requirements."

## Step 3 — Elicitation

This is an interactive conversation. Claude guides the user to articulate what they want clearly enough that gather can make decisions without assumptions.

**Update `.gig/STATE.md`:**
- Set **Status** to `SPECING`
- Set **Last Updated** to today's date

### Starting the Conversation

**If user says "baseline" or "reverse-engineer" (or provided args containing these words):**

Jump to the **Baseline from Iterations** flow below.

**If user says "mvp" (or provided args containing "mvp"):**

Jump to the **MVP Product Discovery** flow below.

**If user provided other args:** Use the args as the starting topic. Begin with: "Let's build a spec for **{topic}**. I'll help you define what you want so gather can execute it cleanly."

**If no args and the project has completed iterations (existing project):**

Launch 3 Explore agents in parallel (Agent tool, subagent_type "Explore"), one per profile:

- **Architecture Agent** — Investigate current project structure, stack health, and pattern consistency. Receives: `.gig/ARCHITECTURE.md`, package/config files.
- **Quality Agent** — Investigate test coverage, code quality, broken/stale behavior, and technical debt. Receives: test files, lint config, `.gig/ISSUES.md`.
- **Discovery Agent** — Investigate what the project can do now, what's rough or incomplete, feature gaps, and opportunities. Receives: `.gig/ROADMAP.md`, `.gig/BACKLOG.md`, `.gig/ISSUES.md`.

Synthesize findings from all 3 agents into a unified project assessment before presenting directions.

Present a project assessment and propose directions:

```
### Your Project Now

{2-3 sentence assessment of current state and capabilities}

### Suggested Directions

1. **{Direction}** ({type: refactor / feature / enhancement / testing / docs}) — {why this matters now}
2. **{Direction}** ({type}) — {why}
3. **{Direction}** ({type}) — {why}

Pick a direction to spec out, combine them, or tell me what you have in mind.
```

The user picks a direction (or states their own), then elicitation continues normally.

**If no args and new project (no completed iterations):** Ask ONE question: "What are you trying to build or accomplish?"

### MVP-Aware Elicitation

**If `.gig/MVP.md` was loaded in Step 2 and has content beyond the template** (and this is NOT an MVP or baseline flow):

Before starting normal elicitation, pre-populate from the MVP document:

1. **Extract story candidates** from MVP Core Flows — each flow maps to a candidate user story. Present them as draft US-XXX entries for the user to confirm or adjust.

2. **Extract requirement candidates** from MVP Screens and Data Model — each screen maps to requirements about what it must display/do, each entity maps to data requirements. Present them as draft REQ-XXX entries.

3. **Surface Open Questions** from MVP.md:
   "These items were flagged as open questions during MVP discovery — let's resolve them now before building the spec:"
   - {list each open question}

4. Present the pre-populated draft:
   "Found MVP discovery document. Pre-populated **{N} story candidates** and **{M} requirement candidates** from your flows and screens. Let's refine them."

Then continue with normal elicitation — the user adjusts, adds, removes, and the standard elicitation behaviors apply.

### Baseline from Iterations

For existing projects that want to capture what's already been built as a spec. This reverse-engineers user stories and requirements from iteration history.

1. **Read all archived iterations:** Scan `.gig/iterations/` for completed iteration archives. For each, read PLAN.md (batch details, acceptance criteria) and DECISIONS.md (what was decided and why).

2. **Read current state:** Read `.gig/ARCHITECTURE.md`, `.gig/ROADMAP.md` (completed milestones and iterations).

3. **Launch 3 Explore agents in parallel** (Agent tool, subagent_type "Explore"), one per profile:
   - **Architecture Agent:** Group completed iterations into user stories — what user-facing capability did each cluster of iterations deliver? Assign IDs: US-001, US-002, etc.
   - **Quality Agent:** Extract requirements from batch acceptance criteria and test criteria across all iterations. Link each to its parent story. Assign IDs: REQ-001, REQ-002, etc.
   - **Discovery Agent:** Detect patterns, themes, and cross-cutting concerns across iterations. Identify architectural trends, recurring problem areas, and capabilities that span multiple stories.

4. **Present the baseline draft spec:**

```
### Baseline Spec (reverse-engineered from {N} iterations)

## Stories

| ID | Story | Priority | Status |
|----|-------|----------|--------|
| US-001 | As a ..., I want ..., so that ... | core | DELIVERED |
| US-002 | ... | core | DELIVERED |
| ... | ... | ... | ... |

## Requirements

| ID | Story | Description | Acceptance Criteria | Status | Iteration |
|----|-------|-------------|---------------------|--------|-----------|
| REQ-001 | US-001 | ... | ... | COVERED | v0.X.Y |
| REQ-002 | US-001 | ... | ... | COVERED | v0.X.Y |
| ... | ... | ... | ... | ... | ... |

All {count} requirements are marked COVERED — these represent what's already built.
```

5. **Ask the user to review and extend:**

> "This is what your project has built so far. Review the stories and requirements — adjust anything that's wrong."
>
> "To add NEW work, describe what you want next. I'll add new stories and requirements with status NOT COVERED. Govern will track them going forward."

6. The user reviews, adjusts existing items, and adds new stories/requirements. New items get status `NOT COVERED`. Then continue to the **Lock Gate** (Step 4).

### MVP Product Discovery

A structured interview that produces `.gig/MVP.md` — a product discovery document with flows, screens, data model, and boundaries. Use this for new projects or existing projects that need to think through the product before coding.

**If the project has existing context** (`.gig/ARCHITECTURE.md` has content beyond the template, or `.gig/ROADMAP.md` has completed iterations): Read both files before starting. Reference existing architecture and capabilities when asking questions — the interview should build on what exists, not ignore it.

**If `.gig/MVP.md` already exists and has content beyond the template:** Present it and ask: "Found existing MVP discovery document. Resume editing or start fresh?" If resume, pre-populate the running draft from the existing file. If fresh, proceed with a blank slate.

The interview uses **clustered questions** — each section presents 2-4 related questions at once. After the user answers, show a running draft of that section for course-correction before moving to the next.

**Handling unknowns:** When the user says "I don't know" or is uncertain, ask ONE follow-up to help them think through it (e.g., "If you had to pick, would it be more like X or Y?"). If still uncertain after the follow-up, add it to the Open Questions section and move on.

**Handling multiple user types:** When the user identifies multiple user types in Section 1, interview all types together. Annotate flows and screens with which role performs/sees them. Shared elements are noted as shared; role-specific elements are tagged with the user type.

#### Section 1 — Vision & Problem

Ask as a cluster:
- "What are you building? Give me the elevator pitch — one or two sentences."
- "Who are the users? If there are different types (admin, customer, etc.), name them."
- "What problem does this solve? What do users do today without this tool?"

After answers, present running draft:

```
### MVP Draft (Section 1/7 complete)

## Vision

**Product:** {elevator pitch}
**Target Users:** {user types}
**Problem:** {problem statement}
**What exists today:** {current state}
```

#### Section 2 — Inspiration

Ask as a cluster:
- "Name 1-3 existing products that do something similar or inspired this idea."
- "For each: what do you want to borrow from it? What do you want to avoid?"

Use the inspiration answers to ground follow-up questions in later sections. For example, if the user says "like Trello but for X," ask about differences from Trello when discussing flows and screens.

After answers, update running draft adding:

```
## Inspiration

| Product | Borrow | Avoid |
|---------|--------|-------|
| {product} | {what to borrow} | {what to avoid} |
```

#### Section 3 — Core Flows

Ask as a cluster:
- "Walk me through the main thing a user does, step by step. Start from the beginning."
- "Are there other key flows? (onboarding, settings, admin tasks, etc.)"
- "For each flow: what can go wrong? What happens when something fails or the user makes a mistake?"

If multiple user types were identified in Section 1, ask: "Which user type performs each flow?"

For each flow described, generate a Mermaid flowchart:

```mermaid
flowchart TD
    A[{first step}] --> B[{second step}]
    B --> C{Decision point}
    C -->|Option 1| D[{outcome}]
    C -->|Option 2| E[{outcome}]
```

If a flow is role-specific, add a comment: `%% Role: {user type}`

After answers, update running draft with all flows and their Mermaid diagrams.

#### Section 4 — Screens

Ask as a cluster:
- "Based on the flows we just mapped, what screens or pages does the user see?"
- "For each key screen: describe what's on it — what does the user see and interact with?"
- "Which screens are shared across user types, and which are role-specific?"

Generate a screen inventory table:

```
| Screen | Purpose | User Types |
|--------|---------|------------|
| {name} | {what it does} | {all / specific role} |
```

For each key screen, generate an ASCII mockup showing rough layout:

```
### {Screen Name}
{Brief description of purpose and what the user does here.}

┌─────────────────────────────────┐
│ {Header / Nav}                  │
├─────────────────────────────────┤
│ ┌───────────┐  ┌─────────────┐ │
│ │ {Section}  │  │ {Section}   │ │
│ │ {content}  │  │ {content}   │ │
│ └───────────┘  └─────────────┘ │
├─────────────────────────────────┤
│ {Actions / Footer}              │
└─────────────────────────────────┘
```

After answers, update running draft with screen inventory and mockups.

#### Section 5 — Data Model

Ask as a cluster:
- "What are the main things (entities) the system needs to track? (e.g., users, projects, tasks, orders)"
- "For each entity: what are the key attributes? How does it relate to other entities?"
- "Do any entities have states they move through? (e.g., an order goes from pending → paid → shipped)"

Generate an entity table:

```
| Entity | Key Attributes | Relationships |
|--------|---------------|---------------|
| {name} | {attr1, attr2, ...} | {belongs to X, has many Y} |
```

For stateful entities, generate Mermaid state diagrams:

```mermaid
stateDiagram-v2
    [*] --> {initial state}
    {state1} --> {state2}: {trigger}
    {state2} --> {state3}: {trigger}
```

After answers, update running draft with entity table and state diagrams.

#### Section 6 — Success Metrics

Ask as a cluster:
- "How will you know the MVP is working? What would you measure or observe?"
- "What does 'good enough' look like for launch? What quality bar are you setting?"

If the user is uncertain, push once: "Think about it from the user's perspective — what would make them come back a second time?" If still uncertain, flag as open question.

After answers, update running draft with metrics.

#### Section 7 — Boundaries & Open Questions

Ask as a cluster:
- "What is explicitly NOT in the MVP? What features are tempting but should wait?"
- "Any technical constraints? (specific stack, hosting, integrations, budget)"
- "Anything else that's still unclear or that we should flag for later?"

Surface all items flagged as open questions during earlier sections:
"During our conversation, these items were flagged as open questions: {list}. Want to resolve any of them now, or keep them flagged for spec?"

After answers, update running draft with boundaries, constraints, and final open questions list.

### MVP Running Draft

After EACH section, present the full accumulated MVP.md draft so far:

```
### MVP Draft (Section {N}/7 complete)

{Full accumulated content from all completed sections}
```

Do NOT write to `.gig/MVP.md` during the interview — keep the draft in the conversation. Only write on lock.

### MVP Lock Gate

After all 7 sections are complete, present the full MVP.md document. Do not abbreviate, inline, or collapse into prose.

Then ask:

> **Does this capture your MVP vision?**
>
> - **"lock"** / **"approve"** — write MVP.md and continue to spec.
> - **"change X"** — adjust specific sections before locking.
> - **"not yet"** — continue refining (go back to any section).

**STOP. Do not write MVP.md. Wait for approval.**

### After MVP Lock — Write MVP

Once the user approves:

1. **Write `.gig/MVP.md`** with the locked content. Overwrite any existing draft.

2. **Update `.gig/STATE.md`:**
   - **Status:** `SPECCED`
   - **Last Updated:** today's date

3. **Derive documentation needs from MVP.md:**

   Read the just-written MVP.md and `.gig/ARCHITECTURE.md` (if populated). For each section, determine if additional documentation beyond the minimum set (README, CHANGELOG, LICENSE) would help users of this project:

   - **Core Flows** — If flows describe API endpoints or service interactions → recommend API-REFERENCE.md
   - **Screens** — If UI screens are described → recommend USAGE.md (user guide)
   - **Boundaries & Constraints** — If deployment targets, hosting, or infrastructure mentioned → recommend DEPLOYMENT.md
   - **Vision / Target Users** — If open-source or team project → recommend CONTRIBUTING.md
   - **ARCHITECTURE.md stack** — If environment variables, config files, or multiple services → recommend ENV-SETUP.md

   Do NOT use a fixed mapping. Read the actual content and reason about what docs would help. The above are examples, not rules.

   **Write `.gig/DOCS.md`** with the derived documentation plan:
   - Add the minimum set (README.md, CHANGELOG.md, LICENSE) with status `scaffolded`
   - Add each derived doc with status `not-started`, noting which MVP section or ARCHITECTURE.md field informed the need
   - For each derived doc, copy the relevant template from `templates/docs/` (look in `${CLAUDE_PLUGIN_ROOT}/templates/docs/` then `~/.claude/templates/docs/`) to the project root

   Present the documentation plan:

   > "Based on your MVP, this project needs these docs beyond the basics:"
   > - {doc} — {reason} (template scaffolded)
   > - {doc} — {reason} (template scaffolded)
   >
   > "Documentation plan written to `.gig/DOCS.md`. Govern will track freshness."

4. Say:

> "MVP discovery locked. Run `/gig:spec` to build the detailed spec from this MVP — spec will pre-populate stories and requirements from your flows and screens."
>
> "Or run `/gig:gather` to plan implementation directly if the MVP is straightforward enough."

**After writing MVP.md and DOCS.md, STOP.** Do not auto-transition to spec elicitation. The user decides the next step.

### Background Research During Elicitation

During the elicitation conversation, use `run_in_background` to launch research agents when the user mentions topics that benefit from investigation. This keeps the conversation flowing while research completes.

**When to launch:**
- User mentions a specific area of the codebase → launch Architecture Agent in background
- User describes quality concerns → launch Quality Agent in background
- User references prior iterations or patterns → launch Discovery Agent in background

**When to collect:**
- Before presenting the running draft that incorporates findings
- Before asking follow-up questions that depend on research results

Do NOT block the conversation waiting for background agents. Ask the next question while research runs.

### Elicitation Behaviors

Claude's job is to draw out what the user knows but hasn't articulated:

**User Stories:**
- Help articulate stories in format: "As a [who], I want [what], so that [why]"
- Assign IDs: US-001, US-002, etc.
- For each story, ask: "What else does this need to handle?"
- Identify conflicts between stories
- Classify priority: core / enhancement / nice-to-have
- Define what's explicitly out of scope

**Requirements (derived from stories):**
- For each story, break into concrete, testable requirements
- Assign IDs: REQ-001 linked to parent US-001
- For each requirement, probe:
  - "What does done look like for this specifically?"
  - "Are there edge cases that matter?"
  - "Does this depend on anything else?"
- Classify priority: must / should / could
- Track dependencies between requirements

**Constraints:**
- Surface as they come up naturally during story/requirement discussion
- Ask about: existing patterns, compatibility, performance, conventions to follow/avoid
- Ask: "If two requirements conflict at implementation time, which wins?"

**Clarifications:**
- Record key Q&A exchanges that resolved ambiguity
- Format: Q: {question} → A: {answer}
- These help gather (and future sessions) understand *why* each requirement is shaped the way it is

### Running Draft

After each substantive exchange, present the updated spec draft so the user can see it taking shape. Use the SPEC.md format:

```
### Current Draft

**Stories:** {count}
**Requirements:** {count}
**Constraints:** {count}

{Show the most recently added/changed items}
```

Do NOT write to `.gig/SPEC.md` during elicitation — keep the draft in the conversation. Only write on lock.

### Continuing the Conversation

Keep asking questions until:
- All stories have at least one requirement
- All requirements have acceptance criteria
- No known ambiguities remain
- The user says "lock", "done", or "that's everything"

If the user seems done but gaps remain, surface them:
"Before locking, I notice {gap}. Want to address it or mark it out of scope?"

## Step 4 — Lock Gate

**Present the complete spec in full. Do not abbreviate, inline, or collapse into prose.**

Present the entire draft spec in SPEC.md format:

```
# Spec

## Stories

| ID | Story | Priority | Scope Notes | Status |
|----|-------|----------|------------|--------|
| US-001 | As a ..., I want ..., so that ... | core | ... | NOT COVERED |
| ... | ... | ... | ... | ... |

## Requirements

| ID | Story | Description | Acceptance Criteria | Priority | Dependencies | Status | Iteration |
|----|-------|-------------|---------------------|----------|-------------|--------|-----------|
| REQ-001 | US-001 | ... | ... | must | — | NOT COVERED | — |
| ... | ... | ... | ... | ... | ... | ... | ... |

## Constraints

- ...

## Out of Scope

- ...

## Clarifications

- Q: ... → A: ...
```

Then ask:

> **If gather executes this spec perfectly, does the result match what you have in your head?**
>
> - **"lock"** / **"approve"** — write the spec and mark it ready for gather.
> - **"change X"** — adjust specific items before locking.
> - **"not yet"** — continue elicitation (go back to Step 3).

**STOP. Do not write SPEC.md. Do not proceed to gather. Wait for approval.**

## After Lock — Write Spec

Once the user approves:

1. **Write `.gig/SPEC.md`** with the locked spec content. Overwrite any existing draft.

2. **Update `.gig/STATE.md`:**
   - **Status:** `SPECCED`
   - **Last Updated:** today's date

3. Say:

> "Spec locked. Run `/gig:gather` to start making decisions — gather will trace every decision back to these requirements."
>
> "To change the spec later, edit `.gig/SPEC.md` and re-run `/gig:gather`."
