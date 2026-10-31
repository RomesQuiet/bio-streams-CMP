# Milestone 12 — Minutes slider and the cardio minigame

**Status: Task 1 built, not committed (31 October 2026). Task 2 waits for the user's choices.**

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
| 21 | How does the player score well, and how long do they tap? | **Decided during development, by messaging.** Do not build these without asking. |

**Proposed by Claude, not yet confirmed by the user or team:**

- **Meals have no slider.** The concept says both "a minutes slider before every activity" and "portions are fixed", and a meal counts in proportion to the time eaten, so a slider would change the portion. Meals stay at 0.5 avatar hours.
- **Slider limits:** 5 to 240 minutes in steps of 5 (`activity_slider` in `data/config.json`, placeholders; the concept lists the limits as open). 240 keeps the 4 hours of cardio of the v1 scenarios possible, so too much exercise still has its consequences.
- **The slider starts at the activity's `duration_hours`** (60 minutes for exercise and entertainment) every time it opens.
- **While an activity runs the speech bubble counts in minutes**, except sleep, which stays in hours.

## Task 1 — Minutes slider

- `"minutes_slider": true` on `exercise` and `entertainment` in `data/activities.json`. The options panel shows the minutes and the slider, and the player then clicks the option.
- `Activities.start()` uses the chosen time. Without one it uses `duration_hours`, as the scenario tests do, so their results do not change.
- Done when: `tests/minutes_slider_test.gd` passes, and the slider works in the web build.

## Task 2 — Cardio minigame (not started)

Open points to decide together (decision 21):

- How the player scores well (for example a steady rhythm, or as many steps as possible).
- How long the player taps inside the activity.
- Decision 19 in detail: how long without a tap counts as "does not tap", how many seconds until the avatar returns to normal, and what happens to minutes already done.
- `minigame.min_performance` (0.7) was meant as the lowest result. With decision 19 it only applies while the player is tapping, so it needs checking with the team.
- Whether football, which also counts as cardio, uses this minigame until it has its own.

Technical points: the score replaces `minigame.default_score` in `Training.performance()` only while a player is really playing, because the scenario tests have no player and must keep the fixed score. The minigame must work with pause, settings, saving in the middle of an activity, both languages and a touch screen.

## Out of scope

The other minigames, screens (no minigame idea exists yet), and any health value.
