# Workflow: Execute

Reference for Step 4 - loading sessions, creating tasks, executing stages, transitioning state.

### Step 4: Continue Session / Execute

#### 4.0: Load Session

If coming from "continue" mode, find active sessions:

Use **Glob** to find all `session.md` files: `$PROJECT/.craft/workflows/*/sessions/*/session.md`
Read each with `limit: 10` to check frontmatter. Filter for `status: active`.

**If an active session exists:** If multiple, let user pick. If one, auto-select.

**If NO active session exists:** Check for runnable sessions (draft or ready) using Step 3c logic across all workflows.

If runnable sessions found, show the next one and offer to activate it:

> "No active session. Next up: **{session name}** [{draft|ready}] in {workflow name}"

Use **AskUserQuestion**:
```
question: "No active workflow session. {N} draft sessions remaining. Next up: {session name}"
header: "Workflow"
options:
  - label: "Activate next and run"
    description: "Run {session name}, stop after it completes"
  - label: "Run all in sequence"
    description: "Chain through all {N} remaining sessions"
  - label: "Pick a different one"
    description: "Choose which session to run"
```

**If "Activate next and run":** Run `start-workflow-session.sh` for that session, execute per Step 4.1. After session completes, **stop** - do not auto-advance.

**If "Run all in sequence":** Run `start-workflow-session.sh`, execute per Step 4.1. After session completes, find next runnable session via Step 3c. If found, activate and run it. Repeat until none remain.

**If "Pick a different one":** List all non-complete sessions. Let user select via AskUserQuestion. Activate the chosen session and proceed.

If no runnable sessions found either: "No active, draft, or ready sessions found."

Read the session's `session.md` to get current_stage, mode, and variables.
Read the parent workflow's `definition.md` to get stage execution details.

#### 4.1: Create Tasks for Live Progress Tracking

**Use the built-in Task tools to create a live checklist visible in the terminal UI.** This is the primary progress display - not custom text output.

**Load stage list based on format:**
- **stages-v1:** Read the `## Stages` routing table from `definition.md`. Each row gives the stage number, name, execution mode, and file path.
- **monolithic:** Read `## Stage N:` headings from `definition.md` as before.

For each stage, call **TaskCreate**:

```
TaskCreate({
  subject: "Stage {N}: {Name}",
  description: "{execution mode} | {one-line stage description}",
  activeForm: "Running Stage {N}: {Name}"
})
```

Then set up dependencies with **TaskUpdate**:

```
TaskUpdate({
  taskId: "{stage-2-id}",
  addBlockedBy: ["{stage-1-id}"]
})
```

This produces a persistent, visible checklist in the terminal that:
- Shows completed/in-progress/pending status for every stage
- Updates in real-time as stages advance
- Survives context compaction (agent can call TaskList to recover state)
- Is visible to both the agent and the user at all times

Set Stage 1 to `in_progress` immediately after creating all tasks.

**After context compaction or session restart:** Call **TaskList** to recover current workflow state. The task with `status: in_progress` is the current stage. All `completed` tasks are done stages. This replaces the need to re-read session.md for live state.

#### 4.2: Execute Current Stage

**Load stage details based on format:**

1. Detect format (check for `stages/` directory in workflow dir - see Format Detection).

2. **If stages-v1:**
   a. Read the routing table from `definition.md` `## Stages` to find the stage file path for the current stage number.
   b. Read the stage file (e.g., `stages/03-domain-map.md`).
   c. Extract execution mode, agent, prompt, produces, consumes, human_gate from the stage file frontmatter and body.
   d. **Artifact dependency check (fail fast):** If the stage has a non-empty `consumes:` list, substitute `{session_dir}` in each path and verify the file exists on disk using Glob or Read. If ANY consumed artifact is missing, **do not dispatch the stage.** Report: "Stage N requires artifact `{path}` from a prior stage, but it doesn't exist. The prior stage may not have produced output, or artifact capture was skipped." Use AskUserQuestion to let the user re-run the prior stage or provide the artifact manually.
   e. Substitute all `{variable}` placeholders in the stage file content using the session's `variables:` frontmatter values PLUS the system variable `{session_dir}` (the full path to this session's directory). This is on-the-fly substitution - the stage file on disk stays as a template.
   f. For agent-type stages: the substituted `## Prompt` section becomes the agent prompt. The session's checklist section for this stage is what the orchestrator tracks for completion.
   g. For inline-type stages: the substituted body (everything after frontmatter) becomes the orchestrator's instructions.

3. **If monolithic:**
   Read the stage's execution mode from the definition as before (current behavior).

**Then execute based on execution mode (same for both formats):**

**If `agent`:**
1. Substitute session variables into the prompt template (from stage file for stages-v1, from definition for monolithic).
2. Spawn the specified agent via the Agent tool.
3. When agent completes, check its output for success indicators.
4. **Artifact capture (stages-v1 only):** Write the agent's output to `{session_dir}/artifacts/NN-{stage-slug}.md`. This makes the output available to downstream stages that declare it in their `consumes:` frontmatter.
5. Mark checklist items as complete in session.md.
6. Update `session.md`: mark stage `[complete]`, add `completed: {timestamp}`, increment `current_stage`.
7. **If interactive mode:** If the stage has a `human_gate:`, present it as an AskUserQuestion (see `human_gate:` AskUserQuestion below). Otherwise, show agent results and ask "Ready to proceed to Stage {N+1}?"
8. **If auto mode:** Advance automatically to next stage. `human_gate:` is ignored.

**If `manual`:**
1. Display the stage description and checklist (from stage file for stages-v1, from definition for monolithic).
2. **Artifact requirement check (stages-v1 only):** If this stage has a non-empty `produces:` or any downstream stage's `consumes:` references this stage's artifact, inform the user: "This stage's output is needed by a later stage. When you're done, paste or describe your output so I can write it to `{session_dir}/artifacts/NN-{stage-slug}.md`."
3. Present: "This stage requires your input. Mark items as you complete them."
4. Use **AskUserQuestion**:
```
question: "Stage {N}: {Name} - What's the status?"
header: "Progress"
options:
  - label: "Complete"
    description: "All items done, advance to next stage"
  - label: "In progress"
    description: "Still working, pause here"
  - label: "Skip"
    description: "Skip this stage (flagged in validation)"
```
5. **If "Complete" and artifact is required:** Ask the user for their output and write it to the artifact file before transitioning. The `complete-workflow-stage.sh` script will verify it exists.
6. Update session.md based on response.

**If `inline`:**
1. Substitute session variables into the prompt/instructions template (from stage file for stages-v1, from definition for monolithic).
2. Execute the instructions directly as the orchestrator - read files, make edits, run commands, etc. You have full workflow context including all prior stage results.
3. When complete, mark checklist items as complete.
4. **Artifact capture (stages-v1 only):** Write a summary of what you did to `{session_dir}/artifacts/NN-{stage-slug}.md` (files modified, decisions made, key outputs).
5. Update `session.md`: mark stage `[complete]`, add `completed: {timestamp}`, increment `current_stage`.
6. **If interactive mode:** If the stage has a `human_gate:`, present it as an AskUserQuestion (same options as below). Otherwise, show results and ask "Ready to proceed to Stage {N+1}?"
7. **If auto mode:** Advance automatically to next stage. `human_gate:` is ignored.

**`human_gate:` AskUserQuestion** (used by any execution type in interactive mode):
```
question: "{human_gate description from definition}"
header: "Review"
options:
  - label: "Approve and continue"
    description: "Output looks good"
  - label: "Needs work"
    description: "Provide feedback, re-run stage"
  - label: "I'll handle it manually"
    description: "Skip automation, do it myself"
```
If "Approve" -> advance. If "Needs work" -> get feedback, re-run. If "Manually" -> switch to manual for this stage only.

**If `command`:**
1. **Write breadcrumb** before invoking the skill (see Breadcrumb Pattern in the main command).
2. Invoke the specified craft command via the **Skill** tool.
3. When command completes, the stop hook reads the breadcrumb and re-invokes `/craft:workflow continue`.
4. The orchestrator loads the session, sees the stage is done, marks it complete, and advances.

#### 4.3: Stage Transition (MANDATORY - BOTH SCRIPT AND TASKS)

After completing a stage, do BOTH of these. Do not skip either.

**1. Run the transition script** (updates session.md - the permanent record):

```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/complete-workflow-stage.sh "{session-dir}" {stage-number} "{optional notes}"
```

Example:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/complete-workflow-stage.sh ".craft/workflows/write-lesson/sessions/2026-04-10-mcp-u1-l3" 3 "5 violations found, all fixed"
```

The script handles both formats automatically:
- **monolithic:** Changes stage heading `[active]` -> `[complete]`, checks all `- [ ]` items, adds `completed:` date, increments `current_stage`, marks next stage `[active]`.
- **stages-v1:** Updates the Progress table row (status -> complete, adds date and notes), checks `- [ ]` items in the stage's checklist section, updates stage heading status tags, increments `current_stage`, marks next stage active in both the Progress table and checklist heading. Also verifies artifact existence for non-manual stages with `produces:`.

**2. Update Tasks** (updates live UI - what you and the user see):

```
TaskUpdate({ taskId: "{completed-stage-task-id}", status: "completed" })
TaskUpdate({ taskId: "{next-stage-task-id}", status: "in_progress" })
```

If the script reports "ALL STAGES COMPLETE", jump to **Step 5** (Validation).

**Then continue:**
- **If there are more stages:** Continue to next stage (respecting mode).
- **If all stages complete:** Jump to **Step 5** (Validation). **This is mandatory - do not skip validation. Do not present results to the user before validation runs.**

#### 4.4: Session Interruption

If the user needs to stop mid-session:
- The session stays `active` with `current_stage` pointing to where they stopped.
- `/craft:workflow continue` picks up exactly here next time.
- No state is lost - everything is in `session.md`.
- `session-start.sh` should surface active workflow sessions as a reminder (same pattern as active stories).
