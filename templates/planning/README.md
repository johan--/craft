---
project: "{{PROJECT_NAME}}"
updated: {{DATE}}
initiatives_total: 0
concepts_total: 0
---

# {{PROJECT_NAME}} - Planning

{{ONE_LINE_DESCRIPTION}}

## How this folder works

- **`active.md`** is the live-state file. Read it first every session.
- **Each concept gets one file** (`concept-slug.md`) until it grows sub-concepts.
- **Concepts with sub-concepts get a folder** with a README.md + sub-concept files inside.
- **Every resolved item cites its source** - transcript quote + date, code file:line, or meeting note. No unsourced claims.
- **Priority = table order below.** Top of table = highest priority. Reorder rows to reprioritize.

## Roadmap

| Concept | Status | Scope | Owner | File |
|---------|--------|-------|-------|------|
| {{CONCEPT_1}} | open | {{SCOPE}} | {{OWNER}} | [`{{FILE}}`]({{FILE}}) |

## Cross-cutting dependencies

<!-- Visible here so they don't require digging into each concept file -->

## Timeline

<!-- Reverse chronological. Key decisions and state changes. -->

- **{{DATE}}**: Planning initialized.

## Source of truth

- **`active.md`** for current state
- **Individual concept files** for concept-scoped decisions, questions, gaps, actions
- **Code** for technical facts - always wins over older docs
