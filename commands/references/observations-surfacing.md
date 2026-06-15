# Observations Surfacing & Routing (orchestrator-inline routine)

The orchestrator **Reads this file and runs it inline** at a human-step-in moment - story-complete or cycle-complete in an attended session. It surfaces the unread implementer-observation basket, lets the user route each cluster, and only then marks the acted-on entries surfaced.

This is a Read-inline reference, NOT a skill - invoking it via the Skill tool would break the chain back to the caller (see `.claude/rules/skill-invocation-chain-breaks.md`).

## Preconditions

- **Attended session only.** When `RUN_MODE=autonomous`, this routine does NOT run at all - observations are left in their sidecars (`surfaced: false`) and accumulate until a human steps in. The caller (`craft-story-implement.md` Step 5.9a) gates this behind a `RUN_MODE != autonomous` check. Never surface, route, or create a todo unattended.
- Set `CYCLE_DIR` to the active cycle dir: `${CRAFT_PROJECT_ROOT:-.}/.craft/cycles/$ACTIVE_CYCLE`.

## Step 1 - Compute the count (digest header)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/observations-count.sh "$CYCLE_DIR"
```

If it prints nothing, the basket is empty - **say nothing and return.** Otherwise hold the `N unread / M stories` string as the digest header.

## Step 2 - Cluster the basket

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/observations-cluster.sh "$CYCLE_DIR"
```

Output is deterministic, one block per cluster:

```
CLUSTER=<file> (<count>)
  <file:line> [<grade>/<severity>] <desc>
  ...
```

## Step 3 - Present a PROSE digest (NOT an AskUserQuestion)

This is a read-only surface - it ends in prose, never an AUQ that hides the data behind options (the craft-status lesson). Lead with the count header, then one line per cluster.

**The per-cluster recommendation is PINNED to ONE LINE = lean + short reason. NEVER a paragraph.** This keeps the digest compact by construction - an underspecified "recommendation" is where verbosity creeps in over time.

Format - one line per cluster:

```
<cluster-name> (<count>): <lean> - <short reason>
```

Worked example digest:

```
14 unread / 5 stories. Themes:

error-handling (5): story lean - confirmed gaps in a seam already under test
config-parsing (3): notebook lean - modest drift, no urgency
auth/session.ts (2): in-cycle story lean - a confirmed data-loss risk, fix this cycle
naming-drift (2): dismiss lean - cosmetic, not worth a ticket
date-math (2): circle-back lean - real but you're mid-hotfix
```

One line per cluster. Do NOT expand into prose blocks. (A future fast-follow may show headers-only first and expand on drill-in; not built yet.)

## Step 4 - Route each cluster (user chooses; you may recommend, never auto-write)

Offer the five outcomes per cluster. The orchestrator MAY recommend with the one-line reason above, but **never acts without an explicit user choice** (Nielsen user-control).

| Outcome | What it does |
|---------|--------------|
| **notebook todo** (defer) | Capture as a notebook todo - an observation -> notebook IS a notebook capture. |
| **backlog story** (later) | Pre-fill a story-new spark seed from the cluster, lands in backlog. |
| **in-cycle story** (urgent) | Same, placed into the active cycle now. |
| **circle back / not now** | Acknowledge + park (see Step 5b). Clears the count AND writes one durable rollup todo. |
| **dismiss** | Drop it - clears the count, writes nothing durable. |

### 4a - notebook todo

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/notebook-capture.sh todo "<cluster desc with file:line refs>" --source="observations - {date}"
```

### 4b - backlog / in-cycle story

Invoke `/craft:craft-story-new` with the cluster's observations pre-filled as the spark seed (exactly as notebook graduate pre-fills a spark). For in-cycle, assign it to the active cycle after creation.

## Step 5 - Apply the routing, THEN mark surfaced

**Order matters.** Execute the user's chosen destinations first. Then, as the LAST action, mark the acted-on entries surfaced:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/mark-observations-surfaced.sh "$CYCLE_DIR/.observations/<story-name>.yaml" <file:line> [<file:line> ...]
```

mark-surfaced runs **LAST, only after the user has acknowledged and routed** - never before presenting. Marking before presenting would lose the signal forever on a mid-routing crash; marking after acknowledgment re-presents the digest at worst. mark-surfaced is idempotent and best-effort, so a missing key or a re-run is harmless.

Pass each story's own sidecar path with the locs that belong to it. A loc's story is the entry's `story` field; group locs by sidecar before calling.

### 5b - Circle back (the consolidated rollup)

For every observation the user routed to **circle back**, write EXACTLY ONE notebook todo carrying all their `file:line` refs - never N separate todos:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/notebook-capture.sh todo \
  "circle back to these: <file:line> - <desc>; <file:line> - <desc>; ..." \
  --source="observations rollup - {date}"
```

Then mark all those circle-back entries surfaced (Step 5). Dismiss does the same surfaced-flip but writes no todo.

The obligation moves, it is not dropped: the watermark count stops nagging, and the rollup todo - fattening across cycles in the notebook where the user actually looks - becomes a better drift signal than an injected number.
