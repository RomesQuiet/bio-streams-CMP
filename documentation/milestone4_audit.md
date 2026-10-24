# Milestone 4 — Audit of the Milestone 3 code (Task 0)

This table compares what the code did at the end of Milestone 3 with `MILESTONE_4.md` (approved by the user). Decisions: points 1 to 3 below approved as proposed; the weight score keeps the t² curve; Milestone 3 saves load, Milestone 1 and 2 saves stay ignored.

**Progress:** Task 1 done (health block, activity fields, F6 reload, no health number in scripts).

**Legend:** ✅ exists and matches · 🟡 exists but differs · ❌ missing

## Tasks 1 to 8

| Task | Part | Status | What the code does now, and what has to change |
|---|---|---|---|
| 1 | `health` block in `data/config.json` | 🟡 | The health values exist, but they are spread over 7 sections: `health_formula`, `physical_measure`, `recommended_sleep`, `habits`, `body_states`, `measures_from_body` and `difficulties`. They have to move into one `health` block with the M4 key names and a `status` and `owner` for each value. |
| 1 | Activity fields in `activities.json` | 🟡 | Cardio is 500 kcal/h and strength 300 kcal/h (as `effects_per_hour.calories_spent`). M4 wants `kcal_per_hour` 300 and 200, and `activity_intensity` = `"moderate_vigorous"`. There is no intensity field yet. |
| 1 | Debug key to reload the config | ❌ | Config is read once, when the game starts. |
| 1 | No health number in a script | 🟡 | Only one number: `habits.gd` turns hours into minutes with `* 60.0`. It is a unit conversion, not a health value; I will use the Clock's `MINUTES_PER_HOUR`. Every other health number is already in config. |
| 2 | Activity log: type, start time, hours done | ✅ | `Habits.entries`. Stop counts only the time done. Saved with the game. |
| 2 | Log intensity and calories | ❌ | Entries have no intensity or calories fields. |
| 2 | Scoring day = `wake_to_wake` | 🟡 | The scores use the last **24 avatar hours** before the sleep ends, not "since the last wake-up". This is almost always the same, because one sleep plus the awake period is 24 h. It differs after a nap or the 0-hour rule. The log keeps 7 × 24 avatar hours, not "7 scoring days". |
| 2 | Calculation when any sleep ends (naps, 0-hour rule) | ✅ | `Habits._score_sleep()` runs at the end of every sleep and when the 0-hour rule starts a new day. |
| 3 | Sleep score s | ✅ | 1 inside the range, linear from 0 at 4 h, −0.1 per hour above the range. Only the key names change. |
| 3 | Activity a, strength w, screens c | ✅ | Same formulas: ÷ 60 min; strength days in the last 7 ÷ 3; 1 up to 2 h, then 0 at 6 h. Strength days use 24-hour blocks, not scoring days. |
| 3 | Enjoyment e | ❌ | No enjoyment score. Entertainment only counts as screen time. |
| 4 | k run as **k real-day updates** | 🟡 | k = **4** (M4: **5**), and it multiplies the rate (`rate × k`, capped at 1). It is not run as k separate updates. |
| 4 | Sleep debt | 🟡 | `old × r + (recommended − slept)`, with r **0.7** (M4: 0.8). "Recommended" is the range **minimum** (M4: the midpoint, 10.5 / 9). k is not applied to it (matches `k_applies_to_sleep_debt` = false, but that key doesn't exist yet). |
| 4 | Fitness and muscle | 🟡 | Same formula, but k_up **0.05** and k_down **0.02** per avatar day × k. M4: 0.0056 per real day, run k times. ⚠️ Fitness will rise much more slowly than now. |
| 4 | Weight z-score fixed | ✅ | Stays at the difficulty's value. |
| 4 | Usual level H of each habit | 🟡 | Stored as the **habit score** (0 to 1). It moves k × 0.05 of the way each avatar day. M4: H is the **intensity** A (sleep h ÷ 12, minutes ÷ 60, strength days ÷ 7, screen h ÷ 6), with rate 1 − 0.05^(1/66), run k times. |
| 4 | Rootedness R | ❌ | Doesn't exist. `start_R` per difficulty is needed. |
| 5 | Mood 0 to 100 | 🟡 | Mood is 0 to 1. Its target is the average of s, a and c (no enjoyment). |
| 5 | Habit-change cost (team model) | 🟡 | A placeholder model: `habit_change_cost` per difficulty (1 / 0.5 / 2) × 0.1 × the sum of the score jumps above usual + 0.1. It lowers **mental**, not mood. M4: D, P, P_max, R with T, alpha, gamma and lambda, and the cost lowers **mood**. The old keys (`habit_change_cost`, `habit_change_free_step`, `habit_change_penalty`) will be deleted. |
| 6 | Physical = mix | ✅ | Equal thirds of fitness, muscle and weight score. The weight score uses the **t² curve** (`curve_power` 2), which you chose to keep. M4's table says linear. |
| 6 | Sleep = s × (1 − debt ÷ debt_max) | 🟡 | Uses `1 − 0.05 × debt`, which is debt_max = **20**. M4: debt_max **10**. |
| 6 | Mental = mood ÷ 100 | 🟡 | Mental = mood − the habit cost (both 0 to 1). |
| 6 | C (power mean) and target = 1 + 4 × C | ✅ | p 0.5 and equal weights. Target = health_min + (health_max − health_min) × C, which is 1 + 4C. |
| 6 | Displayed health, `alpha_bar` | 🟡 | Moves once per sleep with **0.3** (M4: **0.37**). The key is `daily_alpha`. |
| 6 | XP from the new health | ✅ | Health changes give or take XP. Hourly XP uses the displayed level. |
| 6 | Failure message at minimum health | ❌ | Nothing happens at minimum health. |
| 6 | No death (`death_enabled` false) | 🟡 | There is no death code. The `death_enabled` key doesn't exist yet. |
| 6 | Per-hour effects gone, calories kept | ✅ | Exercise only adds calories (a record). Entertainment and sleep have no per-hour effects. |
| 6 | M3 saves load with defaults for new values | 🟡 | M3 saves load, but there are no defaults for R or the H in intensity units. Mood 0–1 in old saves must be scaled to 0–100. M1 and M2 saves stay ignored (confirmed). |
| 6 | Starting health still matches M3 | ✅ | Easy 4.00, Normal 3.00, Hard 1.98, Very hard 1.26 (from the starting measures, not from the new formulas). |
| 7 | Simulation tests | 🟡 | `tests/calibration_test.gd` has 4 scenarios on Normal and Very hard, for a child and a teenager. M4 has 6 scenarios on each difficulty, plus the same run printed with p = 0.2, 0.5 and 1. |
| 8 | Debug panel | 🟡 | Shows the scores, debt, fitness, muscle, z, H, mood, measures, target and displayed health. It is missing R, the cost of the day and enjoyment. |
| 8 | CSV log `user://health_log.csv` | ❌ | Doesn't exist. |
| — | Tests for Milestones 1 to 3 | ✅ | 9 test files: 236 checks pass. The calibration test has 3 known failures with p = 0.5. |

## Health numbers found in scripts

| File | Number | What it is | What to do |
|---|---|---|---|
| `scripts/autoload/habits.gd` | `60.0` | Minutes per hour (`hours * 60.0`) | Use `Clock.MINUTES_PER_HOUR` |

No other health number is in a script. The clamps to 0 and 1 and the loop over the 3 measures are limits of the formulas, not tunable values.

## Gaps and conflicts I need you to decide (I won't choose on my own)

1. **Starting H per difficulty.** M4 changes H to intensity units (sleep h ÷ 12, etc.) but gives no starting values. Proposal: derive them from each difficulty's starting habits, as placeholders. For example, Normal sleep 0.5 means a score of 0.5, which for a child is 6.5 h, so H = 6.5 ÷ 12 ≈ 0.54.
2. **Age group key.** M4 uses `sleep_range.teen`, but the game saves the age group as `"teenager"`. Proposal: use the key `teenager` in config, so Milestone 3 saves keep working.
3. **Starting values per difficulty.** M4 doesn't say where the starting measures and body states (`difficulties`) go. Proposal: move them into the `health` block as `health.difficulties`, each with status "placeholder" and owner Pessoa 4. `habit_change_cost` is replaced by `start_R`.
4. **Very hard start_R 0.8.** With the team model, a Very hard avatar that changes everything on day 1 loses up to 10 mood points. Its mood starts at 5 (0.05 × 100), so it hits 0 at once. That is what the team wants ("high cost"), but I'm flagging it.
5. **Fitness speed.** With 0.0056 per real day and k = 5, one avatar day of full activity closes only about 2.8% of the gap to 1. Health will rise much more slowly than in Milestone 3. The calibration scenarios in Task 7 will show whether "perfect player reaches 5" still happens.
6. **Total cost limit.** M4 says the day's total cost is the sum over the habits, at most P_max. M4 itself marks this as a placeholder rule, so I'll flag it again when I build it.
