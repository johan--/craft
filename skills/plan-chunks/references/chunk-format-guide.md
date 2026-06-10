# Chunk Format Guide

This is the required format for all chunk specs produced during Phase 4 (Detailed Chunk Planning). Every chunk must follow this template exactly.

**The standard:** Implementation details must be practically copy-pasteable into code. The implementer agent is fully automated in production — it follows instructions, it doesn't make design decisions. Every decision about HOW to build something is made here during planning, not deferred to implementation.

---

## Required Template

```markdown
### Chunk [N]: [Descriptive Name]

**Goal:** [Specific outcome — not vague]

**Files:**
- `src/components/Feature/Component.tsx` — create
- `src/lib/feature.ts` — modify (add newFunction around line 45)
- `src/hooks/useFeature.ts` — create

**Implementation Details:**
- Import `Card` from `src/components/ui/Card` — use `<Card variant="outlined">` with `{title: string, children: ReactNode}` props
- Data fetching: `useQuery({ queryKey: ['features', id], queryFn: fetchFeature })` — follow pattern in `src/hooks/useStory.ts:12-25`
- Form validation: zod schema with `z.object({ email: z.string().email(), name: z.string().min(3) })`
- Submit: `api.feature.create(data)` returns `Feature` — toast via `useToast()` from `src/hooks/useToast`
- Follow form layout pattern from `src/components/auth/LoginForm.tsx:45-62`

**What Could Break:**
- Card component API — verify `variant` prop exists (researcher found it at `Card.tsx:8`)
- Depends on `api.feature.create()` from Chunk 2

**Done When:**
- [ ] Component renders with all required fields
- [ ] Validation shows inline errors on blur
- [ ] Loading state disables submit button
- [ ] Success clears form and shows toast
- [ ] Error shows toast with message
- [ ] Build passes and all tests pass
```

---

## Implementation Detail Quality Gate

**Before presenting the plan, review every implementation detail against this test:**

> Can the implementer agent translate this bullet into code without making a design decision?

If the answer is no, the detail is too vague. Rewrite it.

**The litmus test for each bullet:**
- Does it specify the EXACT approach (not "regex-based" but which regex pattern and why)?
- Does it specify the EXACT function signatures, return types, and data shapes?
- Does it specify the EXACT order of operations (step 1, step 2, step 3)?
- Does it reference EXACT file paths and line numbers for patterns to follow?
- Could an agent write the code from this bullet alone without guessing?

If a detail describes a *category of work* ("handle edge cases", "parse the data", "extract values") instead of *specific instructions* ("strip CSS comments with `css.replace(/\/\*[\s\S]*?\*\//g, '')` before parsing", "capture property-value pairs with `/(--.+?):\s*(.+?);/g` applied to each :root block"), it's too vague.

---

## Green-Tree Requirement

Every chunk's **Done When** must include at least one criterion asserting the project compiles and all tests pass at the end of the chunk ("Build passes and all tests pass"). Plan validation rejects any chunk whose Done When lacks one.

This is a planning constraint, not a checkbox to append. Cut chunk boundaries so the criterion can actually be true: a rename or symbol removal and every reference to it - including test files, mocks, and fixtures - belong in the same chunk. A plan that defers compilation across a chunk boundary ("do not build between Chunk 1 and Chunk 2") is invalid; merge or re-cut the chunks, or flag the story for splitting.

Exempt: chunks that modify no source files (all Files entries `read-only`, or a Goal that touches only docs).

---

## Bad → Mediocre → Good Examples

### Example: CSS Parser

**BAD (theoretical — describes what, not how):**
```
**Implementation Details:**
- Regex-based extraction: match :root { ... } blocks, then extract --property-name: value; pairs
- Handle edge cases: CSS comments, multi-line shadow values, var() references
- Export: parseCSSCustomProperties(css: string): Record<string, string>
```

**MEDIOCRE (names the pieces but doesn't specify them):**
```
**Implementation Details:**
- Strip CSS comments first, then find :root blocks, then extract custom properties
- Use regex to match property-value pairs
- Handle multi-line values by matching to the next semicolon
- Export parseCSSCustomProperties(css: string): Record<string, string>
```

**GOOD (copy-pasteable — each bullet translates directly to code):**
```
**Implementation Details:**
- Step 1 — Strip comments: `css.replace(/\/\*[\s\S]*?\*\//g, '')` removes all block comments before any parsing
- Step 2 — Extract :root blocks: `/(?:^|\s):root\s*\{([^}]+)\}/gm` captures content between :root { }. Apply globally — CSS may have multiple :root blocks (merge all matches)
- Step 3 — Parse properties: for each :root block content, split on semicolons, then for each declaration match `/\s*(--.+?)\s*:\s*(.+)/` to capture name and value. Trim both. This handles multi-line values because we split on `;` not newlines
- Step 4 — Normalize values: trim whitespace, collapse internal whitespace runs to single space. Preserve `var()` references as raw strings (don't resolve)
- Export: `export function parseCSSCustomProperties(css: string): Record<string, string>` — keys include the `--` prefix (e.g., `--color-primary`), values are the raw trimmed CSS value
- Ignore `@media`-scoped :root blocks — the top-level regex won't match them because they're nested inside @media { :root { } } (the `[^}]` stops at the inner brace). Verify this in tests
- Test fixture: import Craftsman's own `apps/web/src/styles/tokens.css` as a real-world fixture. Assert specific properties by name: `--color-primary`, `--radius-lg`, `--shadow-md`
```

### Example: React Component

**BAD (theoretical):**
```
**Implementation Details:**
- Use existing Card component
- Data fetching with useQuery
- Form validation using zod
- Reuse PasswordStrength component
- Follow existing patterns from LoginForm
```

**GOOD (concrete):**
```
**Implementation Details:**
- Import `Card` from `src/components/ui/Card` — `<Card variant="outlined">` takes `{title, children, className?}`
- `useQuery({ queryKey: ['auth', 'register'], queryFn: ... })` — follow pattern in `src/hooks/useAuth.ts:18-30`
- Zod schema: `z.object({ email: z.string().email(), password: z.string().min(8), confirm: z.string() }).refine(d => d.password === d.confirm)`
- `PasswordStrength` from `src/components/auth/PasswordStrength` — props: `{score: 0-4, showLabel?: boolean}`
- Form layout: follow `LoginForm.tsx:45-62` (FormField → Label → Input → ErrorMessage stack)
- Submit: `api.auth.register(data)` — handle 409 with `if (err.status === 409)` per `src/lib/api.ts:89` error pattern
```

---

## Why This Matters

The entire purpose of plan-chunks is to eliminate risk before implementation. In production, the implementer agent is autonomous — it cannot ask clarifying questions, it cannot make judgment calls, it cannot research approaches. Every decision deferred from planning to implementation is a potential failure point.

**Planning is where the thinking happens. Implementation is where the typing happens.**

If the implementer has to think, the plan failed.
