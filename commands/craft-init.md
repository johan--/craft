---
name: craft:init
description: "One-time setup to initialize the Craft harness for a project."
---

# Project Init

Set up the Craft harness for your project. Run once at the start.

## Flow

### Phase 0: Init Mode

Before scanning or asking questions, check what the user needs.

Use **AskUserQuestion**:
```
question: "What kind of setup do you need?"
header: "Init mode"
options:
  - label: "Full setup (Recommended)"
    description: "Scan project, extract patterns, configure tokens/conventions"
  - label: "Quick setup"
    description: "Just the .craft/ directory structure — for projects with strong existing docs (CLAUDE.md, etc.)"
```

**If "Quick setup":**

Ask one follow-up for project type:

Use **AskUserQuestion**:
```
question: "What type of project is this?"
header: "Type"
options:
  - label: "UI / Web app"
    description: "Includes design tokens, inspiration, components templates"
  - label: "CLI / Backend / Plugin"
    description: "Includes naming conventions, schemas, code patterns"
```

Then:
1. **For UI projects:** Run `SKIP_TOKENS=1 ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-craft.sh ui`
   - Quick setup skips the scanner, so there's no visual file count. Default to deferred tokens.
   - The user chose quick setup because they have strong existing docs. Tokens can be added later when you have visual code to reference.
2. **For CLI projects:** Run `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-craft.sh cli`
   - CLI conventions are always generated.
3. Skip straight to Phase 6 (First Cycle Kickoff)

The `.craft/` structure is created with sensible template defaults. The project's existing CLAUDE.md serves as the source of truth for stack, patterns, and conventions - no need to duplicate into project.md. Run `/craft:update-docs` later when there's code to scan.

> "Craft is ready! Directory structure created.
>
> Your CLAUDE.md is your project DNA - Craft will use it alongside `.craft/` state.
> [If UI:] Design tokens can be added later when you're ready - no guessing upfront.
> [If CLI:] Project conventions are set up and ready to enforce.
>
> What's the first thing we're tackling?"

→ Creates first cycle → Enters Creative Mode

**If "Full setup":** Continue to Phase 0a below.

**If invoked with `RESUME_INSPIRATION=true`:**

Read `.craft/design/.inspiration-session`. Check the `phase` field:
- `"collecting"` -> Skip to Phase 3a. Present: "Resuming your inspiration session. You have [N] source(s) so far."
- `"assembling"` -> Skip to Phase 3b. Present: "Resuming your inspiration session. Let me re-assemble your [N] sources."
- `"riffing"` -> Skip to Phase 3b first (to re-present the assembly), then proceed to Phase 3c. Present: "Resuming your inspiration session with [N] riff(s) applied."

Skip Phase 0, 0a, 0b, 1, 2, and 2b entirely - the session file already has all context needed.

---

### Phase 0a: Project Scan

Before asking any questions, understand the project by scanning it.

**Launch the project-scanner agent:**

> "Let me analyze your project..."


**INVOKE the project-scanner agent using the Task tool:**

```
Task tool:
  subagent_type: "craft:project-scanner"
  description: "Analyze project for Craft init"
  prompt: "Scan this project comprehensively.

  **Project root:** [current working directory]

  Follow your full analysis checklist (P1-P9). Be thorough but efficient.
  Return findings in your structured output format."
```

The agent returns:
- Project type (UI / CLI / API / Hybrid)
- Tech stack (languages, framework, package manager)
- Architecture and patterns discovered
- Conventions already in use
- Quality infrastructure status
- Existing documentation
- Locked patterns discovered
- Confidence signals (YAML) for visual patterns

**Extract confidence signals:**

If the agent's output contains a `## Confidence Signals (YAML)` section:
1. Extract the YAML content from the fenced code block in that section
2. Write it to `.craft/design/.confidence-signals.yaml` at the project root
3. This file is consumed by craft-init for project-state matrix branching.

If the section is missing (agent failed, non-UI project), skip this step. The file's absence is a valid state - consumers handle it gracefully.

**Fallback:** If the agent fails or returns empty, fall back to manual detection (Phase 0b).

---

### Phase 0b: Manual Detection (Fallback Only)

Only run this if the agent fails. Otherwise skip to Phase 1.

Quick detection via file presence:

```
# Project type indicators
Glob "src/components" or "components" or "app" or "pages" → count matches → UI_INDICATORS
Glob "bin" or "cli" or "commands" → count matches → CLI_INDICATORS
Glob "routes" or "controllers" or "handlers" or "api" → count matches → API_INDICATORS

# Package manager
Glob "pnpm-lock.yaml" → if found: PM = "pnpm"
else Glob "yarn.lock" → if found: PM = "yarn"
else Glob "bun.lockb" → if found: PM = "bun"
else Glob "package-lock.json" → if found: PM = "npm"
else PM = "none"

# Language (count files, excluding node_modules/venv)
Glob "**/*.ts" + "**/*.tsx" (exclude node_modules) → count → TS_COUNT
Glob "**/*.js" + "**/*.jsx" (exclude node_modules) → count → JS_COUNT
Glob "**/*.py" (exclude venv) → count → PY_COUNT
Glob "**/*.md" → count → MD_COUNT
Glob "**/*.sh" → count → SH_COUNT
```

Use these counts to infer project type and stack. Continue to Phase 1 with partial findings.

---

### Phase 1: Confirm Findings

Present the agent's findings and let the user confirm or correct.

> "I've analyzed your project. Here's what I found:
>
> **Project type:** [detected type]
> **Primary language:** [language] ([percentage]%)
> **Framework:** [framework or 'None']
> **Package manager:** [pm]
>
> **Key patterns discovered:**
> - [pattern 1]
> - [pattern 2]
> - [pattern 3]
>
> Does this look right?"

Use **AskUserQuestion**:
```
question: "Does this look right?"
header: "Confirm"
options:
  - label: "Yes, that's accurate"
    description: "Proceed with these settings"
  - label: "Mostly right, minor corrections"
    description: "I'll note what's different"
  - label: "Needs significant changes"
    description: "Let me describe the project"
```

**If "Mostly right":** Ask what needs correction, update findings, proceed.

**If "Needs significant changes":** Fall back to asking key questions (project type, language, framework). Don't ask about things that are verifiable from files.

**Store confirmed values:**
- `PROJECT_TYPE` = `ui` | `cli` (API uses cli templates)
- `TECH_STACK` = agent findings or user corrections
- `PATTERNS` = discovered patterns for locked.md

---

### Phase 2: Project-State Matrix

Route the init flow based on what the scanner found. For UI projects, this replaces the old "What are we working with?" question - the visual file count tells us what we're working with.

**Read the visual file count from the scanner output.** The scanner reports `visual_file_count` in its Quick Summary and Visual File Analysis section. Parse this number.

**If PROJECT_TYPE is `cli` or `api`:** -> **CLI/Backend branch**

> "This is a CLI/backend project - I'll set up Project Conventions (naming, structure, code style) and enforce them immediately."

Set `SKIP_TOKENS=0` (CLI tokens are conventions, always generated).
Skip to Phase 2b (Energy question).

**If PROJECT_TYPE is `ui` or `hybrid`:** Route by visual file count:

**Branch: UI from scratch (0 visual files)**

> "Fresh start! I won't guess at design tokens - I'll learn your visual language from what you build. No design tokens yet. When you're ready to establish a design system, re-run `/craft:init` with inspiration or add tokens.yaml manually."

Set `SKIP_TOKENS=1`.
Skip Phase 3 entirely.

**Branch: UI existing early (< 5 visual files)**

> "Your project has [N] visual files - not quite enough signal to extract confident design tokens yet. I'll defer tokens and learn from what you build next. When you have more visual code, run `/craft:update-docs` and I'll extract patterns."

Set `SKIP_TOKENS=1`.
Skip Phase 3 entirely.

**Branch: UI existing mid (5-20 visual files)**

> "Your project has [N] visual files - enough to start seeing patterns. Let me extract what I can find..."

Extract visual patterns from the scanner's findings (colors, fonts, spacing mentioned in the Key Patterns table). Present them to the user:

> "Here's what I found in your code:
>
> **Colors:** [list extracted colors with file references]
> **Typography:** [list font families found]
> **Spacing:** [list spacing patterns if consistent]
>
> These aren't confident enough to lock automatically. Want me to save them as starting tokens?"

Use **AskUserQuestion**:
```
question: "Save these as starting design tokens?"
header: "Tokens"
options:
  - label: "Yes, save and enforce"
    description: "Write to tokens.yaml - new code should follow these"
  - label: "Skip for now"
    description: "I'll skip tokens for now - add them later when patterns are clearer"
```

If "Yes": Set `SKIP_TOKENS=0`. The scanner findings feed into Phase 5 file generation (tokens.yaml gets populated from extracted values, not the generic template).
If "Skip": Set `SKIP_TOKENS=1`.

Skip Phase 3 (no inspiration needed - working from existing code).

**Branch: UI existing mature (20+ visual files)**

> "Your project has [N] visual files - rich enough for confident pattern extraction."

Extract visual patterns from scanner findings. Split into high-confidence (consistent, widely used) and low-confidence (inconsistent, few usages):

> "Here's what I found:
>
> **High confidence** (consistent across files):
> [list with use counts and file references]
>
> **Low confidence** (inconsistent or sparse):
> [list with use counts and notes]
>
> I recommend locking the high-confidence patterns immediately."

Use **AskUserQuestion**:
```
question: "How should I handle these patterns?"
header: "Token Recognition"
options:
  - label: "Lock high-confidence, defer low (Recommended)"
    description: "Enforce consistent patterns now, revisit uncertain ones later"
  - label: "Lock all"
    description: "Save everything as tokens - I'll adjust later if needed"
  - label: "Review each"
    description: "Walk me through each pattern for individual approve/skip"
  - label: "Skip all"
    description: "Don't save any tokens now"
```

If "Lock high-confidence": Write high-confidence to tokens.yaml, skip low-confidence. Set `SKIP_TOKENS=0`.
If "Lock all": Write all to tokens.yaml. Set `SKIP_TOKENS=0`.
If "Review each": Walk through each pattern with individual AskUserQuestion. Set `SKIP_TOKENS=0` if any approved, `1` if all skipped.
If "Skip all": Set `SKIP_TOKENS=1`.

Skip Phase 3 (no inspiration needed).

**Branch: UI with inspiration**

This branch fires when the user explicitly wants inspiration-driven design. Since the matrix auto-routes based on visual file count, the inspiration path needs a user signal. After the matrix routing above, if the project is a UI project (any visual file count), offer the inspiration option:

Use **AskUserQuestion**:
```
question: "Do you have design inspiration to draw from?"
header: "Inspiration"
options:
  - label: "Yes, I have reference sites"
    description: "Pull colors, typography, spacing from sites I admire"
  - label: "No, continue with what we have"
    description: "Use the token decision from above"
```

**If "Yes":**

> "Let's build your design from inspiration. You can pull colors from one site, typography from another, spacing from a third - and iterate until it feels right."

Proceed to Phase 3 (Inspiration Design Session). Do NOT skip Phase 3 for this branch.

**If "No":** Continue to Phase 2b.

---

### Phase 2b: Energy

> "What's the energy?"

Use **AskUserQuestion**:
```
question: "What's the energy?"
header: "Energy"
options:
  - label: "Move fast, break things"
    description: "Startup mode - momentum over perfection"
  - label: "Steady and solid"
    description: "Production mode - thorough validation"
  - label: "Learning/exploring"
    description: "Experimental mode - educational checkpoints"
```

**If user provides custom text:** Ask a clarifying AskUserQuestion.

---

### Phase 3: Inspiration Design Session

**Entry conditions:**
- User selected "Yes, I have reference sites" in Phase 2's inspiration AskUserQuestion, OR
- Craft was invoked with `RESUME_INSPIRATION=true` (resuming interrupted session)

**If RESUME_INSPIRATION=true:** Read `.craft/design/.inspiration-session`, check `phase` field, and jump to the matching sub-phase (3a if collecting, 3b if assembling, 3c if riffing). Present a brief summary of what's already captured before continuing.

**If starting fresh:** Create the session file and begin at Phase 3a.

#### Phase 3a: Source Collection

Initialize the session file (if starting fresh):

```bash
cat > "${CRAFT_PROJECT_ROOT:-.}/.craft/design/.inspiration-session" << 'YAML'
phase: "collecting"
started: "[ISO UTC timestamp]"
sources: []
assembly: null
riffs: []
YAML
```

**Source collection loop:**

> "Let's build your design from inspiration. Give me a URL to start with."

[User provides URL]

Ask which aspects to capture from this source:

Use **AskUserQuestion**:
```
question: "What should I capture from [URL]?"
header: "Aspects"
options:
  - label: "Whole vibe"
    description: "Colors, typography, spacing, shadows - everything visual"
  - label: "Colors only"
    description: "Color palette and usage"
  - label: "Typography only"
    description: "Font families, sizes, weights"
  - label: "Spacing & layout"
    description: "Spacing scale, component gaps, section padding"
  - label: "Pick specific aspects"
    description: "I'll tell you exactly what"
```

**If "Pick specific aspects":** Follow up with a free-text prompt: "Which aspects? (e.g., colors and shadows, typography and radius)". Parse the response into aspect categories.

**Aspect categories** (enum used throughout): `colors`, `typography`, `spacing`, `shadows`, `radius`, `borders`, `whole-vibe` (expands to all categories).

**Extract from the source site:**

Check if chrome-devtools MCP tools are available by looking for `navigate_page` tool.

**If chrome-devtools MCP is available (primary path):**

Step 1 - Navigate: Use `navigate_page` tool with the URL. Wait for page load.

Step 2 - Screenshot: Use `take_screenshot` tool. Save to `.craft/inspiration/screenshots/[domain-slug].png`.

Step 3 - Extract: Use `evaluate_script` tool with JavaScript that extracts the requested aspects. The script depends on which aspects were selected:

For **colors**: Run this JavaScript via `evaluate_script`:
```javascript
(() => {
  const colors = new Map();
  const els = document.querySelectorAll('*');
  for (const el of els) {
    const s = getComputedStyle(el);
    for (const prop of ['color', 'backgroundColor', 'borderColor', 'boxShadow']) {
      const v = s[prop];
      if (v && v !== 'rgba(0, 0, 0, 0)' && v !== 'transparent' && v !== 'rgb(0, 0, 0)') {
        const hex = rgbToHex(v);
        if (hex) colors.set(hex, (colors.get(hex) || 0) + 1);
      }
    }
  }
  const rootSheet = [...document.styleSheets].flatMap(s => {
    try { return [...s.cssRules]; } catch { return []; }
  });
  for (const rule of rootSheet) {
    if (rule.selectorText === ':root' && rule.style) {
      for (let i = 0; i < rule.style.length; i++) {
        const prop = rule.style[i];
        if (prop.startsWith('--') && /color|bg|surface|brand|primary|accent/i.test(prop)) {
          const val = rule.style.getPropertyValue(prop).trim();
          colors.set(val, (colors.get(val) || 0) + 100);
        }
      }
    }
  }
  function rgbToHex(rgb) {
    const m = rgb.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (!m) return null;
    return '#' + [m[1],m[2],m[3]].map(x => parseInt(x).toString(16).padStart(2,'0')).join('');
  }
  return [...colors.entries()].sort((a,b) => b[1] - a[1]).slice(0, 20).map(([hex, count]) => ({hex, count}));
})()
```

For **typography**: Run this JavaScript via `evaluate_script`:
```javascript
(() => {
  const fonts = new Map();
  const sizes = new Map();
  const weights = new Map();
  const els = document.querySelectorAll('h1,h2,h3,h4,h5,h6,p,span,a,li,button,label,input');
  for (const el of els) {
    const s = getComputedStyle(el);
    const family = s.fontFamily.split(',')[0].trim().replace(/['"]/g, '');
    fonts.set(family, (fonts.get(family) || 0) + 1);
    sizes.set(s.fontSize, (sizes.get(s.fontSize) || 0) + 1);
    weights.set(s.fontWeight, (weights.get(s.fontWeight) || 0) + 1);
  }
  return {
    fonts: [...fonts.entries()].sort((a,b) => b[1] - a[1]).slice(0, 5),
    sizes: [...sizes.entries()].sort((a,b) => b[1] - a[1]).slice(0, 10),
    weights: [...weights.entries()].sort((a,b) => b[1] - a[1]).slice(0, 5)
  };
})()
```

For **spacing**: Run this JavaScript via `evaluate_script`:
```javascript
(() => {
  const gaps = new Map();
  const paddings = new Map();
  const els = document.querySelectorAll('*');
  for (const el of els) {
    const s = getComputedStyle(el);
    for (const prop of ['gap', 'rowGap', 'columnGap']) {
      const v = s[prop];
      if (v && v !== 'normal' && v !== '0px') gaps.set(v, (gaps.get(v) || 0) + 1);
    }
    for (const prop of ['paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft']) {
      const v = s[prop];
      if (v && v !== '0px') paddings.set(v, (paddings.get(v) || 0) + 1);
    }
  }
  return {
    gaps: [...gaps.entries()].sort((a,b) => b[1] - a[1]).slice(0, 10),
    paddings: [...paddings.entries()].sort((a,b) => b[1] - a[1]).slice(0, 10)
  };
})()
```

For **shadows**: Run via `evaluate_script`:
```javascript
(() => {
  const shadows = new Map();
  for (const el of document.querySelectorAll('*')) {
    const s = getComputedStyle(el).boxShadow;
    if (s && s !== 'none') shadows.set(s, (shadows.get(s) || 0) + 1);
  }
  return [...shadows.entries()].sort((a,b) => b[1] - a[1]).slice(0, 5);
})()
```

For **radius**: Run via `evaluate_script`:
```javascript
(() => {
  const radii = new Map();
  for (const el of document.querySelectorAll('*')) {
    const r = getComputedStyle(el).borderRadius;
    if (r && r !== '0px') radii.set(r, (radii.get(r) || 0) + 1);
  }
  return [...radii.entries()].sort((a,b) => b[1] - a[1]).slice(0, 5);
})()
```

For **whole-vibe**: Run all of the above scripts sequentially.

Step 4 - Present extraction results to user:

> "From **[site name]**, I captured:
>
> [For each aspect category extracted:]
> **Colors:** [top 5-8 colors with hex values and usage counts]
> **Typography:** [font families, top sizes, weights]
> **Spacing:** [gap/padding patterns]
> [etc.]
>
> Screenshot saved to `.craft/inspiration/screenshots/[slug].png`"

Step 5 - Update the session file. Append a new entry to the `sources` array with the URL, site name (derive from domain - e.g., "linear.app" becomes "Linear"), aspects selected, and extracted values. Write the updated YAML to `.craft/design/.inspiration-session`.

**If chrome-devtools MCP is NOT available (WebFetch fallback):**

Use WebFetch to fetch the URL. Extract what's available from HTML/CSS:
- Colors from inline styles, style tags, and linked stylesheets (limited - only what's in the HTML response)
- Font families from CSS font-family declarations
- Note that spacing/shadows/radius are less reliable from static HTML

Present results with a caveat:
> "I used basic HTML extraction (browser tools aren't available). Results may be less accurate than full browser extraction. Consider restarting Claude Code to enable chrome-devtools MCP for better results."

Still update the session file the same way.

**After extraction, ask the loop question:**

Use **AskUserQuestion**:
```
question: "Source captured! What next?"
header: "Sources"
options:
  - label: "Add another source"
    description: "Pull from one more reference site"
  - label: "Assemble what I have"
    description: "Combine [N] sources into a token set"
  - label: "Done for now"
    description: "Save session, I'll come back later"
```

**If "Add another source":** Loop back to the URL prompt. Repeat the extraction flow.

**If "Assemble":** Update session file `phase` to `"assembling"`. Proceed to Phase 3b.

**If "Done for now":** Session file already has all state. Print:
> "Session saved! You have [N] source(s) captured. Run `/craft` anytime to resume where you left off."
Skip to Phase 4 (with `SKIP_TOKENS=1` since tokens aren't locked yet).

#### Phase 3b: Assembly + Interpretation

Read the session file. For each token category, merge values across all sources. When multiple sources contribute to the same category, use these merging rules:

**Color merging:**
- If one source was captured for colors and another wasn't, use the captured source's colors directly
- If multiple sources have colors, prefer the source whose colors were explicitly selected (not "whole vibe" default). If both explicitly selected, present both palettes and ask user to pick primary/surface/text

**Typography merging:**
- Use the most common font family across sources as the primary sans
- If sources have different fonts, present both and ask: "Which feels right for body text?"
- Mono font: use whichever source had a mono font, or fall back to "JetBrains Mono, monospace"

**Spacing merging:**
- Find the base unit by looking at the smallest common gap value across sources
- If sources use different spacing scales, note the difference and pick the one closest to a 4px base unit

**Shadows, radius, borders:**
- Use the source with the most entries in that category
- If roughly equal, present both and let user pick

**After merging, map to the tokens.yaml structure.** Use the template at `${CLAUDE_PLUGIN_ROOT}/templates/craft/design/tokens.yaml` as the target schema. For each section in the template, fill in the merged value if available, or leave the template default if no source provided that aspect.

Specifically, map extracted values to these token keys:
- `colors.primary` - the most prominent non-neutral color from color extraction
- `colors.background` - the most common background color (lightest or darkest depending on theme detection)
- `colors.surface` - second most common background color
- `colors.text-primary` - most common text color
- `colors.text-secondary` - second most common text color
- `typography.font-sans` - most common font family, with system fallbacks appended
- `typography.font-mono` - mono font if found, or template default
- `spacing.unit` - detected base unit (round to nearest 4px multiple)
- `radius.md` - most common border radius
- `shadows.md` - most common box shadow

**Creative interpretation:** After assembling tokens, write a 1-2 sentence creative description that names the combined feeling. This is NOT a technical summary - it's an evocative label. Examples:
- "Calm authority with warm accents - Linear's restraint meets Stripe's confidence"
- "Playful clarity - Vercel's precision softened by Notion's warmth"
- "Dark brutalism with generous breathing room"

Present the assembly:

> "I've combined your [N] sources into a unified design language:
>
> **[Creative interpretation]**
>
> **Colors:**
> | Token | Value | Source |
> |-------|-------|--------|
> | primary | #5E6AD2 | Linear |
> | background | #FFFFFF | Vercel |
> | surface | #FAFAF9 | Stripe |
> | text-primary | #171717 | Vercel |
> | text-secondary | #6B7280 | template default |
>
> **Typography:**
> | Token | Value | Source |
> |-------|-------|--------|
> | font-sans | Inter, -apple-system, ... | Vercel |
> | font-mono | Geist Mono, monospace | Vercel |
>
> **Spacing:**
> | Token | Value | Source |
> |-------|-------|--------|
> | unit | 4px | Linear |
>
> **Shadows:**
> [if captured]
>
> **Radius:**
> [if captured]
>
> Any values not captured from your sources use sensible defaults.
>
> How does this feel?"

Use **AskUserQuestion**:
```
question: "How does this feel?"
header: "Assembly"
options:
  - label: "Love it, lock these"
    description: "Write to tokens.yaml immediately"
  - label: "Close, let me adjust"
    description: "Riff on specific aspects"
  - label: "Add more sources first"
    description: "Go back to source collection"
  - label: "Save for later"
    description: "Keep the assembly, come back to finalize"
```

**If "Love it, lock these":** Jump to the Lock step below.

**If "Close, let me adjust":** Update session file `phase` to `"riffing"`. Proceed to Phase 3c.

**If "Add more sources":** Update session file `phase` to `"collecting"`. Loop back to Phase 3a's URL prompt.

**If "Save for later":** Update session file with current assembly. Print save message. Skip to Phase 4 with `SKIP_TOKENS=1`.

Update session file with the assembly (interpretation text + full token map).

#### Phase 3c: Riff Loop

The user adjusts, Claude responds. This is a conversational loop.

> "What would you like to adjust? (e.g., 'more warmth', 'less corporate', 'darker backgrounds', 'swap the font to Geist')"

[User provides free text adjustment]

**Interpret the adjustment.** The user speaks in vibes, not hex codes. Map their intent to specific token changes:

- "more warmth" -> shift colors toward amber/warm tones. Adjust primary/surface/accent colors.
- "less corporate" -> reduce spacing formality, consider rounder radius, softer shadows
- "darker" -> shift background toward darker values, invert text colors if needed
- "swap font to X" -> replace font-sans or font-mono with the specified font + system fallbacks
- "bolder" -> increase contrast between text-primary and background, consider heavier font weights
- Specific hex values -> apply directly to the mentioned token

After interpreting, present the updated tokens:

> "Got it - [echo back the interpretation]. Here's the update:
>
> **Changes:**
> | Token | Was | Now |
> |-------|-----|-----|
> | colors.primary | #5E6AD2 | #7C3AED |
> | colors.surface | #FAFAF9 | #FFFBF5 |
>
> **Updated interpretation:** [new creative description reflecting the riff]
>
> How's this?"

Use **AskUserQuestion**:
```
question: "How's this?"
header: "Riff"
options:
  - label: "Yeah THAT - lock it"
    description: "Write these tokens to tokens.yaml"
  - label: "Keep adjusting"
    description: "More riffing"
  - label: "Go back to assembly"
    description: "Start the riff from the original assembly"
  - label: "Save for later"
    description: "Keep progress, come back to finalize"
```

**If "Yeah THAT":** Proceed to Lock step.

**If "Keep adjusting":** Append the riff to session file's `riffs` array (input, response, token_changes). Loop back to the free text prompt.

**If "Go back to assembly":** Clear `riffs` array in session file. Update phase to `"assembling"`. Return to Phase 3b presentation.

**If "Save for later":** Update session file. Skip to Phase 4 with `SKIP_TOKENS=1`.

**Riff limit:** After 5 riffs without locking, gently nudge:
> "We've done [N] rounds of adjustments. These are looking refined. Ready to lock, or still want to adjust?"
This is a nudge, not a hard limit - the user can keep going.

#### Lock: Write Tokens

When the user confirms ("Love it, lock these" or "Yeah THAT"):

Step 1 - Read the current assembly tokens from the session file.

Step 2 - Read the tokens.yaml template from `${CLAUDE_PLUGIN_ROOT}/templates/craft/design/tokens.yaml`. This is the target structure.

Step 3 - Generate the final tokens.yaml by filling in the template structure with the assembled values. For each token in the template:
- If the assembly has a value for this token, use the assembly value
- If the assembly doesn't have a value, keep the template default
- Add a comment noting the source: `# from [source name]` or `# default`

Step 4 - Write the populated tokens.yaml to `.craft/design/tokens.yaml` using the Write tool.

Step 5 - Set `SKIP_TOKENS=0` so the setup script preserves the file.

Step 6 - Update `.craft/inspiration/sites.md` with all source URLs and the creative interpretation.

Step 7 - Delete the session file:
```bash
rm -f "${CRAFT_PROJECT_ROOT:-.}/.craft/design/.inspiration-session"
```

Step 8 - Confirm to user:
> "Design tokens locked! Your design language: **[creative interpretation]**
>
> [N] source(s) combined, [M] riff(s) applied. Tokens are in `.craft/design/tokens.yaml` and will be enforced from now on.
>
> Let's continue setup."

Proceed to Phase 4.

---

### Phase 4: Create Structure

Run the setup script with detected project type:

Export `SKIP_TOKENS` before calling the setup script. If the inspiration session already wrote tokens.yaml, prevent the setup script from overwriting it:

```bash
# If inspiration session already wrote tokens.yaml, tell setup to skip
if [ -f "${CRAFT_PROJECT_ROOT:-.}/.craft/design/tokens.yaml" ]; then
  SKIP_TOKENS=1
fi
SKIP_TOKENS=${SKIP_TOKENS:-0} ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-craft.sh [PROJECT_TYPE]
# PROJECT_TYPE is "ui" or "cli" from Phase 1
```

**For UI projects** (`setup-craft.sh ui`):
```
.craft/
├── backlog/                    ← Empty, ready for stories
├── cycles/                     ← Empty, ready for cycles
├── projects/                   ← Empty, ready for projects
├── inspiration/
│   ├── screenshots/            ← From Phase 3
│   ├── sites.md                ← Reference URLs
│   └── patterns.md             ← UI patterns to follow
├── design/
│   ├── tokens.yaml             ← Design tokens (colors, spacing, etc.)
│   ├── .confidence-signals.yaml ← Scanner confidence output (auto-generated)
│   ├── components.md           ← Component patterns
│   ├── locked.md               ← Approved UI patterns
│   └── animations.md           ← Motion patterns
├── project.md                  ← Project DNA (tech stack, conventions)
├── quality.yaml                ← Quality gates
├── settings.yaml               ← User preferences
├── .learnings.yaml             ← Captured learnings
└── .global-state               ← Runtime state
```

**For CLI/Backend projects** (`setup-craft.sh cli`):
```
.craft/
├── backlog/                    ← Empty, ready for stories
├── cycles/                     ← Empty, ready for cycles
├── projects/                   ← Empty, ready for projects
├── design/
│   ├── tokens.yaml             ← Naming conventions, file structure
│   ├── locked.md               ← Approved code patterns
│   └── schemas.md              ← Frontmatter schemas
├── project.md                  ← Project DNA (tech stack, conventions)
├── quality.yaml                ← Quality gates
├── settings.yaml               ← User preferences
├── .learnings.yaml             ← Captured learnings
└── .global-state               ← Runtime state
```

---

### Phase 5: Generate Rich Files

The setup script copies templates. Now **enhance them with agent findings**.

This is the key improvement — files are populated from actual project analysis, not templates with blanks.

#### project.md

**Use the agent's findings to generate a comprehensive project.md:**

```markdown
---
name: [project-name from package.json or directory]
type: [ui/cli/api]
package_manager: [detected]
---

# [Project Name]

[Brief description from README or inferred from structure]

## Tech Stack

- **Runtime:** [Node.js/Python/etc]
- **Language:** [TypeScript/JavaScript/etc] ([percentage]%)
- **Framework:** [Next.js/Express/etc or "None"]
- **Package manager:** [pnpm/npm/yarn/bun]
- **Testing:** [Vitest/Jest/etc or "None configured"]

## Architecture

[From agent's architecture discovery]

### Directory Structure
```
[Agent's directory tree]
```

### Entry Points
| Type | Path | Purpose |
|------|------|---------|
[Agent's entry points table]

## Conventions

### Naming
[From agent's convention extraction]

### Organization
[From agent's pattern discovery]

### Code Style
[From agent's style detection]

## File Counts

[From agent's file inventory]

## Energy Level

**[Selected energy]** — [Description from Phase 2]

## Quality Philosophy

[Based on energy level selection]
```

#### locked.md (or design/locked.md)

**Populate with patterns the agent discovered:**

```markdown
# Locked Patterns

Approved patterns for [Project Name]. Follow these exactly.

---

[For each pattern the agent discovered in Phase P5:]

## [Pattern Name]

**Location:** [example file path from agent findings]

**Description:** [what the pattern is]

**Key elements:**
- [element 1]
- [element 2]

**Example:**
[Code snippet or reference from agent findings]

---

[Continue for all significant patterns...]
```

#### tokens.yaml

**If SKIP_TOKENS was set (from-scratch or early UI):** tokens.yaml was not created by setup-craft.sh. Do NOT create it manually. Tokens can be added later via `/craft:init` with inspiration, or by creating tokens.yaml manually.

**If tokens were extracted from existing code (mid/mature UI):** Use the extracted values to populate tokens.yaml instead of the generic template values. Replace `{{PRIMARY_COLOR}}` etc. with actual extracted values.

**For CLI projects:** tokens.yaml was created from the CLI template (Project Conventions). Enhance with scanner findings as before.

**For UI projects (when tokens exist):** Use inspiration extraction results or defaults.

**For CLI projects:** Use agent's convention findings:

```yaml
# Conventions for [Project Name]
# Detected from codebase analysis

naming:
  files_components: "[detected]"    # e.g., "PascalCase"
  files_utilities: "[detected]"     # e.g., "kebab-case"
  functions: "[detected]"           # e.g., "camelCase"
  types: "[detected]"               # e.g., "PascalCase"
  constants: "[detected]"           # e.g., "SCREAMING_SNAKE"

file_structure:
  [from agent's directory organization findings]

code_style:
  semicolons: [detected]
  quotes: "[detected]"
  trailing_commas: [detected]
```

#### schemas.md (CLI projects only)

If the project has frontmatter-based files (like this plugin), document schemas found.
Otherwise, provide a template for future use.

#### settings.yaml and .learnings.yaml

These are standard templates — no customization needed from agent findings.

---

### Phase 6: First Cycle Kickoff

> "Craft is ready!
>
> **Project:** [name]
> **Type:** [ui/cli]
> **Energy:** [selected energy]
>
> I've documented [X] patterns in locked.md and captured your conventions.
>
> What's the first thing we're tackling?"

[User describes first feature/epic]

→ Creates first cycle
→ Enters Creative Mode
→ Starts riffing on stories

---

## Existing Codebase (Special Handling)

If user selected "Existing codebase" in Phase 2, the agent has already analyzed patterns.

After Phase 5 file generation:

> "I've extracted [X] patterns from your existing code and documented them in locked.md.
>
> Want to review what I captured before we continue?"

Use **AskUserQuestion**:
```
question: "Review captured patterns?"
header: "Review"
options:
  - label: "Show me what you found"
    description: "Review and approve patterns before continuing"
  - label: "Looks good, continue"
    description: "Trust the extraction, move to first cycle"
  - label: "I'll review later"
    description: "Continue now, I'll check locked.md myself"
```

**If "Show me what you found":**
Display the locked.md contents, walk through each pattern, allow edits.

---

## Energy Adaptations

| Energy | CLAUDE.md Tone | Validation | Checkpoints |
|--------|----------------|------------|-------------|
| **Move fast** | Minimal, momentum | Light | Ask when weird |
| **Steady solid** | Thorough | Full + tests | Every chunk |
| **Learning** | Educational | Full + explain | Every step |

---

## Remember

- **Quick setup** for projects with strong CLAUDE.md — just scaffolds `.craft/`, start building
- **Full setup** for deep analysis — agent scans, extracts patterns, populates rich files
- **Run once per project** — sets the foundation for everything
- **Can be updated later** — `/craft:update-docs` re-scans and creates/updates project.md
- **Can be adjusted later** — via `/craft:reflect`
