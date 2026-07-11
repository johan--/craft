#!/bin/bash
# Self-critique: Compare implementation against standards
# Generates a report for Claude to present

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve project root (handles monorepo)
source "$SCRIPT_DIR/find-workshop.sh" 2>/dev/null || {
  echo "Error: Could not resolve project root"
  exit 1
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SELF-CRITIQUE REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check against design tokens
echo "## Design Token Compliance"
echo ""

if [ -f "${PROJECT_ROOT}.craft/design/tokens.yaml" ]; then
  # Count hardcoded values — search within the project's src/
  hardcoded=$(grep -rn "#[0-9A-Fa-f]\{6\}" "${PROJECT_ROOT}src/" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v "tokens\|config" | head -10)

  if [ -n "$hardcoded" ]; then
    echo "Found hardcoded color values:"
    echo "$hardcoded" | while read line; do
      echo "  - $line"
    done
    echo ""
  else
    echo "No hardcoded colors found"
    echo ""
  fi
else
  echo "No tokens.yaml found - skipping token check"
  echo ""
fi

# Check against locked patterns
echo "## Locked Pattern Compliance"
echo ""

if [ -f "${PROJECT_ROOT}.craft/design/locked.md" ]; then
  # Count locked patterns
  pattern_count=$(grep -c "^## " "${PROJECT_ROOT}.craft/design/locked.md" 2>/dev/null || echo "0")

  if [ "$pattern_count" -gt 0 ]; then
    echo "Checking against $pattern_count locked patterns..."
    echo "(Manual review recommended)"
    echo ""
  else
    echo "No locked patterns yet"
    echo ""
  fi
else
  echo "No locked.md found - skipping pattern check"
  echo ""
fi

# Check against inspiration
echo "## Inspiration Alignment"
echo ""

if [ -f "${PROJECT_ROOT}.craft/inspiration/sites.md" ]; then
  echo "Reference sites to compare against:"
  grep -E "^## |^\- \*\*URL" "${PROJECT_ROOT}.craft/inspiration/sites.md" 2>/dev/null | head -10 || echo "No sites listed"
  echo ""
  echo "(Visual comparison recommended)"
  echo ""
else
  echo "No inspiration sites configured"
  echo ""
fi

# Summary questions
echo "## Review Questions"
echo ""
echo "Before marking complete, consider:"
echo ""
echo "1. Does this match the design intent?"
echo "2. Would this pass at Stripe/Linear/Vercel?"
echo "3. Are loading, error, and empty states handled?"
echo "4. Is it accessible (keyboard, screen reader)?"
echo "5. Does it work on mobile?"
echo "6. Would you be proud to show this?"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
