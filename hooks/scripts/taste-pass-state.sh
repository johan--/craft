#!/bin/bash
# taste-pass-state.sh - read and mutate the taste-pass state and enabled switch.
#
# Owns every write to .craft/tweaks/.taste-pass-state and to the taste_pass_enabled
# key in .craft/settings.yaml. One action per invocation:
#
#   accept              -> last_asked=today, snooze_offset=0 (also the terminal
#                          "neither" reset)
#   decline             -> raise snooze_offset 0->2->5 (cap 5); last_asked
#                          unchanged; creates the state file at offset 2 if absent
#   disable             -> set taste_pass_enabled: false in settings.yaml via an
#                          exact-match replace of the existing key line (appended
#                          only if absent); exactly one such line remains; portable
#                          (no sed -i)
#   effective-threshold -> print taste_pass_threshold (settings, else 3) plus
#                          snooze_offset (state, else 0)
#
# Nothing is inferred from silence: state changes only when a mutating action runs.
# No set -e: a grep with no match returns non-zero, which under set -e would abort a
# command substitution; every read below tolerates an empty result instead.

ROOT="${CRAFT_PROJECT_ROOT:-.}"
TWEAKS_DIR="$ROOT/.craft/tweaks"
STATE_FILE="$TWEAKS_DIR/.taste-pass-state"
SETTINGS="$ROOT/.craft/settings.yaml"

ACTION="$1"

read_offset() {
  local offset=""
  if [ -f "$STATE_FILE" ]; then
    offset=$(grep -m1 '^snooze_offset:' "$STATE_FILE" | sed 's/^snooze_offset:[[:space:]]*//' | tr -d '"' | tr -d "'")
  fi
  [[ "$offset" =~ ^[0-9]+$ ]] || offset=0
  echo "$offset"
}

read_last_asked() {
  local la=""
  if [ -f "$STATE_FILE" ]; then
    la=$(grep -m1 '^last_asked:' "$STATE_FILE" | sed 's/^last_asked:[[:space:]]*//' | tr -d '"' | tr -d "'")
  fi
  echo "$la"
}

write_state() {
  # $1 = last_asked, $2 = snooze_offset. Both fields regenerated to avoid partial edits.
  mkdir -p "$TWEAKS_DIR"
  {
    echo "last_asked: $1"
    echo "snooze_offset: $2"
  } > "$STATE_FILE"
}

case "$ACTION" in
  accept)
    write_state "$(date +%Y-%m-%d)" 0
    ;;

  decline)
    offset=$(read_offset)
    case "$offset" in
      0) new_offset=2 ;;
      2) new_offset=5 ;;
      *) new_offset=5 ;;
    esac
    write_state "$(read_last_asked)" "$new_offset"
    ;;

  disable)
    mkdir -p "$(dirname "$SETTINGS")"
    if [ -f "$SETTINGS" ] && grep -q '^taste_pass_enabled:' "$SETTINGS"; then
      tmp=$(mktemp)
      # Rewrite the first key line to false; drop any later duplicates so exactly
      # one key line remains even if the file arrived with a pre-existing dupe.
      awk '
        /^taste_pass_enabled:/ { if (seen) next; print "taste_pass_enabled: false"; seen=1; next }
        { print }
      ' "$SETTINGS" > "$tmp"
      mv "$tmp" "$SETTINGS"
    else
      # Key absent (or file absent): append exactly once.
      printf 'taste_pass_enabled: false\n' >> "$SETTINGS"
    fi
    ;;

  effective-threshold)
    threshold=""
    if [ -f "$SETTINGS" ]; then
      threshold=$(grep -m1 '^taste_pass_threshold:' "$SETTINGS" | sed 's/^taste_pass_threshold:[[:space:]]*//' | tr -d '"' | tr -d "'")
    fi
    [[ "$threshold" =~ ^[0-9]+$ ]] || threshold=3
    echo $(( threshold + $(read_offset) ))
    ;;

  *)
    echo "Error: unknown action '$ACTION' (expected accept|decline|disable|effective-threshold)" >&2
    exit 1
    ;;
esac
