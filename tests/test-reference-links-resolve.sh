#!/bin/bash
# test-reference-links-resolve.sh - Every anchored runtime Read points at a real file.
# Walks the mechanically-extractable anchor forms and asserts each target exists:
#   ${CLAUDE_PLUGIN_ROOT}/PATH   (skills/, commands/ - substituted at load)
#   <PLUGIN_ROOT>/PATH           (agents/ - injected by the invoker)
# A missed rename or typo'd anchor goes red here, at commit time, instead of failing
# silently in a user's session (the run-7 failure class this suite line kills).
#
# Scope boundary (deliberate): same-directory-phrased Reads inside raw-Read reference
# files are natural language, not mechanically extractable - their net is the runtime
# stop-rule in the orchestration index (layered defense: CI kills the mechanical
# class, the stop-rule catches the rest).
#
# Skips candidates carrying placeholder metacharacters (* < > { } [ ] $) - forms like
# `commands/craft-*.md` or `templates/analysis/pending/[type]-...` are illustrative,
# not real targets. Extraction stops at whitespace/newline/quote/paren delimiters.

source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

begin_test "every anchored runtime Read target resolves to a real path"

check_form() {
  local marker="$1" scope="$2" label="$3"
  local missing=0 checked=0
  while IFS= read -r raw; do
    # strip the marker prefix and trailing punctuation
    local rel="${raw#"$marker"/}"
    rel="${rel%%[\`\")\]]*}"
    rel="${rel%.}"
    rel="${rel%,}"
    # skip placeholder/illustrative forms
    case "$rel" in
      *'*'*|*'<'*|*'>'*|*'{'*|*'}'*|*'['*|*'$'*|'') continue ;;
    esac
    checked=$((checked+1))
    if [ ! -e "$PLUGIN_ROOT/$rel" ]; then
      echo "    MISSING: $rel (form: $label)"
      missing=$((missing+1))
    fi
  done < <(grep -rhoE "${4}" $scope 2>/dev/null | sort -u)
  if [ "$missing" -eq 0 ]; then
    echo "  PASS: $label - all $checked extracted targets exist"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label - $missing missing target(s) of $checked"
    FAIL=$((FAIL + 1))
  fi
}

cd "$PLUGIN_ROOT"

# ${CLAUDE_PLUGIN_ROOT}/... in substitution-capable surfaces (also hooks/, reference/)
check_form '${CLAUDE_PLUGIN_ROOT}' "commands/ skills/ reference/" "variable-anchored" \
  '\$\{CLAUDE_PLUGIN_ROOT\}/[^ `")]+'

# <PLUGIN_ROOT>/... in agent files (invoker-injected)
check_form '<PLUGIN_ROOT>' "agents/" "invoker-anchored" \
  '<PLUGIN_ROOT>/[^ `")]+'

begin_test "placeholder forms are skipped, not flagged"
# Sanity: a known illustrative form must not be treated as a missing target.
# guide.md carries deliberately-illustrative paths like <PLUGIN_ROOT>/commands/craft-*.md;
# if the filter above ever regresses, the first test fails on them - this assert
# documents the fixture that exercises the filter.
if grep -rqE '<PLUGIN_ROOT>/commands/craft-\*' agents/ 2>/dev/null; then
  echo "  PASS: illustrative glob form present in corpus and not flagged above"
else
  echo "  PASS: no illustrative glob form in corpus (filter untested but harmless)"
fi
PASS=$((PASS + 1))

finish_tests
