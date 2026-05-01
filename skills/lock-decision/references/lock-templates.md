# Lock Decision Templates

## Table of Contents
- [Design Decisions (Typed)](#design-decisions-typed)
- [Pattern Locks](#pattern-locks)
- [Token Locks](#token-locks)
- [Approach Locks](#approach-locks)

---

## Design Decisions (Typed)

For structured UI decisions that Tokens Studio can render:

```markdown
### [Decision Name]
**Type:** layout | component | density | visibility
**Choice:** [key]
```

**Valid keys by type:**

| Type | Valid Keys |
|------|------------|
| `layout` | list, cards, table, grid, bento, sidebar, topnav, tabs, gallery |
| `component` | modal, inline, drawer, dropdown, pills, tabs, accordion, toggle, readonly |
| `density` | compact, comfortable, spacious |
| `visibility` | minimal, rich, full |

**Example:**
```markdown
### Task Display
**Type:** layout
**Choice:** cards

### Priority Selector
**Type:** component
**Choice:** pills

### Dashboard Density
**Type:** density
**Choice:** comfortable
```

> Tokens Studio renders these as a visual showcase. User changes decisions by asking — not through UI.

---

## Pattern Locks

For UI patterns that should be consistent:

```markdown
## Locked Pattern: Primary Button

**Locked:** 2024-01-15

### Specification
- Background: `primary` token
- Text: `white`
- Padding: `12px 24px`
- Border radius: `8px`
- Font: `medium` weight

### States
- Hover: `primary-dark` background
- Active: Scale 0.98
- Disabled: 50% opacity, no pointer events
- Loading: Spinner replaces text

### Variants
- `size="sm"` — Padding `8px 16px`, font size `14px`
- `size="lg"` — Padding `16px 32px`, font size `18px`

### Usage Rules
- One primary button per view
- Always has explicit label (no icon-only primary)
- Loading state required for async actions
```

---

## Token Locks

For design values that are final:

```markdown
## Locked Tokens

### Colors (Locked 2024-01-15)
| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#6366F1` | Main actions, links |
| `primary-dark` | `#4F46E5` | Hover states |
| `surface` | `#FAFAFA` | Backgrounds |

### Spacing Scale (Locked 2024-01-15)
`4, 8, 12, 16, 24, 32, 48, 64`

No arbitrary values. If you need something else, propose a token.
```

---

## Approach Locks

For technical decisions:

```markdown
## Locked Approach: Data Fetching

**Locked:** 2024-01-15
**Applies to:** All data fetching in the application

### Decision
Use React Query (TanStack Query) for all server state.

### Rationale
- Built-in caching and invalidation
- Optimistic updates
- DevTools for debugging
- Team familiarity

### Implementation Standard
```tsx
// All queries must follow this pattern
const { data, isLoading, error } = useQuery({
  queryKey: ['resource', id],
  queryFn: () => fetchResource(id),
  staleTime: 5 * 60 * 1000, // 5 minutes
});
```

### Not Allowed
- Direct fetch() calls for server data
- useEffect for data fetching
- Custom caching solutions
```
