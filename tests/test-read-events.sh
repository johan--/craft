#!/bin/bash
# test-read-events.sh — Tests for read-events.sh
# Validates: story filter, type filter, --last, empty dir, graceful fallback

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-events.sh"

READ_SCRIPT="$SCRIPTS_DIR/read-events.sh"

# --- Tests ---

echo "=== test-read-events.sh ==="
echo ""

# Test 1: Read all events from a specific story
begin_test "Read all events for a story"

TEST_DIR=$(create_craft_with_events)
trap cleanup_test_dir EXIT
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=test-story)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
assert_eq "4 events for test-story" "4" "$LINE_COUNT"
assert_contains "has story_started" '"type":"story_started"' "$RESULT"
assert_contains "has chunk_completed" '"type":"chunk_completed"' "$RESULT"
assert_contains "has tool_failure" '"type":"tool_failure"' "$RESULT"

cleanup_test_dir
echo ""

# Test 2: Filter by type across all stories
begin_test "Filter by type across all stories"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --type=chunk_completed)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
assert_eq "3 chunk_completed events total" "3" "$LINE_COUNT"

cleanup_test_dir
echo ""

# Test 3: Filter by type within a story
begin_test "Filter by type within a story"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=test-story --type=chunk_completed)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
assert_eq "2 chunk_completed for test-story" "2" "$LINE_COUNT"

cleanup_test_dir
echo ""

# Test 4: --last=N returns last N events
begin_test "--last=N returns last N events"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=test-story --last=2)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
assert_eq "last 2 events returned" "2" "$LINE_COUNT"

# Last event should be the final chunk_completed
LAST_LINE=$(echo "$RESULT" | tail -1)
assert_contains "last event is chunk_completed" '"chunk":"2"' "$LAST_LINE"

cleanup_test_dir
echo ""

# Test 5: Read cycle-level events
begin_test "Read _cycle events"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=_cycle)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
assert_eq "2 cycle events" "2" "$LINE_COUNT"
assert_contains "has cycle_started" '"type":"cycle_started"' "$RESULT"
assert_contains "has cycle_completed" '"type":"cycle_completed"' "$RESULT"

cleanup_test_dir
echo ""

# Test 6: Missing events dir — exits silently
begin_test "Missing events dir exits 0 silently"

set +e
RESULT=$(bash "$READ_SCRIPT" "/tmp/nonexistent-events-dir-12345" 2>&1)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"
assert_eq "no output" "" "$RESULT"

echo ""

# Test 7: Missing story file — exits silently
begin_test "Missing story file exits 0 silently"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

set +e
RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=nonexistent-story 2>&1)
EXIT_CODE=$?
set -e

assert_eq "exits 0" "0" "$EXIT_CODE"
assert_eq "no output" "" "$RESULT"

cleanup_test_dir
echo ""

# Test 8: No args — exits silently
begin_test "No args exits 0 silently"

set +e
RESULT=$(bash "$READ_SCRIPT" 2>&1)
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no args" "0" "$EXIT_CODE"

echo ""

# Test 9: Type filter with no matches — returns empty
begin_test "Type filter with no matches returns empty"

TEST_DIR=$(create_craft_with_events)
EVENTS_DIR="$TEST_DIR/.craft/cycles/1-test-cycle/.events"

RESULT=$(bash "$READ_SCRIPT" "$EVENTS_DIR" --story=test-story --type=nonexistent_type)

assert_eq "empty result" "" "$RESULT"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
