---
last_updated: {{DATE}}
---

# Component Patterns

Standard patterns for UI components. All implementations should follow these specifications.

## Buttons

### Primary Button
The main call-to-action. One per view maximum.

```
Background: primary
Text: text-inverse (white)
Padding: sm (8px) vertical, md (16px) horizontal
Border Radius: md (8px)
Font: text-base, weight-medium
Shadow: none (default), sm (hover)

States:
- Default: primary background
- Hover: primary-hover background, shadow-sm, scale(1.02)
- Active: scale(0.98)
- Disabled: 50% opacity, cursor-not-allowed
- Loading: spinner replaces text, disabled state
```

### Secondary Button
For secondary actions.

```
Background: transparent
Border: 1px solid border
Text: text-primary
Padding: sm vertical, md horizontal
Border Radius: md

States:
- Default: transparent
- Hover: surface background
- Active: surface-hover background
- Disabled: 50% opacity
```

### Ghost Button
Minimal emphasis, often for tertiary actions.

```
Background: transparent
Border: none
Text: text-secondary
Padding: sm vertical, md horizontal

States:
- Hover: surface background
- Active: surface-hover background
```

### Button Sizes
```
sm: text-sm, padding xs/sm (4px/8px)
md: text-base, padding sm/md (8px/16px) — default
lg: text-lg, padding md/lg (12px/24px)
```

## Inputs

### Text Input
```
Background: background
Border: 1px solid border
Border Radius: md
Padding: sm (8px) all sides
Font: text-base
Min Height: 40px

States:
- Default: border color
- Focus: primary border, 2px ring primary-light
- Error: error border, error-light background
- Disabled: surface background, text-muted
```

### Input with Label
```
Label: text-sm, weight-medium, text-primary
Gap: xs (4px) between label and input
Helper text: text-sm, text-secondary
Error text: text-sm, error color
```

### Textarea
Same as text input, but:
```
Min Height: 120px
Resize: vertical
```

## Cards

### Default Card
```
Background: background
Border: 1px solid border
Border Radius: lg (12px)
Padding: lg (24px)
Shadow: sm

States:
- Hover (if clickable): shadow-md, border-strong
```

### Card Sections
```
Header: weight-semibold, text-lg, border-bottom
Body: padding-top md
Footer: border-top, padding-top md
```

## Modals

### Modal Container
```
Background: background
Border Radius: lg
Shadow: xl
Max Width: md (448px) default, lg (512px) large
Padding: lg (24px)
```

### Modal Structure
```
Backdrop: black, 50% opacity
Position: centered vertically and horizontally
Animation: fade in + scale from 0.95
Close: X button top-right, Escape key
```

### Modal Sections
```
Header: text-xl, weight-semibold, border-bottom optional
Body: padding-top md
Footer: border-top, flex justify-end, gap sm
```

## Toasts / Notifications

### Position
```
Desktop: bottom-right, 24px from edge
Mobile: bottom-center, 16px from edge
```

### Toast Container
```
Background: background
Border: 1px solid border
Border Radius: md
Shadow: lg
Padding: md
Min Width: 300px
Max Width: 400px
```

### Toast Types
```
Success: success-light background, success border-left (4px)
Error: error-light background, error border-left
Warning: warning-light background, warning border-left
Info: info-light background, info border-left
```

### Behavior
```
Duration: 4s default, 6s for errors
Animation: slide up 16px + fade in
Dismiss: X button always visible
Stack: newest on top, max 3 visible
```

## Empty States

### Structure
```
Container: centered in parent, max-width md
Illustration: 120px max height, muted colors
Headline: text-lg, weight-medium, text-primary
Description: text-secondary, max 2 lines, text-center
Action: Primary button below, margin-top lg
```

### Example
```
[Illustration]

No projects yet

Projects help you organize related work
and track progress over time.

[Create your first project →]
```

## Loading States

### Skeleton
```
Background: surface
Animation: shimmer (subtle pulse)
Border Radius: matches content shape
```

### Skeleton Patterns
```
Text line: height 16px, width varies (60-100%)
Avatar: circle, matches avatar size
Card: full card shape with internal skeletons
Table row: alternating width skeletons
```

### Loading Spinner (rare)
Only when skeleton doesn't make sense:
```
Size: 20px default
Color: primary
Animation: rotate 1s linear infinite
```

## Forms

### Layout
```
Direction: single column
Label position: above input
Gap between fields: lg (24px)
```

### Validation
```
Timing: inline (on blur), not on submit
Error display: below input, text-sm, error color
Success: subtle checkmark, success color
```

### Submit Button
```
Position: below last field, margin-top xl
Width: auto (not full width) for desktop
Width: full for mobile
Loading: show spinner, disable button
```

## Tables

### Container
```
Border: 1px solid border
Border Radius: lg
Overflow: hidden
```

### Header
```
Background: surface
Font: text-sm, weight-semibold
Padding: sm vertical, md horizontal
Border-bottom: 1px solid border
```

### Row
```
Background: background
Padding: md vertical, md horizontal
Border-bottom: 1px solid border (except last)

States:
- Hover: surface background
- Selected: primary-light background
```

### Cell Alignment
```
Text: left
Numbers: right
Actions: right
Status: center
```

## Navigation

### Sidebar
```
Width: 240px (desktop), full (mobile overlay)
Background: surface
Border-right: 1px solid border
```

### Nav Item
```
Padding: sm vertical, md horizontal
Border Radius: md
Font: text-sm, weight-medium

States:
- Default: text-secondary
- Hover: surface-hover background, text-primary
- Active: primary-light background, primary text
```

### Breadcrumbs
```
Separator: / or chevron
Font: text-sm
Color: text-secondary, last item text-primary
```
