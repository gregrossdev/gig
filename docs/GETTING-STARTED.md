# Getting Started with gig

This guide walks you through your first project with gig.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- gig installed (via plugin or `install.sh`)

## Step 1 — Initialize

Navigate to your project directory and run:

```
/gig:init
```

gig will:
- Create a `.gig/` directory with state files
- Scan your project (if existing code) to discover stack, structure, and patterns
- Populate `ARCHITECTURE.md` with what it finds
- Propose a first milestone with version number

You'll see something like:

```
Project initialized (existing project).

Discovery summary:
  Stack: TypeScript, React, Node.js
  Structure: src/, tests/, config/
  Patterns: Component-based, REST API

Milestone: API Improvements v0.3.0 — Improve API error handling and validation.
```

Review and approve, adjust, or ask questions.

## Step 2 — Gather

Once the milestone is locked, run:

```
/gig:gather
```

This is the core of gig's "zero decision fatigue" approach. Claude will:

1. **Research** — Explore your codebase, read docs, search the web if needed
2. **Decide** — Generate 3-7 decisions as a batch (tech choices, patterns, naming, structure)
3. **Present for approval** — You see a summary table and say "looks good" or redline by ID

After you approve decisions:

4. **Plan** — Break work into small batches (1-5 files each, one concern per batch)
5. **Present for approval** — You see the batch table with dependencies and delegation modes

Two gates, one command. You approve twice, then you're ready to build.

## Step 3 — Implement

```
/gig:implement
```

gig executes one batch at a time with checkpoints:

```
Checkpoint. Batch 1.2 complete — version 0.1.2.

  - Continue — next to proceed.
  - Pause — save state and stop here.
  - Fix [thing] — insert unplanned work.
  - Revise decision — reference by ID.
```

At each checkpoint you can:
- Say `next` to continue
- Say `fix [thing]` to insert unplanned work (gets its own version number)
- Revise a decision if reality disagrees with the plan
- Pause and resume later

When independent batches exist, gig runs them in parallel using Agent Teams with git worktrees.

## Step 4 — Govern

When all batches are done:

```
/gig:govern
```

gig will:
- Run project tests and linters
- Validate acceptance criteria from the plan
- Audit decisions (did they hold up?)
- Track issues by severity (blocker, major, minor, cosmetic)
- Blockers and majors loop back to implement for fixing
- Archive the completed phase to `.gig/phases/`
- Summarize what was built and suggest 2-3 next phase ideas

## Repeat

After governance approves the phase, start the next one:

```
/gig:gather    # new phase, new decisions, new plan
/gig:implement # execute
/gig:govern    # validate
```

Each phase increments the MINOR version. Phases build toward the milestone.

## Useful commands during a session

| Command | What it does |
|---------|-------------|
| `/gig:status` | Show where you are and what to do next |
| `/gig:research [topic]` | Deep-dive a topic before deciding |
| `/gig:handoff` | Save session context for next time |
| `status` | Quick progress check |
| `next` | Execute next batch |
| `fix [thing]` | Unplanned work as next batch |

## Tips

- **Trust the workflow.** Let Claude research and decide. You only intervene when you disagree.
- **Keep batches small.** gig plans 1-5 files per batch. If a batch feels too big, say "split this."
- **Revise freely.** Decisions aren't permanent. Say "revise D-1.3" if something isn't working.
- **Use handoff.** Running `/gig:handoff` before ending a session saves context for the next one.
- **Check status.** When returning to a project, `/gig:status` tells you exactly where you left off and what to do next.

## File reference

| File | Purpose | When it changes |
|------|---------|----------------|
| `STATE.md` | Current version, phase, batch history | Every batch |
| `PLAN.md` | Active phase batches and acceptance criteria | During gather, updated during implement |
| `DECISIONS.md` | All decisions with rationale | During gather, can be revised anytime |
| `ISSUES.md` | Issues found during governance | During govern |
| `ARCHITECTURE.md` | Project structure and stack | During init, updated as project evolves |
| `ROADMAP.md` | Milestones and phases | Phase start/end, milestone completion |
| `GIT-STRATEGY.md` | Branch, commit, tag conventions | Reference only |
