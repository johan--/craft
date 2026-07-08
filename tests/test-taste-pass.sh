#!/bin/bash
# test-taste-pass.sh - doc-structure guard for the two taste-pass reference files.
#
# Runtime state effects live in test-taste-pass-state.sh (beside the script). This
# file pins the scout constraints, the graceful-degradation path, the pacing policy,
# the anti-patterns, and the disable branch's three outcomes - the prose contracts
# that both propagation doors depend on. Lineage read/write-side greps are added
# alongside the mockup-hop work.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

TASTE_MD="$SCRIPT_DIR/../commands/references/taste-pass.md"
DISABLE_MD="$SCRIPT_DIR/../commands/references/taste-pass-disable.md"
MOCKUP_MD="$SCRIPT_DIR/../commands/references/mockup-inline.md"
STORY_MD="$SCRIPT_DIR/../commands/references/story-from-mockup.md"
TWEAK_MD="$SCRIPT_DIR/../skills/adhoc/references/tweak.md"

echo "=== test-taste-pass.sh ==="
echo ""

assert_file_exists "taste-pass.md exists" "$TASTE_MD"
assert_file_exists "taste-pass-disable.md exists" "$DISABLE_MD"

TASTE="$(cat "$TASTE_MD")"
DISABLE="$(cat "$DISABLE_MD")"
echo ""

# --- Scout constraints ---
begin_test "scout forbids tokens/locked gating"
assert_contains_literal "no tokens/locked gate on discovery" "NO tokens/locked gate on discovery" "$TASTE"
echo ""

begin_test "scout forbids new agent / subagent / style-analyzer"
assert_contains_literal "no style-analyzer / agent / subagent" "NO \`style-analyzer\`, NO new agent, NO subagent" "$TASTE"
echo ""

begin_test "scout POINTS, never prescribes"
assert_contains_literal "points, never prescribes" "POINTS, never prescribes" "$TASTE"
echo ""

# --- Graceful degradation ---
begin_test "documents the no-visual graceful-degradation fallback"
assert_contains_literal "points from code when it can't see live" "pointing from the code" "$TASTE"
assert_contains_literal "accepting is never a dead end" "NEVER a dead end" "$TASTE"
echo ""

# --- Anti-patterns ---
begin_test "carries all three anti-patterns as do-not lines"
assert_contains_literal "anti-pattern 1: no gating discovery" "Do NOT gate discovery on tokens/locked/quality" "$TASTE"
assert_contains_literal "anti-pattern 2: no locking mockup to seed" "Do NOT lock the mockup to the seed vibe" "$TASTE"
assert_contains_literal "anti-pattern 3: never sever lineage" "Do NOT sever lineage when the outcome diverged" "$TASTE"
echo ""

# --- Pacing calls the state script ---
begin_test "pacing calls taste-pass-state.sh accept on accept, decline on below-cap decline"
assert_contains_literal "accept action wired" "state.sh\" accept" "$TASTE"
assert_contains_literal "decline action wired" "state.sh\" decline" "$TASTE"
echo ""

# --- Silence + second-in-session ---
begin_test "pure silence writes nothing (explicit-lock cite); second in-session offer intentional"
assert_contains_literal "silence writes nothing" "Pure silence writes NOTHING" "$TASTE"
assert_contains_literal "cites explicit-lock-confirmation" "explicit-lock-confirmation" "$TASTE"
assert_contains_literal "second in-session offer is intentional" "second offer in one session is intentional" "$TASTE"
echo ""

# --- Same-day quiet ---
begin_test "same-day-after-a-pass quiet stated as designed"
assert_contains_literal "same-day quiet is designed" "Same-day quiet is designed" "$TASTE"
echo ""

# --- Handoff dossier ---
begin_test "one todo per winner, shared family tag, source as a quoted wikilink"
assert_contains_literal "one todo per winner" "one notebook todo per winner" "$TASTE"
assert_contains_literal "shared family tag" "family tag" "$TASTE"
assert_contains_literal "source is a quoted wikilink" "QUOTED wikilink" "$TASTE"
echo ""

# --- Disable branch ---
begin_test "taste-pass-disable.md has three outcomes incl. neither terminal-reset and calls disable"
assert_contains_literal "outcome: disable forever" "Disable forever" "$DISABLE"
assert_contains_literal "outcome: run it now" "Run it now" "$DISABLE"
assert_contains_literal "outcome: neither (terminal reset)" "SINGLE decline that RESETS" "$DISABLE"
assert_contains_literal "disable action wired" "state.sh\" disable" "$DISABLE"
echo ""

# --- Lineage across the mockup hop (both ramps, read + write) ---
MOCKUP="$(cat "$MOCKUP_MD")"
STORY="$(cat "$STORY_MD")"
TWEAK="$(cat "$TWEAK_MD")"

begin_test "mockup record schema carries an origin field"
assert_contains_literal "record.md has an origin field" "origin: [origin tweak name when launched from a taste-pass todo" "$MOCKUP"
echo ""

begin_test "tweak-ramp handoff forwards origin"
assert_contains_literal "handoff forwards origin to the ported tweak" "grew from [origin]" "$MOCKUP"
echo ""

begin_test "tweak.md port branch stamps grew_from from the handoff origin"
assert_contains_literal "port branch has the read-side grew_from write" "This is the read side of the lineage" "$TWEAK"
echo ""

begin_test "story-ramp writes grew_from from the record origin"
assert_contains_literal "story ramp forwards origin as grew_from" 'forward it as `grew_from:` on the produced story' "$STORY"
echo ""

begin_test "lineage language is unconditional (never severed on divergence)"
assert_contains_literal "tweak ramp: never severed on divergence" "however far it diverged from the seed" "$TWEAK"
assert_contains_literal "story ramp: never severed on divergence" "however far it diverged from the seed" "$STORY"
echo ""

finish_tests
