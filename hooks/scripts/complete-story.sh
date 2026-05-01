#!/bin/bash
# complete-story.sh — Transition: Mark a story as complete
# Usage: complete-story.sh <story-file>
#
# Updates:
# - Story: status = complete (via frontmatter)
# - Cycle: CURRENT_STORY cleared, CURRENT_CHUNK cleared
# - Global: CURRENT_STORY cleared

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STORY_FILE="$1"

if [ -z "$STORY_FILE" ]; then
  echo "Usage: complete-story.sh <story-file>"
  exit 1
fi

# Convert relative paths to absolute — walk up to find actual file
if [[ "$STORY_FILE" != /* ]]; then
  _dir="$PWD"
  _found=""
  while [ "$_dir" != "/" ]; do
    if [ -f "$_dir/$STORY_FILE" ]; then
      _found="$_dir/"
      break
    fi
    _dir=$(dirname "$_dir")
  done
  STORY_FILE="${_found:-$PWD/}${STORY_FILE}"
fi

if [ ! -f "$STORY_FILE" ]; then
  echo "Error: Story file not found: $STORY_FILE"
  exit 1
fi

# Derive project root from story file path
PROJECT_ROOT=$(echo "$STORY_FILE" | sed 's|/.craft/.*||')
if [ -d "${PROJECT_ROOT}/.craft" ]; then
  PROJECT_ROOT="${PROJECT_ROOT}/"
else
  PROJECT_ROOT=""
fi

# Update story status to complete (frontmatter only)
"$SCRIPT_DIR/update-story-status.sh" "$STORY_FILE" complete

# Aggregate knowledge-gap failures for reflect pipeline
python3 "$SCRIPT_DIR/aggregate-failures.py" "$PROJECT_ROOT" 2>/dev/null || true

# --- Git commit: one commit per story ---

if [ -n "$PROJECT_ROOT" ]; then
  cd "${PROJECT_ROOT}"

  # Parse story title from frontmatter
  STORY_TITLE=$(grep "^title:" "$STORY_FILE" 2>/dev/null | sed 's/title: *//' | tr -d '"' | tr -d '\r')

  # Parse chunk descriptions from chunk headings
  CHUNK_BODY=""
  while IFS= read -r line; do
    # Strip "### Chunk N: " prefix, keep just the description
    desc=$(echo "$line" | sed 's/### Chunk [0-9]*: //')
    CHUNK_BODY="${CHUNK_BODY}
- ${desc}"
  done < <(grep "^### Chunk [0-9]" "$STORY_FILE" 2>/dev/null)

  # Build commit message
  COMMIT_MSG="feat: ${STORY_TITLE:-$(basename "$STORY_FILE" .md)}"
  if [ -n "$CHUNK_BODY" ]; then
    COMMIT_MSG="${COMMIT_MSG}
${CHUNK_BODY}"
  fi

  # Stage and commit
  git add -A 2>/dev/null || true
  if git diff --cached --quiet 2>/dev/null; then
    # Nothing to commit
    true
  else
    git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null || true
  fi
fi

# Get cycle from story frontmatter
cycle_name=$(grep "^cycle:" "$STORY_FILE" 2>/dev/null | sed 's/cycle: *//' | tr -d '\r')

if [ -n "$cycle_name" ]; then
  cycle_dir=$(find "${PROJECT_ROOT}.craft/cycles" -maxdepth 1 -type d -name "*${cycle_name}*" 2>/dev/null | head -1)

  if [ -n "$cycle_dir" ] && [ -d "$cycle_dir" ]; then
    # Clear current story/chunk in cycle state
    "$SCRIPT_DIR/update-cycle-state.sh" "$cycle_dir" CURRENT_STORY ""
    "$SCRIPT_DIR/update-cycle-state.sh" "$cycle_dir" CURRENT_CHUNK "0"
    "$SCRIPT_DIR/update-cycle-state.sh" "$cycle_dir" TOTAL_CHUNKS "0"
  fi
fi

# Clear current story in global state
"$SCRIPT_DIR/update-global-state.sh" CURRENT_STORY "" "$PROJECT_ROOT"
"$SCRIPT_DIR/update-global-state.sh" LAST_ACTIVITY "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PROJECT_ROOT"
"$SCRIPT_DIR/update-global-state.sh" CRAFT_WRITE_ENABLED "" "$PROJECT_ROOT"

# Emit event
if [ -n "$cycle_name" ] && [ -n "$cycle_dir" ]; then
  STORY_NAME=$(basename "$STORY_FILE" .md)
  chunks_complete=$(grep "^chunks_complete:" "$STORY_FILE" 2>/dev/null | sed 's/chunks_complete: *//' || echo "0")
  EVENTS_DIR="$cycle_dir/.events"
  "$SCRIPT_DIR/append-event.sh" "$EVENTS_DIR" "story_completed" "$STORY_NAME" chunks_complete="$chunks_complete" || true
fi

# Clean up checkpoint YAML files — no longer needed after story commit
rm -f "${PROJECT_ROOT}.craft/checkpoints/"*.yaml 2>/dev/null

# Clean up chunk validation state
rm -f "${PROJECT_ROOT}.craft/.chunk-state" 2>/dev/null

echo "Story completed: $STORY_FILE"
