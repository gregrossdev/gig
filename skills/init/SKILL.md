---
name: gig:init
description: Initialize the gig system in any project. Discovers context, scaffolds .gig/, proposes first milestone. Universal entry point.
user-invocable: true
---

# /gig:init Skill

## Step 0 — Guard Check

Check if `.gig/` already exists in the current project root.

**If present:**
Use AskUserQuestion:
1. **Reinitialize** — wipe `.gig/` and start fresh (destructive).
2. **Abort** — keep existing context.

If user chooses abort, STOP.
If user chooses reinitialize, delete `.gig/` and proceed.

## Step 1 — Scaffold .gig/

1. Create `.gig/` directory.
2. Create `.gig/phases/` directory (for completed phase archives).
3. Copy templates into `.gig/`:
   - Look for templates in this order: `${CLAUDE_PLUGIN_ROOT}/templates/` (plugin install), then `~/.claude/templates/gig/` (script install).
   - If templates are not found at either location, say: "Error: gig templates not found. Reinstall gig or check your installation." STOP.
   - Files: STATE.md, PLAN.md, DECISIONS.md, ISSUES.md, ARCHITECTURE.md, ROADMAP.md, GIT-STRATEGY.md
4. Say: "Initialized `.gig/` from templates."

## Step 2 — Detect Project Type

Scan the current directory to classify:

| Check | Signal |
|-------|--------|
| `.git/` exists | Git repository |
| `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `deno.json` | Package manager |
| `src/`, `lib/`, `app/` directories | Source code present |
| `Makefile`, `Dockerfile`, `docker-compose.yml` | Build/deploy tooling |
| `test/`, `tests/`, `__tests__/`, `spec/` | Test infrastructure |

Classify as:
- **New project** — empty or near-empty (no source code, no package files).
- **Existing project** — has source code, dependencies, or meaningful structure.

## Step 3 — Project Discovery (existing projects only)

**If new project:** Skip to Step 4.

**If existing project:** Use subagents (Agent tool, subagent_type "Explore") to discover:

1. **Structure** — directory layout, key file locations, naming conventions.
2. **Stack** — languages, frameworks, runtime, database, from package files and imports.
3. **Patterns** — architecture style (MVC, modular, monorepo, etc.), state management, API patterns.
4. **Dependencies** — key libraries and their purposes.
5. **Git history** — recent commits (last 10-20), branch structure, commit style.
6. **Tests** — test framework, coverage, test file locations.
7. **Config** — linters, formatters, CI/CD, environment setup.

Compile findings into a Discovery Report (internal context — findings are used directly in Steps 4-5, not written to a file).

## Step 4 — Populate Architecture

**If new project:**
Leave `.gig/ARCHITECTURE.md` as the blank template. User fills during `gig:gather`.

**If existing project:**
Update `.gig/ARCHITECTURE.md` with discovered context:
- **Overview:** one-paragraph summary.
- **Stack:** language, framework, runtime, database, key libraries.
- **Structure:** directory layout with purposes.
- **Patterns:** architecture style, conventions found.
- **External Dependencies:** APIs, services, infrastructure.

Mark uncertain sections with `[needs confirmation]`.

## Step 5 — Git Setup

If `.git/` does NOT exist and the project is new:
1. Run `git init`.
2. Create `.gitignore` if not present — include common ignores for the detected stack
   (e.g., `node_modules/`, `dist/`, `.env`, `*.sqlite` for Node; `target/` for Rust; etc.).
3. Add `.gig/` files and `.gitignore`.
4. Initial commit: `chore: initialize project`

If `.git/` already exists:
- Skip git init.
- Do NOT commit `.gig/` files yet — they'll be committed with the first batch.

Reference: `.gig/GIT-STRATEGY.md` for full branch/commit/tag conventions.

## Step 6 — Propose First Milestone

Based on discovery, propose the first milestone:

**For new projects:**
- Version: `0.1.0`
- Name: derived from project directory or user's stated goal.
- Description: "Initial project setup and foundation."

**For existing projects:**
- Version based on maturity:
  - Has basic structure but incomplete → `0.1.0` - `0.3.0`
  - Has working features but needs improvement → `0.4.0` - `0.6.0`
  - Substantial and mostly working → `0.7.0` - `0.9.0`
- Name: derived from most pressing next step.

**Hard rule:** NEVER propose v1.0.0 or higher. Stays 0.x.y until user explicitly declares v1.0.

## Step 7 — Write State

1. Update `.gig/ROADMAP.md`:
   - Set Current Milestone with name, version, status "in-progress", description.
   - Clear the Phases table.

2. Update `.gig/STATE.md`:
   - Version: `0.0.1`
   - Phase: 0 — Bootstrap
   - Status: `IDLE`
   - Last Batch: "Project discovery & scaffold"
   - Last Updated: today's date
   - Working Memory (the Working Memory section of STATE.md — key context like file paths, patterns, and conventions discovered during work): leave empty for now; populated during implement.

3. Add bootstrap entry to Batch History:
   `| 0.0.1 | 0 | Project discovery & scaffold | PLANNED | done | {today} |`

## APPROVAL GATE

Present to the user:

### For new projects:
```
Project initialized (new project).
Milestone: {name} v{version} — {description}
```

### For existing projects:
```
Project initialized (existing project).

Discovery summary:
  Stack: {languages, frameworks}
  Structure: {brief layout}
  Patterns: {architecture style}
  Tests: {framework, coverage}

Architecture populated: .gig/ARCHITECTURE.md

Milestone: {name} v{version} — {description}
  Reasoning: {why this version}
```

Then say:

> **Approval required.** Review the initialization above.
>
> - **Approve** — reply "approve" to lock in the milestone and proceed.
> - **Adjust version** — propose a different version number.
> - **Adjust milestone** — change the name or description.
> - **Review architecture** — I'll show the full ARCHITECTURE.md for review.
>
> After approval, run `/gig:gather` to start the first phase.

**STOP. Do not create phases. Do not make decisions. Wait for approval.**

## After Approval

1. If user adjusted version/name/description, update ROADMAP.md and STATE.md.
2. Say: "Project initialized. Run `/gig:gather` to start the first phase."
