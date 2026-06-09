#!/bin/bash
# pre-push-gate.sh - PreToolUse wrapper that blocks `git push` on documentation drift.
#
# CONTRIBUTOR TOOLING - for developing craft ITSELF. Registered only in the
# maintainer's local settings (gitignored, not shipped with the plugin). NOT a
# feature for projects built with craft.
#
# Registered as a PreToolUse hook (matcher Bash, if: Bash(git push *)). Reads the
# hook's stdin JSON, runs the caller-agnostic doc-drift core, and on drift emits a
# permissionDecision:deny with the findings as the reason (exit 0 + JSON, never
# exit 2 - exit-2 can make the model stop instead of acting on the message).
# Pairs with scripts/check-doc-drift.sh.
#
# Fails open: if the command is not a push, jq is missing, or the core is absent,
# it raises no objection and normal permission flow applies. A blocking gate that
# fails closed on its own tooling would wedge every push.

set -uo pipefail

INPUT="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

# The settings `if` filter already scopes this to git push; double-check defensively.
# Anchor to `git push` as a command prefix (start, or after whitespace) so the
# backstop is no wider than the filter - a stray "git push" inside an argument or
# comment (e.g. grep "git push" log) must not trigger a check run.
case "$COMMAND" in
  git\ push*|*[[:space:]]git\ push*) ;;
  *) exit 0 ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-.}")"
CORE="$ROOT/scripts/check-doc-drift.sh"
[ -x "$CORE" ] || exit 0

if findings="$(bash "$CORE" 2>&1)"; then
  exit 0   # clean - no objection; normal permission flow allows the push
fi

# Drift detected: deny with the findings as the reason (jq escapes it safely).
jq -n --arg r "$findings" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Push blocked - documentation drift:\n" + $r)
  }
}'
exit 0
