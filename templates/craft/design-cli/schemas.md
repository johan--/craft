---
last_updated: {{DATE}}
---

# Frontmatter Schemas

Reference for YAML frontmatter used in this project's files.

---

## How to Use This File

Document the expected structure for any file types that use frontmatter.
The implementer agent references this when working with your files.

---

## Example Schema (Delete and Replace)

### File Type Name

**Location:** `path/to/files/*.md`

```yaml
---
required_field: "value"           # Description of this field
another_required: 123             # Numeric field
optional_field: "optional"        # Optional: description
list_field:                       # List of items
  - item1
  - item2
---
```

**Field Details:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| required_field | string | Yes | What this field is for |
| another_required | number | Yes | What this field is for |
| optional_field | string | No | What this field is for |
| list_field | array | No | What this field is for |

---

## Your Schemas

Add your file schemas below.

<!-- Example schemas to document:
- Configuration files
- Story/task files
- Template files
- Hook definitions
- Plugin manifests
-->
