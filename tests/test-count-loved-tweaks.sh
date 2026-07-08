#!/bin/bash
# test-count-loved-tweaks.sh - fixture-driven coverage for the loved-tweak counter.
#
# Every predicate branch (taste stamp, empty reapplies, empty grew_from, the
# last_asked watermark, the space-insensitive parse) and the threshold early-exit
# is constructed from fixtures - the multi-field predicate is the one piece that
# cannot be verified by reading, so it is pinned here.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

COUNTER="$SCRIPT_DIR/../hooks/scripts/count-loved-tweaks.sh"

echo "=== test-count-loved-tweaks.sh ==="
echo ""

# A project root WITH an empty .craft/tweaks/ dir.
new_root() {
  local tr
  tr=$(mktemp -d)
  mkdir -p "$tr/.craft/tweaks"
  echo "$tr"
}

# mk_tweak <root> <name> <created> [extra frontmatter lines...]
mk_tweak() {
  local root="$1" name="$2" created="$3"; shift 3
  {
    echo "---"
    echo "name: $name"
    echo "status: accepted"
    echo "created: $created"
    local line
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo "## Request"
    echo "body"
  } > "$root/.craft/tweaks/$name.md"
}

# mk_state <root> <last_asked> [snooze_offset]
mk_state() {
  local root="$1" last_asked="$2" offset="${3:-0}"
  {
    echo "last_asked: $last_asked"
    echo "snooze_offset: $offset"
  } > "$root/.craft/tweaks/.taste-pass-state"
}

# --- Test 1: no tweaks dir ---
begin_test "no tweaks dir -> 0"
TR=$(mktemp -d)
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "returns 0 when .craft/tweaks/ is absent" "0" "$actual"
rm -rf "$TR"
echo ""

# --- Test 2: cold start ---
begin_test "cold start counts every loved+unspread record"
TR=$(new_root)
mk_tweak "$TR" tweak-a 2026-07-01 "taste: loved"
mk_tweak "$TR" tweak-b 2026-07-02 "taste: loved"
mk_tweak "$TR" tweak-c 2026-07-03 "taste: loved"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "3 loved records, no state file -> 3" "3" "$actual"
rm -rf "$TR"
echo ""

# --- Test 3: routine excluded ---
begin_test "taste: routine is not counted"
TR=$(new_root)
mk_tweak "$TR" tweak-a 2026-07-01 "taste: loved"
mk_tweak "$TR" tweak-b 2026-07-02 "taste: loved"
mk_tweak "$TR" tweak-r 2026-07-03 "taste: routine"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "routine record excluded -> 2" "2" "$actual"
rm -rf "$TR"
echo ""

# --- Test 4: non-empty grew_from excluded ---
begin_test "loved with non-empty grew_from is not counted"
TR=$(new_root)
mk_tweak "$TR" tweak-a 2026-07-01 "taste: loved"
mk_tweak "$TR" tweak-g 2026-07-02 "taste: loved" "grew_from: tweak-a"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "grew_from set -> excluded -> 1" "1" "$actual"
rm -rf "$TR"
echo ""

# --- Test 5: non-empty reapplies excluded ---
begin_test "loved with non-empty reapplies is not counted"
TR=$(new_root)
mk_tweak "$TR" tweak-a 2026-07-01 "taste: loved"
mk_tweak "$TR" tweak-re 2026-07-02 "taste: loved" "reapplies: tweak-a"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "reapplies set -> excluded -> 1" "1" "$actual"
rm -rf "$TR"
echo ""

# --- Test 6: reapplies: none (non-blank) excluded ---
begin_test "loved with reapplies: none is not counted (non-blank disqualifies)"
TR=$(new_root)
mk_tweak "$TR" tweak-a 2026-07-01 "taste: loved"
mk_tweak "$TR" tweak-n 2026-07-02 "taste: loved" "reapplies: none"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "reapplies: none is non-blank -> excluded -> 1" "1" "$actual"
rm -rf "$TR"
echo ""

# --- Test 7: space-insensitive parse ---
begin_test "taste:loved with no space is counted (space-insensitive parse)"
TR=$(new_root)
mk_tweak "$TR" tweak-nospace 2026-07-01 "taste:loved"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "taste:loved parses -> 1" "1" "$actual"
rm -rf "$TR"
echo ""

# --- Test 8: same-day strict ---
begin_test "record created the same day as last_asked is not counted (strict >)"
TR=$(new_root)
mk_tweak "$TR" tweak-sameday 2026-07-05 "taste: loved"
mk_state "$TR" 2026-07-05
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "created == last_asked -> not counted -> 0" "0" "$actual"
rm -rf "$TR"
echo ""

# --- Test 9: strictly-after watermark ---
begin_test "with last_asked set, only strictly-after records count"
TR=$(new_root)
mk_tweak "$TR" old1 2026-07-01 "taste: loved"
mk_tweak "$TR" old2 2026-07-04 "taste: loved"
mk_tweak "$TR" new1 2026-07-06 "taste: loved"
mk_state "$TR" 2026-07-05
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "only the 2026-07-06 record counts -> 1" "1" "$actual"
rm -rf "$TR"
echo ""

# --- Test 10: threshold early-exit ---
begin_test "with 5 qualifying records and threshold arg 3, returns 3 (early-exit)"
TR=$(new_root)
mk_tweak "$TR" t1 2026-07-01 "taste: loved"
mk_tweak "$TR" t2 2026-07-02 "taste: loved"
mk_tweak "$TR" t3 2026-07-03 "taste: loved"
mk_tweak "$TR" t4 2026-07-04 "taste: loved"
mk_tweak "$TR" t5 2026-07-05 "taste: loved"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER" 3)
assert_eq "early-exit at threshold 3 -> 3" "3" "$actual"
# and the no-arg total is still exact
total=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
assert_eq "no-arg call still returns the exact total -> 5" "5" "$total"
rm -rf "$TR"
echo ""

# --- Test 11: bare integer output ---
begin_test "output is a bare integer, no extra text"
TR=$(new_root)
mk_tweak "$TR" t1 2026-07-01 "taste: loved"
mk_tweak "$TR" t2 2026-07-02 "taste: loved"
actual=$(CRAFT_PROJECT_ROOT="$TR" bash "$COUNTER")
if [[ "$actual" =~ ^[0-9]+$ ]]; then
  assert_eq "output is purely numeric -> 2" "2" "$actual"
else
  assert_eq "output should be a bare integer" "bare-int" "not-bare:$actual"
fi
rm -rf "$TR"
echo ""

finish_tests
