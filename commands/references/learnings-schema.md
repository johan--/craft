# Learnings Schema Reference

The `.craft/.learnings.yaml` file captures patterns, corrections, and conventions discovered during story implementation. Written incrementally after each chunk (Step 4 post-chunk check) and verified at story completion (Step 5). The file is global - a single project-level file that accumulates across cycles and is drained when reflection runs (offered at cycle-complete, or any time via `/craft:reflect`).

## Data Structure

Six categories, each following the same evidence/occurrence pattern:

```yaml
# .craft/.learnings.yaml

conventions:
  - pattern: "Use Zustand for client state"
    evidence:
      - source: user_statement
        quote: "We use Zustand here"
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending
    section: stack  # stack | patterns | preferences

enforcements:
  - pattern: "Never use 'any' type"
    evidence:
      - source: user_correction
        quote: "Don't use any, type it properly"
        file: "[file where correction happened]"
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending
    rule_name: no-any-type
    paths: ["**/*.ts", "**/*.tsx"]

behaviors:
  - pattern: "Never skip pre-existing code"
    evidence:
      - source: user_correction
        quote: "Don't skip that"
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending

automations:
  - name: prettier-on-edit
    trigger: "After editing .tsx files"
    action: "prettier --write"
    evidence:
      - source: user_request
        quote: "Always run prettier after"
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending
    hook_event: PostToolUse
    hook_matcher: "Write|Edit"

skills:
  - name: our-form-pattern
    description: "How we build forms..."
    evidence:
      - source: user_explanation
        quote: "Let me explain how we do forms..."
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending
    canonical_example: "[reference file]"
    key_points: [...]

workflows:
  - name: create-component
    description: "Create component with test"
    steps: [...]
    evidence:
      - source: repeated_pattern
        files: [...]
        story: "[current story]"
        date: 2026-02-03
    occurrences: 1
    status: pending
    allowed_tools: [Read, Write, Edit]
```

## Merge Logic

- Read existing file first
- For existing patterns: increment `occurrences`, add new evidence entry
- For new patterns: add as new entry with `occurrences: 1`

## Evidence Sources

| Source | When |
|--------|------|
| `user_statement` | User states a preference or convention |
| `user_correction` | User corrects the agent's approach |
| `user_request` | User asks for a specific automation |
| `user_explanation` | User explains a pattern or process |
| `repeated_pattern` | Agent observes a recurring pattern in code |
| `cli_error` | Infrastructure error captured by validate-chunk Phase 4 |
