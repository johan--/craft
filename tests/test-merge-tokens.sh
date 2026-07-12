#!/bin/bash
# test-merge-tokens.sh — merge-tokens.py: keyed tokens.yaml merge (report/merge/verify)
#
# Seeds the exact shape that failed the 2026-07-11 live init run: a copper/dark
# mockup-born tokens.yaml with provenance comments, teal/light incoming scan values,
# one genuine same-key conflict. Asserts the union, precedence, comment survival,
# backfill, and the resolve/schema guardrails.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

MERGE="$SCRIPTS_DIR/merge-tokens.py"
TEMPLATE="$TEMPLATES_DIR/craft/design/tokens.yaml"

# Seed: mockup-born copper file (subset of the live fixture's shape)
make_copper_file() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/tokens.yaml" << 'EOF'
# Design Tokens - Craft Design System
# Locked: 2026-07-10 - from mockup pricing-card (C1: Ember Restraint)

colors:
  primary: "#d97706"                     # Locked: 2026-07-10 - from mockup pricing-card
  primary-hover: "#b45309"               # Locked: 2026-07-10 - from mockup pricing-card
  surface: "#141414"                     # Locked: 2026-07-10 - from mockup pricing-card

radius:
  md: "8px"                              # Locked: 2026-07-10 - from mockup pricing-card
  xl: "16px"                             # Locked: 2026-07-10 - from mockup pricing-card

typography:
  font-sans: "Inter, system-ui, sans-serif"  # Locked: 2026-07-10 - from mockup pricing-card

transitions:
  normal: "200ms ease"                   # Locked: 2026-07-10 - from mockup pricing-card
EOF
}

# Incoming teal scan values: one conflict (colors.surface), one same (radius.md),
# news (colors.text-primary, spacing.md)
INCOMING='colors.surface=#ffffff|from src/ui/components/*.css - 24 uses
colors.text-primary=#1f2933|from src/ui/components/*.css - 12 uses
radius.md=8px|from src/ui/components/*.css - 23 uses
spacing.md=16px|from src/ui/components/*.css'

echo "=== test-merge-tokens.sh ==="
echo ""

# Test 1: report mode classifies CONFLICT / NEW / SAME
begin_test "report — classifies CONFLICT / NEW / SAME"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
set +e
OUT=$(echo "$INCOMING" | python3 "$MERGE" report "$TEST_DIR/tokens.yaml" 2>&1); EC=$?
set -e
assert_eq "exits 0" "0" "$EC"
assert_contains_literal "conflict detected" 'CONFLICT colors.surface: existing "#141414" vs incoming "#ffffff"' "$OUT"
assert_contains_literal "new key detected" 'NEW colors.text-primary' "$OUT"
assert_contains_literal "new section key detected" 'NEW spacing.md' "$OUT"
assert_contains_literal "same value detected" 'SAME radius.md' "$OUT"
rm -rf "$TEST_DIR"
echo ""

# Test 2: merge default (existing wins) — union, conflict kept, comments intact
begin_test "merge — existing wins: union + provenance survival"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
set +e
OUT=$(echo "$INCOMING" | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" 2>&1); EC=$?
set -e
RESULT=$(cat "$TEST_DIR/tokens.yaml")
assert_eq "exits 0" "0" "$EC"
assert_contains_literal "conflict keeps existing value" 'surface: "#141414"' "$RESULT"
assert_contains_literal "mockup primary intact" 'primary: "#d97706"' "$RESULT"
assert_contains_literal "new key added" 'text-primary: "#1f2933"' "$RESULT"
assert_contains_literal "new key provenance comment" 'from src/ui/components/*.css - 12 uses' "$RESULT"
assert_contains_literal "new section created with key" 'md: "16px"' "$RESULT"
assert_contains_literal "provenance comments byte-intact" 'primary: "#d97706"                     # Locked: 2026-07-10 - from mockup pricing-card' "$RESULT"
assert_file_exists "premerge snapshot created" "$TEST_DIR/.tokens-premerge"
rm -rf "$TEST_DIR"
echo ""

# Test 3: --resolve applies incoming for that key only
begin_test "merge — --resolve replaces only the named conflict key"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
set +e
echo "$INCOMING" | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" --resolve colors.surface=incoming > /dev/null 2>&1; EC=$?
set -e
RESULT=$(cat "$TEST_DIR/tokens.yaml")
assert_eq "exits 0" "0" "$EC"
assert_contains_literal "resolved key takes incoming" 'surface: "#ffffff"' "$RESULT"
assert_contains_literal "unresolved mockup key untouched" 'primary: "#d97706"' "$RESULT"
rm -rf "$TEST_DIR"
echo ""

# Test 4: --resolve on a non-conflict key hard-errors, file untouched
begin_test "merge — --resolve outside conflict set is a hard error"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
BEFORE=$(md5 -q "$TEST_DIR/tokens.yaml" 2>/dev/null || md5sum "$TEST_DIR/tokens.yaml" | cut -d' ' -f1)
set +e
echo "$INCOMING" | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" --resolve colors.primary=incoming > /dev/null 2>&1; EC=$?
set -e
AFTER=$(md5 -q "$TEST_DIR/tokens.yaml" 2>/dev/null || md5sum "$TEST_DIR/tokens.yaml" | cut -d' ' -f1)
assert_eq "exits non-zero" "1" "$EC"
assert_eq "file untouched on error" "$BEFORE" "$AFTER"
rm -rf "$TEST_DIR"
echo ""

# Test 5: backfill — absent template sections appear, no placeholders anywhere
begin_test "merge — backfills absent sections, zero placeholders"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
echo "$INCOMING" | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" > /dev/null 2>&1
RESULT=$(cat "$TEST_DIR/tokens.yaml")
assert_contains_literal "z-index backfilled" 'z-index:' "$RESULT"
assert_contains_literal "breakpoints backfilled" 'breakpoints:' "$RESULT"
assert_contains_literal "backfill uses template literal" 'modal: 1050' "$RESULT"
if echo "$RESULT" | grep -q '{{'; then
  echo "  FAIL: placeholder survived merge"; FAIL=$((FAIL + 1))
else
  echo "  PASS: no {{...}} placeholder in merged file"; PASS=$((PASS + 1))
fi
rm -rf "$TEST_DIR"
echo ""

# Test 6: --precedence incoming (inspiration wins) — conflicts flip, rest survives
begin_test "merge — --precedence incoming: conflict takes incoming, uncovered keys survive"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
echo "$INCOMING" | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" --precedence incoming > /dev/null 2>&1
RESULT=$(cat "$TEST_DIR/tokens.yaml")
assert_contains_literal "conflict takes incoming" 'surface: "#ffffff"' "$RESULT"
assert_contains_literal "uncovered mockup key survives" 'primary-hover: "#b45309"' "$RESULT"
assert_contains_literal "uncovered provenance survives" 'normal: "200ms ease"                   # Locked: 2026-07-10 - from mockup pricing-card' "$RESULT"
rm -rf "$TEST_DIR"
echo ""

# Test 7: schema guard — unknown top-level section rejected before any write
begin_test "merge — unknown section hard-errors, file untouched"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
BEFORE=$(md5 -q "$TEST_DIR/tokens.yaml" 2>/dev/null || md5sum "$TEST_DIR/tokens.yaml" | cut -d' ' -f1)
set +e
echo 'bogus.key=1|x' | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" > /dev/null 2>&1; EC=$?
set -e
AFTER=$(md5 -q "$TEST_DIR/tokens.yaml" 2>/dev/null || md5sum "$TEST_DIR/tokens.yaml" | cut -d' ' -f1)
assert_eq "exits non-zero" "1" "$EC"
assert_eq "file untouched" "$BEFORE" "$AFTER"
rm -rf "$TEST_DIR"
echo ""

# Test 8: malformed stdin hard-errors
begin_test "merge — malformed stdin is a hard error"
TEST_DIR=$(mktemp -d); make_copper_file "$TEST_DIR"
set +e
echo 'no-equals-sign-here' | python3 "$MERGE" merge "$TEST_DIR/tokens.yaml" --template "$TEMPLATE" > /dev/null 2>&1; EC=$?
set -e
assert_eq "exits non-zero" "1" "$EC"
rm -rf "$TEST_DIR"
echo ""

finish_tests
