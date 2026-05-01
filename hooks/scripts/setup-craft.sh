#!/bin/bash
# Setup-craft: Initialize the .craft directory structure
# Called by /craft:init command
#
# Usage: setup-craft.sh [project-type]
#   project-type: "ui" (default) or "cli"

set -e

# Get project type from argument (default: ui)
PROJECT_TYPE="${1:-ui}"

# Get the plugin root (templates location)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname $(dirname $(dirname "$0")))}"
TEMPLATES_DIR="$PLUGIN_ROOT/templates"

# Set design templates directory based on project type
if [ "$PROJECT_TYPE" = "cli" ]; then
  DESIGN_TEMPLATES="$TEMPLATES_DIR/craft/design-cli"
else
  DESIGN_TEMPLATES="$TEMPLATES_DIR/craft/design"
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  CRAFT SETUP${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create directory structure
echo "Creating directory structure..."
echo "  Project type: $PROJECT_TYPE"

mkdir -p .craft/backlog
mkdir -p .craft/cycles
mkdir -p .craft/projects
mkdir -p .craft/design
mkdir -p .craft/.exports
mkdir -p .craft/requests

# Inspiration directory only for UI projects
if [ "$PROJECT_TYPE" != "cli" ]; then
  mkdir -p .craft/inspiration/screenshots
fi

echo -e "  ${GREEN}✓${NC} Created .craft directories"

# Initialize git repository if not already one
if [ ! -d .git ]; then
  git init
  echo -e "  ${GREEN}✓${NC} Initialized git repository"
else
  echo -e "  ${GREEN}✓${NC} Git repository already exists"
fi

# Copy template files
echo "Setting up configuration files..."

# Get current date
DATE=$(date +%Y-%m-%d)

# Quality configuration
if [ -f "$TEMPLATES_DIR/craft/quality.yaml" ]; then
  cp "$TEMPLATES_DIR/craft/quality.yaml" .craft/quality.yaml
  echo -e "  ${GREEN}✓${NC} Created quality.yaml"
fi

# Design tokens / conventions
# For UI projects: SKIP_TOKENS=1 means from-scratch or early - don't generate speculative tokens
# For CLI projects: always generate (these are conventions, not visual design)
if [ "$PROJECT_TYPE" = "cli" ]; then
  if [ -f "$DESIGN_TEMPLATES/tokens.yaml" ]; then
    cp "$DESIGN_TEMPLATES/tokens.yaml" .craft/design/tokens.yaml
    echo -e "  ${GREEN}✓${NC} Created design/tokens.yaml (project conventions)"
  fi
elif [ "${SKIP_TOKENS:-0}" != "1" ]; then
  if [ -f "$DESIGN_TEMPLATES/tokens.yaml" ]; then
    sed "s/{{DATE}}/$DATE/g; s/{{PRIMARY_COLOR}}/#6366F1/g; s/{{PRIMARY_HOVER}}/#4F46E5/g; s/{{PRIMARY_LIGHT}}/#EEF2FF/g" \
      "$DESIGN_TEMPLATES/tokens.yaml" > .craft/design/tokens.yaml
    echo -e "  ${GREEN}✓${NC} Created design/tokens.yaml"
  fi
else
  echo -e "  ${GREEN}✓${NC} Skipped design/tokens.yaml (will learn from your code)"
fi

# Component patterns (UI only)
if [ -f "$DESIGN_TEMPLATES/components.md" ]; then
  sed "s/{{DATE}}/$DATE/g" "$DESIGN_TEMPLATES/components.md" > .craft/design/components.md
  echo -e "  ${GREEN}✓${NC} Created design/components.md"
fi

# Locked patterns
if [ -f "$DESIGN_TEMPLATES/locked.md" ]; then
  sed "s/{{DATE}}/$DATE/g" "$DESIGN_TEMPLATES/locked.md" > .craft/design/locked.md
  echo -e "  ${GREEN}✓${NC} Created design/locked.md"
fi

# Animation patterns (UI only)
if [ -f "$DESIGN_TEMPLATES/animations.md" ]; then
  sed "s/{{DATE}}/$DATE/g" "$DESIGN_TEMPLATES/animations.md" > .craft/design/animations.md
  echo -e "  ${GREEN}✓${NC} Created design/animations.md"
fi

# Schemas (CLI only)
if [ -f "$DESIGN_TEMPLATES/schemas.md" ]; then
  sed "s/{{DATE}}/$DATE/g" "$DESIGN_TEMPLATES/schemas.md" > .craft/design/schemas.md
  echo -e "  ${GREEN}✓${NC} Created design/schemas.md"
fi

# Inspiration files (UI projects only)
if [ "$PROJECT_TYPE" != "cli" ]; then
  if [ -f "$TEMPLATES_DIR/craft/inspiration/sites.md" ]; then
    sed "s/{{DATE}}/$DATE/g" "$TEMPLATES_DIR/craft/inspiration/sites.md" > .craft/inspiration/sites.md
    echo -e "  ${GREEN}✓${NC} Created inspiration/sites.md"
  fi

  if [ -f "$TEMPLATES_DIR/craft/inspiration/patterns.md" ]; then
    sed "s/{{DATE}}/$DATE/g" "$TEMPLATES_DIR/craft/inspiration/patterns.md" > .craft/inspiration/patterns.md
    echo -e "  ${GREEN}✓${NC} Created inspiration/patterns.md"
  fi
fi

# Global state
if [ -f "$TEMPLATES_DIR/craft/.global-state" ]; then
  cp "$TEMPLATES_DIR/craft/.global-state" .craft/.global-state
  echo -e "  ${GREEN}✓${NC} Created .global-state"
fi

echo ""
echo -e "${GREEN}Craft initialized!${NC} (project type: $PROJECT_TYPE)"
echo ""
echo "Next steps:"
if [ "$PROJECT_TYPE" = "cli" ]; then
  echo "  1. Edit .craft/project.md with your tech stack"
  echo "  2. Add your patterns to .craft/design/locked.md"
  echo "  3. Create your first story with /craft:story-new"
else
  echo "  1. Run /craft:init to configure project DNA"
  echo "  2. Add inspiration sites to .craft/inspiration/sites.md"
  echo "  3. Create your first story with /craft:story-new"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
