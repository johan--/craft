#!/bin/bash
# Check-polish: Verify polish requirements from quality.yaml
# Scans code for required patterns

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  POLISH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

warnings=0
src_dir="src"

# Check if src directory exists
if [ ! -d "$src_dir" ]; then
  echo "No src directory found. Skipping polish check."
  exit 0
fi

# Check for loading states
echo "  Loading States"
loading_patterns=$(grep -rn "isLoading\|loading\|Skeleton\|skeleton" "$src_dir" 2>/dev/null | wc -l)
if [ "$loading_patterns" -gt 0 ]; then
  echo -e "    ${GREEN}✓${NC} Found $loading_patterns loading patterns"
else
  echo -e "    ${YELLOW}⚠${NC} No loading state patterns detected"
  ((warnings++))
fi

# Check for error handling
echo "  Error Handling"
error_patterns=$(grep -rn "error\|Error\|catch\|try {" "$src_dir" 2>/dev/null | wc -l)
if [ "$error_patterns" -gt 0 ]; then
  echo -e "    ${GREEN}✓${NC} Found $error_patterns error handling patterns"
else
  echo -e "    ${YELLOW}⚠${NC} Limited error handling detected"
  ((warnings++))
fi

# Check for empty states
echo "  Empty States"
empty_patterns=$(grep -rn "empty\|Empty\|no.*found\|no.*yet" "$src_dir" 2>/dev/null | wc -l)
if [ "$empty_patterns" -gt 0 ]; then
  echo -e "    ${GREEN}✓${NC} Found $empty_patterns empty state patterns"
else
  echo -e "    ${YELLOW}⚠${NC} No empty state patterns detected"
  ((warnings++))
fi

# Check for accessibility
echo "  Accessibility"
a11y_patterns=$(grep -rn "aria-\|role=\|alt=\|tabIndex\|onKeyDown" "$src_dir" 2>/dev/null | wc -l)
if [ "$a11y_patterns" -gt 5 ]; then
  echo -e "    ${GREEN}✓${NC} Found $a11y_patterns accessibility attributes"
else
  echo -e "    ${YELLOW}⚠${NC} Limited accessibility attributes ($a11y_patterns found)"
  ((warnings++))
fi

# Check for responsive patterns
echo "  Responsive Design"
responsive_patterns=$(grep -rn "md:\|lg:\|sm:\|@media\|useMediaQuery" "$src_dir" 2>/dev/null | wc -l)
if [ "$responsive_patterns" -gt 0 ]; then
  echo -e "    ${GREEN}✓${NC} Found $responsive_patterns responsive patterns"
else
  echo -e "    ${YELLOW}⚠${NC} No responsive patterns detected"
  ((warnings++))
fi

# Check for hardcoded colors
echo "  Token Compliance"
hardcoded_colors=$(grep -rn "#[0-9A-Fa-f]\{6\}\|rgb(\|rgba(" "$src_dir" --include="*.tsx" --include="*.ts" --include="*.css" 2>/dev/null | grep -v "node_modules\|\.craft" | wc -l)
if [ "$hardcoded_colors" -lt 5 ]; then
  echo -e "    ${GREEN}✓${NC} Minimal hardcoded colors ($hardcoded_colors found)"
else
  echo -e "    ${YELLOW}⚠${NC} Found $hardcoded_colors hardcoded color values"
  ((warnings++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $warnings -gt 0 ]; then
  echo -e "  ${YELLOW}$warnings warnings${NC} - Review recommended"
else
  echo -e "  ${GREEN}All polish checks passed${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Don't fail on warnings, just report
exit 0
