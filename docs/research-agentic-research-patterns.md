# Agentic Research Patterns - Design Research

> **Date:** 2026-04-09
> **Purpose:** Design research for `/craft:research` command
> **Status:** Complete
> **Depth:** 3-agent parallel research (frameworks, formats, depth control)

## TL;DR

The dominant pattern across every major implementation (Anthropic, OpenAI, Perplexity, Stanford STORM, GPT-Researcher) is the same: **Discover → Rank → Elaborate → Synthesize.** One system parameterized by depth - not separate shallow/deep systems. Shallow research is just deep research with aggressive pruning. Output format converges on Markdown + YAML frontmatter with three-tier confidence tagging.

---

## Table of Contents

- [1. Architecture Pattern: Discover-Elaborate](#1-architecture-pattern-discover-elaborate)
- [2. Research Tree Structures](#2-research-tree-structures)
- [3. Depth Control - Shallow to Deep](#3-depth-control---shallow-to-deep)
- [4. Output Document Format](#4-output-document-format)
- [5. Citation and Confidence Patterns](#5-citation-and-confidence-patterns)
- [6. Notable Implementations](#6-notable-implementations)
- [7. Design Recommendations for Craft](#7-design-recommendations-for-craft)
- [Sources](#sources)

---

## 1. Architecture Pattern: Discover-Elaborate

Every major system follows the same four-phase flow - directly maps to the Google search analogy (index results → click to elaborate → related results):

| Phase | What Happens | Budget |
|-------|-------------|--------|
| **Discover** (Scan) | Decompose query into sub-questions. Parallel shallow searches. Titles + snippets. Build topic map. | ~5% |
| **Rank** (Filter) | Score discovered sources against research objective. Identify gaps. Decide which branches get deeper exploration. | ~5% |
| **Elaborate** (Read + Verify) | Spawn focused agents on top-ranked branches. Full document reads. Cross-reference. New findings generate follow-up searches. | ~70% |
| **Synthesize** (Merge) | Aggregate across branches. Resolve contradictions. Structure output with citations. | ~20% |

**Anthropic's own system** uses this exact pattern: Opus orchestrates, Sonnet subagents do the work. Scaling rules embedded in prompts:
- Simple fact-finding = 1 agent, 3-10 tool calls
- Comparisons = 2-4 subagents, 10-15 calls each
- Complex research = 10+ subagents with divided responsibilities
- Result: outperformed single-agent by 90.2%

**Key insight from Anthropic:** Without detailed task boundaries, agents duplicate work or leave gaps. The task boundary definition - telling each subagent exactly what NOT to research - is what prevents redundancy.

---

## 2. Research Tree Structures

Three patterns have emerged, each with trade-offs:

### Pattern A: Question Expansion Tree

The simplest and most common. The orchestrator decomposes the query into sub-questions, which can spawn follow-ups.

```
Original Query
├── Sub-question 1 (technical angle)
│   ├── Follow-up 1a (detail found in phase 1)
│   └── Follow-up 1b (contradiction to resolve)
├── Sub-question 2 (practical angle)
│   └── Follow-up 2a
├── Sub-question 3 (competitive angle)
└── Sub-question 4 (contrarian angle)
```

Used by: GPT-Researcher, LangChain Open Deep Research, most custom implementations.

### Pattern B: Perspective Tree (STORM)

Stanford's STORM doesn't do traditional search-then-synthesize. It simulates an expert roundtable. Perspectives ARE the branches - each expert asks different questions, retrieves different sources.

```
Topic
├── Expert A perspective → questions → sources → findings
├── Expert B perspective → questions → sources → findings
├── Expert C perspective → questions → sources → findings
└── Merge perspectives → outline → article
```

Unique advantage: naturally produces diverse coverage because different "experts" care about different things.

### Pattern C: Research Graph (Graph of Thoughts)

The research tree is evolving into a research graph. Pure tree structures (Tree of Thoughts) are giving way to Graph of Thoughts where branches can **merge**. This matters for synthesis - when two branches discover related but differently-framed information, you need to merge them, not just concatenate.

```
Query → Branch A ──────────┐
      → Branch B ──┐       ├── Merged finding (A+B agree)
                   ├───────┘
      → Branch C ──┘       → Independent finding (C unique)
```

**What determines which branches to explore deeper:**

| Signal | Action |
|--------|--------|
| Multiple sources agree | Branch may need LESS depth (settled) |
| Sources contradict | Go DEEPER (resolve conflict) |
| Coverage gap detected | Spawn new branch |
| Novel info found | Continue deepening |
| Redundant info (>90% overlap) | Prune branch |

---

## 3. Depth Control - Shallow to Deep

### One System, Parameterized by Depth

The cleanest pattern: one pipeline where the depth parameter controls thresholds, pass limits, and verification requirements. NOT separate systems for shallow vs deep.

| Depth | Planning | Passes | Sources | Verification | Output |
|-------|----------|--------|---------|-------------|--------|
| **1 - Quick** | Skip | 1 | 3 | None | 2-3 sentences |
| **2 - Standard** | Auto-decompose | 2 | 10 | Spot-check contradictions | Structured summary |
| **3 - Deep** | Explicit plan | 3 | 25 | Cross-reference key claims | Report with citations |
| **4 - Comprehensive** | Plan + approval | 4+ | 50+ | Systematic, find counterarguments | Full report + confidence |
| **5 - Exhaustive** | Multi-phase plan | Until saturation | Unlimited in budget | Adversarial (try to disprove) | Report + gaps + further questions |

### Adaptive Escalation (Recommended)

Instead of pre-committing to a depth, start shallow and let complexity of findings determine depth:

```
Start at depth 1 (quick scan)
If question is simple + answer clear + sources agree:
  → Return quick answer (stayed shallow)
If question complex OR answer ambiguous OR sources conflict:
  → Escalate to depth 2
  → Repeat assessment
  → Continue escalating until answer stabilizes, budget exhausted, or max depth reached
```

### Saturation Detection

The key signal for "should I go deeper?" is the **novel fact ratio**:

```
after_each_pass:
  new_facts = extract_facts(retrieved_content)
  novel_facts = new_facts - known_facts
  saturation = len(novel_facts) / len(new_facts)

  if saturation < 0.1:   # 90%+ redundant → stop or pivot
  elif saturation < 0.3: # getting thin → narrow scope
  else:                   # still finding new stuff → continue
```

### The Diminishing Returns Curve (Validated)

| Pass | Cumulative Coverage | Marginal Gain |
|------|-------------------|---------------|
| 1 | ~80% of key facts | 80% |
| 2 | ~90% | +10% |
| 3 | ~93% | +3% |
| 4+ | ~95% | <2% |

This maps to the Zipf distribution of information - a few sources contain most important info, additional sources have rapidly decreasing marginal value. After 3 passes, diminishing returns. Self-review is biased (sycophantic) - cross-model verification helps but adds cost.

### Budget Allocation

**Time-boxed with quality gates** (most practical for Craft):
- At 50% of time budget: must have completed scan pass
- At 80%: must begin synthesis regardless of remaining branches
- At 95%: must be writing final output
- Unfinished branches noted as "areas for further investigation"

---

## 4. Output Document Format

### Consensus: Markdown + YAML Frontmatter

Every major system converges on Markdown. Not JSON (too noisy for humans), not pure Markdown (no metadata slot). Markdown is token-efficient, diffable, version-controllable, and readable by both humans and LLMs.

### Recommended Document Structure

```markdown
---
title: "Research Topic"
query: "Original query"
date: 2026-04-09
status: complete         # draft | in-progress | complete | stale
depth_target: 3
depth_reached: 3
confidence: 0.82
sources_consulted: 47
sources_cited: 23
branches_explored: 8
branches_pruned: 4
knowledge_gaps:
  - "What couldn't be found"
search_terms:
  - "term 1"
  - "term 2"
stale_after: 2026-07-09  # when to re-run
---

# Research Topic

> **TL;DR:** 2-3 sentence executive summary.

## Table of Contents
(auto-generated or manually maintained)

## Section 1 (H2 = self-contained knowledge unit)
Content with inline citations [1]. Each H2 section delivers
value independently - reader can stop at any section.

### Subsection 1.1 (H3 = drill-down detail)
Deeper content for those who want it.

## Section 2
More self-contained content.

## Open Questions
- What remains unanswered
- What needs further investigation
- Branches that were pruned and why

## Sources
1. [Source Title](url) - type: academic | corporate | user-generated
2. [Source Title](url) - type: ...
```

### Key Format Decisions

1. **Separate the outline from the article** (STORM's lesson). The research tree should be a first-class artifact, not just implied by headers.
2. **Self-contained sections at H2 level** (Perplexity's lesson). Each section delivers value independently. Drill-down goes to H3/H4.
3. **Metadata captures process, not just results** - search terms used, branches pruned and why, knowledge gaps, sources consulted vs cited.
4. **TL;DR at the top** - front-load the important stuff (newspaper article pattern).

---

## 5. Citation and Confidence Patterns

### Three-Tier Confidence Tagging

The most practical pattern - inline confidence markers with numbered citations:

```markdown
React Server Components reduce bundle size significantly.
[HIGH] [1][3][7]

Vue's composition API outperforms React hooks in benchmarks.
[CONFLICTING] [2] vs [4]

Svelte 5 runes eliminate the virtual DOM entirely.
[UNVERIFIED] [6]
```

| Tag | Meaning | Rule |
|-----|---------|------|
| `[HIGH]` | 3+ independent sources agree | Stop verifying |
| `[CONFLICTING]` | Sources contradict each other | Investigate further |
| `[UNVERIFIED]` | Only 1 source supports claim | Flag for reader |

### Separated Citation Index (STORM)

For rich citation data, store details in a companion file:

```json
{
  "https://source.com/article": {
    "title": "Article Title",
    "snippets": ["relevant excerpt 1", "relevant excerpt 2"],
    "citation_indices": [1, 4, 7]
  }
}
```

Lets you update citations without touching article text.

---

## 6. Notable Implementations

### Anthropic Multi-Agent Research System
- **Architecture:** Orchestrator (Opus) + worker subagents (Sonnet) in parallel
- **Key insight:** Task boundary definitions prevent duplication. Each subagent gets explicit scope AND explicit "do NOT research" boundaries
- **Performance:** 90.2% improvement over single-agent
- **Subagent OODA loop:** Observe → Orient → Decide → Act
- **Source:** https://www.anthropic.com/engineering/multi-agent-research-system

### OpenAI Deep Research
- **Architecture:** GPT-4o handles intent clarification (cheap), o3 handles research loop (powerful)
- **Pattern:** Clarify → Scope → Iterative search-read-reason loop → Synthesize
- **Key innovation:** Research model can pivot dynamically - not locked to initial plan
- **Source:** https://openai.com/index/introducing-deep-research/

### Stanford STORM
- **Architecture:** Multi-perspective expert roundtable + outline-driven RAG
- **Unique:** Perspectives ARE the branches. Simulates experts with different viewpoints asking different questions
- **Citation quality:** 84.83% recall, 85.18% precision
- **Co-STORM:** Human can participate in the roundtable
- **Source:** https://github.com/stanford-oval/storm

### GPT-Researcher (Open Source)
- **Architecture:** Planner-Executor-Publisher with asyncio parallelization
- **Multi-agent variant:** Chief Editor → Researcher → Reviewer → Reviser → Writer → Publisher
- **Key decision:** Sub-questions designed to be independent for concurrency
- **Source:** https://github.com/assafelovic/gpt-researcher

### Perplexity
- **Architecture:** Two-tier - single-shot (fast) vs multi-step plan-and-execute (deep)
- **Deep Research:** Loop-based. Searches → reads → reasons → refines plan → loops
- **Scale:** 200M daily queries, 200B+ indexed URLs
- **Source:** https://www.perplexity.ai/hub/blog/introducing-perplexity-deep-research

### LangChain Open Deep Research
- **Architecture:** Supervisor on LangGraph. Three phases: Scoping → Research (parallel subagents) → Report (with reflection)
- **Reflection pattern:** Generate → self-critique → refine iteratively
- **Source:** https://github.com/langchain-ai/open_deep_research

---

## 7. Design Recommendations for Craft

Based on everything above, here's what maps cleanly to a `/craft:research` command:

### Architecture: Adaptive Discover-Elaborate

```
User query
  │
  ▼
┌─────────────────────────────┐
│ PHASE 1: DISCOVER (single)  │  One agent, shallow scan
│ - Decompose into sub-Qs     │  3-5 web searches
│ - Skim results              │  Build topic map
│ - Rank by relevance         │  Identify top branches
│ - Output: research plan     │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ PHASE 2: ELABORATE (parallel)│  N agents, deep dive
│ - One agent per branch      │  Full page reads
│ - Cross-reference sources   │  Extract facts + evidence
│ - Saturation detection      │  Stop when < 10% novel
│ - Report findings back      │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ PHASE 3: SYNTHESIZE (single)│  One agent, merge
│ - Combine all branches      │  Resolve contradictions
│ - Structure with TOC        │  Tag confidence levels
│ - Identify gaps             │  Note pruned branches
│ - Write final document      │
└─────────────────────────────┘
```

### Depth as a Parameter

```
/craft:research "query"              → auto-detect depth (start shallow, escalate)
/craft:research "query" --quick      → depth 1: scan only, 30 seconds
/craft:research "query" --deep       → depth 3: full three-phase, 3-5 minutes
/craft:research "query" --exhaustive → depth 5: multi-pass with verification
```

### Output Location

```
.craft/research/
  YYYY-MM-DD-{slug}.md               # Main research document
  YYYY-MM-DD-{slug}.sources.json     # Citation index (optional, for deep+)
```

### Subagent Configuration

- **Discover agent:** Same model as orchestrator (needs judgment for decomposition)
- **Elaborate agents:** Cheaper model (Sonnet/Haiku - doing retrieval + extraction, not strategy)
- **Synthesize agent:** Same model as orchestrator (needs judgment for conflict resolution)
- **All research agents:** Read-only. No file modifications except final output.

### Integration Points with Craft

- Research feeds story creation: `/craft:research` output can be referenced in `/craft:story-new`
- Research feeds design decisions: findings can be locked via `/craft:lock-decision`
- Research feeds `project.md`: technical research updates project DNA
- Stale detection: `stale_after` field triggers "this research may be outdated" warnings

---

## Sources

### Primary (directly consulted by research agents)
1. [Anthropic: Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
2. [OpenAI: Introducing Deep Research](https://openai.com/index/introducing-deep-research/)
3. [Stanford STORM GitHub](https://github.com/stanford-oval/storm)
4. [Stanford STORM Paper](https://arxiv.org/abs/2402.14207)
5. [GPT-Researcher GitHub](https://github.com/assafelovic/gpt-researcher)
6. [Perplexity: Deep Research](https://www.perplexity.ai/hub/blog/introducing-perplexity-deep-research)
7. [Perplexity: AI-First Search API Architecture](https://research.perplexity.ai/articles/architecting-and-evaluating-an-ai-first-search-api)
8. [LangChain: Open Deep Research](https://github.com/langchain-ai/open_deep_research)
9. [SkyworkAI DeepResearchAgent](https://github.com/SkyworkAI/DeepResearchAgent)
10. [Markform - Structured Markdown for Agents](https://github.com/jlevy/markform)
11. [Perplexity Pages](https://www.perplexity.ai/hub/blog/perplexity-pages)

### Academic/Survey Papers
12. [Deep Research Agents: Systematic Examination and Roadmap](https://arxiv.org/abs/2506.18096)
13. [Deep Research: A Systematic Survey](https://arxiv.org/abs/2512.02038)
14. [DeepDive: Knowledge Graphs and Multi-Turn RL](https://arxiv.org/html/2509.10446v1)
15. [From Web Search towards Agentic Deep Research](https://arxiv.org/html/2506.18959v1)

### Industry Analysis
16. [HuggingFace: Deep Research Technology Survey](https://huggingface.co/blog/exploding-gradients/deepresearch-survey)
17. [ByteByteGo: Anthropic Multi-Agent Architecture](https://blog.bytebytego.com/p/how-anthropic-built-a-multi-agent)
18. [LangChain: Perplexity Pro Search Case Study](https://www.langchain.com/breakoutagents/perplexity)
