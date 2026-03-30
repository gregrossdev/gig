---
name: gig:learn
description: Create structured lesson plans for learning new concepts or following courses.
argument-hint: "[topic | course URL | from scratch]"
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebSearch, WebFetch]
---

<objective>
Create structured lesson plans for any topic — from scratch or by following an existing course.

**When to use:** When you want to learn something new. Claude builds a curriculum, then you work through it lesson by lesson using the normal gig workflow.
</objective>

<execution_context>
@~/.claude/skills/gig/learn/SKILL.md
</execution_context>

<process>
**Follow the skill instructions in @~/.claude/skills/gig/learn/SKILL.md**
</process>
