#!/bin/bash
# read-events.sh — Read and filter events from the JSONL event log
#
# Usage: read-events.sh <events-dir> [--story=<name>] [--type=<type>] [--last=N]
#
# Reads from story-specific file or all files in .events/
# Filters via grep on type field
# --last=N returns only the last N events (after filtering)
# Outputs filtered JSONL to stdout
#
# Graceful fallback if jq not available — outputs raw JSONL lines.

set -e

EVENTS_DIR="$1"
shift 2>/dev/null || true

# Parse options
STORY_FILTER=""
TYPE_FILTER=""
LAST_N=""

for arg in "$@"; do
  case "$arg" in
    --story=*) STORY_FILTER="${arg#--story=}" ;;
    --type=*)  TYPE_FILTER="${arg#--type=}" ;;
    --last=*)  LAST_N="${arg#--last=}" ;;
  esac
done

# Validate
if [ -z "$EVENTS_DIR" ] || [ ! -d "$EVENTS_DIR" ]; then
  exit 0  # No events dir — silent exit
fi

# Determine which files to read
if [ -n "$STORY_FILTER" ]; then
  FILES="$EVENTS_DIR/${STORY_FILTER}.jsonl"
  if [ ! -f "$FILES" ]; then
    exit 0  # No events for this story
  fi
else
  FILES=$(ls "$EVENTS_DIR"/*.jsonl 2>/dev/null)
  if [ -z "$FILES" ]; then
    exit 0  # No event files
  fi
fi

# Read all matching lines
LINES=""
for f in $FILES; do
  if [ -f "$f" ]; then
    if [ -n "$LINES" ]; then
      LINES="${LINES}
$(cat "$f")"
    else
      LINES="$(cat "$f")"
    fi
  fi
done

# Filter by type
if [ -n "$TYPE_FILTER" ]; then
  LINES=$(echo "$LINES" | grep "\"type\":\"${TYPE_FILTER}\"" 2>/dev/null || true)
fi

# Apply --last
if [ -n "$LAST_N" ] && [ -n "$LINES" ]; then
  LINES=$(echo "$LINES" | tail -n "$LAST_N")
fi

# Output
if [ -n "$LINES" ]; then
  echo "$LINES"
fi
