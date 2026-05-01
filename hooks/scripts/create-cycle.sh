#!/bin/bash
# Create-cycle: Create a new cycle directory and files
# Usage: create-cycle.sh <cycle-name> [cycle-title] [cycle-target] [project-root]

set -e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname $(dirname $(dirname "$0")))}"
TEMPLATES_DIR="$PLUGIN_ROOT/templates"

# Arguments
CYCLE_NAME="$1"
CYCLE_TITLE="${2:-$CYCLE_NAME}"
CYCLE_TARGET="${3:-TBD}"
PROJECT_ROOT="${4:-.}"

# Normalize PROJECT_ROOT
PROJECT_ROOT="${PROJECT_ROOT%/}"
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="."
fi

if [ -z "$CYCLE_NAME" ]; then
  echo "Error: Cycle name required"
  echo "Usage: create-cycle.sh <cycle-name> [cycle-title] [cycle-target] [project-root]"
  exit 1
fi

# Ensure .craft exists
if [ ! -d "${PROJECT_ROOT}/.craft" ]; then
  echo "Error: .craft directory not found at ${PROJECT_ROOT}. Run /craft:init first."
  exit 1
fi

# Determine cycle number
existing_cycles=$(ls -d "${PROJECT_ROOT}/.craft/cycles"/*/ 2>/dev/null | wc -l | tr -d ' ')
cycle_num=$((existing_cycles + 1))
cycle_dir="${PROJECT_ROOT}/.craft/cycles/${cycle_num}-${CYCLE_NAME}"

# Format title with cycle number (e.g., "Cycle 08: Stability & Quality")
CYCLE_TITLE="Cycle $(printf '%02d' $cycle_num): $CYCLE_TITLE"

# Create cycle directory
mkdir -p "$cycle_dir/stories"

# Get current date
DATE=$(date +%Y-%m-%d)

# Escape sed special characters (& and \) in variables used in replacement strings
escape_sed() { printf '%s' "$1" | sed 's/[&\\]/\\&/g'; }
CYCLE_NAME_ESC=$(escape_sed "$CYCLE_NAME")
CYCLE_TITLE_ESC=$(escape_sed "$CYCLE_TITLE")
CYCLE_TARGET_ESC=$(escape_sed "$CYCLE_TARGET")

# Create cycle.yaml from template
if [ -f "$TEMPLATES_DIR/cycle.yaml" ]; then
  sed -e "s|{{CYCLE_NAME}}|$CYCLE_NAME_ESC|g" \
      -e "s|{{CYCLE_TITLE}}|$CYCLE_TITLE_ESC|g" \
      -e "s|{{DATE}}|$DATE|g" \
      -e "s|{{CYCLE_TARGET}}|$CYCLE_TARGET_ESC|g" \
      -e "s|{{CYCLE_FOCUS}}|TBD|g" \
      -e "s|{{GOAL_1}}|TBD|g" \
    "$TEMPLATES_DIR/cycle.yaml" > "$cycle_dir/cycle.yaml"
else
  # Fallback: create minimal cycle.yaml
  cat > "$cycle_dir/cycle.yaml" << EOF
name: $CYCLE_NAME
title: "$CYCLE_TITLE"
status: planning
created: $DATE
updated: $DATE
target: $CYCLE_TARGET
focus: TBD

goals:
  - TBD
EOF
fi

# Create .state from template
if [ -f "$TEMPLATES_DIR/cycle-state" ]; then
  sed "s|{{CYCLE_NAME}}|$CYCLE_NAME_ESC|g" "$TEMPLATES_DIR/cycle-state" > "$cycle_dir/.state"
else
  # Fallback: create minimal .state
  cat > "$cycle_dir/.state" << EOF
# Cycle State
CYCLE_NAME="$CYCLE_NAME"
CYCLE_STATUS="planning"
CURRENT_STORY=""
CURRENT_CHUNK=0
TOTAL_CHUNKS=0
LAST_VALIDATION=""
LAST_CHECKPOINT=""
EOF
fi

# Ensure project-wide learnings file exists (create if missing)
if [ ! -f "${PROJECT_ROOT}/.craft/.learnings.yaml" ]; then
  cat > "${PROJECT_ROOT}/.craft/.learnings.yaml" << EOF
# Project learnings - captured during implementation
# Processed at cycle-complete into harness updates
# Schema matches craft-story-implement.md canonical format

conventions: []
enforcements: []
behaviors: []
automations: []
skills: []
workflows: []
EOF
fi

echo "$cycle_dir"
