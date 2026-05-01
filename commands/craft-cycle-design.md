---
name: craft:cycle-design
description: "Design a cycle — create new cycles with planned stories, detail existing planning cycles, or quick-sketch a roadmap."
---

# Cycle Design

Create a new cycle or detail an existing one — this IS the planning phase. Stories come out fully fleshed with implementation details.

## Philosophy

**Plan first. Files last. Align before you chunk.**

The entire cycle should reach **95% alignment** before ANY story gets planned into chunks.

**95% alignment means: "I have asked the user every question the codebase raised that only they can answer."** It's about capturing the user's intent - not about whether the solution approach is right. The orchestrator investigates the codebase, surfaces conflicts, adjacencies, and assumptions, and confirms the user's product decisions through dialogue. See `commands/references/alignment-check.md` for the full pattern.

1. Discuss everything in conversation
2. Lock decisions as you go
3. Run the alignment check per-story (codebase investigation + product questions)
4. Confirm the whole plan
5. THEN plan chunks (with full alignment)

No half-baked stories. No "I'll figure it out during implementation." Align thoroughly, execute confidently.

## Skills — When to Invoke (and When NOT To)

**Invoke skills using the Skill tool** — but only at the right moments:

| Phase | Skill | Invoke When |
|-------|-------|-------------|
| Per-story content | `content-spark` | After spark captured, before creative-spark. Surfaces content assumptions. |
| Per-story creative | `creative-spark` | When user chooses "Let's get creative" for a story in Step 3. Includes visual direction for UI stories. |
| Visual cohesion | `design-vibe` | After all stories captured (Step 7). Reviews cohesion across UI stories, unifies tokens. |
| Locking decisions | `lock-decision` | When user confirms a decision. Quick, focused. |
| Chunk breakdown | `plan-chunks` | When ready to break a story into implementation steps. |

**DON'T invoke skills:**
- At the cycle brainstorm level (Step 2) — that's decomposition, not creative exploration
- `design-vibe` per-story — visual direction is handled by `creative-spark`
- Every single turn (conversation fatigue)
- During technical discussion (just talk normally)
- When user is answering a question (let them finish)
- When refining details (stay in conversation)

**Skill flow for a typical cycle:**
1. Step 3: `content-spark` per story → surface content assumptions
2. Step 3: `creative-spark` per story → explore options (includes visual direction for UI)
3. Normal conversation → discuss trade-offs, pick direction
4. `lock-decision` → capture each confirmed decision (quick)
5. Step 7: `design-vibe` → review visual cohesion across all UI stories (once per cycle)
6. `plan-chunks` → break stories into implementation (once per story)
7. Normal conversation → refine chunks, confirm

---

## Your Role: Creative Pairing Partner

**Applies during story creation and brainstorming (Steps 2-3).** Once stories are confirmed (Step 5+) or when entering Detailing Mode with pre-existing sparks, switch to a review-and-finalize posture - present what exists, don't suggest restructuring unless the user asks.

During cycle planning, you're not a transcriber — you're a **creative thinking partner**. Be proactive AND imaginative.

### Inspire & Suggest
- "What if instead of a modal, we did an inline expansion? Feels smoother."
- "Stripe does this cool thing where the button morphs into a success state."
- "This is a great opportunity for a micro-animation — task completing could feel satisfying."
- "What if we flipped this? Instead of users pulling data, it pushes to them."
- "Have you considered doing X? It would open up Y later."

### Offer Creative Alternatives
When user proposes something, don't just accept — riff on it:
- "That works, but here's a twist: what if we also..."
- "I like that. Another angle could be..."
- "Yes, and — we could take it further by..."

### Reference Inspiration
Pull from the user's inspiration library AND your knowledge:
- "Linear does something similar but with a keyboard-first approach."
- "Based on your Stripe inspiration, they'd probably use generous whitespace here."
- "Duolingo makes this moment feel like a celebration — want that energy?"

### Find Delight Opportunities
Actively look for moments to add magic:
- "This empty state could have personality — a friendly illustration?"
- "First-time completion is an emotional moment. Confetti? Sound? Badge?"
- "The loading state could show progress, not just a spinner."
- "Error messages could have warmth: 'Oops, that didn't work. Here's what to try.'"

### Think Beyond the Obvious
Challenge the framing, not just the details:
- "You're thinking list view — what if it was spatial? A canvas?"
- "Everyone does tabs here. What if we used progressive disclosure instead?"
- "This could be a feature... or it could be the core differentiator."

---

### Push Back
- "Are you sure that's one story? Feels like two separate concerns."
- "This is ambitious. What would an MVP version look like?"
- "That's vague — what specifically triggers this behavior?"

### Ask Probing Questions
- "What happens if the user cancels mid-flow?"
- "How does this behave on mobile?"
- "What's the error state if the API fails?"
- "Who's the primary user for this?"

### Catch Gaps
- "You haven't mentioned loading states."
- "What about empty states? First-time users?"
- "Authentication — is the user logged in here?"
- "Accessibility — keyboard users?"

### Suggest Best Practices
- "Linear handles this with X — want to borrow that pattern?"
- "Standard approach here would be Y. Does that fit?"
- "Based on your inspiration site, they do Z."

### Connect Dependencies
- "This assumes Story 1's data layer is done, right?"
- "These two stories touch the same component — order matters."
- "This chunks spans concerns — maybe split at the API boundary?"

### Challenge Scope
- "5 stories with 4 chunks each = 20 chunks. That's a big cycle."
- "Want to split this into 'foundation' and 'polish' cycles?"
- "What's the minimum to call this cycle done?"

**Your goal:** By the end of planning, the user should feel like you caught things they would have missed.

---

## Flow

### Handling Custom Text Responses

Throughout this flow, users can always select "Other" to provide custom text. When they do:

1. **Don't assume intent** — Custom text can be ambiguous
2. **Ask a clarifying AskUserQuestion** — Present options based on your interpretation
3. **Confirm before acting** — Never make changes based on unclear input

Example:
> User selects "Other" and types: "Actually the second one feels off"

Use **AskUserQuestion**:
```
question: "What would you like to change about Story 2?"
header: "Clarify"
options:
  - label: "Revise the spark"
    description: "Rewrite what the story is about"
  - label: "Remove it"
    description: "Drop this story from the cycle"
  - label: "Merge with another"
    description: "Combine with a different story"
```

This ensures nothing gets lost in translation.

---

### Step 1: Name & Goal

> "What's this cycle about?"
> [User provides name/theme]

> "What's the goal? What will be true when this cycle is done?"
> [User describes goal]

**Once the cycle name is confirmed, immediately create the cycle directory and set the planning state:**

```bash
# Create cycle directory with proper auto-numbering, cycle.yaml, and .state
cycle_dir=$(${CLAUDE_PLUGIN_ROOT}/hooks/scripts/create-cycle.sh "[cycle-slug]" "[Cycle Title]" "[Goal]")

# Set planning state
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE "$(basename $cycle_dir)"
```

- **`cycle-slug`** = kebab-case slug (e.g., `auth-flow`). The script auto-numbers it (creates `11-auth-flow/` if cycles 1-10 exist).
- **`Cycle Title`** = human-readable name (e.g., `"Auth Flow"`). Always provide this.
- The script creates `cycle.yaml` and `.state` immediately — no orphaned directories if the session interrupts later.
- Store the returned `cycle_dir` path — use it for all story file writes in Step 3e.

This ensures all subsequent prompts show `[Craft: PLANNING cycle 'X' — stories go to .craft/cycles/X/stories/]` so context is never lost.

### Step 1b: Choose Planning Depth

**Before asking:** Consider the goal from Step 1. If it sounds like it spans multiple concerns, would need 8+ stories, or the user described something ambitious/multi-phase — **recommend "Quick sketch (Roadmap)"** and explain why:

> "That sounds like it could span multiple cycles. I'd recommend starting with a quick roadmap — sketch out the cycles and story titles, then come back to detail each one."

If the goal sounds focused and single-cycle-sized, present both options neutrally.

Use **AskUserQuestion**:
```
question: "How do you want to plan this cycle?"
header: "Depth"
options:
  - label: "Add stories now"
    description: "Brainstorm and capture sparks for each story (full planning)"
  - label: "Quick sketch (Roadmap)"
    description: "Just list story titles — detail them later"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their preference.

**If "Add stories now":** Continue to Step 2 (existing flow, unchanged).

**If "Quick sketch (Roadmap)":** Jump to **Roadmap Mode** below.

---

### Step 2: Story Brainstorm

> "Let's map out the stories for this cycle.
>
> What needs to happen to achieve: **[goal]**?"

Help the user decompose the cycle into stories through conversation:
- What are the pieces?
- What's the user journey?
- What are the dependencies?

**Note:** Don't automatically invoke `creative-spark` here. The user usually knows what stories they need — they're decomposing a known feature. Creative exploration happens per-story in Step 3.

**Only invoke `creative-spark`** if the user is genuinely unsure what stories the cycle needs (e.g., "I don't know where to start" or "What would you suggest?").

Present initial story list with inferred type tags (`ui`, `technical`, or `content`). Infer the type from conversational context — if the story involves visual design, layout, or animation it's `ui`; if it's API routes, data, or infrastructure it's `technical`; if it's copy, tone, or onboarding flow it's `content`.

**Scope check (before presenting):** Before showing the story list, evaluate whether the story count matches the scope complexity. Count the concrete deliverables in the cycle goal and discussion — interactive features, distinct pages/views, API endpoints, data models, content surfaces. Apply these heuristics:

- If deliverables-per-story ratio exceeds ~3, the stories are probably too coarse
- If any single story covers more than one distinct concern (e.g., "build layout AND wire interactions AND add animations"), it should likely split
- If the project has existing completed cycles, compare story count against similar-scope cycles in `.craft/cycles/`

If the scope looks thin, include a **Scope check** note inline with the story list. If the count looks reasonable, present the list without commentary.

**When the check fires:**

> "Based on our discussion, I'm thinking these stories:
>
> 1. **[Story idea 1]** `ui` — [one line]
> 2. **[Story idea 2]** `ui` — [one line]
> 3. **[Story idea 3]** `ui` — [one line]
>
> **Scope check:** This cycle covers [N deliverables] but only has [M] stories. [Specific concern — e.g., "Story 2 alone covers 5 interactive commands with distinct animations - that could be 8+ chunks. Consider splitting into separate stories per command group."] You can proceed as-is or adjust.
>
> Does this capture the scope? (Check the type tags — correct any that are wrong.)"

**When the check doesn't fire:**

> "Based on our discussion, I'm thinking these stories:
>
> 1. **[Story idea 1]** `ui` — [one line]
> 2. **[Story idea 2]** `technical` — [one line]
> 3. **[Story idea 3]** `ui` — [one line]
>
> Does this capture the scope? (Check the type tags — correct any that are wrong.)"

Use **AskUserQuestion**:
```
question: "Does this capture the scope?"
header: "Stories"
options:
  - label: "Save these sparks"
    description: "The descriptions above are the sparks — write all story files now"
  - label: "Flesh out individually"
    description: "Go through each story to explore or refine the spark"
  - label: "Add another story"
    description: "I have more stories to include"
  - label: "Remove/combine some"
    description: "Some of these should be merged or dropped"
```

**If user selects "Other" or provides custom text:** Ask a clarifying AskUserQuestion before proceeding. Don't assume intent — confirm what they want to change.

**Important:** Don't proceed until user confirms the story list is complete.

**If "Save these sparks":** Jump to **Step 3-Fast** below.

**If "Flesh out individually":** Continue to Step 3 (per-story flow).

### Step 3-Fast: Batch Save Stories

The brainstorm already produced clear sparks. Write all story files at once using the descriptions from Step 2.

For each story in the confirmed list:
1. Use the story description from Step 2 as the spark
2. Use the confirmed type tag from Step 2 (`ui`, `technical`, or `content`) — write it into the `type` frontmatter field
3. Extract dependencies from the brainstorm discussion (e.g., "parser feeds editors" → Story 3 blocked by Story 1). If dependencies were discussed, capture them accurately. If a specific story's dependencies weren't discussed, leave the Dependencies section empty for the user to fill later — do NOT default to "none".
4. Write story file to `.craft/cycles/[cycle-name]/stories/[N]-[slug].md` with `status: planning`
5. Use the story template format from Step 3e

After writing all files, skip to **Step 5: Cycle Review**.

### Step 3: Capture Each Story (Spark Level Only)

**Cycle planning is high-level.** Capture the spark for each story — detailed planning happens later via `plan-chunks`.

**CRITICAL: Questions vs Answers**

Before capturing ANYTHING, distinguish:
- **Question from user:** "What do you recommend?" / "What should this do?" / "Any ideas?" → **ANSWER THE QUESTION FIRST.** Provide recommendations/options. Do NOT capture or lock anything. Wait for user to explicitly confirm.
- **Answer from user:** "Let's do X" / "The spark is Y" / "It should handle Z" → This is input to capture.

**Never lock or save based on a question.** Questions require answers, not actions.

For EACH story in the list:

> "Let's capture **Story 1: [Name]**"

**3a. Choose Your Path (Per Story)**

**If the story has `type: ui`**, prepend a recommendation:

> "This is a visual story — I'd recommend exploring directions before locking in the spark."

Use **AskUserQuestion**:
```
question: "How formed is the idea for [Story Name]?"
header: "Approach"
options:
  - label: "Let's get creative (recommended)"
    description: "Explore visual options, riff on the design together"
  - label: "I know what I want"
    description: "Capture the spark directly"
```

**If the story has `type: technical` or `type: content`**, present the options neutrally (no recommendation, no "(recommended)" suffix):

Use **AskUserQuestion**:
```
question: "How formed is the idea for [Story Name]?"
header: "Approach"
options:
  - label: "Let's get creative"
    description: "Explore options, riff on the design together"
  - label: "I know what I want"
    description: "Capture the spark directly"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their preferred approach.

**If "I know what I want":**
- Proceed directly to capturing the spark

**For either path, run content-spark first** (if the story spark has been captured).

⛔ **DO NOT analyze content assumptions directly. DO NOT invoke content-spark via the Skill tool (chain break - no return-to-caller).** Instead, Read and execute the logic inline:

```
Read "${CLAUDE_PLUGIN_ROOT}/commands/references/content-spark-inline.md"
Execute the phases described in that file against the current story.
```

**After content-spark logic completes:**
- If "I know what I want" was selected, continue to spark capture (Step 3b).
- If "Let's get creative" was selected, immediately continue to creative-spark below. Do NOT stop or ask the user again - they already chose the creative path.

**Running creative-spark inline:**

⛔ **DO NOT generate creative options from scratch. DO NOT invoke creative-spark via the Skill tool (chain break).** Instead, Read and execute the logic inline:

```
Read "${CLAUDE_PLUGIN_ROOT}/commands/references/creative-spark-inline.md"
Execute the steps described in that file against the current story.
```

The creative-spark reference file reads its own sub-references (output-formats.md, cross-domain-patterns.md, animation-integration.md) from `${CLAUDE_PLUGIN_ROOT}/skills/creative-spark/references/`. After creative-spark logic completes, capture the user's chosen direction as the spark.

**3b. Spark (What & Why)**
> "What's the spark? What problem does it solve?"

Capture 2-3 sentences describing the essence. Be an active partner:
- "Who specifically benefits from this?"
- "What's the 'wow' moment?"
- "Is this a must-have or nice-to-have?"

**3c. Rough Acceptance (Optional)**

If the user wants to capture high-level acceptance criteria:
- User can [action]
- [Behavior] when [condition]

**Note:** Detailed acceptance criteria come during `plan-chunks`, not here.

**3d. Dependencies**

> "Does this depend on other stories? Does anything depend on this?"

**Before writing dependencies, check for file-level overlap with sibling stories already in the cycle.** Read each sibling's spark and do a lightweight scan: what files will this story likely touch? What files will siblings likely touch? If two stories will modify the same files, they MUST declare a dependency - even if they touch different data fields within those files. Shared files means shared risk.

Present any detected overlap to the user:
> "This story and [sibling] both touch [files]. One should depend on the other so plan-chunks orders them correctly. Which goes first?"

**If no sibling overlap detected:** Proceed normally - dependencies may still exist for other reasons.

**If dependencies weren't discussed and no overlap detected:** Leave the Dependencies section empty for the user to fill later - do NOT default to "none". An empty section means "not yet determined." `Blocked by: none` means "I checked and there are no dependencies."

Capture the dependency chain for story ordering.

**3e. Save Story**

Write story file to `.craft/cycles/[cycle-name]/stories/[N]-[slug].md` with `status: planning`.

```markdown
---
name: [slug]
title: "[Title]"
type: [ui/technical/content]
status: planning
priority: [high/medium/low]
created: [date]
updated: [date]
cycle: [cycle-name]
story_number: [N]
alignment: pending
chunks_total: 0
chunks_complete: 0
current_chunk: 0
---

# Story: [Title]

## Spark
[2-3 sentences from discussion]

## Dependencies
**Blocked by:** [stories this depends on]
**Blocks:** [stories that depend on this]

## Content Direction
<!-- Captured during content-spark - assumptions surfaced and resolved -->

## Acceptance
[Rough criteria if captured, otherwise empty for plan-chunks to fill]

## Chunks
<!-- Detailed chunks added via plan-chunks -->
```

**Note:** Stories are saved with `status: planning`. They become `status: ready` after `plan-chunks` is run.

### Step 4: Repeat for All Stories

Go through Step 3 for each story. Each story is saved immediately with `status: planning`.

> "Stories captured: 2/5 ✓
>
> Ready for **Story 3: [Name]**?"

**If context compacts:** Read existing story files from `.craft/cycles/[cycle-name]/stories/`, resume with next unwritten story.

### Step 5: Cycle Review

All stories are now saved. Review the cycle as a whole:

> "**Cycle: [Name]** — Story List
>
> **Goal:** [Goal]
>
> ---
>
> **Story 1: [Name]** — [spark summary]
> **Story 2: [Name]** — [spark summary]
> **Story 3: [Name]** — [spark summary]
>
> **Dependencies:**
> - Story 2 depends on Story 1
> - Story 3 can run parallel
>
> ---
>
> **Total:** [N] stories (all need plan-chunks before implementation)
>
> Is this the right scope and order?"

Use **AskUserQuestion**:
```
question: "Is this the right scope and order?"
header: "Review"
options:
  - label: "Yes, finalize the cycle"
    description: "Lock in the story list — you can still run creative-spark and plan-chunks on each story"
  - label: "Add another story"
    description: "I have more to include"
  - label: "Reorder stories"
    description: "Change the implementation order"
  - label: "Revisit a spark"
    description: "Refine one of the story descriptions"
```

**If user selects "Other" or provides custom text:** Ask a clarifying AskUserQuestion to understand specifically what they want to change before making modifications.

**Note:** Stories have `status: planning`. Run `plan-chunks` on each before starting implementation.

### Step 6: Finalize Cycle

Stories are already saved. Update the cycle metadata created in Step 1 with final details from discussion.

**6a. Cycle structure already exists (created by `create-cycle.sh` in Step 1):**
```
.craft/cycles/[N]-[name]/
├── cycle.yaml          ✓ created in Step 1 — update now with final goals/notes
├── .state              ✓ created in Step 1 — no changes needed
└── stories/            ← Already populated
    ├── 1-[story].md    ✓ saved in Step 3
    ├── 2-[story].md    ✓ saved in Step 3
    └── ...
```

**Note:** Learnings are project-wide at `.craft/.learnings.yaml`, not per-cycle.

**6b. Update cycle.yaml** — use targeted edits on the existing file (created by `create-cycle.sh` in Step 1). **NEVER rewrite cycle.yaml from scratch** — that causes YAML formatting bugs (null goals, unquoted titles).

Use `sed` for simple field updates:
```bash
cycle_yaml="[cycle_dir]/cycle.yaml"
sed -i.bak "s/^status:.*/status: ready/" "$cycle_yaml"
sed -i.bak "s/^updated:.*/updated: $(date +%Y-%m-%d)/" "$cycle_yaml"
sed -i.bak "s/^focus:.*/focus: [Primary focus area]/" "$cycle_yaml"
rm -f "$cycle_yaml.bak"
```

For goals and notes, use the Edit tool to replace the existing `goals:` and `notes:` sections.

**Goals are outcomes, not story summaries.** Each goal should be a state that will be TRUE when the cycle completes - something you could verify. Good: "Failures feed back into learnings pipeline instead of being discarded." Bad: "Implement failure tracking story." If you find yourself restating story sparks as goals, stop - that's the wrong level.

**Before writing goals, check what exists:** Read the current `goals:` value from cycle.yaml.

- **If goals were discussed this session** (full creation path, Step 1): Write the outcome-oriented goals from that conversation.
- **If goals were NOT discussed** (Detailing Mode, pre-planned stories): Ask the user with AskUserQuestion: "What outcomes should this cycle achieve? (Or I can leave goals as TBD for now.)" Then write their answer, or leave the existing TBD value untouched.
- **Never auto-fill goals by summarizing story sparks.** That produces generic descriptions that add no value to plan-chunks agents. TBD is better than watered-down spark rewrites.

```yaml
goals:
  - [Outcome 1 - what will be true when done]
  - [Outcome 2 - what will be true when done]

notes: |
  [All locked decisions from planning]
```

**IMPORTANT:** Every goal must be a non-empty string. Never leave a trailing `- ` with no value — Craftsman's Zod parser will reject it. If goals are unknown, keep the existing `- TBD` value rather than inventing content.

**Note:** No stories array in cycle.yaml. Stories are discovered by scanning the `stories/` directory.

**6d. Stories already created in Step 3 with `status: planning`.**

Story files look like:

```markdown
---
name: [slug]
title: "[Full title]"
type: [ui/technical/content]
status: planning
priority: [high/medium/low]
created: [date]
cycle: [cycle-name]
story_number: [N]
alignment: pending
chunks_total: 0
chunks_complete: 0
current_chunk: 0
---

# Story: [Title]

## Spark
[2-3 sentence essence from discussion]

## Dependencies
**Blocked by:** [list or "none"]
**Blocks:** [list or "none"]

## Content Direction
<!-- Captured during content-spark - assumptions surfaced and resolved -->

## Visual Direction
<!-- For type: ui stories only - captured during creative-spark -->
**Vibe:** [Name from creative-spark, e.g., "Friendly Energy"]
**Feel:** [2-3 words, e.g., "Clean, warm, approachable"]
**Inspiration:** [Reference sites/patterns]
**Key tokens:** [Token names this story will use]
**Motion:** [Animation approach from creative-spark]

<!-- Leave empty for non-UI stories -->

## Wireframe
<!-- For type: ui stories - capture the chosen layout as ASCII art -->
<!-- This preserves the visual context for plan-chunks -->

```
[Paste the chosen wireframe option here]
```

<!-- Leave empty for non-UI stories -->

## Acceptance
<!-- Detailed criteria added via plan-chunks -->

## Chunks
<!-- Detailed chunks added via plan-chunks -->

## Notes
[Any additional context, open questions, references]
```

### Step 7: Visual Cohesion Review (Optional)

Check if the cycle has UI stories that would benefit from a cohesion review:

Use **Grep** with pattern `^type: ui`, path `.craft/cycles/[cycle]/stories/`, glob `*.md`, output_mode `files_with_matches` → count → `ui_stories`.

**If ui_stories > 1:**

> "This cycle has [N] stories with visual direction. Want to review them for cohesion before implementation?"

Use **AskUserQuestion**:
```
question: "Review visual cohesion across stories?"
header: "Design"
options:
  - label: "Yes, let's review"
    description: "Ensure consistent visual language across all UI stories"
  - label: "Skip for now"
    description: "Move forward, review later if needed"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their intent.

**If "Yes, let's review":**

⛔ **DO NOT review visual cohesion directly. You MUST invoke the skill:**

```
Skill tool:
  skill: "craft:design-vibe"
  args: "[cycle directory path] — Cycle '[cycle name]' has [N] UI stories with visual direction.
  CYCLE: [cycle-dir-name]
  STORY_VIBES: [story1: vibe1, story2: vibe2, ...]
  TOKEN_FILES: [.craft/design/tokens.yaml]"
```

Include the cycle path, which stories have visual direction, and their vibe names. This gives design-vibe targeted context for the cohesion review.

This hands off to `design-vibe` which reviews visual direction across all stories, identifies inconsistencies, and proposes unified design tokens. Do NOT replicate visual cohesion analysis inline.

**If "Skip for now" or no UI stories:**
- Continue to Step 8

### Step 8: Confirm Cycle

> "**Cycle: [Name]** created!
>
> - [N] stories captured (all `status: planning`)
> - Stories need `plan-chunks` before implementation
>
> What's next?"

Use **AskUserQuestion** (options vary based on story count):

**If N > 1 (multiple stories):**
```
question: "What's next?"
header: "Next step"
options:
  - label: "Plan all [N] stories"
    description: "Reads dependency graph, plans chains sequentially, parallelizes independent stories"
  - label: "Plan a specific story"
    description: "Run plan-chunks on one story interactively"
  - label: "Review visual cohesion"
    description: "Run design-vibe to ensure consistent visual language"
  - label: "Keep in planning"
    description: "I'll come back to plan stories later"
```

**If N = 1 (single story):**
```
question: "What's next?"
header: "Next step"
options:
  - label: "Explore a story creatively"
    description: "Run creative-spark on a story to explore design options"
  - label: "Plan a story now"
    description: "Run plan-chunks on a story to make it implementation-ready"
  - label: "Review visual cohesion"
    description: "Run design-vibe to ensure consistent visual language"
  - label: "Keep in planning"
    description: "I'll come back to plan stories later"
```

**If user selects "Other" or provides custom text:** Ask a clarifying AskUserQuestion to understand their intent before proceeding.

**Note:** Cycle stays in `planning` status until stories are planned and you're ready to implement.

**If user wants to explore a story creatively:**

⛔ **DO NOT generate creative options directly. You MUST invoke the skill:**

```
Skill tool:
  skill: "craft:creative-spark"
  args: "[story name] — [context from story file]
  STORY: [story-name]
  CYCLE: [cycle-dir-name]
  CYCLE_GOAL: [cycle goal]"
```

This hands off to `creative-spark` which generates options, wireframes, and visual direction. After the user picks a direction, update the story file with the chosen spark and visual direction.

**If user wants to review visual cohesion:**

⛔ **DO NOT review visual cohesion directly. You MUST invoke the skill:**

```
Skill tool:
  skill: "craft:design-vibe"
  args: "[cycle directory path] — Cycle '[cycle name]' has [N] UI stories.
  CYCLE: [cycle-dir-name]
  STORY_VIBES: [story1: vibe1, story2: vibe2, ...]
  TOKEN_FILES: [.craft/design/tokens.yaml]"
```

This hands off to `design-vibe` which reviews visual cohesion. Do NOT replicate this work inline.

**Before planning any story**, check `alignment` in frontmatter. If `alignment: pending`, run the alignment check first. Read `commands/references/alignment-check.md` and follow the loop for each story before invoking plan-chunks. The alignment check surfaces product questions from codebase investigation - it must complete before chunking begins.

**If user wants to plan all stories:**

⛔ **DO NOT plan chunks directly. You MUST invoke the skill:**

```
Skill tool:
  skill: "craft:plan-chunks"
  args: "DIRECTION_CONFIRMED: true
  MODE: batch
  CYCLE: [cycle-dir-name]
  CYCLE_GOAL: [cycle goal]"
```

This hands off to `plan-chunks` in batch mode, which reads the dependency graph from story files, plans dependency chains sequentially (level by level), and parallelizes independent stories within each level. The skill handles agent orchestration, batch triage, per-story approval, and story file writing. Do NOT replicate any of this inline.

**If user wants to plan a specific story:**

⛔ **DO NOT plan chunks or break down implementation directly. You MUST invoke the skill:**

```
Skill tool:
  skill: "craft:plan-chunks"
  args: "[story file path] — Part of cycle '[cycle name]'.
  DIRECTION_CONFIRMED: true
  STORY: [story-name]
  CYCLE: [cycle-dir-name]
  CYCLE_GOAL: [cycle goal]
  SIBLINGS: [story1, story2, story3]
  DECISIONS: [key decisions from planning discussion]"
```

Include the story path, cycle context, sibling stories, and any relevant discussion context. This gives plan-chunks the full cycle picture for coordination.

This hands off to `plan-chunks` which produces detailed chunk-by-chunk implementation plans. Do NOT replicate planning inline. Story becomes `status: ready` when chunks are complete.

**After plan-chunks returns:** Check if all stories in the cycle are now `status: ready`. If so, clear PLANNING_CYCLE — the cycle is implementation-ready:

Use **Glob** with pattern `.craft/cycles/[cycle]/stories/*.md` → count → `stories_total`.

Use **Grep** with pattern `^status: ready`, path `.craft/cycles/[cycle]/stories/`, glob `*.md`, output_mode `files_with_matches` → count → `stories_ready`.

If `stories_total > 0` and `stories_total == stories_ready`:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE ""
```

**If kept for later:**
- Clear PLANNING_CYCLE:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE ""
```
- Cycle stays `status: planning` until activated

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

## Detailing Mode (Flesh Out Planning Cycles)

Entered when `/craft` routes here with an existing cycle directory name as arg. This mode adds sparks and detail to title-only stories created in Roadmap Mode.

### Pre-check

If args are provided:
1. Check if `.craft/cycles/[arg]/` exists
2. Check if `cycle.yaml` has `status: planning`
3. If valid: set PLANNING_CYCLE and proceed to Step D1
4. If invalid: show error and offer cycle picker

Use **Read** to read `.craft/cycles/[arg]/cycle.yaml`. Parse `status:` value.

If the file exists and `status == "planning"`:
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE "[arg]"
```

If the file doesn't exist or status is not `planning` → show error and offer cycle picker.

### Step D1: Show Current State

Read all stories in the cycle. Check which have sparks, type tags, and creative tool output:

```
# Check story state
Glob ".craft/cycles/[cycle]/stories/*.md" → story_files

stories = []
for each story_file in story_files:
  Read story_file (limit: 50) → parse frontmatter + section headings
  - title: from frontmatter
  - has_spark: "## Spark" section has non-empty, non-comment content
  - type: from frontmatter `type` field (may be missing)
  - has_content_direction: "## Content Direction" section has non-comment content
  - has_visual_direction: "## Visual Direction" section has non-comment content
  stories.append(title, has_spark, type, has_content_direction, has_visual_direction)
```

**Batch type inference for stories with sparks but no type:**

If any stories have sparks but missing `type` field, infer the type from the spark content and present for confirmation:

> "I've inferred types for stories with existing sparks:
>
> | # | Story | Type (inferred) |
> |---|-------|-----------------|
> | 1 | [Title] | `ui` |
> | 2 | [Title] | `technical` |
>
> Correct? (Say which to change, or confirm to update the files.)"

On confirmation, update each story's frontmatter to add the `type` field.

**Present the full status:**

> "**Cycle: [Name]** — Detailing Mode
>
> | # | Story | Spark | Type | Content | Visual |
> |---|-------|-------|------|---------|--------|
> | 1 | [Title] | ✓ | `ui` | — | — |
> | 2 | [Title] | — | — | — | — |
> | 3 | [Title] | ✓ | `technical` | ✓ | n/a |
>
> [N] stories need sparks. [M] stories are missing creative tool output."

The "Visual" column shows `n/a` for non-ui stories, `—` for ui stories missing Visual Direction, and `✓` for ui stories with it. The "Content" column shows `—` for any story missing Content Direction and `✓` for those with it.

Use **AskUserQuestion**:
```
question: "How do you want to detail these stories?"
header: "Approach"
options:
  - label: "Go through all stories"
    description: "Capture sparks for each story in order"
  - label: "Pick specific stories"
    description: "Choose which stories to detail now"
  - label: "Add more stories first"
    description: "Add new story titles before detailing"
  - label: "Rearrange/rename"
    description: "Reorder or rename existing stories"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion to understand their intent.

### Step D2: Capture Sparks

For each story that needs a spark, reuse the existing **Step 3** flow (Capture Each Story):

- **3a. Choose Your Path** — "Let's get creative" or "I know what I want" (with recommendation for `type: ui` stories)
- **3b. Spark** — Capture the essence
- **3c. Rough Acceptance** — Optional
- **3d. Dependencies** — What depends on what
- **3e. Save Story** — Update the existing story file with spark content (including `type` in frontmatter)

Stories that already have sparks are skipped unless user explicitly asks to revisit.

### Step D2b: Creative Tool Checks (After Each Story's Spark Is Captured)

After writing/updating a story's spark (whether new or revised), run two independent checks. These also apply to stories that already had sparks but are missing creative tool output.

**Check 1: Content-spark** — runs for ANY story type.

Condition: The story has no `## Content Direction` content (empty or comment-only).

```
question: "[Story Name] has unsurfaced content assumptions. Run content-spark to surface them before planning?"
header: "Content Check"
options:
  - label: "Yes, run content-spark"
    description: "Surface content assumptions before planning"
  - label: "Skip"
    description: "Move on without content-spark"
  - label: "Skip for all remaining"
    description: "Don't prompt for content-spark on remaining stories"
```

If "Yes": Read and execute `${CLAUDE_PLUGIN_ROOT}/commands/references/content-spark-inline.md` inline against this story. After it completes, continue to Check 2.

**Check 2: Creative-spark** - runs for `type: ui` stories only.

Condition: The story has `type: ui` AND no `## Visual Direction` content (empty or comment-only).

```
question: "[Story Name] is a visual story with no creative exploration yet. Run creative-spark to explore directions?"
header: "Creative Check"
options:
  - label: "Yes, explore directions"
    description: "Run creative-spark to generate visual options"
  - label: "Skip"
    description: "Use the current spark as-is"
  - label: "Skip for all remaining"
    description: "Don't prompt for creative-spark on remaining stories"
```

If "Yes": Read and execute `${CLAUDE_PLUGIN_ROOT}/commands/references/creative-spark-inline.md` inline against this story. After it completes, update the story file with the chosen Visual Direction and Wireframe.

**"Skip for all remaining"** sets a flag for the current detailing session — subsequent stories skip that check without prompting. The two checks are independent — skipping content-spark for all doesn't skip creative-spark.

Progress indicator between stories:

> "Stories detailed: 2/5 ✓
>
> Ready for **Story 3: [Name]**?"

### Step D3: Finalize

After all stories have sparks, continue with the existing cycle finalization flow:

- **Step 5: Cycle Review** — Review all stories as a whole
- **Step 6: Finalize Cycle** — Create/update cycle.yaml and .state
- **Step 7: Visual Cohesion** — Optional design-vibe review
- **Step 8: Confirm Cycle** — Next steps

**Clear PLANNING_CYCLE when done:**
```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/update-global-state.sh PLANNING_CYCLE ""
```

---

## Story Order

Stories are numbered for implementation order:
- `1-app-shell.md`
- `2-data-layer.md`
- `3-backlog-view.md`

Dependencies flow downward. Story 2 can depend on Story 1.

## Pulling from Backlog

If user wants to include backlog stories:

> "Your backlog has [N] stories. Pull any into this cycle?"

Use **AskUserQuestion**:
```
question: "Pull any backlog stories into this cycle?"
header: "Backlog"
options:
  - label: "Yes, show me the list"
    description: "Review backlog stories to pull in"
  - label: "No, start fresh"
    description: "Only use new stories for this cycle"
```

**If user selects "Other" or provides custom text:** Ask a clarifying AskUserQuestion to confirm which specific stories they want to include.

Moving a backlog story to a cycle sets its status to `planning`. It still needs `plan-chunks` before implementation.

## Time Guidance

Cycle planning is lightweight (sparks only):
- 3 stories: ~10-15 minutes
- 5 stories: ~15-20 minutes
- 8+ stories: Consider splitting into multiple cycles

Detailed planning happens per-story via `plan-chunks` when you're ready to implement.

## Remember

- **Cycle = plan of plans** — goals and story sparks, not implementation details
- **Stories saved with `status: planning`** — need `plan-chunks` before implementation
- **Dependencies captured** — story order matters
- **Story paths:** `.craft/cycles/[cycle]/stories/[N]-[slug].md`
- **Context-safe** — if context compacts, read existing story files and continue
- **Detailed planning happens later** — via `plan-chunks` when ready to implement
