#!/bin/bash
# test-update-progress.sh — Tests for update-progress.py
# Validates PostToolUse hook: tracks touched files + timestamps in state

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

UPDATE_PROGRESS_SCRIPT="$SCRIPTS_DIR/update-progress.py"

# Helper: run update-progress.py with JSON input
run_update_progress() {
  local json="$1"
  shift
  env "$@" python3 "$UPDATE_PROGRESS_SCRIPT" <<< "$json" 2>/dev/null || true
}

# --- Tests ---

echo "=== test-update-progress.sh ==="
echo ""

# Test 1: Tracks Write tool file in TOUCHED_FILES
begin_test "Tracks Write tool file in TOUCHED_FILES"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
trap cleanup_test_dir EXIT

# Set up global state with active cycle and story
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
LAST_ACTIVITY=""
EOF

JSON="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/src/app.ts\"}}"
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON")

# Check that TOUCHED_FILES in cycle state contains the file
CYCLE_STATE="$TEST_DIR/.craft/cycles/1-test-cycle/.state"
source "$CYCLE_STATE"
assert_contains "TOUCHED_FILES has app.ts" "app.ts" "$TOUCHED_FILES"

cleanup_test_dir
echo ""

# Test 2: Updates LAST_ACTIVITY in global state
begin_test "Updates LAST_ACTIVITY in global state"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
LAST_ACTIVITY=""
EOF

JSON="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/src/app.ts\"}}"
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON")

GLOBAL_STATE="$TEST_DIR/.craft/.global-state"
# LAST_ACTIVITY should be set (non-empty)
LAST=$(grep "^LAST_ACTIVITY=" "$GLOBAL_STATE" | sed 's/LAST_ACTIVITY=//' | tr -d '"')
assert_not_eq "LAST_ACTIVITY is set" "" "$LAST"

cleanup_test_dir
echo ""

# Test 3: Skips .craft/ files — not tracked as touched
begin_test "Skips .craft/ files — not tracked as touched"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
LAST_ACTIVITY=""
EOF

JSON="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/.craft/design/tokens.yaml\"}}"
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON")

# TOUCHED_FILES should be empty (or not contain .craft/)
CYCLE_STATE="$TEST_DIR/.craft/cycles/1-test-cycle/.state"
source "$CYCLE_STATE"
assert_not_contains "TOUCHED_FILES does not have .craft file" ".craft/" "${TOUCHED_FILES:-}"

cleanup_test_dir
echo ""

# Test 4: No active story — no-op (no crash)
begin_test "No active story — no-op"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
LAST_ACTIVITY=""
EOF

JSON="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/src/app.ts\"}}"

set +e
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON")
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no active story" "0" "$EXIT_CODE"

cleanup_test_dir
echo ""

# Test 5: No .craft/ directory — exits cleanly
begin_test "No .craft/ directory — exits cleanly"

TEST_DIR=$(mktemp -d)

JSON='{"tool_name":"Write","tool_input":{"file_path":"/some/file.ts"}}'

set +e
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON")
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no .craft/" "0" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 6: Malformed JSON — exits 0 (no crash)
begin_test "Malformed JSON — exits 0"

set +e
RESULT=$(echo "not json" | python3 "$UPDATE_PROGRESS_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0 on malformed JSON" "0" "$EXIT_CODE"
echo ""

# Test 7: Multiple file touches — accumulates in TOUCHED_FILES
begin_test "Multiple file touches — accumulates"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
LAST_ACTIVITY=""
EOF

JSON1="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/src/app.ts\"}}"
JSON2="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/src/utils.ts\"}}"

(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON1")
(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && run_update_progress "$JSON2")

CYCLE_STATE="$TEST_DIR/.craft/cycles/1-test-cycle/.state"
source "$CYCLE_STATE"
assert_contains "TOUCHED_FILES has app.ts" "app.ts" "$TOUCHED_FILES"
assert_contains "TOUCHED_FILES has utils.ts" "utils.ts" "$TOUCHED_FILES"

cleanup_test_dir
echo ""

# Test 8: Always exits 0
begin_test "Always exits 0 — even with errors"

set +e
RESULT=$(echo "" | python3 "$UPDATE_PROGRESS_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0 on empty stdin" "0" "$EXIT_CODE"
echo ""

# --- Summary ---
finish_tests
