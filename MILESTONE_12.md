# Milestone 12 — Minutes slider and the cardio minigame

**Status: Task 1 done (`c892ecb`). Tasks 2 to 6 in progress (31 October 2026).**

Goal: the player chooses the minutes of an activity on a slider, as the concept has said for a while, and then the first minigame: **cardio**.

Read `CLAUDE.md` and `documentation/handoff.md` first. The concept's ideas for the minigames are in section 8 of the concept document.

## Decisions

**User, 31 Oct 2026:**

| # | Question | Decision |
|---|---|---|
| 17 | Which minigame comes first? | **Cardio** (concept: a single button to run, each click is one step). |
| 18 | Do we add the minutes slider now? | **Yes, before the minigame.** The concept asked for it and it was missing. |
| 19 | What if the player does not tap? | **The activity is not done:** the avatar does not do it and returns to its normal state after some seconds. |
| 20 | Does the score count for the session or as the player goes? | **As the player goes**, so Stop counts only what was done. |
| 21 | How does the player score well, and how long do they tap? | Answered by decisions 22 and 27. |

**User, 31 Oct 2026 (the cardio minigame):**

| # | Question | Decision |
|---|---|---|
| 22 | Rhythm or number of steps? | **Both.** The time between steps and the number of steps depend on the avatar, and it gets fatigued at some point. Follow the science. |
| 23 | What sets those values? | **Fitness, weight (BMI-for-age z) and sleepiness**, not the Physical bar: diet quality does not change running directly. |
| 24 | What is one tap? | **One stride, two steps.** This changes the concept's "each click is one step". |
| 25 | Where does the new fatigue apply? | **Inside each session only.** Health values and the scenario results stay as they are. This changes the concept's "no separate fatigue system". |
| 26 | What happens when the fatigue bar is empty? | **The avatar slows to a walk** while it refills, then can run again. |
| 27 | How long does the player tap? | **The whole session.** |
| 28 | What if the player stops tapping? | **The avatar stands still and waits for up to 20 seconds, then the activity ends.** This is the detail of decision 19. Game time keeps running. |
| 29 | Football? | **No minigame for now:** it keeps the fixed score. |
| 30 | How to work | **All steps in a row**, each reviewed and committed; nothing pushed; the user reviews at the end. |

**Proposed by Claude, not yet confirmed by the user or team:**

- **Meals have no slider.** The concept says both "a minutes slider before every activity" and "portions are fixed", and a meal counts in proportion to the time eaten, so a slider would change the portion. Meals stay at 0.5 avatar hours.
- **Slider limits:** 5 to 240 minutes in steps of 5 (`activity_slider` in `data/config.json`, placeholders; the concept lists the limits as open). 240 keeps the 4 hours of cardio of the v1 scenarios possible, so too much exercise still has its consequences.
- **The slider starts at the activity's `duration_hours`** (60 minutes for exercise and entertainment) every time it opens.
- **While an activity runs the speech bubble counts in minutes**, except sleep, which stays in hours.

## Task 1 — Minutes slider

- `"minutes_slider": true` on `exercise` and `entertainment` in `data/activities.json`. The options panel shows the minutes and the slider, and the player then clicks the option.
- `Activities.start()` uses the chosen time. Without one it uses `duration_hours`, as the scenario tests do, so their results do not change.
- Done when: `tests/minutes_slider_test.gd` passes, and the slider works in the web build.

## The science

| Fact | Source | Used for |
|---|---|---|
| Moderate intensity starts at 115 steps/min at ages 9 to 11 and 110 at 12 to 14; vigorous at 130 and 125. These are real walking and running values. | CADENCE-kids (Tudor-Locke 2018), Table 4, heuristic thresholds | The time between taps: 2 steps / cadence |
| Children with obesity have about 25 ml/kg/min of peak oxygen uptake, against 36.5 at a normal weight (0.68 times). | Frontiers in Physiology 2021 (PMC8155533); several studies agree on the direction, the size varies | The weight term of capacity |
| A pace above the sustainable one uses up a limited reserve, faster the further above it, and the reserve recovers below it. | Critical speed model. The pace is reliable in adolescents; the reserve is not yet, so its size is a placeholder | The Breath bar |
| Prepubertal children recover from hard exercise quickly. | Birat 2018 | A short refill while walking |
| Walking below the moderate threshold is lighter than 4 METy. | CADENCE-kids uses 4 METy as moderate for ages 6 to 17 | `walk_mety` |

## Tasks 2 to 6 — The cardio minigame

**How it plays.** Each tap is one stride. The Beat bar shows the time since the last tap and a green zone at the avatar's interval. The player taps in the green zone for the whole session. The Breath bar runs down while running and refills while walking.

**Task 2 — Pace and fatigue model.** `scripts/health/cardio_pace.gd`, values in the config group `minigame`.
- Capacity = fitness x body x (1 - `capacity_tired_cut` x tiredness), with body = 1 - `weight_cut_per_z` x z above 0 (0.32 lower at z +2), at least `body_floor`.
- Run cadence = moderate + capacity x (vigorous - moderate), by age group. Run interval = `steps_per_tap` x 60 / cadence. Walk interval uses `walk_cadence_share` x moderate.
- Run minutes before the Breath bar is empty = `run_minutes_base` + `run_minutes_range` x capacity (10 to 120 avatar minutes; 120 is `train.cardio_tire_min`).
- Done when: `tests/minigame_test.gd` shows the values for each difficulty, and that a heavier, less fit or sleepier avatar has a slower pace and less time.

**Task 3 — Session logic.** New autoload `Minigame`, listed before `Simulation`, with time passed in as real seconds so it can be tested.
- A session starts only when the main screen is open, the option has `"minigame": "cardio"` and the debug speed is off, so the scenario tests keep the fixed score. Football has no minigame.
- A tap before `min_gap_share` of the interval is not a stride and counts as off the beat. Within `on_beat_share` of the interval it is on the beat.
- Score = `rhythm_weight` x rhythm + the rest x pace. Both are averages of the last `score_window_strides` strides, so the score follows the player (decision 20). Pace = run interval / time between taps, at most 1, so walking lowers it.
- Breath falls with avatar minutes / run minutes, x interval / time between taps (running faster tires faster). It starts at `GameState.cardio_recovery`, so a second session right after the first starts tired. At 0 the avatar walks until `run_again_at`.
- No tap for `stall_seconds`: the avatar waits. After `wait_seconds` the activity ends (decision 28).
- Saved in the middle of an activity. Done when: tests cover all of this.

**Task 4 — Connect it to health.** `Training.performance()` uses the live score. While waiting nothing counts: no activity minutes, no training, and idle energy. While walking the energy uses `walk_mety`. The happiness cost of starting exercise only comes with the first tap (decision 19). Done when: without a player every number is exactly as before.

**Task 5 — On screen.** A panel in the place of the four buttons: status, steps, Breath bar, Beat bar and a large tap button (Space on a computer). The avatar hops once per tap and stands still while waiting. Texts in both languages. Done when: it plays in the web build, also at phone width.

**Task 6 — Review and finish.** Read the whole change again, run all tests, export, update the documents. Nothing is pushed.

## Still open (for the team)

- All the new numbers are placeholders, except the cadences, which are from the study.
- `minigame.min_performance` (0.7) now only applies while the player is tapping.
- Severe thinness also limits exercise, but it is not in capacity: no source was read for it.
- Football trains with a perfect score and no tapping (decision 29), so it can beat cardio.
- The concept document still says "each click is one step" and "no separate fatigue system".

## Out of scope

The other minigames, screens (no minigame idea exists yet), and any health value.
