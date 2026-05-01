#!/bin/bash
# test-find-project-root.sh — Tests for find-project-root.sh
# Validates project root resolution in monorepo scenarios
#
# Key behavior: "nearest wins" — walk up from CWD, first .craft/.global-state wins.
# In a monorepo with multiple .craft/ directories (one per sub-project),
# each sub-project owns its own .craft/. This is intentional.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-shadow.sh"
source "$SCRIPT_DIR/fixtures/minimal.sh"

FIND_SCRIPT="$SCRIPTS_DIR/find-project-root.sh"

# --- Tests ---

echo "=== test-find-project-root.sh ==="
echo ""

# Test 1: Nearest .craft/ wins — child found before parent
# In a monorepo, each sub-project has its own .craft/. When CWD is inside
# a sub-project, find-project-root should resolve to THAT sub-project.
begin_test "Nearest wins — resolves to child .craft/ from child dir"

TEST_DIR=$(create_craft_with_shadow)
trap cleanup_test_dir EXIT
PARENT_DIR="$TEST_DIR/project"
CHILD_DIR="$TEST_DIR/project/apps/web"

# Source find-project-root.sh from the child dir in a subshell
RESULT=$(cd "$CHILD_DIR" && unset PROJECT_ROOT && unset CRAFT_PROJECT_ROOT && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "resolves to child (nearest) project root" "$CHILD_DIR/" "$RESULT"

cleanup_test_dir
echo ""

# Test 2: Nearest wins from deep subdir — walks up to closest .craft/
begin_test "Nearest wins — resolves to child .craft/ from deep subdir"

TEST_DIR=$(create_craft_with_shadow)
PARENT_DIR="$TEST_DIR/project"
CHILD_DIR="$TEST_DIR/project/apps/web"

# Go deeper — from apps/web/src/components/
mkdir -p "$CHILD_DIR/src/components"
RESULT=$(cd "$CHILD_DIR/src/components" && unset PROJECT_ROOT && unset CRAFT_PROJECT_ROOT && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "resolves to child from deep subdir" "$CHILD_DIR/" "$RESULT"

cleanup_test_dir
echo ""

# Test 3: Basic — single .craft/.global-state, correct resolution
begin_test "Basic — single .craft/ resolves correctly"

TEST_DIR=$(create_minimal_craft)

RESULT=$(cd "$TEST_DIR" && unset PROJECT_ROOT && unset CRAFT_PROJECT_ROOT && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "resolves to project dir" "$TEST_DIR/" "$RESULT"

cleanup_test_dir
echo ""

# Test 4: No .craft/ anywhere — returns empty/error
begin_test "No .craft/ — returns error"

TEST_DIR=$(mktemp -d)

set +e
RESULT=$(cd "$TEST_DIR" && unset PROJECT_ROOT && unset CRAFT_PROJECT_ROOT && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")
EXIT_CODE=$?
set -e

# PROJECT_ROOT should be empty (script exits 1 or return 1)
if [ -z "$RESULT" ]; then
  echo "  PASS: PROJECT_ROOT is empty when no .craft/ found"
  PASS=$((PASS + 1))
else
  echo "  FAIL: PROJECT_ROOT should be empty, got: $RESULT"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 5: CRAFT_PROJECT_ROOT env var takes precedence
begin_test "Env var CRAFT_PROJECT_ROOT takes precedence"

TEST_DIR=$(create_minimal_craft)
# Create a second dir that CRAFT_PROJECT_ROOT points to
ALT_DIR=$(create_minimal_craft)

RESULT=$(cd "$TEST_DIR" && unset PROJECT_ROOT && export CRAFT_PROJECT_ROOT="$ALT_DIR" && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "uses env var, not walk-up" "$ALT_DIR/" "$RESULT"

rm -rf "$ALT_DIR"
cleanup_test_dir
echo ""

# Test 6: Invalid CRAFT_PROJECT_ROOT falls through to walk-up
begin_test "Invalid env var falls through to walk-up"

TEST_DIR=$(create_minimal_craft)

RESULT=$(cd "$TEST_DIR" && unset PROJECT_ROOT && export CRAFT_PROJECT_ROOT="/nonexistent/path" && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "falls through to walk-up" "$TEST_DIR/" "$RESULT"

cleanup_test_dir
echo ""

# Test 7: Bare .craft/ fallback skipped — walks past rogue directory
begin_test "Bare .craft/ skipped — fallback ignores rogue dir without project.md"

TEST_DIR=$(create_craft_with_rogue_shadow)
PARENT_DIR="$TEST_DIR/project"
ROGUE_DIR="$TEST_DIR/project/apps/web"

# From apps/web/ (which has bare .craft/), should walk up to parent
RESULT=$(cd "$ROGUE_DIR" && unset PROJECT_ROOT && unset CRAFT_PROJECT_ROOT && unset CRAFT_MULTI_PROJECT && source "$FIND_SCRIPT" 2>/dev/null && echo "$PROJECT_ROOT")

assert_eq "skips rogue .craft/, resolves to parent" "$PARENT_DIR/" "$RESULT"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
