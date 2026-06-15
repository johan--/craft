#!/bin/bash
# observations-count.sh - Compute the unread observation count for a cycle.
#
# Usage: observations-count.sh <cycle-dir>
#
# Prints "<N> unread / <M> stories" where:
#   N = total entries with `surfaced: false` across <cycle-dir>/.observations/*.yaml
#   M = number of sidecar files containing at least one unread entry
# Prints an empty string and exits 0 when there are no sidecars or zero unread entries.
#
# PURE bash/grep - NO python3. This runs on every UserPromptSubmit via
# inject-craft-context.sh; spawning python3 per prompt would add ~100ms to every submit.
# The sidecar is a known fixed format, so the unread count is a pure line-count of
# `surfaced: false`. The count is computed on every call and never stored - a stored
# count drifts the instant an entry flips.

CYCLE_DIR="${1:-}"
[ -n "$CYCLE_DIR" ] || exit 0

OBS_DIR="$CYCLE_DIR/.observations"
[ -d "$OBS_DIR" ] || exit 0

N=0
M=0
for f in "$OBS_DIR"/*.yaml; do
  [ -e "$f" ] || continue   # no-match glob guard
  c=$(grep -c "surfaced: false" "$f" 2>/dev/null || true)
  [ -n "$c" ] || c=0
  if [ "$c" -gt 0 ]; then
    N=$((N + c))
    M=$((M + 1))
  fi
done

[ "$N" -gt 0 ] || exit 0
echo "$N unread / $M stories"
