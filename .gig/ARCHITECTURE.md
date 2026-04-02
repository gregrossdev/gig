# Architecture

## Overview

The gig meta prompting system — a structured workflow for Claude Code that provides gather→implement→govern steps with decision tracking, batch versioning, milestone/iteration hierarchy, git strategy, and human-in-the-loop checkpoints. This repo is the source of truth for all skills, templates, and global configuration.

## Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Runtime | Claude Code CLI | Skills, Agent Teams, worktrees |
| Format | Markdown | All skills, templates, state files |
| VCS | Git | Feature branches, worktrees, tags |
| Installation | `~/.claude/` | Skills and templates symlinked or copied to here |

## Structure

```
project-root/
├── CLAUDE.md                # Global rules (installed to ~/.claude/CLAUDE.md)
├── skills/                  # Skill definitions (installed to ~/.claude/skills/gig/)
│   ├── init/SKILL.md        # /gig:init — project initialization
│   ├── gather/SKILL.md      # /gig:gather — research + decisions + plan
│   ├── implement/SKILL.md   # /gig:implement — execute batches
│   ├── govern/SKILL.md      # /gig:govern — verify + archive
│   ├── status/SKILL.md      # /gig:status — show state + next action
│   ├── milestone/SKILL.md   # /gig:milestone — milestone lifecycle
│   ├── research/SKILL.md    # /gig:research — deep-dive topics

│   ├── learn/SKILL.md       # /gig:learn — structured lesson plans
│   └── design/SKILL.md      # /gig:design — Figma prototypes + DESIGN.md
├── commands/                # Command stubs (installed to ~/.claude/commands/gig/)
│   └── {skill}.md           # Registers each skill as a slash command
├── templates/               # Project scaffolding (installed to ~/.claude/templates/gig/)
│   ├── gig/
│   │   ├── STATE.md
│   │   ├── PLAN.md
│   │   ├── DECISIONS.md
│   │   ├── ISSUES.md
│   │   ├── GOVERNANCE.md
│   │   ├── ARCHITECTURE.md
│   │   ├── ROADMAP.md
│   │   ├── BACKLOG.md
│   │   ├── DEBT.md
│   │   ├── SPEC.md
│   │   └── GIT-STRATEGY.md
│   └── project/
│       ├── ARTICLE.md
│       ├── README.md
│       └── RESEARCH.md
│   └── project/
│       └── ARTICLE.md       # Flexible content writing template
├── .gig/                    # This project's own gig state (gitignored)
└── .gitignore
```

## Patterns

- **Skill-per-concern** — one SKILL.md per workflow step (init, gather, implement, govern, etc.)
- **Template-driven scaffolding** — templates copied into `.gig/` per project on init
- **Markdown-only** — no executable code; skills are instructions that guide Claude's behavior
- **Three-step workflow** — Gather → Implement → Govern with approval gates
- **Append-only decisions** — originals preserved, amendments/revisions appended
- **Iteration-based versioning** — MINOR = iteration number, PATCH = batch, MAJOR = milestone
- **Milestone-driven development** — milestone creation includes spec elicitation (stories, requirements, constraints); requirements traced through decisions to implementation
- **Living diagrams** — Mermaid diagrams auto-derived during gather based on project content, archived by govern
- **Self-documenting** — Init scaffolds minimum docs (README, CHANGELOG, LICENSE), auto-detects project type, govern tracks documentation health

## Boundaries

- **In scope:** Skill definitions, templates, global CLAUDE.md rules, installation/distribution
- **Out of scope:** Actual project code that gig manages, CI/CD, deployment
- **Hard constraint:** Version stays 0.x.y until user explicitly declares v1.0

## External Dependencies

| Dependency | Purpose | Notes |
|-----------|---------|-------|
| Claude Code CLI | Runtime execution | Skills, Agent Teams, worktrees |
| Git | Version control | Required by gig's git strategy |

## Audit Log

### Iteration 115 — 2026-04-02
One feature per milestone: Current versioning has MINOR=iteration (globally incrementing), PATCH=batch. Needs to change to MINOR=milestone, PATCH=iteration within milestone. "Upcoming Iterations" appears in 9 files. Govern Step 10 auto-queues iterations; needs to prompt milestone completion instead. ~23 test assertions affected. Branch naming uses iteration numbers. Core restructure of versioning model across govern, gather, milestone, RULES.md, GIT-STRATEGY.md, ROADMAP template.

### Iteration 114 — 2026-04-02
Milestone resume & status integration: SPECING status is missing from the status skill's suggestion table (11 statuses defined, only 10 handled). Milestone skill has no guard for SPECING — user can accidentally overwrite an in-progress elicitation. Status displays milestone name but not spec progress (stories/requirements). Small, targeted changes to 2 skills.

### Iteration 113 — 2026-04-02
Milestone-driven workflow: Current system has 5-step user journey (milestone → spec → gather → implement → govern) where spec (535 lines) is a standalone skill. Milestone skill (118 lines) is thin — only manages versions and ROADMAP.md. Spec elicitation produces SPEC.md that gather/govern consume. Traceability chain (US→REQ→Decision→Batch→Tests) is solid and should be preserved. 52 test assertions reference spec directly. Backlog is empty and well-structured. The restructure is primarily UX consolidation — absorb spec into milestone create, streamline lifecycle, make backlog drive roadmap.

### Iteration 112 — 2026-04-01
Agent profile standardization: Inconsistent agent usage across skills — triage uses 3 parallel agents (gold standard), but gather/init/learn use single agents for equivalent research. Delegation policy in RULES.md is thin (3 lines). No standard context-passing pattern. Triage is redundant now that spec handles project assessment and govern handles iteration suggestions. Govern runs validation checks sequentially where Steps 5/5b/5c are independent. Research skill ambiguous about parallelization. Structural change: define agent profiles in RULES.md, update 5 skills, remove triage, parallelize govern validation.

### Iteration 110 — 2026-03-30
Govern doc health: Adding Step 5c (Documentation Health Check) to govern, between Architecture Health Check (5b) and UAT (6). Reads DOCS.md for tracked docs, checks each for existence and staleness against recent iteration changes. Auto-generates updates, presents diffs for approval. Deferred updates become DOC issues. New Documentation Coverage section in governance report. No new skills — extends govern skill.


