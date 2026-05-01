#!/bin/bash
# Generate-project-md: Create project.md from user choices
# Called during /project init

set -e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname $(dirname $(dirname "$0")))}"
TEMPLATES_DIR="$PLUGIN_ROOT/templates"

# Arguments (passed as environment variables or command line)
PROJECT_NAME="${PROJECT_NAME:-MyProject}"
ENERGY="${ENERGY:-solid}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"
FRAMEWORK="${FRAMEWORK:-Next.js 14 (App Router)}"
STYLING="${STYLING:-Tailwind CSS}"
STATE_MANAGEMENT="${STATE_MANAGEMENT:-React Query + Zustand}"
FORMS="${FORMS:-react-hook-form + zod}"
API="${API:-Next.js API routes}"
DATABASE="${DATABASE:-Postgres via Prisma}"
AUTH="${AUTH:-NextAuth.js}"
HOSTING="${HOSTING:-Vercel}"
CI_CD="${CI_CD:-GitHub Actions}"

DATE=$(date +%Y-%m-%d)

# Create project.md
if [ -f "$TEMPLATES_DIR/craft/project.md" ]; then
  sed "s|{{PROJECT_NAME}}|$PROJECT_NAME|g; \
       s|{{DATE}}|$DATE|g; \
       s|{{ENERGY}}|$ENERGY|g; \
       s|{{PACKAGE_MANAGER}}|$PACKAGE_MANAGER|g; \
       s|{{FRAMEWORK}}|$FRAMEWORK|g; \
       s|{{STYLING}}|$STYLING|g; \
       s|{{STATE_MANAGEMENT}}|$STATE_MANAGEMENT|g; \
       s|{{FORMS}}|$FORMS|g; \
       s|{{API}}|$API|g; \
       s|{{DATABASE}}|$DATABASE|g; \
       s|{{AUTH}}|$AUTH|g; \
       s|{{HOSTING}}|$HOSTING|g; \
       s|{{CI_CD}}|$CI_CD|g" \
    "$TEMPLATES_DIR/craft/project.md" > .craft/project.md

  echo ".craft/project.md created"
else
  echo "Error: Template not found"
  exit 1
fi
