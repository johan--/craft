#!/bin/bash
# test-tweak-reconcile.sh - Verify the tweak flow carries the reconcile design
#
# The tweak-snowball story rewired skills/adhoc/references/tweak.md: lock
# conflicts reconcile pre-edit (recommend-resolve-proceed, escalate only on
# decline), mid-pass pivots announce-only with no lock write, acceptance runs
# ONE reconcile beat (single AskUserQuestion call, conditional slots), and a
# rule change triggers the snowball sweep offer as an ignorable closing line.
#
# Assertions are SECTION-SCOPED (awk between ## headings), not file-wide: the
# escalation fallback must live inside Step 2's decline path, the pivot
# announce inside Step 3 - a file-wide grep would pass even if a future edit
# orphaned the strings elsewhere.
#
# Chunk 2 extends this file with the lock-decision/SKILL.md assertions.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# Working-tree files - guards THIS repo's edits, not the installed plugin copy
TWEAK_MD="$SCRIPT_DIR/../skills/adhoc/references/tweak.md"
LOCK_DECISION_MD="$SCRIPT_DIR/../skills/lock-decision/SKILL.md"

# Prints a ## section's body (heading to next ## heading or EOF).
# ### subsections stay inside the section - they don't match /^## /.
# Fence-aware: a "## " line inside a ``` code block (e.g. the ## Attempt [N]
# record template) is content, not a section boundary.
section() {
  awk -v h="$1" '
    /^```/ { fence = !fence }
    $0 ~ "^## " h { found = 1; next }
    /^## / { if (found && !fence) exit }
    found
  ' "$2"
}

echo "=== test-tweak-reconcile.sh ==="
echo ""

STEP2="$(section "Step 2: Fit Check" "$TWEAK_MD")"
STEP3="$(section "Step 3: The Attempt Loop" "$TWEAK_MD")"
STEP3B="$(section "Step 3b: Reapplying Elsewhere" "$TWEAK_MD")"

# Test 1: pre-edit lock-recommend branch lives in Step 2
begin_test "Step 2 carries the pre-edit lock-recommend branch"

assert_contains_literal \
  "Step 2 has the lock-conflict pre-edit branch" \
  "Lock conflict (pre-edit)" \
  "$STEP2"

echo ""

# Test 2: the escalation fallback survives INSIDE Step 2's decline path
begin_test "escalation decline-fallback survives in Step 2"

assert_contains_literal \
  "decline path still suggests design-vibe" \
  "design-vibe" \
  "$STEP2"

assert_contains_literal \
  "decline path still sets status: escalated" \
  "status: escalated" \
  "$STEP2"

echo ""

# Test 3: the inline lock-edit path is defined in Step 2 (explicit yes, one write moment)
begin_test "inline explicit-yes lock-edit path defined in Step 2"

assert_contains_literal \
  "lock edits demand an explicit yes" \
  "explicit yes" \
  "$STEP2"

assert_contains_literal \
  "a lock gets at most one write moment per tweak thread" \
  "ONE write moment" \
  "$STEP2"

echo ""

# Test 4: mid-pass pivot announce lives in Step 3's attempt loop
begin_test "Step 3 carries the mid-pass lock pivot announce"

assert_contains_literal \
  "Step 3 has the pivot re-check" \
  "Mid-pass lock pivot" \
  "$STEP3"

assert_contains_literal \
  "pivot writes nothing to locked.md mid-pass" \
  "NO locked.md write mid-pass" \
  "$STEP3"

echo ""

# Test 5: the one-beat acceptance reconcile lives in Step 3, payload-gated
begin_test "Step 3 carries the payload-gated acceptance reconcile"

assert_contains_literal \
  "Step 3 has the acceptance reconcile" \
  "Acceptance reconcile" \
  "$STEP3"

assert_contains_literal \
  "the beat is entered only on a pending payload" \
  "entered when ANY payload is pending" \
  "$STEP3"

assert_contains_literal \
  "one beat means a single AskUserQuestion call" \
  "ONE AskUserQuestion call" \
  "$STEP3"

echo ""

# Test 6: the snowball offer lives in Step 3, as a closing line not an AUQ
begin_test "Step 3 carries the snowball offer as an ignorable line"

assert_contains_literal \
  "Step 3 has the snowball sweep line" \
  "worth a sweep TODO in /craft:notebook" \
  "$STEP3"

assert_contains_literal \
  "the offer is never an AskUserQuestion" \
  "never an AskUserQuestion" \
  "$STEP3"

echo ""

# Test 7: the close-out is the 4-button pure-sentiment gradient
begin_test "close-out is the 4-button gradient"

assert_contains_literal "gradient offers Love it" 'label: "Love it"' "$STEP3"
assert_contains_literal "gradient offers Looks good" 'label: "Looks good"' "$STEP3"
assert_contains_literal "gradient offers Good enough" 'label: "Good enough"' "$STEP3"
assert_contains_literal "gradient offers Not quite" 'label: "Not quite"' "$STEP3"

echo ""

# the shipped "apply elsewhere" button is decoupled to a follow-on offer
begin_test "apply-elsewhere is a follow-on offer, not a button"

assert_not_contains \
  "the apply-elsewhere button is gone" \
  "Looks good - apply elsewhere" \
  "$STEP3"

assert_contains_literal \
  "apply-elsewhere survives as a follow-on line" \
  "Want to apply this same move to other surfaces" \
  "$STEP3"

echo ""

# the taste stamp is a holistic love-signal read with no kind gate
begin_test "taste stamped by holistic judgment + love-signal, no kind gate"

assert_contains_literal \
  "holistic spreadable-taste rule present" \
  "spreadable visual taste the user loved" \
  "$STEP3"

assert_contains_literal \
  "no kind-in-a-set gate on the stamp" \
  "NO \`kind\`-in-a-set gate" \
  "$STEP3"

echo ""

# exactly one propagation offer, resolved by priority
begin_test "one propagation offer by priority victory-lap > snowball > apply-elsewhere"

assert_contains_literal \
  "priority ordering stated" \
  "victory-lap > snowball > apply-elsewhere" \
  "$STEP3"

echo ""

# the acceptance reconcile beat is separate and still fires on its own
begin_test "acceptance reconcile beat fires independently of the propagation offer"

assert_contains_literal \
  "reconcile fires independently of the propagation offer" \
  "fires independently" \
  "$STEP3"

echo ""

# Test 8: the family close-out fires no second reconcile beat
begin_test "Step 3b family close-out has no second reconcile"

assert_contains_literal \
  "reapplication settles rules at the original's acceptance" \
  "NO second reconcile" \
  "$STEP3B"

echo ""

# --- Chunk 2: lock-decision/SKILL.md surfaces ---

# Test 9: lock-decision cross-references the tweak-path inline lock edit
begin_test "lock-decision cross-references the tweak inline lock path"

assert_file_contains \
  "cross-reference section present" \
  "Tweak-path lock edits (inline)" \
  "$LOCK_DECISION_MD"

assert_file_contains \
  "cross-reference points at the tweak flow reference file" \
  "skills/adhoc/references/tweak.md" \
  "$LOCK_DECISION_MD"

echo ""

# Test 10: lock-decision no longer claims hooks auto-enforce locks
begin_test "lock-decision no longer claims hooks auto-enforce locks"

assert_file_not_contains \
  "the false automaticity claim is gone" \
  "hooks check locks on every change" \
  "$LOCK_DECISION_MD"

assert_file_not_contains \
  "the phantom pattern-hook enforcement item is gone" \
  "Pattern hooks" \
  "$LOCK_DECISION_MD"

echo ""

finish_tests
