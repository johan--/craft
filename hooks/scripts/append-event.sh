#!/bin/bash
# append-event.sh — Append a structured JSONL event to the event log
#
# Usage: append-event.sh <events-dir> <type> <story> [key=value pairs...]
#
# Writes one JSON line to <events-dir>/<story>.jsonl
# If story is "_cycle", writes to <events-dir>/_cycle.jsonl
#
# Required fields auto-populated: timestamp (ISO UTC), type, story
# Optional key=value pairs become the "data" object:
#   chunk=2 tool=Edit → {"data":{"chunk":"2","tool":"Edit"}}
#
# Creates .events/ dir and file if they don't exist.
# Always exits 0 — event logging must never block the caller.

set -e

EVENTS_DIR="$1"
EVENT_TYPE="$2"
STORY="$3"
shift 3 2>/dev/null || true

# Validate required args
if [ -z "$EVENTS_DIR" ] || [ -z "$EVENT_TYPE" ] || [ -z "$STORY" ]; then
  exit 0  # Silent exit — don't block caller
fi

# Create dir if needed
mkdir -p "$EVENTS_DIR" 2>/dev/null || exit 0

# Timestamp (ISO UTC)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build data object from remaining key=value args
DATA_FIELDS=""
for arg in "$@"; do
  key="${arg%%=*}"
  value="${arg#*=}"
  if [ -n "$key" ] && [ "$key" != "$arg" ]; then
    # Escape double quotes in value
    value=$(echo "$value" | sed 's/"/\\"/g')
    if [ -n "$DATA_FIELDS" ]; then
      DATA_FIELDS="${DATA_FIELDS},"
    fi
    DATA_FIELDS="${DATA_FIELDS}\"${key}\":\"${value}\""
  fi
done

# Build JSON line
if [ -n "$DATA_FIELDS" ]; then
  JSON="{\"timestamp\":\"${TIMESTAMP}\",\"type\":\"${EVENT_TYPE}\",\"story\":\"${STORY}\",\"data\":{${DATA_FIELDS}}}"
else
  JSON="{\"timestamp\":\"${TIMESTAMP}\",\"type\":\"${EVENT_TYPE}\",\"story\":\"${STORY}\"}"
fi

# Append to file
TARGET_FILE="${EVENTS_DIR}/${STORY}.jsonl"
echo "$JSON" >> "$TARGET_FILE" 2>/dev/null || exit 0
