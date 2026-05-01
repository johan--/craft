#!/bin/bash
# test-update-story-status.sh — Tests for update-story-status.sh
# Validates frontmatter status transitions and date updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

UPDATE_STATUS_SCRIPT="$SCRIPTS_DIR/update-story-status.sh"

# --- Tests ---

echo "=== test-update-story-status.sh ==="
echo ""

# Test 1: Transition to ready
begin_test "Transition to ready — status changes"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "planning")
trap cleanup_test_dir EXIT
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

set +e
RESULT=$(bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" ready 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"
assert_yaml_field "status is ready" "status" "ready" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 2: Transition to active
begin_test "Transition to active — status changes"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "ready")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" active >/dev/null 2>&1
assert_yaml_field "status is active" "status" "active" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 3: Transition to complete
begin_test "Transition to complete — status changes"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" complete >/dev/null 2>&1
assert_yaml_field "status is complete" "status" "complete" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 4: Updates the updated date
begin_test "Updates the updated date to today"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "planning")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" active >/dev/null 2>&1

TODAY=$(date +%Y-%m-%d)
assert_yaml_field "updated is today" "updated" "$TODAY" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 5: Preserves content — markdown body unchanged
begin_test "Preserves content — markdown body unchanged"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "ready")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

# Get original body content
ORIG_BODY=$(sed -n '/^---$/,/^---$/!p' "$STORY_FILE" | tail -n +1)

bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" active >/dev/null 2>&1

NEW_BODY=$(sed -n '/^---$/,/^---$/!p' "$STORY_FILE" | tail -n +1)
assert_eq "body content preserved" "$ORIG_BODY" "$NEW_BODY"

cleanup_test_dir
echo ""

# Test 6: Invalid status — exits 1
begin_test "Invalid status — exits 1"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "ready")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

set +e
RESULT=$(bash "$UPDATE_STATUS_SCRIPT" "$STORY_FILE" "invalid-status" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for invalid status" "1" "$EXIT_CODE"

# Status should be unchanged
assert_yaml_field "status unchanged" "status" "ready" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 7: Missing file — exits 1
begin_test "Missing file — exits 1"

set +e
RESULT=$(bash "$UPDATE_STATUS_SCRIPT" "/nonexistent/path.md" active 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing file" "1" "$EXIT_CODE"
echo ""

# Test 8: No arguments — exits 1
begin_test "No arguments — exits 1"

set +e
RESULT=$(bash "$UPDATE_STATUS_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"
echo ""

# --- Summary ---
finish_tests
