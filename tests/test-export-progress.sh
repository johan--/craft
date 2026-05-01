#!/bin/bash
# test-export-progress.sh — Tests for export-progress.sh
# Validates state export writes to the correct .craft/ in monorepo scenarios
#
# REGRESSION (story 9): test 1 MUST FAIL against current codebase
# export-progress.sh uses relative ".craft" paths instead of CRAFT_PROJECT_ROOT,
# so exports go to the wrong directory (or fail silently) when CWD ≠ project root.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-shadow.sh"
source "$SCRIPT_DIR/fixtures/minimal.sh"

EXPORT_SCRIPT="$SCRIPTS_DIR/export-progress.sh"

# --- Tests ---

echo "=== test-export-progress.sh ==="
echo ""

# ---- REGRESSION TEST (Story 9) ----
# export-progress.sh uses relative ".craft" paths throughout:
#   if [ ! -d ".craft" ]; then exit 0; fi
#   mkdir -p .craft/.exports
#   export_file=".craft/.exports/pre-compact-$timestamp.md"
#
# When CWD is a subdirectory without .craft/, the script exits early (line 8).
# Even when CRAFT_PROJECT_ROOT is set, exports don't land in the right place.
begin_test "REGRESSION: export-progress uses CRAFT_PROJECT_ROOT, not relative .craft"

TEST_DIR=$(create_craft_with_shadow)
trap cleanup_test_dir EXIT
PARENT_DIR="$TEST_DIR/project"
CHILD_DIR="$TEST_DIR/project/apps/web"

# Add a story to make the export non-trivial
cat > "$PARENT_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY="login-form"
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

# Run export-progress.sh from the CHILD directory (apps/web/)
# with CRAFT_PROJECT_ROOT pointing to the PARENT (correct root)
# The script SHOULD write to $PARENT_DIR/.craft/.exports/
set +e
(cd "$CHILD_DIR" && export CRAFT_PROJECT_ROOT="$PARENT_DIR" && bash "$EXPORT_SCRIPT" 2>/dev/null)
EXPORT_EXIT=$?
set -e

# Check: did the export land in the PARENT's .craft/.exports/ ?
PARENT_EXPORTS=$(ls "$PARENT_DIR/.craft/.exports/pre-compact-"*.md 2>/dev/null | wc -l | tr -d ' ')

if [ "$PARENT_EXPORTS" -gt 0 ]; then
  echo "  PASS: export written to parent .craft/.exports/"
  PASS=$((PASS + 1))
else
  echo "  FAIL: export NOT written to parent .craft/.exports/"
  echo "    expected: file in $PARENT_DIR/.craft/.exports/"
  echo "    exit code: $EXPORT_EXIT"
  # Check if it accidentally wrote to child or CWD
  CHILD_EXPORTS=$(ls "$CHILD_DIR/.craft/.exports/pre-compact-"*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHILD_EXPORTS" -gt 0 ]; then
    echo "    BUG: export went to CHILD .craft/.exports/ instead"
  else
    echo "    BUG: export went nowhere (script likely exited early — no .craft in CWD)"
  fi
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 2: Happy path — export from project root works
begin_test "Happy path — export from project root creates file"

TEST_DIR=$(create_minimal_craft)

# Add some state to export
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

set +e
(cd "$TEST_DIR" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && bash "$EXPORT_SCRIPT" 2>/dev/null)
EXPORT_EXIT=$?
set -e

assert_eq "exits 0" "0" "$EXPORT_EXIT"

# Should have created an export file
EXPORT_COUNT=$(ls "$TEST_DIR/.craft/.exports/pre-compact-"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$EXPORT_COUNT" -gt 0 ]; then
  echo "  PASS: export file created"
  PASS=$((PASS + 1))
else
  echo "  FAIL: no export file created in $TEST_DIR/.craft/.exports/"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 3: Export includes global state content
begin_test "Export includes global state content"

TEST_DIR=$(create_minimal_craft)

cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="test-cycle"
CURRENT_STORY="test-story"
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

set +e
(cd "$TEST_DIR" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && bash "$EXPORT_SCRIPT" 2>/dev/null)
set -e

EXPORT_FILE=$(ls "$TEST_DIR/.craft/.exports/pre-compact-"*.md 2>/dev/null | head -1)
if [ -n "$EXPORT_FILE" ] && [ -f "$EXPORT_FILE" ]; then
  CONTENT=$(cat "$EXPORT_FILE")
  assert_contains_literal "contains Global State header" "## Global State" "$CONTENT"
  assert_contains_literal "contains ACTIVE_CYCLE" "ACTIVE_CYCLE" "$CONTENT"
else
  echo "  FAIL: no export file found to check content"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 4: No .craft/ directory — exits cleanly
begin_test "No .craft/ — exits 0 without error"

TEST_DIR=$(mktemp -d)

set +e
(cd "$TEST_DIR" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && bash "$EXPORT_SCRIPT" 2>/dev/null)
EXPORT_EXIT=$?
set -e

assert_eq "exits 0 (no-op)" "0" "$EXPORT_EXIT"

# Should NOT create any .craft/ directory
if [ -d "$TEST_DIR/.craft" ]; then
  echo "  FAIL: script created .craft/ where none existed"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: no .craft/ directory created"
  PASS=$((PASS + 1))
fi

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
