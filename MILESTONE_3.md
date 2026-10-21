# Milestone 3 — Player choices and the new health system

Goal: the player chooses the avatar's age group, sex and difficulty, and health is calculated from habits with the working plan in `CLAUDE.md` ("Health calculation (working plan)"). Every number is a **placeholder** in `data/config.json`. Keep it simple: only what is listed here. Read `CLAUDE.md` first. After each task, say how to run it and what to check.

Milestone 2 must be finished before starting (activity system, exercise, entertainment, naps, 0-hour rule).

## Task 1 — Avatar creation screen
- New screen shown when there is no save: avatar name, age group (child or teenager), sex (male or female) and difficulty (Easy, Normal, Hard, Very hard). A "Start" button opens the main screen.
- Show the difficulties with neutral wording (describe the starting habits, do not use words that stigmatise weight). The texts are placeholders.
- Store `age_group`, `sex` and `difficulty` in `GameState` and save them.
- A save without these choices (from Milestones 1 and 2) is **not loaded**: the creation screen opens and the player starts a new avatar.
- Done when: a new game asks for the four choices, and they are restored after closing and reopening.

## Task 2 — Starting values per difficulty
- In `data/config.json`, one block per difficulty (placeholders):
  - Easy: physical 0.75, mental 0.75, sleep 0.75, weight z-score 0.
  - Normal: 0.50, 0.50, 0.50, z +1.
  - Hard: 0.15, 0.30, 0.30, z +2.2, habit change cost low.
  - Very hard: 0.05, 0.05, 0.10, z +3.2, habit change cost high.
- Also in config: recommended sleep per age group (child 9 to 12 h, teenager 8 to 10 h) and starting values for fitness, muscle and the usual level of each habit per difficulty.
- Choose the starting body states so that the measures they give on day 1 match the starting measures above (otherwise health jumps after the first sleep). List the values you chose.
- **Starting health is calculated** with the formula from Task 5, never typed in. Saves from Milestones 1 and 2 **do not load** (see Task 1): the player creates a new avatar. Before a difficulty is chosen, the Normal values are used.
- Done when: a printout shows starting health of about 4.0 (Easy), 3.0 (Normal), 2.0 (Hard) and 1.3 (Very hard, shown as level 1).

## Task 3 — Action log and daily habit scores
- Log every activity with its type, the avatar time it started and the avatar hours actually done (Stop counts only the time done). Keep the last 7 avatar days.
- When a sleep ends (any sleep, including naps and the 0-hour rule), calculate the day's habit scores (0 to 1):
  - Sleep s: 1 inside the age range; falls linearly to 0 at 4 h or less; falls slowly above the range.
  - Activity a = minutes of cardio and muscle strength ÷ 60, at most 1.
  - Strength w = days with muscle strength in the last 7 ÷ 3, at most 1.
  - Screens c = 1 up to 2 h of entertainment; falls linearly to 0 at 6 h. For now all entertainment counts as recreational screen time (placeholder until sedentary and active entertainment exist).
- Done when: a test with a known log gives the expected four scores.

## Task 4 — Slow body states
- New `GameState` values, saved: sleep debt, fitness, muscle, weight z-score, mood and the usual level of each habit.
- Update them once per avatar day, after the habit scores, using the formulas in `CLAUDE.md` and the body speed multiplier `k` (placeholder 4) from config. `k` applies to fitness, muscle and usual habit levels only; not to the clock, the night's sleep or the scores.
- Weight z-score **stays at the difficulty's starting value** (no food yet, no automatic eating).
- The Milestone 2 per-hour effects (calories spent, muscle, physical +, mental +) are replaced by this system. Keep `calories_spent` as a record only.
- Done when: a test shows fitness rising after days of activity and falling slowly after days without, and sleep debt growing with short sleep and shrinking with enough sleep.

## Task 5 — Measures and health
- Calculate the three measures from the body states, as in `CLAUDE.md`: physical (mix of fitness, muscle and weight score; equal thirds as placeholder), sleep (sleep score lowered by debt), mental (mood lowered by the cost of changing habits fast, scaled by the difficulty's cost).
- Target health = 1 + 4 × C, with the weighted power mean `C = (w_P·P^p + w_M·M^p + w_S·S^p)^(1/p)`; p = 0.5 and equal weights from config.
- Displayed health moves toward the target once per avatar day: `health += α × (target − health)`, α placeholder 0.3. The health bar shows the displayed health.
- XP keeps the Milestone 1 placeholder rule, now driven by the new health.
- Done when: the measures panel shows the new values and the health bar moves gradually after each sleep.

## Task 6 — Calibration scenario tests
- A headless test that simulates many avatar days with fixed habits and prints health per day. Scenarios (from the recommendations):
  1. Recommended habits every day (sleep in range, 60 min activity, strength 3 days a week, at most 2 h screens): health rises above 4 on Normal.
  2. 5 hours of sleep every day with lots of exercise: health never goes above 3.
  3. Good sleep but no activity and 6 h of screens: health falls below 3.
  4. Very hard, changing every habit on day 1: mental health drops. Changing step by step: it drops much less.
- If a scenario fails, **do not change p or the weights on your own**. Report which scenario failed and propose values for the user to decide.
- Done when: the test runs with one command and prints a pass or fail per scenario.

## Task 7 — Debug view, check, export and publish
- A debug panel (only in debug builds) showing the habit scores, body states, measures, target and displayed health.
- Run all tests (Milestones 1 to 3). Play a few avatar days on the Mac with the debug speed on each difficulty.
- Export to `docs/`, check the web build (creation screen, saving after a reload), then commit and push.
- Done when: the published game has the creation screen and the new health system.

## Out of scope for this milestone
Food, hunger and energy balance (weight stays fixed), sedentary and active entertainment, minigames, commitment goals, death and failure, avatar state art, translations, settings contents, server and accounts.
