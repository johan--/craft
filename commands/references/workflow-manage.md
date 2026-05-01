# Workflow: Manage

Reference for Steps 7-8 - archive workflows and mark sessions ready.

### Step 7: Archive Workflow

Move the workflow folder to `.archived/` using Bash:

```bash
mkdir -p "$PROJECT/.craft/workflows/.archived"
mv "$PROJECT/.craft/workflows/{slug}" "$PROJECT/.craft/workflows/.archived/{slug}"
```

> **Archived: {workflow name}**
> Moved to `.craft/workflows/.archived/{slug}/`
> Sessions and definition preserved. Not shown in dashboard.

---

### Step 8: Mark Sessions Ready

`/craft:workflow ready {workflow-name}` transitions sessions from `draft` to `ready`.

#### 8.1: Find Draft Sessions

Use **Glob** to find all sessions for the specified workflow. Filter for `status: draft`.

If no draft sessions found, report: "No draft sessions for {workflow name}."

#### 8.2: Select Sessions

Use **AskUserQuestion**:
```
question: "Which sessions to mark ready?"
header: "Ready"
multiSelect: true
options:
  - label: "All {N} draft sessions"
    description: "Mark everything ready for execution"
  - label: "{Session 1 name}"
    description: "draft"
  - label: "{Session 2 name}"
    description: "draft"
  - label: "{Session 3 name}"
    description: "draft"
```

#### 8.3: Update Sessions

For each selected session, update `session.md` frontmatter: `status: ready`.

Display:

```
Marked ready: {N} sessions

  [ready] {Session 1 name}
  [ready] {Session 2 name}
  ...

Run /craft:workflow continue to start executing.
```
