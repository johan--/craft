# Workflow: Sessions

Reference for session lifecycle - create, batch, find next, run next, run all.

### Step 3: New Session

#### 3.1: Select Workflow

If workflow name provided in args, use it. Otherwise, list available workflows and let user pick.

Read the workflow's `definition.md` to get variables and stages.

#### 3.2: Name and Configure Session

Ask for session name (e.g., "MCP Course", "Auth Service").

For each variable in the definition, ask for the value:

> **Fill in workflow variables:**
> - `{var1}` ({description}):
> - `{var2}` ({description}):

#### 3.3: Choose Run Mode

Use **AskUserQuestion**:
```
question: "How do you want to run this session?"
header: "Mode"
options:
  - label: "Interactive (Recommended)"
    description: "Step through each stage, confirm before advancing"
  - label: "Auto"
    description: "Run all stages automatically, pause only at manual gates"
  - label: "Draft only"
    description: "Create the session file but don't start yet"
```

#### 3.4: Write Session File

Create the session directory using Bash:

```bash
mkdir -p "$PROJECT/.craft/workflows/{workflow-slug}/sessions/{date}-{session-slug}"
```

**Determine format:** Check if `$PROJECT/.craft/workflows/{workflow-slug}/stages/` exists (see Format Detection).

**If stages-v1 format:**

Also create the artifacts directory:
```bash
mkdir -p "$PROJECT/.craft/workflows/{workflow-slug}/sessions/{date}-{session-slug}/artifacts"
```

Write `session.md` with hybrid format (see **New Session Format Reference** in [references/workflow-formats.md](references/workflow-formats.md)). The session contains:
- Frontmatter: workflow, name, status, mode, started, completed, current_stage, variables (including system variable `session_dir` set to the full session directory path)
- H1 title
- `## Progress` table with one row per stage (columns: #, Stage, Status, Completed, Notes). All stages start as `pending` status. Read stage names from the definition's `## Stages` routing table.
- Per-stage checklist sections: for each stage, read the `## Checklist` from its stage file and copy the items into the session as `## Stage N: {Name} [pending]` with `- [ ]` items. Variable substitution on checklist items happens here.
- No prompts - those stay in stage files and are loaded on demand at dispatch.

**If monolithic format:**
Write `session.md` - see **Session Format Reference** in [references/workflow-formats.md](references/workflow-formats.md) for the full format.

Variable substitution: replace all `{variable}` placeholders in checklist items and descriptions with the session's variable values.

**Both formats:**

**If "Draft only"** -> Done. Show the session file path.
**If "Interactive" or "Auto"** -> Run `start-workflow-session.sh {session-dir}` to set status to active. Jump to **Step 4** (Execute).

---

### Step 3b: Batch Create Sessions

Create multiple sessions as `draft` in one pass. No execution, no prompts to run.

#### 3b.1: Select Workflow

Same as Step 3.1.

#### 3b.2: Collect Variable Sets

Ask the user for a list of variable sets. Two input modes:

**List mode** (most common): User provides a comma-separated or newline-separated list of the primary variable. The orchestrator infers the rest from the definition's defaults or from context.

Example:
> Provide the lesson IDs to create sessions for:

User: `mcp-u1-l3, mcp-u1-l4, mcp-u2-l1, mcp-u2-l2, mcp-u2-l3, mcp-u2-l4`

The orchestrator derives the other variables from each lesson ID:
- `course_id`: `model-context-protocol` (from lesson prefix)
- `unit_number`: extracted from the ID (u1 = 1, u2 = 2, etc.)
- `blueprint_file`: inferred from unit number + definition's pattern

**Table mode** (full control): User provides all variables per session as a table or structured list.

#### 3b.3: Create All Sessions

**Determine format:** Check if the workflow has a `stages/` directory (see Format Detection).

For each variable set:
1. Create the session directory (and `artifacts/` subdirectory if stages-v1 format)
2. Write `session.md` with `status: draft` - use hybrid format for stages-v1 (see New Session Format Reference), monolithic format otherwise
3. Do NOT prompt for run mode - all sessions are draft

After all sessions are created, display the batch summary:

```
Batch created: {N} sessions for {workflow name}

  [draft] {Session 1 name}
  [draft] {Session 2 name}
  [draft] {Session 3 name}
  ...

All sessions are draft. Use /craft:workflow ready {workflow-name} to mark them ready for execution.
```

**Done.** No execution, no follow-up prompts.

---

### Step 3c: Find Next Runnable Session (Shared Helper)

Shared logic used by `continue`, `next`, and `run-all` to pick the next session.

**Find the next session to run:**

1. Use **Glob** to find all `session.md` files for the specified workflow.
2. Read each session's frontmatter (with `limit: 10`) to get status.
3. Filter for sessions with `status: draft` or `status: ready` (both are runnable).
4. Sort: `ready` before `draft` at the same date, then by date prefix, then alphabetical.
5. Return the first match.

**Session priority:** `ready` sessions are picked before `draft` sessions. This means `/craft:workflow ready` is still useful for prioritizing a subset - but the system won't refuse to run a draft.

**Activate the session:**

Run `start-workflow-session.sh` to transition the session to `active`. The script handles validation (e.g., blocking if another session is already active).

---

### Step 3d: Run Next Session (`next`)

**Invocation:** `/craft:workflow next <workflow-name>`

No-prompt shortcut: finds the next runnable session (draft or ready), activates it, runs it to completion, then **stops**.

1. Use Step 3c to find the next runnable session for the specified workflow.
2. If none found: "No draft or ready sessions for {workflow-name}."
3. Count total remaining runnable sessions for context.
4. Show: "Activating session: {name} ({M} of {N} remaining)"
5. Activate via `start-workflow-session.sh`.
6. Execute per Step 4 (all stages, validation included).
7. On completion, show: "Session complete. {N-1} sessions remaining. Run `/craft:workflow next {name}` for the next one."
8. **Stop.** Do not auto-advance to the next session.

---

### Step 3e: Run All Sessions (`run-all`)

**Invocation:** `/craft:workflow run-all <workflow-name>`

Chains through all runnable sessions (draft or ready) in sequence. Only stops when no sessions remain or the user interrupts.

1. If an active session exists for this workflow, resume it first (same as `continue`).
2. Use Step 3c to count all runnable sessions. Add 1 if resuming an active session.
3. If none (no active, no runnable): "No sessions to run for {workflow-name}."
4. Show: "Running {N} sessions for {workflow-name} in sequence."
5. For each session:
   a. If not already active, activate via `start-workflow-session.sh`.
   b. Show: "Starting session {M}/{N}: {name}"
   c. Execute per Step 4 (all stages, validation included).
   d. On completion, run `complete-workflow-session.sh`, show validation.
   e. Use Step 3c to find next runnable session.
   f. If found, continue to next session.
   g. If none, done.
6. Final summary: "All {N} sessions complete for {workflow-name}."

**Interruption:** If the user stops mid-session, the active session stays active. Resume with `/craft:workflow continue` (single session) or `/craft:workflow run-all {name}` (finish active + chain remaining).

At manual gates within each session, the orchestrator pauses as normal. The sequential chaining only auto-advances *between* sessions, not within them.

**Enforced by script:** `start-workflow-session.sh` will exit 1 if another session in the same workflow is already active. The script is the gate - you cannot start the next session until the current one completes.
