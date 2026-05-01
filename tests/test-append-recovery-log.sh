#!/bin/bash
# test-append-recovery-log.sh — Tests for append-recovery-log.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# --- Test-specific setup ---

setup_test_project() {
  TEST_DIR=$(mktemp -d)

  # Create .craft structure
  mkdir -p "$TEST_DIR/.craft"

  # Create global state
  cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="10-test-cycle"
CURRENT_STORY="login-form"
LAST_ACTIVITY=""
EOF

  echo "$TEST_DIR"
}

# --- Tests ---

echo "=== test-append-recovery-log.sh ==="
echo ""

# Test 1: Creates log file from scratch
begin_test "Creates log file — new file with header + entry"
TEST_DIR=$(setup_test_project)
trap cleanup_test_dir EXIT

"$SCRIPTS_DIR/append-recovery-log.sh" \
  "$TEST_DIR" "login-form" 2 "agent_error" \
  "nothing_to_salvage" "a1b2c3d" "Task tool returned error"

LOG_FILE="$TEST_DIR/.craft/recovery-log.md"
assert_file_exists "recovery-log.md created" "$LOG_FILE"

LOG_CONTENT=$(cat "$LOG_FILE")
assert_contains_literal "has header" "# Recovery Log" "$LOG_CONTENT"
assert_contains_literal "has story name" "login-form" "$LOG_CONTENT"
assert_contains_literal "has chunk number" "chunk 2" "$LOG_CONTENT"
assert_contains_literal "has failure reason" "agent_error" "$LOG_CONTENT"
assert_contains_literal "has checkpoint ref" "a1b2c3d" "$LOG_CONTENT"
assert_contains_literal "has details" "Task tool returned error" "$LOG_CONTENT"

cleanup_test_dir
echo ""

# Test 2: Appends to existing log
begin_test "Appends to existing — two ## entries in the file"
TEST_DIR=$(setup_test_project)

# First entry
"$SCRIPTS_DIR/append-recovery-log.sh" \
  "$TEST_DIR" "login-form" 2 "agent_error" \
  "nothing_to_salvage" "a1b2c3d" "First failure"

# Second entry
"$SCRIPTS_DIR/append-recovery-log.sh" \
  "$TEST_DIR" "signup-form" 1 "validation_error" \
  "nothing_to_salvage" "d4e5f6g" "Second failure"

LOG_FILE="$TEST_DIR/.craft/recovery-log.md"
LOG_CONTENT=$(cat "$LOG_FILE")

ENTRY_COUNT=$(grep -c "^## " "$LOG_FILE")
assert_eq "two ## entries" "2" "$ENTRY_COUNT"

assert_contains_literal "first entry has login-form" "login-form" "$LOG_CONTENT"
assert_contains_literal "second entry has signup-form" "signup-form" "$LOG_CONTENT"

cleanup_test_dir
echo ""

# Test 3: All fields present
begin_test "All fields present — entry has all required fields"
TEST_DIR=$(setup_test_project)

# Create a fake salvage directory with manifest
SALVAGE_DIR="$TEST_DIR/.craft/salvage/20260209_153500"
mkdir -p "$SALVAGE_DIR"
cat > "$SALVAGE_DIR/manifest.yaml" << 'EOF'
story: "login-form"
chunk: 2
file_count: 3
EOF

"$SCRIPTS_DIR/append-recovery-log.sh" \
  "$TEST_DIR" "login-form" 2 "agent_error" \
  "$SALVAGE_DIR" "a1b2c3d" "Task tool returned error after 12k tokens"

LOG_FILE="$TEST_DIR/.craft/recovery-log.md"
LOG_CONTENT=$(cat "$LOG_FILE")

assert_contains_literal "has Failure field" "**Failure:**" "$LOG_CONTENT"
assert_contains_literal "has Cycle field" "**Cycle:**" "$LOG_CONTENT"
assert_contains_literal "has Salvage field" "**Salvage:**" "$LOG_CONTENT"
assert_contains_literal "has Checkpoint field" "**Checkpoint:**" "$LOG_CONTENT"
assert_contains_literal "has Details field" "**Details:**" "$LOG_CONTENT"
assert_contains_literal "shows file count from manifest" "3 files" "$LOG_CONTENT"
assert_contains_literal "shows cycle name" "10-test-cycle" "$LOG_CONTENT"

cleanup_test_dir
echo ""

# Test 4: Does not create .craft/ when it doesn't exist
begin_test "Does NOT create .craft/ — exits 0 when .craft/ missing"
TEST_DIR=$(mktemp -d)

# No .craft/ directory exists — just a bare temp dir
"$SCRIPTS_DIR/append-recovery-log.sh" \
  "$TEST_DIR" "login-form" 2 "agent_error" \
  "nothing_to_salvage" "a1b2c3d" "Should not create .craft/"

assert_dir_not_exists ".craft/ should not be created" "$TEST_DIR/.craft"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
