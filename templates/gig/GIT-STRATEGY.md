# Git Strategy

> Branch, commit, tag, and merge conventions aligned with gig versioning.

---

## Branch Model

```
main                          ← stable, verified, tagged
  └── feature/v0.1-auth       ← milestone 1 (auth feature)
  └── feature/v0.2-crud       ← milestone 2 (CRUD feature)
  └── feature/v0.3-tests      ← milestone 3 (test feature)
```

### Branch Naming

| Branch | Pattern | Created By | Lifecycle |
|--------|---------|-----------|-----------|
| **main** | `main` | — | Permanent. Always deployable. |
| **milestone** | `feature/v0.{M}-{milestone-name}` | `gig:implement` | Created at milestone start, deleted after merge. |
| **team task** | `feature/v0.{M}-{milestone-name}/batch-{P}` | `gig:implement` (team mode) | Created per parallel batch, merged into milestone branch. |

### Rules

- One milestone branch at a time. No long-lived feature branches.
- Milestone branches are created from `main` HEAD at first iteration start.
- Team task branches are created from the milestone branch.
- Never work directly on `main`.

---

## Commit Strategy

### Per-Batch Commits

Every completed batch gets one commit on the iteration branch.

**Format:**
```
{type}(v0.{N}.{P}): {batch description}
```

**Examples:**
```
feat(v0.1.1): add database schema and drizzle config
feat(v0.1.2): add task CRUD routes
fix(v0.1.3): [UNPLANNED] fix auth redirect bug
feat(v0.1.4): add input validation
test(v0.1.5): add integration tests
```

### Commit Types

| Type | When |
|------|------|
| `feat` | New functionality |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Tooling, deps, config |

### Staging Rules

- Stage specific files by name. Never `git add -A` or `git add .`.
- Do not commit `.env`, credentials, or secrets.
- Each commit should be atomic — one batch, one concern.

### Unplanned Work

Unplanned batches (`fix [thing]`) follow the same commit format with `[UNPLANNED]` in the commit body:

```
fix(v0.2.4): fix auth redirect on expired tokens

[UNPLANNED] — inserted during iteration 2 apply.
```

---

## Merge Strategy

### Iteration → Main

When `gig:verify` approves an iteration:

1. **Switch to main:** `git checkout main`
2. **Merge the iteration branch** using regular merge (default):
   ```
   git merge --no-ff feature/v0.{N}-{iteration-name}
   ```
   This preserves batch-level commit history on main.
3. **Delete the iteration branch:** `git branch -d feature/v0.{N}-{iteration-name}`

> **Note:** Do not prompt for merge strategy. Regular merge (`--no-ff`) is the default.
> The user can explicitly request squash if they prefer it for a specific iteration.

### Team Task → Iteration Branch

When parallel batches complete in team mode:

1. **Merge each task branch** into the iteration branch (regular merge).
2. **Resolve conflicts** if any — flag to user.
3. **Delete task branches** after merge.

---

## Tag Strategy

Tags mark significant points aligned with the version timeline.

### Iteration Tags

Created automatically when an iteration is governed. The tag is the milestone version with the iteration patch.

```
git tag -a v0.{M}.{P} -m "Milestone {M}, iteration {P}: {iteration name}"
```

**Examples:**
```
v0.1.1  — Milestone 1, iteration 1: Database & Schema
v0.1.2  — Milestone 1, iteration 2: Task CRUD Routes
v0.2.1  — Milestone 2, iteration 1: Validation & Error Handling
```

### Milestone Tags

Created by `gig:milestone complete` when a milestone finishes. The tag is the last iteration version.

```
git tag -a v0.{M}.{last-P} -m "Milestone: {milestone name}"
```

**Examples:**
```
v0.1.3  — Milestone: Auth Feature (3 iterations)
v0.2.1  — Milestone: CRUD Feature (1 iteration)
```

### Tag Rules

- Tags are created on `main` after merge.
- Iteration tags use the `v0.{M}.{P}` format (milestone.iteration).
- Milestone tags use the last iteration version.
- Never move or delete tags.

---

## Full Lifecycle Example

```
main:     ──●────────────────●──────────────────●──── ...
              \              ↑ merge + tag        \
               \             │ v0.1.4              \
feature/v0.1:   ──●──●──●──●                       ──●──●──●
                  │   │   │  │                        │   │   │
                 0.1.1│  0.1.3│                      0.2.1│  0.2.3
                    0.1.2  0.1.4                       0.2.2
```

**Reading the graph:**
- Each `●` on a feature branch = one iteration commit
- Each iteration is versioned `v0.{M}.{P}` (milestone.iteration)
- Milestone merges back to main tagged with the **last iteration version** (e.g., `v0.1.4`)
- The next milestone starts at `v0.{M+1}.1` (first iteration of next milestone)
- Main always has clean, verified, tagged code

---

## Git Init (for new projects)

When `gig:init` runs in a directory without `.git/`:

1. `git init`
2. Create `.gitignore` (if not present) — include common ignores for detected stack.
3. Initial commit: `chore: initialize project`
4. All subsequent work follows the branch model above.

---

## Recovery

If an iteration branch gets messy:
- **Soft reset:** `gig:verify` can flag issues and send back to `gig:apply`.
- **Hard reset:** Abandon the iteration branch, create a new one from main, re-apply.
- **Cherry-pick:** Pull specific batch commits from an abandoned branch.

Never force-push. Never rewrite history on main.
