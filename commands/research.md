---
name: gig:research
description: Deep-dive a topic using subagents, feed findings into decisions or working memory.
argument-hint: <topic>
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Task, WebSearch, WebFetch]
---

<objective>
Deep-dive a topic using subagents. Synthesize findings and optionally feed them into active decisions or working memory.

**When to use:** Before deciding, or anytime you need thorough research on a topic.
</objective>

<execution_context>
@~/.claude/skills/gig/research/SKILL.md
</execution_context>

<process>
**Follow the skill instructions in @~/.claude/skills/gig/research/SKILL.md**
</process>
