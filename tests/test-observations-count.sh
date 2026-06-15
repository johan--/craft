#!/bin/bash
# test-observations-count.sh - Tests for observations-count.sh (pure bash/grep count)
# and the conditional injection into inject-craft-context.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
source "$SCRIPT_DIR/fixtures/with-cycle.sh"

COUNT="$SCRIPTS_DIR/observations-count.sh"
INJECT="$SCRIPTS_DIR/inject-craft-context.sh"

# Helper: write a sidecar with $1 unread entries and $2 surfaced entries into $3
make_sidecar() {
  local unread="$1" surfaced="$2" file="$3"
  mkdir -p "$(dirname "$file")"
  echo "observations:" > "$file"
  local i=0
  while [ "$i" -lt "$unread" ]; do
    printf '  - story: "s"\n    loc: "x.sh:%s"\n    surfaced: false\n' "$i" >> "$file"
    i=$((i + 1))
  done
  i=0
  while [ "$i" -lt "$surfaced" ]; do
    printf '  - story: "s"\n    loc: "y.sh:%s"\n    surfaced: true\n' "$i" >> "$file"
    i=$((i + 1))
  done
}

# --- Test 1: counts unread across multiple sidecars ---
begin_test "counts unread across multiple sidecars"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
make_sidecar 3 0 "$CYCLE/.observations/a.yaml"
make_sidecar 2 1 "$CYCLE/.observations/b.yaml"
out=$(bash "$COUNT" "$CYCLE")
assert_eq "5 unread across 2 stories" "5 unread / 2 stories" "$out"
cleanup_test_dir

# --- Test 2: excludes fully-surfaced stories from M ---
begin_test "excludes fully-surfaced stories from M"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
make_sidecar 2 0 "$CYCLE/.observations/a.yaml"
make_sidecar 0 3 "$CYCLE/.observations/b.yaml"   # all surfaced -> not counted
out=$(bash "$COUNT" "$CYCLE")
assert_eq "only the story with unread counts" "2 unread / 1 stories" "$out"
cleanup_test_dir

# --- Test 3: empty when no .observations dir ---
begin_test "empty when no .observations dir"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
mkdir -p "$CYCLE"
set +e
out=$(bash "$COUNT" "$CYCLE")
code=$?
set -e
assert_eq "empty output" "" "$out"
assert_exit_code "exit 0" "0" "$code"
cleanup_test_dir

# --- Test 4: empty when zero unread (all surfaced) ---
begin_test "empty when zero unread"
TEST_DIR=$(create_test_dir)
CYCLE="$TEST_DIR/cyc"
make_sidecar 0 4 "$CYCLE/.observations/a.yaml"
out=$(bash "$COUNT" "$CYCLE")
assert_eq "no line when nothing unread" "" "$out"
cleanup_test_dir

# --- Test 5: inject hook silent at zero ---
begin_test "inject hook silent at zero unread"
TEST_DIR=$(create_craft_with_cycle "obs-cycle" "Obs Cycle" "1")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-obs-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
EOF
echo 'title: "Obs Cycle"' > "$TEST_DIR/.craft/cycles/1-obs-cycle/cycle.yaml"
make_sidecar 0 2 "$TEST_DIR/.craft/cycles/1-obs-cycle/.observations/s.yaml"
set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && bash "$INJECT" 2>/dev/null)
set -e
assert_not_contains "no observations line when zero" "Craft observations:" "$RESULT"
cleanup_test_dir

# --- Test 6: inject hook adds line in active-cycle block when unread > 0 ---
begin_test "inject hook adds observations line when unread > 0"
TEST_DIR=$(create_craft_with_cycle "obs-cycle" "Obs Cycle" "1")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE="1-obs-cycle"
CURRENT_STORY=""
PLANNING_CYCLE=""
EOF
echo 'title: "Obs Cycle"' > "$TEST_DIR/.craft/cycles/1-obs-cycle/cycle.yaml"
make_sidecar 3 0 "$TEST_DIR/.craft/cycles/1-obs-cycle/.observations/s.yaml"
set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && bash "$INJECT" 2>/dev/null)
set -e
assert_contains "observations line present" "Craft observations: 3 unread / 1 stories" "$RESULT"
# Must appear before the appended .min orchestration index
obs_ln=$(echo "$RESULT" | grep -n "Craft observations:" | head -1 | cut -d: -f1)
idx_ln=$(echo "$RESULT" | grep -n "v1|craft-orchestration-index" | head -1 | cut -d: -f1)
if [ -n "$obs_ln" ] && [ -n "$idx_ln" ] && [ "$obs_ln" -lt "$idx_ln" ]; then
  echo "  PASS: observations line is above the .min index tail"
  PASS=$((PASS + 1))
else
  echo "  FAIL: observations line not above the .min index (obs=$obs_ln idx=$idx_ln)"
  FAIL=$((FAIL + 1))
fi
cleanup_test_dir

# --- Test 7: inject hook silent in planning context even with unread sidecars ---
begin_test "inject hook silent in planning context"
TEST_DIR=$(create_craft_with_cycle "plan-cycle" "Plan Cycle" "1")
cat > "$TEST_DIR/.craft/.global-state" << 'EOF'
ACTIVE_CYCLE=""
CURRENT_STORY=""
PLANNING_CYCLE="1-plan-cycle"
EOF
echo 'title: "Plan Cycle"' > "$TEST_DIR/.craft/cycles/1-plan-cycle/cycle.yaml"
# Unread sidecar exists in the cycle dir, but no ACTIVE_CYCLE -> elif branch unreached
make_sidecar 4 0 "$TEST_DIR/.craft/cycles/1-plan-cycle/.observations/s.yaml"
set +e
RESULT=$(cd "$TEST_DIR" && unset CRAFT_PROJECT_ROOT && bash "$INJECT" 2>/dev/null)
set -e
assert_contains "still shows PLANNING context" "PLANNING" "$RESULT"
assert_not_contains "no observations line in planning context" "Craft observations:" "$RESULT"
cleanup_test_dir

finish_tests
