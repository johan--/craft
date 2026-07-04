# Adhoc Tweak Flow (reference - read inline by the craft:adhoc shell)

<!-- DO NOT SIMPLIFY THIS SCHEMA. Tweak records are mined by a future graduation
     pass that clusters them (by kind, surface, attempts, verbatim reactions) into
     project-level skills - the way fix records graduate into rules, tweak records
     graduate into taste. Every field below exists to serve that pass. Dropping a
     field or paraphrasing user reactions destroys the signal. -->

This is the TWEAK flavor: nothing is broken - something works as built, and the user wants it different. A different icon, tighter spacing, calmer wording. The gate here is not root-cause confidence ("will it work") but **fit** ("will it fit"). The shell has already classified the request, opened the write gate, and created the close-obligation tasks - this file owns the tweak record, the Fit Check, the attempt loop, and the close-out. Hand back to the shell for each commit and the final gate close.

The word "enhancement" never appears in tweak filenames or frontmatter values - "tweak" is the term, everywhere. This keeps the corpus fully separate from craft:analyze's `enhance-*` proposal records: those are agent-generated ideas; these are user-driven changes with real reactions attached.

## Step 1: Create the Tweak Record

**Check for a matching move first:** before treating the request as novel, glance at recent records - `grep -l "kind: [matching-kind]" .craft/tweaks/*.md` and skim by `created:` date. If an accepted tweak already made this same move on another surface, this is a REAPPLICATION: set `reapplies:` to that record's name (see below). Reapplied moves inherit a proven direction, and the backlink count is the graduation signal.

Create `.craft/tweaks/` if it doesn't exist, then write the record:

```bash
mkdir -p "${CRAFT_PROJECT_ROOT:-.}/.craft/tweaks"
```

Write to `.craft/tweaks/tweak-[descriptive-slug].md`:

```markdown
---
name: tweak-[descriptive-slug]
status: open
created: [YYYY-MM-DD]
project: [project name]
surface: [free-text kebab slug for WHERE in the product, e.g. settings-toolbar]
kind: [icon | copy | spacing | color | motion | content]
source_story: [story that built the element, if known]
reapplies: [name of the original tweak this reapplies, e.g. tweak-toolbar-stroke-weight - empty for a novel tweak]
attempts: 0
outcome_note:
files_changed: 0
lines_changed: 0
---

## Request
[The user's ask, close to verbatim. "Different icon than what we added - something more like a hammer"]

## Fit Check
[Filled in Step 2]
```

**`surface`:** before minting a new slug, check the existing records - `grep -h "^surface:" .craft/tweaks/*.md | sort -u` - and reuse a matching slug. Consistent surfaces are what let the future mining pass cluster ("five tweaks on settings-toolbar").

**`kind`:** exactly one of `icon | copy | spacing | color | motion | content`.

**`reapplies`:** backlink to the original tweak when this record applies an already-accepted move to a new surface. Every reapplication gets its OWN record (one file per surface - records never bloat with multi-surface history); the shared `reapplies:` value is what ties the family together. The count of records naming the same original is the graduation vote: a move applied in several places is a standard waiting to be written down (tokens.yaml for value kinds like spacing/color, locked.md via lock-decision for patterns - the graduation pass consumes this).

**`status` lifecycle:** born `open`, stays `open` until the user explicitly closes it - `accepted` (first attempt landed), `revised-then-accepted` (took 2+ attempts), `abandoned` (user dropped it), or `escalated` (became a story/design question). **Validation passing never closes a tweak. Only the user's reaction does.** A later conversational decline also abandons an open record - name it explicitly before writing ("Closing `tweak-settings-icon` as abandoned"), never guess which record the user means when more than one is open.

## Step 2: Fit Check

Before editing anything, answer "will it fit?" - the tweak equivalent of the fix flow's confidence check:

1. **Survey the neighborhood.** What sits next to this element - same row, same toolbar, same card? Read the surrounding component code; for UI, screenshot the surface as it is now (this is also your before-shot - if the shell already took a classification screenshot, reuse it, don't re-take).
2. **Match the visual family.** An icon next to existing icons should mirror their language: stroke vs filled, weight, corner radius, metaphor register. Copy should match the surrounding voice; spacing should follow the established rhythm.
3. **Check the design contracts.** Read `.craft/design/tokens.yaml` and `.craft/design/locked.md` - does the change use existing tokens and respect locked decisions? Also glance at `.craft/quality.yaml`'s standards (touch targets, contrast): if the tweak conflicts with one, say so and proceed anyway - a heads-up, never a blocker.

Write the findings into the `## Fit Check` section: where the element lives, what its siblings look like, which conventions apply, and how the requested change fits them.

**Escalation:** if the fit check surfaces a genuine design question (multiple plausible directions and no clear fit) or the change would break a locked decision - do NOT edit. Update `status: escalated`, tell the user why, and suggest design-vibe or a story. Hand back to the shell to close the gate. (Mention the option; do not invoke another skill from inside this flow.)

## Step 3: The Attempt Loop

Each attempt appends a block to the record:

```markdown
## Attempt [N]
### Change
[What was edited, which files, and how the fit check shaped the choice]
### Validation
[Tests/build result; for visual tweaks, before/after screenshots - the after-shot doubles as the fit-check receipt]
### Reaction
[The user's response, VERBATIM]
```

Per attempt:

1. **Change.** Make the edits with Edit/Write. Increment `attempts`, update `files_changed` / `lines_changed`.
2. **Validate.** Run the project's tests/build. For anything visual, use the browser: navigate to the surface, take the after screenshot, and confirm the change landed as the fit check intended. Record it in the attempt's Validation.
3. **Commit.** Hand back to the shell's commit step (manifest staging, `tweak:` prefix). Every validated attempt commits - the custody chain holds even if the record stays open.
4. **Close-out ask.** Use **AskUserQuestion**:

```
question: "How does it look?"
header: "Tweak"
options:
  - label: "Looks good"
    description: "Close this tweak as accepted"
  - label: "Looks good - apply elsewhere"
    description: "Accept it, then reapply the same move to other surfaces"
  - label: "Not quite"
    description: "Tell me what's off - I'll take another pass"
```

5. **Route the reaction - capture it VERBATIM:**
   - **"Looks good"** (or equivalent typed approval): write it to the attempt's Reaction and to `outcome_note`. Set `status: accepted` (attempt 1) or `revised-then-accepted` (2+). Continue to Step 4.
   - **"Looks good - apply elsewhere":** close THIS record exactly as "Looks good" above (the move proved out - propagation never reopens it), then run Reapplying Elsewhere (Step 3b) inside the same work thread before Step 4.
   - **Typed criticism** ("the alignment is still off"): write the exact words to the attempt's Reaction. Leave `status: open`. Loop to the next attempt - the reaction is the new brief.
   - **Explicit decline** ("never mind", "drop it", "not worth another pass"): write the exact words to the attempt's Reaction and to `outcome_note`. Set `status: abandoned`. Hand back to the shell to close the gate.
   - **No reaction / user changes topic:** leave `status: open` and the record as-is. Do not nag, do not mark accepted. Hand back to the shell to close the gate (the gate closes with the thread; the record's openness is independent bookkeeping). If the user raises it again - this session or any later one - reopen the loop from the recorded reactions.

There is NO lesson-capture step on the tweak path - that belongs to fixes. The record's verbatim reactions ARE the learning payload here.

## Step 3b: Reapplying Elsewhere

The user chose to propagate an accepted move. The original record is already closed; the work thread (gate, task pair) stays open.

1. **Ask where - never scan by default.** "Where else should this land?" The user usually knows ("also the profile cards"). Offer the scan as a visibly priced opt-in in the same breath: "Or I can look for candidates - that means scanning [named scope, e.g. the components directory] for similar [kind] patterns." Run a scan ONLY on explicit acceptance, and scope it by the tweak's kind and surface - grep for the matching pattern, never a whole-project read. An unrequested full-project scan is the failure mode this step exists to prevent.
2. **One record per target.** Each target surface gets its own `tweak-[slug].md` with `reapplies:` set to the original's name. One file per surface - the family tree lives in the backlinks, never in one bloated record.
3. **Abbreviated loop per target:** Fit Check the NEW neighborhood (siblings differ - the move may need local adaptation, and a target where it genuinely doesn't fit gets said out loud, not forced), then run the same per-attempt mechanics as Step 3 on the target's own record: write its `## Attempt 1` block (Change/Validation), increment its `attempts`, update its `files_changed` / `lines_changed`, edit, validate, commit (shell's commit step).
4. **Batched close-out.** ONE "How do they look?" ask for the whole batch, targets named - not one ask per target. The user's reply closes all records it approves (same verbatim reaction in each); a called-out target ("checkout's still off") loops just that record's attempt cycle.
5. When the batch settles, continue to Step 4 - the summary covers the family: original + N reapplications.

## Step 4: Close

Output a summary. For a single tweak:

```
## Adhoc Tweak: [name]
Surface: [surface] | Kind: [kind]
Attempts: [N]
Outcome: [status] - "[outcome_note]"
Files: [N] changed, [N] lines
```

For a reapplication batch, one line per record in the family:

```
## Adhoc Tweak: [original name] + [N] reapplications
- [surface] ([kind]): [status] - "[outcome_note]", [N] files/[N] lines
- [surface] ([kind]): [status] - "[outcome_note]", [N] files/[N] lines
```

Then hand back to the shell to close the gate (Step 6 there).
