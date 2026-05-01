#!/bin/bash
# Track token usage per chunk/agent invocation
# Usage: track-usage.sh <story_file> <chunk_number> <agent_type> <total_tokens> <tool_uses> <duration_ms>

set -e

story_file="$1"
chunk_num="$2"
agent_type="$3"
total_tokens="$4"
tool_uses="$5"
duration_ms="$6"

if [ -z "$story_file" ] || [ -z "$chunk_num" ] || [ -z "$total_tokens" ]; then
  echo "Usage: track-usage.sh <story_file> <chunk> <agent_type> <tokens> <tool_uses> <duration_ms>"
  exit 1
fi

# Derive cycle directory and story name from story file path
cycle_dir=$(dirname "$(dirname "$story_file")")
story_name=$(basename "$story_file" .md)

# Create usage directory
usage_dir="$cycle_dir/.usage"
mkdir -p "$usage_dir"

usage_file="$usage_dir/$story_name.log"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Append usage entry
cat >> "$usage_file" << EOF
$timestamp | chunk:$chunk_num | agent:$agent_type | tokens:$total_tokens | tools:$tool_uses | duration:${duration_ms}ms
EOF

# Emit event (dual-write alongside .usage/ log)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$cycle_dir/.state" ]; then
  source "$cycle_dir/.state" 2>/dev/null
  EVENTS_DIR="$cycle_dir/.events"
  "$SCRIPT_DIR/append-event.sh" "$EVENTS_DIR" "usage_recorded" "$story_name" agent="$agent_type" tokens="$total_tokens" tools="$tool_uses" duration="$duration_ms" chunk="$chunk_num" || true
fi

exit 0
