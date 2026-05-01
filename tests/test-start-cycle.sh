#!/bin/bash
# test-start-cycle.sh — Tests for start-cycle.sh
# Validates cycle activation: global state + cycle state + cycle.yaml updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

START_CYCLE_SCRIPT="$SCRIPTS_DIR/start-cycle.sh"

# --- Tests ---

echo "=== test-start-cycle.sh ==="
echo ""

# Test 1: Activates cycle — sets global ACTIVE_CYCLE
begin_test "Activates cycle — sets global ACTIVE_CYCLE"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
trap cleanup_test_dir EXIT
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

set +e
RESULT=$(bash "$START_CYCLE_SCRIPT" "$CYCLE_DIR" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"

source "$TEST_DIR/.craft/.global-state"
assert_eq "ACTIVE_CYCLE set" "1-test-cycle" "$ACTIVE_CYCLE"

cleanup_test_dir
echo ""

# Test 2: Clears PLANNING_CYCLE
begin_test "Clears PLANNING_CYCLE on activation"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

# Set a planning cycle first
bash "$SCRIPTS_DIR/update-global-state.sh" PLANNING_CYCLE "1-test-cycle" "$TEST_DIR"

bash "$START_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

source "$TEST_DIR/.craft/.global-state"
assert_eq "PLANNING_CYCLE cleared" "" "$PLANNING_CYCLE"

cleanup_test_dir
echo ""

# Test 3: Sets cycle .state to active
begin_test "Sets cycle CYCLE_STATUS to active"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$START_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

source "$CYCLE_DIR/.state"
assert_eq "CYCLE_STATUS is active" "active" "$CYCLE_STATUS"

cleanup_test_dir
echo ""

# Test 4: Updates cycle.yaml status
begin_test "Updates cycle.yaml status to active"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

bash "$START_CYCLE_SCRIPT" "$CYCLE_DIR" >/dev/null 2>&1

assert_file_contains "cycle.yaml has status: active" "status: active" "$CYCLE_DIR/cycle.yaml"

cleanup_test_dir
echo ""

# Test 5: Output shows human-readable message
begin_test "Output shows cycle started message"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
CYCLE_DIR="$TEST_DIR/.craft/cycles/1-test-cycle"

RESULT=$(bash "$START_CYCLE_SCRIPT" "$CYCLE_DIR" 2>/dev/null)

assert_contains "shows started message" "started" "$RESULT"

cleanup_test_dir
echo ""

# Test 6: No arguments — exits 1
begin_test "No arguments — exits 1"

set +e
RESULT=$(bash "$START_CYCLE_SCRIPT" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 with no args" "1" "$EXIT_CODE"
echo ""

# Test 7: Non-existent cycle — exits 1
begin_test "Non-existent cycle — exits 1"

set +e
RESULT=$(bash "$START_CYCLE_SCRIPT" "/nonexistent/cycle" 2>/dev/null)
EXIT_CODE=$?
set -e

assert_eq "exits 1 for missing cycle" "1" "$EXIT_CODE"
echo ""

# --- Summary ---
finish_tests
