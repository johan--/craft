#!/bin/bash
# fixtures/with-failures.sh — .craft/ with a cycle and populated .failures file
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/fixtures/with-failures.sh"
#   dir=$(create_craft_with_failures)
#
# Creates a temp .craft/ structure modeled on real failure data:
#   - 4x missing-script-typecheck (knowledge_gap) across 3 stories → QUALIFIES
#   - 3x test-failure (iteration_noise) across 2 stories → EXCLUDED (noise)
#   - 2x read-missing-file (iteration_noise) across 2 stories → EXCLUDED (noise)
#   - 2x edit-unique-context (knowledge_gap) in 1 story → EXCLUDED (single story)
#   - 2x legacy entries without category/pattern → CLASSIFIED via fallback:
#       one missing-script (knowledge_gap → contributes to typecheck count)
#       one vitest output (iteration_noise → excluded)

FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$FIXTURES_DIR/with-cycle.sh"

create_craft_with_failures() {
  local dir
  dir=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
  local cycle_dir="$dir/.craft/cycles/1-test-cycle"
  local failures_file="$cycle_dir/.failures"

  # --- Write .failures entries ---
  # Format matches handle-tool-failure.py output: ---\nkey: value\n...
  # Entries are separated by \n---\n (leading --- per entry)

  cat > "$failures_file" << 'EOF'
---
timestamp: "2026-02-17 00:20:51"
story: "1-article-infrastructure"
chunk: "2"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-typecheck"
error: |
  npm error Missing script: "typecheck"
---
timestamp: "2026-02-17 00:22:10"
story: "1-article-infrastructure"
chunk: "3"
tool: "Bash"
category: "iteration_noise"
pattern: "test-failure"
error: |
  FAIL src/__tests__/article.test.ts
  AssertionError: expected undefined to equal 42
---
timestamp: "2026-02-17 00:25:33"
story: "2-writing-listing-page"
chunk: "1"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-typecheck"
error: |
  npm error Missing script: "typecheck"
---
timestamp: "2026-02-17 00:26:01"
story: "2-writing-listing-page"
chunk: "1"
tool: "Read"
category: "iteration_noise"
pattern: "read-missing-file"
error: |
  File does not exist: /src/components/WritingList.tsx
---
timestamp: "2026-02-17 00:28:44"
story: "2-writing-listing-page"
chunk: "2"
tool: "Bash"
category: "iteration_noise"
pattern: "test-failure"
error: |
  vitest: FAIL src/__tests__/listing.test.ts
  TypeError: Cannot read properties of undefined
---
timestamp: "2026-02-17 00:31:15"
story: "3-tag-filtering"
chunk: "1"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-typecheck"
error: |
  npm error Missing script: "typecheck"
---
timestamp: "2026-02-17 00:32:00"
story: "3-tag-filtering"
chunk: "2"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-typecheck"
error: |
  npm error Missing script: "typecheck"
---
timestamp: "2026-02-17 00:33:11"
story: "3-tag-filtering"
chunk: "3"
tool: "Edit"
category: "knowledge_gap"
pattern: "edit-unique-context"
error: |
  old_string not unique in file
---
timestamp: "2026-02-17 00:33:45"
story: "3-tag-filtering"
chunk: "3"
tool: "Edit"
category: "knowledge_gap"
pattern: "edit-unique-context"
error: |
  old_string not unique in file — 2 occurrences
---
timestamp: "2026-02-17 00:34:02"
story: "1-article-infrastructure"
chunk: "4"
tool: "Bash"
category: "iteration_noise"
pattern: "test-failure"
error: |
  FAIL src/__tests__/article.test.ts
  AssertionError: 3 assertions failed
---
timestamp: "2026-02-17 00:35:20"
story: "2-writing-listing-page"
chunk: "3"
tool: "Read"
category: "iteration_noise"
pattern: "read-missing-file"
error: |
  File does not exist: /src/lib/tags.ts
---
timestamp: "2026-02-17 00:38:00"
story: "1-article-infrastructure"
chunk: "1"
tool: "Bash"
error: |
  npm error Missing script: "typecheck"
---
timestamp: "2026-02-17 00:39:00"
story: "2-writing-listing-page"
chunk: "5"
tool: "Bash"
error: |
  FAIL src/__tests__/listing.test.ts
  AssertionError: expected 1 to equal 0
  at vitest
EOF

  # Update global state to point to this cycle
  cat > "$dir/.craft/.global-state" << EOF
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

  echo "$dir"
}
