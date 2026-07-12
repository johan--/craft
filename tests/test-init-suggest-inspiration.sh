#!/bin/bash
# test-init-suggest-inspiration.sh - Guard the Phase 2b suggestion beat in craft-init.md.
# Doc-level assertions that the intent-seeded inspiration suggestions are specced as
# locked: the conditional third gate option, the single verified-inline subagent spawn,
# the dare-floor framing, the one-re-roll rule, and the degrade path. Adjacent stories
# edit this same file; a paraphrased label or a resurrected killed pattern should fail
# the suite, not slip through review.

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

INIT="$PLUGIN_ROOT/commands/craft-init.md"

# The beat region, extracted for scoped negative assertions (muse legitimately appears
# elsewhere in craft-init.md - Phase 5b - so whole-file negatives can't be used for it).
BEAT="$(sed -n '/The suggestion beat/,/^---$/p' "$INIT")"

# --- The third option is present, first, recommended, and conditional ---
begin_test "the gate gains the suggest option - first, recommended, intent-gated"
assert_file_exists "craft-init.md exists" "$INIT"
assert_file_contains "suggest option label with marker" 'label: "Suggest some for me (Recommended)"' "$INIT"
assert_file_contains "gate has an INTENT_CAPTURED=true branch" '\*\*If INTENT_CAPTURED=true:\*\*' "$INIT"
assert_file_contains "gate has an INTENT_CAPTURED=false branch" '\*\*If INTENT_CAPTURED=false:\*\*' "$INIT"
# Order: within the true-branch AUQ block, Suggest is listed before the Yes option
TRUE_BRANCH="$(sed -n '/\*\*If INTENT_CAPTURED=true:\*\*/,/\*\*If INTENT_CAPTURED=false:\*\*/p' "$INIT")"
FIRST_TWO_LABELS="$(echo "$TRUE_BRANCH" | grep -o 'label: "[^"]*"' | head -2)"
assert_contains "suggest option is listed first in the true branch" 'Suggest some for me' "$(echo "$FIRST_TWO_LABELS" | head -1)"

# --- Both existing options preserved verbatim, and scoped to the false branch too ---
begin_test "both existing gate options survive byte-for-byte in both branches"
assert_file_contains "yes option label" 'label: "Yes, I have reference sites"' "$INIT"
assert_file_contains "yes option description" 'Pull colors, typography, spacing from sites I admire' "$INIT"
assert_file_contains "no option label" 'label: "No, continue with what we have"' "$INIT"
assert_file_contains "no option description" 'Use the token decision from Phase 2' "$INIT"
FALSE_BRANCH="$(sed -n '/\*\*If INTENT_CAPTURED=false:\*\*/,/\*\*Routing (both branches):\*\*/p' "$INIT")"
assert_contains "false branch keeps the yes option" 'label: "Yes, I have reference sites"' "$FALSE_BRANCH"
assert_contains "false branch keeps the no option" 'label: "No, continue with what we have"' "$FALSE_BRANCH"
assert_not_contains "false branch has no suggest option" 'Suggest some for me' "$FALSE_BRANCH"

# --- The dispatch: one general-purpose haiku subagent, inline, seeded, verified ---
begin_test "the beat dispatches exactly one verified inline subagent"
assert_contains "spawns exactly one subagent" 'Spawn EXACTLY ONE subagent via the Task tool' "$BEAT"
assert_contains "subagent_type is general-purpose" 'subagent_type: "general-purpose"' "$BEAT"
assert_contains "haiku requested" 'model: "haiku"' "$BEAT"
assert_contains "seeded from Q1 verbatim" 'PROJECT_INTENT_Q1 verbatim' "$BEAT"
assert_contains "seeded from Q2 verbatim" 'PROJECT_INTENT_Q2 verbatim' "$BEAT"
assert_contains "WebFetch verification required" 'Verify EVERY candidate with WebFetch' "$BEAT"
assert_contains "no model-memory URLs" 'NEVER suggest a URL from model memory' "$BEAT"
assert_contains "inline return required" 'Return your result INLINE' "$BEAT"
assert_contains "no file writes" 'Do NOT write any file' "$BEAT"
assert_contains "return shape is URL, stance, why" 'URL | stance name | one-line why' "$BEAT"

# --- Dare-floor, react-against framing, conversational reaction ---
begin_test "dare-floor and react-against framing are specced"
assert_contains "stances not variations" 'genuinely different stances, not variations' "$BEAT"
assert_contains "dare-floor" 'outside the obvious category' "$BEAT"
assert_contains "react-against framing" 'starting points to react against' "$BEAT"
assert_contains "reaction is conversational" 'invite a reaction conversationally' "$BEAT"
assert_contains "no widget at the beat" 'no AskUserQuestion widget at this beat' "$BEAT"
assert_contains "bring-your-own URL stays first-class" 'first-class answer' "$BEAT"

# --- One re-roll, then manual; unpicked candidates ride the existing loop ---
begin_test "reject-all fires exactly one seeded re-roll, then falls back"
assert_contains "exactly one re-roll" 'fire exactly ONE re-roll' "$BEAT"
assert_contains "re-roll is seeded by rejections" 'rejections appended to the prompt as constraints' "$BEAT"
assert_contains "second rejection stops suggesting" 'stop suggesting' "$BEAT"
assert_contains "unpicked candidates ride the existing loop" 'Add another source' "$BEAT"

# --- Degrade rules: never an unverified URL ---
begin_test "degrade path falls back to today's flow"
assert_contains "sentinel handled" 'NO_VERIFIED_CANDIDATES' "$BEAT"
assert_contains "WebSearch-unavailable degrade" 'If WebSearch is unavailable' "$BEAT"
assert_contains "never an unverified URL" 'Never show an unverified URL' "$BEAT"

# --- Phase 3 entry gains the additive bullet, and Phase 3a implements the skip ---
begin_test "Phase 3 entry conditions carry the picked-URL path"
assert_file_contains "picked-URL entry bullet" 'picked a suggested candidate' "$INIT"
assert_file_contains "skip the opening URL ask" 'skips its opening URL ask' "$INIT"
SOURCE_LOOP="$(sed -n '/\*\*Source collection loop:\*\*/,/header: "Aspects"/p' "$INIT")"
assert_contains "Phase 3a source loop has the arrival conditional" 'If arriving from the Phase 2b suggestion beat' "$SOURCE_LOOP"
assert_contains "arrival conditional skips the prompt" 'skip the prompt below' "$SOURCE_LOOP"

# --- Killed patterns stay gone (scoped to the beat region) ---
begin_test "killed patterns stay out of the beat"
assert_not_contains "no muse in the beat" '[Mm]use' "$BEAT"
assert_not_contains "no auto-selection" '[Aa]uto-select one of' "$BEAT"
assert_contains "never auto-selected stated" 'Never auto-select' "$BEAT"
assert_not_contains "no craft:researcher dispatch" 'craft:researcher' "$BEAT"

finish_tests "test-init-suggest-inspiration"
