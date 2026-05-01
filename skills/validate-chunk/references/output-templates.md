# Validation Output Templates

These templates show the output format from the validate-chunk skill when it wraps the chunk-validator agent.

## Table of Contents
- [Per-Chunk Passed](#per-chunk-passed)
- [Per-Chunk Partial (Warnings)](#per-chunk-partial-warnings)
- [Per-Chunk Passed (Final Chunk)](#per-chunk-passed-final-chunk)
- [Story-Final Passed](#story-final-passed)
- [Validation Failed](#validation-failed)
- [Validation Failed (Final Chunk Escalation)](#validation-failed-final-chunk-escalation)

---

## Per-Chunk Passed
```
## Validation: PASSED — Chunk 2/4: API routes

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | PASS |
| No Any Types | PASS |
| Build | SKIP |
| Tests + Coverage | SKIP |
| Design Tokens | SKIP |

>>> NEXT ACTION: NOW continue with Step 4 implementation loop in craft-story-implement. Invoke checkpoint, then implementer agent for chunk 3/4, then validate-chunk. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```

---

## Per-Chunk Partial (Warnings)
```
## Validation: PASSED (warnings) — Chunk 2/4: API routes

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | WARN |
| No Any Types | WARN |
| Build | SKIP |
| Tests + Coverage | SKIP |
| Design Tokens | WARN |

Warnings (non-blocking, enforced on final chunk):
- **Check:** Lint | **Type:** lint-warning | **File:** src/api/routes.ts | **Line:** 12 | **Message:** Unexpected any value
- **Check:** No Any Types | **Type:** any-type-warning | **File:** src/api/routes.ts | **Line:** 8 | **Message:** any type found: handler(req: any)
- **Check:** Design Tokens | **Type:** token-warning | **File:** src/components/Card.tsx | **Line:** 5 | **Message:** Hex color values found — consider using design tokens

>>> NEXT ACTION: NOW continue with Step 4 implementation loop in craft-story-implement. Invoke checkpoint, then implementer agent for chunk 3/4, then validate-chunk. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```

---

## Per-Chunk Passed (Final Chunk)
```
## Validation: PASSED — Chunk 4/4: Final polish (FINAL CHUNK)

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | PASS |
| No Any Types | PASS |
| Build | SKIP |
| Tests + Coverage | SKIP |
| Design Tokens | PASS |

>>> NEXT ACTION: All chunks validated. NOW proceed to Step 5: Story Completion in craft-story-implement. Invoke story-final validation. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```

---

## Story-Final Passed
```
## Validation: PASSED (story-final)

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | PASS |
| No Any Types | SKIP |
| Build | PASS |
| Tests + Coverage | PASS |
| Design Tokens | SKIP |

>>> NEXT ACTION: Story-final validation complete. NOW continue Step 5 in craft-story-implement: Self-Critique, then Usage Summary, then complete-story.sh. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```

---

## Validation Failed
```
## Validation: FAILED — Chunk 2/4: API routes

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | PASS |
| No Any Types | PASS |
| Build | PASS |
| Tests + Coverage | FAIL |
| Design Tokens | SKIP |

Routing: test-failure → invoking test-fix

>>> NEXT ACTION: NOW invoke test-fix. After it returns, re-validate this chunk. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```

---

## Validation Failed (Final Chunk Escalation)
```
## Validation: FAILED — Chunk 4/4: Final polish

| Check | Result |
|-------|--------|
| TypeScript Strict | PASS |
| Lint | FAIL |
| No Any Types | FAIL |
| Build | PASS |
| Tests + Coverage | PASS |
| Design Tokens | WARN |

Routing: lint-error, type-error → invoking refine-chunk

>>> NEXT ACTION: NOW invoke refine-chunk. After it returns, re-validate this chunk. IMMEDIATELY EXECUTE THIS — DO NOT STOP.
```
