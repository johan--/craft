---
last_updated: {{DATE}}
---

# UI Patterns We Follow

Established patterns that guide implementation decisions.

## Forms

### Layout
- Single column for simplicity
- Generous vertical spacing (24px between fields)
- Labels above inputs, not beside

### Validation
- Inline validation on blur, not on submit
- Show errors immediately below the field
- Green checkmark for valid fields (subtle)
- Never clear user input on error

### Submit Behavior
- Disable button during submission
- Show spinner inside button
- Optimistic feedback when safe
- Clear error recovery on failure

### Example
```
[Label]
[Input field]
[Helper text or error]

[24px gap]

[Label]
[Input field]

[32px gap]

[Submit Button with loading state]
```

## Navigation

### Primary Navigation
- Persistent sidebar for main navigation
- Collapsible on mobile (hamburger menu)
- Active state clearly visible
- Icons + labels for clarity

### Secondary Navigation
- Tabs for same-page sections
- Breadcrumbs for deep hierarchies
- Back buttons respect history

### Power Users
- Command palette (Cmd+K) available
- Keyboard shortcuts for common actions
- Shortcuts displayed on hover

## Empty States

### Required Elements
1. **Illustration** — Not a sad face, something helpful
2. **Headline** — What's empty
3. **Description** — Why it matters / what to do
4. **Primary Action** — How to fix it

### Tone
- Helpful, not apologetic
- Forward-looking, not dwelling on emptiness
- Action-oriented

### Examples
```
[Illustration of a project folder]

No projects yet

Projects help you organize related work
and track progress across multiple tasks.

[Create your first project →]
```

## Loading States

### Skeleton Screens (Preferred)
- Match the layout of actual content
- Subtle shimmer animation
- Same dimensions as real content
- Never jarring when content loads

### When to Use Spinners
- Full-page loads (rare)
- Actions where skeleton doesn't apply
- Inside buttons during submission

### Never Do
- "Loading..." text without visual
- Blank screens while fetching
- Layout shifts on load

## Error States

### Structure
1. **What happened** — Clear, non-technical
2. **Why** — If we know and it helps
3. **How to fix** — Actionable next step

### Tone
- Never blame the user
- Be specific, not vague
- Offer a way forward

### Examples
```
❌ "Something went wrong"
✅ "Couldn't save your changes. Check your connection and try again."

❌ "Invalid input"
✅ "Email must include @ symbol"

❌ "Error 500"
✅ "Our servers are having trouble. We're on it. Try again in a few minutes."
```

## Feedback & Confirmation

### Success
- Subtle, not disruptive
- Confirms what happened
- Disappears automatically (4s)

### Destructive Actions
- Always confirm before delete
- Show what will be deleted
- Make cancel the default/easiest action

### Progress
- Show progress for operations > 2s
- Percentage or steps when possible
- Allow cancel for long operations

## Responsive Behavior

### Mobile First
- Design for mobile, enhance for desktop
- Touch targets minimum 44px
- No horizontal scrolling ever

### Breakpoint Behavior
- **Mobile (<640px):** Stack, simplify, full-width
- **Tablet (640-1024px):** Adapt layouts, show more
- **Desktop (>1024px):** Full experience, shortcuts visible

### What Changes
- Navigation collapses to hamburger
- Sidebars become overlays
- Tables become cards
- Multi-column becomes single-column
