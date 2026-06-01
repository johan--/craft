#!/bin/bash
# notebook-done.sh — Mark a todo done: move to todos/done/ + update frontmatter
# Usage: notebook-done.sh <todo-file>
#   <todo-file>: absolute or project-relative path to the todo .md file
#
# Actions:
#   1. Update frontmatter: status: open -> done; insert done_at: YYYY-MM-DD
#   2. Move file to .craft/notebook/todos/done/{basename}
#
# Output (stdout): the new file path (in done/)
# Exit: 0 on success, non-zero on error

set -e

TODO_FILE="$1"

if [ -z "$TODO_FILE" ]; then
  echo "Error: todo file required" >&2
  echo "Usage: notebook-done.sh <todo-file>" >&2
  exit 1
fi

if [ ! -f "$TODO_FILE" ]; then
  echo "Error: todo file not found: $TODO_FILE" >&2
  exit 1
fi

if ! grep -q "^type: todo$" "$TODO_FILE"; then
  echo "Error: file is not a todo (type: todo not found): $TODO_FILE" >&2
  exit 1
fi

DATE=$(date +%Y-%m-%d)

python3 - "$TODO_FILE" "$DATE" <<'PYEOF'
import sys, re
path, date = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'^status:\s*open\s*$', 'status: done', content, count=1, flags=re.MULTILINE)
if not re.search(r'^done_at:', content, flags=re.MULTILINE):
    content = re.sub(
        r'^(status:\s*done)\s*$',
        r'\1\ndone_at: ' + date,
        content, count=1, flags=re.MULTILINE
    )
with open(path, 'w') as f:
    f.write(content)
PYEOF

TODO_DIR=$(dirname "$TODO_FILE")
BASENAME=$(basename "$TODO_FILE")
DONE_DIR="$TODO_DIR/done"
mkdir -p "$DONE_DIR"

DEST="$DONE_DIR/$BASENAME"
mv "$TODO_FILE" "$DEST"

echo "$DEST"
