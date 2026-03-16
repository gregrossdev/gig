---
name: gig:research
description: Deep-dive a topic using subagents. Feeds findings into decisions or working memory.
user-invocable: true
argument-hint: "[topic to research]"
---

# /gig:research Skill

## Step 0 — Auto-Load Context

If `.gig/STATE.md` exists, read it and display:
`Version: {version} | Phase: {phase} | Status: {status}`

## Step 1 — Guard Check

Check if `.gig/` exists in the current project root.

**If NOT present:**
Note: "No gig context — research will proceed but findings won't be integrated."
Continue to Step 2 (research works standalone).

**If present:**
Read `.gig/STATE.md`, `.gig/DECISIONS.md`, and `.gig/ARCHITECTURE.md` for context.

## Step 2 — Gather Topic

If the user provided a topic in their message, use it.
Otherwise ask: "What do you want to research?"

## Step 3 — Determine Research Scope

Classify the research:

| Type | Approach |
|------|----------|
| **Library/framework** | WebSearch + docs, compare alternatives |
| **Codebase question** | Subagents to explore code (Agent tool, subagent_type "Explore") |
| **Architecture pattern** | WebSearch + existing codebase analysis |
| **API/service** | WebSearch + docs, check compatibility |
| **Bug investigation** | Codebase exploration + error analysis |

## Step 4 — Execute Research

Launch subagents in parallel where possible:

- Use Agent tool with subagent_type "Explore" for codebase investigation.
- Use WebSearch for external information.
- Use Agent tool with subagent_type "general-purpose" for complex multi-step research.

Collect all findings.

## Step 5 — Synthesize

Present a concise research report:

```
## Research: {topic}

### Findings
{Key discoveries, organized by sub-topic}

### Recommendations
{Opinionated suggestions based on findings}

### Impact on Current Work
{How this affects active decisions/plan, if any}

### Sources
{Links, file paths, or references}
```

## Step 6 — Integrate

Skip if no gig context (Step 1 noted absence).

If `.gig/STATE.md` exists and has an active phase:
- Ask: "Want me to save these findings to working memory?"
- If yes: append key findings to STATE.md Working Memory section.
- If findings suggest a decision should change, flag it:
  "Finding X suggests decision D-{id} may need revision."
