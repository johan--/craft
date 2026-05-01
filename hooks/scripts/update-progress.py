#!/usr/bin/env python3
"""Update-progress: Track file changes during story implementation.

Async PostToolUse hook — updates timestamps and touched files in .craft/ state.
Follows hookify canonical pattern: json.load(sys.stdin), sys.exit(0) always.
"""
import json
import os
import sys
from datetime import datetime, timezone


def find_project_root():
    """Find the nearest Craft project root by walking up from cwd.

    Resolution order:
      1. CRAFT_PROJECT_ROOT env var (set by session-start or /craft:project)
      2. Walk up from cwd looking for .craft/.global-state (initialized project)
      3. Walk up from cwd looking for .craft/ directory (fallback)
    """
    # 1. Check env var
    env_root = os.environ.get("CRAFT_PROJECT_ROOT", "")
    if env_root:
        root = env_root.rstrip("/") + "/"
        if os.path.isdir(os.path.join(root, ".craft")):
            return root

    # 2. Walk up looking for .craft/.global-state
    d = os.getcwd()
    while d != os.path.dirname(d):
        if os.path.isfile(os.path.join(d, ".craft", ".global-state")):
            return d.rstrip("/") + "/"
        d = os.path.dirname(d)

    # 3. Fallback: walk up looking for .craft/ directory
    d = os.getcwd()
    while d != os.path.dirname(d):
        if os.path.isdir(os.path.join(d, ".craft")):
            return d.rstrip("/") + "/"
        d = os.path.dirname(d)

    return None


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


def write_state_file(path, data):
    """Write a dict as shell-style key=value state file (atomic via rename)."""
    tmp_path = path + ".tmp"
    with open(tmp_path, "w") as f:
        for key, value in data.items():
            if " " in value or not value:
                f.write(f'{key}="{value}"\n')
            else:
                f.write(f'{key}="{value}"\n')
    os.replace(tmp_path, path)


def main():
    # Read hook input from stdin
    input_data = json.load(sys.stdin)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "") or tool_input.get("path", "") or ""

    # Skip .craft/ paths — these are harness state files, not implementation
    if ".craft/" in file_path:
        return

    # Find project root
    project_root = find_project_root()
    if not project_root:
        return

    global_state_path = os.path.join(project_root, ".craft", ".global-state")
    if not os.path.isfile(global_state_path):
        return

    state = parse_state_file(global_state_path)
    active_cycle = state.get("ACTIVE_CYCLE", "")
    current_story = state.get("CURRENT_STORY", "")

    if not active_cycle or not current_story:
        return

    # Update last activity timestamp in .global-state
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    state["LAST_ACTIVITY"] = now
    write_state_file(global_state_path, state)

    # Track touched files in cycle state
    cycle_state_path = os.path.join(
        project_root, ".craft", "cycles", active_cycle, ".state"
    )
    if not os.path.isfile(cycle_state_path):
        return

    cycle_state = parse_state_file(cycle_state_path)

    # Add file to touched files list if not already present
    touched = cycle_state.get("TOUCHED_FILES", "")
    if file_path and file_path not in touched:
        if touched:
            touched = touched + " " + file_path
        else:
            touched = file_path
        cycle_state["TOUCHED_FILES"] = touched

    # Update last checkpoint timestamp
    cycle_state["LAST_CHECKPOINT"] = now
    write_state_file(cycle_state_path, cycle_state)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Async hook — always exit cleanly
    sys.exit(0)
