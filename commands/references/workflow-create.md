# Workflow: Create

Reference for `/craft:workflow create` - Step 1: Create a new workflow.

#### 1.1: Determine Source

Use **AskUserQuestion**:
```
question: "How do you want to create this workflow?"
header: "Source"
options:
  - label: "From scratch"
    description: "Define stages interactively"
  - label: "Import from file"
    description: "Parse an existing process document (Markdown, any project)"
  - label: "Import from URL"
    description: "Fetch and parse a remote process document"
```

**If "From scratch"** -> Jump to **Step 1.3** (Define Stages).
**If "Import from file"** -> Ask for file path. Jump to **Step 1.2**.
**If "Import from URL"** -> Fetch URL. Jump to **Step 1.2**.

#### 1.2: Parse Source Document

Read the source file. Identify stages by looking for:
- `### Stage N:` or `## Stage N:` headings
- `### Step N:` or `## Step N:` headings
- Numbered headings (`### 1. Title`, `## 1: Title`)
- Any `##` or `###` level heading pattern that repeats with incrementing numbers

For each stage found, extract:
- **Name** from the heading
- **Description** from the first paragraph
- **Produces** from "Artifacts:" or "What it produces:" sections
- **Key principles** from "Key principle:" sections
- **Sub-steps** from bullet lists or sub-headings within the stage

Present the parsed structure to the user:

> Found **{N} stages** in "{source file}":
> 1. {Stage 1 name} - {first line of description}
> 2. {Stage 2 name} - {first line}
> ...
>
> Does this look right?

Use **AskUserQuestion**:
```
question: "Does the parsed structure look correct?"
header: "Review"
options:
  - label: "Looks good"
    description: "Continue to configure execution modes"
  - label: "Needs adjustment"
    description: "I'll tell you what to fix"
```

**If "Looks good"** -> Jump to **Step 1.3**.
**If "Needs adjustment"** -> Let user describe changes, re-parse. Loop.

#### 1.3: Define Workflow Metadata

Ask for:
- **Workflow name** (will be slugified for the folder name)
- **Description** (one line)
- **Variables** - What changes per session? Ask: "What variables does this workflow need? (e.g., topic, domain, project)"

For each variable, capture:
- Name
- Description (what it represents)
- Optional default value

#### 1.4: Configure Execution Modes

Walk through each stage. For each one, suggest an execution mode based on the stage description:

- Stages mentioning "research", "investigate", "analyze" with a named agent -> suggest `agent`
- Stages mentioning "verify" with a named agent -> suggest `agent`
- Stages mentioning "synthesize", "combine", "integrate", "review", "decide" -> suggest `inline` (needs prior stage context)
- Stages mentioning "build", "write", "create", "implement" -> suggest `inline` (needs workflow context)
- Stages mentioning "apply", "fix", "update" -> suggest `inline`
- Stages with sub-passes or multiple agents -> suggest `agent`
- Default -> suggest `inline`

Use **AskUserQuestion** per stage:
```
question: "Stage {N}: {name} - How should this execute?"
header: "Execution"
options:
  - label: "{suggested mode} (Recommended)"
    description: "{description of what this mode does}"
  - label: "{alternative 1}"
    description: "{description}"
  - label: "{alternative 2}"
    description: "{description}"
  - label: "{alternative 3}"
    description: "{description}"
```

Execution modes:
| Mode | Behavior |
|------|----------|
| `agent` | Spawn isolated sub-agent, auto-advance on success. Use when the work is self-contained and doesn't need prior stage context. |
| `inline` | Orchestrator executes directly with full workflow context, auto-advance. Use when the stage builds on prior stages or needs context continuity. |
| `manual` | Present stage, wait for human to mark complete |
| `command` | Run a craft command via Skill tool |

**Trust is controlled at session level, not per stage.** In interactive mode, every stage pauses for confirmation. In auto mode, only `manual` stages pause. The execution mode controls *who does the work* - not whether there's a human gate.

**If "Agent":** Ask which agent to use. Suggest based on stage description:
- Research stages -> `craft:researcher`
- Verification stages -> `craft:verifier`
- Review stages -> project-specific agents if they exist (check `.claude/agents/`)
- Default -> generic agent with a prompt template

Also ask for a prompt template with `{variable}` placeholders.

**If "Inline":** Ask for a prompt/instructions template with `{variable}` placeholders. No agent selection needed - the orchestrator executes this directly.

**If "Command":** Ask which command (e.g., `craft:research`, `craft:research-verify`).

After configuring all stages, ask about sub-stages:

Use **AskUserQuestion**:
```
question: "Any stages that should have sub-stages? (e.g., a stage with two distinct passes)"
header: "Sub-stages"
options:
  - label: "No sub-stages needed"
    description: "Each stage is atomic"
  - label: "Yes, let me specify"
    description: "Some stages have distinct sub-passes"
```

#### 1.5: Write Definition

**If creating in new stage-file format** (default for all new workflows):

1. Create the workflow directories:
   ```bash
   mkdir -p "$PROJECT/.craft/workflows/{workflow-slug}/stages"
   mkdir -p "$PROJECT/.craft/workflows/{workflow-slug}/sessions"
   ```

2. Write `definition.md` as a routing table (see **New Definition Format Reference** in [references/workflow-formats.md](references/workflow-formats.md)).

3. For each stage, write `stages/NN-{slug}.md` where NN is zero-padded stage number and slug is the kebab-case stage name. Use the stage file format from the **New Definition Format Reference**.

4. The definition's `## Stages` table `File` column points to `stages/01-slug.md` etc.

**If creating in old monolithic format** (only for backward compat):

Create the workflow directory using Bash:

```bash
mkdir -p "$PROJECT/.craft/workflows/{workflow-slug}/sessions"
```

Write `definition.md` - see **Definition Format Reference** in [references/workflow-formats.md](references/workflow-formats.md) for the full format.

**Present result (both formats):**

> **Workflow created: {name}**
>
> Saved to `.craft/workflows/{slug}/definition.md`
> {N} stages | {agent_count} agent, {inline_count} inline, {manual_count} manual, {command_count} command
>
> Run `/craft:workflow run {slug}` to create your first session.
