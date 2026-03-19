---
name: gig:init
description: Initialize the gig system in any project. Discovers context, scaffolds .gig/, proposes first milestone. Universal entry point.
user-invocable: true
---

# /gig:init Skill

## Step 0 — Guard Check

Check if `.gig/` already exists in the current project root.

**If present:**

First, check for stale "phase" terminology and auto-migrate:
1. Read `.gig/STATE.md` — look for `| **Phase**`.
2. Read `.gig/ROADMAP.md` — look for `## Phases`.
3. If either marker is found, migrate:
   - **Plugin install:** Run `${CLAUDE_PLUGIN_ROOT}/migrate.sh` via Bash.
   - **Script install (or migrate.sh not found):** Use the Edit tool to perform these replacements in `.gig/`:
     - `STATE.md`: `| **Phase**` → `| **Iteration**`; `| Phase |` → `| Iteration |`
     - `ROADMAP.md`: `## Phases` → `## Iterations`; `## Upcoming Phases` → `## Upcoming Iterations`; `Pre-planned phases` → `Pre-planned iterations`
     - `ISSUES.md`: `archived with their phase` → `archived with their iteration`; `future phases` → `future iterations`; `future phase` → `future iteration`; `**Phase:**` → `**Iteration:**`
     - `ARCHITECTURE.md`: `Phase-based versioning` → `Iteration-based versioning`; `MINOR = phase number` → `MINOR = iteration number`; `milestone/phase hierarchy` → `milestone/iteration hierarchy`
   - Say: "Migrated .gig/ from 'phase' to 'iteration' terminology."
4. If neither marker is found, skip silently.

Then present choices via AskUserQuestion:
1. **Reinitialize** — wipe `.gig/` and start fresh (destructive).
2. **Abort** — keep existing context.

If user chooses abort, STOP.
If user chooses reinitialize, delete `.gig/` and proceed.

## Step 1 — Scaffold .gig/

1. Create `.gig/` directory.
2. Create `.gig/iterations/` directory (for completed iteration archives).
3. Copy templates into `.gig/`:
   - Look for templates in this order: `${CLAUDE_PLUGIN_ROOT}/templates/` (plugin install), then `~/.claude/templates/gig/` (script install).
   - If templates are not found at either location, say: "Error: gig templates not found. Reinstall gig or check your installation." STOP.
   - Files: STATE.md, PLAN.md, DECISIONS.md, ISSUES.md, ARCHITECTURE.md, ROADMAP.md, GIT-STRATEGY.md, ARTICLE.md
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
2. Create `.gitignore` if not present — include `.gig/`, `.claude/`, and common ignores for the detected stack
   (e.g., `node_modules/`, `dist/`, `.env`, `*.sqlite` for Node; `target/` for Rust; etc.).
3. Add `.gig/` files and `.gitignore`.
4. Initial commit: `chore: initialize project`

If `.git/` already exists:
- Skip git init.
- Ensure `.gig/` and `.claude/` are in `.gitignore` — if not present, append them to the file (create `.gitignore` if it doesn't exist).
- Do NOT commit `.gig/` or `.claude/` files — they are local session state.

Reference: `.gig/GIT-STRATEGY.md` for full branch/commit/tag conventions.

## Step 6 — Set Up Project Rules

Add gig workflow rules to the project's `.claude/CLAUDE.md` so they apply when Claude Code runs in this project.

1. **Locate RULES.md:**
   - Plugin install: `${CLAUDE_PLUGIN_ROOT}/docs/RULES.md`
   - Script install: `~/.claude/templates/gig/RULES.md`
   - If not found at either location, say: "Warning: RULES.md not found. Skipping project rules setup. You can manually copy docs/RULES.md to `.claude/CLAUDE.md`." and skip this step.

2. **Create `.claude/` directory** in the project root if not present.

3. **Check for existing gig rules:** If `.claude/CLAUDE.md` exists and contains `# --- gig workflow rules ---`, remove the section between the markers (inclusive) first. This ensures idempotent updates.

4. **Append gig rules** to `.claude/CLAUDE.md` (create the file if it doesn't exist):
   ```
   # --- gig workflow rules ---

   {contents of RULES.md}

   # --- end gig workflow rules ---
   ```

5. Say: "Added gig workflow rules to `.claude/CLAUDE.md`."

## Step 7 — Propose First Milestone

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

## Step 8 — Write State

1. Update `.gig/ROADMAP.md`:
   - Set Current Milestone with name, version, status "in-progress", description.
   - Clear the Iterations table.

2. Update `.gig/STATE.md`:
   - Version: `0.0.1`
   - Iteration: 0 — Bootstrap
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
> After approval, run `/gig:gather` to start the first iteration.

**STOP. Do not create iterations. Do not make decisions. Wait for approval.**

## After Approval

1. If user adjusted version/name/description, update ROADMAP.md and STATE.md.
2. Say: "Project initialized. Run `/gig:gather` to start the first iteration."
