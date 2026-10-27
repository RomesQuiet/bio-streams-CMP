# Milestone 10.5 — Fixes from the team's review of Milestone 10

**Status: complete and pushed (27 October 2026)**, after the user checked the game in the Godot editor. Task 0 `f89926e`; Task 1 `2d9ac90`; Task 2 `47e5d0b`; Task 3 `2b8fce2`; Task 4 `e3c6f06`; Task 5 `1926e49`; Task 6 `d761cef`. All 20 tests pass. Results and proposals for the team: `documentation/milestone10_calibration.md`.

**Changes made while building (beyond this list):** the failure message now names its cause (thinness, health or happiness); the training window (`train.average_window_h`) now averages minutes per day over its length, so the parity test can try a one-week window (with 24 h nothing changes); the scenario test cuts an activity just before the end of the day so it never runs into the 0-hour rule.

Goal: fix what the team's review found (`documentation/milestone10_review.md`, a copy of the Google Doc "Milestone 10 Review", 27 Oct 2026). It is a short milestone between 10 and 11: one bug, two gaps in the v1 design, and a better scenario test that finds the real causes of the differences from v1 instead of guessing them.

Read `CLAUDE.md`, `documentation/handoff.md` and the review first. The rules of Milestone 10 still hold: no game number in a script, every new value in `data/config.json` with status and owner, and **no value changed just to make a test pass**: differences go to the team.

## Decisions (user, 27 Oct 2026)

| # | Question | Decision |
|---|---|---|
| 10 | Decision 1 said failure uses the displayed health bar. The bar moves 37% of the way per day, so a very sick avatar can take about a week to fail. The review says failure should use the true health. | **Failure uses the target health** (health below 1.3 for 24 avatar hours). This replaces the failure part of decision 1. The slow bar and XP stay as they are. |
| 11 | The review's danger state for severe thinness: "eating normally again ends it". What ends it? | **Only z back at −3 or above.** A very thin avatar must regain weight in time, or it fails. |
| 12 | The parity run needs v1's exact scenario plans, which only the team's v1 simulation has. | **Use what we know:** our plans plus the review's corrections; list every plan detail that had to be guessed, for the team to check. |
| 13 | How to work through this milestone | **All tasks in a row**, each committed on its own; nothing is pushed; the user reviews at the end. |

The review's proposals for the two gaps are taken as written (the user asked to fix what the review found); their numbers are placeholders for the team:

- A **minimum gap of 36 avatar hours** (clock time) between the start of one strength session and the next; a session inside the gap counts as too soon, like the recovery rule.
- A reversible **danger state** below BMI-for-age z −3 (WHO severe thinness): the Thin and Ill looks and a health bar warning. **Failure** if it lasts 3 avatar days or z reaches −4.
- A **thinness term** in the risk index: 0.40 × clamp((−2 − z) ÷ 2), mirroring the obesity term.

## Task 0 — Plan and a copy of the review
- `documentation/milestone10_review.md` (copy of the review) and this file.
- Done when: both are committed.

## Task 1 — Failure uses the target health (difference 5, decision 10)
- The health failure timer counts the hours that the **target health** stays below `fail.health_line`. XP keeps using the displayed health.
- Update the comments, the config comment and `CLAUDE.md`.
- Done when: a test shows a low target with a high bar reaching failure after 24 avatar hours, and a high target with a low bar never failing.

## Task 2 — Minimum gap between strength sessions (review, gap 1)
- New `train.strength_min_gap_h` (36, placeholder): a strength session that starts less than 36 avatar hours after the start of the previous strength session counts as too soon (no effective minutes, all its minutes build O), like the recovery rule. The hours since the last start are saved.
- Done when: `tests/training_test.gd` shows a session 24 h after the last one is too soon, one 48 h later is not, and the guideline plan (3 non-consecutive days) is unchanged.

## Task 3 — Danger state for severe thinness (review, gap 2; decision 11)
- New config values (placeholders): `fail.danger_z` (−3), `fail.danger_hours` (72), `fail.danger_failure_z` (−4).
- `GameState.danger_hours`: hours without a break with z below `fail.danger_z`; back to 0 when z is −3 or above. Failure when it reaches 72 h or z reaches −4.
- The avatar shows Thin and **Ill** (placeholder look), the health bar warns (placeholder: red bar and "Health: danger"), and the failure message says why it failed.
- Risk index: the thinness term (`risk.thin_weight` 0.40, `risk.thin_from` −2, `risk.thin_range` 2).
- Saved, in the debug panel and in the CSV log.
- Done when: tests show the danger state starting below −3, ending only at −3 or above, failure after 72 h or at −4, and the thinness risk term.

## Task 4 — Scenario test: method and missing scenarios (review, Method)
- Write the player rule exactly (when it checks hunger, the unit of the wait, no randomness).
- Report failure (day and cause) for every scenario, and the hungry share and lowest happiness.
- Add "1 h strength every day" and the severe diet over 60 avatar days; add daily strength to the Bases rule "too much or too often does less good"; add a rule that the severe diet reaches the danger state and fails before z −5.
- Play v1's known plans: strength twice a day with 40 min of cardio and strength at 9 and 12 hours after waking (review, difference 3); 30-minute strength sessions in the guideline plan (review, difference 4).
- Very hard: compare the gradual switch with v1's gradual result (4.28) and the abrupt one with 4.45 (difference 6).
- Done when: every rule passes or its failure is reported to the team.

## Task 5 — Parity run and the causes of differences 1, 2 and 4 (review, Method)
- New `tests/parity_test.gd`: plays the v1 scenarios with the user's decisions switched off (the bar follows the target at once, Very hard happiness 0.15) and the Milestone 10.5 rules off, the avatar eating as soon as it says "I'm hungry!" (checked every 5-minute step). Then switches one thing on at a time and prints how each result moves.
- Difference 1: kcal and meals per day of the severe diet, compared with v1 (1,145 kcal, 2.3 meals).
- Difference 2: where happiness is held down (baseline parts and events) in the imperfect plans.
- Difference 4: guideline strength with strength before or after cardio (daily capacity) and with 30 or 60-minute sessions.
- Write the results into `documentation/milestone10_calibration.md`. No value is changed to fit.
- Done when: each of differences 1, 2 and 4 has a measured cause, or the report says what is still unexplained.

## Task 6 — Docs, web export and checks
- `CLAUDE.md`, `documentation/handoff.md`, `documentation/milestone10_calibration.md` and this file describe the new state.
- Run all tests; export the web build to `docs/`.
- Done when: everything is committed. Pushed only after the user has checked the game (done on 27 Oct 2026).

## Out of scope
Values the team must research or decide (the review's numbers stay placeholders), the failure effect, disease stages, a 45-minute strength option (the review shows it would not raise strength), translations and the other "Not decided yet" items in `CLAUDE.md`.
