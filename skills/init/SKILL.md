---
name: gig:init
description: Initialize the gig system in any project. Discovers context, scaffolds .gig/, proposes first milestone. Universal entry point.
user-invocable: true
---

# /gig:init Skill

## Step 0 — Guard Check

Check if `.gig/` already exists in the current project root.

**If present:**

**Reinitialize check:** If user args contain "reinitialize" or "reinit", delete `.gig/` and proceed to Step 1.

**MVP check:** If user args contain "mvp", store as MVP flag. Proceed through normal init flow — the flag only affects routing after approval.

Otherwise, check if `.gig/` needs upgrading:
1. Read `.gig/.gig-version` (if missing, treat as `0.0.0`).
2. Compare against the current gig version:
   - **Plugin install:** Read version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (`"version"` field).
   - **Script install:** Read version from `~/.claude/templates/gig/.gig-version` if it exists, otherwise use `0.0.0`.
3. If `.gig-version` is missing or older than current:
   - **Plugin install:** Run `${CLAUDE_PLUGIN_ROOT}/upgrade.sh` via Bash.
   - **Script install:** If `~/.claude/upgrade.sh` exists, run it via Bash. Otherwise, fall back to inline upgrade logic:
     - Check each expected template file (STATE.md, PLAN.md, DECISIONS.md, ISSUES.md, GOVERNANCE.md, ARCHITECTURE.md, ROADMAP.md, GIT-STRATEGY.md, BACKLOG.md, DEBT.md, SPEC.md, MVP.md, DOCS.md) — copy any missing ones from `~/.claude/templates/gig/`.
     - Create `.gig/iterations/` directory if missing.
     - Check for stale "phase" terminology and apply fixes via Edit tool:
       - `STATE.md`: `| **Phase**` → `| **Iteration**`; `| Phase |` → `| Iteration |`
       - `ROADMAP.md`: `## Phases` → `## Iterations`; `## Upcoming Phases` → `## Upcoming Iterations`
       - `ISSUES.md`: `archived with their phase` → `archived with their iteration`; `**Phase:**` → `**Iteration:**`
       - `ARCHITECTURE.md`: `Phase-based versioning` → `Iteration-based versioning`; `MINOR = phase number` → `MINOR = iteration number`
     - Write current gig version to `.gig/.gig-version`.
   - Say: "Upgraded .gig/ to version {version}. Run `/gig:status` to see current state." STOP.
4. If `.gig-version` matches current version:
   - Say: "Already up to date (v{version}). Run `/gig:status` to see current state." STOP.

**If NOT present:** Proceed to Step 1.

## Step 1 — Scaffold .gig/

1. Create `.gig/` directory.
2. Create `.gig/iterations/` directory (for completed iteration archives).
3. Copy gig templates into `.gig/`:
   - Look for templates in this order: `${CLAUDE_PLUGIN_ROOT}/templates/gig/` (plugin install), then `~/.claude/templates/gig/` (script install).
   - If templates are not found at either location, say: "Error: gig templates not found. Reinstall gig or check your installation." STOP.
   - Files: STATE.md, PLAN.md, DECISIONS.md, ISSUES.md, GOVERNANCE.md, ARCHITECTURE.md, ROADMAP.md, GIT-STRATEGY.md, BACKLOG.md, DEBT.md, SPEC.md, MVP.md, DOCS.md
4. Write `.gig/.gig-version` with the current gig version:
   - **Plugin install:** Read version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (`"version"` field).
   - **Script install:** Read version from `~/.claude/templates/gig/.gig-version` if it exists, otherwise write `0.0.0` as a placeholder.
5. Say: "Initialized `.gig/` from templates."

## Step 1b — Scaffold Project Documentation

Create minimum documentation in the project root if not already present:

1. **README.md** — If missing, create with:
   - Project name derived from the directory name (title case)
   - Basic structure: `# {Project Name}`, `## Overview`, `## Getting Started`, `## Usage`, `## License`
   - Placeholder content in each section: "TODO: describe..."

2. **CHANGELOG.md** — If missing, create with [Keep a Changelog](https://keepachangelog.com/) format:
   ```
   # Changelog

   All notable changes to this project will be documented in this file.

   The format is based on [Keep a Changelog](https://keepachangelog.com/).

   ## [Unreleased]
   ```

3. **LICENSE** — If missing, ask: "What license? (MIT, Apache-2.0, ISC, or skip)"
   - If user picks one, generate standard license text with current year and project name derived from directory.
   - If "skip", proceed without creating a LICENSE file.

4. **Article template** — If the project type (detected in Step 2 below) is `content`, offer: "This looks like a content project. Want an Article template? (yes/no)"
   - If yes: copy Article.md from project templates (`${CLAUDE_PLUGIN_ROOT}/templates/project/` or `~/.claude/templates/project/`) to the project root.
   - For non-content projects, skip silently.

Say: "Scaffolded project documentation: {list of created files}."
If all already exist: "Project documentation already present — skipped."

**Note:** Step 1b runs after Step 2 (Detect Project Type) so that the content-type Article offer is informed by detection. However, README.md, CHANGELOG.md, and LICENSE scaffolding does not depend on project type — these are created for all projects.

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

Additionally, classify the project type based on detection signals:

| Signals | Type |
|---------|------|
| Express, Next.js, React, Vue, Angular, HTML files, frontend frameworks | `webapp` |
| FastAPI, Flask, Hono, API routes, no frontend assets | `api` |
| `bin/` directory, CLI flags, commander, yargs, clap, argparse | `cli` |
| Exports-focused, `index.ts`/`index.js`, no app entry point, published package | `library` |
| `.md` files as primary content, no source code directories | `content` |
| No signals (new empty project) | `unknown` |

Record the detected type in `.gig/ARCHITECTURE.md` Overview section by adding:
`**Type:** {webapp | api | cli | library | content | unknown}`

For new projects with no signals, set type to `unknown` — the MVP interview will inform it later.

After detection, run Step 1b (Scaffold Project Documentation) before proceeding to Step 3.

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
   - Plugin Version: if `.claude-plugin/plugin.json` exists in the project, read its `version` field. Otherwise set to `—`.
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
> After approval, {if new project or MVP flag: "MVP product discovery" | else: "spec elicitation"} will begin automatically.

**STOP. Do not create iterations. Do not make decisions. Wait for approval.**

## After Approval

1. If user adjusted version/name/description, update ROADMAP.md and STATE.md.
2. **If new project OR MVP flag is set:**
   - Say: "Project initialized. Starting MVP product discovery..."
   - Proceed directly to `/gig:spec` with the `mvp` argument. This triggers the MVP Product Discovery flow in the spec skill. Do NOT stop or ask the user to run a separate command.
3. **If existing project without MVP flag:**
   - Say: "Project initialized. Starting spec elicitation..."
   - Proceed directly to `/gig:spec` Step 2 (Load Project Context) and Step 3 (Elicitation). The spec guard check accepts IDLE status, so this transition works seamlessly. Do NOT stop or ask the user to run a separate command.
