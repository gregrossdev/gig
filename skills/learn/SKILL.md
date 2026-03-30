---
name: gig:learn
description: Create structured lesson plans for learning new concepts or following courses.
user-invocable: true
argument-hint: "[topic | course URL | from scratch]"
---

# /gig:learn Skill

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
Say: "An iteration is in progress. Complete it before starting a new lesson plan." STOP.

**If status is SPECCED:**
Warn: "A locked spec already exists. Running `/gig:learn` will create a new curriculum. Continue?"
If user says no, STOP.
If user says yes, proceed (spec skill's archiving logic handles the old spec).

**If status is IDLE, GOVERNED, or SPECING (resuming):**
Proceed.

## Step 2 — Detect Learning Mode

**If user provided args containing a URL (http/https):**
Say: "Detected external course URL. I'll analyze the course structure and build a curriculum around it."
Set mode to `external`. Jump to **External Course Flow** below.

**If user provided args containing "from scratch":**
Say: "Building a curriculum from scratch."
Set mode to `fresh`. Jump to **Fresh Curriculum Flow** below.

**If user provided other args:**
Use the args as the topic. Ask ONE question:
"Creating a curriculum from scratch, or following an existing course?"
- **"from scratch"** → fresh mode
- **"course"** or provides URL → external mode

**If no args:**
Ask: "What do you want to learn? (Topic, course URL, or describe what you're trying to understand)"

## Step 3 — Build Curriculum

### Fresh Curriculum Flow

1. **Research the topic** using subagents (Agent tool, subagent_type "Explore") and WebSearch:
   - What are the core concepts and standard learning progression?
   - What prerequisites exist?
   - What are common problem-solving patterns in this domain?
   - What resources (books, docs, platforms) are authoritative?

2. **Design the curriculum:**
   - Break into 5-12 lessons ordered by progression (simple → complex)
   - Each lesson focuses on ONE concept or pattern
   - Each lesson has 2-4 learning objectives (concrete, testable)
   - Identify dependencies between lessons

3. **Present the draft curriculum** (see Running Draft below).

### External Course Flow

1. **Research the course** using WebSearch and subagents:
   - Course structure (modules, lessons, topics)
   - Learning objectives per module
   - Prerequisites
   - Exercises or projects included

2. **Map to curriculum format:**
   - Each course module becomes a lesson (story)
   - Each module's learning objectives become requirements
   - Preserve the course's progression order
   - Note which parts are theory vs practice

3. **Present the draft curriculum** (see Running Draft below).

### Running Draft

After building the curriculum, present it in spec format:

```
### Curriculum Draft: {Topic}

**Mode:** {from scratch | following {course name}}
**Lessons:** {count}
**Estimated progression:** {description of learning arc}

## Stories (Lessons)

| ID | Lesson | Focus | Prerequisites | Status |
|----|--------|-------|--------------|--------|
| US-001 | {Lesson 1 title} | {concept} | — | NOT COVERED |
| US-002 | {Lesson 2 title} | {concept} | US-001 | NOT COVERED |
| ... | ... | ... | ... | ... |

## Requirements (Learning Objectives)

| ID | Lesson | Objective | How to verify | Priority | Status |
|----|--------|-----------|--------------|----------|--------|
| REQ-001 | US-001 | {Understand X} | {Can explain X, solve Y type problem} | must | NOT COVERED |
| REQ-002 | US-001 | {Apply X to Y} | {Can implement Z pattern} | must | NOT COVERED |
| ... | ... | ... | ... | ... | ... |
```

### Continuing the Conversation

Keep refining until:
- All lessons have at least one learning objective
- Prerequisites between lessons are clear
- The user confirms the scope and order

If the user seems done but gaps remain, surface them:
"Before locking, I notice {gap}. Want to add a lesson for it or mark it out of scope?"

## Step 4 — Lock Gate

**Present the complete curriculum in full SPEC.md format.**

Map the curriculum to standard spec format:
- **Stories** = Lessons (with `Scope Notes` = focus area)
- **Requirements** = Learning objectives (with `Acceptance Criteria` = how to verify learning)
- **Constraints** = Prerequisites, time commitments, tools needed
- **Out of Scope** = Topics explicitly excluded
- **Clarifications** = Learning approach decisions (e.g., "theory before practice" or "learn by doing")

Then ask:

> **Does this curriculum match what you want to learn?**
>
> - **"lock"** / **"approve"** — write the curriculum and start learning.
> - **"change X"** — adjust lessons, add/remove objectives.
> - **"not yet"** — continue refining.

**STOP. Do not write SPEC.md. Wait for approval.**

## After Lock — Write Curriculum

Once the user approves:

1. **Write `.gig/SPEC.md`** with the locked curriculum in standard spec format. Overwrite any existing draft.

2. **Update `.gig/STATE.md`:**
   - **Status:** `SPECCED`
   - **Last Updated:** today's date

3. Say:

> "Curriculum locked with {N} lessons and {M} learning objectives."
>
> "Run `/gig:gather` to start the first lesson. Each lesson runs through the normal gather→implement→govern flow."
>
> "After each lesson, governance generates an article capturing what you learned."
