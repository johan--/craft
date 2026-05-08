# Roadmap Mode Reference

Quick-sketch flow for capturing multiple cycles with story titles only - no sparks, no details. Fires when the user picks "Quick sketch (Roadmap)" at Step 1b, or loops back via Step R3 for additional cycles.

The orchestrator command (`commands/craft-cycle-design.md`) defines the routing - this reference contains the full mode flow.

---

## Roadmap Mode (Quick Sketch)

Entered when user selects "Quick sketch (Roadmap)" in Step 1b. Creates a lightweight cycle with just story titles — no sparks, no details.

### Step R1: Capture Story Titles

> "List out the stories for **[cycle name]**. Just titles — we'll flesh them out later."

Capture story titles conversationally. The user can list them all at once or one by one. When the list feels complete, confirm:

Include inferred type tags where possible. If there's enough context to classify a story (from the title and any brief description), tag it. If not, leave the type out — it will be set during Detailing Mode when the spark is captured.

Use **AskUserQuestion**:
```
question: "Here are the stories for [cycle name]:\n\n1. [Title 1] `ui`\n2. [Title 2] `technical`\n3. [Title 3]\n\nLook right? (Check the type tags — correct any that are wrong.)"
header: "Stories"
options:
  - label: "Yes, save these"
    description: "Create the cycle with these story titles"
  - label: "Add more"
    description: "I have more stories to add"
  - label: "Edit the list"
    description: "Change or remove some titles"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand what they want to change.

### Step R2: Create Cycle and Story Files

1. **Create cycle** using `create-cycle.sh`:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/create-cycle.sh "[cycle-slug]" "[Cycle Title]" "[Goal]"
```
   - **`cycle-slug`** = kebab-case slug for the directory (e.g., `auth-flow`). The script auto-numbers it (creates `3-auth-flow/`).
   - **`Cycle Title`** = human-readable name shown in status line and context (e.g., `"Auth Flow"`). Always provide this.

2. **Create story files** with the spark descriptions from the conversation. The orchestrator generated these sparks during the story breakdown — they MUST be written into the files, not discarded.

Write to `.craft/cycles/[cycle-dir]/stories/[N]-[slug].md`:
```markdown
---
name: [slug]
title: "[Story Title]"
type: [ui/technical/content — from confirmed tags, omit if unclassified]
status: planning
priority: medium
created: [date]
updated: [date]
cycle: [cycle-name]
story_number: [N]
chunks_total: 0
chunks_complete: 0
current_chunk: 0
---

# Story: [Story Title]

## Spark
[Write the spark description that was discussed and approved during the story breakdown. This content already exists in the conversation — re-read it and transcribe it here. Never use a placeholder.]

## Dependencies
**Blocked by:** [from discussion and file-overlap check — leave empty if not yet determined, write "none" only if explicitly confirmed]
**Blocks:** [from discussion — leave empty if not yet determined]

## Chunks
<!-- Added via plan-chunks -->
```

3. **Clear PLANNING_CYCLE** — the cycle shell is done:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE ""
```

### Step R3: Roadmap Loop

> "**[Cycle Name]** created with [N] story titles.
>
> Want to sketch another cycle?"

Use **AskUserQuestion**:
```
question: "Cycle saved. Create another?"
header: "Next"
options:
  - label: "Yes, another cycle"
    description: "Sketch the next cycle in the roadmap"
  - label: "No, I'm done"
    description: "Show roadmap summary and exit"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their intent.

**If "Yes, another cycle":**
- Go back to **Step 1: Name & Goal** (start a fresh cycle)
- PLANNING_CYCLE is already cleared — the new cycle gets its own

**If "No, I'm done":**
- Show summary of all cycles created:

> "**Roadmap Summary**
>
> | Cycle | Stories | Status |
> |-------|---------|--------|
> | [Cycle 1] | [N] stories | planning |
> | [Cycle 2] | [M] stories | planning |
>
> Use `/craft` to detail or activate these cycles when ready."

---

