# Spark Extraction Guide

How to extract concrete requirements from a story's Spark prose. These requirements become the constraints that chunks must fulfill.

---

## Method

The Spark is 2-3 sentences of freeform prose. Pull out the distinct outcomes or behaviors it describes — not every word, but every intent. Ask: "If this requirement isn't addressed, did we actually deliver the story?"

---

## Worked Examples

**Example 1:**
> Spark: "The discovery page filter labels are misleading — 'Transcripts/Videos' actually filters by in-bank status. Rename to 'Saved/Not Saved' on Discovery, and add a real content type filter on Knowledge Bank."

Requirements:
1. Discovery filter renamed from "Transcripts/Videos" to "Saved/Not Saved"
2. Knowledge Bank gets a content type filter for Videos vs Transcripts

**Example 2:**
> Spark: "The agent never offers implementation during story creation. Story-new mode is purely creative — no code suggestions, no implementation planning."

Requirements:
1. Agent does not offer implementation during story creation
2. Story-new mode is creative-only
