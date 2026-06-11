# Creative Spark (Inline Reference)

This file is read by parent commands (cycle-design, story-new) that need to run creative-spark logic inline instead of via nested Skill invocation. The standalone `/craft:creative-spark` skill reads this same file.

## When to Run

When the user selected "Let's get creative" for a story. After content-spark has completed (if applicable).

## Pre-checks

**Existing Visual Direction:** Read the story file. If it already has a populated `## Visual Direction` section:

Use **AskUserQuestion**:
```
question: "This story already has visual direction. How should creative exploration work?"
header: "Visual"
options:
  - label: "Build on it"
    description: "Explore functional and interaction options within the existing visual direction"
  - label: "Replace it"
    description: "Start fresh - generate new visual directions too"
```

**Content Direction Awareness:** If the story has `## Content Direction`, read it fully. Treat it as a constraint - your options explore the HOW while respecting the WHAT.

## Step 1: Creative Driver (Optional)

Use **AskUserQuestion**:
```
question: "Who should drive the creative direction?"
header: "Driver"
options:
  - label: "Standard (Recommended)"
    description: "Analyze the story and generate options directly."
  - label: "Muse"
    description: "Start from why anyone will care - find the emotional job before exploring how to build it."
  - label: "Alchemist"
    description: "Find the physical metaphor first - what does this weigh, how does it move?"
  - label: "Full Workshop"
    description: "Muse finds the feeling. Alchemist finds the physics. Options where both speak."
```

**If Standard:** Skip to Step 2.

**If Muse, Alchemist, or Full Workshop:** Invoke the agent(s) via Agent tool (NOT Skill tool - agents return results directly). Use the prompts from `skills/creative-spark/SKILL.md` Steps 1.5-1.6 for agent invocation format. Store results as enriched brief for Step 2.

## Step 2: Reframe and Find the Tension

If an enriched brief exists from agent interrogation, use it as input.

Before jumping to layouts and wireframes, spend a moment as a design director:

- **What is this feature actually about?** Name the deeper job-to-be-done.
- **Name the tension.** Every interesting feature lives at the intersection of competing values. One option prioritizes side A, another side B, a third finds a novel resolution.
- **What does this weigh?** Find the physical metaphor. Does this feel like flipping cards? Surfacing content from below? A drawer sliding open?
- **What would make this remarkable?** Not "good" - remarkable.
- **Where can we steal from outside software?** Read `${CLAUDE_PLUGIN_ROOT}/skills/creative-spark/references/cross-domain-patterns.md` for proven cross-pollinations. Option C MUST draw from a named non-software domain.

Write your output preamble:
1. **Design POV** (2-3 sentences) - opinionated thesis on what this feature should feel like
2. **Core Tension** (1 sentence) - the competing values your options take different stances on
3. **Physics** (1 sentence, UI stories only) - "This interface has the weight of ___. It responds like ___."

## Step 3: Generate Options (3-5)

Read `${CLAUDE_PLUGIN_ROOT}/skills/creative-spark/references/output-formats.md` for UI/UX, Technical, and Copy/Voice option format templates.

Options should span genuinely different creative territories anchored by the tension:
- One option that leans into side A of the tension
- One option that leans into side B
- One option that resolves the tension unexpectedly (MUST borrow from a named non-software domain)

For each option provide: name, approach (2-3 sentences), why it works, trade-offs, effort (Small/Medium/Large), best for.

## Step 4: Recommend

Pick a winner and defend it with conviction. Don't hedge.

## Step 5: Present for Selection

Present options via **AskUserQuestion** with previews:

```
question: "Which direction speaks to you?"
header: "Direction"
options:
  - label: "[Option A name]"
    description: "[1-sentence summary]"
    preview: "[Full content block - wireframe + visual direction for UI, architecture for technical]"
  - label: "[Option B name]"
    description: "[1-sentence summary]"
    preview: "[Full content block]"
  - label: "[Option C name]"
    description: "[1-sentence summary]"
    preview: "[Full content block]"
```

## Handling the Selection Response

Read the user's response to the selection AUQ and route:

- **Picks an option** -> continue to Step 6 (motion, UI only) / After Selection.
- **Wants more** ("none of these land") -> generate 3 more options with a narrower brief.
- **Wants to combine** ("A's layout with B's motion") -> synthesize a hybrid from the named pieces.
- **Unsure** - route by language:
  - **Resonated, can't name which** ("they're all good, I can't tell which", "a mix I can't see") -> run the calibration loop: Read `reference/calibration-loop.md` and run it inline, one either/or at a time, until the pick clicks. The loop SURFACES a direction; it does NOT commit it - close it with an explicit pick before writing to the story file.
  - **Nothing landed** ("all feel expected") -> generate 3 more, narrower brief. Not the loop.
  - **Explicit delegation** ("just pick for me") -> recommend + commit (the only auto-pick case).
  - **Named hybrid** -> synthesize the combine.

Rail: recommend freely, commit to the story file only on an explicit pick/yes; auto-pick ONLY on explicit delegation. A converged loop direction is not approval - close it with the selection.

## Step 6: Motion Refinement (UI Stories Only)

After user picks a direction, before transitioning to lock-decision, run motion refinement. Read `${CLAUDE_PLUGIN_ROOT}/skills/creative-spark/references/animation-integration.md` for the full 3-step motion refinement workflow.

## After Selection

Update the story file with the chosen option's:
- Visual Direction (Vibe, Feel, Inspiration, Key tokens, Motion)
- Wireframe (for UI stories)
- Any decisions locked during the creative process

Creative-spark is done. The parent command continues its flow.
