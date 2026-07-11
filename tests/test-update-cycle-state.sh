#!/bin/bash
# test-update-cycle-state.sh — Tests for update-cycle-state.sh
# Validates key-value setter for cycle .state files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

UPDATE_CYCLE_STATE_SCRIPT="$SCRIPTS_DIR/update-cycle-state.sh"

# --- Tests ---

echo "=== test-update-cycle-state.sh ==="
echo ""

# Test 1: Updates existing key in .state
begin_test "Updates existing key in .state"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_STORY "login-form"

source "$CYCLE_DIR/.state"
assert_eq "CURRENT_STORY is login-form" "login-form" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 2: Updates CURRENT_CHUNK (numeric value)
begin_test "Updates CURRENT_CHUNK"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_CHUNK "3"

source "$CYCLE_DIR/.state"
assert_eq "CURRENT_CHUNK is 3" "3" "$CURRENT_CHUNK"

cleanup_test_dir
echo ""

# Test 3: Clears a key
begin_test "Clears a key"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_STORY "some-story"
bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_STORY ""

source "$CYCLE_DIR/.state"
assert_eq "CURRENT_STORY cleared" "" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 4: Creates .state file if missing
begin_test "Creates .state file if missing"

TEST_DIR=$(mktemp -d)
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
mkdir -p "$CYCLE_DIR"
# No .state file

bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_STORY "test"

assert_file_exists ".state created" "$CYCLE_DIR/.state"
source "$CYCLE_DIR/.state"
assert_eq "CURRENT_STORY is test" "test" "$CURRENT_STORY"

rm -rf "$TEST_DIR"
echo ""

# Test 5: No arguments — exits 1
begin_test "No arguments — exits 1"

set +e
RESULT=$(bash "$UPDATE_CYCLE_STATE_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"
echo ""

# Test 6: BUG — Missing cycle dir with name-based fallback
# When given an absolute path like /nonexistent/cycle, the script SHOULD exit 1.
# But it falls through to find-workshop.sh, finds the REAL project,
# then `find ... -name "*cycle*"` wildcard matches real cycle directories.
# Same class of env contamination bug as complete-chunk.sh.
# With env isolation, it correctly exits 1.
begin_test "BUG: Missing cycle dir — exits 1 (env isolated)"

TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.craft"

set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && unset PROJECT_ROOT && bash "$UPDATE_CYCLE_STATE_SCRIPT" "/nonexistent/cycle" CURRENT_STORY "test" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing cycle dir (isolated)" "1" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 7: Multiple sequential updates — all preserved
begin_test "Multiple sequential updates — all preserved"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_STORY "login"
bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" CURRENT_CHUNK "2"
bash "$UPDATE_CYCLE_STATE_SCRIPT" "$CYCLE_DIR" TOTAL_CHUNKS "5"

source "$CYCLE_DIR/.state"
assert_eq "CURRENT_STORY is login" "login" "$CURRENT_STORY"
assert_eq "CURRENT_CHUNK is 2" "2" "$CURRENT_CHUNK"
assert_eq "TOTAL_CHUNKS is 5" "5" "$TOTAL_CHUNKS"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
