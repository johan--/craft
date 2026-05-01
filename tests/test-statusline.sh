#!/bin/bash
# test-statusline.sh — Tests for statusline.sh
# Validates status line generation reads from correct .craft/ directory
#
# REGRESSION (story 9): test 1 MUST FAIL against current codebase
# statusline.sh uses relative ".craft" paths throughout:
#   line 37: if [ ! -f ".craft/.global-state" ]
#   line 42: source .craft/.global-state
#   line 46: ls -1 .craft/backlog/*.md
#   line 57: .craft/cycles/$ACTIVE_CYCLE/cycle.yaml
#   line 64: .craft/cycles/$ACTIVE_CYCLE/.state
#   line 99: .craft/cycles/$ACTIVE_CYCLE/stories/
# When CWD ≠ project root, statusline shows wrong info even when
# CRAFT_PROJECT_ROOT is set correctly.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-story.sh"
source "$SCRIPT_DIR/fixtures/minimal.sh"

STATUSLINE_SCRIPT="$SCRIPTS_DIR/statusline.sh"

# Minimal JSON input for statusline.sh (it reads cost + token usage from stdin)
MOCK_INPUT='{"cost":{"total_cost_usd":0.42},"tokenUsage":{"input":50000,"contextLimit":200000}}'

# --- Tests ---

echo "=== test-statusline.sh ==="
echo ""

# ---- REGRESSION TEST (Story 9): Relative .craft path ----
# statusline.sh checks `if [ ! -f ".craft/.global-state" ]` (line 37) and
# sources `.craft/.global-state` (line 42) — all relative to CWD.
# When CWD is a subdirectory and CRAFT_PROJECT_ROOT is set, the script
# should use CRAFT_PROJECT_ROOT to find .craft/, not CWD.
begin_test "REGRESSION: statusline uses CRAFT_PROJECT_ROOT, not relative .craft"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
trap cleanup_test_dir EXIT

# Create subdirectory WITHOUT .craft/
mkdir -p "$TEST_DIR/src/components"

# Run from subdirectory with CRAFT_PROJECT_ROOT set
set +e
RESULT=$(cd "$TEST_DIR/src/components" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && \
  echo "$MOCK_INPUT" | bash "$STATUSLINE_SCRIPT" 2>/dev/null)
set -e

# Should show cycle info (not "No active cycle")
if echo "$RESULT" | grep -q "No active cycle"; then
  echo "  FAIL: shows 'No active cycle' — script used relative path, ignoring CRAFT_PROJECT_ROOT"
  echo "    CWD: $TEST_DIR/src/components (no .craft/ here)"
  echo "    CRAFT_PROJECT_ROOT: $TEST_DIR (has .craft/ with active cycle)"
  echo "    output: $RESULT"
  FAIL=$((FAIL + 1))
else
  # Should contain some reference to the cycle or story
  if echo "$RESULT" | grep -qi "test"; then
    echo "  PASS: shows cycle/story info from CRAFT_PROJECT_ROOT"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: unexpected output (expected cycle info)"
    echo "    output: $RESULT"
    FAIL=$((FAIL + 1))
  fi
fi

cleanup_test_dir
echo ""

# ---- REGRESSION TEST (Story 9): Backlog count from subdirectory ----
# statusline.sh line 46: ls -1 .craft/backlog/*.md — relative path
# When CWD ≠ project root, backlog count is wrong.
begin_test "REGRESSION: statusline shows correct backlog count from subdirectory"

TEST_DIR=$(create_minimal_craft)

# No active cycle, but stories in backlog
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

# Create backlog stories
mkdir -p "$TEST_DIR/.craft/backlog"
echo "---" > "$TEST_DIR/.craft/backlog/story-1.md"
echo "---" > "$TEST_DIR/.craft/backlog/story-2.md"

# Create subdirectory WITHOUT .craft/
mkdir -p "$TEST_DIR/src/features"

set +e
RESULT=$(cd "$TEST_DIR/src/features" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && \
  echo "$MOCK_INPUT" | bash "$STATUSLINE_SCRIPT" 2>/dev/null)
set -e

# Should show "Backlog: 2 stories" (not "No active cycle" or "Backlog: 0")
if echo "$RESULT" | grep -q "Backlog.*2"; then
  echo "  PASS: shows correct backlog count from subdirectory"
  PASS=$((PASS + 1))
elif echo "$RESULT" | grep -q "Backlog"; then
  echo "  FAIL: shows Backlog but wrong count"
  echo "    output: $RESULT"
  FAIL=$((FAIL + 1))
else
  echo "  FAIL: does not show backlog count at all"
  echo "    BUG: script uses relative 'ls .craft/backlog/*.md', ignoring CRAFT_PROJECT_ROOT"
  echo "    output: $RESULT"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 3: Happy path — from project root shows cycle and story
begin_test "Happy path — from project root shows cycle and story"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")

set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && echo "$MOCK_INPUT" | bash "$STATUSLINE_SCRIPT" 2>/dev/null)
set -e

# Should contain story name (with hyphens converted to spaces)
assert_contains "output contains story name" "test.story" "$RESULT"
# Should contain chunk info
assert_contains "output contains chunk info" "chunk" "$RESULT"
# Cost check uses LC_ALL=C because progress bar has malformed UTF-8 bytes
# (known bug: statusline.sh e2e2 byte sequence) which breaks grep in UTF-8 locale
if echo "$RESULT" | LC_ALL=C grep -q "0.42"; then
  echo "  PASS: output contains cost"
  PASS=$((PASS + 1))
else
  echo "  FAIL: output contains cost"
  echo "    expected to contain: '0.42'"
  echo "    in: '$RESULT'"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 4: No .craft/ at CWD, no CRAFT_PROJECT_ROOT — shows "No active cycle"
begin_test "No .craft/ anywhere — shows 'No active cycle'"

TEST_DIR=$(mktemp -d)

set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && echo "$MOCK_INPUT" | bash "$STATUSLINE_SCRIPT" 2>/dev/null)
set -e

assert_contains "shows no active cycle" "No active cycle" "$RESULT"

rm -rf "$TEST_DIR"
echo ""

# Test 5: Active cycle with no current story — shows story counts
begin_test "Active cycle, no story — shows story counts"

TEST_DIR=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "complete")

# Clear current story from BOTH global state AND cycle state
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

cat > "$TEST_DIR/.craft/cycles/1-test-cycle/.state" << 'EOF'
CYCLE_NAME="test-cycle"
CYCLE_STATUS="active"
CURRENT_STORY=""
CURRENT_CHUNK="0"
TOTAL_CHUNKS="0"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && echo "$MOCK_INPUT" | bash "$STATUSLINE_SCRIPT" 2>/dev/null)
set -e

# Should show story counts, not "No active cycle"
assert_contains "output contains stories count" "stories" "$RESULT"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
