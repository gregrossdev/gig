---
name: gig:spec
description: Build a complete spec through interactive conversation so gather produces plans that execute cleanly.
argument-hint: "[topic or goal]"
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebSearch, WebFetch]
---

<objective>
Build a complete spec through interactive conversation — user stories, requirements, constraints — so gather can make decisions without assumptions.

**When to use:** Before `/gig:gather` for complex features, new milestones, or when you want clarity before decisions.
</objective>

<execution_context>
@~/.claude/skills/gig/spec/SKILL.md
</execution_context>

<process>
**Follow the skill instructions in @~/.claude/skills/gig/spec/SKILL.md**
</process>
