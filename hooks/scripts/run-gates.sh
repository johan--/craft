#!/bin/bash
# Run-gates: Execute quality gates from quality.yaml
# Returns pass/fail status with details

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve project root (handles monorepo)
source "$SCRIPT_DIR/find-project-root.sh" 2>/dev/null || {
  echo "Error: Could not resolve project root"
  exit 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if quality.yaml exists
if [ ! -f "${PROJECT_ROOT}.craft/quality.yaml" ]; then
  echo "No quality.yaml found. Skipping gates."
  exit 0
fi

# Detect package manager
PM=""
if [ -f "${PROJECT_ROOT}.craft/project.md" ]; then
  PM=$(grep "^package_manager:" "${PROJECT_ROOT}.craft/project.md" 2>/dev/null | sed 's/package_manager: *//' | tr -d '"' | tr -d "'")
fi
if [ -z "$PM" ]; then
  if [ -f "${PROJECT_ROOT}pnpm-lock.yaml" ]; then PM="pnpm"
  elif [ -f "${PROJECT_ROOT}yarn.lock" ]; then PM="yarn"
  elif [ -f "${PROJECT_ROOT}bun.lockb" ]; then PM="bun"
  elif [ -f "${PROJECT_ROOT}package-lock.json" ]; then PM="npm"
  else PM="npm"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  QUALITY GATES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

failed=0
passed=0

# Function to run a gate (runs from project root)
run_gate() {
  local name=$1
  local command=$2
  local blocking=$3

  printf "  %-15s " "$name"

  # Run the command from project root and capture output
  if output=$(cd "${PROJECT_ROOT}" && eval "$command" 2>&1); then
    echo -e "${GREEN}Pass${NC}"
    ((passed++))
    return 0
  else
    if [ "$blocking" = "true" ]; then
      echo -e "${RED}Fail${NC}"
      ((failed++))
      echo "$output" | head -20 | sed 's/^/    /'
      return 1
    else
      echo -e "${YELLOW}Warn${NC}"
      echo "$output" | head -10 | sed 's/^/    /'
      return 0
    fi
  fi
}

# TypeScript check
if command -v "$PM" &> /dev/null && [ -f "${PROJECT_ROOT}package.json" ]; then
  if grep -q '"typecheck"' "${PROJECT_ROOT}package.json" 2>/dev/null; then
    run_gate "TypeScript" "$PM run typecheck" "true" || true
  elif grep -q '"tsc"' "${PROJECT_ROOT}package.json" 2>/dev/null || [ -f "${PROJECT_ROOT}tsconfig.json" ]; then
    run_gate "TypeScript" "npx tsc --noEmit" "true" || true
  fi
fi

# Lint check
if command -v "$PM" &> /dev/null && [ -f "${PROJECT_ROOT}package.json" ]; then
  if grep -q '"lint"' "${PROJECT_ROOT}package.json" 2>/dev/null; then
    run_gate "Lint" "$PM run lint" "true" || true
  fi
fi

# Format check
if command -v "$PM" &> /dev/null && [ -f "${PROJECT_ROOT}package.json" ]; then
  if grep -q '"format:check"' "${PROJECT_ROOT}package.json" 2>/dev/null; then
    run_gate "Format" "$PM run format:check" "false" || true
  fi
fi

# Test check
if command -v "$PM" &> /dev/null && [ -f "${PROJECT_ROOT}package.json" ]; then
  if grep -q '"test"' "${PROJECT_ROOT}package.json" 2>/dev/null; then
    run_gate "Tests" "$PM test -- --passWithNoTests --watchAll=false" "true" || true
  fi
fi

# Build check
if command -v "$PM" &> /dev/null && [ -f "${PROJECT_ROOT}package.json" ]; then
  if grep -q '"build"' "${PROJECT_ROOT}package.json" 2>/dev/null; then
    run_gate "Build" "$PM run build" "true" || true
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $failed -gt 0 ]; then
  echo -e "  ${RED}$failed failed${NC}, ${GREEN}$passed passed${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
else
  echo -e "  ${GREEN}All $passed gates passed${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi
