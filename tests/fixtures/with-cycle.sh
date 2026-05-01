#!/bin/bash
# fixtures/with-cycle.sh — .craft/ with a cycle (cycle.yaml + .state + stories/)
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/fixtures/with-cycle.sh"
#   dir=$(create_craft_with_cycle "test-cycle" "Test Cycle")
#
# Creates:
#   .craft/.global-state (ACTIVE_CYCLE set)
#   .craft/cycles/1-test-cycle/cycle.yaml
#   .craft/cycles/1-test-cycle/.state
#   .craft/cycles/1-test-cycle/stories/

create_craft_with_cycle() {
  local cycle_name="${1:-test-cycle}"
  local cycle_title="${2:-Test Cycle}"
  local cycle_num="${3:-1}"
  local dir
  dir=$(mktemp -d)
  local cycle_dir="$dir/.craft/cycles/${cycle_num}-${cycle_name}"

  mkdir -p "$cycle_dir/stories"
  mkdir -p "$dir/.craft/backlog"

  cat > "$dir/.craft/.global-state" << EOF
ACTIVE_CYCLE="${cycle_num}-${cycle_name}"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

  cat > "$cycle_dir/cycle.yaml" << EOF
name: "${cycle_name}"
title: "${cycle_title}"
status: active
created: 2026-02-14
goals:
  - "Test cycle for automated tests"
EOF

  cat > "$cycle_dir/.state" << EOF
CYCLE_NAME="${cycle_name}"
CYCLE_STATUS="active"
CURRENT_STORY=""
CURRENT_CHUNK="0"
TOTAL_CHUNKS="0"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

  echo "$dir"
}
