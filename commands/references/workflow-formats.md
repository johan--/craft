# Workflow: Format References

All definition and session format specifications - monolithic and stages-v1.

---

## Definition Format Reference (Monolithic)

```markdown
---
name: {Workflow Name}
description: {one-line description}
created: {date}
variables:
  {var}: "{description}"
stages: {count}
---

# {Workflow Name}

{Overview paragraph.}

## Stage 1: {Name}
execution: agent
agent: craft:researcher
prompt: "Research {topic} for {domain}"
produces: .craft/research/{topic}-pedagogy/
requires: []

{Human-readable description of what this stage does, why it matters,
and what principles apply. This IS the process documentation.}

- [ ] {Completion criterion 1}
- [ ] {Completion criterion 2}

## Stage 2: {Name}
execution: inline
prompt: "Synthesize the research from Stage 1 into a landscape map for {topic}"
produces: .craft/research/{topic}-landscape/
requires: [stage-1]
human_gate: "Review the landscape map before proceeding to domain mapping"

{Description - orchestrator executes this directly with full workflow context.
human_gate is optional - in interactive mode it pauses for review, in auto mode it is ignored.}

- [ ] {Criterion 1}
- [ ] {Criterion 2}

## Stage 3: {Name}
execution: manual
requires: [stage-2]

{Description - this stage is done by the human.}

- [ ] {Criterion 1}

## Stage 4: {Name}
execution: command
command: craft:research-verify
args: "{topic}-domain-map"
requires: [stage-3]

{Description.}

- [ ] {Criterion 1}
```

**Formatting rules:**
- Execution metadata lines (`execution:`, `agent:`, `prompt:`, `produces:`, `requires:`, `human_gate:`, `command:`, `args:`) go immediately after the `##` heading, before any prose.
- `human_gate:` is optional on any execution type. In interactive mode, the orchestrator presents it as an AskUserQuestion after the stage work completes. In auto mode, it is ignored.
- The prose section is the human-readable process documentation, preserved from the source.
- Checklist items (`- [ ]`) are the completion criteria.
- `requires:` lists stage dependencies. Default is sequential (`[stage-N-1]`). No dependencies = `[]`.
- Variable substitution uses `{variable}` syntax throughout prompts, produces, args, and checklist items.

---

## New Definition Format Reference (Stage-File Format)

When a workflow has a `stages/` directory, the definition.md is a routing table only:

```markdown
---
name: {Workflow Name}
description: {one-line description}
created: {date}
variables:
  {var}: "{description}"
stages: {count}
format: stages-v1
---

# {Workflow Name}

{Overview paragraph.}

## Stages

| # | Name | Execution | File | Produces |
|---|------|-----------|------|----------|
| 1 | {Stage Name} | agent | stages/01-slug.md | .craft/research/{topic}-pedagogy/ |
| 2 | {Stage Name} | inline | stages/02-slug.md | .craft/research/{topic}-landscape/ |
| 3 | {Stage Name} | manual | stages/03-slug.md | |
| 4 | {Stage Name} | command | stages/04-slug.md | |
```

Each stage file in `stages/` is a self-contained brief:

```markdown
---
stage: 1
name: {Stage Name}
execution: agent
agent: craft:researcher
produces: .craft/research/{topic}-pedagogy/
consumes: []
human_gate: ""
---

# Stage 1: {Stage Name}

{Human-readable description of what this stage does, why it matters,
and what principles apply. This IS the process documentation.
Variable placeholders like {topic} and {domain} are substituted
at dispatch time from session variables.}

## Prompt

Research {topic} for {domain}. Focus on evidence-based approaches
and pedagogical best practices.

## Checklist

- [ ] Research branches produced
- [ ] Expert agent crystallized

## Artifacts

- **Produces:** `.craft/research/{topic}-pedagogy/`
- **Consumes:** (none - first stage)
```

**Stage file rules:**
- Frontmatter contains all machine-readable metadata (execution mode, agent, produces, consumes, human_gate).
- `consumes:` lists artifact file paths from prior stages. Use `{session_dir}` to reference the current session's artifact directory. Example: `["{session_dir}/artifacts/01-pedagogy-research.md"]`.
- `produces:` is the artifact or file path this stage creates.
- The `## Prompt` section is the agent/inline instructions. Variable placeholders (`{variable}`) are substituted at dispatch time.
- The `## Checklist` section defines completion criteria. These are copied into the session at creation time for per-session tracking.
- The prose between the heading and `## Prompt` is human-readable documentation - not sent to agents.
- Stage files are templates shared across all sessions - never modified per-session.

---

## Session Format Reference (Monolithic)

```markdown
---
workflow: {workflow-slug}
name: {Session Name}
status: active
mode: interactive
started: {date}
completed: {date, when done}
current_stage: 4
variables:
  topic: mcp
  domain: Model Context Protocol
  project: slingshot
---

# {Session Name} - {Workflow Name}

## Stage 1: Pedagogy Research [complete]
- [x] Research branches produced
- [x] Expert agent crystallized
completed: 2026-04-08
artifacts: .craft/research/mcp-pedagogy/
notes: "Crystallized at .claude/agents/evidence-based-practitioner-training-expert.md"

## Stage 2: Education Landscape [complete]
- [x] Landscape mapped
- [x] Gaps identified
completed: 2026-04-08
artifacts: .craft/research/mcp-education-landscape/

## Stage 3: Domain Map [complete]
- [x] Concept inventory complete
- [x] Prerequisite chains documented
completed: 2026-04-09
artifacts: .craft/research/mcp-domain-map/

## Stage 4: Gap Analysis [active]
- [x] Coverage table produced
- [ ] Mermaid diagrams generated
- [ ] Proposal reviewed

## Validation
status: passed-with-issues
checked: 2026-04-10

### Issues
- [ ] Stages 3-7: checklist items not marked [x] despite stages marked [complete]
- [x] Artifact verified: .craft/research/mcp-domain-map/ exists

### Summary
Stages: 4/4 complete, 0 skipped
Checklist: 6/10 items checked
Artifacts: 1/1 present
```

**Session status lifecycle:** `draft` -> `ready` -> `active` -> `complete`

**Stage status tags:** `[pending]`, `[active]`, `[complete]`, `[skipped]`

**Validation statuses:** `clean`, `passed-with-issues`

---

## New Session Format Reference (Hybrid)

When the parent workflow uses stage-file format, sessions have a Progress table for routing plus per-stage checklists for step tracking. Prompts live in stage files only - never in the session.

**System variables** (auto-set, not user-defined):
- `{session_dir}` - full path to this session's directory. Used in stage prompts to reference artifact files from prior stages.

```markdown
---
workflow: {workflow-slug}
name: {Session Name}
status: active
mode: interactive
started: {date}
completed:
current_stage: 4
variables:
  topic: mcp
  domain: Model Context Protocol
  project: slingshot
  session_dir: "/full/path/to/.craft/workflows/write-lesson/sessions/2026-04-08-mcp-course"
---

# {Session Name} - {Workflow Name}

## Progress

| # | Stage | Status | Completed | Notes |
|---|-------|--------|-----------|-------|
| 1 | Pedagogy Research | complete | 2026-04-08 | Crystallized at .claude/agents/... |
| 2 | Education Landscape | complete | 2026-04-08 | |
| 3 | Domain Map | complete | 2026-04-09 | |
| 4 | Gap Analysis | active | | |
| 5 | Course Structure | pending | | |

## Stage 1: Pedagogy Research [complete]
- [x] Research branches produced
- [x] Expert agent crystallized

## Stage 2: Education Landscape [complete]
- [x] Landscape mapped
- [x] Gaps identified

## Stage 3: Domain Map [complete]
- [x] Concept inventory complete
- [x] Prerequisite chains documented

## Stage 4: Gap Analysis [active]
- [x] Coverage table produced
- [ ] Mermaid diagrams generated
- [ ] Proposal reviewed

## Stage 5: Course Structure [pending]
- [ ] Unit structure finalized
- [ ] Lesson flow documented

## Validation
(written by complete-workflow-session.sh at session end)
```

**Hybrid session rules:**
- The `## Progress` table is the routing index - the orchestrator reads this to know which stage is current.
- Per-stage checklist sections (`## Stage N: {Name} [status]`) contain the checklist items copied from stage files at session creation time. These are per-session and get checked off during execution.
- No prompts in the session - those are loaded on demand from stage files at dispatch time.
- `{session_dir}` is set automatically in the session's variables at creation time.

**Artifact handoff:** After each agent stage completes, the orchestrator writes the agent's output to `{session_dir}/artifacts/NN-slug.md`. Downstream stages reference these via `{session_dir}` in their prompts:

```
sessions/2026-04-08-mcp-course/
  session.md
  artifacts/
    01-pedagogy-research.md
    02-education-landscape.md
    03-domain-map.md
```

Stage files declare dependencies via `consumes:` frontmatter:
```yaml
consumes:
  - "{session_dir}/artifacts/01-pedagogy-research.md"
  - "{session_dir}/artifacts/02-education-landscape.md"
```

The orchestrator substitutes `{session_dir}` at dispatch time so the agent receives concrete file paths it can read directly.
