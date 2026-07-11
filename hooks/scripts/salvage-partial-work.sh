#!/bin/bash
# salvage-partial-work.sh — Save changes since checkpoint before rollback
# Usage: salvage-partial-work.sh <checkpoint-git-ref> <story-name> <chunk-number> [project-root]
#
# Copies changed files and generates patches to .craft/salvage/{timestamp}/
# so partial work is preserved before any user-initiated rollback.
#
# stdout: salvage directory path (or "nothing_to_salvage")
# exit 0: always (even if nothing to salvage)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHECKPOINT_REF="$1"
STORY_NAME="$2"
CHUNK_NUMBER="$3"
PROJECT_ROOT="$4"

if [ -z "$CHECKPOINT_REF" ] || [ -z "$STORY_NAME" ] || [ -z "$CHUNK_NUMBER" ]; then
  echo "Usage: salvage-partial-work.sh <checkpoint-git-ref> <story-name> <chunk-number> [project-root]"
  exit 0
fi

# Resolve project root
if [ -z "$PROJECT_ROOT" ]; then
  if [ -n "$CRAFT_PROJECT_ROOT" ]; then
    PROJECT_ROOT="$CRAFT_PROJECT_ROOT"
  else
    PROJECT_ROOT=""
    source "$SCRIPT_DIR/find-workshop.sh"
  fi
fi

# Normalize PROJECT_ROOT (ensure trailing slash)
PROJECT_ROOT="${PROJECT_ROOT%/}/"

cd "${PROJECT_ROOT}"

# --- Find changed files ---

# Include both tracked changes and untracked files
CHANGED_FILES=$(git diff "$CHECKPOINT_REF" --name-only 2>/dev/null || echo "")
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

# Combine and deduplicate
ALL_CHANGED=$(printf "%s\n%s" "$CHANGED_FILES" "$UNTRACKED_FILES" | sort -u | grep -v '^$' || echo "")

if [ -z "$ALL_CHANGED" ]; then
  echo "nothing_to_salvage"
  exit 0
fi

# --- Create salvage directory ---

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SALVAGE_DIR="${PROJECT_ROOT}.craft/salvage/${TIMESTAMP}"
FILES_DIR="${SALVAGE_DIR}/files"
PATCHES_DIR="${SALVAGE_DIR}/patches"
mkdir -p "$FILES_DIR" "$PATCHES_DIR"

# --- Copy changed files and generate patches ---

FILE_COUNT=0
ADDED_COUNT=0
MODIFIED_COUNT=0
DELETED_COUNT=0
MANIFEST_ENTRIES=""

while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Determine change type
  CHANGE_TYPE=""
  if echo "$UNTRACKED_FILES" | grep -qx "$file" 2>/dev/null; then
    CHANGE_TYPE="added"
    ADDED_COUNT=$((ADDED_COUNT + 1))
  elif [ ! -f "$file" ]; then
    CHANGE_TYPE="deleted"
    DELETED_COUNT=$((DELETED_COUNT + 1))
  else
    CHANGE_TYPE="modified"
    MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
  fi

  # Copy current version if file exists
  if [ -f "$file" ]; then
    FILE_DEST_DIR="${FILES_DIR}/$(dirname "$file")"
    mkdir -p "$FILE_DEST_DIR"
    cp "$file" "$FILE_DEST_DIR/"
  fi

  # Generate patch (for tracked files that have diffs)
  if [ "$CHANGE_TYPE" != "added" ]; then
    PATCH_NAME=$(echo "$file" | tr '/' '_').patch
    git diff "$CHECKPOINT_REF" -- "$file" > "${PATCHES_DIR}/${PATCH_NAME}" 2>/dev/null || true
    # Remove empty patch files
    if [ ! -s "${PATCHES_DIR}/${PATCH_NAME}" ]; then
      rm -f "${PATCHES_DIR}/${PATCH_NAME}"
    fi
  fi

  FILE_COUNT=$((FILE_COUNT + 1))
  MANIFEST_ENTRIES="${MANIFEST_ENTRIES}  - path: \"${file}\"\n    change_type: \"${CHANGE_TYPE}\"\n"

done <<< "$ALL_CHANGED"

# --- Write manifest ---

cat > "${SALVAGE_DIR}/manifest.yaml" << EOF
story: "${STORY_NAME}"
chunk: ${CHUNK_NUMBER}
checkpoint_ref: "${CHECKPOINT_REF}"
timestamp: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
file_count: ${FILE_COUNT}
added: ${ADDED_COUNT}
modified: ${MODIFIED_COUNT}
deleted: ${DELETED_COUNT}
files:
$(echo -e "$MANIFEST_ENTRIES")
EOF

# stdout: salvage directory path
echo "$SALVAGE_DIR"
