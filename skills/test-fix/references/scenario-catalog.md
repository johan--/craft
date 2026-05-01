# Test Fix Scenario Catalog

Worked examples of common test triage outcomes. Reference these when determining if the test or the implementation is wrong.

---

## Stale Assertion (most common)
Chunk changed a function's return value. Test asserts old value.
```diff
- expect(getStatus()).toBe('pending')
+ expect(getStatus()).toBe('active')
```

## Renamed/Moved Export
Chunk refactored an export name. Test imports old name.
```diff
- import { oldName } from './module'
+ import { newName } from './module'
```

## Changed Component Props
Chunk added a required prop. Test renders without it.
```diff
- render(<Component />)
+ render(<Component requiredProp="value" />)
```

## Changed API Response Shape
Chunk updated an API endpoint's response format. Test mocks old shape.
```diff
- mockResponse({ data: items })
+ mockResponse({ items, total: items.length })
```

## New Validation Added
Chunk added input validation. Test submits data that's now invalid.
```diff
- const input = { name: '' }  // was valid, now rejected
+ const input = { name: 'Test User' }  // passes new validation
```

## Side-Effect Behavior Change
Chunk changed Component A, but Component B's test fails because B depends on A.
- Read Component B's test to understand the dependency
- Check if the dependency change was intentional
- Update B's test mocks to reflect A's new behavior
