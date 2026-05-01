---
name: {{PROJECT_NAME}}
type: {{PROJECT_TYPE}}
package_manager: {{PACKAGE_MANAGER}}
last_updated: {{DATE}}
energy: {{ENERGY}}
---

# Project DNA

This file defines the technical foundation and conventions for this project.
Every agent reads this to maintain consistency.

## Tech Stack

### Frontend
- **Framework**: {{FRAMEWORK}}
- **Styling**: {{STYLING}}
- **State**: {{STATE_MANAGEMENT}}
- **Forms**: {{FORMS}}

### Backend
- **API**: {{API}}
- **Database**: {{DATABASE}}
- **Auth**: {{AUTH}}

### Infrastructure
- **Hosting**: {{HOSTING}}
- **CI/CD**: {{CI_CD}}

## Code Patterns

### File Organization
```
src/
├── app/                 # Routes and pages
├── components/
│   ├── ui/              # Design system components
│   └── [feature]/       # Feature-specific components
├── lib/                 # Utilities and helpers
├── hooks/               # Custom React hooks
├── types/               # TypeScript types
└── styles/              # Global styles
```

### Naming Conventions
- **Components**: PascalCase (`UserProfile.tsx`)
- **Hooks**: camelCase with `use` prefix (`useAuth.ts`)
- **Utilities**: camelCase (`formatDate.ts`)
- **Types**: PascalCase with descriptive suffix (`UserDTO`, `AuthState`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_RETRIES`)

### API Patterns
- All routes return: `{ data, error, meta }`
- Use Zod for request validation
- Wrap handlers with error boundary
- Log errors appropriately

### Component Patterns
- Server components by default
- 'use client' only when needed
- Colocate styles, tests, stories
- Extract hooks for complex logic
- Props interface named `[Component]Props`

## Voice & Copy

### Tone
- Friendly but professional
- Clear, not clever
- Helpful, not condescending
- Concise, not verbose

### Error Messages
- Say what happened
- Say why (if known)
- Say how to fix it
- Example: "Couldn't save changes. You're offline. We'll retry when you're back."

### Empty States
- Acknowledge the emptiness
- Explain the benefit of adding content
- Provide clear action
- Example: "No projects yet. Projects help you organize your work. Create your first one →"

### Success Messages
- Confirm the action
- Subtle celebration
- Clear next step (if any)
- Example: "Saved! ✓" or "Welcome aboard! Let's set up your workspace →"

### Loading States
- Never leave user wondering
- Use skeleton screens, not spinners
- Preserve layout during load
- Show progress for long operations

## Preferences

### Do This
- Use existing components before creating new ones
- Prefer server components
- Use `cn()` for conditional Tailwind classes
- Handle loading, error, empty states for every async operation
- Use design tokens for all visual values
- Follow locked patterns exactly

### Don't Do This
- Don't use inline styles
- Don't create new color variables (use tokens)
- Don't skip TypeScript types
- Don't leave console.logs in production code
- Don't ignore accessibility
- Don't deviate from locked patterns without a story

## Quality Bar

This project follows **pristine** quality standards:
- Pixel-perfect alignment
- Smooth 60fps animations
- WCAG AA accessible
- Mobile-first responsive
- Loading states everywhere
- Helpful error states
- Delightful empty states

**The bar is Stripe, Linear, Vercel** — not generic templates.
