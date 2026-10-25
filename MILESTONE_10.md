# Milestone 10 — Food and the new health system (Architecture v1)

Goal: make **food a real activity** (the Eat button works: healthy food or fast food, hunger, meals) and then **rebuild the whole health calculation** following `documentation/health_calculation_architecture_v1.md` ("v1"). The number 10 (not 5) shows how big the change is: this milestone replaces the Milestone 4 health system instead of adjusting it.

Read `CLAUDE.md` and the v1 document first. After each task, say how to run it and what to check. Keep it simple: only what is listed here. "Bases fundamental" has priority over v1; if they seem to disagree, stop and ask the user.

**What changes compared with Milestone 4**
- Food exists: the avatar gets hungry, eats healthy food or fast food, and its weight changes from energy eaten minus energy spent.
- The body grows (body age, height from WHO) and weight status is the real WHO BMI-for-age z-score.
- **k = 10** (was 5) and it applies to sleep debt too. Happiness is not sped up.
- The game updates every **5 avatar minutes**, not once per avatar day.
- v1 health becomes the target health; the slow health bar (`alpha_bar`) is kept.
- **Mental becomes Happiness**, with its own baseline and events. The Milestone 4 mood, habit-change cost (T, alpha, gamma, P_max, H, R) and daily habit scores are **deleted**.
- Physical comes from weight, fitness, strength and diet quality, with penalties for eating too little (U) and training too much (O).
- Health uses the power mean with **p = 0.5** (was 0.2).
- A day is **20 real minutes** (was 30).
- Failure uses time windows (health below 1.3 for 24 h, happiness below 0.10 for 12 h).

## Rules for every value
- **No game number in a script.** Every number of v1 lives in `data/config.json`, with the names from the v1 "Parameters" table (`group.name_unit`, e.g. `sleep.debt_recovery_tau_days`). Each time constant says whether it is **body time** (× k) or **clock time**.
- Each value keeps the Milestone 4 note format: `{"value": ..., "status": "placeholder" | "team decision" | "from source", "owner": "Pessoa 1 to 4" or "team"}`. Values with a source in v1 are `"from source"`; "Design" values are `"placeholder"`.
- The WHO BMI-for-age table (both sexes, 5 to 19 years, by month: L, M, S, SD2, SD3) and the WHO height-for-age table go in their own files in `data/` (for example `data/who_bmi_for_age.json`, `data/who_height_for_age.json`), copied from the WHO site with the source written in the file.
- The F6 debug reload of `config.json` keeps working.
- If v1 does not say something, use a placeholder and list it in the reply. Do not invent rules.

## Decisions (user, 25 Oct 2026)
These are not written in v1 or Bases fundamental; the user decided them.

| # | Question | Decision |
|---|---|---|
| 1 | v1 calculates health directly ("Instant"). Keep the slow health bar? | **Yes, keep it.** v1 health is the **target health**; the displayed health bar moves toward it with `health.alpha_bar` (0.37, placeholder) once per avatar day when a sleep ends, as now. Failure and XP use the displayed health. |
| 2 | Does eating take avatar time? | **Yes.** A meal is an activity of 0.5 avatar hours (placeholder); the buttons are locked like other activities. |
| 3 | Which food options? | Two options only: **Healthy meal** and **Fast-food meal**. |
| 4 | Football and screens as entertainment options | **Yes.** Entertainment gets **Screens** and **Football** (1 avatar hour each, placeholder). |
| 5 | Minigame score until minigames exist | `minigame.default_score` = 1 (performance 1.0), placeholder. |
| 6 | Milestone 4 saves | Do not load (like the Milestone 1 and 2 saves): the creation screen opens. |
| 7 | Very hard starting happiness | **Higher than v1's 0.15, so Very hard is playable.** Placeholder **0.30** (the Hard value), so an abrupt food switch does not cross the failure line (0.10 for 12 h) at once. Very hard starting health is then calculated again (about 1.5 instead of 1.35); the scenario tests check that it is still playable and still the hardest level. |
| 8 | Does the body age keep growing past the chosen age group? | **No.** The body still grows inside its age group (so height rises and BMI-for-age can fall without dieting, v1 Step 2), but body age stops at the end of the group: child at 12 years 11 months, teenager at 18 years 11 months (`body.max_age_child_months` 155, `body.max_age_teen_months` 227, placeholders). The age group, sleep range and BMR band never change during a game. |
| 9 | Diseases | Build only the risk index and hidden damage, shown in the debug panel. No disease stages until the team chooses diseases with a health professional. |

## Task 0 — Plan the replacement (no changes yet)
- Read the current code: `Config`, `Clock`, `GameState`, `Habits`, `Activities`, `SaveGame`, `HealthLog`, `scripts/ui/main.gd`, the debug panel, `data/*.json` and every test.
- Write `documentation/milestone10_plan.md`: for each file, what is **kept**, **changed** or **deleted**, and for each v1 module (Clock, Body size, Energy and weight, Training, Sleep, Habits, Mood, Health, Risk, Progress, Avatar messages) which script will own it. Keep the Milestone 4 rule that time and saving stay in separate scripts.
- Follow the decisions in the table above.
- Done when: the user has approved the plan.

## Task 1 — Config and WHO data
- Replace the Milestone 4 `health` block with the v1 parameters (all groups: `body`, `time`, `energy`, `appetite`, `meals`, `deficit`, `train`, `minigame`, `diet`, `sleep`, `mood`, `health`, `fail`, plus `risk` and `xp`).
- Replace `health.difficulties` with the v1 difficulty starts (z, fitness, strength, Q, C, happiness, debt), with Very hard happiness 0.30 (decision 7). The starting weight is **calculated** from the starting z, the sex and the body age (WHO tables), never written by hand.
- Add the WHO data files and a small loader with a function `z_from_bmi(sex, age_months, bmi)` and its inverse `bmi_from_z(...)` (including the WHO rule above +3 and below −3).
- Delete the Milestone 4 keys that v1 no longer uses (habit cost, mood_speed, habit intensities, scores). Keep `alpha_bar` (decision 1).
- Done when: `tests/config_test.gd` still finds no health number in scripts, and a new `tests/who_test.gd` checks the v1 example (boy 10 y 0 m: L −1.7407, M 16.4433, S 0.10566) and a z → BMI → z round trip.

## Task 2 — Clock and the 5-minute update
- Day = 20 real minutes = 14 avatar hours (`time.awake_avatar_min_per_real_min` 42); night unchanged (5). The sleep-to-day conversion keeps the same rule; update the `Clock` tests for the new scale.
- Add one **update loop** that runs in fixed steps of `time.step_avatar_min` (5) avatar minutes, in the v1 order (Clock → energy → hunger → weight and body → U → training → Physical → happiness → health, failure, risk, XP → messages). Each module gets its own function; nothing runs while paused or closed. With the debug speed, several steps run per frame.
- Body time: each step adds k × 5 avatar minutes of body time to the slow states.
- **Can sleep** rule: only when sleep debt ≥ `sleep.can_sleep_debt_h` or awake ≥ `sleep.can_sleep_awake_h`; otherwise the avatar says "I'm not sleepy." Waking is never later than the maximum + min(debt, 2 h).
- Done when: tests show the same results whatever the frame rate (one big frame = many 5-minute steps), and the can-sleep rule works.

## Task 3 — Food as an activity
- `data/foods.json` with the two options of decision 3: healthy meal (portion = reference ÷ 4 kcal, satiety 1.0, x = 1) and fast-food meal (portion 1.3 × healthy, satiety 0.83, x = 0). Background colour and animation like the other activities.
- The **Eat** button opens its options. Eating is allowed only while awake. A meal removes kcal × satiety from hunger, adds the kcal to "eaten in the last 24 h", and is logged in the action log with its type and kcal.
- **Hunger** (v1 Step 4): every avatar hour, hunger += (0.7 × reference ÷ 24 + 0.3 × energy spent this hour) × (1 + 0.2 × d) × (1 + 0.15 × max(0, −z)). It grows during sleep too.
- "I'm hungry!" in the speech bubble when hunger ≥ 0.8 of a healthy meal and at least 2 avatar hours have passed since the last meal or skip. Add a **Skip** choice when the avatar is hungry (it removes nothing from hunger and resets the 2-hour gap).
- Done when: tests show hunger rising at the right rate, a healthy meal and a fast-food meal changing hunger by the right amount, and the hungry message following the two rules.

## Task 4 — Body size, energy and weight
- Body age += k × avatar hours ÷ 8,760, stopping at the end of the age group (decision 8); height = WHO median height-for-age; BMI = weight ÷ height²; z from the WHO table; weight score w(z) as in v1 Step 2.
- Energy spent per avatar hour = Schofield BMR (by sex and age band) ÷ 24 × METy of what the avatar is doing (sleep 0.95, idle 1.7, screens 1.3, cardio 7.0, football 7.5, strength 5.0). METy goes in `data/activities.json` for each option, replacing `kcal_per_hour`. Sleep never changes the metabolic rate.
- Weight change per avatar hour = k × (kcal eaten − kcal spent) ÷ 7,700.
- Energy deficit penalty U from the last 24 avatar hours (0 below 30%, 1 at 60%).
- Keep `calories_spent` as a record.
- Done when: tests show a guideline day costing about 2,100 kcal for a boy of 10, weight going up with fast food at every meal and down with healthy food, and U at its limits.

## Task 5 — Training
- Daily capacity, effective minutes (× performance × recovery, 0 beyond capacity), overreaching O, cardio and strength recovery, fitness and strength targets and their movement (τ 30 and 42 body days), and the gain penalties from d, U and O, all as in v1 Step 6.
- Minutes beyond capacity give no benefit and cost 0.02 happiness per hour. A strength session started below 60% recovery counts as too soon.
- Performance uses `minigame.default_score` (decision 5) and tiredness.
- Done when: tests show the guideline plan raising fitness and strength, 4 h of cardio a day and strength twice a day ending below it, and strength 48 h after a session being about 86% recovered.

## Task 6 — Sleep
- At each new day: sleep debt with the v1 formula (k included through the 12 h constant), oversleep, the Sleep measure, d, and night quality. The recommended range and target follow the body age (child 9 to 12 h, target 10.5; teenager 8 to 10 h, target 9). Naps count; the 0-hour rule still counts as 0 h.
- Tiredness = max(d, (hours awake − 15) ÷ 4), at most 1; "I'm tired" when tiredness ≥ 0.5.
- Done when: tests show a full night repaying 86% of the debt, no sleep repaying nothing, and 6 h every night settling near 4.4 h of debt.

## Task 7 — Diet habits and Happiness
- Q, C (body time) and A (clock time) change at each meal (v1 Step 7).
- Happiness (0 to 1) moves toward the v1 baseline with τ 12 avatar hours (clock time) and jumps with every event in the v1 Step 10 table (meals, starting exercise, exercise within or beyond capacity, football, screens, 4 h without screens, hunger while awake, waking up).
- Fun and screen excess from the 24-hour averages in the action log (the log keeps at least the last 24 avatar hours and 7 days).
- Delete the Milestone 4 mood, scores and habit-change cost code, and rename Mental to Happiness everywhere in code and UI (English text only; the pt and en translations come in a later milestone, decided in Task 0).
- Done when: tests show the abrupt switch from fast food with craving 0.9 dropping happiness lower than the gradual switch, and the guideline plan reaching happiness near 1.0.

## Task 8 — Physical, Health, failure, risk and XP
- Physical = (0.5·√w + 0.3·√fitness + 0.2·√strength)² × (0.4 + 0.6·Q) × (1 − 0.5·U) × (1 − 0.3·O).
- Target health = 1 + 4 × ((√Physical + √Happiness + √Sleep) ÷ 3)² (p = 0.5, equal weights, from config), worked out every step. Displayed health (the bar) += `alpha_bar` × (target − displayed) once per avatar day when a sleep ends (decision 1).
- Failure: displayed health below `fail.health_line` for `fail.health_hours`, or happiness below `fail.happiness_line` for `fail.happiness_hours`. Keep the placeholder failure message; no death.
- Risk index R and hidden damage (decision 9), debug only.
- XP: 100 × change in health, plus 10 per avatar hour at health ≥ 4.5 × (1 + hours at that level ÷ 48), at most × 3. Never below 0.
- Avatar states for the messages and placeholder shapes: hungry, tired, sad, thin, overweight, muscular, muscular with fat (v1 table). Ill is not used yet.
- UI: the measures panel shows Physical, Happiness and Sleep amount; the physical box shows weight, height, BMI-for-age z, fitness, strength, diet quality and calories spent as numbers.
- Done when: the Normal start gives health about 2.91 for a boy of 10, and Easy, Normal and Hard starts match the v1 table (Very hard is higher because of decision 7).

## Task 9 — Saves
- Save every new state (weight, body age, fitness, strength, Q, C, A, hunger, U, O, debt, happiness, timers, damage, the action log). Time and saving stay in separate scripts.
- Milestone 4 saves follow decision 6.
- Done when: `tests/save_test.gd` saves and reloads every new value, and a Milestone 4 save opens the creation screen (if that is the decision).

## Task 10 — Scenario tests (Bases fundamental check)
- Rewrite `tests/calibration_test.gd` to play the v1 "Predicted results" scenarios through the real update loop and the real Eat, exercise, entertainment and sleep actions (boy of 10, Normal; then a girl of 10 and teenagers of both sexes), for 21 and 60 avatar days.
- Print each scenario's row (kg, z, fitness, strength, Physical, Sleep, Happiness, Health) next to the v1 prediction, and PASS or FAIL for every row of the v1 "Bases fundamental check" table. Also print the Very hard gradual vs abrupt food switch, and XP per real hour for recommended vs 6 h sleep.
- Also check that Very hard (with happiness 0.30) does not reach failure in the first avatar days with the guidelines changed gradually, and still starts with the lowest health.
- The displayed health bar (decision 1) makes health move more slowly than the v1 predictions; compare the **target health** with v1, and print the displayed health too.
- Small differences from the v1 numbers are expected (the predictions came from a separate simulation); the pass criteria are the **rules**, not the exact numbers.
- If a rule fails, **do not change values on your own**: report the numbers and propose values for the team.
- Done when: one command runs every scenario and prints pass or fail for each rule.

## Task 11 — Debug view, CSV log, check and publish
- Debug panel (F7, debug builds only): every v1 state variable, the three measures, health, failure timers, risk and damage.
- `HealthLog` writes one CSV line per avatar hour (decided in Task 0) with every state variable, so the team can compare with its spreadsheet.
- Run all tests. Play a few avatar days with the debug speed on each difficulty.
- Export to `docs/`, check the web build (saving after a reload), update `CLAUDE.md` so it describes the new code, then commit and push.
- Done when: the published game uses food and the v1 health system, and every test passes or its failure has been reported to the team.

## Out of scope for this milestone
Food menus and tastes beyond the two meals, minigames (only the default score), disease stages and their effects, the failure effect, avatar art (placeholder shapes only), settings contents, server and accounts. The researched values that replace the v1 placeholders come after this milestone.
