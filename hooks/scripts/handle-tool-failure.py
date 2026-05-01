#!/usr/bin/env python3
"""Handle-tool-failure: Capture tool failure context during implementation.

Async PostToolUseFailure hook — logs failures for learning capture and provides
helpful hints. Follows hookify canonical pattern: json.load(sys.stdin), sys.exit(0) always.
"""
import json
import os
import subprocess
import sys
from datetime import datetime, timezone


def parse_state_file(path):
    """Parse a shell-style key=value state file into a dict."""
    data = {}
    if not os.path.isfile(path):
        return data
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                data[key.strip()] = value.strip().strip('"')
    return data


def classify_failure(tool_name: str, error: str) -> tuple:
    """Classify failure as knowledge_gap or iteration_noise.

    Returns (category, pattern) tuple.
    Conservative default: unrecognized failures → iteration_noise to avoid
    false positives in the learnings pipeline.
    """
    import re

    error_lower = error.lower()

    # KNOWLEDGE GAP: Project doesn't have this npm/pnpm script
    if "missing script" in error_lower:
        match = re.search(r'[Mm]issing script:\s*"?(\w[\w-]*)"?', error)
        script = match.group(1) if match else "unknown"
        return ("knowledge_gap", f"missing-script-{script}")

    # KNOWLEDGE GAP: Shell command not installed / not on PATH
    if tool_name == "Bash" and "command not found" in error_lower:
        return ("knowledge_gap", "bash-command-not-found")

    # ITERATION NOISE: Test runner output (TDD working correctly — tests failing
    # before implementation is expected and not a signal worth learning from)
    if any(marker in error for marker in [
        "FAIL ", "Failed Tests", "Failed Suites",
        "vitest", "jest", "AssertionError", "TypeError:",
        "TestingLibraryElementError",
    ]):
        return ("iteration_noise", "test-failure")

    # ITERATION NOISE: TypeScript compilation errors during implementation
    if "error TS" in error:
        return ("iteration_noise", "typescript-error")

    # ITERATION NOISE: Trying to read a file being built (file doesn't exist yet)
    if tool_name == "Read" and "does not exist" in error_lower:
        return ("iteration_noise", "read-missing-file")

    # ITERATION NOISE: Vite/Next.js bundler can't resolve module not yet created
    if "Failed to resolve import" in error:
        return ("iteration_noise", "import-not-yet-created")

    # KNOWLEDGE GAP: Edit tool can't apply patch — agent has stale context
    if tool_name == "Edit":
        if "not unique" in error_lower:
            return ("knowledge_gap", "edit-unique-context")
        if "not found" in error_lower:
            return ("knowledge_gap", "edit-not-found")

    # DEFAULT: conservative — unknown failures are noise, not learnings
    return ("iteration_noise", f"{tool_name.lower()}-unknown")


def main():
    # Read hook input from stdin
    input_data = json.load(sys.stdin)

    tool_name = input_data.get("tool_name", "unknown")
    error = input_data.get("error", "")

    # Resolve project root (CRAFT_PROJECT_ROOT set by session-start, or find-project-root.sh fallback)
    project_root = os.environ.get("CRAFT_PROJECT_ROOT", "").rstrip("/")
    if not project_root:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        result = subprocess.run(
            ["bash", "-c", f"source '{script_dir}/find-project-root.sh' && printf '%s' \"$PROJECT_ROOT\""],
            capture_output=True, text=True
        )
        project_root = result.stdout.strip().rstrip("/")
    if not project_root:
        return

    # Only track failures in craft-enabled projects during implementation
    global_state_path = os.path.join(project_root, ".craft", ".global-state")
    if not os.path.isfile(global_state_path):
        return

    state = parse_state_file(global_state_path)
    active_cycle = state.get("ACTIVE_CYCLE", "")
    current_story = state.get("CURRENT_STORY", "")

    # Only log failures during active implementation
    if not active_cycle or not current_story:
        return

    current_chunk = state.get("CURRENT_CHUNK", "unknown")

    # Log the failure for potential learning capture
    failure_log = os.path.join(project_root, ".craft", "cycles", active_cycle, ".failures")
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    # Classify before writing so category/pattern land in the log entry
    category, pattern = classify_failure(tool_name, error)

    # Append to failures log (create if doesn't exist)
    with open(failure_log, "a") as f:
        f.write(f"""---
timestamp: "{timestamp}"
story: "{current_story}"
chunk: "{current_chunk}"
tool: "{tool_name}"
category: "{category}"
pattern: "{pattern}"
error: |
  {error}
""")

    # Emit event (dual-write alongside .failures)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    events_dir = os.path.join(project_root, ".craft", "cycles", active_cycle, ".events")
    error_first_line = error.split("\n")[0][:200] if error else "unknown"
    try:
        result = subprocess.run(
            [os.path.join(script_dir, "append-event.sh"),
             events_dir, "tool_failure", current_story,
             f"tool={tool_name}", f"chunk={current_chunk}", f"error={error_first_line}"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0 and result.stderr:
            print(f"Event log warning: {result.stderr.strip()}", file=sys.stderr)
    except Exception:
        pass  # Event logging must never block

    # Provide helpful context back to Claude based on failure type
    if tool_name == "Bash":
        if "command not found" in error:
            print("Bash failure: Command not found. Check if the tool is installed or use an alternative.")
        elif "Permission denied" in error:
            print("Bash failure: Permission denied. May need elevated permissions or different approach.")
        elif "No such file" in error:
            print("Bash failure: File not found. Verify the path exists before proceeding.")
    elif tool_name == "Edit":
        if "not unique" in error:
            print("Edit failure: String not unique. Add more context to old_string or use replace_all.")
        elif "not found" in error:
            print("Edit failure: String not found. Re-read the file to get current content.")
    elif tool_name == "Write":
        if "Permission" in error:
            print("Write failure: Permission denied. Check file permissions.")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Async hook — always exit cleanly
    sys.exit(0)
