#!/bin/bash
# test-mark-observations-surfaced.sh - Tests for mark-observations-surfaced.sh
# (idempotent, best-effort clear event).

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

APPEND="$SCRIPTS_DIR/observations-append.sh"
MARK="$SCRIPTS_DIR/mark-observations-surfaced.sh"

unread_count() { local c; c=$(grep -c "surfaced: false" "$1" 2>/dev/null || true); echo "${c:-0}"; }
surfaced_count() { local c; c=$(grep -c "surfaced: true" "$1" 2>/dev/null || true); echo "${c:-0}"; }

# --- Test 1 (FIRST): flips matching entry false -> true ---
begin_test "flips matching entry false -> true"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "x.sh:42" "desc" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/s.yaml"
bash "$MARK" "$SIDECAR" "x.sh:42"
assert_eq "no unread remain" "0" "$(unread_count "$SIDECAR")"
assert_eq "one entry surfaced" "1" "$(surfaced_count "$SIDECAR")"
cleanup_test_dir

# --- Test 2: idempotent on second run ---
begin_test "idempotent on second run"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "x.sh:42" "desc" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/s.yaml"
bash "$MARK" "$SIDECAR" "x.sh:42"
first=$(cat "$SIDECAR")
set +e
bash "$MARK" "$SIDECAR" "x.sh:42"
code=$?
set -e
assert_exit_code "second run exits 0" "0" "$code"
assert_eq "file unchanged on second run" "$first" "$(cat "$SIDECAR")"
assert_eq "still surfaced" "1" "$(surfaced_count "$SIDECAR")"
cleanup_test_dir

# --- Test 3: best-effort on missing sidecar ---
begin_test "best-effort on missing sidecar"
TEST_DIR=$(create_test_dir)
set +e
err=$(bash "$MARK" "$TEST_DIR/nope/missing.yaml" "x.sh:1" 2>&1)
code=$?
set -e
assert_exit_code "missing sidecar exits 0" "0" "$code"
assert_eq "no error output" "" "$err"
cleanup_test_dir

# --- Test 4: unmatched loc is a no-op ---
begin_test "unmatched loc is a no-op"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "x.sh:42" "desc" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/s.yaml"
before=$(cat "$SIDECAR")
set +e
bash "$MARK" "$SIDECAR" "other.sh:99"
code=$?
set -e
assert_exit_code "unmatched loc exits 0" "0" "$code"
assert_eq "file unchanged" "$before" "$(cat "$SIDECAR")"
assert_eq "entry still unread" "1" "$(unread_count "$SIDECAR")"
cleanup_test_dir

# --- Test 5: flips multiple locs in one call ---
begin_test "flips multiple locs in one call"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "a.sh:1" "one" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "suspicion" "modest" "b.sh:2" "two" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "c.sh:3" "three" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/s.yaml"
bash "$MARK" "$SIDECAR" "a.sh:1" "b.sh:2" "c.sh:3"
assert_eq "all flipped, none unread" "0" "$(unread_count "$SIDECAR")"
assert_eq "three surfaced" "3" "$(surfaced_count "$SIDECAR")"
cleanup_test_dir

# --- Test 6: flips only the targeted loc, leaves others unread ---
begin_test "flips only targeted loc, leaves others unread"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "a.sh:1" "one" >/dev/null 2>&1
bash "$APPEND" "$CYCLE" "s" "confirmed" "high" "b.sh:2" "two" >/dev/null 2>&1
SIDECAR="$CYCLE/.observations/s.yaml"
bash "$MARK" "$SIDECAR" "a.sh:1"
assert_eq "one still unread" "1" "$(unread_count "$SIDECAR")"
assert_eq "one surfaced" "1" "$(surfaced_count "$SIDECAR")"
cleanup_test_dir

finish_tests
