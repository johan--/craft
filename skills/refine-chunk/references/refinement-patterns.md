# Refinement Patterns Catalog

Common validation errors and their surgical fixes, organized by error type.

---

## TypeScript Errors

**Missing prop:**
```diff
- <Component />
+ <Component requiredProp={value} />
```

**Wrong type:**
```diff
- const count: string = 5
+ const count: number = 5
```

**Missing return type:**
```diff
- function getData() {
+ function getData(): Promise<User[]> {
    return fetch('/api/users')
  }
```

**Null safety:**
```diff
- user.name.toUpperCase()
+ user?.name?.toUpperCase() ?? ''
```

---

## Lint Errors

**Unused import:**
```diff
- import { unused, used } from 'package'
+ import { used } from 'package'
```

**Missing dependency:**
```diff
  useEffect(() => {
    fetchData(id)
- }, [])
+ }, [id])
```

**Prefer const:**
```diff
- let value = 'constant'
+ const value = 'constant'
```

---

## Build Errors

**Missing module:**
```bash
npm install missing-package
```

**Export issue:**
```diff
// In source file
- function helper() { ... }
+ export function helper() { ... }
```

---

## Test Failures

**Assertion mismatch:**
```diff
- expect(result).toBe('old value')
+ expect(result).toBe('new value')
```

**Async timing:**
```diff
- expect(screen.getByText('loaded')).toBeInTheDocument()
+ await waitFor(() => {
+   expect(screen.getByText('loaded')).toBeInTheDocument()
+ })
```
