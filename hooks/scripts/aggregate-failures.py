#!/usr/bin/env python3
"""aggregate-failures.py — Aggregate knowledge-gap failures across stories.

Usage: aggregate-failures.py <project-root>

Reads .craft/cycles/<cycle>/.failures, filters to knowledge_gap entries,
applies cross-story threshold (2+ unique stories), and writes qualifying
patterns to .craft/cycles/<cycle>/.failure-patterns.yaml.

Designed to run after each story completion. Always exits 0.
PyYAML is not available — all YAML output uses stdlib string formatting.
"""
import os
import re
import sys
from datetime import datetime, timezone


# --- Reused from handle-tool-failure.py (acceptable duplication in hook scripts) ---

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

    Duplicated from handle-tool-failure.py for legacy entry fallback.
    Conservative default: unrecognized → iteration_noise.
    """
    error_lower = error.lower()

    # KNOWLEDGE GAP: Project doesn't have this npm/pnpm script
    if "missing script" in error_lower:
        match = re.search(r'[Mm]issing script:\s*"?(\w[\w-]*)"?', error)
        script = match.group(1) if match else "unknown"
        return ("knowledge_gap", f"missing-script-{script}")

    # KNOWLEDGE GAP: Shell command not installed / not on PATH
    if tool_name == "Bash" and "command not found" in error_lower:
        return ("knowledge_gap", "bash-command-not-found")

    # ITERATION NOISE: Test runner output
    if any(marker in error for marker in [
        "FAIL ", "Failed Tests", "Failed Suites",
        "vitest", "jest", "AssertionError", "TypeError:",
        "TestingLibraryElementError",
    ]):
        return ("iteration_noise", "test-failure")

    # ITERATION NOISE: TypeScript compilation errors
    if "error TS" in error:
        return ("iteration_noise", "typescript-error")

    # ITERATION NOISE: Trying to read a file not yet created
    if tool_name == "Read" and "does not exist" in error_lower:
        return ("iteration_noise", "read-missing-file")

    # ITERATION NOISE: Bundler can't resolve module not yet created
    if "Failed to resolve import" in error:
        return ("iteration_noise", "import-not-yet-created")

    # KNOWLEDGE GAP: Edit tool patch failures — agent has stale context
    if tool_name == "Edit":
        if "not unique" in error_lower:
            return ("knowledge_gap", "edit-unique-context")
        if "not found" in error_lower:
            return ("knowledge_gap", "edit-not-found")

    # DEFAULT: conservative — unknown failures are noise
    return ("iteration_noise", f"{tool_name.lower()}-unknown")


# --- Pattern label mapping ---

# Known patterns with human-readable labels
PATTERN_LABELS = {
    "bash-command-not-found": "Shell command not found — check if tool is installed or on PATH",
    "edit-unique-context": "Edit patch string not unique — agent has stale file context",
    "edit-not-found": "Edit patch string not found — agent has stale file content",
}

# Known patterns with suggested rule slugs
PATTERN_RULES = {
    "bash-command-not-found": "check-command-availability",
    "edit-unique-context": "reread-before-edit",
    "edit-not-found": "reread-before-edit",
}


def get_label(pattern: str, pm: str = "npm") -> str:
    """Return human-readable label for a pattern."""
    if pattern in PATTERN_LABELS:
        return PATTERN_LABELS[pattern]
    # Dynamic: missing-script-{script}
    match = re.match(r"missing-script-(.+)$", pattern)
    if match:
        script = match.group(1)
        return f"Project does not have '{pm} run {script}' — check available scripts with '{pm} run'"
    return f"Repeated failure: {pattern}"


def get_suggested_rule(pattern: str) -> str:
    """Return suggested rule slug for a pattern."""
    if pattern in PATTERN_RULES:
        return PATTERN_RULES[pattern]
    # Dynamic: missing-script-{script}
    match = re.match(r"missing-script-(.+)$", pattern)
    if match:
        script = match.group(1)
        return f"use-correct-{script}-command"
    return pattern.replace("-", "_")


# --- Entry parsing ---

_FIELD_RE = re.compile(r'^(\w+):\s*"?(.+?)"?\s*$')


def parse_entry(block: str) -> dict:
    """Parse a single ---\\n...\\n block into a dict.

    Handles multiline error: | values by reading only the first line.
    Fields without category/pattern are treated as legacy.
    """
    entry = {}
    lines = block.strip().splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        m = _FIELD_RE.match(line)
        if m:
            key = m.group(1)
            value = m.group(2).strip().rstrip('"').strip()
            # Multiline block: next lines are indented
            if value == "|":
                # Collect indented continuation lines
                collected = []
                i += 1
                while i < len(lines) and (lines[i].startswith("  ") or lines[i].startswith("\t")):
                    collected.append(lines[i].strip())
                    i += 1
                entry[key] = "\n".join(collected)
                continue
            entry[key] = value
        i += 1
    return entry


def parse_failures_file(path: str) -> list:
    """Parse .failures file into list of entry dicts.

    Entries are separated by lines that are exactly '---'.
    Each entry starts with an implicit or explicit '---'.
    """
    with open(path, "r") as f:
        content = f.read()

    # Split on the separator --- (may appear at start too)
    # The file format starts entries with ---
    raw_blocks = re.split(r'\n?^---\s*$', content, flags=re.MULTILINE)

    entries = []
    for block in raw_blocks:
        block = block.strip()
        if not block:
            continue
        entry = parse_entry(block)
        if entry:
            entries.append(entry)
    return entries


# --- YAML output (no PyYAML) ---

def _yaml_str(value: str) -> str:
    """Escape a string for YAML double-quoted output."""
    return value.replace('\\', '\\\\').replace('"', '\\"')


def write_patterns_yaml(path: str, qualifying: list) -> None:
    """Write .failure-patterns.yaml using stdlib string formatting."""
    generated = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    lines = [
        "# Auto-generated by aggregate-failures.py",
        "# Knowledge gaps meeting cross-story threshold (2+ stories)",
        "# Review during /craft:reflect to promote to rules",
        f'generated: "{generated}"',
        "",
        "patterns:",
    ]

    for item in qualifying:
        pattern = item["pattern"]
        label = item["label"]
        stories = item["stories"]
        total_count = item["total_count"]
        first_seen = item["first_seen"]
        suggested_rule = item["suggested_rule"]

        # stories: ["a", "b", "c"]
        stories_inline = "[" + ", ".join(f'"{s}"' for s in sorted(stories)) + "]"

        lines.append(f'  - pattern: "{_yaml_str(pattern)}"')
        lines.append(f'    label: "{_yaml_str(label)}"')
        lines.append(f'    category: "knowledge_gap"')
        lines.append(f'    stories: {stories_inline}')
        lines.append(f'    total_count: {total_count}')
        lines.append(f'    first_seen: "{_yaml_str(first_seen)}"')
        lines.append(f'    suggested_rule: "{_yaml_str(suggested_rule)}"')

    content = "\n".join(lines) + "\n"
    with open(path, "w") as f:
        f.write(content)


# --- Main logic ---

def main():
    if len(sys.argv) < 2:
        return  # No project root — exit cleanly

    project_root = sys.argv[1].rstrip("/")

    # Read active cycle from global state
    global_state_path = os.path.join(project_root, ".craft", ".global-state")
    state = parse_state_file(global_state_path)
    active_cycle = state.get("ACTIVE_CYCLE", "")
    if not active_cycle:
        return  # No active cycle — nothing to aggregate

    # Locate .failures file
    cycle_dir = os.path.join(project_root, ".craft", "cycles", active_cycle)
    failures_path = os.path.join(cycle_dir, ".failures")
    if not os.path.isfile(failures_path):
        return  # No failures yet — clean exit, no output

    # Parse all entries
    entries = parse_failures_file(failures_path)
    if not entries:
        return

    # Filter to knowledge_gap only; classify legacy entries without category/pattern
    knowledge_gaps = []
    for entry in entries:
        category = entry.get("category", "")
        pattern = entry.get("pattern", "")
        tool = entry.get("tool", "unknown")
        error = entry.get("error", "")

        if category == "knowledge_gap":
            knowledge_gaps.append(entry)
        elif not category:
            # Legacy entry: classify via fallback
            inferred_category, inferred_pattern = classify_failure(tool, error)
            if inferred_category == "knowledge_gap":
                entry_copy = dict(entry)
                entry_copy["category"] = inferred_category
                entry_copy["pattern"] = inferred_pattern
                knowledge_gaps.append(entry_copy)
        # iteration_noise entries are silently dropped

    if not knowledge_gaps:
        return

    # Group by pattern: collect unique stories + count + first_seen
    pattern_data: dict = {}
    for entry in knowledge_gaps:
        pat = entry.get("pattern", "unknown")
        story = entry.get("story", "unknown")
        timestamp = entry.get("timestamp", "")

        if pat not in pattern_data:
            pattern_data[pat] = {
                "stories": set(),
                "total_count": 0,
                "first_seen": timestamp,
            }

        pattern_data[pat]["stories"].add(story)
        pattern_data[pat]["total_count"] += 1
        # Track earliest timestamp
        if timestamp and (not pattern_data[pat]["first_seen"] or timestamp < pattern_data[pat]["first_seen"]):
            pattern_data[pat]["first_seen"] = timestamp

    # Apply cross-story threshold: 2+ unique stories required
    qualifying = []
    for pat, data in sorted(pattern_data.items()):
        if len(data["stories"]) >= 2:
            qualifying.append({
                "pattern": pat,
                "label": get_label(pat),
                "stories": data["stories"],
                "total_count": data["total_count"],
                "first_seen": data["first_seen"],
                "suggested_rule": get_suggested_rule(pat),
            })

    if not qualifying:
        # Nothing qualifies — do not write empty file
        return

    # Write .failure-patterns.yaml (overwrite for idempotency)
    patterns_path = os.path.join(cycle_dir, ".failure-patterns.yaml")
    write_patterns_yaml(patterns_path, qualifying)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Hook scripts always exit cleanly
    sys.exit(0)
