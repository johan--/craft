#!/usr/bin/env python3
"""merge-tokens.py - the sole writer for merges into an existing tokens.yaml.

Line-surgical by construction: the file is never parsed-and-regenerated. Untouched
lines (and therefore their provenance comments) are byte-preserved; the script only
inserts new key lines and replaces the value lines of explicitly sanctioned keys.

Modes:
  report <tokens.yaml>                     stdin: incoming values
      Prints a mechanical per-key diff: CONFLICT / NEW / SAME lines. Run this BEFORE
      the token AskUserQuestion and paste its output verbatim into the presentation.

  merge <tokens.yaml> --template <path>    stdin: incoming values
        [--precedence existing|incoming]   default: existing (extraction path;
                                           'incoming' = inspiration Lock, where the
                                           user's fresh explicit choice wins)
        [--resolve section.key=incoming]   apply the user's per-key AUQ choice; only
                                           valid for keys in the derived conflict set
      Snapshots to <dir>/.tokens-premerge, applies the keyed union, backfills absent
      template sections (never a {{...}} placeholder), then self-verifies. On any
      invariant violation the snapshot is restored and the exit code is non-zero.
      FAILED means FAILED - do not retry with the Write tool; fix the input.

stdin contract (both modes): one value per line,
    section.key=value|provenance comment
The dotted key's first segment must be a section defined in the template (schema
source of truth). The comment is optional and becomes the inserted line's comment.

Exit codes: 0 ok; 1 invalid input (file untouched); 2 self-verify failed (restored).
"""

import os
import re
import shutil
import sys

KEY_RE = re.compile(r'^(\s*)([A-Za-z0-9_-]+):(.*)$')


def fail(msg, code=1):
    sys.stderr.write(f"merge-tokens: ERROR: {msg}\n")
    sys.exit(code)


def split_value_comment(rest):
    """Split the text after 'key:' into (value, comment). '#' inside quotes is value."""
    rest = rest.rstrip("\n")
    stripped = rest.strip()
    if not stripped:
        return "", ""
    if stripped.startswith('"'):
        end = stripped.find('"', 1)
        if end != -1:
            value = stripped[: end + 1]
            tail = stripped[end + 1:].strip()
            comment = tail.lstrip("#").strip() if tail.startswith("#") else ""
            return value, comment
    # unquoted: comment starts at first ' #'
    m = re.search(r'\s#\s?', stripped)
    if m:
        return stripped[: m.start()].strip(), stripped[m.end():].strip()
    return stripped, ""


def norm(value):
    """Normalize a value for comparison: strip surrounding quotes and whitespace."""
    v = value.strip()
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        v = v[1:-1]
    return v


def parse_file(lines):
    """Return {dotted.key: (line_index, value)} for every key line, tracking depth."""
    keys = {}
    path = []
    for i, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = KEY_RE.match(line)
        if not m:
            continue
        indent, name, rest = m.groups()
        depth = len(indent) // 2
        path = path[:depth] + [name]
        value, _ = split_value_comment(rest)
        if value:
            keys[".".join(path)] = (i, value)
    return keys


def section_bounds(lines, section):
    """(header_index, end_index_exclusive) of a top-level section, or None."""
    start = None
    for i, line in enumerate(lines):
        m = KEY_RE.match(line)
        if m and m.group(1) == "" and m.group(2) == section:
            start = i
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        m = KEY_RE.match(lines[j])
        if m and m.group(1) == "":
            end = j
            break
    # trim trailing blanks/banner comments of the NEXT section out of the range
    while end > start + 1 and (not lines[end - 1].strip() or lines[end - 1].startswith("#")):
        end -= 1
    return (start, end)


def parse_stdin(raw):
    """Parse 'section.key=value|comment' lines -> ordered [(dotted, value, comment)]."""
    incoming = []
    for lineno, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            continue
        if "=" not in line:
            fail(f"stdin line {lineno}: expected section.key=value|comment, got: {line!r}")
        dotted, rest = line.split("=", 1)
        dotted = dotted.strip()
        if "." not in dotted:
            fail(f"stdin line {lineno}: key must be section-qualified (section.key): {dotted!r}")
        value, _, comment = rest.partition("|")
        incoming.append((dotted, value.strip(), comment.strip()))
    if not incoming:
        fail("stdin: no incoming values")
    return incoming


def template_sections(template_path):
    with open(template_path) as f:
        tlines = f.readlines()
    sections = {}
    current = None
    for line in tlines:
        m = KEY_RE.match(line)
        if m and m.group(1) == "":
            current = m.group(2)
            sections[current] = []
        if current is not None:
            sections[current].append(line)
    return sections


def classify(existing_keys, incoming):
    conflicts, news, sames = [], [], []
    for dotted, value, comment in incoming:
        if dotted in existing_keys:
            _, evalue = existing_keys[dotted]
            if norm(evalue) == norm(value):
                sames.append((dotted, value))
            else:
                conflicts.append((dotted, evalue, value))
        else:
            news.append((dotted, value, comment))
    return conflicts, news, sames


def format_value(value):
    v = value.strip()
    if v.startswith('"') or re.fullmatch(r'-?\d+(\.\d+)?', v):
        return v
    return f'"{v}"'


def insert_key(lines, dotted, value, comment):
    """Insert a new key line at the end of its (possibly created) section path."""
    parts = dotted.split(".")
    section = parts[0]
    bounds = section_bounds(lines, section)
    if bounds is None:
        lines.append("\n")
        lines.append(f"{section}:\n")
        bounds = (len(lines) - 1, len(lines))
    start, end = bounds
    # walk/create intermediate levels (rare: 3+ deep like spacing.scale.4)
    insert_at = end
    depth = 1
    for level, part in enumerate(parts[1:-1], start=1):
        found = None
        path_depth = level
        for j in range(start + 1, end):
            m = KEY_RE.match(lines[j])
            if m and len(m.group(1)) // 2 == path_depth and m.group(2) == part:
                found = j
                break
        if found is None:
            lines.insert(insert_at, "  " * level + f"{part}:\n")
            insert_at += 1
            end += 1
        else:
            # end of this sub-block
            sub_end = end
            for j in range(found + 1, end):
                m = KEY_RE.match(lines[j])
                if m and len(m.group(1)) // 2 <= path_depth:
                    sub_end = j
                    break
            insert_at = sub_end
        depth = level + 1
    pad = "  " * depth
    comment_part = f"  # {comment}" if comment else ""
    lines.insert(insert_at, f"{pad}{parts[-1]}: {format_value(value)}{comment_part}\n")


def replace_key(lines, existing_keys, dotted, value, comment):
    idx, _ = existing_keys[dotted]
    m = KEY_RE.match(lines[idx])
    indent, name, _ = m.groups()
    comment_part = f"  # {comment}" if comment else ""
    lines[idx] = f"{indent}{name}: {format_value(value)}{comment_part}\n"


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("report", "merge"):
        fail("usage: merge-tokens.py report|merge <tokens.yaml> [--template <path>] "
             "[--precedence existing|incoming] [--resolve section.key=incoming ...]")
    mode, target = sys.argv[1], sys.argv[2]
    if not os.path.isfile(target):
        fail(f"no such file: {target} (merge mode is only for a PRE-EXISTING tokens.yaml; "
             "creation uses the normal template path)")

    template = None
    precedence = "existing"
    resolves = []
    args = sys.argv[3:]
    i = 0
    while i < len(args):
        if args[i] == "--template":
            template = args[i + 1]; i += 2
        elif args[i] == "--precedence":
            precedence = args[i + 1]; i += 2
        elif args[i] == "--resolve":
            resolves.append(args[i + 1]); i += 2
        else:
            fail(f"unknown argument: {args[i]}")
    if precedence not in ("existing", "incoming"):
        fail(f"--precedence must be existing|incoming, got {precedence!r}")

    incoming = parse_stdin(sys.stdin.read())

    with open(target) as f:
        lines = f.readlines()
    existing_keys = parse_file(lines)
    conflicts, news, sames = classify(existing_keys, incoming)

    if mode == "report":
        for dotted, evalue, ivalue in conflicts:
            print(f'CONFLICT {dotted}: existing "{norm(evalue)}" vs incoming "{norm(ivalue)}"')
        for dotted, value, _ in news:
            print(f'NEW {dotted}: "{norm(value)}"')
        for dotted, value in sames:
            print(f'SAME {dotted}: "{norm(value)}"')
        return

    # --- merge mode ---
    if template is None or not os.path.isfile(template):
        fail("merge requires --template <path to templates/craft/design/tokens.yaml>")
    tsections = template_sections(template)

    for dotted, _, _ in incoming:
        if dotted.split(".")[0] not in tsections:
            fail(f"schema: {dotted!r} - section {dotted.split('.')[0]!r} is not defined "
                 f"in the template; keys must live under a template section")

    conflict_keys = {d for d, _, _ in conflicts}
    resolved = set()
    for r in resolves:
        key, _, choice = r.partition("=")
        if choice != "incoming":
            fail(f"--resolve only supports '=incoming' (keeping existing needs no flag): {r!r}")
        if key not in conflict_keys:
            fail(f"--resolve {key!r} is not in the derived conflict set "
                 f"{sorted(conflict_keys)} - a resolve must match a real conflict")
        resolved.add(key)

    snapshot = os.path.join(os.path.dirname(os.path.abspath(target)), ".tokens-premerge")
    shutil.copy2(target, snapshot)
    pre_lines = list(lines)
    pre_keys = dict(existing_keys)

    incoming_by_key = {d: (v, c) for d, v, c in incoming}
    replaced = set()
    for dotted, _, ivalue in conflicts:
        if precedence == "incoming" or dotted in resolved:
            value, comment = incoming_by_key[dotted]
            replace_key(lines, existing_keys, dotted, value, comment)
            replaced.add(dotted)
    for dotted, value, comment in news:
        insert_key(lines, dotted, value, comment)

    # backfill: template sections entirely absent get the template block, minus
    # any {{...}} placeholder lines - a placeholder never lands in a merged file
    present_sections = {k.split(".")[0] for k in parse_file(lines)}
    top_level = [KEY_RE.match(l).group(2) for l in lines
                 if KEY_RE.match(l) and KEY_RE.match(l).group(1) == ""]
    backfilled = []
    for section, block in tsections.items():
        if section in present_sections or section in top_level:
            continue
        lines.append("\n")
        lines.append(f"# {section}: template defaults (backfilled by merge - not earned values)\n")
        lines.extend(l for l in block if "{{" not in l)
        backfilled.append(section)

    with open(target, "w") as f:
        f.writelines(lines)

    # --- self-verify: recompute from disk; restore + hard-fail on any violation ---
    def verify():
        with open(target) as f:
            post_lines = f.readlines()
        post_keys = parse_file(post_lines)
        for dotted, (_, evalue) in pre_keys.items():
            if dotted not in post_keys:
                return f"pre-existing key {dotted} missing after merge"
            expected = incoming_by_key[dotted][0] if dotted in replaced else evalue
            if norm(post_keys[dotted][1]) != norm(expected):
                return f"key {dotted}: expected {norm(expected)!r}, found {norm(post_keys[dotted][1])!r}"
        replaced_lines = {pre_keys[d][0] for d in replaced}
        post_set = set(post_lines)
        for idx, line in enumerate(pre_lines):
            if idx in replaced_lines or not line.strip():
                continue
            if line not in post_set:
                return f"pre-existing line altered or lost: {line.strip()!r}"
        for section in tsections:
            if section not in {k.split('.')[0] for k in post_keys}:
                return f"template section {section!r} absent after backfill"
        for line in post_lines:
            if "{{" in line:
                return f"placeholder survived: {line.strip()!r}"
        return None

    violation = verify()
    if violation:
        shutil.copy2(snapshot, target)
        fail(f"self-verify FAILED ({violation}) - original file restored from "
             f"{snapshot}; nothing was merged. Fix the input; do NOT retry with the "
             f"Write tool.", code=2)

    kept = len(pre_keys) - len(replaced)
    print(f"merged: {kept} kept, {len(news)} added, {len(replaced)} replaced "
          f"({precedence} precedence), {len(backfilled)} sections backfilled "
          f"({', '.join(backfilled) if backfilled else 'none'})")


if __name__ == "__main__":
    main()
