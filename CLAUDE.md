# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Craft** — a creative-first, feedback-loop-driven development harness. The philosophy: **Creativity as default. Smart execution follows.**

Instead of rigid spec-first processes, embrace the way great pairing works:
- Riff on ideas together (Creative Mode)
- Lock decisions as you go
- Execute with confidence (Smart Mode)
- Analyze and inspire next iteration (Analysis Mode)

Claude is smarter now. Trust it to run further. Checkpoint for safety, not for control.

## CRITICAL: No Unauthorized Architectural Changes

**DO NOT** make any of these changes without explicit user approval:

1. **Workflow changes** — How commands/skills flow into each other
2. **State changes** — What gets stored, where, or in what format
3. **New behaviors** — Adding git push, auto-commits, new validations
4. **Removing features** — Even if they seem unused
5. **Changing skill invocation patterns** — How skills call each other
6. **File format changes** — YAML structure, frontmatter fields

**Before making architectural changes:**
- Explain WHAT you want to change
- Explain WHY
- Get explicit "yes" from user

**If you're unsure if something is architectural:** ASK FIRST.

This rule exists because "helpful" changes have repeatedly broken the plugin.

---

## Core Principles

1. **Quality is Pristine** — Industry-leading (Stripe, Linear level), not "good enough"
2. **Nothing Without Approval** — Claude advises, user approves. No magic.
3. **Always Suggest with Reasoning** — Options + recommendation + why
4. **Perfection Gets Locked** — Approved patterns become enforced standards
5. **Quality Evolves Upward** — Can add requirements, never remove
6. **Claude Self-Critiques** — Compares against inspiration + locked patterns before complete
7. **Harness Evolves** — Every cycle makes it smarter

## Three Modes

Modes are **fluid** — Claude prompts via AskUserQuestion at natural transition points. Commands are shortcuts. Mode definitions live in `modes/`.

1. **Chat Mode** (`modes/chat.yaml`): Creative work — story creation, design, planning. Write access restricted to `.craft/` only.
2. **Implement Mode** (`modes/implement.yaml`): Autonomous story implementation. Full write access, gated by `CRAFT_WRITE_ENABLED`. Runs with `acceptEdits` permission.
3. **Analysis Mode**: Post-cycle MCP-powered analysis (QA, UX, Creative, Style) → new cycle ideas.

## Architecture

### Hierarchy (Linear-style)
```
Project → Story (first-class, create anytime)
        → Cycle (time-boxed container)
```

### .craft/ Directory Structure
```
.craft/
├── backlog/                  ← Stories not yet in a cycle
├── cycles/                   ← Time-boxed work containers
│   └── 1-auth/
│       ├── cycle.yaml
│       ├── .state
│       ├── .failures
│       ├── .learnings.yaml   ← Cycle learnings for reflection
│       ├── .events/          ← Structured JSONL append-only event log
│       └── stories/
├── checkpoints/              ← Chunk rollback points
├── fixes/                    ← Adhoc fix records (created by /craft:fix)
├── .exports/                 ← Pre-compact state exports (auto-managed)
├── analysis/                 ← Analysis results (QA, UX, Creative, Style)
│   ├── pending/
│   └── completed/
├── inspiration/              ← Reference library (screenshots, patterns)
├── design/                   ← Design tokens + component patterns
│   ├── tokens.yaml
│   ├── components.md
│   ├── animations.md
│   ├── locked.md
│   └── .confidence-signals.yaml  ← Token confidence scores (written by project-scanner)
├── docs/                     ← Documentation briefs (created by /craft:docs)
├── project.md                ← Project DNA (stack, patterns, voice)
├── quality.yaml              ← Quality gates before "complete"
├── research/                 ← Ad-hoc research (folder per topic, ranked branches)
│   └── {topic-slug}/         ← README.md (synthesis), _plan.md, 01-branch.md...
├── workflows/                ← Reusable multi-step process workflows
│   ├── {workflow-name}/
│   │   ├── definition.md     ← Routing table (stages-v1) or full definition (legacy)
│   │   ├── stages/           ← Per-stage self-contained briefs (stages-v1 format)
│   │   │   ├── 01-name.md
│   │   │   └── 02-name.md
│   │   └── sessions/         ← Per-run instances with progress tracking
│   │       └── {date}-{slug}/
│   │           ├── session.md
│   │           └── artifacts/ ← Stage outputs for cross-stage handoff
│   └── .archived/            ← Archived workflows
├── planning/                 ← Feature roadmap (initiatives, concepts, open questions)
│   ├── active.md             ← Live state: current focus, blockers, next actions
│   ├── README.md             ← Roadmap index: priority = table order
│   ├── {initiative-slug}/    ← Initiative folder (has sub-concepts)
│   │   ├── README.md         ← Initiative overview + concept index
│   │   └── {concept}.md      ← Concept file (scope, questions, decisions)
│   └── {concept}.md          ← Standalone concept (auto-promotes to folder)
├── requests/                 ← External feature requests (from a UI, agent, etc.)
│   └── processed/            ← Requests that have been routed to stories/cycles
├── settings.yaml             ← Craft settings (parallel planning, etc.)
└── .global-state             ← Active cycle, global config
```

**Templates** live in `templates/` with variants for UI (`design/`) and CLI (`design-cli/`) projects. Analysis templates in `templates/analysis/pending/`.

### Quality Layers
| Layer | Purpose |
|-------|---------|
| `inspiration/` | What you want it to feel like (references) |
| `design/` | Visual consistency (enforced via hooks) |
| `project.md` | Technical consistency (stack, patterns) |
| `quality.yaml` | Gates before anything ships |

### Skills vs Agents

**Skills** (run in orchestrator context):
- `content-spark`, `creative-spark`, `design-vibe`, `lock-decision` — Creative Mode
- `plan-chunks`, `validate-chunk`, `refine-chunk`, `test-fix` — Smart Mode
- `fix`, `approve`, `browser` — Utility
- `content-spark` — Content checkpoint (surfaces content assumptions before creative/planning)
- `creative-spark` — supports a Creative Driver step (Step 1.5) that invokes `muse` and/or `alchemist` interrogators to enrich the brief before generating options
- `plan-chunks` — supports parallel batch planning (orchestrates multiple agents, batch triage, per-story approval). Requires `## Dependencies` section with `**Blocked by:**` line in every story before batch mode can proceed (HARD BLOCK gate)
- `fix` — adhoc fix without story ceremony (investigate → confidence check → apply → validate → commit). Backs `/craft:fix`
- `approve` — request scoped write permission from the user via AskUserQuestion. Opens the write gate only after explicit approval
- `browser` — launch a persistent playwright-cli browser session (~4x cheaper than Chrome DevTools MCP in token cost). Backs `/craft:browser`
- `validate-chunk` — derives `FILES_CHANGED` from `git diff`, not the spec-only file list from the story frontmatter

**Agents** (isolated context):

*Core workflow:*
- `implementer` — owns implement→validate→refine loop per chunk
- `tester` — integration tests, E2E after chunks complete
- `chunk-validator` — runs quality checks and returns a structured report (haiku model, read-only)
- `plan-chunks-agent` — autonomous research + chunk planning for a single story (used by plan-chunks skill)
- `project-scanner` — full project analysis for documentation updates

*Analysis:*
- `qa-analyzer` — finds bugs using browser inspection
- `ux-analyzer` — Nielsen heuristics, accessibility, mental models
- `creative-analyzer` — delight moments, viral potential
- `style-analyzer` — token compliance, pattern consistency
- `walkthrough-analyzer` — browser-based interactive testing, clicks everything, reports what doesn't feel right

*Review and research:*
- `pr-reviewer-expert` — PR review crystallized from CodeRabbit, reads locked.md before any opinion
- `maze-architect` — generates perpendicular review questions from a diff with zero intent context (haiku)
- `researcher` — investigates one research sub-question, writes branch file to disk
- `verifier` — adversarial claim checker, tries to disprove findings using primary sources
- `practitioner-reviewer` — challenges verified claims from practical experience

*Browser:*
- `playwright-browser` — owns a live browser session via playwright-cli, steerable via SendMessage

*Crystallized experts (consult via `/craft:ask`):*
- `muse` — emotional job translator, interrogator for creative-spark Step 1.5
- `alchemist` — CSS interaction physicist, interrogator for creative-spark Step 1.5
- `conductor` — AI orchestration architect
- `doc-writer` — documentation diagnostician
- `product-anthropologist` — human-truth layer, diagnoses whether a product solves a real problem
- `crystallizer` — psychological synthesizer that distills research into portable 9-section agent personas (opus, used by /craft:become)
- `become-researcher` — psychological material collector for `/craft:become`

**Orchestration:** plan-chunks uses dual-mode orchestration - agent teams (primary, when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) with Task subagent fallback. Batch size determined by story dependency graph (independent stories plan in parallel, dependent chains plan sequentially).

## Hooks

Defined in `hooks/hooks.json`. Scripts live in `hooks/scripts/`.

| Event | Script | Purpose |
|-------|--------|---------|
| SessionStart | `session-start.sh` | Load craft context on session start |
| SessionStart (compact) | `post-compact-reinject.sh` | Re-inject context after compaction |
| PreToolUse (Write\|Edit) | `check-write-permission.py` | Gate writes via mode + CRAFT_WRITE_ENABLED |
| PostToolUse (Write\|Edit) | `update-progress.py` | Track file changes, update story progress |
| PostToolUseFailure | `handle-tool-failure.py` | Log and recover from tool failures |
| PreCompact | `export-progress.sh` | Save progress state before context compaction |
| UserPromptSubmit | `inject-craft-context.sh` | Inject active cycle/story context per prompt |
| Stop | `stop-hook-guard.sh` | Guard against unclean stops |

## Breadcrumb Continuation Pattern

When a skill invokes another skill via the Skill tool (e.g., validate-chunk → test-fix), each invocation creates a turn boundary. The agent may stop instead of continuing the outer skill's flow. The breadcrumb pattern prevents this.

**How it works:**
1. Before invoking a nested skill, the outer skill writes `.craft/.continuation`
2. The inner skill completes, and the agent tries to stop
3. The Stop hook (Layer 0) reads the breadcrumb, extracts the ACTION, deletes the file, and injects a "DO NOT STOP" continuation instruction
4. The agent continues the outer skill's flow

**When to use:** Any skill that invokes another skill via the Skill tool and needs to continue after the inner skill returns.

**Breadcrumb file format** (`.craft/.continuation`, plain text):
```
ACTION: [Human-readable next step — this is injected into the Stop hook's systemMessage]
SKILL: [skill name to re-invoke, e.g., craft:validate-chunk]
ARGS: [full args string for re-invocation]
WRITTEN_BY: [skill that wrote this breadcrumb]
TIMESTAMP: [ISO UTC timestamp]
```

**Writing a breadcrumb** (before the nested INVOKE):
```bash
cat > "${CRAFT_PROJECT_ROOT:-.}/.craft/.continuation" << CRUMB
ACTION: [describe what to do next]
SKILL: craft:[skill-name]
ARGS: [args]
WRITTEN_BY: [your-skill-name]
TIMESTAMP: $(date -u +%Y-%m-%dT%H:%M:%S)
CRUMB
```

**Cleaning up** (on ALL exit paths — success, failure, escalation):
```bash
rm -f "${CRAFT_PROJECT_ROOT:-.}/.craft/.continuation"
```

**Safety guarantees:**
- **30-minute TTL** — Stop hook ignores breadcrumbs older than 1800s (deletes them silently)
- **One-shot** — breadcrumb is deleted after reading; it cannot re-fire
- **SessionStart cleanup** — `session-start.sh` removes stale breadcrumbs on new sessions
- **Layer 1 fallback** — the existing 2-minute retry window in Layer 1 serves as a safety valve if the breadcrumb mechanism fails

**Reference implementation:** `skills/validate-chunk/SKILL.md` (writes breadcrumbs before invoking test-fix and refine-chunk)

## Key Design Decisions

- **Max 2 parallel stories** with `1a`, `1b` naming
- **Files are source of truth** — state reconstructable from cycle.yaml and story files
- **Human checkpoints** — if ANYTHING weird, ask human (no assumptions)
- **State snapshot before every chunk** — YAML checkpoints for resume/recovery, one git commit at story completion
- **Walkthrough quick-fix exception** — Walkthrough findings with `complexity: quick-fix` and a `fix_hint` may be implemented directly by the orchestrator without invoking the implementer agent. This is the ONLY exception to the "always invoke implementer via Task" rule. Scoped to trivial CSS/attribute edits (1-5 lines, single file) where the walkthrough agent has provided a specific fix hint. Story-fix findings still go through the standard implementer loop.
- **Status line** — always-visible craft progress
- **Prompt-based hooks** — AI decides, not just bash scripts
- **Requests gate in /craft entry** — External tools can submit feature requests to `.craft/requests/`. The `/craft` entry flow surfaces pending requests as a priority gate (Step 2.5) before the full state scan — so the user sees what's been submitted before choosing what to work on. Auto/cruise modes are unaffected (they chain stories via direct skill invocations, never going through `/craft`).
- **Codebase alignment check** - Before plan-chunks runs, the orchestrator investigates the codebase where the work will land and surfaces every product question that only the user can answer. 95% alignment = zero unasked product questions. Uses an Explore agent with SendMessage for follow-up rounds. The `alignment` frontmatter field (`pending`/`complete`) ensures no story skips the check. See `commands/references/alignment-check.md`.
- **Three-tier file organization** - `reference/` for orchestration-critical files (injected by hooks, drives routing), `commands/references/` for command-specific execution files (read inline during command execution), `docs/` for generated informational documentation.

## State Management

**Files are source of truth.** State passes between agents via:
1. Explicit prompt handoff
2. File-based state (`.global-state`, `.state`, cycle.yaml, story files)
3. `CLAUDE_ENV_FILE` persistence
4. Dynamic skills with backtick injection of current state

**State files:**
- `.craft/.global-state` - active cycle, backlog count, run mode
- `.craft/cycles/{cycle}/.state` - current story/chunk progress
- `.craft/cycles/{cycle}/.failures` - failure tracking
- `.craft/planning/active.md` - planning live state (injected at `/craft` entry, not session start)

### Planning Concept Lifecycle

Concepts in `.craft/planning/` have a status that craft manages at natural touchpoints:

| Status | Meaning | Transition |
|--------|---------|------------|
| `open` | Concept exists, no stories yet | Created by `/craft:planning` |
| `planned` | Stories created from this concept | Auto-set when stories created via `/craft:planning` |
| `complete` | All linked stories shipped, user confirmed | Craft prompts at story complete; user confirms |
| `archived` | Removed from active planning | User-driven via `/craft:planning` |

Bidirectional traceability: concept frontmatter has `stories: [path]`, story frontmatter has `source_concept: path`. Links are advisory - `/craft:status` flags broken links but does not auto-heal.

## Commands

Commands are **shortcuts** — the default flow is conversational via AskUserQuestion.

| Command | Purpose |
|---------|---------|
| `/craft` | Main entry point — routes based on context |
| `/craft:status` | Rich dashboard (cycles, stories, backlog) |
| `/craft:plan` | Dedicated planning hub - plan requests, ideas, or backlog stories |
| `/craft:planning` | Feature roadmap - initiatives, concepts, open questions, story creation from planning |
| `/craft:story-new` | Create story (lands in backlog) |
| `/craft:story-implement` | Implement a story (interactive) |
| `/craft:story-implement-auto` | Implement a story (autonomous, for implement mode) |
| `/craft:story-continue` | Resume interrupted story |
| `/craft:story-archive` | Move story back to backlog |
| `/craft:story-delete` | Delete a story |
| `/craft:cycle-design` | Design a cycle (new or existing) |
| `/craft:cycle-start` | Activate a cycle |
| `/craft:cycle-assign` | Move story from backlog to cycle |
| `/craft:cycle-complete` | Complete a cycle, trigger reflection |
| `/craft:analyze` | Post-cycle analysis (QA, UX, Creative, Style) |
| `/craft:reflect` | Improve harness based on learnings |
| `/craft:update-docs` | Re-scan project, update project.md and locked.md |
| `/craft:project` | Switch projects or show cross-project dashboard |
| `/craft:research` | Ad-hoc research - discover, elaborate, synthesize with ranked branches |
| `/craft:research-verify` | Verify existing research findings against independent primary sources |
| `/craft:become` | Crystallize a tool, role, or person into a portable agent with beliefs, scar tissue, and instincts |
| `/craft:ask` | Consult a workshop agent - routes your question to the best available mind |
| `/craft:review` | PR-style code review - branch, story, or project audit. `--maze` flag enables perpendicular review via maze-architect |
| `/craft:fix` | Adhoc fix for small bugs without story ceremony. Creates permanent record in `.craft/fixes/` |
| `/craft:docs` | Generate or update docs using the crystallized doc-writer agent (two-pass: brief then generate) |
| `/craft:workflow` | Reusable multi-step workflows with agent/inline/manual/command execution |
| `/craft:init` | One-time: initialize harness for a project |

## Commit Messages

This is an open-source project. Every commit message lands in public `git log`, GitHub PR pages, and `git blame` views forever. Write them so a contributor browsing the repo for the first time can understand what changed without having read the codebase.

**Public craft terminology is fine** - these terms are the product:
skills, agents, commands, hooks, cycles, stories, backlog, modes, plus user-facing command names like `/craft:cycle-design`.

**Internal mechanism names need translation** - describe what the change DOES, not what we call it internally:

- ❌ `fix: chain break when content-spark invokes via Skill tool`
- ✅ `fix: prevent skill nesting from breaking control flow back to caller`
- ❌ `fix: add no-craft-workflow-leakage rule to implementer agent`
- ✅ `fix: prevent implementer agent from writing project-meta files into user codebases`

**Conventions:**
- Use conventional prefixes: `feat:` / `fix:` / `chore:` / `refactor:` / `docs:` / `test:`
- PR titles follow the same rule (they often inherit from the squash commit)
- Regular dashes only, never em dashes
- One concern per commit; bump `plugin.json` version in the same commit

When in doubt: "would a first-time contributor understand this?"

---

## Personality

- Momentum over perfection
- Challenge ideas constructively ("what if..." not "are you sure...")
- Celebrate progress
- No bureaucratic language
- Trust by default, verify when uncertain

---

*For detailed architecture, file templates, hook scripts, and design philosophy, see `DESIGN.md`, `reference/`, and `docs/`.*
