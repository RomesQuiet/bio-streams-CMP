# Milestone 13 — The strength minigame

**Status: built and committed (31 October 2026), not pushed.** Task 1 `4b5235f`, Task 2 `2c1a1e9`, Task 3 `2087d08`, Task 4 `c894f95`, Task 5 `5461691`, `0817f91` and the docs commit. All 25 tests pass, and the scenario test gives exactly the same output as before the minigames, so without a player nothing changed. The user played it and is happy with it (31 Oct 2026), and pushes next.

**Changes made while building (beyond the plan):**

- The `Minigame` value `breath` is now `reserve`, shared by the Breath and Muscle bars.
- Rushing a press still moves the avatar and counts the repetition; it is poor technique and tires the muscles faster. (In cardio a tap that is too soon is not a stride.)
- Code review: `resting` stayed true after a session ended; fixed.

**Checked in the web build (browser pane, 31 Oct 2026):** the waiting state; Down and Up in turn with only the expected button enabled; set, repetitions and Muscle bar; the squat; a rest followed by set 2 with less Muscle; the too-soon warning on a second session, which can still be played. The presses were sent by a script as arrow keys; the user then played it by hand. **Not confirmed:** a real phone.

Goal: muscle strength becomes a minigame, as cardio did in Milestone 12. The concept's idea: two buttons, Down lowers the avatar and Up raises it, and "the performance and the exercise time adapt to the avatar's current health".

Read `CLAUDE.md`, `documentation/handoff.md` and `MILESTONE_12.md` first. The rules of Milestone 12 still hold: a session only exists with a player, so the scenario tests and every health number stay as they are.

## Decisions (user, 31 Oct 2026)

| # | Question | Decision |
|---|---|---|
| 31 | How is a session organised? | **Sets, repetitions and rest.** Down then Up is one repetition. |
| 32 | What sets the repetitions and sets? | **Muscle strength, weight (BMI-for-age z) and sleepiness**, as in cardio. |
| 33 | How does the player score well? | **Half technique** (Down and Up in turn at a controlled pace), **half finishing the repetitions.** Rushing is poor technique. |
| 34 | What if the muscles tire during a set? | **The set ends early and the avatar rests.** It never trains to failure. |
| 35 | A session started too soon (the existing rule gives no benefit)? | **The avatar warns, and the player can still play.** |
| 36 | The avatar's sets are done and minutes are left? | **More sets until the time ends.** The slider stays in charge. |
| 37 | The player stops pressing? | **Same as cardio:** after 3 seconds the avatar stands still and nothing counts, and 20 seconds later the activity ends. The rest between sets does not count as stopping. |
| 38 | How to work | **All steps in a row**, each reviewed and committed; nothing pushed; the user reviews at the end. |

## The science

| Fact | Source | Used for |
|---|---|---|
| Beginners: 1 to 2 sets of 8 to 12 repetitions at low intensity, without undue fatigue. Later 2 to 4 sets of 6 to 12. | AAP 2020 (Stricker, Pediatrics 145(6)), read in full | 8 to 12 repetitions, 1 to 4 sets |
| Children recover quickly; 1 minute of rest between sets for beginners. | AAP 2020 | The rest between sets (shorter on the game's time scale, see below) |
| Sessions of at least 20 to 30 minutes, 2 to 3 times a week on non-consecutive days. | AAP 2020 | Already in the too-soon rules; 2 sets with rest take about 30 avatar minutes |
| Full range of motion with proper technique; programmes are technique driven; body-weight movements are fine. | AAP 2020 | Scoring technique; Down and Up in turn |
| With obesity children are stronger in absolute terms but weaker per kg: 23 to 24% lower force per body weight when hopping; 12 to 36% lower by joint. | Force-platform study; Theis 2019 | The weight term of capacity (0.76 times at z +2) |

The AAP gives no number for the speed of a repetition, so `press_seconds` is a placeholder. The 1-minute rest would be 86 real seconds on the game's scale, so `rest_seconds` is a placeholder too.

## The tasks

**How it plays.** The player presses Down, then Up, at a controlled pace. A Muscle bar falls with each repetition. When the set is done, or the bar is empty, the avatar rests and the bar partly refills, so later sets are shorter.

**Task 1 — Load model.** `scripts/health/strength_load.gd`, values in the config group `minigame`.
- Capacity = strength x body x (1 - `capacity_tired_cut` x tiredness), with body = 1 - `strength_weight_cut_per_z` x z above 0, at least `body_floor`.
- Repetitions per set from `reps_min` to `reps_max`, sets from `sets_min` to `sets_max`, rounded, by capacity.
- Done when: `tests/minigame_test.gd` shows the values for each difficulty, and that a weaker, heavier or sleepier avatar gets fewer.

**Task 2 — Session logic.** `Minigame` gets a `kind` (`"cardio"` or `"strength"`). The Breath value becomes a shared `reserve`.
- Only the expected button moves the avatar; the other one is off technique.
- A press on time is within `on_beat_share` of `press_seconds`. Rushing counts as poor technique and tires the muscles faster.
- Reserve falls by 1 / (`reps_margin` x repetitions of the set) per repetition, so a rested avatar finishes its set with some left. It starts at `GameState.strength_recovery`.
- The set ends at its repetitions or at an empty bar. Then `rest_seconds` of rest refill `rest_refill` of the bar. More sets follow until the time ends (decision 36).
- Score: technique (rhythm) as in cardio; pace = repetitions done / repetitions planned in the sets so far.
- Saved in the middle of an activity. Done when: tests cover all of this.

**Task 3 — Connect it to health.** The strength start (too soon, the 36-hour gap) only happens at the first press, so an activity with no press is not a session (decision 19). Nothing else changes: rest is part of the session's time, at the option's METy. Done when: without a player every number is exactly as before.

**Task 4 — On screen.** The minigame panel shows Down and Up in place of the tap button, only the expected one enabled; arrow keys on a computer. Status, set, repetitions, Muscle bar. The avatar squats with the presses. The too-soon warning. Texts in both languages. Done when: it plays in the web build, also at phone width.

**Task 5 — Review and finish.** Read the whole change again, run all tests, compare the scenario test with the version before, export, update the documents. Nothing is pushed.

## Still open (for the team)

- All the new numbers are placeholders, except the repetitions and sets, which are from the AAP.
- With decision 36 a long session goes past the AAP's sets: more sets are possible, and the existing rule (`train.strength_tire_min`, 45 minutes) makes them count less.
- Rest minutes count as training, as the v1 sessions do.
- `strength` trains a little from cardio and the other way round, as in v1; the minigame does not change that.
- The real AAP rest is 1 minute, longer than the game's scale allows.

## Out of scope

The football minigame, the other minigames, and any health value.
