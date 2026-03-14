# gig

A structured workflow system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Three phases, two approval gates, zero decision fatigue.

```
gather → implement → govern
```

Claude researches the problem, makes all decisions, builds the plan, executes in batches, and validates quality. You just say "looks good" or "change X."

## Install

**Plugin (recommended):**

```bash
/plugin install gig
```

**Shell script (fallback):**

```bash
git clone https://github.com/gregrossdev/gig.git
cd gig && ./install.sh
```

## How it works

```
┌─────────────────────────────────────────────────┐
│  /gig:init     → scaffold .gig/, first milestone│
│  /gig:gather   → research, decisions, plan      │
│  /gig:implement→ execute batches, checkpoints   │
│  /gig:govern   → verify, issues, archive phase  │
│  ↺ repeat for next phase                        │
└─────────────────────────────────────────────────┘
```

1. **Init** — Run once per project. Discovers existing context, scaffolds `.gig/`, proposes first milestone.
2. **Gather** — Claude researches the problem, generates all decisions as a batch for your approval, then builds the implementation plan. Two gates, one command.
3. **Implement** — Executes batches with human-in-the-loop checkpoints. Parallel execution via worktrees when independent batches exist. Decisions can be revised mid-build.
4. **Govern** — Runs tests, validates acceptance criteria, audits decisions, tracks issues. Fixes blockers before archiving. Summarizes what was built and suggests next phase.

## Commands

| Skill | Purpose |
|-------|---------|
| `/gig:init` | Initialize project, discover context, create first milestone |
| `/gig:gather` | Research + decisions + plan (two approval gates) |
| `/gig:implement` | Execute plan batch by batch |
| `/gig:govern` | Verify, validate, archive phase |
| `/gig:status` | Show current state + suggest next action |
| `/gig:milestone` | Create or complete milestones |
| `/gig:research` | Deep-dive a topic with subagents |
| `/gig:handoff` | Save/restore session context across sessions |

**Natural language shortcuts** (during an active session):

| Say | Effect |
|-----|--------|
| `next` | Execute next batch |
| `status` | Show progress |
| `fix [thing]` | Insert unplanned work |
| `skip` | Skip current batch |
| `amend [change]` | Modify the plan |
| `phase done` | Complete current phase |

## The only question Claude asks

> "Does this batch look good?"
>
> - **"yes"** / **"looks good"** → Claude executes
> - **"change X"** → Claude adjusts and re-presents
> - **"no"** → Claude re-evaluates

## Versioning

Every project uses `MAJOR.MINOR.PATCH`:

- **PATCH** — increments per executed batch
- **MINOR** — always equals the phase number
- **MAJOR** — milestone completion (you declare v1.0, never Claude)

## How gig differs from alternatives

| | gig | GSD | PAUL |
|---|---|---|---|
| **Workflow** | gather → implement → govern | discuss → plan → execute → verify | plan → apply → unify |
| **Decision-making** | Claude decides everything, you approve batches | Interactive discussion | Interactive planning |
| **Distribution** | Native Claude Code plugin | npx installer | npx installer |
| **Versioning** | Built-in batch versioning (MAJOR.MINOR.PATCH) | Phase-based | Phase-based |
| **Issue tracking** | Built-in (ISSUES.md, severity, fix cycles) | External | External |
| **Parallel execution** | Agent Teams with worktrees | Sequential | Sequential |

## Project structure

```
.gig/                    # Created per-project by /gig:init
├── STATE.md             # Current version, phase, progress
├── PLAN.md              # Active phase plan
├── DECISIONS.md         # Append-only decision log
├── ISSUES.md            # Issue tracker
├── ARCHITECTURE.md      # Project structure overview
├── ROADMAP.md           # Milestone/phase tracker
├── GIT-STRATEGY.md      # Branch/commit/tag conventions
└── phases/              # Completed phase archives
```

## Getting started

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for a full walkthrough.

**Quick start:**

```
cd your-project
/gig:init              # scaffold + first milestone
/gig:gather            # research → decisions → plan
/gig:implement         # execute batches
/gig:govern            # verify + archive
```

## License

[MIT](LICENSE)
