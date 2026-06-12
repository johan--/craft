#!/bin/bash
# test-acceptance-preflight.sh - Verify the acceptance pre-flight gate discriminates
#
# The plan-chunks structural check (row #7) greps a written plan for the
# `## Acceptance Pre-Flight` receipt: an absent section fails, the section
# needs at least one table row, and any UNREACHABLE verdict fails the plan.
# These tests run that exact grep logic against static fixture plans and
# verify the planning agent's template wiring emits the section.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# --- The gate logic under test (mirrors SKILL.md check #7) ---

# Returns 0 if the section heading is present in the file
preflight_section_present() {
  grep -q '^## Acceptance Pre-Flight' "$1"
}

# Prints the section body (from the heading to the next ## heading or EOF)
preflight_section() {
  awk '/^## Acceptance Pre-Flight/{found=1; next} /^## /{if(found) exit} found' "$1"
}

# Counts data rows in the section's table (pipe rows minus header + separator)
preflight_row_count() {
  local rows
  rows=$(preflight_section "$1" | grep -c '^|' || true)
  if [ "$rows" -ge 2 ]; then echo $((rows - 2)); else echo 0; fi
}

# Returns 0 if any verdict in the section contains UNREACHABLE
preflight_has_unreachable() {
  preflight_section "$1" | grep -q 'UNREACHABLE'
}

# --- Fixtures ---

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FIXTURE_UNREACHABLE="$TMP_DIR/plan-unreachable.md"
cat > "$FIXTURE_UNREACHABLE" << 'EOF'
# Plan fixture: one structurally unreachable acceptance vehicle

## Acceptance Pre-Flight

| Acceptance vehicle | Walk | Verdict |
|--------------------|------|---------|
| "discount applies at $100" | order fixture totals $120 -> threshold branch satisfied | reachable |
| "saved preference applied to invoice" | seed writes by customerId; path reads by (customerId, region); seeded row has no region | UNREACHABLE - seed and lookup use different key shapes |

## Chunks
EOF

FIXTURE_REACHABLE="$TMP_DIR/plan-reachable.md"
cat > "$FIXTURE_REACHABLE" << 'EOF'
# Plan fixture: all acceptance vehicles reachable

## Acceptance Pre-Flight

| Acceptance vehicle | Walk | Verdict |
|--------------------|------|---------|
| "discount applies at $100" | order fixture totals $120 -> threshold branch satisfied | reachable |
| "doc assertions only" | no executable acceptance vehicle | reachable - by construction |

## Chunks
EOF

FIXTURE_ABSENT="$TMP_DIR/plan-absent.md"
cat > "$FIXTURE_ABSENT" << 'EOF'
# Plan fixture: no Acceptance Pre-Flight section at all

## Acceptance

- some criterion

## Chunks
EOF

# --- Tests ---

echo "=== test-acceptance-preflight.sh ==="
echo ""

# Test 1: a planted unreachable acceptance vehicle is flagged
begin_test "unreachable acceptance vehicle is flagged"

if preflight_section_present "$FIXTURE_UNREACHABLE" && preflight_has_unreachable "$FIXTURE_UNREACHABLE"; then
  RESULT="flagged"
else
  RESULT="missed"
fi

assert_eq \
  "gate flags the UNREACHABLE verdict in the fixture plan" \
  "flagged" \
  "$RESULT"

echo ""

# Test 2: a reachable-only plan passes the pre-flight
begin_test "reachable-only plan passes pre-flight"

if preflight_section_present "$FIXTURE_REACHABLE" \
  && [ "$(preflight_row_count "$FIXTURE_REACHABLE")" -ge 1 ] \
  && ! preflight_has_unreachable "$FIXTURE_REACHABLE"; then
  RESULT="passes"
else
  RESULT="fails"
fi

assert_eq \
  "gate passes a plan whose verdicts are all reachable (incl. the docs-only exempt row)" \
  "passes" \
  "$RESULT"

echo ""

# Test 3: the fixture carries the section name and table format the gate greps for
begin_test "fixture carries the Acceptance Pre-Flight section and table format"

assert_file_contains \
  "fixture contains the section heading" \
  "^## Acceptance Pre-Flight" \
  "$FIXTURE_UNREACHABLE"

assert_file_contains \
  "fixture contains the receipt table header" \
  "| Acceptance vehicle | Walk | Verdict |" \
  "$FIXTURE_UNREACHABLE"

echo ""

# Test 4: an entirely absent section is flagged (the missing-section branch)
begin_test "absent section is flagged"

if preflight_section_present "$FIXTURE_ABSENT"; then
  RESULT="missed"
else
  RESULT="flagged"
fi

assert_eq \
  "gate flags a plan with no Acceptance Pre-Flight section (section missing from plan)" \
  "flagged" \
  "$RESULT"

echo ""

# Test 5: the planning agent's story template emits the section
begin_test "agent template list carries the section"

assert_file_contains \
  "plan-chunks-agent story template includes the Acceptance Pre-Flight section" \
  "^## Acceptance Pre-Flight" \
  "$PLUGIN_ROOT/agents/plan-chunks-agent.md"

assert_file_contains \
  "structural check table row references the section" \
  "## Acceptance Pre-Flight" \
  "$PLUGIN_ROOT/skills/plan-chunks/SKILL.md"

assert_file_exists \
  "walk reference file exists" \
  "$PLUGIN_ROOT/skills/plan-chunks/references/acceptance-walkthrough.md"

echo ""

finish_tests
