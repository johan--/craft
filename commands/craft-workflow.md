---
name: craft:workflow
description: "Define reusable multi-step workflows with mixed execution modes (agent/inline/manual/command). Create definitions, run sessions, track progress."
argument-hint: "[create | batch <name> | list | run <name> | next <name> | run-all <name> | continue | ready <name> | archive <name> | <workflow-name>]"
---

# Workflow

Reusable multi-step process engine. Define a workflow once, run it many times with different variables. Each step can be agent-driven, inline (orchestrator executes with full context), manual, or a craft command.

## Project Root

Use `$CRAFT_PROJECT_ROOT` (set at session start) as the base path for all `.craft/` references. If not set, resolve by walking up from PWD to find the nearest `.craft/.global-state`.

Set `PROJECT` to `${CRAFT_PROJECT_ROOT:-.}`.

## Format Detection

To determine which format a workflow uses, check for a `stages/` directory with at least one file:

```
WORKFLOW_DIR="$PROJECT/.craft/workflows/{workflow-slug}"
if [ -d "$WORKFLOW_DIR/stages" ] && [ -n "$(ls -A "$WORKFLOW_DIR/stages" 2>/dev/null)" ]; then
  # New format: stage-file dispatch
  FORMAT="stages-v1"
else
  # Old format: monolithic definition
  FORMAT="monolithic"
fi
```

All dispatch, session creation, and stage loading steps MUST check format before acting. When `FORMAT="stages-v1"`, read stage details from individual files in `stages/`. When `FORMAT="monolithic"`, read from `definition.md` sections as before.

## File Structure

```
.craft/workflows/
  {workflow-name}/
    definition.md              # Routing table (stages-v1) or full definition (monolithic)
    stages/                    # Per-stage self-contained briefs (stages-v1 only)
      01-name.md
      02-name.md
    sessions/
      {YYYY-MM-DD}-{slug}/
        session.md             # Progress + checklists (hybrid) or full content (monolithic)
        artifacts/             # Stage outputs for cross-stage handoff (stages-v1 only)
  .archived/                   # Archived workflows (still readable)
```

## Flow

### Step 0: Determine Invocation Mode

Parse args to determine routing:

**Mode A - "create":** Args start with `create`.
-> Read [references/workflow-create.md](references/workflow-create.md) for the full create flow.

**Mode A2 - Inline workflow in user message:** The user's message contains a numbered list of steps (e.g., "1. Read the blueprint... 2. Write content...") alongside or instead of `create`. Treat this as "from scratch" input - skip the source selection AskUserQuestion and parse the steps directly from the user's message.
-> Read [references/workflow-create.md](references/workflow-create.md), jump to Step 1.3 with the parsed stages.

**Mode B - "list":** Args are `list`.
-> Jump to **Step 2** (Dashboard) below.

**Mode C - "run {name}":** Args start with `run`.
-> Read [references/workflow-sessions.md](references/workflow-sessions.md) for session creation (Step 3).

**Mode C2 - "batch {name}":** Args start with `batch`.
-> Read [references/workflow-sessions.md](references/workflow-sessions.md) for batch creation (Step 3b).

**Mode D - "continue":** Args are `continue`.
-> Read [references/workflow-execute.md](references/workflow-execute.md) for execution (Step 4).

**Mode I - "next {name}":** Args start with `next`.
-> Read [references/workflow-sessions.md](references/workflow-sessions.md) for next session (Step 3d).

**Mode J - "run-all {name}":** Args start with `run-all`.
-> Read [references/workflow-sessions.md](references/workflow-sessions.md) for run-all (Step 3e).

**Mode E - "archive {name}":** Args start with `archive`.
-> Read [references/workflow-manage.md](references/workflow-manage.md) for archive (Step 7).

**Mode F - "ready {name}":** Args start with `ready`.
-> Read [references/workflow-manage.md](references/workflow-manage.md) for ready (Step 8).

**Mode G - "{workflow-name}":** Args match an existing workflow folder name in `$PROJECT/.craft/workflows/`.
-> Jump to **Step 2b** below.

**Mode H - No args:** Jump to **Step 2** (Dashboard).

---

### Step 2: Dashboard / List Workflows

Use **Glob** with pattern `$PROJECT/.craft/workflows/*/definition.md` to find all workflows (excludes `.archived/`).

For each workflow:
- Read frontmatter with `limit: 10` (name, description, stages count)
- Use **Glob** to find sessions: `$PROJECT/.craft/workflows/{slug}/sessions/*/session.md`
- Read each session's frontmatter with `limit: 10` for status and current_stage

Also check each session's Validation section for issue counts: count `- [ ]` items under `### Issues`.

Display:

```
WORKFLOWS
---------

  {Workflow 1 Name}                              {N} stages
  {description}
  |- [active]   {Session 1 name}       stage 4/13
  |- [ready]    {Session 2 name}
  |- [complete] {Session 3 name}       clean
  '- [complete] {Session 4 name}       2 issues

  {Workflow 2 Name}                              {N} stages
  {description}
  '- No sessions yet
```

Use **AskUserQuestion**:
```
question: "What would you like to do?"
header: "Action"
options:
  - label: "Continue active session"
    description: "Resume {session name} at stage {N}"
    -> only show if there's an active session
  - label: "Start new session"
    description: "Run an existing workflow with new variables"
  - label: "Create new workflow"
    description: "Define a new workflow from scratch or import"
  - label: "Browse a workflow"
    description: "View details, sessions, or edit"
```

Route based on selection.

### Step 2b: Browse Workflow

Read the workflow's `definition.md`. Display stage overview with execution modes. For stages-v1 format, the `## Stages` routing table in definition.md directly provides the stage overview. For monolithic format, extract stage info from `## Stage` headings.

List sessions with status.

Use **AskUserQuestion**:
```
question: "What would you like to do with {workflow name}?"
header: "Action"
options:
  - label: "Run new session"
    description: "Create a new session with this workflow"
  - label: "Continue a session"
    description: "Resume an in-progress session"
  - label: "View definition"
    description: "Show the full workflow definition"
  - label: "Archive workflow"
    description: "Move to .archived/ (keeps all data)"
```

---

## Breadcrumb Pattern

For `command`-type stages that invoke skills via the Skill tool, write a breadcrumb before invocation to prevent the orchestrator from stopping after the skill returns.

**Write before invoking the skill:**
```bash
cat > "${CRAFT_PROJECT_ROOT:-.}/.craft/.continuation" << CRUMB
ACTION: Continue workflow session "{session-name}" from stage {N+1}
SKILL: craft:craft-workflow
ARGS: continue
WRITTEN_BY: craft-workflow
TIMESTAMP: $(date -u +%Y-%m-%dT%H:%M:%S)
CRUMB
```

**Clean up on ALL exit paths** (session complete, user cancels, error):
```bash
rm -f "${CRAFT_PROJECT_ROOT:-.}/.craft/.continuation"
```

**Not needed for:** `agent`-type stages (Agent tool returns inline), `inline`-type stages (orchestrator executes directly), or `manual` stages (AskUserQuestion pauses naturally).

**Safety:** Same guarantees as all craft breadcrumbs - 30-minute TTL, one-shot, session-start cleanup.

---

## Format References

For all definition and session format specifications, see [references/workflow-formats.md](references/workflow-formats.md).
