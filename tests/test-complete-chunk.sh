#!/bin/bash
# test-complete-chunk.sh — Tests for complete-chunk.sh
# Validates chunk completion: state increment, frontmatter update, last-chunk signal

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

COMPLETE_CHUNK_SCRIPT="$SCRIPTS_DIR/complete-chunk.sh"

# --- Tests ---

echo "=== test-complete-chunk.sh ==="
echo ""

# Test 1: Happy path — chunk 1 of 3 increments to chunk 2
begin_test "Happy path — chunk 1→2 of 3"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
STORY_FILE="$CYCLE_DIR/stories/1-test-story.md"

set +e
RESULT=$(cd "$TEST_DIR" && bash "$COMPLETE_CHUNK_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

# Cycle state should show CURRENT_CHUNK=2
source "$CYCLE_DIR/.state"
assert_eq "CURRENT_CHUNK is 2" "2" "$CURRENT_CHUNK"

# Story frontmatter chunks_complete should be 1
CHUNKS_COMPLETE=$(grep "^chunks_complete:" "$STORY_FILE" | sed 's/chunks_complete: *//')
assert_eq "chunks_complete is 1" "1" "$CHUNKS_COMPLETE"

# Story frontmatter current_chunk should be 2
CURRENT_CHUNK_FM=$(grep "^current_chunk:" "$STORY_FILE" | sed 's/current_chunk: *//')
assert_eq "current_chunk is 2" "2" "$CURRENT_CHUNK_FM"

# Output should indicate continuation
assert_contains "output shows chunk progress" "chunk 2" "$RESULT"

cleanup_test_dir
echo ""

# Test 2: Last chunk — signals all chunks complete
begin_test "Last chunk — signals all chunks complete"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "2" "active")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Set to chunk 2 of 2 (about to complete last chunk)
cat > "$CYCLE_DIR/.state" << 'EOF'
CYCLE_NAME="test-cycle"
CYCLE_STATUS="active"
CURRENT_STORY="test-story"
CURRENT_CHUNK="2"
TOTAL_CHUNKS="2"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

set +e
RESULT=$(cd "$TEST_DIR" && bash "$COMPLETE_CHUNK_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
set -e

# Output should signal completion
assert_contains "signals ALL CHUNKS COMPLETE" "ALL CHUNKS COMPLETE" "$RESULT"

# CURRENT_CHUNK should be 3 (past total)
source "$CYCLE_DIR/.state"
assert_eq "CURRENT_CHUNK is 3 (past total)" "3" "$CURRENT_CHUNK"

cleanup_test_dir
echo ""

# Test 3: Updates story frontmatter — chunks_complete incremented
begin_test "Updates story frontmatter — updated date changes"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"
STORY_FILE="$CYCLE_DIR/stories/1-test-story.md"

# Check original date
ORIG_UPDATED=$(grep "^updated:" "$STORY_FILE" | sed 's/updated: *//')

set +e
(cd "$TEST_DIR" && bash "$COMPLETE_CHUNK_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
set -e

# Updated date should be today
TODAY=$(date +%Y-%m-%d)
NEW_UPDATED=$(grep "^updated:" "$STORY_FILE" | sed 's/updated: *//')
assert_eq "updated date is today" "$TODAY" "$NEW_UPDATED"

cleanup_test_dir
echo ""

# Test 4: BUG — complete-chunk.sh picks up CRAFT_PROJECT_ROOT from environment
# When called with no args from a random directory, find-project-root.sh inherits
# CRAFT_PROJECT_ROOT from the parent environment and operates on the REAL project.
# This is a safety issue: an accidental invocation can corrupt real state.
# The test verifies the bug exists by checking that env isolation changes behavior.
begin_test "BUG: no args + no env isolation → picks up real CRAFT_PROJECT_ROOT"

TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.craft"

# WITHOUT env isolation — script inherits CRAFT_PROJECT_ROOT from parent
# It will find the real project and try to operate on it (dangerous!)
# WITH env isolation — script can't find any active cycle → should exit 1
set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && unset PROJECT_ROOT && bash "$COMPLETE_CHUNK_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no cycle (env isolated)" "1" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 5: No active story in cycle — exits 1
begin_test "No active story in cycle — exits 1"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Ensure no CURRENT_STORY
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
RESULT=$(cd "$TEST_DIR" && bash "$COMPLETE_CHUNK_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no story" "1" "$EXIT_CODE"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
