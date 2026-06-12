# Acceptance Pre-Flight Guide

How to symbolically walk each acceptance vehicle through the rule or code path it exercises - using the test's own data shape - and emit the receipt table the orchestrator gates on at triage.

---

## Why this exists

Plans verify by type-truth while test data lies about data-truth. An acceptance test can name a real function, satisfy every type, and still be structurally unreachable: the data the test constructs cannot produce the outcome the test asserts. That escape is invisible at plan time and expensive at acceptance time - it surfaces mid-acceptance, after the full setup/teardown cycle, when the assertion fails for a structural reason no implementation could have fixed.

The pre-flight catches it before the plan is accepted. It is the third member of the reality-grounding family, beside the do-nothing walk and reader tracing.

---

## The Walk (per acceptance vehicle)

An acceptance vehicle is any test or check named in the plan's `## Acceptance` section. For each one:

1. **Identify the path** - name the rule, function, or gate the test actually exercises (the thing that computes the asserted outcome, not the file it lives in).
2. **Instantiate the test's own data shape** - the literal fixture, seed values, or inputs the test constructs. Not the idealized type. Not "a valid order" - THE order this test builds.
3. **Trace** that data through the path, step by step, to the asserted outcome.
4. **Ask: is the asserted outcome constructible from that data?** If any step requires a value, key, or branch the test's data cannot produce, the vehicle is UNREACHABLE - record the step that breaks.

The walk is symbolic: you are reading code and data shapes, not executing anything.

---

## Verdicts

| Verdict | Meaning |
|---------|---------|
| `reachable` | The asserted outcome is constructible from the test's own data - the trace completes. |
| `UNREACHABLE - <reason>` | Some step in the trace cannot be satisfied by the test's data. Name the breaking step. The plan is not ready to finalize - fix the vehicle (its data or its assertion) or the plan. |
| `reachable - by construction` | Docs-only exempt row (see below). |

---

## Receipt format (exact)

The plan must emit a `## Acceptance Pre-Flight` section, placed directly after `## Acceptance`, containing one table row per acceptance vehicle:

```markdown
## Acceptance Pre-Flight

| Acceptance vehicle | Walk | Verdict |
|--------------------|------|---------|
| "10% discount applies at $100" | order fixture: 2 items totaling $120 -> qualifiesForDiscount(total) -> 120 >= 100 true -> discount branch returns 0.10 | reachable |
| "saved preference is applied to the invoice" | seed writes preference keyed by customerId; renderInvoice looks up by (customerId, region); seeded row has no region -> lookup returns empty | UNREACHABLE - seed and lookup use different key shapes (signature asymmetry) |
| "reference doc describes the new format" | no executable acceptance vehicle | reachable - by construction |
```

The orchestrator's structural check greps this section: an absent section fails ("section missing from plan"), the section requires at least one row, and any `UNREACHABLE` verdict fails the plan.

---

## Docs-only exempt row

A story qualifies as docs-only when its changes are confined to `.md` files - no new tests, no new agents, no new source files. Such a story has no rule or code path to walk. It satisfies the pre-flight with a single row:

| Acceptance vehicle | Walk | Verdict |
|--------------------|------|---------|
| "doc assertions only" | no executable acceptance vehicle | reachable - by construction |

A triager seeing this row should cross-check it against the chunks' Files entries - if any chunk creates a test, agent, or source file, the exempt row is illegitimate and the vehicles must be walked.

---

## Worked examples

**Reachable.** Acceptance says: "orders of $100 or more get a 10% discount." The test builds an order with two items priced $70 and $50. Walk: the path is `qualifiesForDiscount(order.total)`; the test's data produces `total = 120`; the branch `total >= 100` is satisfiable by 120; the discount computation returns 0.10. The asserted outcome is constructible. Verdict: `reachable`.

**Unreachable (signature asymmetry - the originating failure).** Acceptance says: "a customer's saved invoice preference is applied when the invoice renders." The test seeds a preference row keyed by `customerId`. Walk: the render path looks up preferences by the composite key `(customerId, region)`; the seeded row carries no region; the lookup can never return the seeded preference, regardless of implementation. The asserted outcome is not constructible from this test's data. Verdict: `UNREACHABLE - seed writes by customerId, path reads by (customerId, region)`. Nobody learns this until mid-acceptance unless the walk happens at plan time.

---

## Named failure patterns

- **Signature asymmetry** - the data writer and the path's reader use different key or value shapes; seeded data is invisible to the path under test.
- **Empty by construction** - the fixture builds data whose derived value can never cross the asserted threshold (an order with no items asserting a minimum-total branch).
- **Dead branch** - the asserted outcome lives behind a flag, config, or environment the test never enables.
- **Type-true, data-false** - the fixture satisfies the type but not the invariant the path requires (a status value that is valid per the type union but filtered out by an earlier guard).

When a walk fails, name the pattern in the Verdict's reason if one fits - it tells the planner what kind of fix the vehicle needs.
