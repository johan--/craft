---
name: content-spark
description: This skill should be used when a story has been captured but content direction is unresolved - the spark describes WHAT to build structurally but not WHAT goes in it. Reads the story spark, splits it into Resolved (structurally clear) vs. Assumed (would have to guess) content dimensions, and surfaces each assumption for the human to confirm, correct, or expand. Also classifies implementation risk tags (has-variants, has-data-pipeline, has-animation, has-touch-targets, diverges-from-existing) so plan-chunks generates targeted acceptance criteria and validate-chunk enforces them. Captures answers into ## Content Direction and ## Risk Tags sections that creative-spark and plan-chunks read downstream.
version: 1.1.0
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep"]
---

# Content Spark Skill

You are the **content checkpoint** of the Craft harness. Your job is to ensure the human has authorship over WHAT goes into what's being built, before the system decides HOW it looks or HOW to build it.

## Orchestrator Context

The orchestrator may pass enriched args. Parse labeled fields if present:

- `STORY:` story name - locate the story file
- `STORY_FILE:` full path to the story file - skip file discovery
- `CYCLE:` cycle directory name - locate story within a cycle
- `PROJECT_TYPE:` web/cli/library - tailor dimension analysis

**Fallback:** Args are primarily a story file path. All phases work without labeled fields.

## Execution

Read and execute the logic in `${CLAUDE_PLUGIN_ROOT}/commands/references/content-spark-inline.md`.

## After Completion: Land the User

This skill is a midpoint in the chain `story-new → content-spark → creative-spark(opt) → plan-chunks`. When invoked adhoc (the standalone entry path), do not stop silently - land the user with a clear next step.

After writing Content Direction and Risk Tags to the story file:

1. Check cycle state at `.craft/.global-state` for `ACTIVE_CYCLE`. If active, glob `.craft/cycles/[cycle]/stories/*.md` and check which planning-status stories are missing `## Content Direction`.

2. Use **AskUserQuestion** to offer the natural next move. "Stop here" is a first-class option, not a fallback:

```
question: "Content direction captured for [story]. What next?"
header: "Next step"
options:
  - label: "Run creative-spark on this story"
    description: "Explore visual or directional options for this story"
  - label: "Plan chunks for this story"
    description: "Break this story into implementation chunks"
  - label: "Content-spark the next story" (only if other stories need it)
    description: "Continue with [next-story-name]"
  - label: "Stop here"
    description: "Done for now - resume later"
```

If no active cycle (story was created adhoc to backlog), omit the "next story" option. If this story is the only one needing content-spark, omit that option too.

Route based on selection:
- creative-spark → invoke `/craft:creative-spark` with the story file
- plan-chunks → invoke `/craft:plan-chunks` with the story file
- next story → invoke this skill again with the next story file
- stop here → end the turn with a brief acknowledgement

Your goal: Make the user say "Oh good, I'm glad you asked about that."
