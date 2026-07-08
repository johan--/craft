# Changelog

Notable, user-facing changes per version. Internal changes (tests, refactors, contributor tooling) bump the version without an entry, so version numbers here may skip.

## 1.99.35

- Added the Taste Pass: once several tweaks you loved have accrued, craft offers a "victory lap" that scouts other surfaces the same taste could spread to and hands each one to /craft:mockup to make - surfaced as one ignorable line at session start or a tweak close-out, never a popup, and self-silencing if you never take it
- Added taste lineage: a loved tweak that grows into a mockup and graduates into a story or another tweak now records where it came from, so a button that snowballs into a whole page still traces back to where the taste started
- Changed the tweak close-out to a feeling gradient (Love it / Looks good / Good enough / Not quite); "apply elsewhere" is now a follow-on offer instead of a button

## 1.99.34

- Improved mockup Diverge rounds: options are style-isolated (no more overlap between them), render at real scale, and at least one option must break past the project's current design language - safe-times-three now counts as a failed round

## 1.99.32

- Changed mockup rounds to edit the living page instead of regenerating it, and to verify handoffs with console/DOM checks - screenshots now happen only for viewports you can't see (mobile emulation, unattended sessions) or on request

## 1.99.31

- Changed the changelog to notable-only: features and user-visible fixes get entries, internal fixes bump the version silently

## 1.99.29

- Added /craft:mockup: a live HTML mockup funnel - a persistent alchemist builds 3 genuinely different options, you converge by reacting through diverge/refine/polish rounds, and new design values solidify to tokens.yaml at acceptance
- Added three graduation ramps for a converged mockup: port it now as a tweak, create a pre-filled story (mockup CSS is normative - ported, never reinterpreted), or park it as a notebook todo
- Added mockup visibility: a Mockups section in /craft:status and a session-start segment when mockups await a destination
- Changed story creation: the source question now also offers "From mockup" when converged mockup records exist

## 1.99.28

- Added this changelog: notable user-facing changes land here with every release, enforced by the doc-drift push gate
