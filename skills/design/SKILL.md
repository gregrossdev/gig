---
name: gig:design
description: Generate UI/UX prototypes in Figma and produce DESIGN.md with design decisions and links.
user-invocable: true
argument-hint: "[screen or flow to design]"
---

# /gig:design Skill

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
Say: "An iteration is in progress. Complete it before starting design." STOP.

**If status is DESIGNED:**
Warn: "A locked design already exists. Running `/gig:design` will start a new design session. Continue?"
If user says no, STOP.

**If status is SPECCED, IDLE, GOVERNED, or DESIGNING (resuming):**
Proceed.

## Step 2 — Load Context

Read these files for background:
1. `.gig/SPEC.md` — locked spec with stories, requirements, constraints
2. `.gig/ARCHITECTURE.md` — project structure, stack, patterns
3. `.gig/ROADMAP.md` — current milestone, completed iterations
4. `.gig/DESIGN.md` — if resuming a previous design session

If `.gig/SPEC.md` exists and has content beyond the template, use it as the foundation for design work. Every design should trace to a requirement in the spec.

If `.gig/SPEC.md` does not exist or is empty, print: "No spec found. Consider running `/gig:spec` first for complex features." Then proceed — ask the user what screens or flows need design.

If `.gig/DESIGN.md` exists and has content, present it: "Found existing design. Resuming from where you left off."

## Step 3 — Analyze Requirements

**If a spec exists:**

Review all requirements in `.gig/SPEC.md` and classify each:

| REQ ID | Description | Needs UI/UX Design? | Notes |
|--------|-------------|---------------------|-------|

Present the classification:
- Requirements needing UI/UX design: {list with REQ IDs}
- Requirements that are system-only (no design needed): {list}

Ask: "Want to design all UI requirements, or focus on specific ones?"

**If no spec:**

Ask: "What screens, flows, or UI components need design?" Use the user's response to define the design scope.

## Step 4 — Generate Figma Prototypes

**Update `.gig/STATE.md`:**
- Set **Status** to `DESIGNING`
- Set **Last Updated** to today's date

For each screen or flow in scope:

1. **Describe the design intent** — what the screen does, its layout, key components, user interactions. Reference ARCHITECTURE.md for stack/framework context.

2. **Generate the Figma design** — use `mcp__figma__generate_figma_design` or `mcp__figma__create_new_file` to create the design in Figma. Provide clear descriptions of:
   - Layout structure (header, sidebar, content area, etc.)
   - Key UI components (buttons, forms, tables, cards, etc.)
   - User flow connections (what happens on click, navigation paths)
   - Visual hierarchy and content placement

3. **Capture a screenshot** — use `mcp__figma__get_screenshot` to verify the design looks correct. Present it to the user.

4. **Track the design** — record: screen name, Figma file key, Figma URL, REQ IDs covered, design notes.

5. **Iterate** — if the user requests changes, use `mcp__figma__get_design_context` to read the current state, then regenerate or modify.

Repeat for each screen/flow until all in-scope designs are complete.

## Step 5 — Approval Gate

**Present the design summary table in full. Do not abbreviate, inline, or collapse into prose.**

| # | Screen/Flow | Figma Link | REQ IDs | Notes |
|---|-------------|------------|---------|-------|
| 1 | {name} | {Figma URL} | {REQ-001, REQ-002} | {key design decisions} |
| 2 | {name} | {Figma URL} | {REQ-003} | {notes} |
| ... | ... | ... | ... | ... |

Then say:

> **Does this design look good?**
>
> - **"approve"** / **"looks good"** — lock the design and write DESIGN.md.
> - **"change X"** — adjust specific screens before locking.
> - **"not yet"** — continue designing (go back to Step 4).

**STOP. Do not write DESIGN.md. Do not proceed to gather. Wait for approval.**

## After Approval — Write Design

Once the user approves:

1. **Write `.gig/DESIGN.md`** with the locked design content:

```markdown
# Design

> Locked design for the current iteration. Gather references these designs when making decisions.

## Design Summary

| # | Screen/Flow | Figma Link | REQ IDs | Notes |
|---|-------------|------------|---------|-------|
| {table rows from approval gate} |

## Screen Details

### {Screen Name}

**Figma:** {URL}
**Requirements:** {REQ IDs}
**Description:** {What this screen does and key design decisions}
**Components:** {Key UI components used}
**Interactions:** {User interactions and navigation}
```

2. **Update `.gig/STATE.md`:**
   - **Status:** `DESIGNED`
   - **Last Updated:** today's date

3. Say:

> "Design locked. Run `/gig:gather` to start making decisions — gather will reference these designs when making UI-related choices."
>
> "To change the design later, re-run `/gig:design`."
