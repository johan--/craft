# Craft — Design Reference

> Architecture reference for `craft`, a Claude Code plugin that turns the CLI into a creative-first development harness. CLAUDE.md is the rules file Claude auto-loads each session; this file holds the architectural detail CLAUDE.md summarizes.

For definitions of cycle, story, chunk, and the workshop concepts, see README.md. This file assumes that vocabulary.

---

## Plugin Structure

```
plugins/craft/
├── .claude-plugin/
│   └── plugin.json            ← Plugin manifest (name, version)
├── agents/                    ← Isolated-context specialist agents (23 agents)
│   ├── alchemist.md           ← CSS interaction physicist (crystallized)
│   ├── become-researcher.md   ← Psychological material collector for /craft:become
│   ├── chunk-validator.md     ← Quality check executor (haiku model)
│   ├── conductor.md           ← AI orchestration architect (crystallized)
│   ├── creative-analyzer.md   ← Delight moments, viral potential
│   ├── crystallizer.md        ← Research-to-agent synthesizer (opus model)
│   ├── doc-writer.md          ← Documentation practitioner (crystallized)
│   ├── implementer.md         ← Implement → validate → refine loop per chunk
│   ├── maze-architect.md      ← Perpendicular review question generator (haiku)
│   ├── muse.md                ← Emotional job translator (crystallized)
│   ├── plan-chunks-agent.md   ← Autonomous chunk planning per story
│   ├── playwright-browser.md  ← Interactive browser session via playwright-cli
│   ├── pr-reviewer-expert.md  ← PR review (crystallized from CodeRabbit)
│   ├── practitioner-reviewer.md ← Practical experience claims challenger
│   ├── product-anthropologist.md ← Human-truth layer for product decisions
│   ├── project-scanner.md     ← Full project analysis for documentation updates
│   ├── qa-analyzer.md         ← Bug hunting via browser inspection
│   ├── researcher.md          ← Research sub-question investigator
│   ├── style-analyzer.md      ← Token compliance, pattern consistency
│   ├── tester.md              ← Integration tests, E2E, final validation
│   ├── ux-analyzer.md         ← Nielsen heuristics, accessibility
│   ├── verifier.md            ← Adversarial claim checker (primary sources only)
│   └── walkthrough-analyzer.md ← First-time user simulation (chrome-devtools MCP)
├── commands/                  ← Slash command definitions (25 commands)
│   ├── craft.md               ← Main entry point
│   ├── craft-ask.md           ← Consult a workshop agent (intelligent routing)
│   ├── craft-become.md        ← Agent crystallization (4-phase: research→checkpoint→crystallize→save)
│   ├── craft-docs.md          ← Documentation generation (two-pass: brief then generate)
│   ├── craft-init.md
│   ├── craft-planning.md
│   ├── craft-status.md
│   ├── craft-project.md
│   ├── craft-review.md        ← PR-style review with standard and --maze modes
│   ├── craft-research.md
│   ├── craft-research-verify.md ← Verify research findings against primary sources
│   ├── craft-cycle-design.md
│   ├── craft-cycle-start.md
│   ├── craft-cycle-assign.md
│   ├── craft-cycle-complete.md
│   ├── craft-story-new.md     ← Runs Likely Files scan; writes ## Likely Files section
│   ├── craft-story-implement.md
│   ├── craft-story-implement-auto.md
│   ├── craft-story-continue.md
│   ├── craft-story-archive.md
│   ├── craft-story-delete.md
│   ├── craft-analyze.md
│   ├── craft-reflect.md
│   ├── craft-update-docs.md
│   ├── craft-workflow.md      ← Workflow router (lean 191 lines, delegates to references/)
│   └── references/            ← Workflow sub-command reference files
│       ├── workflow-create.md
│       ├── workflow-execute.md
│       ├── workflow-formats.md
│       ├── workflow-manage.md
│       ├── workflow-sessions.md
│       └── workflow-validate.md
├── skills/                    ← Orchestrator-context skills (11 skills)
│   ├── approve/               ← Scoped write permission gate (AskUserQuestion + TaskCreate)
│   ├── browser/               ← playwright-cli browser automation launcher
│   ├── content-spark/         ← Surface content assumptions before creative/planning
│   ├── creative-spark/        ← Generate creative options; supports muse/alchemist drivers
│   ├── design-vibe/           ← Visual cohesion review across stories
│   ├── fix/                   ← Adhoc fix without story ceremony; records to .craft/fixes/
│   ├── lock-decision/         ← Formalize approved decisions
│   ├── plan-chunks/           ← Batch planning with file-based dependency verification
│   ├── validate-chunk/        ← Validation via git diff (not spec file list)
│   ├── refine-chunk/          ← Targeted fixes for validation failures
│   └── test-fix/              ← Triage failing tests, fix the right thing
├── hooks/
│   ├── hooks.json             ← Hook event definitions
│   └── scripts/               ← 35+ bash/python hook scripts
├── modes/                     ← Mode definitions (write scoping, tool access)
│   ├── chat.yaml              ← Creative mode: .craft/ writes only
│   └── implement.yaml         ← Implementation mode: full access, gated
├── templates/                 ← File templates for craft init and scaffolding
│   ├── craft/                 ← .craft/ directory templates
│   │   ├── design/            ← tokens.yaml, components.md, locked.md
│   │   ├── design-cli/        ← CLI-specific design templates
│   │   ├── inspiration/
│   │   ├── project.md
│   │   └── quality.yaml
│   ├── analysis/
│   │   └── pending/           ← Analysis queue templates
│   ├── cycle/
│   │   └── learnings.yaml
│   ├── cycle-state
│   ├── cycle.yaml
│   ├── planning/
│   ├── request.md
│   ├── story-backlog.md       ← Backlog story template
│   ├── story-full.md          ← Full story template (with chunks)
│   └── story-roadmap.md       ← Roadmap-only story template
├── reference/                 ← Orchestration-critical (injected by hooks, drives routing)
│   ├── decision-tree.md
│   ├── orchestration-index.md
│   └── orchestration-index.min
├── docs/                      ← Generated documentation (informational, not auto-loaded)
│   ├── agent-catalog.md
│   ├── creative-workshop.md
│   ├── design-philosophy.md
│   ├── plan-tdd-enforcement.md
│   ├── research-agentic-research-patterns.md
│   └── workflow-reference.md
├── tests/                     ← Bash test suite (25+ tests)
│   ├── run-all.sh
│   ├── test_helper.sh
│   ├── fixtures/
│   └── test-*.sh
├── CLAUDE.md                  ← Auto-loaded every session
├── DESIGN.md                  ← This file (reference only)
└── README.md                  ← Human-facing docs
```

---

## Statuses

| Status | Meaning |
|--------|---------|
| `draft` | Just an idea, not planned |
| `planning` | In creative mode, locking decisions |
| `ready` | Story file complete, can implement |
| `active` | Currently being implemented |
| `blocked` | Waiting on dependency |
| `complete` | 95% done, tests passing |
| `verified` | Human reviewed & approved |
| `reverted` | Story was started but reverted after a checkpoint; preserved for history |

## Parallelism

### Implementation Parallelism
- Max 2 stories in parallel, use `1a`, `1b` suffix
- Parallel stories must NOT touch same files

### Planning Parallelism
- `plan-chunks` skill supports batch mode: plans all `status: planning` stories in a cycle in parallel
- **Dual-mode orchestration:**
  - Agent teams (primary) — when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Teammates coordinate live (file overlap, dependency awareness)
  - Task subagents (fallback) — isolated agents with post-hoc cohesion check by orchestrator
- Batch size: determined by story dependency graph (topological levels — independent stories plan in parallel, dependent chains plan sequentially)
- Pattern: **skill as orchestrator + agents as workers** — plan-chunks orchestrates, plan-chunks-agent does the heavy lifting per story
- After agents complete → batch triage (BT-1 through BT-7) reviews all plans with user

## Workflow Formats

The workflow command supports two formats detected by checking for a `stages/` directory.

**Monolithic** — all stages in `definition.md`. Good for 3-5 stage workflows.

**stages-v1** — `definition.md` is a routing table; each stage is a self-contained file in `stages/`. Sessions get an `artifacts/` directory for cross-stage handoff. Stage files declare `consumes:` (artifact paths from prior stages) and `produces:` (output path). This is the preferred format for workflows with 6+ stages or substantial per-stage documentation.

Artifact handoff replaces relying on conversation memory across compaction boundaries. Stage 5 can reliably read Stage 1's output by declaring it in `consumes:` - the orchestrator reads the artifact file at dispatch time regardless of whether the original context is still present.

See `docs/workflow-reference.md` for the full format spec and examples.

---

## Human Checkpoints

- If ANYTHING weird → NO assumptions, ask human
- State snapshot before every chunk, one git commit at story completion
- Trust by default, verify when uncertain

---

## Modes Detail

### Chat Mode (`modes/chat.yaml`)

Write access restricted to `.craft/` and `.claude/` only. All creative and planning skills available. Used by Craftsman web chat agent and CLI sessions between stories.

**Included skills:** content-spark, creative-spark, design-vibe, lock-decision, plan-chunks, fix, approve, browser
**Included agents:** plan-chunks-agent, project-scanner, muse, alchemist, conductor, doc-writer, product-anthropologist, pr-reviewer-expert, maze-architect, researcher, verifier, practitioner-reviewer, playwright-browser, become-researcher, crystallizer
**Included commands:** craft, craft:init, craft:cycle-design, craft:cycle-start, craft:cycle-complete, craft:cycle-assign, craft:story-new, craft:story-archive, craft:story-delete, craft:status, craft:update-docs, craft:docs, craft:project, craft:review, craft:become, craft:ask, craft:workflow, craft:research, craft:research-verify, craft:fix

### Implement Mode (`modes/implement.yaml`)

Full write access, gated by `CRAFT_WRITE_ENABLED` in `.global-state`. Runs with `acceptEdits` permission mode. Max 100 turns. Auto-prompt: runs `/craft:story-implement-auto`.

**Allowed tools:** Read, Write, Edit, Glob, Grep, Bash, Task
**Included skills:** validate-chunk, refine-chunk, test-fix
**Included agents:** implementer, tester, chunk-validator
**Included commands:** craft:story-implement, craft:story-implement-auto, craft:story-continue

---

## Hooks Detail

All hooks defined in `hooks/hooks.json`. Scripts in `hooks/scripts/`.

### SessionStart
- **`session-start.sh`** (once) — Detects active cycle, sets status line, loads context
- **`post-compact-reinject.sh`** (on compact) — Re-injects craft context after context compaction

### PreToolUse (Write|Edit)
- **`check-write-permission.py`** — Enforces write permission gating. Checks mode (chat vs implement), CRAFT_WRITE_ENABLED flag, and allowed paths.

### PreToolUse (Bash)
- **`auto-approve-plugin-scripts.sh`** — Auto-approves bash invocations of plugin scripts to reduce permission prompts.

### PostToolUse (Write|Edit)
- **`update-progress.py`** (async) — Tracks which files were modified, updates story progress counts

### PostToolUseFailure
- **`handle-tool-failure.py`** (async) — Logs tool failures, appends to recovery log

### PreCompact
- **`export-progress.sh`** — Exports current progress state before context window compaction

### UserPromptSubmit
- **`inject-craft-context.sh`** — Injects active cycle/story context into every prompt

### Stop
- **`stop-hook-guard.sh`** — Guards against unclean session stops, ensures state consistency

### Utility Scripts (called by hooks or commands)
| Script | Purpose |
|--------|---------|
| `create-checkpoint.sh` | Git stash-based rollback points before chunks |
| `create-cycle.sh` | Scaffold a new cycle directory |
| `create-story.sh` | Create story file from template |
| `delete-story.sh` | Remove a story file |
| `move-story.sh` | Move story between backlog and cycle |
| `start-cycle.sh` | Set active cycle in .global-state |
| `start-story.sh` | Set active story, enable writes |
| `complete-chunk.sh` | Mark chunk done, update .state |
| `complete-story.sh` | Mark story complete, disable writes |
| `complete-cycle.sh` | Complete cycle, trigger learnings |
| `start-workflow-session.sh` | Initialize a workflow session directory and state |
| `complete-workflow-session.sh` | Mark a workflow session complete |
| `complete-workflow-stage.sh` | Advance workflow to the next stage |
| `get-latest-cycle.sh` | Resolve the most recent cycle directory path |
| `update-global-state.sh` | Update .global-state key-value pairs |
| `update-cycle-state.sh` | Update cycle .state file |
| `update-story-status.sh` | Change story status in frontmatter |
| `statusline.sh` | Generate status line display |
| `find-project-root.sh` | Locate .craft/ directory |
| `discover-projects.sh` | Find all craft projects |
| `count-requests.sh` | Count pending items in requests queue |
| `process-request.sh` | Route a request to a story or cycle |
| `salvage-partial-work.sh` | Recover work from interrupted sessions |
| `append-recovery-log.sh` | Log recovery events |
| `read-events.sh` | Read from the event log |
| `append-event.sh` | Append an entry to the event log |
| `aggregate-failures.py` | Aggregate failure records for triage |
| `run-gates.sh` | Run quality gate checks |
| `check-polish.sh` | Check polish requirements |
| `self-critique.sh` | Self-critique against locked patterns |
| `generate-project-md.sh` | Generate project.md from scan |
| `setup-craft.sh` | Initial .craft/ directory setup |
| `track-usage.sh` | Track usage metrics |

---

## .craft/ Directory Structure (Complete)

```
project-root/
├── .craft/
│   ├── backlog/               ← Stories not yet in a cycle
│   │   └── story-name.md
│   ├── cycles/                ← Time-boxed work containers
│   │   └── 1-auth/
│   │       ├── cycle.yaml     ← Cycle metadata (name, goal, dates, optional source_concept)
│   │       ├── .state         ← Current story/chunk progress
│   │       ├── .failures      ← Failure tracking for retry logic
│   │       ├── .learnings.yaml ← Cycle learnings for reflection
│   │       └── stories/
│   │           └── 1-story-name.md
│   ├── checkpoints/           ← Chunk rollback points (YAML)
│   ├── fixes/                 ← Adhoc fix records (created by /craft:fix)
│   │   └── fix-name.md        ← category, root cause, solution, lesson
│   ├── analysis/              ← Persistent analysis findings
│   │   ├── pending/           ← Findings queue (survives sessions)
│   │   │   ├── qa.yaml
│   │   │   ├── ux.yaml
│   │   │   ├── creative.yaml
│   │   │   └── style.yaml
│   │   ├── screenshots/
│   │   └── reports/
│   ├── inspiration/           ← Reference library for Creative Mode
│   │   ├── screenshots/
│   │   ├── sites.md
│   │   └── patterns.md
│   ├── design/                ← Design system (enforced)
│   │   ├── tokens.yaml        ← Design tokens
│   │   ├── components.md      ← Component patterns
│   │   ├── locked.md          ← Approved patterns (enforced)
│   │   ├── animations.md      ← Animation patterns
│   │   └── .confidence-signals.yaml ← Token confidence scores (use_count, file_count, consistency_score, recency)
│   ├── workflows/             ← Reusable multi-step workflows
│   │   └── {workflow-slug}/
│   │       ├── definition.md  ← Routing table (stages-v1) or full definition (monolithic)
│   │       ├── stages/        ← Per-stage self-contained briefs (stages-v1 format only)
│   │       └── sessions/      ← Per-run instances with progress + artifacts
│   ├── requests/              ← External feature requests
│   │   └── processed/         ← Requests routed to stories or cycles
│   ├── docs/                  ← Documentation briefs (created by /craft:docs)
│   │   └── brief.md
│   ├── research/              ← Ad-hoc research folders (created by /craft:research)
│   │   └── {topic-slug}/
│   │       ├── _plan.md
│   │       ├── 01-branch.md
│   │       └── verification-{slug}.md
│   ├── project.md             ← Project DNA
│   ├── quality.yaml           ← Quality gates
│   ├── settings.yaml          ← Craft settings
│   ├── .global-state          ← Active cycle, global config
│   └── .continuation          ← Breadcrumb for skill continuation (transient, 30-min TTL)
└── src/
```

### .global-state Fields

```
LAST_ACTIVITY="2026-04-14T00:11:52Z"
ACTIVE_CYCLE="8-token-lifecycle-v3"
CURRENT_STORY=""
DEFAULT_MODE="creative"
BACKLOG_COUNT="10"
PLANNING_CYCLE=""
CRAFT_WRITE_ENABLED=""
CYCLE_STATUS=""
CURRENT_WORKFLOW_SESSION=""
RUN_MODE=""
```

Key fields:
- `CRAFT_WRITE_ENABLED` — gates writes outside `.craft/`. Set to `"true"` by active stories, the `fix` skill, and the `approve` skill. Empty string means closed.
- `CURRENT_WORKFLOW_SESSION` — active workflow session path (set when a workflow session is running).
- `RUN_MODE` — `cruise` (chains stories automatically) or empty (interactive).
- `CYCLE_STATUS` — current state of the active cycle.

### cycle.yaml Schema

```yaml
name: cycle-slug
title: "Cycle NN: Display Title"
status: planning | ready | active | complete
created: YYYY-MM-DD
updated: YYYY-MM-DD
target: One-line description of what ships
focus: Primary focus area
source_concept: [planning/concept-a.md, planning/concept-b.md]   # may be empty []

goals:
  - Outcome 1
  - Outcome 2
```

**`source_concept`** — YAML flow list of planning doc paths (relative to project root) this cycle is sourced from. Empty list `[]` means the cycle is freeform (no planning source). When populated, cycle-design routes story-creation moments to the From planning protocol (`commands/references/story-from-planning.md`) so each planning-extracted story's spark draws from the planning content. Stories added during the add-a-separate-story moment within a planning-sourced cycle remain freeform and get no `source_concept` of their own. Captured at cycle creation via `create-cycle.sh`'s 5th positional arg, gated behind the Step 1 verbatim-quote rule + AskUserQuestion safety gate.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  ENTRY: /craft or just start talking                            │
│  → Creates story → Assign to cycle or backlog                   │
└─────────────────────────────────────────────────────────────────┘
         │                                    │
    BACKLOG ──assign──▶ CYCLE ──▶ CHAT MODE (creative)
                                      │
                               IMPLEMENT MODE (autonomous)
                                      │
                               ANALYSIS MODE (post-cycle)
                                      │
                               Back to Backlog / Cycle
```

---

## Testing

Bash test suite in `tests/`. Run all tests:

```bash
./tests/run-all.sh
```

Individual tests follow the pattern `test-{script-name}.sh` and test the corresponding hook script. Tests use `test_helper.sh` for shared setup/teardown and fixtures from `tests/fixtures/`.

---

*For decision trees and orchestration routing, see `reference/`. For design philosophy and TDD enforcement patterns, see `docs/`.*
