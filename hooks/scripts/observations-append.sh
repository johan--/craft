#!/bin/bash
# observations-append.sh - Append one structural observation to a per-story sidecar.
#
# Usage:
#   observations-append.sh <cycle-dir> <story-name> <grade> <severity> <file:line> <desc> [--craft-version=X]
#
# Writes to <cycle-dir>/.observations/<story-name>.yaml, creating the .observations/
# directory on demand. One sidecar per story (keyed on the story name), append-stable
# across resumes and multi-day runs.
#
# Each appended entry carries: story, grade, severity, loc (the file:line), desc,
# surfaced (always false at write time), created (ISO-8601 UTC), and craft_version.
# created and craft_version are inert provenance - stamped here, read by no current
# consumer. They are captured speculatively because they cannot be backfilled later.
#
# Write-nothing guard: if grade, severity, or loc is empty/whitespace - or the
# cycle-dir / story-name is missing - the script exits 0 and writes NOTHING. A drifted
# or malformed entry must never be able to corrupt a sidecar.
#
# Exit: 0 on success and on every guard path (best-effort, never crashes a caller).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse args (positional + optional --craft-version override) ---
CRAFT_VERSION_OVERRIDE=""
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --craft-version=*)
      CRAFT_VERSION_OVERRIDE="${1#*=}"
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

CYCLE_DIR="${POSITIONAL[0]:-}"
STORY_NAME="${POSITIONAL[1]:-}"
GRADE="${POSITIONAL[2]:-}"
SEVERITY="${POSITIONAL[3]:-}"
LOC="${POSITIONAL[4]:-}"
DESC="${POSITIONAL[5]:-}"

# --- Write-nothing guard ---
# Required content fields must be non-empty after trimming whitespace.
nonblank() { [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }
nonblank "$GRADE"    || exit 0
nonblank "$SEVERITY" || exit 0
nonblank "$LOC"      || exit 0
# Structural fields: without them there is nowhere to write.
[ -n "$CYCLE_DIR" ]  || exit 0
[ -n "$STORY_NAME" ] || exit 0

# desc collapses to a single line - the schema is one line per observation.
DESC=$(printf '%s' "$DESC" | tr '\n' ' ')

CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Resolve craft_version (override wins; else read plugin.json) ---
CRAFT_VERSION="$CRAFT_VERSION_OVERRIDE"
if [ -z "$CRAFT_VERSION" ]; then
  PLUGIN_JSON=""
  if [ -n "$CLAUDE_PLUGIN_ROOT" ] && [ -f "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
    PLUGIN_JSON="$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json"
  elif [ -f "$SCRIPT_DIR/../../.claude-plugin/plugin.json" ]; then
    PLUGIN_JSON="$SCRIPT_DIR/../../.claude-plugin/plugin.json"
  fi
  if [ -n "$PLUGIN_JSON" ]; then
    CRAFT_VERSION=$(grep '"version"' "$PLUGIN_JSON" 2>/dev/null | head -1 \
      | sed -E 's/.*"version": *"([^"]+)".*/\1/' || true)
  fi
fi
[ -n "$CRAFT_VERSION" ] || CRAFT_VERSION="unknown"

# --- Write ---
OBS_DIR="$CYCLE_DIR/.observations"
mkdir -p "$OBS_DIR"
SIDECAR="$OBS_DIR/${STORY_NAME}.yaml"

# YAML-escape scalars as double-quoted strings. json.dumps output is a valid YAML
# flow scalar for these values; python3 is already a plugin dependency.
esc() { python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1]))' "$1"; }
STORY_Y=$(esc "$STORY_NAME")
GRADE_Y=$(esc "$GRADE")
SEVERITY_Y=$(esc "$SEVERITY")
LOC_Y=$(esc "$LOC")
DESC_Y=$(esc "$DESC")

# Write the list header once, on first observation for this story.
if [ ! -f "$SIDECAR" ]; then
  echo "observations:" > "$SIDECAR"
fi

{
  echo "  - story: $STORY_Y"
  echo "    grade: $GRADE_Y"
  echo "    severity: $SEVERITY_Y"
  echo "    loc: $LOC_Y"
  echo "    desc: $DESC_Y"
  echo "    surfaced: false"
  echo "    created: $CREATED"
  echo "    craft_version: $CRAFT_VERSION"
} >> "$SIDECAR"

exit 0
