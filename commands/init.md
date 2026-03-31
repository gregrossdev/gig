---
name: gig:init
description: Initialize the gig system in any project. Discovers context, scaffolds .gig/, proposes first milestone.
argument-hint: "[mvp | reinit]"
allowed-tools: [Read, Write, Bash, Glob, Grep, AskUserQuestion, Task]
---

<objective>
Initialize the `.gig/` structure in a project directory. Discovers project context, populates architecture, creates first milestone.

**When to use:** Starting a new project with gig, or adding gig to an existing codebase.
</objective>

<execution_context>
@~/.claude/skills/gig/init/SKILL.md
</execution_context>

<process>
**Follow the skill instructions in @~/.claude/skills/gig/init/SKILL.md**
</process>
