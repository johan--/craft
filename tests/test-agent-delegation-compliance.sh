#!/bin/bash
# test-agent-delegation-compliance.sh — Verify resume paths delegate to implementer agent
#
# Both craft-story-continue.md and craft-story-implement.md's Resume Support
# must route through the implementer agent — not implement directly.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

STORY_CONTINUE="$PLUGIN_ROOT/commands/craft-story-continue.md"
STORY_IMPLEMENT="$PLUGIN_ROOT/commands/craft-story-implement.md"

# --- Tests ---

echo "=== test-agent-delegation-compliance.sh ==="
echo ""

# Test 1: story-continue must hand off to story-implement (not implement directly)
begin_test "story-continue hands off to craft:story-implement"

assert_file_contains \
  "story-continue references craft:story-implement" \
  "craft:story-implement" \
  "$STORY_CONTINUE"

echo ""

# Test 2: story-implement Resume Support section must reference the implementer agent
begin_test "story-implement Resume Support references implementer agent"

# Extract just the Resume Support section (between "## Resume Support" and the next "## " heading)
RESUME_SECTION=$(sed -n '/^## Resume Support/,/^## [^R]/p' "$STORY_IMPLEMENT")

assert_contains \
  "Resume Support section references craft:implementer" \
  "craft:implementer" \
  "$RESUME_SECTION"

echo ""

# Test 3: story-continue must NOT contain "Continue chunk" self-implementation language
begin_test "story-continue does not contain self-implementation language"

assert_file_not_contains \
  "story-continue should not say 'Continue chunk' (implies self-implementation)" \
  "Continue chunk" \
  "$STORY_CONTINUE"

echo ""

# --- Summary ---
finish_tests
