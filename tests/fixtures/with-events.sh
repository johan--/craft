#!/bin/bash
# fixtures/with-events.sh — .craft/ with sample JSONL event data
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/fixtures/with-events.sh"
#   dir=$(create_craft_with_events)
#
# Creates:
#   .craft/cycles/1-test-cycle/.events/test-story.jsonl (4 events)
#   .craft/cycles/1-test-cycle/.events/second-story.jsonl (2 events)
#   .craft/cycles/1-test-cycle/.events/_cycle.jsonl (2 events)

FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$FIXTURES_DIR/with-story.sh"

create_craft_with_events() {
  # Create base structure with a story
  local dir
  dir=$(create_craft_with_story "test-cycle" "test-story" "Test Story" "3" "active")
  local events_dir="$dir/.craft/cycles/1-test-cycle/.events"
  mkdir -p "$events_dir"

  # Story 1 events (4 events)
  cat > "$events_dir/test-story.jsonl" << 'EOF'
{"timestamp":"2026-02-16T10:00:00Z","type":"story_started","story":"test-story","data":{"chunk_total":"3"}}
{"timestamp":"2026-02-16T10:05:00Z","type":"chunk_completed","story":"test-story","data":{"chunk":"1","total":"3"}}
{"timestamp":"2026-02-16T10:10:00Z","type":"tool_failure","story":"test-story","data":{"tool":"Edit","error":"old_string not unique"}}
{"timestamp":"2026-02-16T10:15:00Z","type":"chunk_completed","story":"test-story","data":{"chunk":"2","total":"3"}}
EOF

  # Story 2 events (2 events)
  cat > "$events_dir/second-story.jsonl" << 'EOF'
{"timestamp":"2026-02-16T11:00:00Z","type":"story_started","story":"second-story","data":{"chunk_total":"2"}}
{"timestamp":"2026-02-16T11:05:00Z","type":"chunk_completed","story":"second-story","data":{"chunk":"1","total":"2"}}
EOF

  # Cycle-level events (2 events)
  cat > "$events_dir/_cycle.jsonl" << 'EOF'
{"timestamp":"2026-02-16T09:00:00Z","type":"cycle_started","story":"_cycle","data":{"name":"test-cycle"}}
{"timestamp":"2026-02-16T12:00:00Z","type":"cycle_completed","story":"_cycle","data":{"stories_complete":"2"}}
EOF

  echo "$dir"
}
