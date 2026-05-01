#!/bin/bash
# test-append-event.sh — Tests for append-event.sh
# Validates: file creation, JSONL format, data fields, missing dir handling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

APPEND_SCRIPT="$SCRIPTS_DIR/append-event.sh"

# --- Tests ---

echo "=== test-append-event.sh ==="
echo ""

# Test 1: Creates .events/ dir and appends valid JSONL
begin_test "Creates dir and appends valid JSONL"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "story_started" "my-story" chunk_total=3

assert_dir_exists "events dir created" "$EVENTS_DIR"
assert_file_exists "story JSONL file created" "$EVENTS_DIR/my-story.jsonl"

CONTENT=$(cat "$EVENTS_DIR/my-story.jsonl")
assert_contains "has timestamp" '"timestamp"' "$CONTENT"
assert_contains "has type" '"type":"story_started"' "$CONTENT"
assert_contains "has story" '"story":"my-story"' "$CONTENT"
assert_contains "has data" '"data"' "$CONTENT"
assert_contains "has chunk_total in data" '"chunk_total":"3"' "$CONTENT"

# Verify it's exactly one line
LINE_COUNT=$(wc -l < "$EVENTS_DIR/my-story.jsonl" | tr -d ' ')
assert_eq "exactly one line" "1" "$LINE_COUNT"

cleanup_test_dir
echo ""

# Test 2: Appends to existing file (doesn't overwrite)
begin_test "Appends to existing file"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "story_started" "my-story"
bash "$APPEND_SCRIPT" "$EVENTS_DIR" "chunk_completed" "my-story" chunk=1

LINE_COUNT=$(wc -l < "$EVENTS_DIR/my-story.jsonl" | tr -d ' ')
assert_eq "two lines after two appends" "2" "$LINE_COUNT"

# Second line should be chunk_completed
SECOND_LINE=$(tail -1 "$EVENTS_DIR/my-story.jsonl")
assert_contains "second line is chunk_completed" '"type":"chunk_completed"' "$SECOND_LINE"

cleanup_test_dir
echo ""

# Test 3: No data fields — event has no data object
begin_test "No data fields — no data object in JSON"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "cycle_started" "_cycle"

CONTENT=$(cat "$EVENTS_DIR/_cycle.jsonl")
assert_not_contains "no data field" '"data"' "$CONTENT"
assert_contains "has type" '"type":"cycle_started"' "$CONTENT"
assert_contains "story is _cycle" '"story":"_cycle"' "$CONTENT"

cleanup_test_dir
echo ""

# Test 4: Multiple data fields
begin_test "Multiple data key=value pairs"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "usage_recorded" "my-story" agent=implementer tokens=45000 tools=18

CONTENT=$(cat "$EVENTS_DIR/my-story.jsonl")
assert_contains "has agent" '"agent":"implementer"' "$CONTENT"
assert_contains "has tokens" '"tokens":"45000"' "$CONTENT"
assert_contains "has tools" '"tools":"18"' "$CONTENT"

cleanup_test_dir
echo ""

# Test 5: _cycle story routes to _cycle.jsonl
begin_test "_cycle routes to _cycle.jsonl"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "cycle_started" "_cycle" name=test-cycle

assert_file_exists "_cycle.jsonl created" "$EVENTS_DIR/_cycle.jsonl"
assert_file_not_exists "no other file" "$EVENTS_DIR/cycle.jsonl"

cleanup_test_dir
echo ""

# Test 6: Missing args — exits silently
begin_test "Missing args exits 0 silently"

set +e
RESULT=$(bash "$APPEND_SCRIPT" 2>&1)
EXIT_CODE=$?
set -e

assert_eq "exits 0 with no args" "0" "$EXIT_CODE"

set +e
RESULT=$(bash "$APPEND_SCRIPT" "/tmp/test-events" 2>&1)
EXIT_CODE=$?
set -e

assert_eq "exits 0 with partial args" "0" "$EXIT_CODE"

echo ""

# Test 7: Timestamp format is ISO UTC
begin_test "Timestamp is ISO UTC format"

TEST_DIR=$(create_test_dir)
EVENTS_DIR="$TEST_DIR/.events"

bash "$APPEND_SCRIPT" "$EVENTS_DIR" "test_event" "test-story"

CONTENT=$(cat "$EVENTS_DIR/test-story.jsonl")
# Match YYYY-MM-DDTHH:MM:SSZ pattern
assert_contains "ISO UTC timestamp" '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z' "$CONTENT"

cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
