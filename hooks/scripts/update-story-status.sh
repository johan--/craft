#!/bin/bash
# Update-story-status: Change a story's status in frontmatter
# Usage: update-story-status.sh <story-file> <new-status>
# Statuses: backlog, planning, ready, active, complete
#
# Updates story frontmatter only. No cycle.yaml manipulation.
# Story counts are derived from directory scan, not stored.

set -e

STORY_FILE="$1"
NEW_STATUS="$2"

if [ -z "$STORY_FILE" ] || [ -z "$NEW_STATUS" ]; then
  echo "Error: Story file and status required"
  echo "Usage: update-story-status.sh <story-file> <status>"
  echo "Statuses: backlog, planning, ready, active, complete"
  exit 1
fi

# Convert relative paths to absolute using PWD
if [[ "$STORY_FILE" != /* ]]; then
  STORY_FILE="$PWD/$STORY_FILE"
fi

if [ ! -f "$STORY_FILE" ]; then
  echo "Error: Story file not found: $STORY_FILE"
  exit 1
fi

# Validate status
case "$NEW_STATUS" in
  backlog|planning|ready|active|complete) ;;
  *)
    echo "Error: Invalid status '$NEW_STATUS'"
    echo "Valid statuses: backlog, planning, ready, active, complete"
    exit 1
    ;;
esac

DATE=$(date +%Y-%m-%d)

# Update story frontmatter
sed -i.bak "s/^status:.*/status: $NEW_STATUS/" "$STORY_FILE"
sed -i.bak "s/^updated:.*/updated: $DATE/" "$STORY_FILE"
rm -f "$STORY_FILE.bak"

echo "Story status updated to '$NEW_STATUS': $STORY_FILE"
