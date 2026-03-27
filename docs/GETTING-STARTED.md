# Getting Started with gig

This guide walks you through your first project with gig.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- gig installed (via plugin or `install.sh`)
- Contributing to gig? Use `./install.sh --symlink` for dev mode (repo edits are instantly live)

## Verify it works

After installing, open Claude Code in any project directory and check:

1. **Skills are visible** — type `/gig:` and you should see all 8 skills in autocomplete (init, gather, implement, govern, status, milestone, research, handoff)
2. **Status responds** — run `/gig:status`. It should say "No gig context. Use `/gig:init` to start."
3. **Init creates .gig/** — run `/gig:init` in a test directory. Confirm `.gig/` is created with STATE.md, PLAN.md, DECISIONS.md, etc.

If any of these fail, check your installation method and try reinstalling.

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

## Step 2 — Spec (optional)

For complex features or new milestones, build a spec first:

```
/gig:spec
```

Claude guides you through an interactive conversation to define user stories, requirements, and constraints. This eliminates the ambiguity that causes rework — by the time gather runs, decisions are grounded in a clear spec.

Skip this step for simple iterations where the goal is already clear.

## Step 3 — Gather

Once the milestone is locked (and optionally spec'd), run:

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

## Step 4 — Implement

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

## Step 5 — Govern

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
- Archive the completed iteration to `.gig/iterations/`
- Summarize what was built and suggest 3 next iteration ideas

## Repeat

After governance approves the iteration, just say `gather` to start the next one.

If your roadmap has pre-planned iterations (in the Upcoming Iterations section of ROADMAP.md), gig auto-flows:

- **Govern** finishes with: `> Next up: Iteration Name — description. Run gather to start.`
- **Gather** auto-pulls the next planned iteration — no need to specify what to build
- You can still say `skip` to choose something different

If no upcoming iterations are planned, gather asks what you want to build next.

```
/gig:gather    # auto-pulls next iteration, or asks if none planned
/gig:implement # execute batches
/gig:govern    # validate, archive, surface next iteration
```

Each iteration increments the MINOR version. Iterations build toward the milestone.

## Useful commands during a session

| Command | What it does |
|---------|-------------|
| `/gig:status` | Show where you are and what to do next |
| `/gig:research [topic]` | Deep-dive a topic before deciding |
| `/gig:handoff` | Save session context for next time |
| `status` | Quick progress check |
| `next` | Execute next batch |
| `fix [thing]` | Unplanned work as next batch |
| `decisions` | Show active decisions |
| `issues` | Show open/deferred issues |
| `history` | Show batch execution history |

## Tips

- **Trust the workflow.** Let Claude research and decide. You only intervene when you disagree.
- **Keep batches small.** gig plans 1-5 files per batch. If a batch feels too big, say "split this."
- **Revise freely.** Decisions aren't permanent. Say "revise D-1.3" if something isn't working.
- **Use handoff.** Running `/gig:handoff` before ending a session saves context for the next one.
- **Check status.** When returning to a project, `/gig:status` tells you exactly where you left off and what to do next.

## File reference

| File | Purpose | When it changes |
|------|---------|----------------|
| `STATE.md` | Current version, iteration, batch history | Every batch |
| `PLAN.md` | Active iteration batches and acceptance criteria | During gather, updated during implement |
| `DECISIONS.md` | All decisions with rationale | During gather, can be revised anytime |
| `ISSUES.md` | Issues found during governance | During govern |
| `ARCHITECTURE.md` | Project structure and stack | During init, updated as project evolves |
| `ROADMAP.md` | Milestones and iterations | Iteration start/end, milestone completion |
| `GOVERNANCE.md` | Iteration closure report (tests, audit, verdict) | During govern, archived with iteration |
| `SPEC.md` | Locked spec — stories, requirements, constraints | During spec, read by gather/govern |
| `BACKLOG.md` | Backlog ideas — no commitment, no priority | During govern, anytime |
| `GIT-STRATEGY.md` | Branch, commit, tag conventions | Reference only |
