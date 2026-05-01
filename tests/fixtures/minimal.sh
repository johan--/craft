#!/bin/bash
# fixtures/minimal.sh — Minimal .craft/ directory with global state
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/fixtures/minimal.sh"
#   dir=$(create_minimal_craft)  # creates temp dir with .craft/.global-state

create_minimal_craft() {
  local dir
  dir=$(mktemp -d)

  mkdir -p "$dir/.craft"
  cat > "$dir/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

  echo "$dir"
}
