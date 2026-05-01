#!/bin/bash
# create-checkpoint.sh — YAML state snapshot for chunk recovery
# Usage: create-checkpoint.sh <story-name> <chunk-number> [cycle-dir] [project-root]
#
# Serializes current state to .craft/checkpoints/{story}-chunk-{N}.yaml
# for structured recovery and resume support. Captures current HEAD ref
# for salvage operations but does not create git commits.
# Git commits happen once at story completion (via complete-story.sh).
#
# stdout: path to checkpoint YAML file
# exit 0: success
# exit 1: missing state file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STORY_NAME="$1"
CHUNK_NUMBER="$2"
CYCLE_DIR="$3"
PROJECT_ROOT="$4"

if [ -z "$STORY_NAME" ] || [ -z "$CHUNK_NUMBER" ]; then
  echo "Usage: create-checkpoint.sh <story-name> <chunk-number> [cycle-dir] [project-root]"
  exit 1
fi

# Normalize STORY_NAME: strip path and .md extension if a full path was passed
STORY_NAME="$(basename "$STORY_NAME" .md)"

# Resolve project root
if [ -z "$PROJECT_ROOT" ]; then
  if [ -n "$CRAFT_PROJECT_ROOT" ]; then
    PROJECT_ROOT="$CRAFT_PROJECT_ROOT"
  else
    PROJECT_ROOT=""
    source "$SCRIPT_DIR/find-project-root.sh"
  fi
fi

# Normalize PROJECT_ROOT (ensure trailing slash)
PROJECT_ROOT="${PROJECT_ROOT%/}/"

# Resolve cycle dir
if [ -z "$CYCLE_DIR" ]; then
  if [ -f "${PROJECT_ROOT}.craft/.global-state" ]; then
    source "${PROJECT_ROOT}.craft/.global-state"
    if [ -n "$ACTIVE_CYCLE" ]; then
      CYCLE_DIR="${PROJECT_ROOT}.craft/cycles/$ACTIVE_CYCLE"
    fi
  fi
fi

# Convert relative cycle dir to absolute
if [ -n "$CYCLE_DIR" ] && [[ "$CYCLE_DIR" != /* ]]; then
  CYCLE_DIR="${PROJECT_ROOT}${CYCLE_DIR}"
fi

if [ -z "$CYCLE_DIR" ] || [ ! -d "$CYCLE_DIR" ]; then
  echo "Error: No active cycle found" >&2
  exit 1
fi

# --- Capture current git state (no commit) ---

cd "${PROJECT_ROOT}"

GIT_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# --- Read state ---

CYCLE_DIR_NAME=$(basename "$CYCLE_DIR")
STATE_FILE="$CYCLE_DIR/.state"

# Initialize state vars with defaults
state_CYCLE_STATUS=""
state_CURRENT_STORY=""
state_CURRENT_CHUNK=""
state_TOTAL_CHUNKS=""
state_LAST_VALIDATION=""

if [ -f "$STATE_FILE" ]; then
  # Source the state file to get values (use eval to avoid polluting our vars)
  state_CYCLE_STATUS=$(grep '^CYCLE_STATUS=' "$STATE_FILE" 2>/dev/null | sed 's/^CYCLE_STATUS=//' | tr -d '"' || echo "")
  state_CURRENT_STORY=$(grep '^CURRENT_STORY=' "$STATE_FILE" 2>/dev/null | sed 's/^CURRENT_STORY=//' | tr -d '"' || echo "")
  state_CURRENT_CHUNK=$(grep '^CURRENT_CHUNK=' "$STATE_FILE" 2>/dev/null | sed 's/^CURRENT_CHUNK=//' | tr -d '"' || echo "")
  state_TOTAL_CHUNKS=$(grep '^TOTAL_CHUNKS=' "$STATE_FILE" 2>/dev/null | sed 's/^TOTAL_CHUNKS=//' | tr -d '"' || echo "")
  state_LAST_VALIDATION=$(grep '^LAST_VALIDATION=' "$STATE_FILE" 2>/dev/null | sed 's/^LAST_VALIDATION=//' | tr -d '"' || echo "")
fi

# Read story frontmatter
STORY_FILE=$(find "$CYCLE_DIR/stories" -name "*${STORY_NAME}*.md" 2>/dev/null | head -1)
story_status=""
story_chunks_total=""
story_chunks_complete=""
test_status=""
modified_files=""

if [ -n "$STORY_FILE" ] && [ -f "$STORY_FILE" ]; then
  # Normalize STORY_NAME to match actual filename (includes number prefix)
  STORY_NAME="$(basename "$STORY_FILE" .md)"
  story_status=$(grep "^status:" "$STORY_FILE" 2>/dev/null | sed 's/status: *//' | head -1 || echo "")
  story_chunks_total=$(grep "^chunks_total:" "$STORY_FILE" 2>/dev/null | sed 's/chunks_total: *//' | head -1 || echo "")
  story_chunks_complete=$(grep "^chunks_complete:" "$STORY_FILE" 2>/dev/null | sed 's/chunks_complete: *//' | head -1 || echo "")
fi

# Get recently modified tracked files (last commit)
modified_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | tr '\n' ' ' || echo "")

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Write checkpoint YAML ---

CHECKPOINT_DIR="${PROJECT_ROOT}.craft/checkpoints"
mkdir -p "$CHECKPOINT_DIR"

CHECKPOINT_FILE="${CHECKPOINT_DIR}/${STORY_NAME}-chunk-${CHUNK_NUMBER}.yaml"

cat > "$CHECKPOINT_FILE" << EOF
story: "${STORY_NAME}"
chunk: ${CHUNK_NUMBER}
total_chunks: ${state_TOTAL_CHUNKS:-${story_chunks_total:-0}}
cycle: "${CYCLE_DIR_NAME}"
timestamp: "${TIMESTAMP}"
git_ref: "${GIT_REF}"
git_branch: "${GIT_BRANCH}"
state_CYCLE_STATUS: "${state_CYCLE_STATUS}"
state_CURRENT_STORY: "${state_CURRENT_STORY}"
state_CURRENT_CHUNK: "${state_CURRENT_CHUNK}"
state_TOTAL_CHUNKS: "${state_TOTAL_CHUNKS}"
state_LAST_VALIDATION: "${state_LAST_VALIDATION}"
story_status: "${story_status}"
story_chunks_total: "${story_chunks_total}"
story_chunks_complete: "${story_chunks_complete}"
test_status: "${test_status}"
modified_files: "${modified_files}"
EOF

# --- Update LAST_CHECKPOINT in cycle state ---

"$SCRIPT_DIR/update-cycle-state.sh" "$CYCLE_DIR" LAST_CHECKPOINT "$TIMESTAMP"

# Emit event
EVENTS_DIR="$CYCLE_DIR/.events"
"$SCRIPT_DIR/append-event.sh" "$EVENTS_DIR" "checkpoint_created" "$STORY_NAME" chunk="$CHUNK_NUMBER" commit="$GIT_REF" || true

# stdout: checkpoint file path
echo "$CHECKPOINT_FILE"
