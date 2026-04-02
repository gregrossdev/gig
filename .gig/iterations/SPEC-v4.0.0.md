# Spec v4.1

> Locked spec for the current milestone. Gather references these requirements when making decisions.

## Stories

| ID | Story | Priority | Scope Notes | Status |
|----|-------|----------|------------|--------|
| US-001 | As a gig user, I want gather's deep research phase to use parallel agent profiles, so that codebase analysis is faster and more thorough | core | Gather Step 3 only. Decisions/plan steps unchanged. | COVERED |
| US-002 | As a gig user, I want init's project discovery to split across parallel agent profiles for existing projects, so that initialization is faster | core | Existing projects only. New/empty projects unaffected. | COVERED |
| US-003 | As a gig user, I want the research skill to explicitly parallelize codebase + external research, so that both run concurrently | core | Clarify subagent type guidance too. | COVERED |
| US-004 | As a gig user, I want govern's independent validation checks to run concurrently, so that governance completes faster | enhancement | Bash run_in_background, not agents. | COVERED |
| US-005 | As a gig user, I want standardized agent profiles defined in CLAUDE.md, so that research-phase skills compose from consistent, maintainable agent definitions instead of redefining focus areas each time | core | Defines 3 profiles: Architecture, Quality, Discovery. All research skills reference by name. | COVERED |
| US-006 | As a gig user, I want the triage skill removed, so that the system doesn't have redundant research capabilities now that spec and gather are properly parallelized | core | Spec + govern absorb triage's roles. | COVERED |

## Requirements

| ID | Story | Description | Acceptance Criteria | Priority | Dependencies | Status | Iteration |
|----|-------|-------------|---------------------|----------|-------------|--------|-----------|
| REQ-001 | US-001 | Gather Step 3 launches 3 parallel Explore agents using Architecture, Quality, and Discovery profiles | Gather launches 3 agents in parallel during deep research. Each uses a named profile. Findings synthesized before decisions. | must | REQ-011 | COVERED | v0.112.5 |
| REQ-002 | US-001 | Each agent receives shared context per its profile definition plus SPEC.md and working memory | Agent prompts include profile-defined context files plus active gig state. | must | REQ-001 | COVERED | v0.112.5 |
| REQ-003 | US-001 | Agent count guidance: 3 agents for projects with iteration history, 2 minimum for new projects | Skill instructions include guidance on agent count. | should | REQ-001 | COVERED | v0.112.5 |
| REQ-004 | US-002 | Init Step 3 launches 3 parallel Explore agents using Architecture, Quality, and Discovery profiles for existing project discovery | Init launches 3 agents for existing project discovery. New/empty projects unchanged. | must | REQ-011 | COVERED | v0.112.5 |
| REQ-005 | US-002 | Discovery agents' findings merged into unified project assessment before presenting to user | User sees one coherent assessment, not separate agent outputs. | must | REQ-004 | COVERED | v0.112.5 |
| REQ-006 | US-003 | Research Step 4 launches codebase Explore agents and WebSearch calls in parallel, not sequentially | Agent tool calls and WebSearch calls appear in the same tool-call block. | must | — | COVERED | v0.112.5 |
| REQ-007 | US-003 | Add subagent type decision guidance: Explore for read-only codebase investigation, general-purpose for multi-step tasks combining search + synthesis + file creation | Research skill includes a decision table for subagent type selection. | must | — | COVERED | v0.112.5 |
| REQ-008 | US-004 | Run test suite and linter as parallel Bash commands using run_in_background | Tests and lint launch concurrently; results collected before governance report. | must | — | COVERED | v0.112.5 |
| REQ-009 | US-004 | Documentation health check runs in parallel with tests/lint | Doc health check launches concurrently with test/lint commands. | should | REQ-008 | COVERED | v0.112.5 |
| REQ-010 | US-004 | Architecture health check and spec coverage check run in parallel where both exist | These checks launch concurrently when both ARCHITECTURE.md and SPEC.md present. | should | REQ-008 | COVERED | v0.112.5 |
| REQ-011 | US-005 | Define 3 agent profiles in CLAUDE.md delegation policy: Architecture (structure, stack, deps, frameworks, file layout — reads ARCHITECTURE.md, package/config files), Quality (tests, lint, coverage, code patterns, tech debt — reads test files, lint config, ISSUES.md), Discovery (patterns, themes, cross-cutting concerns, git history, iteration trends — reads ROADMAP.md, iterations/, BACKLOG.md) | Delegation policy in CLAUDE.md includes 3 named profiles with focus areas and standard context files. | must | — | COVERED | v0.112.5 |
| REQ-012 | US-005 | Update spec, gather, init, learn, and research skills to reference profiles by name instead of inline focus descriptions | All research-phase skills reference "Architecture Agent", "Quality Agent", "Discovery Agent" rather than redefining focus areas. | must | REQ-011 | COVERED | v0.112.5 |
| REQ-013 | US-005 | Learn skill composes Architecture + Discovery profiles for curriculum research, adding topic-specific context on top | Learn launches 2 agents using named profiles during curriculum research. | must | REQ-011 | COVERED | v0.112.5 |
| REQ-014 | US-005 | Add background execution guidance to CLAUDE.md delegation policy: "Use run_in_background for research agents when user is actively making decisions or answering questions" | Delegation policy includes background execution guidance with examples. | must | REQ-011 | COVERED | v0.112.5 |
| REQ-015 | US-005 | Spec skill uses background agents during elicitation: launch iteration analysis in background while user answers questions | Spec can launch background research that feeds into running draft without blocking conversation. | should | REQ-014 | COVERED | v0.112.5 |
| REQ-016 | US-006 | Remove skills/triage/SKILL.md and commands/triage.md | Files deleted. No references to /gig:triage remain in any skill or command file. | must | — | COVERED | v0.112.5 |
| REQ-017 | US-006 | Remove triage from CLAUDE.md natural language commands table and skills list | No mention of triage in CLAUDE.md. | must | REQ-016 | COVERED | v0.112.5 |
| REQ-018 | US-006 | Remove triage from install.sh copy/symlink logic and update tests | install.sh doesn't reference triage. Tests updated. | must | REQ-016 | COVERED | v0.112.5 |
| REQ-019 | US-006 | Update ARCHITECTURE.md template structure diagram to remove triage | Triage no longer listed in skills directory structure. | must | REQ-016 | COVERED | v0.112.5 |
| REQ-020 | US-005 | Update spec baseline flow to use 3 parallel Explore agents with profiles: Architecture (group iterations into stories), Quality (extract requirements from criteria), Discovery (detect patterns, themes, cross-cutting concerns) | Spec baseline launches 3 agents in parallel using named profiles. | must | REQ-011 | COVERED | v0.112.5 |

## Constraints

- No new subagent types — use existing Explore and general-purpose only
- Background execution must never block user interaction — results collected when the skill needs them
- Agent count guidance is instructional (skill markdown), not enforced by code — Claude uses judgment
- Spec and govern absorb triage's "what to work on next" and backlog surfacing roles — no new capability needed
- Agent profiles are focus definitions, not rigid templates — Claude adapts based on skill context

## Out of Scope

- Cross-skill parallelization (running gather + design simultaneously)
- Inter-agent communication (agents sharing findings directly)
- New delegation modes beyond team/subagent/in-session
- Progress streaming or real-time agent status display
- Design skill agent usage (not yet leveraged)

## Clarifications

- Q: Should triage be modified instead of removed? → A: No — spec's project assessment and govern's iteration suggestions fully cover triage's role.
- Q: Does backlog awareness need new capability? → A: No — spec reads BACKLOG.md in Step 2, govern manages backlog in its suggestion step. Already covered.
- Q: Does this affect implement's team mode? → A: No — implement's worktree-based team execution is already well-designed. This spec focuses on research-phase parallelization.
- Q: Why 3 agents as the standard? → A: Triage proved 3 parallel agents with named focuses produces thorough, fast results. Standardizing on 3 gives consistency without overcomplicating.
- Q: Why not 4 profiles (adding Curriculum)? → A: Curriculum is too niche for learn alone. Learn composes Architecture + Discovery and adds topic-specific context on top.
- Q: Why profiles instead of per-skill focus descriptions? → A: Maintenance. Update one profile definition, all skills benefit. Same pattern as delegation policy and git strategy — define once, reference everywhere.

## Amendments

<!-- Append-only. Format: AMD-{N}: Tier {T} — {description}. Affected: {REQ IDs}. Reason: {why}. -->
