# Milestone 27: sleep model v2 (19 Nov 2026)

Request (user, 19 Nov 2026): "the sleep bar doesn't work well. When someone starts with the avatar at normal difficulty, it starts at 7 a.m. with the sleep debt, and the health doesn't rise unless you sleep during the day and during the night. There should also be a minimum wake time according to science. You should research that, and the sleep debt should be dynamical, not a fixed number, and it should indicate the sleep debt a little in the health bars. Research all that and write it in the documents: what was changed, what was unchanged, what is adapted for the game to be playable. Fix it in this milestone."

The research, the model and the tables of what changed, what stayed and what was adapted are in **`documentation/sleep_model_v2.md`**.

## Causes found (in the code built in Milestone 10)

1. The debt and the Sleep measure changed only when a sleep ended: a fixed number all day.
2. The health bar also moved only when a sleep ended (37% per sleep), so health looked stuck while playing, and every extra sleep gave one more step.
3. "Tired" came from the debt alone: Normal (4 h of debt) was tired, and asked to sleep, at 7:00.
4. With 1 h of debt or more the avatar could sleep at any moment: no minimum wake time.
5. A nap counted as a whole short night: a 1-hour nap added 8 h of debt.

## Decisions (Claude's proposals, built because the user said "do everything"; the team checks them)

| # | Decision |
|---|---|
| 93 | Sleep need and debt are worked out every step (sleep v2, 4.1): need + minimum / 24 per hour, − 1 per hour asleep; when a sleep ends the unpaid need becomes debt; need above a normal day's counts as debt at once (`effective_debt()`); v1's recovery factor applied hour by hour; the 0-hour rule converts nothing. Exactly v1's total per cycle for short nights. |
| 94 | "I'm tired" comes from sleepiness = need / day need + 0.5 × d (never just after waking). Tiredness for performance stays v1. |
| 95 | Minimum wake time: 6 h after any sleep (`sleep.can_sleep_awake_h`), 0.5 h less per hour of debt, at least 3 h; or any time when tired. Replaces "debt ≥ 1 h". |
| 96 | The health bar moves 37% of the way per 24 avatar hours, a little every step (decision 1 adapted). |
| 97 | The measures panel shows "Sleep amount · debt 2.4 h", the Sleep bar moves while playing, and a thin lavender line shows today's sleep need. |

## What was built

- `scripts/health/sleep_model.gd`: `step()`, `effective_debt()`, `repaid_share()`, `day_need()`, `sleepiness()`, `min_wake_hours()`, `can_sleep()`; `new_day()` turns the unpaid need into debt after a real sleep; `debt_after()` is gone; `update_tired()` uses sleepiness.
- `scripts/autoload/game_state.gd`: `sleep_need` (saved; 0 for a new avatar, which has just woken).
- `scripts/autoload/simulation.gd`: `SleepModel.step()` at the start of every step.
- `scripts/health/health_model.gd`: the health bar moves every step; `daily_step()` does nothing now.
- `scripts/autoload/clock.gd`: `is_sleepy()` is `SleepModel.can_sleep()`.
- `data/config.json`: `sleep.min_wake_cut_per_debt_h`, `sleep.min_wake_floor_h`, `sleep.debt_sleepiness_weight` (placeholders); `sleep.can_sleep_debt_h` removed; comments of `sleep.can_sleep_awake_h` and `health.alpha_bar` updated.
- `scenes/main.tscn`, `scripts/ui/main.gd`: the Sleep label with the debt and the `SleepNeedBar`; texts `MEASURE_SLEEP_DEBT` and `MEASURE_SLEEP_NEED` (the Portuguese is Claude's draft).
- `tests/sleep_test.gd` rewritten for v2; `tools/render_ui_states.gd` state H (the measures panel).

## Checked

- A three-to-five-day probe of a Normal child: can sleep from about 11:00 on day 1, tired at 18:30, health rises during the day (2.91 → 2.98 → 3.08 → 3.22), a full night repays 86% of the debt, a long day after a 6-hour night grows the debt while playing.
- `sleep_test.gd`: all pass (6 h every night settles at 4.4 h of debt, as v1).
- The tests the change touches were run (not the parity test). All pass except two in `calibration_test.gd` and two in `happiness_test.gd`, which read the guideline plan's happiness at day 21 (at least 0.9): 0.84 and 0.82 now, 0.93 and 0.91 before. Traced day by day: the new model is slightly happier every day up to day 18, and then the old run happened to fit a fifth meal before bed (the scripted player looks for "I'm hungry!" every 30 minutes). Not a sleep-model effect; the limits were not changed. Question for the user and the team: let the scripted player eat when hungry just before bed, or keep the test as it is.
- **"Short sleep must not pay in real time" fails narrowly:** 55.7 XP per real hour with 6 h nights against 205.2 with 10.5 h (27%; the rule asks for less than 25%; v1 1%). Cause: the debt that counts now rises during a long day and falls hour by hour during sleep, and with decision 92 every rise in health gives XP, so each recovery night earns some XP. Without the late part counting as debt it was 10.5 XP per real hour (6%), but then the debt would not move during the day. Question for the user: keep the dynamic debt and accept 27% (or loosen the limit), count the late need only for tiredness, or give no XP while asleep.
- Short sleep (scenario test): Sleep 0.45 and health 3.71 at day 21 (v1 0.45 and 3.79; before this milestone 0.45 and 3.70).
- Updated tests for the new rules: `clock_test.gd`, `health_xp_test.gd`, `measures_test.gd`, `offline_sleep_test.gd`, `interface_test.gd`, `scenery_test.gd` (they put the avatar to sleep with debt, or checked the once-per-sleep health bar).

## Still to check

The team (Pessoa 2, Pessoa 4): the placeholders and decisions 93 to 97; `documentation/milestone10_calibration.md` was written with v1 sleep (the parity test was not run again). A real phone.
