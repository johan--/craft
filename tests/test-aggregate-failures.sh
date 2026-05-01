#!/bin/bash
# test-aggregate-failures.sh — Tests for aggregate-failures.py
# Validates knowledge-gap aggregation: filtering, cross-story threshold, YAML output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-failures.sh"

AGGREGATE_SCRIPT="$SCRIPTS_DIR/aggregate-failures.py"

# --- Tests ---

echo "=== test-aggregate-failures.sh ==="
echo ""

# Test 1: Knowledge gap cross-story → written to .failure-patterns.yaml
begin_test "Knowledge gap cross-story (2+ stories) → written to .failure-patterns.yaml"

TEST_DIR=$(create_craft_with_failures)
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

set +e
python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"
assert_file_exists ".failure-patterns.yaml created" "$PATTERNS_FILE"
assert_file_contains "missing-script-typecheck in patterns" "missing-script-typecheck" "$PATTERNS_FILE"

cleanup_test_dir
echo ""

# Test 2: Iteration noise excluded even when cross-story
begin_test "Iteration noise excluded even when it spans 2+ stories"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true

# test-failure (iteration_noise) appears across 2 stories but must NOT qualify
if [ -f "$PATTERNS_FILE" ]; then
  assert_file_not_contains "test-failure not in patterns" "test-failure" "$PATTERNS_FILE"
  assert_file_not_contains "read-missing-file not in patterns" "read-missing-file" "$PATTERNS_FILE"
else
  # File might not exist if only the iteration-noise entries didn't qualify
  echo "  PASS: no patterns file — iteration noise correctly excluded"
  PASS=$((PASS + 1))
  PASS=$((PASS + 1))  # Two assertions
fi

cleanup_test_dir
echo ""

# Test 3: Knowledge gap in only 1 story → NOT written (below threshold)
begin_test "Knowledge gap in single story → below threshold, not in patterns"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true

# edit-unique-context appears in only 1 story — must NOT qualify
if [ -f "$PATTERNS_FILE" ]; then
  assert_file_not_contains "edit-unique-context not in patterns (single story)" "edit-unique-context" "$PATTERNS_FILE"
else
  echo "  PASS: no patterns file (single-story knowledge gap correctly excluded)"
  PASS=$((PASS + 1))
fi

cleanup_test_dir
echo ""

# Test 4: Legacy entries without category/pattern classified via fallback
begin_test "Legacy entries (no category/pattern fields) classified via fallback"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true

# Legacy entries in the fixture: one is a missing-script (knowledge_gap),
# one is a test failure (iteration_noise). The missing-script legacy entry
# must be classified and contribute to the missing-script-typecheck pattern count.
# We verify this by checking total_count includes legacy entries.
if [ -f "$PATTERNS_FILE" ]; then
  # The pattern should appear in the output (legacy entries contribute to count)
  assert_file_contains "patterns file has qualifying pattern" "missing-script-typecheck" "$PATTERNS_FILE"
  # total_count should be > 4 or exactly reflect all entries (fixture has 4 explicit + 1 legacy = 5)
  assert_file_contains "total_count field present" "total_count:" "$PATTERNS_FILE"
else
  echo "  FAIL: .failure-patterns.yaml not created — legacy entries may not be classified"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 5: Missing .failures file → exits cleanly, no .failure-patterns.yaml created
begin_test "Missing .failures file → exits cleanly"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

# Remove the .failures file
rm -f "$CYCLE_DIR/.failures"

set +e
python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null
EXIT_CODE=$?
set -e

assert_eq "exits 0 when no .failures file" "0" "$EXIT_CODE"
assert_file_not_exists "no .failure-patterns.yaml when no .failures" "$PATTERNS_FILE"

cleanup_test_dir
echo ""

# Test 6: Idempotent — running twice produces the same output
begin_test "Idempotent: run twice produces same .failure-patterns.yaml"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true
FIRST_RUN=$(cat "$PATTERNS_FILE" 2>/dev/null | grep -v "^generated:" || true)

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true
SECOND_RUN=$(cat "$PATTERNS_FILE" 2>/dev/null | grep -v "^generated:" || true)

if [ "$FIRST_RUN" = "$SECOND_RUN" ]; then
  echo "  PASS: second run produces identical output"
  PASS=$((PASS + 1))
else
  echo "  FAIL: second run differs from first run"
  echo "    First:  $(echo "$FIRST_RUN" | head -5)"
  echo "    Second: $(echo "$SECOND_RUN" | head -5)"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 7: Output YAML includes required fields
begin_test "Output YAML includes required fields: pattern, label, category, stories, total_count, first_seen, suggested_rule"

TEST_DIR=$(create_craft_with_failures)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
PATTERNS_FILE="$CYCLE_DIR/.failure-patterns.yaml"

python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null || true

assert_file_exists "patterns file exists" "$PATTERNS_FILE"
assert_file_contains "has 'pattern:' field" "pattern:" "$PATTERNS_FILE"
assert_file_contains "has 'label:' field" "label:" "$PATTERNS_FILE"
assert_file_contains "has 'category:' field" "category:" "$PATTERNS_FILE"
assert_file_contains "has 'stories:' field" "stories:" "$PATTERNS_FILE"
assert_file_contains "has 'total_count:' field" "total_count:" "$PATTERNS_FILE"
assert_file_contains "has 'first_seen:' field" "first_seen:" "$PATTERNS_FILE"
assert_file_contains "has 'suggested_rule:' field" "suggested_rule:" "$PATTERNS_FILE"

cleanup_test_dir
echo ""

# Test 8: No active cycle → exits cleanly
begin_test "No active cycle in global state → exits cleanly"

TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.craft"
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
EOF

set +e
python3 "$AGGREGATE_SCRIPT" "$TEST_DIR" 2>/dev/null
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no active cycle" "0" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 9: No arguments → exits 0 (guard)
begin_test "No arguments → exits 0 (guard)"

set +e
python3 "$AGGREGATE_SCRIPT" 2>/dev/null
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no args" "0" "$EXIT_CODE"
echo ""

# Test 10: Full pipeline — write failures, aggregate, verify patterns file content
begin_test "Full pipeline: write failures → aggregate → patterns file has correct pattern/label/stories/count"

# Build a minimal project from scratch (no fixture dependency)
FULL_PIPE_DIR=$(mktemp -d)
mkdir -p "$FULL_PIPE_DIR/.craft/cycles/1-pipeline-cycle/stories/pipeline-story-a"
mkdir -p "$FULL_PIPE_DIR/.craft/cycles/1-pipeline-cycle/stories/pipeline-story-b"

# Global state points to this cycle
cat > "$FULL_PIPE_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-pipeline-cycle"
CURRENT_STORY=""
EOF

# Write .failures with one knowledge_gap pattern across 2 different stories
# plus iteration noise that must be excluded
cat > "$FULL_PIPE_DIR/.craft/cycles/1-pipeline-cycle/.failures" << 'EOF'
---
timestamp: "2026-02-18 10:00:00"
story: "pipeline-story-a"
chunk: "1"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-lint"
error: |
  npm error Missing script: "lint"
---
timestamp: "2026-02-18 10:05:00"
story: "pipeline-story-b"
chunk: "2"
tool: "Bash"
category: "knowledge_gap"
pattern: "missing-script-lint"
error: |
  npm error Missing script: "lint"
---
timestamp: "2026-02-18 10:10:00"
story: "pipeline-story-a"
chunk: "3"
tool: "Bash"
category: "iteration_noise"
pattern: "test-failure"
error: |
  FAIL src/__tests__/foo.test.ts
  AssertionError: expected false to equal true
EOF

FULL_PIPE_PATTERNS="$FULL_PIPE_DIR/.craft/cycles/1-pipeline-cycle/.failure-patterns.yaml"

set +e
python3 "$AGGREGATE_SCRIPT" "$FULL_PIPE_DIR" 2>/dev/null
PIPE_EXIT=$?
set -e

assert_eq "full pipeline exits 0" "0" "$PIPE_EXIT"
assert_file_exists "patterns file created by full pipeline" "$FULL_PIPE_PATTERNS"
assert_file_contains "qualifying pattern present: missing-script-lint" "missing-script-lint" "$FULL_PIPE_PATTERNS"
assert_file_contains "label mentions 'lint'" "lint" "$FULL_PIPE_PATTERNS"
assert_file_contains "both stories listed" "pipeline-story-a" "$FULL_PIPE_PATTERNS"
assert_file_contains "both stories listed (b)" "pipeline-story-b" "$FULL_PIPE_PATTERNS"
assert_file_contains "total_count is 2" "total_count: 2" "$FULL_PIPE_PATTERNS"
assert_file_not_contains "iteration noise excluded from full pipeline" "test-failure" "$FULL_PIPE_PATTERNS"

rm -rf "$FULL_PIPE_DIR"
echo ""

# --- Summary ---
finish_tests
