#!/bin/bash
# test-taste-pass-state.sh - fixture-driven runtime coverage for the state mutator.
#
# The state machine (accept resets, below-cap decline raises the offset, disable
# flips the settings key portably) is moved out of orchestrator prose into
# taste-pass-state.sh precisely so it can be unit-tested here rather than trusted.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

STATE_SH="$SCRIPT_DIR/../hooks/scripts/taste-pass-state.sh"

echo "=== test-taste-pass-state.sh ==="
echo ""

new_root() {
  local tr
  tr=$(mktemp -d)
  mkdir -p "$tr/.craft/tweaks"
  echo "$tr"
}

state_field() {
  # <root> <field>
  grep -m1 "^$2:" "$1/.craft/tweaks/.taste-pass-state" | sed "s/^$2:[[:space:]]*//"
}

# --- accept ---
begin_test "accept writes last_asked=today and snooze_offset=0"
TR=$(new_root)
printf 'last_asked: 2026-01-01\nsnooze_offset: 5\n' > "$TR/.craft/tweaks/.taste-pass-state"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" accept
assert_eq "last_asked advanced to today" "$(date +%Y-%m-%d)" "$(state_field "$TR" last_asked)"
assert_eq "snooze_offset reset to 0" "0" "$(state_field "$TR" snooze_offset)"
rm -rf "$TR"
echo ""

# --- decline ladder ---
begin_test "decline ladder: 0->2, 2->5, 5->5 (cap), last_asked untouched"
TR=$(new_root)
printf 'last_asked: 2026-07-01\nsnooze_offset: 0\n' > "$TR/.craft/tweaks/.taste-pass-state"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" decline
assert_eq "0 -> 2" "2" "$(state_field "$TR" snooze_offset)"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" decline
assert_eq "2 -> 5" "5" "$(state_field "$TR" snooze_offset)"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" decline
assert_eq "5 -> 5 (cap)" "5" "$(state_field "$TR" snooze_offset)"
assert_eq "last_asked untouched across declines" "2026-07-01" "$(state_field "$TR" last_asked)"
rm -rf "$TR"
echo ""

# --- decline from cold (no state file) ---
begin_test "decline with no state file creates it at offset 2"
TR=$(new_root)
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" decline
assert_file_exists "state file created by decline" "$TR/.craft/tweaks/.taste-pass-state"
assert_eq "cold decline -> offset 2" "2" "$(state_field "$TR" snooze_offset)"
rm -rf "$TR"
echo ""

# --- effective-threshold, base 3 ---
begin_test "effective-threshold: base 3 + offset {0,2,5} = {3,5,8}"
TR=$(new_root)
printf 'taste_pass_threshold: 3\n' > "$TR/.craft/settings.yaml"
printf 'last_asked: 2026-07-01\nsnooze_offset: 0\n' > "$TR/.craft/tweaks/.taste-pass-state"
assert_eq "3 + 0 = 3" "3" "$(CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" effective-threshold)"
printf 'last_asked: 2026-07-01\nsnooze_offset: 2\n' > "$TR/.craft/tweaks/.taste-pass-state"
assert_eq "3 + 2 = 5" "5" "$(CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" effective-threshold)"
printf 'last_asked: 2026-07-01\nsnooze_offset: 5\n' > "$TR/.craft/tweaks/.taste-pass-state"
assert_eq "3 + 5 = 8" "8" "$(CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" effective-threshold)"
rm -rf "$TR"
echo ""

# --- effective-threshold, base 10 (escalation stays above any base) ---
begin_test "effective-threshold: base 10 + offset 5 = 15"
TR=$(new_root)
printf 'taste_pass_threshold: 10\n' > "$TR/.craft/settings.yaml"
printf 'last_asked: 2026-07-01\nsnooze_offset: 5\n' > "$TR/.craft/tweaks/.taste-pass-state"
assert_eq "10 + 5 = 15" "15" "$(CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" effective-threshold)"
rm -rf "$TR"
echo ""

# --- effective-threshold defaults when settings/state absent ---
begin_test "effective-threshold defaults to base 3, offset 0 when nothing is set"
TR=$(new_root)
assert_eq "no settings, no state -> 3" "3" "$(CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" effective-threshold)"
rm -rf "$TR"
echo ""

# --- disable: replace existing key ---
begin_test "disable replaces an existing taste_pass_enabled: true -> exactly one false line"
TR=$(new_root)
printf 'default_mode: creative\ntaste_pass_enabled: true\ntaste_pass_threshold: 3\n' > "$TR/.craft/settings.yaml"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" disable
assert_eq "exactly one taste_pass_enabled line" "1" "$(grep -c '^taste_pass_enabled:' "$TR/.craft/settings.yaml")"
assert_eq "grep -m1 value is false" "false" "$(grep -m1 '^taste_pass_enabled:' "$TR/.craft/settings.yaml" | sed 's/^taste_pass_enabled:[[:space:]]*//')"
assert_file_contains "other keys preserved" "default_mode: creative" "$TR/.craft/settings.yaml"
rm -rf "$TR"
echo ""

# --- disable: collapse pre-existing duplicate keys ---
begin_test "disable collapses pre-existing duplicate keys to exactly one false line"
TR=$(new_root)
printf 'default_mode: creative\ntaste_pass_enabled: true\ntaste_pass_enabled: true\n' > "$TR/.craft/settings.yaml"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" disable
assert_eq "duplicate keys collapsed to exactly one line" "1" "$(grep -c '^taste_pass_enabled:' "$TR/.craft/settings.yaml")"
assert_eq "the surviving line is false" "false" "$(grep -m1 '^taste_pass_enabled:' "$TR/.craft/settings.yaml" | sed 's/^taste_pass_enabled:[[:space:]]*//')"
assert_file_contains "unrelated keys preserved" "default_mode: creative" "$TR/.craft/settings.yaml"
rm -rf "$TR"
echo ""

# --- disable: append when key absent ---
begin_test "disable appends the key once when settings.yaml lacks it"
TR=$(new_root)
printf 'default_mode: creative\n' > "$TR/.craft/settings.yaml"
CRAFT_PROJECT_ROOT="$TR" bash "$STATE_SH" disable
assert_eq "key appended exactly once" "1" "$(grep -c '^taste_pass_enabled:' "$TR/.craft/settings.yaml")"
assert_eq "appended value is false" "false" "$(grep -m1 '^taste_pass_enabled:' "$TR/.craft/settings.yaml" | sed 's/^taste_pass_enabled:[[:space:]]*//')"
rm -rf "$TR"
echo ""

finish_tests
