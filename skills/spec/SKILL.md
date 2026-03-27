---
name: gig:spec
description: Build a complete spec through interactive conversation so gather produces plans that execute cleanly.
user-invocable: true
argument-hint: "[topic or goal]"
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
Warn: "A locked spec already exists. Running `/gig:spec` will start a new elicitation. Continue?"
If user says no, STOP.

**If status is IDLE, GOVERNED, or SPECING (resuming):**
Proceed.

## Step 2 — Load Project Context

Read these files for background:
1. `.gig/ARCHITECTURE.md` — project structure, stack, patterns
2. `.gig/ROADMAP.md` — current milestone, completed iterations
3. `.gig/BACKLOG.md` — backlog ideas that might inform the spec
4. `.gig/ISSUES.md` — open/deferred issues
5. `.gig/SPEC.md` — if resuming a draft spec

If `.gig/SPEC.md` exists and has content beyond the template, present it:
"Found existing spec draft. Resuming from where you left off."

## Step 3 — Elicitation

This is an interactive conversation. Claude guides the user to articulate what they want clearly enough that gather can make decisions without assumptions.

**Update `.gig/STATE.md`:**
- Set **Status** to `SPECING`
- Set **Last Updated** to today's date

### Starting the Conversation

**If user provided args:** Use the args as the starting topic. Begin with: "Let's build a spec for **{topic}**. I'll help you define what you want so gather can execute it cleanly."

**If no args and the project has completed iterations (existing project):**

Launch 1 Explore subagent (Agent tool, subagent_type "Explore") to analyze the current project state. The agent receives ARCHITECTURE.md, ROADMAP.md (completed iterations), BACKLOG.md, and ISSUES.md.

The agent investigates:
1. What the project can do now (working features, capabilities)
2. What's rough, incomplete, or missing
3. Structural or quality concerns

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

| ID | Story | Priority | Scope Notes |
|----|-------|----------|------------|
| US-001 | As a ..., I want ..., so that ... | core | ... |
| ... | ... | ... | ... |

## Requirements

| ID | Story | Description | Acceptance Criteria | Priority | Dependencies |
|----|-------|-------------|---------------------|----------|-------------|
| REQ-001 | US-001 | ... | ... | must | — |
| ... | ... | ... | ... | ... | ... |

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
