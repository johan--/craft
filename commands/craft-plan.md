---
name: craft:plan
description: "Dedicated planning hub. Three modes: (1) /craft:plan <filename> plans a specific request, (2) /craft:plan request auto-picks or lists pending requests, (3) /craft:plan with no args asks what to plan."
argument-hint: "[request-filename | request]"
---

# Plan

Dedicated planning entry point. Routes to the full `story-new` or `cycle-design` flow with request context. Does NOT offer implementation — the flow ends after planning.

## Project Root

Use `$CRAFT_PROJECT_ROOT` (set at session start) as the base path for all `.craft/` references. If not set, resolve by walking up from PWD to find the nearest `.craft/.global-state`.

## Flow

### Step 0: Determine Invocation Mode

Parse args to determine which of the three modes to use:

**Mode A — Specific request file:** Args contain a filename (not the keyword `request`). Resolve the path:

Set `PROJECT` to `${CRAFT_PROJECT_ROOT:-.}`. Resolve the request file path: `$PROJECT/.craft/requests/[args].md` (append `.md` if not already present).

Use **Read** to check if the request file exists.

If the file exists → jump to **Step 2**.
If not → show error: "Request file not found: `$ARGS`. Check `.craft/requests/` for available files." Then fall through to **Step 1**.

**Mode B — `request` keyword:** Args are exactly `request`. Count pending requests:

Use **Glob** with pattern `$PROJECT/.craft/requests/*.md` → count results → `request_count`.

- If count = 0 → show "No pending requests." Fall through to **Step 1** with the "Plan a pending request" option removed.
- If count = 1 → auto-select the single file, set `REQ_FILE`, jump to **Step 2**.
- If count > 1 → jump to **Step 1b**.

**Mode C — No args:** Jump to **Step 1**.

### Step 1: What to Plan

Count pending requests and backlog stories needing chunks:

Use **Glob** with pattern `$PROJECT/.craft/requests/*.md` → count results → `requests_count`.

Use **Glob** with pattern `$PROJECT/.craft/backlog/*.md` to list backlog stories.
For each story, use **Read** (with `limit: 15` for frontmatter only). If `status: planning` AND `chunks_total: 0`, increment `backlog_needs_planning`.

Use **AskUserQuestion** — show only the options that have items:

```
question: "What would you like to plan?"
header: "Plan"
options:
  - label: "Plan a pending request"
    description: "[N] request(s) waiting"
    → only show if requests_count > 0
    → routes to: Step 1b
  - label: "Plan a new idea"
    description: "Capture and plan a new story from scratch"
    → always shown
    → routes to: Step 3 with source=new-idea
  - label: "Plan a backlog story"
    description: "[N] story/stories need chunks"
    → only show if backlog_needs_planning > 0
    → routes to: Step 1c
```

### Step 1b: Pick a Request

List pending requests using the same listing pattern from `craft.md` Step 5b.1:

Use **Glob** with pattern `$PROJECT/.craft/requests/*.md` to list request files.
For each file, use **Read** to read it and extract `title` and `created` from the YAML frontmatter. If `title` is missing, use "Untitled". If `created` is missing, use "unknown date".

Use **AskUserQuestion**:

```
question: "Which request to plan?"
header: "Requests"
options:
  - label: "[Request 1 title]"
    description: "Submitted [date] — [filename]"
  ...
  - label: "Back to options"
    description: "Return to planning menu"
```

If "Back to options" → return to **Step 1**.
Otherwise → set `REQ_FILE` to the selected request path, jump to **Step 2**.

### Step 1c: Pick a Backlog Story

List backlog stories with `status: planning` AND `chunks_total: 0`:

Use **Glob** with pattern `$PROJECT/.craft/backlog/*.md` to list backlog stories.
For each story, use **Read** (with `limit: 15` for frontmatter only). If `status: planning` AND `chunks_total: 0`, extract `title` and include in the picker.

Use **AskUserQuestion**:

```
question: "Which backlog story needs planning?"
header: "Backlog"
options:
  - label: "[Story 1 title]"
    description: "[story-name].md"
  ...
  - label: "Back to options"
    description: "Return to planning menu"
```

If "Back to options" → return to **Step 1**.

Otherwise → invoke plan-chunks directly (the story already exists, no need for story-new):

→ **INVOKE `craft:plan-chunks` using the Skill tool** with args:

```
"[story file path] — Planning backlog story.
DIRECTION_CONFIRMED: true
STORY: [story-name]
PLAN_ONLY: true"
```

After plan-chunks completes → "Story planned and ready. Planning complete." Done. (No request to process.)

### Step 2: Read and Assess Request

Read the full request file (`REQ_FILE`). The body is everything after the YAML frontmatter closing `---`. Present the content and assess scope using the same rules from `craft.md` Step 5b.2:

**Scope assessment rules (use your judgment):**
- **Single story** — one specific change, feature, or fix. Most requests will be this.
- **Cycle-level** — multiple related changes spanning several stories.
- **Needs creative exploration** — vague or open-ended enough for creative-spark first.

Present the assessment:

> "**Request:** [title]
>
> [Full request body]
>
> **My assessment:** This looks like [a single story / a cycle-level change / something worth exploring creatively]. I'd recommend [routing] because [brief reasoning]."

Use **AskUserQuestion**:

```
question: "How should we plan this request?"
header: "Route"
options:
  - label: "[Recommended option] (Recommended)"
    description: "[matches assessment]"
  - label: "Create story"
    description: "Route to story-new with request as spark"
  - label: "Create cycle"
    description: "This is big enough for a full cycle"
  - label: "Explore creatively first"
    description: "Route to story-new in creative mode"
```

Show only 3-4 options — the recommended option replaces its duplicate (don't show the same option twice).

### Step 3: Route to Planning Flow

All invocations include `PLAN_ONLY: true` to suppress implementation offers.

**If "Create story" or recommended is "Create story":**

→ **INVOKE `craft:craft-story-new` using the Skill tool** with args:

```
"[request title] — Request from .craft/requests/[filename].
REQUEST_BODY: [full body text of the request file]
SKIP_STEP_1: true
PLAN_ONLY: true"
```

After story-new completes, note the created story name for **Step 4**.

**If "Create cycle":**

→ **INVOKE `craft:craft-cycle-design` using the Skill tool** with args:

```
"[request title] — Request from .craft/requests/[filename].
REQUEST_BODY: [full body text of the request file]
PLAN_ONLY: true"
```

After cycle-design completes, note the created cycle name for **Step 4**.

**If "Explore creatively first":**

→ **INVOKE `craft:craft-story-new` using the Skill tool** with args:

```
"[request title] — Request from .craft/requests/[filename].
REQUEST_BODY: [full body text of the request file]
USER_PREFERS: creative
PLAN_ONLY: true"
```

After story-new completes, note the created story name for **Step 4**.

**If "Plan a new idea" (from Step 1, no request):**

→ **INVOKE `craft:craft-story-new` using the Skill tool** with args:

```
"PLAN_ONLY: true"
```

After story-new completes → "Story planned and ready. Planning complete." Done. (No request to process.)

### Step 4: Process Request and Complete

After the routed command completes and a story or cycle has been created, move the request file to processed:

```bash
${CLAUDE_PLUGIN_ROOT}/hooks/scripts/process-request.sh \
  "$REQ_FILE" \
  "[story|cycle]" \
  "[created-story-or-cycle-name]" \
  "${CRAFT_PROJECT_ROOT:-.}"
```

> "Request planned and processed. Planning complete."

Done.

## Remember

- **Planning only** — never offer implementation. `PLAN_ONLY: true` ensures plan-chunks skips its S-6 implementation offer.
- **Three modes** — parse args to determine: specific filename, `request` keyword, or bare invocation.
- **Reuse existing flows** — route to story-new and cycle-design, don't replicate their logic.
- **Process after planning** — request files move to `processed/` only after planning completes successfully.
- **Context Passing Standard** — use labeled field format for all skill invocations (`PLAN_ONLY:`, `SKIP_STEP_1:`, `REQUEST_BODY:`, etc.).
