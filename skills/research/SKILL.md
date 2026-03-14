---
name: gig:research
description: Deep-dive a topic using subagents. Feeds findings into decisions or working memory.
user-invocable: true
argument-hint: "[topic to research]"
---

# /gig:research Skill

## Step 1 — Gather Topic

If the user provided a topic in their message, use it.
Otherwise ask: "What do you want to research?"

## Step 2 — Determine Research Scope

Classify the research:

| Type | Approach |
|------|----------|
| **Library/framework** | WebSearch + docs, compare alternatives |
| **Codebase question** | Subagents to explore code (Agent tool, subagent_type "Explore") |
| **Architecture pattern** | WebSearch + existing codebase analysis |
| **API/service** | WebSearch + docs, check compatibility |
| **Bug investigation** | Codebase exploration + error analysis |

## Step 3 — Execute Research

Launch subagents in parallel where possible:

- Use Agent tool with subagent_type "Explore" for codebase investigation.
- Use WebSearch for external information.
- Use Agent tool with subagent_type "general-purpose" for complex multi-step research.

Collect all findings.

## Step 4 — Synthesize

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

## Step 5 — Integrate (if active gig context exists)

If `.gig/STATE.md` exists and has an active phase:
- Ask: "Want me to save these findings to working memory?"
- If yes: append key findings to STATE.md Working Memory section.
- If findings suggest a decision should change, flag it:
  "Finding X suggests decision D-{id} may need revision."
