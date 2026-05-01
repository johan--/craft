#!/bin/bash
# get-latest-cycle.sh — Get the highest-numbered cycle and its status
# Usage: get-latest-cycle.sh [project-root]
#
# Output: key=value pairs for the most recent cycle
#   LATEST_CYCLE=45-hero-card-share
#   CYCLE_TITLE=Cycle 45: Share + Signature Moments
#   CYCLE_STATUS=planning
#   STORIES_TOTAL=2
#   STORIES_READY=2
#   STORIES_COMPLETE=0
#   STORIES_PLANNING=0
#
# If no cycles exist, outputs LATEST_CYCLE=""

set -e

PROJECT="${1:-.}"
CYCLES_DIR="$PROJECT/.craft/cycles"

if [ ! -d "$CYCLES_DIR" ]; then
  echo 'LATEST_CYCLE=""'
  exit 0
fi

# Get the highest-numbered cycle directory
# ls directories, sort by leading number, take the last one
LATEST=$(ls -d "$CYCLES_DIR"/*/ 2>/dev/null | sed 's|.*/\([^/]*\)/$|\1|' | sort -t'-' -k1 -n | tail -1)

if [ -z "$LATEST" ]; then
  echo 'LATEST_CYCLE=""'
  exit 0
fi

CYCLE_YAML="$CYCLES_DIR/$LATEST/cycle.yaml"
STORIES_DIR="$CYCLES_DIR/$LATEST/stories"

echo "LATEST_CYCLE=\"$LATEST\""

# Read cycle.yaml for title and status
if [ -f "$CYCLE_YAML" ]; then
  TITLE=$(grep "^title:" "$CYCLE_YAML" | head -1 | sed 's/^title: *//' | sed 's/^"//;s/"$//')
  STATUS=$(grep "^status:" "$CYCLE_YAML" | head -1 | awk '{print $2}')
  echo "CYCLE_TITLE=\"$TITLE\""
  echo "CYCLE_STATUS=\"$STATUS\""
else
  echo 'CYCLE_TITLE=""'
  echo 'CYCLE_STATUS=""'
fi

# Count stories by status
if [ -d "$STORIES_DIR" ]; then
  TOTAL=$(ls "$STORIES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  READY=$(grep -l "^status: ready" "$STORIES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  COMPLETE=$(grep -l "^status: complete" "$STORIES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  PLANNING=$(grep -l "^status: planning" "$STORIES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "STORIES_TOTAL=\"$TOTAL\""
  echo "STORIES_READY=\"$READY\""
  echo "STORIES_COMPLETE=\"$COMPLETE\""
  echo "STORIES_PLANNING=\"$PLANNING\""
else
  echo 'STORIES_TOTAL="0"'
  echo 'STORIES_READY="0"'
  echo 'STORIES_COMPLETE="0"'
  echo 'STORIES_PLANNING="0"'
fi
