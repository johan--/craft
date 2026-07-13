#!/bin/bash
# test-muse-gets-seen.sh - Guard Story 6's locked strings across the four spec files.
# Doc-level assertions that the muse-visibility edits are specced as locked: the
# prose-then-widget turn presentation rule, the horizon line, the hard-rule annotations,
# the briefing surfacing beats ("Muse's take:" / "Alchemist's take:"), the conditional
# cold-mockup (Recommended) marker, and the Phase 0.5 Emotional Core sell. Adjacent
# stories edit these same shared files; a paraphrased rule or a resurrected silent-fold
# should fail the suite, not slip through review.

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

MUSE="$PLUGIN_ROOT/commands/references/muse-inline.md"

# --- Chunk 1: turn presentation rule (prose leads, widget collects) ---
begin_test "muse leads with prose, widget collects the answer"
assert_file_exists "muse-inline.md exists" "$MUSE"
assert_file_contains "turn presentation rule block present" '### Turn presentation' "$MUSE"
assert_file_contains "prose leads in the message body" 'prose in the message body' "$MUSE"
assert_file_contains "widget only captures the answer" 'only captures the answer' "$MUSE"

begin_test "tight-prose and restate-in-question sub-rules present"
assert_file_contains "tight prose sub-rule" 'Keep the prose tight' "$MUSE"
assert_file_contains "restate-in-question sub-rule" 'restates the one essential idea' "$MUSE"

begin_test "AUQ question field never carries the turn's content"
assert_file_contains "question-field prohibition" 'NEVER carries the turn'"'"'s full content' "$MUSE"
assert_file_contains "pipe-separated walls named as the failure" 'no pipe-separated field dumps' "$MUSE"
assert_file_contains "synthesis turn called out" "special force to Step 6" "$MUSE"

# --- Chunk 1: horizon line (one core-derived non-committal image) ---
begin_test "horizon line is one core-derived non-committal image"
assert_file_contains "horizon line beat present" '### The horizon line' "$MUSE"
assert_file_contains "exactly one forward image" 'ONE forward image' "$MUSE"
assert_file_contains "never a list" 'never a list' "$MUSE"
assert_file_contains "derived from the locked core" 'Derived from the locked Killer Moment or Share Trigger' "$MUSE"
assert_file_contains "explicitly not a commitment" 'not a commitment' "$MUSE"
assert_file_contains "notebook offer is ignorable prose" 'one ignorable prose line' "$MUSE"

begin_test "horizon line adds no new AUQ turn"
assert_file_contains "no new AUQ or header in the beat" 'No AskUserQuestion, no new turn `header:`' "$MUSE"
assert_file_contains "turn-cap rule annotated as wrap-not-5th-turn" 'part of the wrap, not a 5th turn' "$MUSE"

# --- Chunk 1: hard rules intact, annotations only ---
begin_test "no-brainstorming redirect survives verbatim"
assert_file_contains "redirect literal intact" 'Save those for cycle planning' "$MUSE"
assert_file_contains "sanctioned-exception note on the rule" 'an image, not a mode' "$MUSE"

begin_test "4-turn cap rule text intact"
assert_file_contains "cap rule literal intact" 'Cap at 4 turns total' "$MUSE"
assert_file_contains "wrap-and-lock literal intact" 'Wrap and lock at turn 4' "$MUSE"

SPARK="$PLUGIN_ROOT/skills/creative-spark/SKILL.md"

# --- Chunk 2: creative-spark surfaces the returning briefings ---
begin_test "creative-spark surfaces the muse briefing verbatim"
assert_file_exists "creative-spark SKILL.md exists" "$SPARK"
assert_file_contains "muse take quoted to the user" "Muse's take:" "$SPARK"
assert_file_contains "verbatim lines, not summary" 'Quote 2-3 verbatim lines' "$SPARK"

begin_test "Full Workshop surfaces the alchemist briefing verbatim"
assert_file_contains "alchemist take quoted to the user" "Alchemist's take:" "$SPARK"
assert_file_contains "both surfaced when both return" 'both briefings surfaced when both return' "$SPARK"

begin_test "surfacing is prose, not a new widget"
assert_file_contains "no new AUQ at the surfacing beat" 'adds no AskUserQuestion' "$SPARK"
assert_file_contains "brief enrichment still feeds Step 2" 'Store the agent briefing(s) as `ENRICHED_BRIEF`' "$SPARK"

MOCKUP="$PLUGIN_ROOT/commands/references/mockup-inline.md"

# The added Recommended-marker logic, extracted for a scoped negative assertion
# ("cold" legitimately appears elsewhere in mockup-inline.md - Step 1's canonical
# cold-start and the brief-loading line - so whole-file negatives can't be used).
MARKER_BLOCK="$(sed -n "/The muse option's (Recommended) marker is conditional/,/\*\*If \"Include the muse\":\*\*/p" "$MOCKUP")"

# --- Chunk 3: mockup brief surfaces the muse + conditional recommendation ---
begin_test "mockup brief surfaces the muse briefing verbatim"
assert_file_exists "mockup-inline.md exists" "$MOCKUP"
assert_contains "muse take quoted on the mockup path" "Muse's take:" "$(grep "Muse's take:" "$MOCKUP")"
assert_file_contains "prose only, no new widget" 'prose only, no new widget' "$MOCKUP"
assert_file_contains "three-AUQ budget intact" 'the budget stays three AUQs' "$MOCKUP"

begin_test "vibe AUQ conditions the Recommended marker on both files absent"
assert_contains "marker block exists" 'conditional' "$MARKER_BLOCK"
assert_contains "recommended label form present" 'Include the muse (Recommended)' "$MARKER_BLOCK"
assert_contains "condition names tokens.yaml" 'tokens.yaml' "$MARKER_BLOCK"
assert_contains "condition names locked.md" 'locked.md' "$MARKER_BLOCK"
assert_contains "both-absent condition explicit" 'NEITHER' "$MARKER_BLOCK"
assert_contains "unmarked when either exists" 'If either file exists' "$MARKER_BLOCK"

begin_test "edit 5 does not mint a third 'cold'"
assert_not_contains "marker block avoids the word cold" 'cold' "$MARKER_BLOCK"
assert_not_contains "marker block avoids Cold too" 'Cold' "$MARKER_BLOCK"

INIT="$PLUGIN_ROOT/commands/craft-init.md"
WORKSHOP="$PLUGIN_ROOT/docs/creative-workshop.md"
README="$PLUGIN_ROOT/README.md"

# The Phase 0.5 intent AUQ block, extracted for scoped assertions (the Emotional Core
# and muse legitimately appear elsewhere in craft-init.md - Phase 5b).
INTENT_AUQ="$(sed -n '/Want to capture your project intent now?/,/^```$/p' "$INIT")"
YES_OPTION="$(echo "$INTENT_AUQ" | sed -n '/Yes, capture intent/,/label:/p')"

# --- Chunk 4: Phase 0.5 sells the Emotional Core; docs reconciled ---
begin_test "Phase 0.5 Yes option names the Emotional Core"
assert_contains "yes label keeps its marker" 'Yes, capture intent (Recommended)' "$INTENT_AUQ"
assert_contains "yes description names the Emotional Core" 'Emotional Core' "$YES_OPTION"
assert_contains "yes description names what it feeds" 'every cycle you plan later reads it' "$YES_OPTION"

begin_test "muse no longer only in Skip"
assert_contains "yes description names the muse" 'muse' "$YES_OPTION"
assert_contains "skip option survives" 'Skip - just scaffold' "$INTENT_AUQ"

begin_test "creative-workshop.md drops the silent-folding description"
assert_file_contains "step-2 line quotes the muse first" "you see 2-3 verbatim lines of it first" "$WORKSHOP"
assert_file_contains "interrogators section surfaces both briefings" "Muse's take:" "$WORKSHOP"
assert_file_contains "alchemist surfacing named in docs" "Alchemist's take:" "$WORKSHOP"

begin_test "README intent line stays Emotional-Core consistent"
assert_file_contains "README distill line intact" "muse distills them into the project's Emotional Core" "$README"
assert_file_contains "README cycle-reads line intact" 'Every cycle you plan later reads it' "$README"
