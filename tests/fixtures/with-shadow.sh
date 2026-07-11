#!/bin/bash
# fixtures/with-shadow.sh — Monorepo with multiple .craft/ directories
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/fixtures/with-shadow.sh"
#   dir=$(create_craft_with_shadow)
#
# Creates a monorepo-like structure where parent and child both have .craft/:
#   $dir/project/.craft/.global-state          (parent project)
#   $dir/project/.craft/cycles/1-test-cycle/   (with cycle.yaml, .state, stories/)
#   $dir/project/apps/web/.craft/              (child sub-project)
#   $dir/project/apps/web/.craft/.global-state (child sub-project, initialized)
#
# "Nearest wins" — from apps/web/, find-workshop resolves to child.
# From project/, it resolves to parent. Both are legitimate.

create_craft_with_shadow() {
  local dir
  dir=$(mktemp -d)

  # Real project root
  local project="$dir/project"
  mkdir -p "$project/.craft/cycles/1-test-cycle/stories"
  mkdir -p "$project/.craft/backlog"

  cat > "$project/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

  cat > "$project/.craft/cycles/1-test-cycle/cycle.yaml" << 'EOF'
title: "Test Cycle"
status: active
created: 2026-02-14
goal: "Test cycle"
EOF

  cat > "$project/.craft/cycles/1-test-cycle/.state" << 'EOF'
CYCLE_NAME="test-cycle"
CYCLE_STATUS="active"
CURRENT_STORY=""
CURRENT_CHUNK="0"
TOTAL_CHUNKS="0"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

  # Child sub-project with its own .craft/ (legitimate in monorepo)
  local shadow="$project/apps/web"
  mkdir -p "$shadow/.craft"
  cat > "$shadow/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
EOF

  echo "$dir"
}

# Create shadow with only a bare .craft/ directory (no .global-state)
create_craft_with_bare_shadow() {
  local dir
  dir=$(mktemp -d)

  local project="$dir/project"
  mkdir -p "$project/.craft/cycles/1-test-cycle/stories"

  cat > "$project/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
EOF

  # Bare shadow — just the directory, no .global-state
  mkdir -p "$project/apps/web/.craft"

  echo "$dir"
}

# Create monorepo with a rogue .craft/ that has no .global-state and no project.md
# This simulates the bug: mkdir -p created a bare .craft/ at the wrong level
create_craft_with_rogue_shadow() {
  local dir
  dir=$(mktemp -d)

  # Legitimate parent project (has .global-state AND project.md)
  local project="$dir/project"
  mkdir -p "$project/.craft/cycles/1-test-cycle/stories"
  mkdir -p "$project/.craft/backlog"

  cat > "$project/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-test-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
LAST_ACTIVITY=""
EOF

  cat > "$project/.craft/project.md" << 'EOF'
---
name: parent-project
type: ui
---
# Parent Project
EOF

  cat > "$project/.craft/cycles/1-test-cycle/cycle.yaml" << 'EOF'
title: "Test Cycle"
status: active
created: 2026-02-14
goal: "Test cycle"
EOF

  cat > "$project/.craft/cycles/1-test-cycle/.state" << 'EOF'
CYCLE_NAME="test-cycle"
CYCLE_STATUS="active"
CURRENT_STORY=""
CURRENT_CHUNK="0"
TOTAL_CHUNKS="0"
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF

  # Rogue .craft/ — bare directory, no .global-state, no project.md
  # This is what mkdir -p creates when append-recovery-log.sh runs in wrong dir
  mkdir -p "$project/apps/web/.craft"

  echo "$dir"
}
