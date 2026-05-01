# Content Spark (Inline Reference)

This file is read by parent commands (cycle-design, story-new) that need to run content-spark logic inline instead of via nested Skill invocation. The standalone `/craft:content-spark` skill reads this same file.

## When to Run

After a story spark is captured but before creative-spark or plan-chunks. The story must have a `## Spark` section.

## Phase 1: Read the Spark

Read the story file. Extract the `## Spark` section content.

If the story already has a populated `## Content Direction` section (non-empty, non-comment text after the heading):

Use **AskUserQuestion**:
```
question: "This story already has content direction. What would you like to do?"
header: "Content"
options:
  - label: "Keep it"
    description: "Content direction is good - proceed to next step"
  - label: "Revise it"
    description: "Re-run the content checkpoint to update direction"
```

**If "Keep it":** Content-spark is done. Continue the parent flow.
**If "Revise it":** Continue to Phase 2.

If no Content Direction exists, continue to Phase 2.

## Phase 2: Analyze Content Dimensions

Read the spark and classify each of the five content dimensions as **Resolved** or **Assumed**.

| Dimension | What it covers | Resolved when... |
|-----------|---------------|-------------------|
| **Display content** | What data, features, or items are shown | Spark explicitly names the content items, data sources, or feature list |
| **Narrative arc** | What story the feature tells, what's the user flow | Spark describes the journey, sequence, or progression |
| **Copy direction** | Headlines, labels, empty states, error messages, tone | Spark specifies wording, tone, or references a voice/style |
| **Data shape** | What's real vs. mock, what fields matter, what's dynamic | Spark names specific data fields, sources, or formats |
| **Priority/hierarchy** | What's prominent vs. secondary, what's above the fold | Spark ranks importance, names the hero element, or describes visual weight |

**Classification rules:**
- **Resolved** - the spark explicitly addresses this dimension. The system would not have to guess.
- **Assumed** - the spark is silent or vague on this dimension. The system would have to make assumptions to proceed.

Be honest about what's resolved vs. assumed. The value is revealing what the system would otherwise guess silently.

## Phase 2.5: Risk Classification

Classify which implementation risks apply. These tags tell plan-chunks what acceptance criteria to generate and validate-chunk what to enforce.

| Tag | Apply ONLY when... |
|-----|---------------------|
| `has-variants` | The spark names specific sizes or the component renders at multiple dimensions. Visual properties use absolute pixel values that won't scale. |
| `has-data-pipeline` | The story adds or modifies data fields that pass through schemas/validators, OR uses APIs that behave differently across environments. Must actually CHANGE the data shape. |
| `has-animation` | The spark explicitly describes keyframes, transitions, multi-phase animation sequences, or opacity changes through blend modes. |
| `has-touch-targets` | The spark describes interactive elements with explicit pixel dimensions below 44px, or text inputs with font-size below 16px. |
| `diverges-from-existing` | The spark uses "use X instead of Y" language where the codebase currently does Y, AND an implementer reading existing code would naturally follow the wrong pattern. |

Most stories should get 1-2 tags. Zero is valid for pure logic/config/doc changes.

## Phase 3: Smart Gate

Count the number of **Assumed** dimensions.

**If <2 assumptions:** The content is well-specified. Write the Content Direction section (Phase 5) with the resolved answers and any single noted gap. Content-spark is done - continue the parent flow.

**If >=2 assumptions:** Continue to Phase 4 to surface each assumption.

## Phase 4: Surface Assumptions

Present the analysis summary:

> "Looking at the spark, here's what I see:
>
> **Resolved** (I know what to build):
> - [Dimension]: [evidence from spark]
>
> **Assumed** (I'd have to guess):
> - [Dimension]: [what I'd assume and why]
>
> Let me check each assumption with you."

Surface each assumption **individually** via AskUserQuestion, ordered by impact:

```
question: "[Dimension name]: [System's best guess]. Does this match your intent?"
header: "[Short dimension label]"
options:
  - label: "Yes, that's right"
    description: "Lock in this direction"
  - label: "Close, but..."
    description: "Adjust the direction"
  - label: "No, here's what I want"
    description: "Replace with your vision"
```

If user provides custom text, use their exact words. Do not paraphrase.

## Phase 5: Write Content Direction

Write `## Content Direction` to the story file after `## Spark` and before `## Visual Direction` or `## Decisions`.

Only include dimensions that add value beyond what the spark already says. If all dimensions are obvious:

```markdown
## Content Direction
Content is well-specified in the spark. No additional direction needed.
```

Also write `## Risk Tags`:

```markdown
## Risk Tags

```yaml
risk_tags:
  - has-variants    # [brief justification]
```

<!-- These tags are read by plan-chunks to generate targeted acceptance criteria
     and by validate-chunk to enforce them. -->
```

Use **Edit** to insert both sections into the existing story file.

Content-spark is done. The parent command continues its flow.
