# Milestone 10 — Task 0: replacement plan

Date: 25 October 2026. Written after reading every script in `scripts/`, `data/*.json`, `scenes/main.tscn` and every test in `tests/`. Nothing has been changed yet. The decisions in `MILESTONE_10.md` (user, 25 Oct 2026) are applied here.

## Before Task 1

- The working tree already has **uncommitted changes from Milestone 4** (CLAUDE.md, MILESTONE_4.md, config.json, docs/, game_state.gd, two tests and the new v1 and Milestone 10 documents). They should be committed first, so Milestone 10 starts from a clean, known state.

## How the new code is organised

v1 asks for one module per part of the body, each reading the others only through their outputs, with the global state in the Autoload. Plan:

- **All state variables stay in `GameState`** (one place to save, debug and log). GameState no longer calculates anything; it only holds values, the choices, XP and the start of a new avatar.
- **Each v1 module is its own script** in a new folder `scripts/health/`, with functions that read GameState, update only the variables that module owns, and read every number from `Config`. They are not autoloads (no own state), so tests can call them directly.
- **A new autoload `Simulation`** (`scripts/autoload/simulation.gd`) receives avatar time from the Clock, cuts it into fixed steps of `time.step_avatar_min` (5 avatar minutes), and for each step calls the modules in the v1 order. It also handles the events (meal, start and end of an activity, new day after sleep). This replaces the once-per-day `GameState.update_body_states()`.
- Time (`Clock`) and saving (`SaveGame`) stay in their own scripts, as before.

| v1 module | Owner script | State it owns (in GameState) |
|---|---|---|
| Clock | `scripts/autoload/clock.gd` (kept, changed) | avatar time, phase, day length |
| Body size | `scripts/health/body_size.gd` + `scripts/health/who_tables.gd` | body age, height, z |
| Energy and weight | `scripts/health/energy.gd` | weight, hunger, energy spent, kcal eaten and spent in the last 24 h, U, calories spent (record) |
| Training | `scripts/health/training.gd` | fitness, strength, cardio and strength recovery, overreaching O, capacity used today |
| Sleep | `scripts/health/sleep_model.gd` | sleep debt, Sleep measure, d, night quality, tiredness, hours awake |
| Habits (diet) | `scripts/health/diet.gd` | Q, C, A |
| Mood | `scripts/health/happiness.gd` | Happiness, fun, screen excess |
| Health | `scripts/health/health_model.gd` | Physical, target health, displayed health, failure timers |
| Risk | `scripts/health/risk.gd` | risk index R, hidden damage (debug only, decision 9) |
| Progress | `scripts/health/progress.gd` | XP, hours at high health |
| Avatar messages | `scripts/ui/main.gd` + `scripts/avatar/avatar.gd` | none (reads the states) |
| Action log | `scripts/autoload/habits.gd` (kept, reduced) | log entries for the last 7 avatar days and 24-hour averages |

## File by file

### Autoloads

| File | Plan | What changes |
|---|---|---|
| `config.gd` | **Kept** | No change (F6 reload, `get_value`, `is_placeholder` stay). |
| `clock.gd` | **Changed** | Day scale from config (42 avatar min per real min). New can-sleep rule (debt ≥ 1 h or awake ≥ 6 h) and the latest wake time (maximum + min(debt, 2 h)). `avatar_time_passed` now goes to `Simulation` instead of `GameState.apply_avatar_hours`. Conversion functions and the sleep-to-day rule are unchanged. |
| `game_state.gd` | **Changed (mostly rewritten)** | Keeps choices, XP/level getters, `to_dict`/`from_dict`, `start_new_avatar`. **Deleted:** `update_body_states`, `habit_change_costs`, `total_habit_cost`, `mood_target`, `_train`, `real_days_per_avatar_day`, `_update_measures`, `physical_from_body`, `weight_score`, `apply_effects`, `mental`, `mood`, `muscle` (renamed `strength`), `usual_habits`, `rootedness`, `habit_costs`, `tired` (becomes a value from tiredness). **Added:** the v1 state variables listed above. Starting values come from `health.difficulties` (v1 table, Very hard happiness 0.30), and the starting weight is calculated from z. |
| `activities.gd` | **Changed** | `effects_per_hour` and `kcal_per_hour` are removed; each option has `mety` instead. New activity **eat** (0.5 h, decision 2). New options **screens** and **football** replace `entertainment` (decision 4). Activities report start, progress and end to `Simulation`. Meals are only allowed while awake. |
| `habits.gd` | **Changed (reduced)** | Keeps the action log (type, start time, hours done, intensity, kcal), now with meal entries and minutes per type. **Deleted:** scoring days, `calculate_scores`, the five habit scores, `intensities`, `end_scoring_day`. **Added:** 24-hour sums and averages (cardio and football minutes, strength minutes, screen minutes, exercise minutes, kcal eaten and spent) for training, fun, screen excess and U. |
| `health_log.gd` | **Changed** | New header and row with every v1 state variable. Question A below: one line per avatar hour or per day. |
| `save_game.gd` | **Changed** | `SAVE_VERSION` 1 → 2, so a Milestone 4 save is ignored and the creation screen opens (decision 6; this check already exists). Also saves `Simulation` (the part of a 5-minute step not yet run). |
| `simulation.gd` | **New** | The 5-minute update loop and the event handling. |

### Health scripts (new folder `scripts/health/`)
All new: `who_tables.gd`, `body_size.gd`, `energy.gd`, `training.gd`, `sleep_model.gd`, `diet.gd`, `happiness.gd`, `health_model.gd`, `risk.gd`, `progress.gd`. The power mean (`health_from_measures`) moves from GameState to `health_model.gd`, reused with Physical, Happiness and Sleep.

### UI and avatar

| File | Plan | What changes |
|---|---|---|
| `scripts/ui/main.gd` + `scenes/main.tscn` | **Changed** | Eat button opens Healthy meal / Fast-food meal (and Skip when hungry). Entertainment shows Screens / Football. "Mental" label and bar become **Happiness**. The physical box shows weight, height, BMI-for-age z, fitness, strength, diet quality and calories spent. New speech: "I'm hungry!", "I'm not sleepy.", "I'm tired" from tiredness, failure from the timers. The sleep info text uses the new day scale (no code change; it reads the Clock). |
| `scripts/avatar/avatar.gd` | **Changed** | Placeholder looks for the v1 states (hungry, tired, sad, thin, overweight, muscular, muscular with fat): simple changes of colour and width of the egg shape. An "eat" animation. |
| `scripts/ui/debug_panel.gd` | **Changed** | Shows every v1 state, the three measures, target and displayed health, failure timers, risk and damage. |
| `scripts/ui/creation.gd` | **Kept** | No change (age group, sex, difficulty and name already exist). |

### Data

| File | Plan |
|---|---|
| `data/config.json` | `time.day_avatar_minutes_per_real_minute` 28 → 42 and new `time.step_avatar_min`. The `health` block is replaced by the v1 groups (`body`, `energy`, `appetite`, `meals`, `deficit`, `train`, `minigame`, `diet`, `sleep`, `mood`, `fail`, `risk`, `xp`, and `health` with p, weights and `alpha_bar`), each value with status and owner. **Deleted:** `habit_cost`, `habit_intensity`, `habit_days_to_95`, `habit_share_reached`, `score_window`, `k_applies_to_sleep_debt`, `sleep_zero_at`, `sleep_over_penalty_per_h`, `r`, `debt_max`, `activity_target_min`, `strength_days_target`, `screens_*`, `enjoyment_full_at_h`, `mood_*`, `fitness_k_*`, `muscle_k_*`, `weight_score`, `physical_mix`, `failure_at_health`, `log` (replaced), the old `xp` rule (`loss_per_avatar_hour`, `low_health_max`; v1 has no hourly loss at low health) and `thresholds` (replaced by the v1 avatar image table). `measures.hunger_start` becomes kcal. |
| `data/activities.json` | `mety` per option, new `eat` activity, Screens and Football options. |
| `data/foods.json` | **New**: healthy meal and fast-food meal (portion factor, satiety, x). |
| `data/who_bmi_for_age.json`, `data/who_height_for_age.json` | **New**: WHO 2007 tables, both sexes, 5 to 19 years by month, with the source written in the file. |

### Tests

| Test | Plan |
|---|---|
| `clock_test.gd` | **Changed**: new day scale (14 h = 20 real min, 19 h ≈ 27.1 min), can-sleep rule, latest wake time. |
| `activities_test.gd` | **Changed**: eat, screens, football, no meals while asleep. |
| `save_test.gd` | **Changed**: every new value saves and reloads; a version-1 save opens the creation screen. |
| `config_test.gd` | **Changed**: checks the new groups and that no number is left in `scripts/health/`. |
| `creation_test.gd` | **Kept**. |
| `difficulty_test.gd` | **Changed**: v1 starting values (Normal boy of 10 ≈ 2.91; Very hard higher than 1.35 and still the lowest). |
| `habits_test.gd` | **Changed**: the action log and its 24-hour sums (no scores). |
| `body_test.gd` | **Deleted**, replaced by `who_test.gd`, `food_test.gd`, `energy_test.gd`, `training_test.gd`, `sleep_test.gd`, `happiness_test.gd`. |
| `measures_test.gd` | **Changed**: Physical, target health, health bar after each sleep, failure timers. |
| `health_xp_test.gd` | **Changed**: v1 XP rule. |
| `health_log_test.gd` | **Changed**: new columns. |
| `calibration_test.gd` | **Rewritten** in Task 10 (v1 scenarios and the Bases fundamental check). |
| New | `simulation_test.gd`: same result whatever the frame size (one big frame = many 5-minute steps). |

## Small choices made in this plan (tell me if you disagree)

1. **A meal counts when it ends.** (Changed in Task 3: first planned as spread over its 0.5 h.) Its kcal and its effect on hunger are applied when the meal ends, in proportion to the part eaten, so Stop gives a partial meal. The difference is at most half an hour of hunger growth, and it keeps the code simple and exact. Q, C, A and the happiness jump of the meal are applied at the same moment.
2. **Starting body age** = the reference age of the group (child 10 years, teenager 14 years, as in CLAUDE.md).
3. **Starting weight** = the weight that gives the difficulty's z at the starting height (WHO tables), so it depends on sex and age.
4. **Schofield band:** 3 to 10 years up to 9 years 11 months, then 10 to 18 years up to the cap (18 years 11 months for teenagers).
5. **"Tired"** is no longer set by the Clock when the day ends; it comes from v1 tiredness (≥ 0.5). The 0-hour rule still counts as 0 h of sleep and still shows the sleep recommendation.
6. **XP at low health:** v1 has no hourly XP loss at low health, so that rule is deleted. XP is still lost when health falls.

## Approval

**Approved by the user on 25 October 2026**, with the proposals for A (CSV per avatar hour) and B (English only; translations in a later milestone). The six small choices above are accepted.

## Questions for the user (answered)

A. **CSV log:** one line per **avatar hour** (24 lines per avatar day, shows how hunger, happiness and weight move within a day) or one line per **avatar day** (smaller file, easier to compare with a daily spreadsheet)? Proposal: per avatar hour.

B. **Translations:** the `translations/` folder is empty and every text in the game is written in English in the scenes and scripts. Milestone 10 Task 7 asks to rename Mental to Happiness "in translations pt and en". Proposal: rename it in the English text only, and leave the translation system (pt and en CSV) to its own milestone.
