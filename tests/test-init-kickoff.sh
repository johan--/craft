#!/bin/bash
# test-init-kickoff.sh - Guard the deterministic Phase 6 kickoff in craft-init.md.
# Doc-level assertions that the locked first-move AskUserQuestion copy is present
# and the old free-text kickoff vacuums stay gone. Adjacent stories edit this same
# region of craft-init.md; a paraphrased label or a resurrected free-text prompt
# should fail the suite, not slip through review.

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

INIT="$PLUGIN_ROOT/commands/craft-init.md"

# --- The locked kickoff AUQ is present, verbatim ---
begin_test "Phase 6 carries the deterministic first-move AskUserQuestion"
assert_file_exists "craft-init.md exists" "$INIT"
assert_file_contains "question line" "Craft's ready\. What's the first move?" "$INIT"
assert_file_contains "header chip" 'header: "First move"' "$INIT"
assert_file_contains "option: Mock up a screen" 'label: "Mock up a screen"' "$INIT"
assert_file_contains "option: Describe a feature" 'label: "Describe a feature"' "$INIT"
assert_file_contains "option: I'll take it from here" "label: \"I'll take it from here\"" "$INIT"

# --- The locked descriptions survive, verbatim ---
begin_test "the three option descriptions match the locked copy"
assert_file_contains "mockup description" "Three live options in your browser, before a line of code" "$INIT"
assert_file_contains "feature description" "Tell me what we're building\. We shape it into a story and get to work" "$INIT"
assert_file_contains "exit description" "You're set up\. Run .*/craft.* whenever you're ready to start" "$INIT"

# --- The gating rules are stated ---
begin_test "the deterministic gating rules are stated"
assert_file_contains "PROJECT_TYPE gate on the mockup option" 'renders ONLY when `PROJECT_TYPE` is `ui` or `hybrid`' "$INIT"
assert_file_contains "marker reads total_files from confidence-signals" "confidence-signals\.yaml.*total_files" "$INIT"
assert_file_contains "exit option never recommended" 'NEVER carries (Recommended)' "$INIT"

# --- The old kickoff vacuums stay gone (both init exits) ---
begin_test "the old free-text kickoff vacuums are gone"
assert_file_not_contains "no bare free-text kickoff placeholder" "\[User describes first feature/epic\]" "$INIT"
assert_file_not_contains "no open-ended tackling prompt (Phase 6 or Quick setup)" "first thing we're tackling" "$INIT"

finish_tests "test-init-kickoff"
