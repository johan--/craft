#!/bin/bash
# observations-cluster.sh - Cluster the unread observation basket for a cycle.
#
# Usage: observations-cluster.sh <cycle-dir>
#
# Reads all <cycle-dir>/.observations/*.yaml, considers only UNREAD entries
# (surfaced: false), dedups by `loc` (file:line) - keeping the first-seen entry and
# preferring a `confirmed` grade over `suspicion` on conflict - then groups the
# survivors into clusters by shared file path (one cluster per file, entries ordered by
# line number within).
#
# Output (stdout), deterministic - same basket yields byte-identical output every run:
#   CLUSTER=<file> (<count>)
#     <file:line> [<grade>/<severity>] <desc>
#     ...
#   <blank line between clusters>
#
# Clustering is pure-compute proximity grouping - NO model summarization (that would be
# non-reproducible and untestable). Emits nothing when there are no unread entries.

CYCLE_DIR="${1:-}"
[ -n "$CYCLE_DIR" ] || exit 0

OBS_DIR="$CYCLE_DIR/.observations"
[ -d "$OBS_DIR" ] || exit 0

python3 - "$OBS_DIR" <<'PYEOF' || true
import sys, os, re, json, glob

obs_dir = sys.argv[1]
GRADE_RANK = {'confirmed': 2, 'suspicion': 1}

def fields(block):
    rec = {}
    for ln in block:
        m = re.match(r'^\s*-?\s*([A-Za-z_]+):\s*(.*\S)\s*$', ln)
        if not m:
            continue
        k, v = m.group(1), m.group(2).strip()
        try:
            v = json.loads(v)
        except Exception:
            v = v.strip('"').strip("'")
        rec[k] = v
    return rec

# Collect unread entries, deduped by loc (sorted file order -> deterministic first-seen).
entries = {}
for path in sorted(glob.glob(os.path.join(obs_dir, '*.yaml'))):
    try:
        with open(path) as f:
            lines = f.readlines()
    except Exception:
        continue
    blocks, cur = [], None
    for ln in lines:
        if re.match(r'^\s*-\s', ln):
            if cur is not None:
                blocks.append(cur)
            cur = [ln]
        elif cur is not None:
            cur.append(ln)
    if cur is not None:
        blocks.append(cur)
    for block in blocks:
        rec = fields(block)
        loc = rec.get('loc')
        if not loc or rec.get('surfaced') is not False:
            continue
        if loc in entries:
            if GRADE_RANK.get(rec.get('grade'), 0) > GRADE_RANK.get(entries[loc].get('grade'), 0):
                entries[loc] = rec  # prefer confirmed over suspicion
        else:
            entries[loc] = rec

if not entries:
    sys.exit(0)

def file_of(loc):
    return loc.rsplit(':', 1)[0]

def line_of(loc):
    parts = loc.rsplit(':', 1)
    try:
        return int(parts[1])
    except Exception:
        return 0

clusters = {}
for loc, rec in entries.items():
    clusters.setdefault(file_of(loc), []).append(rec)

for f in sorted(clusters):
    recs = sorted(clusters[f], key=lambda r: (line_of(r['loc']), r['loc']))
    print(f'CLUSTER={f} ({len(recs)})')
    for r in recs:
        print(f"  {r['loc']} [{r.get('grade','?')}/{r.get('severity','?')}] {r.get('desc','')}")
    print('')
PYEOF

exit 0
