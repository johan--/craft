#!/bin/bash
# test-delete-story.sh — Tests for delete-story.sh
# Validates story deletion: file removal + state cleanup when active

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"

DELETE_STORY_SCRIPT="$SCRIPTS_DIR/delete-story.sh"

# --- Tests ---

echo "=== test-delete-story.sh ==="
echo ""

# Test 1: Deletes story file
begin_test "Deletes story file"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
trap cleanup_test_dir EXIT
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

assert_file_exists "story file exists before delete" "$STORY_FILE"

set +e
RESULT=$(bash "$DELETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"
assert_file_not_exists "story file deleted" "$STORY_FILE"

cleanup_test_dir
echo ""

# Test 2: Clears state when deleting active story
begin_test "Clears state when deleting active story"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Set this story as active
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CRAFT_WRITE_ENABLED="true"
LAST_ACTIVITY=""
EOF

# Add cycle field to story frontmatter for cycle lookup
# The fixture creates stories with cycle field already set
bash "$DELETE_STORY_SCRIPT" "$STORY_FILE" >/dev/null 2>&1

source "$TEST_DIR/.craft/.global-state"
assert_eq "CURRENT_STORY cleared" "" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 3: Clears cycle state when deleting active story
begin_test "Clears cycle state when deleting active story"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="test-story"
CRAFT_WRITE_ENABLED="true"
EOF

# Set cycle state
bash "$SCRIPTS_DIR/update-cycle-state.sh" "$CYCLE_DIR" CURRENT_STORY "test-story"
bash "$SCRIPTS_DIR/update-cycle-state.sh" "$CYCLE_DIR" CURRENT_CHUNK "2"

bash "$DELETE_STORY_SCRIPT" "$STORY_FILE" >/dev/null 2>&1

source "$CYCLE_DIR/.state"
assert_eq "cycle CURRENT_STORY cleared" "" "$CURRENT_STORY"
assert_eq "cycle CURRENT_CHUNK reset" "0" "$CURRENT_CHUNK"

cleanup_test_dir
echo ""

# Test 4: Non-active story — deletes without touching state
begin_test "Non-active story — deletes without touching state"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

# Set a DIFFERENT story as active
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="different-story"
EOF

bash "$DELETE_STORY_SCRIPT" "$STORY_FILE" >/dev/null 2>&1

assert_file_not_exists "file deleted" "$STORY_FILE"
source "$TEST_DIR/.craft/.global-state"
assert_eq "CURRENT_STORY unchanged" "different-story" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 5: Missing story file — exits 1
begin_test "Missing story file — exits 1"

set +e
RESULT=$(bash "$DELETE_STORY_SCRIPT" "/nonexistent/story.md" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing file" "1" "$EXIT_CODE"
echo ""

# Test 6: No arguments — exits 1
begin_test "No arguments — exits 1"

set +e
RESULT=$(bash "$DELETE_STORY_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"
echo ""

# Test 7: Output shows deletion message
begin_test "Output shows deletion message"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
STORY_FILE="$TEST_DIR/.craft/cycles/1-test-cycle/stories/1-test-story.md"

cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
EOF

RESULT=$(bash "$DELETE_STORY_SCRIPT" "$STORY_FILE" 2>/dev/null)
assert_contains "shows deleted message" "deleted" "$RESULT"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
