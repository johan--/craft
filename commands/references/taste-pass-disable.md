# Taste Pass - earned exit (read inline ONLY on an offset-maxed decline)

You reach this file from `taste-pass.md`'s pacing step, and ONLY there: the snooze offset is already at
its cap (5) and the user just declined again. The everyday hot path never loads this - it exists so the
"never nag" promise holds even though a below-cap decline preserves the count.

Say ONE warm line naming what they'd miss, then offer a THREE-outcome choice. Keep it to a single
screenful; this is the one place the loop asks to bow out.

> "I keep offering the victory lap and you keep passing - that's fair. I can stop asking on this project
> entirely, run it once now, or just go quiet for a while. Your call."

Resolve to exactly one of:

- **Disable forever (this project):** the user wants both doors silent here.
  `"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/taste-pass-state.sh" disable`
  (sets `taste_pass_enabled: false` in `.craft/settings.yaml`). No pass runs. Both doors stay silent
  until the key is flipped back by hand.

- **Run it now:** they'd rather do the lap after all. Go run the scout in `taste-pass.md` from the top,
  then close as a normal accept: `"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/taste-pass-state.sh" accept`.

- **Neither (go quiet for now):** the terminal decline. This is the SINGLE decline that RESETS the
  count rather than raising the offset: `"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/taste-pass-state.sh" accept`
  (advances `last_asked` to today, offset back to 0). It is the guard that keeps "never nag" true - the
  banked loved tweaks are cleared from the ripe pool, so the loop goes quiet and only speaks again once
  fresh loved taste accrues.

**Explicit choice only.** If the user says none of the three and moves on, that is pure silence - write
nothing (`.claude/rules/explicit-lock-confirmation.md`). Only an explicit selection mutates state.
