#!/bin/bash
# complete-workflow-stage.sh — Transition: Mark a workflow stage as complete, advance to next
# Usage: complete-workflow-stage.sh <session-path> <stage-number> [notes]
#
# session-path: path to the session directory
# stage-number: the stage that just completed (e.g., 3)
# notes: optional notes to add (e.g., "5 violations found, all fixed")
#
# Supports both formats:
# - monolithic: stage headings + checklists in session.md
# - stages-v1 (hybrid): Progress table + per-stage checklist sections in session.md
#
# Updates session.md and prints progress to stdout.

set -e

SESSION_DIR="$1"
STAGE_NUM="$2"
NOTES="$3"

if [ -z "$SESSION_DIR" ] || [ -z "$STAGE_NUM" ]; then
  echo "Error: session path and stage number required"
  echo "Usage: complete-workflow-stage.sh <session-dir> <stage-number> [notes]"
  exit 1
fi

# Resolve relative paths
if [[ "$SESSION_DIR" != /* ]]; then
  SESSION_DIR="$PWD/$SESSION_DIR"
fi

SESSION_FILE="$SESSION_DIR/session.md"

if [ ! -f "$SESSION_FILE" ]; then
  echo "Error: session.md not found at $SESSION_FILE"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
NEXT_STAGE=$((STAGE_NUM + 1))

# Detect format: look for stages/ directory in the workflow dir
# Session dir is like: .../workflows/{name}/sessions/{date}-{slug}/
WORKFLOW_DIR="$(dirname "$(dirname "$SESSION_DIR")")"
if [ -d "$WORKFLOW_DIR/stages" ] && [ -n "$(ls -A "$WORKFLOW_DIR/stages" 2>/dev/null)" ]; then
  FORMAT="stages-v1"
else
  FORMAT="monolithic"
fi

if [ "$FORMAT" = "stages-v1" ]; then
  ##############################################
  # stages-v1: Update Progress table + checklist
  ##############################################

  # Artifact verification gate: check that the stage's artifact exists before transitioning
  # Find the stage file (try zero-padded first, then non-padded)
  STAGE_FILE=$(ls "$WORKFLOW_DIR/stages/$(printf "%02d" "$STAGE_NUM")-"*.md 2>/dev/null | head -1)
  [ -z "$STAGE_FILE" ] && STAGE_FILE=$(ls "$WORKFLOW_DIR/stages/${STAGE_NUM}-"*.md 2>/dev/null | head -1)

  if [ -n "$STAGE_FILE" ]; then
    # Read execution type and produces from stage file frontmatter
    STAGE_EXEC=$(awk '/^---$/{n++; next} n==1 && /^execution:/{print $2; exit}' "$STAGE_FILE")
    STAGE_PRODUCES=$(awk '/^---$/{n++; next} n==1 && /^produces:/{gsub(/^produces: *"?/, ""); gsub(/"$/, ""); print; exit}' "$STAGE_FILE")

    # For non-manual stages with produces: set, verify the artifact exists
    if [ "$STAGE_EXEC" != "manual" ] && [ -n "$STAGE_PRODUCES" ] && [ "$STAGE_PRODUCES" != '""' ] && [ "$STAGE_PRODUCES" != "''" ]; then
      # Check session artifacts directory for this stage's output
      ARTIFACT_FILE=$(ls "$SESSION_DIR/artifacts/$(printf "%02d" "$STAGE_NUM")-"*.md 2>/dev/null | head -1)
      [ -z "$ARTIFACT_FILE" ] && ARTIFACT_FILE=$(ls "$SESSION_DIR/artifacts/${STAGE_NUM}-"*.md 2>/dev/null | head -1)

      if [ -z "$ARTIFACT_FILE" ]; then
        echo "ERROR: Stage $STAGE_NUM artifact missing."
        echo "  Stage file: $STAGE_FILE"
        echo "  Execution: $STAGE_EXEC"
        echo "  Produces: $STAGE_PRODUCES"
        echo "  Expected artifact in: $SESSION_DIR/artifacts/"
        echo ""
        echo "The orchestrator must write the stage output to artifacts/ before completing the stage."
        echo "Write the artifact file, then re-run this script."
        exit 1
      fi
    fi
  fi

  # Count total stages from Progress table
  TOTAL=$(awk '/^\| [0-9]/' "$SESSION_FILE" | wc -l | tr -d ' ')

  # 1. Update the Progress table row for the completed stage
  awk -v stage_num="$STAGE_NUM" -v today="$TODAY" -v notes="$NOTES" '
    /^\| [0-9]/ {
      split($0, fields, "|")
      gsub(/^ +| +$/, "", fields[2])
      if (fields[2] == stage_num) {
        gsub(/active|pending/, "complete", fields[4])
        gsub(/^ +| +$/, "", fields[5])
        if (fields[5] == "") fields[5] = today
        if (notes != "") {
          gsub(/^ +| +$/, "", fields[6])
          fields[6] = notes
        }
        printf "| %s | %s | %s | %s | %s |\n", fields[2], fields[3], fields[4], fields[5], fields[6]
        next
      }
    }
    { print }
  ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

  # 2. Mark next stage as active in the Progress table
  awk -v stage_num="$NEXT_STAGE" '
    /^\| [0-9]/ {
      split($0, fields, "|")
      gsub(/^ +| +$/, "", fields[2])
      if (fields[2] == stage_num) {
        gsub(/pending/, "active", fields[4])
        printf "| %s | %s | %s | %s | %s |\n", fields[2], fields[3], fields[4], fields[5], fields[6]
        next
      }
    }
    { print }
  ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

  # 3. Mark current stage heading [active] -> [complete] in checklist section
  sed -i.bak -E "s/(## Stage ${STAGE_NUM}:.*)\[(active|pending)\]/\1[complete]/" "$SESSION_FILE"

  # 4. Check all [ ] items under this stage section
  awk -v stage="## Stage ${STAGE_NUM}:" -v nextstage="## Stage ${NEXT_STAGE}:" -v validation="## Validation" '
    BEGIN { in_stage = 0 }
    $0 ~ "^" stage { in_stage = 1 }
    in_stage && ($0 ~ "^" nextstage || $0 ~ "^" validation || /^## Stage/) { in_stage = 0 }
    in_stage && /^- \[ \]/ { gsub(/^- \[ \]/, "- [x]") }
    { print }
  ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

  # 5. Mark next stage heading as active
  sed -i.bak -E "s/(## Stage ${NEXT_STAGE}:.*)\[pending\]/\1[active]/" "$SESSION_FILE"

  # 6. Update current_stage in frontmatter
  sed -i.bak "s/^current_stage:.*/current_stage: ${NEXT_STAGE}/" "$SESSION_FILE"

  # Clean up backup files
  rm -f "$SESSION_FILE.bak"

  # 7. Print progress from Progress table
  echo ""
  echo "--- Workflow Progress ---"
  SESSION_NAME=$(awk '/^name:/{gsub(/^name: */, ""); print; exit}' "$SESSION_FILE")
  echo "$SESSION_NAME - Stage $STAGE_NUM/$TOTAL complete"
  echo ""
  awk '/^\| [0-9]/ {
    split($0, f, "|")
    gsub(/^ +| +$/, "", f[2])
    gsub(/^ +| +$/, "", f[3])
    gsub(/^ +| +$/, "", f[4])
    if (f[4] == "complete") printf "  [x] Stage %s: %s\n", f[2], f[3]
    else if (f[4] == "active") printf "  [ ] Stage %s: %s  <- next\n", f[2], f[3]
    else printf "  [ ] Stage %s: %s\n", f[2], f[3]
  }' "$SESSION_FILE"
  echo ""

else
  ##############################################
  # monolithic: Original format (unchanged)
  ##############################################

  # Count ## Stage headings to determine total
  TOTAL=$(grep -c '^## Stage' "$SESSION_FILE" || echo "0")

  # 1. Mark current stage heading [active] -> [complete]
  sed -i.bak -E "s/(## Stage ${STAGE_NUM}:.*)\[(active|pending)\]/\1[complete]/" "$SESSION_FILE"

  # 2. Check all [ ] items under this stage
  awk -v stage="## Stage ${STAGE_NUM}:" -v nextstage="## Stage ${NEXT_STAGE}:" -v validation="## Validation" '
    BEGIN { in_stage = 0 }
    $0 ~ "^" stage { in_stage = 1 }
    in_stage && ($0 ~ "^" nextstage || $0 ~ "^" validation) { in_stage = 0 }
    in_stage && /^- \[ \]/ { gsub(/^- \[ \]/, "- [x]") }
    { print }
  ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

  # 3. Add completed: date after the last checklist item of this stage
  awk -v stage="## Stage ${STAGE_NUM}:" -v nextstage="## Stage ${NEXT_STAGE}:" -v validation="## Validation" \
      -v today="$TODAY" -v notes="$NOTES" '
    BEGIN { in_stage = 0; last_check = 0; added = 0 }
    $0 ~ "^" stage { in_stage = 1 }
    in_stage && ($0 ~ "^" nextstage || $0 ~ "^" validation || /^$/) {
      if (in_stage && !added && last_check) {
        print "completed: " today
        if (notes != "") print "notes: \"" notes "\""
        added = 1
      }
      in_stage = 0
    }
    in_stage && /^- \[x\]/ { last_check = NR }
    { print }
    END {
      if (in_stage && !added && last_check) {
        print "completed: " today
        if (notes != "") print "notes: \"" notes "\""
      }
    }
  ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

  # 4. Update current_stage in frontmatter
  sed -i.bak "s/^current_stage:.*/current_stage: ${NEXT_STAGE}/" "$SESSION_FILE"

  # 5. Mark next stage as active
  sed -i.bak -E "s/(## Stage ${NEXT_STAGE}:.*)\[pending\]/\1[active]/" "$SESSION_FILE"

  # Clean up backup files
  rm -f "$SESSION_FILE.bak"

  # 6. Print progress
  echo ""
  echo "--- Workflow Progress ---"
  SESSION_NAME=$(awk '/^name:/{gsub(/^name: */, ""); print; exit}' "$SESSION_FILE")
  echo "$SESSION_NAME - Stage $STAGE_NUM/$TOTAL complete"
  echo ""
  grep -E '^\#\# Stage' "$SESSION_FILE" | while IFS= read -r line; do
    name=$(echo "$line" | sed 's/## //')
    if [[ "$line" == *"[complete]"* ]]; then
      echo "  [x] $name"
    elif [[ "$line" == *"[active]"* ]]; then
      echo "  [ ] $name  <- next"
    else
      echo "  [ ] $name"
    fi
  done
  echo ""
fi

# Signal whether this was the last stage (same for both formats)
if [ "$NEXT_STAGE" -gt "$TOTAL" ]; then
  echo "ALL STAGES COMPLETE ($TOTAL/$TOTAL). Run complete-workflow-session.sh to finalize."
else
  echo "Stage $STAGE_NUM complete. Now on stage $NEXT_STAGE of $TOTAL."
fi
