# Workflow: Validate

Reference for Step 5 - session validation after all stages complete, and Step 6 - auto mode execution.

### Step 5: Session Validation (MANDATORY)

**This step ALWAYS runs after the last stage completes. It is not optional. Do not present a "session complete" message to the user before validation runs. The validation report IS the completion message.**

When all stages are complete (or user requests early validation):

#### 5.1: Checklist Verification

Read the session.md. For each stage:
- Are all checklist items `[x]`?
- Is the stage tagged `[complete]` or `[skipped]`?

#### 5.2: Artifact Verification

**Artifact verification by format:**
- **stages-v1:** For each stage file in `stages/`, read `produces:` from its frontmatter. Substitute session variables. Check that the artifact path exists on disk using **Glob**. Also verify that `{session_dir}/artifacts/` contains output files for completed agent stages.
- **monolithic:** For stages with `produces:` in the definition, substitute session variables and check that the artifacts exist on disk using **Glob**.

#### 5.3: Skipped Stage Check

Flag any stages tagged `[skipped]`.

#### 5.4: Run Completion Script (MANDATORY - USE SCRIPT)

**You MUST run the completion script.** Do not write the Validation section manually. The script handles validation, writes the section, updates status, and prints the report.

```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/complete-workflow-session.sh "{session-dir}"
```

Example:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/complete-workflow-session.sh ".craft/workflows/write-lesson/sessions/2026-04-10-mcp-u1-l3"
```

The script:
1. Counts stages by status (complete, skipped, pending, active)
2. Counts checked vs unchecked checklist items
3. Identifies unchecked items on completed stages, skipped stages, still-active stages
4. Writes `## Validation` section to session.md with `### Issues` as `- [ ]` items
5. Sets `status: complete` and `completed:` date in frontmatter
6. **Prints the validation report to stdout** - this IS the session completion message

The session is marked complete regardless of validation issues. Issues are tracked as `- [ ]` items in the Validation section, not as blockers. The user circles back when ready.

**After the script runs**, display its output to the user. If running in batch mode (multiple ready sessions), continue to the next ready session.

Use **AskUserQuestion**:
```
question: "Session complete. What next?"
header: "Next"
options:
  - label: "Start another session"
    description: "Run this workflow again with new variables"
  - label: "Done"
    description: "Back to what I was doing"
```

---

### Step 6: Auto Mode Execution

When mode is `auto`, the orchestrator runs through stages without interactive prompts:

1. For each stage in sequence:
   - `agent` stages: run and auto-advance (no confirmation between stages)
   - `inline` stages: execute and auto-advance (orchestrator acts directly)
   - `command` stages: invoke and auto-advance (breadcrumb handles continuation)
   - `manual` stages: **always pause** (human must do the work)
2. **Progress is tracked via Task tools.** The terminal UI updates automatically as tasks move from pending -> in_progress -> completed. No custom text rendering needed - the Task UI is the progress display.
3. Between stages, run `complete-workflow-stage.sh` (session.md) AND `TaskUpdate` (live UI). Both are mandatory.
4. At manual gates, the stage description is visible alongside the task checklist. Wait for input.
5. **After all stages complete, run validation (Step 5) automatically. This is mandatory - do not skip. The validation report is the session completion message, not a separate optional step.**
