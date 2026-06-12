story: fixture-story-with-failed-tests
# Story-Final Validation Report

| Check | Result | Details |
|-------|--------|---------|
| TypeScript Strict | PASS | no errors |
| Lint | PASS | clean |
| No Any Types | PASS | none found |
| Build | PASS | compiled |
| Tests + Coverage | FAIL | 2 of 14 tests failing: rendering.test.ts (assertion mismatch), totals.test.ts (timeout) |
| Design Tokens | PASS | compliant |

## Errors

- rendering.test.ts: expected "Saved" label, received "Transcripts"
- totals.test.ts: timed out after 5000ms waiting for recalculation
