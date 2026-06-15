#!/bin/bash
# test-observations-append.sh - Tests for observations-append.sh (sidecar write helper)

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

APPEND="$SCRIPTS_DIR/observations-append.sh"

# --- Test 1: appends an entry with all schema keys ---
begin_test "appends an entry with all schema keys"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cycle"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "my-story" "confirmed" "high" "hooks/scripts/foo.sh:42" "duplicated date math, omits tz guard" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/my-story.yaml"
assert_file_exists "sidecar written" "$SIDECAR"
body=$(cat "$SIDECAR")
assert_contains "has observations list header" "^observations:" "$body"
assert_contains "stamps grade" "grade: \"confirmed\"" "$body"
assert_contains "stamps severity" "severity: \"high\"" "$body"
assert_contains "stamps loc verbatim" "hooks/scripts/foo.sh:42" "$body"
assert_contains "surfaced false at write time" "surfaced: false" "$body"
assert_contains "stamps ISO created" "created: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T" "$body"
assert_contains "stamps craft_version" "craft_version: " "$body"
cleanup_test_dir

# --- Test 2: creates .observations dir on demand ---
begin_test "creates .observations dir on demand"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cycle"
mkdir -p "$CYCLE"
assert_dir_not_exists "no .observations before" "$CYCLE/.observations"
bash "$APPEND" "$CYCLE" "s" "suspicion" "modest" "a/b.sh:1" "desc" >/dev/null 2>&1
assert_dir_exists ".observations created on demand" "$CYCLE/.observations"
assert_file_exists "sidecar created" "$CYCLE/.observations/s.yaml"
cleanup_test_dir

# --- Test 3: second append to same story stays in one file ---
begin_test "second append to same story stays in one file"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cycle"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "one-story" "confirmed" "high" "x.sh:1" "first" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "one-story" "suspicion" "modest" "x.sh:9" "second" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/one-story.yaml"
file_count=$(ls -1 "$CYCLE/.observations/" | wc -l | tr -d ' ')
assert_eq "exactly one sidecar file" "1" "$file_count"
entry_count=$(grep -c "^  - story:" "$SIDECAR")
assert_eq "two entries appended" "2" "$entry_count"
header_count=$(grep -c "^observations:" "$SIDECAR")
assert_eq "list header written once" "1" "$header_count"
cleanup_test_dir

# --- Test 4: craft_version override is honored ---
begin_test "craft_version override is honored"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cycle"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "x.sh:1" "desc" --craft-version=9.9.9 >/dev/null 2>&1
assert_contains "override lands verbatim" "craft_version: 9.9.9" "$(cat "$CYCLE/.observations/s.yaml")"
cleanup_test_dir

# --- Test 5: empty required arg writes nothing ---
begin_test "empty required arg writes nothing"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cycle"
mkdir -p "$CYCLE"
# empty grade
set +e
bash "$APPEND" "$CYCLE" "s" "" "high" "x.sh:1" "desc" >/dev/null 2>&1
code_grade=$?
set -e
assert_exit_code "empty grade exits 0" "0" "$code_grade"
assert_file_not_exists "empty grade writes no sidecar" "$CYCLE/.observations/s.yaml"
# empty loc
set +e
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "" "desc" >/dev/null 2>&1
code_loc=$?
set -e
assert_exit_code "empty loc exits 0" "0" "$code_loc"
assert_file_not_exists "empty loc writes no sidecar" "$CYCLE/.observations/s.yaml"
cleanup_test_dir

finish_tests
