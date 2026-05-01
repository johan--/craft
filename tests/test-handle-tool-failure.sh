#!/bin/bash
# test-handle-tool-failure.sh — Tests for handle-tool-failure.py
# Validates PostToolUseFailure hook: failure logging + helpful hints

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

HANDLE_FAILURE_SCRIPT="$SCRIPTS_DIR/handle-tool-failure.py"

# Helper: run handle-tool-failure.py with JSON input
run_handle_failure() {
  local json="$1"
  shift
  env "$@" python3 "$HANDLE_FAILURE_SCRIPT" <<< "$json" 2>/dev/null || true
}

# --- Tests ---

echo "=== test-handle-tool-failure.sh ==="
echo ""

# Test 1: Logs failure to .failures file
begin_test "Logs failure to .failures file"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# BUG NOTE: handle-tool-failure.py uses relative path os.path.join(".craft", ".global-state")
# (line 37), so we MUST cd to the project root for it to work.
# This is a known bug — same class as export-progress.sh relative path issue.

# Set global state at project root
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="2"
EOF

JSON='{"tool_name":"Bash","error":"command not found: foobar"}'
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")

# Check that .failures file was created
FAILURES_FILE="$CYCLE_DIR/.failures"
assert_file_exists ".failures file created" "$FAILURES_FILE"

# Check contents
assert_file_contains "failure log has tool name" "Bash" "$FAILURES_FILE"
assert_file_contains "failure log has error" "command not found" "$FAILURES_FILE"
assert_file_contains "failure log has story" "test-story" "$FAILURES_FILE"

cleanup_test_dir
echo ""

# Test 2: Suggests recovery — Bash command not found
begin_test "Suggests recovery — Bash command not found"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"command not found: npm"}'
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")
assert_contains "suggests command not found hint" "Command not found" "$RESULT"

cleanup_test_dir
echo ""

# Test 3: Suggests recovery — Edit not unique
begin_test "Suggests recovery — Edit not unique"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Edit","error":"old_string not unique in file"}'
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")
assert_contains "suggests edit not-unique hint" "not unique" "$RESULT"

cleanup_test_dir
echo ""

# Test 4: No active story — no-op (no failure log)
begin_test "No active story — no-op"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
EOF

JSON='{"tool_name":"Bash","error":"some error"}'

set +e
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no active story" "0" "$EXIT_CODE"
# .failures should NOT be created
assert_file_not_exists "no .failures without active story" "$TEST_DIR/.craft/cycles/1-test-cycle/.failures"

cleanup_test_dir
echo ""

# Test 5: No .craft/ at CWD — exits cleanly
# BUG: This test documents that handle-tool-failure.py uses relative paths.
# If CWD has no .craft/, the script can't find global state and exits cleanly.
begin_test "No .craft/ at CWD — exits cleanly"

TEST_DIR=$(mktemp -d)

JSON='{"tool_name":"Bash","error":"some error"}'

set +e
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no .craft/" "0" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# ---- REGRESSION TEST (Story 9): Relative .craft path ----
# handle-tool-failure.py uses os.path.join(".craft", ".global-state") (line 37)
# and os.path.join(".craft", "cycles", ..., ".failures") (line 52).
# When CWD ≠ project root, the script can't find state and exits early
# even when CRAFT_PROJECT_ROOT is correctly set.
begin_test "REGRESSION: handle-tool-failure uses CRAFT_PROJECT_ROOT, not relative .craft"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="2"
EOF

# Create a subdirectory WITHOUT .craft/
mkdir -p "$TEST_DIR/src/components"

JSON='{"tool_name":"Bash","error":"test failure from subdir"}'

# Run from SUBDIRECTORY with CRAFT_PROJECT_ROOT pointing to correct root
# The script SHOULD read state from CRAFT_PROJECT_ROOT/.craft/, not CWD/.craft/
(cd "$TEST_DIR/src/components" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && \
  python3 "$HANDLE_FAILURE_SCRIPT" <<< "$JSON" 2>/dev/null || true)

# The failure should be logged at the PROJECT ROOT, not CWD
FAILURES_FILE="$CYCLE_DIR/.failures"
if [ -f "$FAILURES_FILE" ]; then
  assert_file_contains "failure logged to project root" "test failure from subdir" "$FAILURES_FILE"
else
  echo "  FAIL: .failures NOT created at project root"
  echo "    expected: $FAILURES_FILE"
  echo "    BUG: script uses relative '.craft' path (line 37, 52), ignoring CRAFT_PROJECT_ROOT"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 7: Malformed JSON — exits 0
begin_test "Malformed JSON — exits 0"

set +e
RESULT=$(echo "not json" | python3 "$HANDLE_FAILURE_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0 on malformed JSON" "0" "$EXIT_CODE"
echo ""

# --- Classification Tests ---

# Helper: run handle-tool-failure and return the .failures file content
run_and_get_failures() {
  local test_dir="$1"
  local json="$2"
  local cycle_dir="$test_dir/.craft/cycles/1-test-cycle"
  (cd "$test_dir" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$json")
  cat "$cycle_dir/.failures" 2>/dev/null || true
}

# Test 8: category and pattern fields written to .failures
begin_test "Classification: failure entry includes category and pattern fields"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"command not found: npm"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "failure entry has category field" 'category:' "$FAILURES"
assert_contains "failure entry has pattern field" 'pattern:' "$FAILURES"

cleanup_test_dir
echo ""

# Test 9: Missing script → knowledge_gap + missing-script-{script}
begin_test "Classification: missing script → knowledge_gap + missing-script-{script}"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"npm error Missing script: \"typecheck\""}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "missing script → knowledge_gap" 'knowledge_gap' "$FAILURES"
assert_contains "missing script → missing-script-typecheck" 'missing-script-typecheck' "$FAILURES"

cleanup_test_dir
echo ""

# Test 10: Bash command not found → knowledge_gap + bash-command-not-found
begin_test "Classification: bash command not found → knowledge_gap"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"zsh: command not found: pnpm"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "bash command not found → knowledge_gap" 'knowledge_gap' "$FAILURES"
assert_contains "bash command not found → bash-command-not-found" 'bash-command-not-found' "$FAILURES"

cleanup_test_dir
echo ""

# Test 11: Test runner output → iteration_noise + test-failure
begin_test "Classification: vitest output → iteration_noise + test-failure"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"FAIL src/__tests__/foo.test.ts\n AssertionError: expected 1 to equal 2\n  at vitest"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "vitest output → iteration_noise" 'iteration_noise' "$FAILURES"
assert_contains "vitest output → test-failure" 'test-failure' "$FAILURES"

cleanup_test_dir
echo ""

# Test 12: TypeScript error → iteration_noise + typescript-error
begin_test "Classification: TypeScript error → iteration_noise + typescript-error"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"src/foo.ts(12,3): error TS2345: Argument of type '\''string'\'' is not assignable to parameter"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "TS error → iteration_noise" 'iteration_noise' "$FAILURES"
assert_contains "TS error → typescript-error" 'typescript-error' "$FAILURES"

cleanup_test_dir
echo ""

# Test 13: Read "does not exist" → iteration_noise + read-missing-file
begin_test "Classification: Read does-not-exist → iteration_noise + read-missing-file"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Read","error":"File does not exist: /src/components/Foo.tsx"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "Read does-not-exist → iteration_noise" 'iteration_noise' "$FAILURES"
assert_contains "Read does-not-exist → read-missing-file" 'read-missing-file' "$FAILURES"

cleanup_test_dir
echo ""

# Test 14: Failed to resolve import → iteration_noise + import-not-yet-created
begin_test "Classification: Failed to resolve import → iteration_noise + import-not-yet-created"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"Failed to resolve import \"@/components/Button\" from \"src/App.tsx\""}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "import-not-yet-created → iteration_noise" 'iteration_noise' "$FAILURES"
assert_contains "import-not-yet-created pattern" 'import-not-yet-created' "$FAILURES"

cleanup_test_dir
echo ""

# Test 15: Edit not unique → knowledge_gap + edit-unique-context
begin_test "Classification: Edit not-unique → knowledge_gap + edit-unique-context"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Edit","error":"old_string not unique in file — 3 occurrences found"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "edit not-unique → knowledge_gap" 'knowledge_gap' "$FAILURES"
assert_contains "edit not-unique → edit-unique-context" 'edit-unique-context' "$FAILURES"

cleanup_test_dir
echo ""

# Test 16: Edit not found → knowledge_gap + edit-not-found
begin_test "Classification: Edit not-found → knowledge_gap + edit-not-found"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Edit","error":"String not found in file"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "edit not-found → knowledge_gap" 'knowledge_gap' "$FAILURES"
assert_contains "edit not-found → edit-not-found" 'edit-not-found' "$FAILURES"

cleanup_test_dir
echo ""

# Test 17: Unknown failure → iteration_noise + {tool}-unknown
begin_test "Classification: unknown failure → iteration_noise + {tool}-unknown"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Write","error":"Some completely unknown error that matches nothing"}'
FAILURES=$(run_and_get_failures "$TEST_DIR" "$JSON")
assert_contains "unknown → iteration_noise" 'iteration_noise' "$FAILURES"
assert_contains "unknown → write-unknown" 'write-unknown' "$FAILURES"

cleanup_test_dir
echo ""

# Test 18: category/pattern appear BETWEEN tool and error fields
begin_test "Classification: category and pattern are between tool and error in YAML"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CURRENT_CHUNK="1"
EOF

JSON='{"tool_name":"Bash","error":"command not found: jest"}'
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_handle_failure "$JSON")

FAILURES_FILE="$CYCLE_DIR/.failures"
# Extract the order: tool line number vs category line number vs error line number
TOOL_LINE=$(grep -n 'tool:' "$FAILURES_FILE" | head -1 | cut -d: -f1)
CATEGORY_LINE=$(grep -n 'category:' "$FAILURES_FILE" | head -1 | cut -d: -f1)
ERROR_LINE=$(grep -n 'error:' "$FAILURES_FILE" | head -1 | cut -d: -f1)

if [ "$TOOL_LINE" -lt "$CATEGORY_LINE" ] && [ "$CATEGORY_LINE" -lt "$ERROR_LINE" ]; then
  echo "  PASS: tool < category < error ordering preserved"
  PASS=$((PASS + 1))
else
  echo "  FAIL: wrong field ordering"
  echo "    tool line: $TOOL_LINE, category line: $CATEGORY_LINE, error line: $ERROR_LINE"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
