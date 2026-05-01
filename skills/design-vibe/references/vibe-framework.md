# Vibe Framework Reference

Reference material for the design-vibe skill. The main SKILL.md defines the creative process - this file covers the structural details of mood axes, token translation, and comparison format when alternatives are needed.

---

## Mood Axes

When you need to position a vibe precisely, use these four axes:

```
Energy Level:  Calm <-------*-------> Energetic
Formality:     Casual <-------*-------> Professional
Density:       Spacious <-------*-------> Dense
Playfulness:   Serious <-------*-------> Playful
```

These are diagnostic tools, not output format. Use them internally to understand where the user's vibe sits, and to identify the tension ("you want calm AND energetic - that's the interesting constraint").

---

## Token Translation

When a vibe is approved and needs to become implementable tokens:

```yaml
# .craft/design/tokens.yaml
# Vibe: [Name] — [Soul Statement]

colors:
  primary: "#6366F1"      # [Why this color fits the vibe]
  surface: "#FAFAFA"      # [Why]
  text-primary: "#1F2937" # [Why]
  accent: "#F59E0B"       # [Why]
  error: "#EF4444"
  success: "#10B981"

typography:
  font-heading: "Inter"           # [Why this typeface]
  font-body: "Inter"
  font-mono: "JetBrains Mono"
  scale: [12, 14, 16, 20, 24, 32, 48]

spacing:
  scale: [4, 8, 12, 16, 24, 32, 48, 64]

radii:
  sm: "4px"    # [Why this radius fits the vibe]
  md: "8px"
  lg: "16px"
  full: "9999px"

shadows:
  sm: "0 1px 2px rgba(0,0,0,0.05)"
  md: "0 4px 6px rgba(0,0,0,0.07)"
  lg: "0 10px 15px rgba(0,0,0,0.10)"

motion:
  duration-fast: "100ms"
  duration-normal: "200ms"
  duration-slow: "300ms"
  easing: "cubic-bezier(0.4, 0, 0.2, 1)"
```

Every token should have a comment explaining WHY it fits the vibe. "8px radii" is a specification. "8px radii - slightly rounded, approachable without being soft" is a design decision.

---

## Alternative Vibes (When Requested)

If the user asks to see an alternative after rejecting the initial proposal, generate a genuine contrast - not a variation. If the first proposal was warm/organic, the alternative should be cool/precise. The contrast helps the user triangulate.

Structure each alternative the same way as the main proposal (Soul Statement, The Feeling, Visual Language, Inspiration Board, What This Vibe Is NOT, Sample Moments).

Present the comparison as:

```
The first direction said "[soul statement A]."
This alternative says "[soul statement B]."
The difference: [one sentence explaining what changes and what stays].
```

This helps the user understand what they're choosing between - not "A vs B" but "this philosophy vs that philosophy."
