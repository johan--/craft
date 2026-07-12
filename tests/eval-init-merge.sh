#!/bin/bash
# eval-init-merge.sh — headless choreography eval for craft-init's token merge.
#
# NOT named test-*.sh on purpose: run-all.sh must never pull this into the suite -
# each eval is a real headless `claude -p` session (minutes + tokens).
#
# Measures the PROSE-CHOREOGRAPHY risk the bash suite cannot: does a live
# orchestrator run merge-tokens.py report before the token AUQ, invoke merge mode
# as the writer, and end with a conforming tokens.yaml? The file-level outcome is
# scored mechanically; the hook + script guarantee the file even when choreography
# drifts, so FAILs here are wording bugs, not data loss.
#
# FIDELITY CAVEAT: AskUserQuestion cannot be answered interactively in -p mode, so
# the prompt pre-scripts the answers ("when you would ask, choose X"). That changes
# the AUQ presentation beat (the model may compress it), so this eval measures the
# report->merge choreography faithfully but the AUQ wording only approximately.
# The cmux live run (cross-terminal pattern, notebook note 2026-07-10) remains the
# hard gate for AUQ presentation.
#
# Usage:
#   bash tests/eval-init-merge.sh [N_RUNS]     # default 1 (smoke)
#
# Scorecard per run: [pass/FAIL] per check + a summary line. Exit 0 iff all runs
# fully conform (informational - this is a measurement, not a suite gate).

set -e

RUNS="${1:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MERGE="$PLUGIN_ROOT/hooks/scripts/merge-tokens.py"

command -v claude >/dev/null || { echo "SKIP: claude CLI not on PATH"; exit 0; }

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/src/ui/components" "$dir/.craft/design"
  # mature branch needs 20+ visual files; teal system with one seeded conflict
  for name in card button modal navbar sidebar footer form table badge tooltip avatar; do
    cat > "$dir/src/ui/components/${name}.css" << 'EOF'
.x { padding: 16px 24px; border-radius: 8px; background: #ffffff;
     font-family: "Inter", system-ui, sans-serif; transition: all 150ms ease; }
.x-action { background: #0f766e; color: #ffffff; border-radius: 8px; }
EOF
    printf 'import "./%s.css";\nexport function C() { return <div className="x" />; }\n' "$name" > "$dir/src/ui/components/${name}.tsx"
  done
  # mockup-born copper tokens.yaml: conflict on colors.surface, absent sections
  cat > "$dir/.craft/design/tokens.yaml" << 'EOF'
# Design Tokens - Craft Design System
# Locked: 2026-07-10 - from mockup eval-card (C1: Ember Restraint)

colors:
  primary: "#d97706"                     # Locked: 2026-07-10 - from mockup eval-card
  surface: "#141414"                     # Locked: 2026-07-10 - from mockup eval-card

radius:
  md: "8px"                              # Locked: 2026-07-10 - from mockup eval-card
EOF
  # disable any marketplace craft in the eval project (duplicate-registration guard)
  mkdir -p "$dir/.claude"
  echo '{"enabledPlugins": {"craft@craft": false}}' > "$dir/.claude/settings.json"
  ( cd "$dir" && git init -q )
}

PROMPT='/craft:init

This is a headless eval run - no human is present. Whenever you would use
AskUserQuestion, do not ask; adopt this answer and say which you adopted:
- Setup kind: Full setup
- Project intent: Skip - just scaffold
- Findings confirmation: Yes, that is accurate
- Deploy target(s): Self-hosted
- Token recognition: Lock high-confidence, defer low
- Energy: Steady and solid
- Inspiration: No, continue with what we have
Complete the full init flow to the end.'

TOTAL_FAIL=0
for i in $(seq 1 "$RUNS"); do
  DIR=$(mktemp -d)
  make_fixture "$DIR"
  echo "=== eval run $i/$RUNS ($DIR) ==="
  LOG=$(mktemp)
  set +e
  ( cd "$DIR" && CRAFT_PROJECT_ROOT="" claude -p "$PROMPT" \
        --output-format stream-json --verbose \
        --plugin-dir "$PLUGIN_ROOT" --dangerously-skip-permissions ) > "$LOG" 2>&1
  EC=$?
  set -e
  FAILS=0
  check() { # check <label> <shell test...>
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "  [pass] $label"; else echo "  [FAIL] $label"; FAILS=$((FAILS+1)); fi
  }
  not_check() { # inverted: pass when the test FAILS
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "  [FAIL] $label"; FAILS=$((FAILS+1)); else echo "  [pass] $label"; fi
  }
  TOK="$DIR/.craft/design/tokens.yaml"
  check "session completed (exit 0)" test "$EC" -eq 0
  check "mockup primary survived" grep -q 'primary: "#d97706"' "$TOK"
  check "conflict key kept existing (bulk never resolves)" grep -q 'surface: "#141414"' "$TOK"
  check "provenance comments survived" grep -q 'Locked: 2026-07-10 - from mockup eval-card' "$TOK"
  check "absent sections backfilled" grep -q 'z-index:' "$TOK"
  not_check "no placeholder in final file" grep -q '{{' "$TOK"
  check "merge mode was the writer (.tokens-premerge snapshot exists)" test -f "$DIR/.craft/design/.tokens-premerge"
  check "report mode ran (CONFLICT line in transcript)" grep -q 'CONFLICT colors.surface' "$LOG"
  check "merge summary echoed in transcript" grep -q 'merged: .* kept' "$LOG"
  if grep -q 'BLOCKED: .craft/design/tokens.yaml' "$LOG"; then
    echo "  [info] Write-deny tripped during run (hook caught a reach-for-Write; file was protected)"
  fi
  rm -f "$LOG"

  echo "  run $i: $FAILS check(s) failed"
  TOTAL_FAIL=$((TOTAL_FAIL + FAILS))
  rm -rf "$DIR"
done

echo ""
echo "=== eval-init-merge: $RUNS run(s), $TOTAL_FAIL total check failure(s) ==="
[ "$TOTAL_FAIL" -eq 0 ]
