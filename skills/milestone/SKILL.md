---
name: gig:milestone
description: Create milestones with spec elicitation, complete milestones, manage ROADMAP.md, tag releases.
user-invocable: true
argument-hint: "[create | complete | view]"
---

# /gig:milestone Skill

## Step 0 — Auto-Load Context

Read `.gig/STATE.md` and `.gig/ROADMAP.md`.
Display: `Version: {version} | Iteration: {iteration} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Say: "No gig context found. Run `/gig:init` first." STOP.

## Step 1b — Resume Check

Read `.gig/STATE.md` to check current status.

**If status is `SPECING`:**

Elicitation was interrupted. Present options:

1. **Resume elicitation** — continue from where you left off.
2. **Start fresh** — discard draft and begin a new milestone.
3. **View roadmap** — show milestone/iteration overview.

- If **Resume:** Skip directly to Step 3a.3 (Load Project Context), which detects the partial SPEC.md and continues elicitation.
- If **Start fresh:** Reset SPEC.md to template state, then proceed to Step 2 normally.
- If **View roadmap:** Proceed to Step 3c.

**If status is `SPECCED`:**

Spec is already locked. Present options:

1. **Create new milestone** — start a new milestone (overwrites current spec).
2. **Complete current milestone** — verify all iterations done, tag, and archive.
3. **View roadmap** — show milestone/iteration overview.

Proceed to the selected action normally.

**Otherwise:** Proceed to Step 2.

## Step 2 — Determine Action

Use AskUserQuestion to present options:

1. **Create new milestone** — define scope with stories and requirements, then start building.
2. **Complete current milestone** — verify all iterations done, tag, and archive.
3. **View roadmap** — show milestone/iteration overview.

---

## Step 3a — Create New Milestone

### Step 3a.1 — Seed from Backlog

Read `.gig/BACKLOG.md`. If it has entries beyond the template:

Present backlog items as seed options:
"Found backlog items that could seed a milestone:"
- {list each backlog entry}

"Pick one to start from, or describe something new."

If the user picks a backlog entry, pre-populate the milestone name and description from it. Remove the consumed entry from BACKLOG.md.

If no backlog entries, skip to Step 3a.2.

### Step 3a.2 — Name and Version

1. Ask for (if not already seeded from backlog):
   - **Name:** short descriptive name
   - **Description:** one-line summary

2. **Propose a version** (do not ask — derive it):
   - Read Completed Milestones in `.gig/ROADMAP.md`.
   - No completed milestones: propose `v0.1.0`.
   - Otherwise: increment **minor** from highest completed (e.g., `0.1.0` → `0.2.0`).
   - Small scope (bug fixes, polish): increment **patch** instead (e.g., `0.2.0` → `0.2.1`).
   - **v1.0 guard:** NEVER propose `v1.0.0` or higher. Only the user may declare v1.0.
   - Present: `Proposed version: {version} — Reasoning: {why}`
   - User may adjust.

3. Update `.gig/ROADMAP.md`:
   - Set Current Milestone with name, version, status "in-progress", description.
   - Clear Iterations table.
   - **Preserve** the Upcoming Milestones table — existing entries are future feature proposals.

4. Update `.gig/STATE.md`:
   - Working Memory: milestone context.
   - Status: `SPECING`
   - Last Updated: today's date.

### Step 3a.3 — Load Project Context

Read these files for background:
1. `.gig/ARCHITECTURE.md` — project structure, stack, patterns
2. `.gig/ROADMAP.md` — current milestone, completed iterations
3. `.gig/BACKLOG.md` — remaining backlog ideas
4. `.gig/ISSUES.md` — open/deferred issues
5. `.gig/SPEC.md` — if resuming a draft spec from a prior session
6. `.gig/MVP.md` — if present, the MVP product discovery document

If `.gig/SPEC.md` exists and has content beyond the template, present it:
"Found existing spec draft. Resuming from where you left off."

If `.gig/MVP.md` exists and has content beyond the template, note it:
"Found MVP discovery document. Will use it to pre-populate stories and requirements."

### Step 3a.4 — Elicitation

This is an interactive conversation. Claude guides the user to articulate what they want clearly enough that gather can make decisions without assumptions.

#### Starting the Conversation

**If user says "baseline" or "reverse-engineer" (or provided args containing these words):**

Jump to the **Baseline from Iterations** flow below.

**If user says "mvp" (or provided args containing "mvp"), OR this is a new project (no completed iterations and no source code):**

Jump to the **MVP Product Discovery** flow below.

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

**If the user already stated their goal (same message or prior context):** Skip the assessment and start elicitation directly.

#### MVP-Aware Elicitation

**If `.gig/MVP.md` was loaded in Step 3a.3 and has content beyond the template** (and this is NOT an MVP or baseline flow):

Before starting normal elicitation, pre-populate from the MVP document:

1. **Extract story candidates** from MVP Core Flows — each flow maps to a candidate user story. Present them as draft US-XXX entries for the user to confirm or adjust.

2. **Extract requirement candidates** from MVP Screens and Data Model — each screen maps to requirements about what it must display/do, each entity maps to data requirements. Present them as draft REQ-XXX entries.

3. **Surface Open Questions** from MVP.md:
   "These items were flagged as open questions during MVP discovery — let's resolve them now before building the spec:"
   - {list each open question}

4. Present the pre-populated draft:
   "Found MVP discovery document. Pre-populated **{N} story candidates** and **{M} requirement candidates** from your flows and screens. Let's refine them."

Then continue with normal elicitation — the user adjusts, adds, removes, and the standard elicitation behaviors apply.

#### Baseline from Iterations

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

6. The user reviews, adjusts existing items, and adds new stories/requirements. New items get status `NOT COVERED`. Then continue to the **Lock Gate** (Step 3a.5).

#### MVP Product Discovery

A structured interview that produces `.gig/MVP.md` — a product discovery document with flows, screens, data model, and boundaries. Use this for new projects or existing projects that need to think through the product before coding.

**If the project has existing context** (`.gig/ARCHITECTURE.md` has content beyond the template, or `.gig/ROADMAP.md` has completed iterations): Read both files before starting. Reference existing architecture and capabilities when asking questions — the interview should build on what exists, not ignore it.

**If `.gig/MVP.md` already exists and has content beyond the template:** Present it and ask: "Found existing MVP discovery document. Resume editing or start fresh?" If resume, pre-populate the running draft from the existing file. If fresh, proceed with a blank slate.

The interview uses **clustered questions** — each section presents 2-4 related questions at once. After the user answers, show a running draft of that section for course-correction before moving to the next.

**Handling unknowns:** When the user says "I don't know" or is uncertain, ask ONE follow-up to help them think through it (e.g., "If you had to pick, would it be more like X or Y?"). If still uncertain after the follow-up, add it to the Open Questions section and move on.

**Handling multiple user types:** When the user identifies multiple user types in Section 1, interview all types together. Annotate flows and screens with which role performs/sees them. Shared elements are noted as shared; role-specific elements are tagged with the user type.

##### Section 1 — Vision & Problem

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

##### Section 2 — Inspiration

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

##### Section 3 — Core Flows

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

##### Section 4 — Screens

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

##### Section 5 — Data Model

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

##### Section 6 — Success Metrics

Ask as a cluster:
- "How will you know the MVP is working? What would you measure or observe?"
- "What does 'good enough' look like for launch? What quality bar are you setting?"

If the user is uncertain, push once: "Think about it from the user's perspective — what would make them come back a second time?" If still uncertain, flag as open question.

After answers, update running draft with metrics.

##### Section 7 — Boundaries & Open Questions

Ask as a cluster:
- "What is explicitly NOT in the MVP? What features are tempting but should wait?"
- "Any technical constraints? (specific stack, hosting, integrations, budget)"
- "Anything else that's still unclear or that we should flag for later?"

Surface all items flagged as open questions during earlier sections:
"During our conversation, these items were flagged as open questions: {list}. Want to resolve any of them now, or keep them flagged for spec?"

After answers, update running draft with boundaries, constraints, and final open questions list.

##### MVP Running Draft

After EACH section, present the full accumulated MVP.md draft so far:

```
### MVP Draft (Section {N}/7 complete)

{Full accumulated content from all completed sections}
```

Do NOT write to `.gig/MVP.md` during the interview — keep the draft in the conversation. Only write on lock.

##### MVP Lock Gate

After all 7 sections are complete, present the full MVP.md document. Do not abbreviate, inline, or collapse into prose.

Then ask:

> **Does this capture your MVP vision?**
>
> - **"lock"** / **"approve"** — write MVP.md and continue to spec elicitation.
> - **"change X"** — adjust specific sections before locking.
> - **"not yet"** — continue refining (go back to any section).

**STOP. Do not write MVP.md. Wait for approval.**

##### After MVP Lock — Write MVP and Continue

Once the user approves:

1. **Write `.gig/MVP.md`** with the locked content. Overwrite any existing draft.

2. **Derive documentation needs from MVP.md:**

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
   >
   > "Documentation plan written to `.gig/DOCS.md`. Govern will track freshness."

3. **Continue to spec elicitation** — pre-populate stories and requirements from the MVP document using the MVP-Aware Elicitation flow above. Do NOT stop or ask the user to run a separate command.

#### Background Research During Elicitation

During the elicitation conversation, use `run_in_background` to launch research agents when the user mentions topics that benefit from investigation. This keeps the conversation flowing while research completes.

**When to launch:**
- User mentions a specific area of the codebase → launch Architecture Agent in background
- User describes quality concerns → launch Quality Agent in background
- User references prior iterations or patterns → launch Discovery Agent in background

**When to collect:**
- Before presenting the running draft that incorporates findings
- Before asking follow-up questions that depend on research results

Do NOT block the conversation waiting for background agents. Ask the next question while research runs.

#### Elicitation Behaviors

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

#### Running Draft

After each substantive exchange, present the updated spec draft so the user can see it taking shape. Use the SPEC.md format:

```
### Current Draft

**Stories:** {count}
**Requirements:** {count}
**Constraints:** {count}

{Show the most recently added/changed items}
```

Do NOT write to `.gig/SPEC.md` during elicitation — keep the draft in the conversation. Only write on lock.

#### Continuing the Conversation

Keep asking questions until:
- All stories have at least one requirement
- All requirements have acceptance criteria
- No known ambiguities remain
- The user says "lock", "done", or "that's everything"

If the user seems done but gaps remain, surface them:
"Before locking, I notice {gap}. Want to address it or mark it out of scope?"

### Step 3a.5 — Lock Gate

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
> - **"lock"** / **"approve"** — write the spec and start building.
> - **"change X"** — adjust specific items before locking.
> - **"not yet"** — continue elicitation (go back to Step 3a.4).

**STOP. Do not write SPEC.md. Do not proceed to gather. Wait for approval.**

### Step 3a.6 — Write Milestone + Spec

Once the user approves:

1. **Write `.gig/SPEC.md`** with the locked spec content. Overwrite any existing draft.

2. **Update `.gig/STATE.md`:**
   - **Status:** `SPECCED`
   - **Last Updated:** today's date

3. Say:

> "Milestone **{name}** v{version} created with {N} stories and {M} requirements."
>
> "Run `/gig:design` to brainstorm with mockups and diagrams first, or `/gig:gather` to start making decisions directly."

---

## Step 3b — Complete Current Milestone

1. **Verify completion:**
   - Read ROADMAP.md iterations table.
   - All iterations must be "complete" or "verified".
   - If incomplete, list them and STOP.

2. **Note upcoming milestones** (informational only):
   - Read the Upcoming Milestones table in ROADMAP.md.
   - If entries exist, note: "Upcoming milestones on roadmap: {list names}."

3. **Single confirmation:**
   - Present milestone summary with iteration count and version.
   - Ask: "Complete milestone **{name}** v{version}? This will tag the release and archive."

4. **After confirmation:**
   - If in a git repo: create annotated tag on main:
     ```
     git tag -a v{version} -m "Milestone: {name}"
     ```
     Reference: `.gig/GIT-STRATEGY.md` for full conventions. Never move or delete tags.
   - Move Current Milestone to Completed Milestones in ROADMAP.md using the rich format:
     ```
     ### v{version} — {Name} (completed {TODAY'S DATE})

     {Description}

     **Iterations:**
     {For each iteration in the Iterations table, format as:}
     {N}. {Name} (v0.{N}.{first-batch}–v0.{N}.{last-batch})
     ```
     Derive version ranges from the Iterations table's "Version Range" column.
   - Clear Current Milestone section.
   - If `.gig/SPEC.md` exists: archive it to `.gig/iterations/` as `SPEC-{milestone-version}.md` (frozen snapshot of the completed spec with all statuses). Then reset SPEC.md to template state.
   - Update STATE.md: set status to `IDLE`, clear iteration/batch.

5. **Push (if remote exists):**
   - Check: `git remote` — if output is non-empty, a remote is configured.
   - Push main and tags: `git push origin main --tags`
   - Report: "Pushed to origin." or note if push fails.
   - If no remote, skip silently.

6. Say: "Milestone v{version} complete. Run `/gig:milestone` to create the next one."

---

## Step 3c — View Roadmap

1. Read `.gig/ROADMAP.md`.
2. Also list `.gig/iterations/` directory for archived iteration history.
3. Present formatted summary:
   ```
   Current Milestone: {name} v{version} ({status})

   Iterations:
     {list from roadmap table}

   Upcoming Milestones:
     {list from Upcoming Milestones table, or "None"}

   Archived:
     {list from .gig/iterations/ directory}

   Completed Milestones:
     v{X.Y} — {name} ({date})
   ```
4. Offer: "What would you like to do next?"
