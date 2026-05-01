#!/bin/bash
# update-cycle-state.sh — Low-level cycle state setter
# Usage: update-cycle-state.sh <cycle-dir> <key> <value>
#
# Valid keys: CYCLE_STATUS, CURRENT_STORY, CURRENT_CHUNK, TOTAL_CHUNKS,
#             LAST_VALIDATION, LAST_CHECKPOINT
# Note: STORIES_TOTAL/COMPLETE removed - derived from directory scan

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYCLE_DIR="$1"
KEY="$2"
VALUE="$3"

if [ -z "$CYCLE_DIR" ] || [ -z "$KEY" ]; then
  echo "Usage: update-cycle-state.sh <cycle-dir> <key> <value>"
  echo "       update-cycle-state.sh .craft/cycles/1-auth CURRENT_STORY login-form"
  exit 1
fi

# Convert relative paths to absolute
if [[ "$CYCLE_DIR" != /* ]]; then
  # Walk up from PWD to find the cycle directory
  _dir="$PWD"
  _found=""
  while [ "$_dir" != "/" ]; do
    if [ -d "$_dir/$CYCLE_DIR" ]; then
      _found="$_dir/$CYCLE_DIR"
      break
    fi
    _dir=$(dirname "$_dir")
  done
  CYCLE_DIR="${_found:-$PWD/$CYCLE_DIR}"
fi

# Find cycle directory if name provided instead of path
if [ ! -d "$CYCLE_DIR" ]; then
  # Resolve project root for lookup
  source "$SCRIPT_DIR/find-project-root.sh" 2>/dev/null || {
    echo "Error: Cycle directory not found: $CYCLE_DIR"
    exit 1
  }
  found_dir=$(find "${PROJECT_ROOT}.craft/cycles" -maxdepth 1 -type d -name "*${CYCLE_DIR##*/}*" 2>/dev/null | head -1)
  if [ -n "$found_dir" ] && [ -d "$found_dir" ]; then
    CYCLE_DIR="$found_dir"
  else
    echo "Error: Cycle directory not found: $CYCLE_DIR"
    exit 1
  fi
fi

STATE_FILE="$CYCLE_DIR/.state"

# Create state file if missing
if [ ! -f "$STATE_FILE" ]; then
  cycle_name=$(basename "$CYCLE_DIR" | sed 's/^[0-9]*-//')
  cat > "$STATE_FILE" << EOF
# Cycle State
# Runtime state for active implementation session
CYCLE_NAME="$cycle_name"
CYCLE_STATUS="planning"
CURRENT_STORY=""
CURRENT_CHUNK=0
TOTAL_CHUNKS=0
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF
fi

# Resolve NOW keyword to current UTC timestamp
if [ "$VALUE" = "NOW" ]; then
  VALUE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
fi

# Update or add the key
if grep -q "^${KEY}=" "$STATE_FILE"; then
  # Key exists — update in place
  sed -i.bak "s|^${KEY}=.*|${KEY}=\"${VALUE}\"|" "$STATE_FILE"
  rm -f "$STATE_FILE.bak"
else
  # Key doesn't exist — append
  echo "${KEY}=\"${VALUE}\"" >> "$STATE_FILE"
fi
