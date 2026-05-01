#!/bin/bash
# test-plan-researcher-removed.sh — Verify plan-researcher agent has been fully removed
#
# plan-researcher was superseded by plan-chunks-agent. This test ensures
# the agent file is gone and no references remain in the plugin.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# --- Tests ---

echo "=== test-plan-researcher-removed.sh ==="
echo ""

# Test 1: Agent file must not exist
begin_test "plan-researcher agent file does not exist"

assert_file_not_exists \
  "agents/plan-researcher.md should be deleted" \
  "$PLUGIN_ROOT/agents/plan-researcher.md"

echo ""

# Test 2: No references to plan-researcher in plugin files (excluding tests/ and .craft/backlog/)
begin_test "no references to plan-researcher in plugin files"

MATCH_COUNT=$(grep -r "plan-researcher" "$PLUGIN_ROOT" \
  --include="*.md" --include="*.yaml" --include="*.json" --include="*.sh" \
  --exclude-dir="tests" \
  --exclude-dir=".craft" \
  2>/dev/null | wc -l | tr -d ' ')

assert_eq \
  "zero references to plan-researcher outside tests/ and .craft/" \
  "0" \
  "$MATCH_COUNT"

echo ""

# --- Summary ---
finish_tests
