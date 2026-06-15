#!/bin/bash
# mark-observations-surfaced.sh - Mark observation entries as surfaced (the clear event).
#
# Usage: mark-observations-surfaced.sh <sidecar-file> <file:line> [<file:line> ...]
#
# Flips `surfaced: false` -> `surfaced: true` on every entry in <sidecar-file> whose
# `loc` (file:line) matches one of the arguments. Pass a whole cluster's (or the whole
# basket's) locs to flip them in one call.
#
# Ordering: the orchestrator runs this LAST, only AFTER the user has acknowledged the
# digest and routed - never before presenting. Marking before presenting would lose the
# signal forever on a mid-routing crash; marking after acknowledgment re-presents the
# digest at worst.
#
# Idempotent: running twice yields the same file (an already-surfaced entry is left
# as-is). Best-effort: a missing sidecar, or a loc that matches no entry, exits 0 with
# no error - a failed mark just means the entry re-surfaces next time.

SIDECAR="$1"
shift 2>/dev/null || true

[ -n "$SIDECAR" ] || exit 0
[ -f "$SIDECAR" ] || exit 0
[ "$#" -gt 0 ] || exit 0

python3 - "$SIDECAR" "$@" <<'PYEOF' || true
import sys, re, json

path = sys.argv[1]
targets = set(sys.argv[2:])

try:
    with open(path) as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)

def loc_of(block):
    for ln in block:
        m = re.match(r'^\s*loc:\s*(.*\S)\s*$', ln)
        if m:
            v = m.group(1).strip()
            try:
                return json.loads(v)
            except Exception:
                return v.strip('"').strip("'")
    return None

# Split into a leading header (e.g. "observations:") plus one block per list entry.
header, blocks, cur = [], [], None
for ln in lines:
    if re.match(r'^\s*-\s', ln):
        if cur is not None:
            blocks.append(cur)
        cur = [ln]
    elif cur is None:
        header.append(ln)
    else:
        cur.append(ln)
if cur is not None:
    blocks.append(cur)

changed = False
for block in blocks:
    if loc_of(block) in targets:
        for i, ln in enumerate(block):
            if re.match(r'^\s*surfaced:\s*false\s*$', ln):
                block[i] = re.sub(r'surfaced:\s*false', 'surfaced: true', ln)
                changed = True

if changed:
    with open(path, 'w') as f:
        f.writelines(header)
        for b in blocks:
            f.writelines(b)
PYEOF

exit 0
