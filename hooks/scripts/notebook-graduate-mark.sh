#!/bin/bash
# notebook-graduate-mark.sh — Flag a notebook idea as graduated (no file move)
# Usage: notebook-graduate-mark.sh <idea-file> <story-slug>
#   <idea-file>: absolute or project-relative path to the idea .md file
#   <story-slug>: slug of the resulting backlog story (frontmatter graduated_to value)
#
# Updates frontmatter:
#   status: open -> graduated
#   graduated_to: <story-slug> (inserted)
# File stays in .craft/notebook/ideas/.
#
# Output (stdout): the file path (unchanged)
# Exit: 0 on success, non-zero on error

set -e

IDEA_FILE="$1"
STORY_SLUG="$2"

if [ -z "$IDEA_FILE" ] || [ -z "$STORY_SLUG" ]; then
  echo "Error: idea file and story slug required" >&2
  echo "Usage: notebook-graduate-mark.sh <idea-file> <story-slug>" >&2
  exit 1
fi

if [ ! -f "$IDEA_FILE" ]; then
  echo "Error: idea file not found: $IDEA_FILE" >&2
  exit 1
fi

if ! grep -q "^type: idea$" "$IDEA_FILE"; then
  echo "Error: file is not an idea (type: idea not found): $IDEA_FILE" >&2
  exit 1
fi

python3 - "$IDEA_FILE" "$STORY_SLUG" <<'PYEOF'
import sys, re
path, slug = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    content = f.read()

content = re.sub(r'^status:\s*open\s*$', 'status: graduated', content, count=1, flags=re.MULTILINE)

if not re.search(r'^graduated_to:', content, flags=re.MULTILINE):
    content = re.sub(
        r'^(status:\s*graduated)\s*$',
        r'\1\ngraduated_to: ' + slug,
        content, count=1, flags=re.MULTILINE
    )

with open(path, 'w') as f:
    f.write(content)
PYEOF

echo "$IDEA_FILE"
