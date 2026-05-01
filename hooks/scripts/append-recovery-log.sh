#!/bin/bash
# append-recovery-log.sh — Append structured entry to recovery log
# Usage: append-recovery-log.sh <project-root> <story> <chunk> <reason> <salvage-path> <checkpoint-ref> [details]
#
# Appends a human-readable entry to .craft/recovery-log.md.
# Creates the file with header if it doesn't exist.
#
# exit 0: always

set -eo pipefail

PROJECT_ROOT="$1"
STORY="$2"
CHUNK="$3"
REASON="$4"
SALVAGE_PATH="$5"
CHECKPOINT_REF="$6"
DETAILS="${7:-}"

if [ -z "$PROJECT_ROOT" ] || [ -z "$STORY" ] || [ -z "$CHUNK" ]; then
  echo "Usage: append-recovery-log.sh <project-root> <story> <chunk> <reason> <salvage-path> <checkpoint-ref> [details]"
  exit 0
fi

# Normalize PROJECT_ROOT
PROJECT_ROOT="${PROJECT_ROOT%/}"
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="."
fi

LOG_FILE="${PROJECT_ROOT}/.craft/recovery-log.md"

# Guard: do NOT create .craft/ — if it doesn't exist, there's nothing to log
if [ ! -d "${PROJECT_ROOT}/.craft" ]; then
  exit 0
fi

# Create log file with header if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
  cat > "$LOG_FILE" << 'EOF'
# Recovery Log

EOF
fi

# Read cycle name from global state
CYCLE_NAME=""
if [ -f "${PROJECT_ROOT}/.craft/.global-state" ]; then
  CYCLE_NAME=$(grep "^ACTIVE_CYCLE=" "${PROJECT_ROOT}/.craft/.global-state" 2>/dev/null | sed 's/ACTIVE_CYCLE=//' | tr -d '"' || echo "")
fi

# Get salvage file count
SALVAGE_INFO="none"
if [ -n "$SALVAGE_PATH" ] && [ "$SALVAGE_PATH" != "nothing_to_salvage" ] && [ -f "${SALVAGE_PATH}/manifest.yaml" ]; then
  FILE_COUNT=$(grep "^file_count:" "${SALVAGE_PATH}/manifest.yaml" 2>/dev/null | sed 's/file_count: *//' || echo "0")
  # Make path relative to project root for readability
  REL_SALVAGE=$(echo "$SALVAGE_PATH" | sed "s|^${PROJECT_ROOT}/||")
  SALVAGE_INFO="\`.craft/${REL_SALVAGE#.craft/}\` (${FILE_COUNT} files)"
fi

TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")

# Append entry
cat >> "$LOG_FILE" << EOF
---

## ${TIMESTAMP} -- ${STORY} chunk ${CHUNK}

**Failure:** ${REASON:-unknown}
**Cycle:** ${CYCLE_NAME:-unknown}
**Salvage:** ${SALVAGE_INFO}
**Checkpoint:** \`${CHECKPOINT_REF:-unknown}\`
**Details:** ${DETAILS:-none}

EOF

echo "$LOG_FILE"
