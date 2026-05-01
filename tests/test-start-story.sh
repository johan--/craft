#!/bin/bash
# test-start-story.sh — Tests for start-story.sh
# Validates story activation: status transition, global/cycle state updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

START_SCRIPT="$SCRIPTS_DIR/start-story.sh"

# --- Tests ---

echo "=== test-start-story.sh ==="
echo ""

# Test 1: Happy path — ready story becomes active, state updated
begin_test "Happy path — ready story transitions to active"

TEST_DIR=$(create_craft_with_story "test-cycle" "login-form" "Login Form" "3" "ready")
trap cleanup_test_dir EXIT
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-login-form.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Reset state so start-story sets it fresh
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF
cat > "$CYCLE_DIR/.state" << 'EOF'
CYCLE_NAME="test-cycle"
CYCLE_STATUS="active"
CURRENT_STORY=""
CURRENT_CHUNK="0"
TOTAL_CHUNKS="0"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

set +e
RESULT=$(cd "$TEST_DIR" && bash "$START_SCRIPT" "$STORY_FILE" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

# Story frontmatter should now say status: active
STATUS=$(grep "^status:" "$STORY_FILE" | sed 's/status: *//')
assert_eq "story status is active" "active" "$STATUS"

# Global state should have CURRENT_STORY set
source "$TEST_DIR/.craft/.global-state"
assert_eq "global CURRENT_STORY set" "1-login-form" "$CURRENT_STORY"

# Cycle state should have CURRENT_STORY, CURRENT_CHUNK=1, TOTAL_CHUNKS=3
source "$CYCLE_DIR/.state"
assert_eq "cycle CURRENT_STORY set" "1-login-form" "$CURRENT_STORY"
assert_eq "cycle CURRENT_CHUNK is 1" "1" "$CURRENT_CHUNK"
assert_eq "cycle TOTAL_CHUNKS is 3" "3" "$TOTAL_CHUNKS"

cleanup_test_dir
echo ""

# Test 2: Sets CRAFT_WRITE_ENABLED in global state
begin_test "Sets CRAFT_WRITE_ENABLED in global state"

TEST_DIR=$(create_craft_with_story "test-cycle" "signup" "Signup" "2" "ready")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-signup.md"

set +e
(cd "$TEST_DIR" && bash "$START_SCRIPT" "$STORY_FILE" 2>/dev/null)
set -e

# Check CRAFT_WRITE_ENABLED is set
source "$TEST_DIR/.craft/.global-state"
assert_eq "CRAFT_WRITE_ENABLED is true" "true" "$CRAFT_WRITE_ENABLED"

cleanup_test_dir
echo ""

# Test 3: Missing file — exits 1
begin_test "Missing file — exits 1"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")

set +e
RESULT=$(cd "$TEST_DIR" && bash "$START_SCRIPT" "$TEST_DIR/.craft/cycles/1-test-cycle/stories/nonexistent.md" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing file" "1" "$EXIT_CODE"

cleanup_test_dir
echo ""

# Test 4: No arguments — exits 1
begin_test "No arguments — exits 1 with usage"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")

set +e
RESULT=$(cd "$TEST_DIR" && bash "$START_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"

cleanup_test_dir
echo ""

# Test 5: Story with chunks_total=0 — still starts
begin_test "Story with chunks_total=0 — starts with 0 chunks"

TEST_DIR=$(create_craft_with_story "test-cycle" "no-chunks" "No Chunks" "0" "ready")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-no-chunks.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

set +e
(cd "$TEST_DIR" && bash "$START_SCRIPT" "$STORY_FILE" 2>/dev/null)
set -e

source "$CYCLE_DIR/.state"
assert_eq "TOTAL_CHUNKS is 0" "0" "$TOTAL_CHUNKS"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
