#!/bin/bash
# count-loved-tweaks.sh - count loved, un-spread tweak records ripe for a pass.
#
# Outputs a single bare integer on stdout. Callers: session-start.sh (the ripe
# line) and the propagation door gate.
#
# A record in .craft/tweaks/*.md qualifies iff ALL of:
#   - `taste:` is exactly `loved` (space-insensitive; `taste:loved` also parses)
#   - `reapplies:` is absent or blank (a non-blank value, incl. `none`, disqualifies)
#   - `grew_from:` is absent or blank
#   - `created:` is strictly after `last_asked` (YYYY-MM-DD string comparison),
#     or the state file is absent (cold start - every qualifying record counts)
#
# Semantics:
# - No .craft/tweaks/ directory   -> 0
# - No .taste-pass-state file      -> cold start (last_asked empty; all qualify)
#
# Optional argument: a numeric threshold. When passed, the scan stops and returns
# as soon as the running count reaches it (returns a value >= threshold without
# scanning the rest). Without the argument it returns the exact total. This keeps
# the session-start hot path O(threshold) rather than O(all records).
#
# The state file is durable across sessions - only an accepted or terminal-declined
# pass advances it. It must never be added to session-start cleanup.

ROOT="${CRAFT_PROJECT_ROOT:-.}"
TWEAKS_DIR="$ROOT/.craft/tweaks"
STATE_FILE="$TWEAKS_DIR/.taste-pass-state"

THRESHOLD=""
if [ -n "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
  THRESHOLD="$1"
fi

if [ ! -d "$TWEAKS_DIR" ]; then
  echo 0
  exit 0
fi

last_asked=""
if [ -f "$STATE_FILE" ]; then
  last_asked=$(grep -m1 '^last_asked:' "$STATE_FILE" | sed 's/^last_asked:[[:space:]]*//' | tr -d '"' | tr -d "'")
fi

count=0
for f in "$TWEAKS_DIR"/*.md; do
  [ -e "$f" ] || continue

  # taste: must be exactly "loved" (space-insensitive)
  grep -Eq '^taste:[[:space:]]*loved[[:space:]]*$' "$f" || continue

  # reapplies: absent or blank; any non-blank value disqualifies
  reapplies=$(grep -m1 '^reapplies:' "$f" | sed 's/^reapplies:[[:space:]]*//')
  [ -z "$reapplies" ] || continue

  # grew_from: absent or blank; any non-blank value disqualifies
  grew_from=$(grep -m1 '^grew_from:' "$f" | sed 's/^grew_from:[[:space:]]*//')
  [ -z "$grew_from" ] || continue

  # created: strictly after last_asked (or state absent -> all qualify)
  if [ -n "$last_asked" ]; then
    created=$(awk '/^created:/{print $2; exit}' "$f")
    [ -n "$created" ] || continue
    [[ "$created" > "$last_asked" ]] || continue
  fi

  count=$((count + 1))
  if [ -n "$THRESHOLD" ] && [ "$count" -ge "$THRESHOLD" ]; then
    break
  fi
done

echo "$count"
