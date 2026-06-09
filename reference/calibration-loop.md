# The calibration loop (optometrist flip test)

A reusable technique for extracting a tacit "I know it when I see it" boundary
into an encodable rule - when the user cannot state the rule but can judge
instances. Any skill that needs to pin down a fuzzy threshold, taste boundary,
or classification line can run this loop.

The name comes from the optometrist's "better one, or better two?" - you cannot
describe your own prescription, but you can reliably judge one lens against
another, and a few well-chosen comparisons converge on the exact correction.

## When to reach for it

Use it when ALL of these hold:

- There is a boundary, threshold, or category line that matters (what counts as
  X, when to do Y, where A becomes B).
- The user cannot articulate the rule directly - asking "what's your rule?"
  produces a shrug, a "it depends," or a rule that they immediately contradict
  with their next example.
- The user CAN judge a concrete instance instantly - shown a specific case, they
  know which side it falls on.

Do NOT use it when the user can just state the rule, or when the boundary does
not actually matter to the work in front of you. The loop is for tacit
knowledge, not for decisions the user is happy to make explicitly.

## The 4-step mechanic

Run this loop, one pass per instance, until the principle stabilizes:

1. **One concrete instance per AskUserQuestion - never batched.** Present a
   single, specific, real case and ask for a verdict on just that one. Batching
   multiple cases into one question muddies the signal: the user averages across
   them instead of judging each cleanly, and you lose which case moved them.

2. **A fixed, low-dimensional verdict: yes / no / unsure.** Keep the answer
   space tiny and constant across every probe. The discriminating power comes
   from WHICH cases get which verdict, not from rich per-case commentary. (When
   the running skill has a recommendation for a case, the AUQ options may carry
   it - label the recommended option "... (Recommended)" first - but the verdict
   primitive stays yes/no/unsure.)

3. **Extract and STATE the inferred principle after each verdict.** Do not just
   record "case 4 = yes." Say out loud the rule you now believe ("so it sounds
   like the line is: durable facts qualify, transient incidents don't"). This
   lets the user correct your INFERENCE, not just the instance - which is where
   the real boundary surfaces. A silently-updated rule never gets challenged.

4. **Adaptive next-probe selection.** Choose the next instance to attack an
   unexplored seam of the boundary, not at random. After a clear "yes" and a
   clear "no," the informative next case is the one that sits between them, or
   that tests a dimension you have not probed yet (social vs. technical, durable
   vs. expiring, mine-to-know vs. already-known). You are the experimenter
   picking the most informative next sample.

## Meta-signals

- **The "unsure" option going unused is itself signal.** If every case resolves
  cleanly to yes or no and "unsure" never fires, the boundary is sharp enough to
  encode - that is the green light to write the rule down. If "unsure" keeps
  firing, the boundary is genuinely fuzzy there; either it needs a sub-rule or
  the category itself is contested.
- **Stop when the principle stabilizes.** When new probes stop moving the stated
  rule - you predict the user's verdict correctly two or three cases running -
  the loop is done. Further cases just confirm; they don't refine.
- **A revised verdict is a gift, not a setback.** When the user flips or nuances
  a verdict mid-loop ("actually, no - that one's different because..."), they
  just handed you a hidden dimension of the boundary. That is the loop working,
  not failing.

## Worked example (condensed)

Pinning the boundary for what counts as a durable "note" worth capturing, run as
a 7-case loop. Each row is one AUQ; the verdict is the user's, the principle is
what got stated and confirmed after it:

| # | Instance | Verdict | Principle it sharpened |
|---|----------|---------|------------------------|
| 1 | Shared staging DB + destructive seed script | yes | durable infra fact + danger payload qualifies |
| 2 | "CI went red, bad migration, reverting it" | no | a transient incident is not a fact (only a reusable technique would be) |
| 3 | Recovered a commit via `git reflog` | no | general knowledge the assistant already holds disqualifies |
| 4 | "Sarah owns billing - loop her in first" | yes | social / ownership facts qualify, not just technical |
| 5 | "We've been drifting toward Tailwind, unofficial" | no | an undecided lean is not a settled fact |
| 6 | Node-20 requirement, buried in unread CONTRIBUTING.md | yes | documented-in-repo does NOT disqualify; only already-known does |
| 7 | "Legacy auth until ~Q3, no owner" | no (don't offer) | provisional / vague-expiry sits below the proactive bar |

Three filters fell out and held across all seven: **durable vs. transient**,
**local vs. already-known**, **settled vs. undecided**. "Unsure" never fired -
the signal that the boundary was sharp enough to write into a rule.

## Also useful for

This is a general technique, not a riff-internal detail. Reach for it in any
skill that has to pin a tacit boundary: **content-spark** (which content
dimensions are assumed vs. resolved), **design-vibe** (what the aesthetic is and
isn't), **lock-decision** (where a project-wide standard's edges are), and
**plan-chunks** (what belongs in scope vs. deferred). A skill running this loop
points here rather than re-documenting the mechanic.
