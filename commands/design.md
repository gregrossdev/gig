---
name: gig:design
description: Generate UI/UX prototypes in Figma and produce DESIGN.md with design decisions and links.
argument-hint: "[screen or flow to design]"
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, mcp__figma__generate_figma_design, mcp__figma__create_new_file, mcp__figma__get_design_context, mcp__figma__get_screenshot, mcp__figma__get_metadata, mcp__figma__whoami, mcp__figma__use_figma]
---

<objective>
Generate UI/UX prototypes in Figma and produce DESIGN.md with design decisions and Figma links.

**When to use:** Before `/gig:gather` for iterations with UI/UX work. Optional — skip for backend-only or system-level iterations.
</objective>

<execution_context>
@~/.claude/skills/gig/design/SKILL.md
</execution_context>

<process>
**Follow the skill instructions in @~/.claude/skills/gig/design/SKILL.md**
</process>
