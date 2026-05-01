#!/bin/bash
# Count-requests: Count pending request files in .craft/requests/
# Usage: count-requests.sh [project-root]
# Outputs: integer count (0 if no requests or directory missing)
# Only counts .md files directly in requests/ (not in processed/ subdirectory)

set -e

PROJECT_ROOT="${1:-.}"
PROJECT_ROOT="${PROJECT_ROOT%/}"

REQUESTS_DIR="${PROJECT_ROOT}/.craft/requests"

# Count .md files in requests dir only (not subdirectories like processed/)
if [ -d "$REQUESTS_DIR" ]; then
  count=$(find "$REQUESTS_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "$count"
else
  echo "0"
fi
