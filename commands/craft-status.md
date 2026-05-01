---
name: craft:status
description: "Show current Craft progress — cycles, stories, backlog in a rich dashboard view."
---

# Craft Status

Display a comprehensive view of current Craft state.

## Dashboard Format

```
┌─────────────────────────────────────────────────────────────┐
│  CRAFT                                               $X.XX  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ● Cycle [N]: [Name]                              [status]  │
│  ├── ✓ [Story 1]                               complete     │
│  ├── ◐ [Story 2]                      chunk X/Y  ███░░      │
│  └── ○ [Story 3]                            ready           │
│                                                             │
│  ○ Cycle [N+1]: [Name]                       [status]       │
│  └── X stories planned                                      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Backlog: X stories                                         │
│  ├── [story-name] (priority)                                │
│  ├── [story-name]                                           │
│  └── +N more                                                │
└─────────────────────────────────────────────────────────────┘
```

## Status Indicators

| Symbol | Meaning |
|--------|---------|
| `○` | Ready/Pending |
| `◐` | In Progress |
| `✓` | Complete |
| `⚠` | Blocked |
| `✗` | Failed |

## Planning Section

If `.craft/planning/` exists, show a planning summary between the cycle dashboard and the backlog:

```
├─────────────────────────────────────────────────────────────┤
│  Planning                          updated 2 days ago       │
│  ► customer-modernization (3 concepts, 1 planned)           │
│  ├── profile-tab                              complete      │
│  ├── cdb-mapping                              planned       │
│  └── invoice-email                            open          │
│  ○ permissions-cleanup                        open          │
│  ○ user-preferences                           open          │
│  ? 4 open questions across 3 concepts                       │
├─────────────────────────────────────────────────────────────┤
```

### Planning data gathering

Use **Glob** with pattern `$PROJECT/.craft/planning/active.md` to check if planning exists. If not found, skip the planning section silently.

If found:
1. Use **Read** to read `$PROJECT/.craft/planning/active.md`. Extract `last_updated` from frontmatter. Calculate days since last update. If >3 days, show "updated N days ago" in the header.
2. Use **Read** to read `$PROJECT/.craft/planning/README.md`. Extract the Roadmap table rows for initiative/concept names and statuses.
3. For each initiative folder (detected via Glob `$PROJECT/.craft/planning/*/README.md`), read the initiative README to get sub-concept count and statuses.
4. Scan for open questions: Use **Bash** to count `- [ ]` items across all planning `.md` files:
   ```bash
   grep -r "^- \[ \]" "${CRAFT_PROJECT_ROOT:-.}/.craft/planning/" --include="*.md" 2>/dev/null | wc -l
   ```
5. **Broken link check:** For each concept file with a `stories:` frontmatter field containing paths, use **Glob** to verify each story path exists. Flag any that don't resolve as `[broken]` in the output.

### Planning display rules

- Show initiatives as indented groups with their sub-concepts
- Show standalone concepts at root level
- Status indicators: `open`, `planned`, `complete`, `archived`
- Show open questions count if >0
- Show broken story links if any found
- If `last_updated` is missing from active.md frontmatter, show "updated: unknown"

## Data Sources

Read from:
- `.craft/.global-state` — active cycle, global config
- `.craft/cycles/*/cycle.yaml` — cycle details
- `.craft/cycles/*/.state` — cycle state
- `.craft/cycles/*/stories/*.md` — story details
- `.craft/backlog/*.md` — backlog stories
- `.craft/planning/active.md` — planning live state (if exists)
- `.craft/planning/README.md` — planning roadmap index (if exists)
- `.craft/planning/*/README.md` — initiative details (if exists)

## Implementation

Set `PROJECT` to `${CRAFT_PROJECT_ROOT:-.}`.

Use **Read** to read `$PROJECT/.craft/.global-state`. Parse key=value pairs to extract `ACTIVE_CYCLE`, `CURRENT_STORY`, etc.

Use **Glob** with pattern `$PROJECT/.craft/cycles/*/cycle.yaml` to find all cycles.
For each cycle, use **Read** to read `cycle.yaml` for status and **Read** to read `.state` for progress.
Use **Glob** with pattern `$PROJECT/.craft/cycles/[cycle-name]/stories/*.md` to list stories per cycle.

Use **Glob** with pattern `$PROJECT/.craft/backlog/*.md` → count results → `backlog_count`.

## Options

- `/craft status` — Full dashboard (default)
- `/craft status --cycle` — Current cycle only
- `/craft status --backlog` — Backlog list only
- `/craft status --story` — Current story details

## Quick Aliases

For convenience, these shortcuts should also work:
- `/s` — Current story details
- `/c` — Current cycle overview
- `/b` — Backlog list

## Output

After showing the dashboard, offer next actions:

> "What would you like to do?"

Use **AskUserQuestion**:
```
question: "What would you like to do?"
header: "Action"
options:
  - label: "Continue current story"
    description: "Resume where you left off"
  - label: "Pick a different story"
    description: "Choose another story to work on"
  - label: "Create new story"
    description: "Add a new story to backlog"
  - label: "Start analysis"
    description: "Run QA/UX/Creative/Style checks"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their intent.
