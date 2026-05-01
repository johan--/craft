#!/bin/bash
# test-create-story.sh — Tests for create-story.sh
# Validates story creation from templates with proper frontmatter
#
# REGRESSION (story 8): test 1 MUST FAIL against current codebase

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

# --- Tests ---

echo "=== test-create-story.sh ==="
echo ""

# ---- REGRESSION TEST (Story 8) ----
# create-story.sh uses raw sed substitution without quoting the title.
# A title with a colon produces invalid YAML: title: Fix: broken thing
begin_test "REGRESSION: create-story.sh quotes title with colon"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
trap cleanup_test_dir EXIT
cd "$TEST_DIR"

# Set CLAUDE_PLUGIN_ROOT so create-story.sh finds templates
RESULT=$(CRAFT_PROJECT_ROOT="$TEST_DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" "$SCRIPTS_DIR/create-story.sh" "fix-auth" "Fix: broken authentication")

# The file should exist
assert_file_exists "story file created" "$RESULT"

# The title MUST be quoted to be valid YAML (colon in value)
TITLE_LINE=$(grep "^title:" "$RESULT" | head -1)
if echo "$TITLE_LINE" | grep -qE '^title: ".*"$' || echo "$TITLE_LINE" | grep -qE "^title: '.*'$"; then
  echo "  PASS: title with colon is quoted"
  PASS=$((PASS + 1))
else
  echo "  FAIL: title with colon is NOT quoted — invalid YAML"
  echo "    actual:   $TITLE_LINE"
  echo "    expected: title: \"Fix: broken authentication\""
  FAIL=$((FAIL + 1))
fi

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# Test 2: Happy path — backlog story creation
begin_test "Happy path — backlog story creates file with frontmatter"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
cd "$TEST_DIR"
mkdir -p .craft/backlog

RESULT=$(CRAFT_PROJECT_ROOT="$TEST_DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" "$SCRIPTS_DIR/create-story.sh" "login-form" "Login Form")

assert_file_exists "story file created" "$RESULT"
assert_contains "file is in backlog" "backlog" "$RESULT"

# Check frontmatter fields
assert_yaml_field "name field" "name" "login-form" "$RESULT"
assert_yaml_field "status field" "status" "backlog" "$RESULT"
assert_yaml_field_exists "priority field exists" "priority" "$RESULT"
assert_yaml_field_exists "created field exists" "created" "$RESULT"

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# Test 3: Story creation with cycle assignment
begin_test "Cycle story — file lands in stories/ with correct number"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
cd "$TEST_DIR"

RESULT=$(CRAFT_PROJECT_ROOT="$TEST_DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" "$SCRIPTS_DIR/create-story.sh" "signup-form" "Signup Form" --cycle=test-cycle)

assert_file_exists "story file created" "$RESULT"
assert_contains "file is in cycle stories dir" "stories/" "$RESULT"
assert_contains "file has story number prefix" "1-signup-form.md" "$RESULT"

# Check cycle-specific frontmatter fields
assert_yaml_field_exists "cycle field exists" "cycle" "$RESULT"
assert_yaml_field_exists "story_number field exists" "story_number" "$RESULT"

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# ---- ADDITIONAL BUG: sed treats & as matched pattern ----
# create-story.sh uses raw sed: sed "s|{{STORY_TITLE}}|${STORY_TITLE}|g"
# The & in the replacement string means "the matched text", so
# "Fix Layout & Spacing" → "Fix Layout {{STORY_TITLE}} Spacing" (corrupted)
begin_test "BUG: create-story.sh corrupts title with ampersand"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
cd "$TEST_DIR"
mkdir -p .craft/backlog

RESULT=$(CRAFT_PROJECT_ROOT="$TEST_DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" "$SCRIPTS_DIR/create-story.sh" "ui-polish" "Fix Layout & Spacing")
assert_file_exists "story with ampersand created" "$RESULT"

# The title should contain the actual text, not the corrupted version
CONTENT=$(cat "$RESULT")
assert_contains_literal "title contains ampersand text" "Fix Layout & Spacing" "$CONTENT"

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# ---- REGRESSION TEST (Story 9): Relative .craft path ----
# create-story.sh line 56: story_file=".craft/backlog/${STORY_NAME}.md"
# This is relative to CWD. When CWD ≠ project root and CRAFT_PROJECT_ROOT is set,
# the story should be created at CRAFT_PROJECT_ROOT/.craft/backlog/, not CWD/.craft/backlog/.
begin_test "REGRESSION: create-story uses CRAFT_PROJECT_ROOT for backlog path"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")
mkdir -p "$TEST_DIR/.craft/backlog"

# Create a subdirectory WITHOUT .craft/
mkdir -p "$TEST_DIR/src/features"

# Run from subdirectory with CRAFT_PROJECT_ROOT set to correct root
set +e
RESULT=$(cd "$TEST_DIR/src/features" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$SCRIPTS_DIR/create-story.sh" "subdir-story" "Story From Subdir" 2>/dev/null)
EXIT_CODE=$?
set -e

# The story should land in the PROJECT ROOT's backlog, not in CWD
if [ -f "$TEST_DIR/.craft/backlog/subdir-story.md" ]; then
  echo "  PASS: story created at project root backlog"
  PASS=$((PASS + 1))
else
  echo "  FAIL: story NOT at project root backlog ($TEST_DIR/.craft/backlog/subdir-story.md)"
  # Check if it accidentally created at CWD
  if [ -f "$TEST_DIR/src/features/.craft/backlog/subdir-story.md" ]; then
    echo "    BUG: story created at CWD/.craft/backlog/ instead of CRAFT_PROJECT_ROOT"
  else
    echo "    BUG: story not created at all (script uses relative '.craft' path, no .craft/ at CWD)"
    echo "    exit code: $EXIT_CODE"
  fi
  FAIL=$((FAIL + 1))
fi

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# ---- REGRESSION TEST (Story 9): Relative .craft path for --cycle ----
# create-story.sh line 43: cycle_dir=$(find .craft/cycles -maxdepth 1 ...)
# Also relative to CWD. Same bug class as the backlog path.
begin_test "REGRESSION: create-story uses CRAFT_PROJECT_ROOT for cycle path"

TEST_DIR=$(create_craft_with_cycle "test-cycle" "Test Cycle" "1")

# Create a subdirectory WITHOUT .craft/
mkdir -p "$TEST_DIR/src/features"

# Run from subdirectory with --cycle flag
set +e
RESULT=$(cd "$TEST_DIR/src/features" && export CRAFT_PROJECT_ROOT="$TEST_DIR" && \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$SCRIPTS_DIR/create-story.sh" "cycle-story" "Cycle Story" --cycle=test-cycle 2>/dev/null)
EXIT_CODE=$?
set -e

# The story should land in the cycle's stories/ at PROJECT ROOT
CYCLE_STORIES=$(ls "$TEST_DIR/.craft/cycles/1-test-cycle/stories/"*cycle-story*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$CYCLE_STORIES" -gt 0 ]; then
  echo "  PASS: story created in cycle at project root"
  PASS=$((PASS + 1))
else
  echo "  FAIL: story NOT in cycle at project root"
  echo "    BUG: script uses 'find .craft/cycles' relative to CWD, ignoring CRAFT_PROJECT_ROOT"
  echo "    exit code: $EXIT_CODE"
  FAIL=$((FAIL + 1))
fi

cd "$SCRIPT_DIR"
cleanup_test_dir
echo ""

# --- Summary ---
finish_tests
