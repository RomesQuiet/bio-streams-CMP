# Milestone 4 — Build the new health system

Goal: build the whole health calculation from `CLAUDE.md` ("Health calculation (working plan)"). The team is still researching many values (document "Plano de Investigação e Testes: Sistema de Saúde"). Every value that is not decided yet gets an **average placeholder** (the middle of the plausible range, or a value derived from the first sources) in `data/config.json`, so the team can change it at any time without touching code. After this milestone the system is **refined**: the team replaces the averages with researched values and runs the tests again.

Read `CLAUDE.md` first. After each task, say how to run it and what to check. Keep it simple: only what is listed here.

**Important: the old Milestone 3 was already built.** The first version of Milestone 3 included a first version of the health system (action log, habit scores, slow body states, measures, power-mean health, calibration scenario tests and a debug view), as well as the creation screen and the starting values. That code exists in the project. Milestone 4 does **not** rebuild it: it **audits it and brings it in line with this document**. The main differences to fix are:
- k is 5 (the old code used a placeholder 4).
- The health bar speed `alpha_bar` is 0.37 (the old code used 0.3).
- The habit-change cost uses the team model (Task 5) instead of the old placeholder cost per difficulty.
- Habit values are updated by running the real-day update k times, not by multiplying a rate by k.
- Mood is on a 0 to 100 scale.
- All values are in the `health` block of `data/config.json` with the key names, status and owner given here.
- There is no death, only failure.
- The scoring day, sleep debt and k, and the debug CSV log are new.

## Rules for every value
- **No game number in a script.** Every number below lives in `data/config.json` under a `health` block, with the key names given here (the team uses these names in its research tables).
- Each value has a short note next to it: `"status": "placeholder" | "team decision" | "from source"`, and the owner (Pessoa 1 to 4, as in the research plan). Example: `"r": {"value": 0.8, "status": "placeholder", "owner": "Pessoa 2"}`.
- Changing a value in `config.json` must change the game **without any code change**. In debug builds, add a key to **reload the config** while the game is running.
- If two rules seem to conflict, do not choose on your own: write it down and ask the user.

## Values to use

**Team decisions (already decided)**

| Key | Value | Note |
|---|---|---|
| `k` | 5 | Body speed multiplier: how much faster health and the body change compared with the real-life average. Same k for habits (no separate k). |
| `death_enabled` | false | There is no death, only failure. |
| `habit_days_to_95` | 66 | Real days for a habit to reach 95% of its usual level (Lally and colleagues 2010, median; a reference with a lot of variation). |
| `habit_cost.T` | 0.10 | Tolerance: changes smaller than this cost nothing. |
| `habit_cost.alpha` | 200 | Penalty intensity (10 before the gradual-vs-sudden solution, see Task 7). |
| `habit_cost.gamma` | 2 | Sensitivity to the deviation (1.5 before): two small steps cost less than one big one. |
| `habit_cost.P_max` | 100 | Maximum penalty of one habit per avatar day (points on the 0 to 100 mood scale); no cap on the day's total (10 on the total before). |
| `habit_cost.alpha_factor` | sleep 0, activity 1, strength 1, screens 1 | Factor on alpha per habit: moving to the recommended sleep has no mental cost. |
| `habit_cost.lambda` | 0.04 | Speed at which rootedness R grows (per real day, only while the habit is stable). |

**Averages until the research is finished**

| Key | Average value | How it was chosen | Owner |
|---|---|---|---|
| `score_window` | `"wake_to_wake"` | One scoring day = from one wake-up to the next (one sleep plus the awake period = 24 avatar hours). Open team decision. | Pessoa 4 |
| `k_applies_to_sleep_debt` | false | Open team decision; debt changes once per avatar day. | Pessoa 4 |
| `sleep_range.child` | [9, 12] | CDC / AASM | Pessoa 2 |
| `sleep_range.teen` | [8, 10] | CDC / AASM | Pessoa 2 |
| `sleep_recommended.child` / `.teen` | 9 / 8 | Lower limit of each range (Task 6.5: with the midpoint, sleep inside the range still built up debt) | Pessoa 2 |
| `sleep_zero_at` | 4 | Sleep score 0 at 4 h or less, linear up to the lower limit | Pessoa 2 |
| `sleep_over_penalty_per_h` | 0.1 | Score falls 0.1 per hour above the upper limit | Pessoa 2 |
| `r` | 0.8 | Debt halves in about 3 days without new debt (r^n = 0.5) | Pessoa 2 |
| `debt_max` | 10 | Sleep measure = sleep score × (1 − debt ÷ debt_max), never below 0 | Pessoa 2 |
| `activity_target_min` | 60 | CDC: 60 min/day of moderate-to-vigorous activity | Pessoa 3 |
| `strength_days_target` | 3 | CDC: 3 days per week | Pessoa 3 |
| `screens_full_until_h` / `screens_zero_at_h` | 2 / 6 | Australian guidelines (2 h); 6 h is a game choice | Pessoa 3 |
| `activity_intensity` (in `activities.json`) | cardio and muscle strength = "moderate_vigorous" | Until the MET values from the Youth Compendium are in | Pessoa 3 |
| `kcal_per_hour` (in `activities.json`) | cardio 300, muscle strength 200 | Record only (no food yet) | Pessoa 3 |
| `enjoyment_full_at_h` | 1 | Enjoyment score e = entertainment hours ÷ 1, at most 1 | Pessoa 3 |
| `mood_speed` | 0.3 | Mood moves 30% of the way to its target per avatar day | Pessoa 3 |
| `fitness_k_down` | 0.0056 per real day | 21% VO₂max loss after 6 weeks without training (young footballers) | Pessoa 1 |
| `fitness_k_up` | 0.0056 per real day | Same as k_down until a source is found | Pessoa 1 |
| `muscle_k_up` / `muscle_k_down` | 0.0056 / 0.0056 | Same as fitness until a source is found | Pessoa 1 |
| `weight_score` | 1 for z in [−1, +1], linear to 0 at ±3 | WHO cut-offs | Pessoa 1 |
| `physical_mix` | fitness 1/3, muscle 1/3, weight 1/3 | Equal thirds | Pessoa 1 |
| `combine.p` | 0.5 | Between the ordinary and the geometric mean | Pessoa 2 (calibration) |
| `combine.weights` | 1/3 each | Equal | Pessoa 2 (calibration) |
| `alpha_bar` | 0.37 | Health bar makes 90% of the way to the target in 5 avatar days ((1 − α)^5 = 0.1) | Pessoa 4 (game choice) |
| `start_R` per difficulty | Easy 0.5, Normal 0.5, Hard 0.2, Very hard 0.8 | Low habit-change cost on Hard, high on Very hard | Pessoa 4 |

Two different "alpha" exist: `habit_cost.alpha` (penalty intensity) and `alpha_bar` (health bar speed). Keep the names separate in code.

## Task 0 — Audit what Milestone 3 already built (no changes yet)
- Read the current code: `GameState`, `Config`, `Clock`, `Activities`, `SaveGame`, `data/config.json`, `data/activities.json`, the health scripts and the tests.
- Write a short table in `documentation/milestone4_audit.md`: for each part of this milestone (Tasks 1 to 8), one line saying **exists and matches**, **exists but differs** (say how) or **missing**. Include every health-related number found in scripts (these must move to config).
- Ask the user to confirm the table before changing anything.
- Done when: the user has seen the table and approved it.

For Tasks 1 to 8, **reuse the existing code and change it to match this document**. Do not rewrite from scratch, and do not keep two versions of the same rule. Delete what becomes unused. Old saves must still load.

## Task 1 — Config and data
- Add (or move into) the `health` block to `data/config.json` with every key above, and the activity fields to `data/activities.json`.
- Add the debug **reload config** key.
- Done when: no health number is left in any script, the game starts with the new config, and changing `k` in the file and pressing reload changes the next day's calculation.

## Task 2 — Activity log and the scoring day
- Log every activity: type, avatar start time, avatar hours actually done (Stop counts only the time done), intensity and calories. Keep the last 7 scoring days.
- A scoring day follows `score_window` (from one wake-up to the next). The calculation runs when any sleep ends, including naps and the 0-hour rule.
- Done when: a test with a known log returns the right totals per scoring day (sleep hours, activity minutes, strength days in the last 7, entertainment hours).

## Task 3 — Habit scores (0 to 1)
- Sleep s: 1 inside the age range; linear from 0 at `sleep_zero_at` to 1 at the lower limit; above the upper limit it falls by `sleep_over_penalty_per_h` per hour.
- Activity a = moderate-to-vigorous minutes ÷ `activity_target_min`, at most 1.
- Strength w = strength days in the last 7 ÷ `strength_days_target`, at most 1.
- Screens c = 1 up to `screens_full_until_h`, linear to 0 at `screens_zero_at_h`. For now all entertainment counts as recreational screen time (sedentary and active entertainment come later).
- Enjoyment e = entertainment hours ÷ `enjoyment_full_at_h`, at most 1.
- Done when: tests check each score at the limits (for example sleep 4 h, 8 h, 9 h and 12 h for a teenager).

## Task 4 — Slow body states
Slow states that use k are updated by running the **real-day update k times** per avatar day (this keeps the speed correct and never overshoots).
- **Sleep debt:** new = old × r + (recommended − hours slept), never below 0. Once per avatar day (k only if `k_applies_to_sleep_debt` is true).
- **Fitness:** per real day, fitness += k_up × a × (1 − fitness) − k_down × (1 − a) × fitness. Run k times.
- **Muscle:** the same formula with w instead of a. Run k times.
- **Weight z-score:** stays at the difficulty's starting value (no food yet).
- **Usual level H of each habit** (sleep, activity, strength, screens): per real day it moves toward today's intensity A by the rate that reaches 95% in `habit_days_to_95` days (rate = 1 − 0.05^(1/66), about 0.044). Run k times. Intensity A (0 to 1): sleep hours ÷ 12; activity minutes ÷ 60; strength days in the last 7 ÷ 7; screen hours ÷ 6 (each at most 1).
- **Rootedness R of each habit:** per real day R += lambda × (1 − R), only on days when the habit is stable (|A − H| at most T). Run k times. Starts at `start_R` of the difficulty.
- Done when: tests show fitness rising with daily activity and falling slowly without it, debt growing with short sleep and halving in about 3 avatar days with enough sleep, and H reaching 95% of a new habit after about 66 ÷ 5 ≈ 13 avatar days.

## Task 5 — Habit change cost and mood (team model)
- Mood is kept on a 0 to 100 scale.
- For each habit: D = max(0, |A − H| − T), and P = min(P_max, alpha × alpha_factor × R^gamma × D^gamma). The day's total cost is the sum over the habits, with no cap (changed after Task 7; the total was capped at P_max before).
- Mood target = 100 × average of s, a, c and e. Then: mood = mood + mood_speed × (target − mood) − total cost, kept between 0 and 100.
- Done when: a test on Very hard shows that changing activity from 0 to 1 in one day costs about 104 points, capped at P_max 100 (R 0.8, D 0.9; about 6 with the first values), and changing by 0.2 per day costs little (about 1.3).

## Task 6 — Measures and health
- Physical = physical_mix of fitness, muscle and the weight score.
- Sleep = s × (1 − debt ÷ debt_max), never below 0.
- Mental = mood ÷ 100.
- C = (w_P · P^p + w_M · M^p + w_S · S^p)^(1/p). Target health = 1 + 4 × C.
- Displayed health: health += alpha_bar × (target − health), once per scoring day. The health bar shows it. XP keeps the Milestone 1 placeholder rule, driven by the new health.
- **Failure** at minimum health: only show a placeholder message for now (the effect is not decided). No death.
- Make sure the Milestone 2 fixed per-hour effects of exercise and entertainment are gone (replaced by this system). Keep `calories_spent` as a record.
- Old saves must still load: missing new values use the Normal starting values.
- Done when: after each sleep the measures panel and the health bar change following the formulas, and starting health on each difficulty still matches Milestone 3.

## Task 7 — Simulation tests (the team's scenarios)
Update the calibration tests from Milestone 3 so they match the scenarios below, then run them. A headless test that simulates many avatar days with fixed habits, on each difficulty, and prints health per day. Pass criteria come from the research plan (Phase 1):

| Scenario | Pass criterion |
|---|---|
| Athlete who sleeps 5 h a night | Health never goes above 3 |
| Sedentary player who sleeps well | Health stays below the perfect player but does not reach the minimum |
| Perfect player | Reaches 5, but slowly (not in the first avatar days) |
| Gradual vs sudden change | The gradual change gives better mental health. Read as in the concept (after Task 7): a 10-day change never lets mental fall below its start; on Normal and Very hard the sudden change makes it fall; a 40-day change is not the best plan |
| Player who ignores everything | Reaches the minimum, but not at once |
| Very hard difficulty | Recovery is possible |

- Also print the same run with p = 0.2, 0.5 and 1 so the team can compare.
- If a scenario fails, **do not change the values on your own**. Report which scenario failed, show the numbers, and propose values for the team to decide.
- Done when: one command runs all scenarios and prints pass or fail for each.

## Task 8 — Debug mode, CSV log, check and publish
- Debug panel (debug builds only; extend the one from Milestone 3): habit scores, debt, fitness, muscle, z-score, every H and R, mood, the cost of the day, the three measures, target and displayed health.
- Write one CSV line per scoring day to `user://health_log.csv` (debug builds only), so the team can compare the game with its spreadsheet simulation. Explain how to find the file on the Mac.
- Run all tests (Milestones 1 to 4). Play a few avatar days with the debug speed on each difficulty.
- Export to `docs/`, check the web build (saving after a reload), then commit and push.
- Done when: the published game uses the new health system, and the debug build writes the CSV log.

## Out of scope for this milestone
Final researched values (the refinement comes after this milestone), food and energy balance (weight stays fixed), sedentary and active entertainment, the effect of exercise on sleep need, minigames, commitment goals, the failure effect, avatar state art, translations, settings contents, server and accounts.
