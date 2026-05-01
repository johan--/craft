# Motion Refinement Guide

After the user picks a direction for a UI story, and BEFORE transitioning to `lock-decision`, run this 3-step motion refinement workflow. The selected option already has **Physicality** and **Signature motion** fields - these constrain everything in this step.

**Physics constraint:** The selected option's Physicality and Signature motion set the character of all motion in this story. A "heavy, deliberate" interface gets different defaults than a "snappy, immediate" one. Match easing and timing to the physics established during option generation.

---

## Step 1: Motion Defaults (with Rationale)

Include these in the Motion field with brief rationale. Each default states WHY it belongs - if the rationale doesn't hold for this story, omit it naturally:
- Skeleton shimmer (content is async - omit if all content is synchronous/static)
- Hover lift/feedback (element is clickable and needs affordance - omit if interaction is obvious from context)
- Enter/exit transitions (state change needs spatial continuity - omit if instantaneous feels more responsive for this interface's physics)
- Form validation feedback (user needs confirmation loop - omit if submission is trivial/instant)

These are choices, not checkboxes. A "snappy, immediate" interface might skip hover lift because instantaneous response IS the feedback. A "weighted, deliberate" interface might use hover lift with longer easing to reinforce physicality.

---

## Step 2: Suggest Next-Level Opportunities

Reference `.craft/design/animations.md` "Next-Level Patterns" section for ideas relevant to this specific story. Only suggest patterns that genuinely fit — don't force it.

Use **AskUserQuestion**:

```
question: "This story has some animation opportunities that could elevate it. Want to explore?"
header: "Animations"
options:
  - label: "Show me what you've got"
    description: "See 2-3 specific animation ideas that could make this shine"
  - label: "Keep it standard"
    description: "Stick with table-stakes animations (loading, hover, transitions)"
  - label: "I have ideas"
    description: "I know what animations I want — let me describe them"
multiSelect: false
```

**If "Show me what you've got":**
Present 2-3 context-specific suggestions using AskUserQuestion with `multiSelect: true`:

```
question: "Which of these appeal to you? Pick any that feel right."
header: "Motion ideas"
options:
  - label: "[Pattern name]"
    description: "[What it does and why it elevates this story]"
  - label: "[Pattern name]"
    description: "[What it does and why it elevates this story]"
  - label: "[Pattern name]"
    description: "[What it does and why it elevates this story]"
multiSelect: true
```

Options should be drawn from the animations.md Next-Level Patterns section, tailored to the story. Examples:
- List/grid story: "Staggered reveal — items animate in sequence (40ms gap) instead of all at once"
- Navigation story: "Direction-aware hover — highlight follows mouse direction between items"
- Completion flow: "Success celebration — subtle confetti or animated checkmark on key completions"
- Complex menu: "Safe triangles — invisible bridge prevents accidental submenu close"
- Dashboard/page: "Stagger choreography — header, then content, then sidebar fade in sequence"

**If "Keep it standard":**
Set Motion to the table-stakes animations identified in Step 1. Move on.

**If "I have ideas":**
Ask the user to describe their animation vision. Capture it in Motion.

---

## Step 3: Compose the Motion Field

Combine the selected option's physics + motion defaults + any chosen next-level patterns into the story's `**Motion:**` field:

```markdown
**Motion:** Heavy, deliberate (ease-in-out, longer deceleration). Cards surface from below
with 20ms stagger. Skeleton shimmer on async grid. Hover lift on cards (scale 1.02 + shadow,
matching deliberate easing). Modal fade+scale enter/exit. Success checkmark on form submit.
```

The physics sentence leads. Every subsequent motion decision references it. Keep it specific enough for `plan-chunks` to translate into implementable chunk details.
