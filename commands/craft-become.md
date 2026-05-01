---
name: craft:become
description: "Agent crystallization command. Studies a tool, role, or person and produces a portable 9-section agent that inhabits the domain - with beliefs, scar tissue, and instincts."
argument-hint: "[tool name | role | person name | description]"
---

# Become

Crystallize a tool, role, or person into a portable AI agent. Unlike `/craft:research` which discovers what's true, `/craft:become` inhabits a mind - producing an agent with beliefs, decision frameworks, and scar tissue.

Agents produced by this command are portable. They carry perception, not project context. Project context comes from the environment at runtime.

## Project Root

Use `$CRAFT_PROJECT_ROOT` (set at session start) as the base path for all `.craft/` references. If not set, resolve by walking up from PWD to find the nearest `.craft/.global-state`.

Set `PROJECT` to `${CRAFT_PROJECT_ROOT:-.}`.

## Flow

### Phase 0: Intent

Parse args to determine what we're crystallizing.

**If no args:** Use **AskUserQuestion**:
```
question: "What tool, role, or person do you want to crystallize into an agent?"
header: "Become"
options:
  - label: "A specific tool"
    description: "Reverse-engineer a tool's decision logic (e.g., CodeRabbit, Lighthouse, ESLint)"
  - label: "A role/expertise"
    description: "Synthesize what the best practitioners believe (e.g., accessibility auditor, UX designer)"
  - label: "A specific person"
    description: "Reconstruct an individual's perceptual framework from their artifacts"
```
Then ask for the specific name/description.

**If args provided:** Infer the source type:
- **Source-based:** Input names a specific tool, library, or product (e.g., "CodeRabbit", "Lighthouse", "Playwright"). Research is narrow and deep - reverse-engineer this tool's decision logic.
- **Role-based:** Input describes a domain or expertise (e.g., "accessibility auditor", "AI-first UX designer", "performance engineer"). Research is broad - synthesize what the best practitioners believe.
- **Person-based:** Input names a specific individual (e.g., "Darin", "Kent Beck"). Research uses writings, decisions, behavioral patterns.

**Only clarify if genuinely ambiguous.** "CodeRabbit" is obviously source-based. "Accessibility auditor" is obviously role-based. But "React expert" could be role-based (what do great React developers believe?) or source-based (reverse-engineer React's design philosophy). When ambiguous, use **AskUserQuestion** with 2-3 interpretations and an opinionated recommendation:

```
question: "'{input}' could mean different things. Which direction?"
header: "Direction"
options:
  - label: "{interpretation 1} (Recommended)"
    description: "{why this is the strongest direction}"
  - label: "{interpretation 2}"
    description: "{what this would produce}"
```

**Set up the research folder:**
- Slugify the input for the folder name (e.g., "AI-first UX designer" -> `ai-first-ux-designer`)
- Research path: `$PROJECT/.craft/research/{slug}-become/`
- Check if this folder already exists. If it does, use **AskUserQuestion**: resume existing research or start fresh?

### Phase 1: Psychological Research

Generate 5-7 sub-questions shaped for **mind-replication**, not fact-gathering. The six categories to cover:

1. **Beliefs** - What do the best practitioners in this domain believe that outsiders think is wrong? What do they treat as obvious that newcomers keep getting wrong?
2. **Trade-offs** - Where do practitioners genuinely disagree with each other, and what does each side think the other is missing?
3. **Refusals/Boundaries** - What do they refuse to do even when stakeholders push for it? What's their line?
4. **Mistake taxonomy** - What are beginner mistakes vs intermediate mistakes vs "looks right but subtly broken"? What have they seen fail badly enough to change their approach?
5. **What users actually need** - When someone asks this expert for X, what do they usually actually need? Where does the question behind the question live?
6. **Scar tissue** - What instinctive flinches do they have from past failures? What patterns trigger "this feels wrong" before they can articulate why?

**Adapt sub-questions based on source type:**
- **Source-based:** Focus on: what does this tool catch that others miss? What trade-offs did its designers make? What does it refuse to do? What are its blind spots?
- **Role-based:** Focus on: what do the best practitioners notice first? What's their threat model? Where is there genuine disagreement in the field?
- **Person-based:** Focus on: what are their recurring themes? What positions do they hold that generate friction? What do they treat as self-evident?

**Before spawning researchers, write the session plan to disk** (compaction survival - if context compresses during Phase 1, the orchestrator can recover state from this file):

Write `{research_path}/_plan.md` with:
```markdown
---
query: "{input}"
date: {today}
status: in-progress
depth: 1
source_type: {source/role/person}
mode: become
output_path: {$PROJECT/.claude/agents/become-{slug}.md}
---

# {input} - Become Research

## Sub-questions ({N} branches)

1. **01-{branch-slug}** - {sub-question}
2. **02-{branch-slug}** - {sub-question}
...
```

This file serves double duty: research documentation AND session state recovery. The `output_path` field is read back during Phase 4 iteration if the variable is lost to compaction.

**Use the Task tool to spawn one become-researcher agent per sub-question in parallel:**

```
Task tool:
  subagent_type: "craft:become-researcher"
  description: "Become research: {short branch name}"
  prompt: |
  ## Your Assignment

  You are collecting psychological material for an agent crystallization project.

  **Topic:** {input} (becoming an agent)
  **Source type:** {source/role/person}
  **Your sub-question:** {sub-question}

  ## Write your material to: {research_path}/{NN}-{branch-slug}.md

  Follow the branch file format in your agent instructions exactly.
  The crystallizer will read your output directly - give it raw psychological
  material, not summarized findings.
```

Wait for all researchers to complete.

### Phase 2: Synthesis Checkpoint

Read each branch file's **frontmatter only** (first 10-15 lines - branch name, question, confidence, sources, status). Do NOT read full branch files here - that's the crystallizer's job in Phase 3. The orchestrator's synthesis should be lightweight and direction-setting, not exhaustive. Reading full branches at this point overloads the orchestrator's context right before the highest-stakes handoff.

Present to the user:

**Strong convergence** (findings that multiple branches agree on):
- List the top 3-5 converging findings with brief descriptions

**Interesting tensions** (where branches disagree or reveal genuine trade-offs):
- List any disagreements or split opinions

**Scar tissue** (things that failed, instinctive flinches):
- List the most interesting failure patterns or negative heuristics

**Gaps** (what the research didn't cover):
- Note any of the 6 categories that came back thin

Use **AskUserQuestion**:
```
question: "Any direction before I crystallize? You can guide emphasis or say 'go'."
header: "Synthesize"
options:
  - label: "Go - crystallize as-is"
    description: "Proceed with the research as it stands"
  - label: "Lean into specific findings"
    description: "I want to emphasize certain threads"
  - label: "Research more"
    description: "Some areas are too thin - spawn more researchers"
```

If "Lean into specific findings" - ask what to emphasize or de-emphasize. Capture as `user_direction`.

If "Research more" - ask which areas need more depth, generate new sub-questions, spawn additional researchers, then re-present Phase 2.

**After synthesis direction is captured**, use **AskUserQuestion** for the research handbook:
```
question: "Should the agent reference its research as a handbook for deeper context?"
header: "Handbook"
options:
  - label: "Yes - include research reference (Recommended)"
    description: "Agent knows where to find its detailed findings. Beliefs are self-contained, handbook is optional depth."
  - label: "No - fully self-contained"
    description: "Agent carries only beliefs and instincts, no external references"
```

If "Yes" - pass `include_handbook: true` and `handbook_path: {research_path}` to the crystallizer in Phase 3. The crystallizer adds a `research_handbook:` field to the agent's frontmatter and a note in the Boundaries section about when to consult it (grounding recommendations in specific sources, citing practitioner quotes, referencing detailed findings beyond what beliefs capture).

If "No" - omit handbook fields. The agent is fully portable with no external references.

### Phase 3: Crystallization

This is where the magic happens. The crystallizer writes the agent file directly to disk - the orchestrator NEVER touches agent content.

**Determine initial output path:**
- Slugify input for filename: `$PROJECT/.claude/agents/become-{slug}.md`
- This may be renamed in Phase 4

**Read 2-3 existing crystallized agents** from the plugin's `agents/` directory as format exemplars. Pick agents that are well-structured (e.g., `pr-reviewer-expert.md`, `crystallizer.md`).

**Invoke the crystallizer agent via the Task tool:**

```
Task tool:
  subagent_type: "craft:crystallizer"
  description: "Crystallize: {input}"
  prompt: |
    ## Crystallization Task

  Produce a 9-section agent file for: {input}
  Source type: {source/role/person}

  ## Parameters

  output_path: {output_path}
  research_folder: {research_path}
  exemplar_paths:
    - {exemplar_1_path}
    - {exemplar_2_path}
  source_type: {source/role/person}
  user_direction: {user_direction or omit this field entirely if user said "go"}

  ## Instructions

  1. Read ALL branch files in the research folder (mandatory)
  2. Read the exemplar agents for format reference
  3. Run your 7-phase extraction protocol
  4. Write the complete agent file to output_path
  5. Include provenance metadata: crystallized_from, crystallized_date, stale_signals
  6. Return a brief summary: identity (1 sentence), top 3 generative beliefs, blind spots
```

The crystallizer writes directly. Wait for it to complete and capture its summary.

### Phase 4: Review & Save

Read the crystallized agent file back from disk. Show the user:

- **Identity:** 1-sentence summary (from crystallizer's return)
- **Top generative beliefs:** The 3-5 beliefs that pre-answer the most decisions
- **Blind spots:** What this agent can't see
- **File size:** Line count / approximate density

**Recommend an agent name** based on what the research revealed, not just the slugified input. "CodeRabbit" might become "become-pr-reviewer-expert". "AI-first UX designer" might become "become-generative-ui-designer". The name should reflect what the agent IS, not what was studied. All crystallized agents use the `become-` prefix for easy discovery (skills glob for `become-*.md` to find available minds).

Use **AskUserQuestion**:
```
question: "Agent crystallized. How would you like to save it?"
header: "Save"
options:
  - label: "Save as become-{recommended-name} (Recommended)"
    description: "Save to .claude/agents/become-{recommended-name}.md"
  - label: "Save with different name or path"
    description: "Choose a custom name or save location"
  - label: "Iterate with feedback"
    description: "I want to adjust something - the crystallizer will edit in place"
  - label: "Start over"
    description: "Discard and re-crystallize from scratch"
```

**If "Save as recommended":** Rename the file from `become-{slug}.md` to `become-{recommended-name}.md` if different.

**If "Save with different name or path":** Ask for the name/path, move the file.

**If "Iterate with feedback":** Ask what to adjust. Re-invoke the crystallizer with feedback:

```
Task tool:
  subagent_type: "craft:crystallizer"
  description: "Iterate: {input}"
  prompt: |
    ## Iteration Task

  The user has feedback on the agent you crystallized.

  output_path: {output_path}
  research_folder: {research_path}
  feedback: "{user feedback}"

  Read your output file back, re-read the relevant branch files, and edit in place.
  Do NOT start from scratch unless the perceptual framework itself is wrong.

  Return updated summary: identity, top 3 beliefs, blind spots.
```

Then re-present Phase 4 with the updated agent.

**If "Start over":** Delete the agent file, jump back to Phase 2 (Synthesis Checkpoint). Re-crystallizing on the same research with no new direction produces the same agent. The user needs a chance to provide different editorial direction or spawn additional researchers before re-crystallizing.

**After save:** Report the final path and remind the user to restart the terminal for the new agent to register.

## Research Folder Structure

```
{slug}-become/
  _plan.md          # Sub-questions, source type, user direction
  01-{branch}.md    # Branch 1 (written by researcher agent)
  02-{branch}.md    # Branch 2
  ...
```

## Agent Configuration

- **Researchers** use the `craft:become-researcher` agent type (sonnet) - a specialized psychological material collector, NOT the generic fact-finding researcher used by `/craft:research`
- **Crystallizer** uses the `craft:crystallizer` agent type (opus - highest-judgment task)
- Researchers write branch files to disk using the psychological material format (axioms, scar tissue, threat model, domain inventory, etc.)
- Crystallizer writes the agent file to disk
- Orchestrator never writes agent content - it's a coordinator
