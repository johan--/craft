#!/bin/bash
# count-ungraduated-fixes.sh - count fix records created since the last rule pass.
#
# Outputs a single bare integer on stdout. Callers: craft-reflect.md (both-queue
# gate) and craft-cycle-complete.md (reflection trigger).
#
# Semantics:
# - No .craft/fixes/ directory       -> 0
# - No .rule-pass-state file         -> count ALL fix records (cold start: the
#   corpus has never been mined, every record is ungraduated)
# - State file present               -> count records whose frontmatter `created:`
#   is strictly after last_pass_at (YYYY-MM-DD string comparison; lexical order
#   equals chronological order for this format)
#
# The state file is durable across sessions - only the rule pass itself advances
# it. It must never be added to session-start cleanup.

ROOT="${CRAFT_PROJECT_ROOT:-.}"
FIXES_DIR="$ROOT/.craft/fixes"
STATE_FILE="$FIXES_DIR/.rule-pass-state"

if [ ! -d "$FIXES_DIR" ]; then
  echo 0
  exit 0
fi

last_pass_at=""
if [ -f "$STATE_FILE" ]; then
  last_pass_at=$(grep -m1 '^last_pass_at:' "$STATE_FILE" | sed 's/^last_pass_at:[[:space:]]*//' | tr -d '"' | tr -d "'")
fi

count=0
for f in "$FIXES_DIR"/*.md; do
  [ -e "$f" ] || continue
  if [ -z "$last_pass_at" ]; then
    count=$((count + 1))
    continue
  fi
  created=$(awk '/^created:/{print $2; exit}' "$f")
  [ -n "$created" ] || continue
  if [[ "$created" > "$last_pass_at" ]]; then
    count=$((count + 1))
  fi
done

echo "$count"
