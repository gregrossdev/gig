---
name: gig:research
description: Deep-dive a topic using subagents. Feeds findings into decisions or working memory.
user-invocable: true
argument-hint: "[topic to research]"
---

# /gig:research Skill

## Step 0 — Auto-Load Context

If `.gig/STATE.md` exists, read it and display:
`Version: {version} | Iteration: {iteration} | Status: {status}`

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

Launch all research in parallel — agents and WebSearch calls in the same tool-call block:

- **Codebase investigation:** Use Agent tool with subagent_type "Explore", selecting profiles based on the research type (see table below).
- **External information:** Use WebSearch for docs, comparisons, and API references.
- **Complex multi-step research:** Use Agent tool with subagent_type "general-purpose" for tasks that combine searching, synthesis, and file creation.

### Subagent Type Decision Table

| Research Type | Subagent Type | Profiles to Use |
|---------------|--------------|-----------------|
| Library/framework comparison | Explore | Discovery |
| Codebase question | Explore | Architecture + Quality |
| Architecture pattern analysis | Explore | Architecture |
| API/service integration | Explore + WebSearch | Discovery + Architecture |
| Bug investigation | Explore | Quality + Architecture |
| Complex multi-step (combining search + synthesis + file creation) | general-purpose | As needed |

**Explore** — read-only codebase investigation. Use for all research that only needs to read and analyze.
**general-purpose** — multi-step tasks that may need to write files, combine multiple searches, or perform complex synthesis. Use sparingly.

Collect all findings and synthesize before presenting.

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

If `.gig/STATE.md` exists and has an active iteration:
- Ask: "Want me to save these findings to working memory?"
- If yes: append key findings to STATE.md Working Memory section.
- If findings suggest a decision should change, flag it:
  "Finding X suggests decision D-{id} may need revision."
