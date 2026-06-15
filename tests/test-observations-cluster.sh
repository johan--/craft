#!/bin/bash
# test-observations-cluster.sh - Tests for observations-cluster.sh
# (deterministic proximity clustering + file:line dedup).

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

APPEND="$SCRIPTS_DIR/observations-append.sh"
CLUSTER="$SCRIPTS_DIR/observations-cluster.sh"

# --- Test 1 (FIRST): dedups identical file:line to one entry ---
begin_test "dedups identical file:line to one entry"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
# Two stories both flag the SAME loc
bash "$APPEND" "$CYCLE" "story-a" "confirmed" "high" "shared.sh:10" "from a" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "story-b" "confirmed" "high" "shared.sh:10" "from b" >/dev/null 2>&1
out=$(bash "$CLUSTER" "$CYCLE")
loc_lines=$(echo "$out" | grep -c "shared.sh:10")
assert_eq "duplicate loc collapses to one" "1" "$loc_lines"
cleanup_test_dir

# --- Test 2: prefers confirmed over suspicion on loc conflict ---
begin_test "prefers confirmed over suspicion on loc conflict"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
# first-seen (sorted file order: a before b) is suspicion; b is confirmed -> confirmed wins
bash "$APPEND" "$CYCLE" "story-a" "suspicion" "modest" "x.sh:5" "weak" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "story-b" "confirmed" "high" "x.sh:5" "strong" >/dev/null 2>&1
out=$(bash "$CLUSTER" "$CYCLE")
assert_contains "confirmed grade survives" "x.sh:5 \[confirmed/" "$out"
assert_not_contains "suspicion did not win" "x.sh:5 \[suspicion/" "$out"
cleanup_test_dir

# --- Test 3: groups same-file entries into one cluster ---
begin_test "groups same-file entries into one cluster"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "same.sh:1" "one" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "same.sh:9" "two" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "other.sh:1" "three" >/dev/null 2>&1
out=$(bash "$CLUSTER" "$CYCLE")
cluster_count=$(echo "$out" | grep -c "^CLUSTER=")
assert_eq "two clusters (two distinct files)" "2" "$cluster_count"
assert_contains "same.sh cluster has count 2" "CLUSTER=same.sh (2)" "$out"
assert_contains "other.sh cluster has count 1" "CLUSTER=other.sh (1)" "$out"
cleanup_test_dir

# --- Test 4: grouping is reproducible (byte-identical) ---
begin_test "grouping is reproducible"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "b.sh:3" "x" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "suspicion" "modest" "a.sh:7" "y" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "a.sh:2" "z" >/dev/null 2>&1
run1=$(bash "$CLUSTER" "$CYCLE")
run2=$(bash "$CLUSTER" "$CYCLE")
assert_eq "two runs byte-identical" "$run1" "$run2"
# entries within a.sh ordered by line number (2 before 7)
a2=$(echo "$run1" | grep -n "a.sh:2" | cut -d: -f1)
a7=$(echo "$run1" | grep -n "a.sh:7" | cut -d: -f1)
if [ -n "$a2" ] && [ -n "$a7" ] && [ "$a2" -lt "$a7" ]; then
  echo "  PASS: entries ordered by line number within file"
  PASS=$((PASS + 1))
else
  echo "  FAIL: line ordering wrong (a2=$a2 a7=$a7)"
  FAIL=$((FAIL + 1))
fi
cleanup_test_dir

# --- Test 5: surfaced entries are excluded from clustering ---
begin_test "surfaced entries excluded"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "live.sh:1" "unread" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "done.sh:1" "to-surface" >/dev/null 2>&1
# surface the second one
bash "$SCRIPTS_DIR/mark-observations-surfaced.sh" "$CYCLE/.observations/s.yaml" "done.sh:1"
out=$(bash "$CLUSTER" "$CYCLE")
assert_contains "unread entry present" "live.sh:1" "$out"
assert_not_contains "surfaced entry excluded" "done.sh:1" "$out"
cleanup_test_dir

# --- Test 6: empty when no unread ---
begin_test "empty output when no .observations"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
set +e
out=$(bash "$CLUSTER" "$CYCLE")
code=$?
set -e
assert_eq "empty output" "" "$out"
assert_exit_code "exit 0" "0" "$code"
cleanup_test_dir

# --- Test 7: surfacing reference pins the one-line recommendation format ---
begin_test "surfacing reference pins one-line recommendation format"
DOC="$PLUGIN_ROOT/commands/references/observations-surfacing.md"
assert_file_exists "surfacing reference exists" "$DOC"
assert_file_contains "pins the format spec" "<cluster-name> (<count>): <lean> - <short reason>" "$DOC"
assert_file_contains "has worked example" "error-handling (5): story lean" "$DOC"
assert_file_contains "states one line per cluster" "One line per cluster" "$DOC"
assert_file_contains "mark-surfaced runs LAST" "LAST" "$DOC"
assert_file_contains "circle-back is exactly one todo" "never N separate todos" "$DOC"
assert_file_contains "autonomous is a no-op" "RUN_MODE=autonomous" "$DOC"

finish_tests
