# Research Branch Template

> The I/O contract for `/craft:research`. Haiku **researcher** agents produce branch files in this exact format. The sonnet **research-synthesizer** agent consumes them to write `_plan.md` and `_sources.md`. Both agents read this file - it is the single source of truth for the schema.

This template is the factual-extraction sibling of `agents/become-researcher.md`'s psychological-material template. Same discipline (verifiable instructions, hard gates, contradictions preserved verbatim), different payload (facts with sources, not beliefs with quotes).

## Producer Rules (the researcher fills this; the researcher does NOT synthesize)

The researcher's job is **extraction only**. The synthesizer ranks, finds convergence, writes the TL;DR, and builds the citation index. A researcher that ranks, summarizes across findings, or writes an executive summary is doing the synthesizer's job and breaking the contract.

1. **Every finding requires an exact verbatim quote AND a URL.** Not a paraphrase. The literal words from the source, in quotation marks, plus the source it came from. You cannot fabricate both convincingly, so this is the anti-hallucination gate. If you cannot produce a verbatim quote for a claim, you have not verified it - drop it or mark it `INSUFFICIENT_EVIDENCE`.

2. **A finding clears the evidence gate if it has EITHER (a) 2+ independent sources, OR (b) 1 authoritative primary source.** Otherwise it is marked `INSUFFICIENT_EVIDENCE`. Not `LOW`, not `MEDIUM` - there is no confidence ladder. This replaces the old HIGH/MEDIUM/LOW labels entirely. Honesty about thin evidence beats a fabricated second source - if you only found one secondary source, mark it `INSUFFICIENT_EVIDENCE`; do not invent a second to clear the gate.

   - **Primary source** (one is enough): official documentation, source code, an RFC or spec, an API reference, or a local test you ran yourself. These are the authority, not a report of the authority.
   - **Secondary source** (need 2+, and they must be independent): blogs, articles, tutorials, community posts, news. These report on the primary; one alone can be wrong or echo a rumor.
   - **Independence:** two sources that trace to the same origin count as ONE (e.g. two blog posts both citing the same tweet). Independent means they arrived at the claim separately - e.g. official docs + your own local test, or two practitioners who tested independently.

3. **Do NOT rank findings.** Finding order is arbitrary (use numbers only as labels for cross-reference). Do not write "the most important finding is..." or order by significance. The synthesizer decides what matters by looking across all branches. State this explicitly so a downstream reader does not mistake order for priority.

4. **Do NOT write a TL;DR, executive summary, or "Open Questions" section.** Those are cross-branch synthesis - the synthesizer's job. A one-line neutral scope statement of what this branch covers is allowed; a synthesized takeaway is not.

5. **Conflicts are data. Preserve them verbatim. Do NOT reconcile.** If two sources disagree, record both positions with their quotes, side by side. Do not add "however," "but," or "the better view is" - the entry ends at the contradiction. (Same rule as `agents/crystallizer.md` and `agents/become-researcher.md`.) Conflicts go in the dedicated `## Conflicts` section, NOT buried in finding prose.

6. **Per-finding source references use S-prefixed IDs (`[S1]`, `[S2]`) that map to the `## Sources` list.** This is the mechanical link the synthesizer reads to build `_sources.md`'s "Claims Supported" column. Every finding's `Sources:` line must reference IDs that exist in the Sources list. Without this, the synthesizer would have to *infer* which source backs which claim - which is the forbidden tidying.

## Branch File Format

Write your findings to the provided file path using this EXACT format:

```markdown
---
branch: "{branch name}"
question: "{your assigned sub-question}"
sources_consulted: {total sources you looked at}
sources_cited: {sources that made it into the report}
conflicts_found: {count of conflicting claims in the Conflicts section}
insufficient_evidence_count: {count of findings marked INSUFFICIENT_EVIDENCE}
status: complete
---

# {Branch Name}

> Part of [{Topic}](_plan.md) | [All Sources](_sources.md)

> **Scope:** One neutral sentence on what sub-question this branch covers. NOT a takeaway, NOT a TL;DR.

## Findings

*Order is arbitrary - numbers are labels for cross-reference, not priority. The synthesizer ranks.*

### Finding 1: {the claim, stated plainly}
{Factual detail. What the source actually says. No editorializing about importance.}
**Quote:** "{exact verbatim words from the source - literal, in quotes}"
**Sources:** [S1][S2]

### Finding 2: {claim}
{detail}
**Quote:** "{exact verbatim quote}"
**Sources:** [S3]
**INSUFFICIENT_EVIDENCE** - only one secondary source (a blog), no primary source and no independent corroboration.

### Finding 3: {claim}
...

(Continue for all findings. Do not filter by importance - include everything you found
with a verbatim quote. Mark INSUFFICIENT_EVIDENCE any finding that has neither 2+
independent sources nor a single authoritative primary source. Do not rank.)

## Conflicts

*Where sources disagree. Record both positions verbatim. Do NOT reconcile, do NOT add "however" or "but" - the entry ends at the contradiction.*

- [Position A: "{exact quote}"] vs [Position B: "{exact quote}"]
  Sources: A = [S1], B = [S4]

(If no conflicts found, write "No conflicts detected across sources.")

## Sources

*S-prefixed IDs. Every finding's Sources: line references these. The synthesizer reads
the "Claims supported" field to build _sources.md mechanically.*

- **S1** [Title](url) - {type: docs | academic | blog | community | corporate | local} - Claims supported: Finding 1
- **S2** [Title](url) - {type} - Claims supported: Finding 1
- **S3** [Title](url) - {type} - Claims supported: Finding 2
- **S4** [Title](url) - {type} - Claims supported: Conflict (Position B)
...
```

## Summary Format (returned to orchestrator)

After writing the file, return ONLY this lightweight summary (~150 tokens) - NOT the full content:

```
BRANCH: {branch name}
FILE: {file path you wrote to}
SOURCES: {count consulted} consulted, {count cited} cited
FINDINGS: {count} ({count} marked INSUFFICIENT_EVIDENCE)
CONFLICTS: {count or "none"}
```

The orchestrator and synthesizer read your file directly for detail. Do not return findings prose.

## Consumer Notes (for the research-synthesizer)

When the synthesizer reads a folder of these branch files:

- **Ranking, convergence, TL;DR, open questions** are all the synthesizer's to produce - they are deliberately absent from branch files.
- **`_sources.md` "Claims Supported" column** is built mechanically from each finding's `**Sources:** [S#]` line cross-referenced against the `## Sources` list's "Claims supported" field. If a finding lacks a `Sources:` line, treat the branch file as malformed (manifest failure) - do not guess which source backs the claim.
- **`INSUFFICIENT_EVIDENCE` findings** are surfaced as low-confidence in `_plan.md`, never promoted to convergence or high-confidence. The synthesizer also **re-enforces the gate** rather than trusting the producer's tags: haiku researchers reliably clear the gate for primary sources but under-tag single-secondary-source findings, so the synthesizer re-counts each finding's sources and tags any single-secondary-source finding `INSUFFICIENT_EVIDENCE` even if the researcher missed it.
- **Conflicts** in the `## Conflicts` section are preserved verbatim in `_plan.md`. Additionally, scan finding prose for hedge language ("however," "but," "some sources say," "others argue," "in contrast") and treat it as an undeclared conflict even if the Conflicts section is empty - producers drift over time and bury conflicts in prose.
- **Quote-claim alignment:** for each finding, check that the verbatim quote actually supports the stated claim. A real quote attached to an unsupported claim is fabricated inference - flag or demote it, do not promote it.
