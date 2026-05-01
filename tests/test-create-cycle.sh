#!/bin/bash
# test-create-cycle.sh — Tests for create-cycle.sh
# Validates cycle creation: directory structure, numbering, yaml content, state file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/minimal.sh"

CREATE_CYCLE_SCRIPT="$SCRIPTS_DIR/create-cycle.sh"

# --- Tests ---

echo "=== test-create-cycle.sh ==="
echo ""

# Test 1: Creates directory structure with cycle.yaml + .state + stories/
begin_test "Creates directory with cycle.yaml, .state, stories/"

TEST_DIR=$(create_minimal_craft)
trap cleanup_test_dir EXIT

set +e
RESULT=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Authentication" "Login flow" "$TEST_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

# Should create 1-auth/ directory
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-auth"
assert_dir_exists "cycle directory created" "$CYCLE_DIR"
assert_file_exists "cycle.yaml exists" "$CYCLE_DIR/cycle.yaml"
assert_file_exists ".state exists" "$CYCLE_DIR/.state"
assert_dir_exists "stories/ directory exists" "$CYCLE_DIR/stories"

# Output should be the cycle dir path
assert_contains "output is cycle dir" "1-auth" "$RESULT"

cleanup_test_dir
echo ""

# Test 2: Auto-numbering — second cycle gets prefix 2-
begin_test "Auto-numbering — second cycle gets prefix 2-"

TEST_DIR=$(create_minimal_craft)

# Create first cycle
CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1

# Create second cycle
set +e
RESULT=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "dashboard" "Dashboard" "UI" "$TEST_DIR" 2>/dev/null)
set -e

assert_dir_exists "cycle 1-auth exists" "$TEST_DIR/.craft/cycles/1-auth"
assert_dir_exists "cycle 2-dashboard exists" "$TEST_DIR/.craft/cycles/2-dashboard"

cleanup_test_dir
echo ""

# Test 3: cycle.yaml content — title, status, created
begin_test "cycle.yaml has correct content"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Authentication Flow" "Login and signup" "$TEST_DIR" >/dev/null 2>&1

CYCLE_YAML="$TEST_DIR/.craft/cycles/1-auth/cycle.yaml"
assert_file_exists "cycle.yaml exists" "$CYCLE_YAML"

# Check key fields
assert_file_contains "has title" "title:" "$CYCLE_YAML"
assert_file_contains "has status: planning" "status: planning" "$CYCLE_YAML"
assert_file_contains "has created date" "created:" "$CYCLE_YAML"

cleanup_test_dir
echo ""

# Test 4: .state file content — CYCLE_NAME, CYCLE_STATUS
begin_test ".state has correct initial values"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1

STATE_FILE="$TEST_DIR/.craft/cycles/1-auth/.state"
assert_file_exists ".state exists" "$STATE_FILE"

source "$STATE_FILE"
assert_eq "CYCLE_NAME is auth" "auth" "$CYCLE_NAME"
assert_eq "CYCLE_STATUS is planning" "planning" "$CYCLE_STATUS"
assert_eq "CURRENT_STORY is empty" "" "$CURRENT_STORY"
assert_eq "CURRENT_CHUNK is 0" "0" "$CURRENT_CHUNK"

cleanup_test_dir
echo ""

# Test 5: No .craft/ directory — exits 1
begin_test "No .craft/ — exits 1"

TEST_DIR=$(mktemp -d)

set +e
RESULT=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 without .craft/" "1" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# Test 6: No cycle name — exits 1
begin_test "No cycle name — exits 1"

TEST_DIR=$(create_minimal_craft)

set +e
RESULT=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no name" "1" "$EXIT_CODE"

cleanup_test_dir
echo ""

# Test 7: Creates learnings file if missing
begin_test "Creates .learnings.yaml if missing"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1

assert_file_exists ".learnings.yaml created" "$TEST_DIR/.craft/.learnings.yaml"

cleanup_test_dir
echo ""

# Test 8: Title includes cycle number prefix
begin_test "Title includes cycle number prefix (Cycle NN: Title)"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Authentication Flow" "Login" "$TEST_DIR" >/dev/null 2>&1

CYCLE_YAML="$TEST_DIR/.craft/cycles/1-auth/cycle.yaml"
TITLE_LINE=$(grep "^title:" "$CYCLE_YAML")

if echo "$TITLE_LINE" | grep -q "Cycle 01:"; then
  echo "  PASS: title has cycle number prefix"
  PASS=$((PASS + 1))
else
  echo "  FAIL: title missing cycle number prefix"
  echo "    expected: Cycle 01: Authentication Flow"
  echo "    actual:   $TITLE_LINE"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 9: Title is quoted in YAML (colon-safe)
begin_test "Title is quoted in YAML (colon in 'Cycle NN:' requires quotes)"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1

CYCLE_YAML="$TEST_DIR/.craft/cycles/1-auth/cycle.yaml"
TITLE_LINE=$(grep "^title:" "$CYCLE_YAML")

if echo "$TITLE_LINE" | grep -qE '^title: ".*"$'; then
  echo "  PASS: title is quoted"
  PASS=$((PASS + 1))
else
  echo "  FAIL: title is NOT quoted — colon will break YAML parsing"
  echo "    actual: $TITLE_LINE"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 10: Goals array has no null/empty entries
begin_test "Goals array has no null/empty entries"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1

CYCLE_YAML="$TEST_DIR/.craft/cycles/1-auth/cycle.yaml"

# Check for bare "- " lines (empty list entries that parse as null)
EMPTY_ENTRIES=$(grep -n "^  - $" "$CYCLE_YAML" 2>/dev/null || true)
if [ -z "$EMPTY_ENTRIES" ]; then
  echo "  PASS: no empty list entries"
  PASS=$((PASS + 1))
else
  echo "  FAIL: found empty list entries (parse as null, break Zod validation)"
  echo "    lines: $EMPTY_ENTRIES"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# Test 11: Auto-numbering carries into title
begin_test "Second cycle title has Cycle 02 prefix"

TEST_DIR=$(create_minimal_craft)

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "auth" "Auth" "Login" "$TEST_DIR" >/dev/null 2>&1
CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$CREATE_CYCLE_SCRIPT" "dashboard" "Dashboard" "UI" "$TEST_DIR" >/dev/null 2>&1

CYCLE_YAML="$TEST_DIR/.craft/cycles/2-dashboard/cycle.yaml"
TITLE_LINE=$(grep "^title:" "$CYCLE_YAML")

if echo "$TITLE_LINE" | grep -q "Cycle 02:"; then
  echo "  PASS: second cycle title has Cycle 02 prefix"
  PASS=$((PASS + 1))
else
  echo "  FAIL: second cycle title has wrong prefix"
  echo "    expected: Cycle 02: Dashboard"
  echo "    actual:   $TITLE_LINE"
  FAIL=$((FAIL + 1))
fi

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
