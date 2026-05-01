---
last_updated: {{DATE}}
---

# Animation Patterns

Industry-leading motion design reference. Used by `plan-chunks` to translate story Motion specs into implementable chunk details.

---

## Philosophy

### The Five Rules of Product Animation

1. **Frequency = inverse of duration.** High-frequency actions (keyboard shortcuts, repeated clicks) get zero animation. Low-frequency actions (first-time onboarding, milestone celebrations) can go up to 400ms.

2. **Never animate keyboard-initiated actions.** Users do them hundreds of times daily. Animation makes them feel slow.

3. **If it doesn't clarify, guide, or confirm — skip it.** Every animation must earn its milliseconds.

4. **CSS transitions over keyframes.** Transitions are interruptible — if state changes mid-animation, they retarget smoothly. Keyframes jump.

5. **GPU properties only.** Animate `transform` and `opacity`. Never animate `width`, `height`, `top`, `left`, `padding`, `margin`.

### When NOT to Animate

- Keyboard-initiated actions (Tab, Enter, arrow keys)
- Actions the user performs more than 20x per session
- Data refreshes / background syncs
- State changes that happen faster than perception (~50ms)
- Anything during initial page paint (defer to after load)

---

## Motion Tokens

### Duration Scale

| Token | Value | Use |
|-------|-------|-----|
| `instant` | 0ms | Keyboard actions, high-frequency operations |
| `fast` | 100ms | Tooltips (subsequent), micro-feedback, focus rings |
| `normal` | 150-200ms | Modals, dropdowns, panels entering, hover effects |
| `moderate` | 300ms | Maximum for productivity UI, page transitions |
| `expressive` | 400ms | Toasts, brand moments, onboarding, celebrations |

**Hard ceiling:** 300ms for any action in a productivity tool. Reserve 400ms for rare, delightful moments only.

### Easing Functions

| Token | Value | When |
|-------|-------|------|
| `ease-default` | `ease-out` | Most interactions (starts fast, feels responsive) |
| `ease-enter` | `cubic-bezier(0, 0, 0.2, 1)` | Elements appearing on screen |
| `ease-exit` | `cubic-bezier(0.4, 0, 1, 1)` | Elements leaving the screen |
| `ease-move` | `cubic-bezier(0.4, 0, 0.2, 1)` | On-screen position/size changes |
| `ease-hover` | `ease` | Hover effects, brand moments |

**Never use:** `linear` (feels robotic), `transition: all` (animate specific properties only).

### Transform Values

| Interaction | Value | Notes |
|-------------|-------|-------|
| Button press (`:active`) | `scale(0.97)` | Subtle physical feedback |
| Button hover | `scale(1.02)` + shadow elevation | Lift effect |
| Card hover | Shadow `sm` → `md` | Elevation only, no scale |
| Never start from | `scale(0)` | Looks jarring — use `scale(0.95)` minimum |

### Spring Presets

For physics-based animations (when using Framer Motion or similar):

| Preset | Value | Feel |
|--------|-------|------|
| `bouncy` | `cubic-bezier(0.68, -0.55, 0.265, 1.55)` | Playful overshoot |
| `snappy` | `cubic-bezier(0.175, 0.885, 0.32, 1.275)` | Confident with subtle overshoot |
| `smooth` | `cubic-bezier(0.4, 0, 0.2, 1)` | Professional, no overshoot |

---

## Pattern Catalog

### Loading States

**Skeleton Screens (preferred)**
```
Trigger:    Async content loading
Animation:  Shimmer pulse (subtle opacity oscillation)
Duration:   1.5s cycle, infinite
Background: surface color
Shape:      Matches content layout exactly
Show-delay: 150-300ms (prevents flicker on fast responses)
Min-visible: 300-500ms once shown (prevents jarring flash)
```

**Progress Bar**
```
Trigger:    Operations with known progress (2-5s)
Animation:  Width grows left-to-right
Duration:   Actual progress + 200ms completion animation
Easing:     ease-out for increments
Completion: Brief pulse/glow, then fade out
```

**Loading Spinner (rare)**
```
Trigger:    Full-page load, unknown duration, no layout to skeleton
Animation:  rotate 1s linear infinite
Size:       20px default
Color:      primary
Show-delay: 300ms (never show for fast operations)
```

**DO NOT skeleton-ize:** Modals themselves, toast notifications, overflow menus, tooltips.

### Hover Effects

**Button Hover**
```
Trigger:    mouseenter
Transform:  scale(1.02)
Shadow:     none → sm (or sm → md)
Transition: 150ms ease
Active:     scale(0.97), 100ms
```

**Clickable Card Hover**
```
Trigger:    mouseenter
Shadow:     sm → md
Border:     border → border-strong (optional)
Transition: 150ms ease
Cursor:     pointer
```

**Navigation Item Hover**
```
Trigger:    mouseenter
Background: transparent → surface-hover
Color:      text-secondary → text-primary
Transition: 150ms ease
```

### State Transitions

**Modal Enter**
```
Backdrop:   opacity 0 → 0.5 (200ms ease-out)
Container:  opacity 0 → 1, scale 0.95 → 1 (200ms ease-out)
Origin:     center
```

**Modal Exit**
```
Container:  opacity 1 → 0, scale 1 → 0.95 (150ms ease-in)
Backdrop:   opacity 0.5 → 0 (150ms ease-in)
Note:       Exit is 25% faster than enter (feels responsive)
```

**Dropdown/Select Enter**
```
Transform:  opacity 0 → 1, translateY(-4px) → 0
Duration:   150ms ease-out
Origin:     top (or top-left for aligned dropdowns)
```

**Dropdown/Select Exit**
```
Transform:  opacity 1 → 0, translateY(0) → -4px
Duration:   100ms ease-in
Note:       Faster exit than enter
```

**Drawer/Panel Slide**
```
Enter:      translateX(100%) → 0 (250ms ease-out) for right drawer
Exit:       translateX(0) → 100% (200ms ease-in)
Backdrop:   Same as modal
```

**Accordion/Collapse**
```
Expand:     height 0 → auto, opacity 0 → 1 (200ms ease-out)
Collapse:   height auto → 0, opacity 1 → 0 (150ms ease-in)
Note:       Use grid technique for height animation (avoid layout thrash)
```

### Page Transitions

**Fade (default)**
```
Exit:       opacity 1 → 0 (100ms ease-in)
Enter:      opacity 0 → 1 (200ms ease-out)
Total:      ~300ms perceived
```

**Slide**
```
Forward:    translateX(0) → -20px (exit), translateX(20px) → 0 (enter)
Back:       translateX(0) → 20px (exit), translateX(-20px) → 0 (enter)
Duration:   250ms ease-in-out
```

**Cross-fade**
```
Old page:   opacity 1 → 0 (150ms)
New page:   opacity 0 → 1 (150ms, starts at 50ms offset)
Duration:   200ms total perceived
```

### List & Grid Animations

**Staggered Reveal**
```
Trigger:    Initial render or filter change
Per-item:   opacity 0 → 1, translateY(8px) → 0
Duration:   200ms ease-out per item
Stagger:    40-60ms between items
Max items:  Stagger first 8-10 items, rest appear instantly
```

**Item Add**
```
New item:   opacity 0 → 1, height 0 → auto
Duration:   200ms ease-out
Others:     Smoothly shift position (200ms ease-in-out)
```

**Item Remove**
```
Removed:    opacity 1 → 0, height auto → 0
Duration:   150ms ease-in
Others:     Smoothly close gap (200ms ease-in-out)
```

**Reorder**
```
Moving items: translateY to new position
Duration:     200ms ease-in-out
Note:         Use FLIP technique for performance
```

### Feedback Animations

**Success Checkmark**
```
Animation:  Draw circle, then draw checkmark stroke
Duration:   400ms total (200ms circle + 200ms check)
Easing:     ease-out
Color:      success
Optional:   Brief scale pulse (1 → 1.1 → 1, 200ms)
```

**Error Shake**
```
Animation:  translateX(0 → 6px → -6px → 4px → -4px → 0)
Duration:   300ms
Easing:     ease-in-out
Trigger:    Invalid form submission, auth failure
Note:       Pair with red border/highlight
```

**Toast Entrance (Sonner-style)**
```
Enter:      translateY(100%) → 0, opacity 0 → 1
Duration:   400ms ease
Stack:      Scale stacked toasts by (1 - 0.05 * index)
Y-offset:   Stack with 8px gap
Hover:      Expand stack to show all, pause auto-dismiss
Exit:       translateX(100%) + opacity fade (200ms ease-in)
```

**Form Validation Inline**
```
Error appear:   opacity 0 → 1, translateY(-4px) → 0 (150ms ease-out)
Error clear:    opacity 1 → 0 (100ms ease-in)
Input border:   color transition 150ms ease
```

### Celebration (use sparingly)

**Confetti**
```
Trigger:    Milestone completion, first-time achievement
Duration:   1.5-2s
Particle count: 30-50 (subtle, not overwhelming)
Physics:    Gravity + slight wind
Cleanup:    Particles fade out, don't litter
Frequency:  RARE — only for genuine milestones
```

**Pulse/Glow**
```
Trigger:    Important state change, new badge, level up
Animation:  box-shadow pulse (0 → 8px → 0 spread)
Duration:   600ms ease-in-out
Repeat:     1-2 times, not infinite
Color:      primary or success, at 30% opacity
```

---

## Next-Level Patterns

These are the "beyond default" opportunities that creative-spark can suggest. Each significantly elevates perceived quality.

### Direction-Aware Hover
Navigation highlight that follows mouse direction between items (Vercel-style).
```
Implementation: Track mouse position, animate indicator translateX/translateY
                from previous active item to hovered item
Duration:       200ms ease-out
Key detail:     Indicator morphs shape/size between items
Library:        CSS transitions + JS for position tracking
```

### Safe Triangles on Nested Menus
Invisible SVG triangle between cursor and sub-menu prevents accidental close.
```
Implementation: getBoundingClientRect() for submenu position
                Track mouse via mousemove
                Calculate triangle: cursor → submenu top corner → submenu bottom corner
                Render as SVG path with pointer-events: auto
Key detail:     pointer-events: none on container, auto on triangle path
```

### Variable Delights
One-time surprise animations that appear only once (Arc browser-style).
```
Examples:       Special animation on first task completion
                Unique transition first time visiting a section
                Easter egg on specific interaction patterns
Key detail:     Track in localStorage, never repeat
                Compounds into "this app has personality" feeling
```

### Tooltip Progressive Reveal
First tooltip gets a delay; subsequent tooltips appear instantly.
```
First hover:    150ms delay before showing
Subsequent:     0ms delay, no entrance animation
Timeout:        Return to "first hover" behavior after 500ms of no tooltip activity
Key detail:     Global tooltip state tracks "is any tooltip recently active"
```

### Priority-Based Responsive Slot Hiding
Header/toolbar items hide by priority as container shrinks (Linear-style).
```
Implementation: ResizeObserver on container
                Each slot has numeric priority
                Lower-priority slots get visibility: hidden first
                Active/selected items always visible regardless of priority
Key detail:     Use visibility: hidden (not display: none) to maintain DOM position
                Calculations in useLayoutEffect
```

### Ambient Motion
Subtle background gradients that shift slowly (Stripe-style).
```
Implementation: CSS gradient animation or canvas
Duration:       10-20s cycle
Movement:       Barely perceptible color shifts
Key detail:     Must not increase CPU usage noticeably
                GPU-accelerated (background-position or transform)
                Disabled for prefers-reduced-motion
```

### Stagger Choreography
Coordinated page load sequence: header → content → sidebar.
```
Sequence:       1. Shell/chrome appears (0ms)
                2. Header content fades in (100ms)
                3. Primary content area (200ms)
                4. Secondary content / sidebar (300ms)
                5. Decorative elements last (400ms)
Duration:       Each element: 200ms ease-out
Key detail:     Total choreography under 500ms
                Use CSS animation-delay, not JS setTimeout
```

---

## Accessibility

### Required: `prefers-reduced-motion`

Every animation MUST include a reduced-motion fallback:

```css
/* Standard animation */
.element {
  transition: transform 200ms ease-out, opacity 200ms ease-out;
}

/* Reduced motion: instant state changes, no movement */
@media (prefers-reduced-motion: reduce) {
  .element {
    transition: opacity 150ms ease-out;
    transform: none !important;
  }
}
```

### Rules
- No rapid flashing (3 flashes/second maximum — WCAG 2.3.1)
- Movement animations become opacity-only in reduced-motion mode
- Screen readers get equivalent feedback via aria-live regions
- Keyboard focus indicators may use subtle animation but must remain visible in reduced-motion
- Test the full app with `prefers-reduced-motion: reduce` enabled

---

## Performance

### GPU-Accelerated Properties Only
Animate these (composited, no layout/paint):
- `transform` (translate, scale, rotate)
- `opacity`

Never animate these (trigger layout/paint):
- `width`, `height`
- `top`, `right`, `bottom`, `left`
- `padding`, `margin`
- `border-width`
- `font-size`

### Best Practices
- Never use `transition: all` — explicitly list properties: `transition: transform 200ms ease-out, opacity 200ms ease-out`
- Use `will-change` sparingly and only on elements about to animate, remove after
- Debounce/throttle animation triggers on scroll and resize
- Profile animations with Chrome DevTools Performance panel before shipping
- Target 60fps minimum — if an animation drops frames, simplify it
- For list animations with many items, virtualize the list and only animate visible items
