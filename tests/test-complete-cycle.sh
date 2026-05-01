#!/bin/bash
# test-complete-cycle.sh — Tests for complete-cycle.sh
# Validates cycle completion: state transitions + global state cleanup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

COMPLETE_CYCLE_SCRIPT="$SCRIPTS_DIR/complete-cycle.sh"

# --- Tests ---

echo "=== test-complete-cycle.sh ==="
echo ""

# Test 1: Completes cycle — sets CYCLE_STATUS to complete
begin_test "Sets CYCLE_STATUS to complete"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Activate cycle first
bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1

set +e
RESULT=$(bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

source "$CYCLE_DIR/.state"
assert_eq "CYCLE_STATUS is complete" "complete" "$CYCLE_STATUS"

cleanup_test_dir
echo ""

# Test 2: Clears global ACTIVE_CYCLE
begin_test "Clears global ACTIVE_CYCLE"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1
bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

source "$TEST_DIR/.craft/.global-state"
assert_eq "ACTIVE_CYCLE cleared" "" "$ACTIVE_CYCLE"

cleanup_test_dir
echo ""

# Test 3: Clears CURRENT_STORY
begin_test "Clears CURRENT_STORY"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1
bash "$SCRIPTS_DIR/update-global-state.sh" CURRENT_STORY "some-story" "$TEST_DIR"
bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

source "$TEST_DIR/.craft/.global-state"
assert_eq "CURRENT_STORY cleared" "" "$CURRENT_STORY"

cleanup_test_dir
echo ""

# Test 4: Updates cycle.yaml status
begin_test "Updates cycle.yaml status to complete"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1
bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

assert_file_contains "cycle.yaml has complete" "status: complete" "$CYCLE_DIR/cycle.yaml"

cleanup_test_dir
echo ""

# Test 5: Clears cycle .state CURRENT_STORY and CURRENT_CHUNK
begin_test "Clears cycle CURRENT_STORY and CURRENT_CHUNK"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1
bash "$SCRIPTS_DIR/update-cycle-state.sh" "$CYCLE_DIR" CURRENT_STORY "some-story"
bash "$SCRIPTS_DIR/update-cycle-state.sh" "$CYCLE_DIR" CURRENT_CHUNK "3"

bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

source "$CYCLE_DIR/.state"
assert_eq "CURRENT_STORY cleared in cycle" "" "$CURRENT_STORY"
assert_eq "CURRENT_CHUNK reset to 0" "0" "$CURRENT_CHUNK"

cleanup_test_dir
echo ""

# Test 6: Output shows completion message
begin_test "Output shows completion message"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$SCRIPTS_DIR/start-cycle.sh" "$CYCLE_DIR" >/dev/null 2>&1
RESULT=$(bash "$COMPLETE_CYCLE_SCRIPT" "$CYCLE_DIR" 2>/dev/null)

assert_contains "shows completed message" "completed" "$RESULT"

cleanup_test_dir
echo ""

# Test 7: No cycle found — exits 1
begin_test "No cycle found — exits 1"

TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.craft"
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
EOF

set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && unset PROJECT_ROOT && bash "$COMPLETE_CYCLE_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no cycle" "1" "$EXIT_CODE"

rm -rf "$TEST_DIR"
echo ""

# --- Summary ---
finish_tests
