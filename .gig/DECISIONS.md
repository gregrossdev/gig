# Decisions

> Append-only log. Never delete entries — amend or revise instead.
> Active decisions for the current iteration live here.
> When an iteration completes, its decisions are archived to `iterations/`.

<!-- Decision statuses:
  PROPOSED  — Claude's recommendation, awaiting user approval
  ACTIVE    — Approved and in effect
  AMENDED   — Overridden by user (original preserved, new entry appended)
  REVISED   — Claude revised based on new information (original preserved)
-->

## 2026-04-02 — Design: Replace Figma with brainstorm artifacts

**Decision:** Replace Figma MCP calls with ASCII mockups, Mermaid diagrams, and descriptive design notes generated in-conversation.
**Rationale:** Claude can produce ASCII layouts, Mermaid wireframes, and component descriptions without external tools. Design = brainstorming to align, not prototyping.
**Alternatives considered:** Keep Figma as optional (creates two paths). Use another design tool (adds dependency).
**Status:** ACTIVE
**ID:** D-1.1

## 2026-04-02 — Design: Remove all Figma MCP tools

**Decision:** Remove all 7 Figma MCP tools from commands/design.md allowed-tools.
**Rationale:** No Figma dependency. Design skill uses only standard tools.
**Alternatives considered:** Keep tools but don't use them (dead code). Keep one tool for screenshots (still a dependency).
**Status:** ACTIVE
**ID:** D-1.2

## 2026-04-02 — Design: DESIGN.md output format

**Decision:** Replace "Figma Link" column and "Figma: {URL}" fields with "Mockup" references to in-conversation diagrams and .mmd files.
**Rationale:** Design artifacts live in conversation and .gig/design/*.mmd files, not external URLs.
**Alternatives considered:** Keep URL column for future tools (YAGNI). Remove DESIGN.md entirely (loses value as design record).
**Status:** ACTIVE
**ID:** D-1.3

## 2026-04-02 — Design: Create DESIGN.md template

**Decision:** Add templates/gig/DESIGN.md template file.
**Rationale:** Currently no template exists; design skill generates format ad-hoc. Template ensures consistency.
**Alternatives considered:** Keep ad-hoc generation (inconsistent across projects).
**Status:** ACTIVE
**ID:** D-1.4

## 2026-04-02 — Design: Update all Figma references in consumers

**Decision:** Replace "Figma prototypes" with "design mockups and diagrams" in gather, RULES.md, GETTING-STARTED.md, README.
**Rationale:** Consistent terminology across the system.
**Alternatives considered:** N/A — documentation must match implementation.
**Status:** ACTIVE
**ID:** D-1.5
