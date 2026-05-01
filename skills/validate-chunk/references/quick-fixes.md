# Quick Fix Patterns

Common validation issues and their fixes. Reference these when applying auto-fixes during validation.

---

## Missing Type
```typescript
// Error
const handleSubmit = (e) => { ... }

// Fix
const handleSubmit = (e: React.FormEvent) => { ... }
```

## Unused Import
```typescript
// Just remove the line
- import { unused } from 'package'
```

## Missing Dependency
```typescript
// Add to dependency array
useEffect(() => {
  fetchData(id)
}, [id])  // Added 'id'
```

## Missing Return Type
```typescript
// Add explicit return
function getData(): Promise<User[]> {
  return fetch('/api/users').then(r => r.json())
}
```
