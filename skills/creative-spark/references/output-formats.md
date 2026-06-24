# Creative Spark Output Formats

Output format templates for each type of creative option. Each option should follow the appropriate template.

**Presentation:** Each option's full content (wireframe, visual direction, architecture, tone examples) maps to the `markdown` preview field in AskUserQuestion. The SKILL.md presentation section handles the AskUserQuestion structure — these templates define what goes inside each option's `markdown` block.

---

## For UI/UX Ideas

When the story involves UI, include visual direction as part of each option:

```markdown
### Option A: Card Grid

```ascii
+----------+ +----------+ +----------+
|  Card    | |  Card    | |  Card    |
|  ....    | |  ....    | |  ....    |
|  [CTA]   | |  [CTA]   | |  [CTA]   |
+----------+ +----------+ +----------+
```

**The Approach:** [How it works functionally]

**Visual Direction:**
- **Feel:** Clean, scannable, modern
- **Inspiration:** Linear's project view
- **Key Elements:** Generous whitespace, subtle shadows, 8px rounded corners
- **Physicality:** [1 sentence - weight and easing character, e.g., "Light, snappy. Ease-out with short duration - the interface gets out of your way."]
- **Signature motion:** [1 sentence - the defining movement, e.g., "Cards reveal with 20ms stagger from top-left, as if dropped from a hand."]
- **Key token assignments:** the elements this option introduces, each as a `Part | Role/State | Token | Value/Source` row - Token = a tokens.yaml name where known, else TBD (planning verifies). These seed the story's Element Binding Table.

**Why it works:** [Benefits]
**Trade-offs:** [Considerations]
```

**Note:** This covers the "vibe" as part of the option. For deeper aesthetic exploration (mood boards, token definition, detailed visual language), the user can separately invoke `design-vibe`.

---

## For Technical Approaches

```markdown
### Approach A: Server-Side Rendering

**Architecture:**
- Next.js App Router
- Server components for data fetching
- Client components for interactivity

**Why:**
- Better SEO
- Faster initial load
- Simpler caching
```

---

## For Copy/Voice

```markdown
### Voice Option A: Friendly Expert

**Tone:** Warm but authoritative
**Example:** "Great choice! Here's how to make the most of it..."

**Voice Option B: Minimal Pro

**Tone:** Concise, confident
**Example:** "Done. Your changes are live."
```
