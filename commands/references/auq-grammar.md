# AUQ Grammar: one worked gate to mirror

This file holds ONE complete worked example of a good alignment gate - a finding
presented to the user, end to end: the brief, the prose, the widget. Agents that
surface a product finding (the alignment check at Step 3) Read this at gate time
and mirror it.

It is a model, not a rulebook. The old Step 3 taught the gate as a pile of prose
directives, and every one of them lost to the model's instincts. One worked gate
carries what a page of rules could not: the length, the air, the voice.

## Mirror the shape, not the content

The scenario below is invented - a fictional checkout form, chosen because it owns
nothing in this codebase. The one rule for reading this file:
mirror the shape, not the content. Copy how it reads, never what it says:

- **Visible prose.** Every word below is message text the user sees. The reasoning
  is never left in thinking with only the widget showing - that failure is the
  disease this file cures.
- **Short, airy paragraphs.** One idea each, a blank line between them. The lean is
  the last line before the widget, in bold - a rushed reader takes the first line of
  each block plus the bolded lean and still gets the whole gate. Correct content
  delivered as a wall still fails.
- **Opens from the user's own intent, in plain language.** The first sentence starts
  where the user already stands. No term coined during the work reaches them.

## The worked gate

_The brief, once, before the first finding:_

> I looked at where this lands. One thing needs your call - I settled the rest
> myself (test names, error copy: engineering, not product).

_The finding:_

> Finding 1 of 1.
>
> You want the new address check on the checkout form. The same check would fit the
> two other forms that take an address - the account page and the shipping-book
> editor.
>
> Those two aren't free, though. Each has its own submit path and its own tests, so
> doing all three roughly doubles the diff for this story.
>
> A quick grep puts the address block at three call sites - checkout, account, and
> the shipping-book editor.
>
> **My lean:** do checkout now and split the other two into a follow-up, so this
> story still ships this cycle.

_The widget:_

```
AskUserQuestion:
  question: "Apply the new address check to all three forms now, or just checkout?"
  options:
    - label: "Checkout only (Recommended)"
      description: "Ships this cycle. The other two forms are real work - a clean follow-up, not a corner cut."
    - label: "All three now"
      description: "Also solid if you'd rather land it once - but it roughly doubles the diff and moves the ship date."
    - label: "Let's discuss"
      description: "Want to weigh the split before I plan."
```

The recommendation is first and carries `(Recommended)`. Each option's description
is an honest one-line verdict - the endorsement on the runner-up, the cost stated
plainly. `Let's discuss` closes the set. The evidence was cited once, as a
coordinate ("three call sites"), never as a claim of diligence. Every option was
already argued in the prose; none is filler invented to round out the list.
