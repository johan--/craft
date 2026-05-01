#!/bin/bash
# test-complete-story.sh — Tests for complete-story.sh
# Validates story completion: status transition, state cleanup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

COMPLETE_STORY_SCRIPT="$SCRIPTS_DIR/complete-story.sh"

# --- Tests ---

echo "=== test-complete-story.sh ==="
echo ""

# Test 1: Happy path — active story becomes complete, state cleared
begin_test "Happy path — story status set to complete"

TEST_DIR=$(create_craft_with_story "test-cycle" "login-form" "Login Form" "3" "active")
trap cleanup_test_dir EXIT
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-login-form.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

set +e
RESULT=$(cd "$TEST_DIR" && bash "$COMPLETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

# Story status should be complete
STATUS=$(grep "^status:" "$STORY_FILE" | sed 's/status: *//')
assert_eq "story status is complete" "complete" "$STATUS"

cleanup_test_dir
echo ""

# Test 2: Clears CURRENT_STORY from global state
begin_test "Clears CURRENT_STORY from global state"

TEST_DIR=$(create_craft_with_story "test-cycle" "login-form" "Login Form" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-login-form.md"

set +e
(cd "$TEST_DIR" && bash "$COMPLETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
set -e

source "$TEST_DIR/.craft/.global-state"
assert_eq "global CURRENT_STORY cleared" "" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 3: Clears cycle state — CURRENT_STORY, CURRENT_CHUNK, TOTAL_CHUNKS
begin_test "Clears cycle state — story, chunk, total"

TEST_DIR=$(create_craft_with_story "test-cycle" "login-form" "Login Form" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-login-form.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

set +e
(cd "$TEST_DIR" && bash "$COMPLETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
set -e

source "$CYCLE_DIR/.state"
assert_eq "cycle CURRENT_STORY cleared" "" "$CURRENT_STORY"
assert_eq "cycle CURRENT_CHUNK reset to 0" "0" "$CURRENT_CHUNK"
assert_eq "cycle TOTAL_CHUNKS reset to 0" "0" "$TOTAL_CHUNKS"

cleanup_test_dir
echo ""

# Test 4: Clears CRAFT_WRITE_ENABLED
begin_test "Clears CRAFT_WRITE_ENABLED from global state"

TEST_DIR=$(create_craft_with_story "test-cycle" "login-form" "Login Form" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-login-form.md"

# Set CRAFT_WRITE_ENABLED first
echo 'CRAFT_WRITE_ENABLED="true"' >> "$TEST_DIR/.craft/.global-state"

set +e
(cd "$TEST_DIR" && bash "$COMPLETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
set -e

source "$TEST_DIR/.craft/.global-state"
assert_eq "CRAFT_WRITE_ENABLED cleared" "" "$CRAFT_WRITE_ENABLED"

cleanup_test_dir
echo ""

# Test 5: Missing file — exits 1
begin_test "Missing file — exits 1"

TEST_DIR=$(mktemp -d)

set +e
RESULT=$(cd "$TEST_DIR" && bash "$COMPLETE_STORY_SCRIPT" "$TEST_DIR/nonexistent.md" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing file" "1" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 6: No arguments — exits 1
begin_test "No arguments — exits 1"

set +e
RESULT=$(bash "$COMPLETE_STORY_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"
echo ""

# --- Summary ---
finish_tests
