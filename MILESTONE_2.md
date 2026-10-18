# Milestone 2 — Sleep at any time, exercise and entertainment

Goal: reuse the sleep activity from Milestone 1 to add **exercise** (cardio and muscle strength) and **entertainment**, and apply the two new sleep rules. Keep it simple: only what is listed here. Read `CLAUDE.md` first (the sleep rules are in "Time"). After each task, say how to run it and what to check. All new numbers go in `data/config.json` or `data/activities.json`, marked as placeholders.

## Task 1 — One activity system for everything
- Turn the sleep activity into a general activity system that sleep, exercise and entertainment all use: lock the four buttons, show the Stop button, play a short repeating animation, show the activity's background, apply effects per avatar hour, and end early with Stop (effects count only for the time actually done).
- Activities are defined as data in `data/activities.json` (id, options, duration in avatar hours, effects per hour, background colour, animation name). Sleep keeps its own slider and the day conversion.
- Add `data/activities.json` to the web export filter (`data/*.json` already covers it; check).
- Done when: sleep still passes all Milestone 1 tests, now running through the general system.

## Task 2 — Sleep at any time (naps)
- The sleep button works at any moment of the day, not only at bedtime.
- Any sleep, short or long, follows the same rule: when it ends, a new day starts with length `14 + (10 - hours slept)`. Example: a 1-hour nap starts a 23-hour day.
- Done when: a test shows that a 1-hour nap at 14:00 gives a new day that ends at 14:00 the next day (24 hours in total), and that a normal 10-hour sleep still gives a 14-hour day.

## Task 3 — Ignoring the sleep recommendation
- If the awake period runs out and the player has not slept, it counts as 0 hours slept: a new 24-hour day starts at once.
- The avatar stays tired, the "I'm tired" message and the recommendation stay visible, and the sleep measure keeps falling (existing placeholder, −0.05 per hour awake). The player can still sleep at any time.
- Done when: a test runs a day without sleep and shows the next day lasting 24 hours, with the sleep measure lower than at the start.

## Task 4 — Exercise
- The exercise button opens two options: **cardio** and **muscle strength**.
- Each runs for a placeholder duration (1 avatar hour each) through the activity system, with its own placeholder animation and background.
- Effects (placeholders, per avatar hour): both spend calories; cardio spends more calories, muscle strength raises muscle more. Store `calories_spent` and `muscle` in `GameState` (save them), and raise the physical measure by a small placeholder amount per hour of exercise. There is **no fatigue system**.
- Done when: one hour of cardio and one hour of muscle strength change calories spent, muscle and the physical measure by the config values, and Stop halfway applies half.

## Task 5 — Entertainment
- The entertainment button opens one option for now ("Entertainment"; the real menu is decided later).
- Placeholder duration 1 avatar hour. Effect: raises the mental measure **significantly** (placeholder, for example +0.1 per hour).
- Done when: one hour of entertainment raises mental health by the config value, and the value is saved.

## Task 6 — Check, export and publish
- Run all tests (Milestone 1 and 2). Play one full day on the Mac with the debug speed: exercise, entertainment, a nap, then ignore the recommendation once.
- Export to `docs/` and check the web build in a browser (saving still works after a reload). Then commit and push.
- Done when: the published game has working exercise, entertainment, naps and the 0-hour rule.

## Out of scope for this milestone
Food and hunger effects, avatar states and body-state art, health formula changes, death and failure, translations, settings contents.
