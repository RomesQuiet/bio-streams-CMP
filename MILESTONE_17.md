# Milestone 17 — The failure screen

**Status: built and committed (7 November 2026), not pushed.** The user plays it, then pushes.

## What was decided before

- Concept and Bases fundamental: there is no death, only failure; after failure the player restarts with a new avatar; the screens include "failure and restart"; the wording stays scientifically correct; the game does not give constant advice (players learn from the consequences).
- Milestones 10 and 10.5: the causes (target health below 1.3 for 24 avatar hours, happiness below 0.10 for 12, the danger state of severe thinness for 72 or z −4; `fail` group, placeholders). Until now failure was only a placeholder message in the speech bubble, and it went away when the timers reset.

## The user's decisions (7 Nov 2026)

Claude proposed: failure final and saved, a screen with the cause and a summary of the avatar's life, its habits next to the recommendations, one Start a new avatar button, and a warning before failure. The user: "that's good, but instead of listing every cause like the people playing are scientists, just output a quick phrase, and then a button with the details. Go on, maintain the style."

## Built

- **Failure is final.** `HealthModel.step()` keeps the first cause in `GameState.failed_cause` with `failed_day` and emits `GameState.failed` once; `GameState.is_at_failure()` stays true even if the values recover, and `GameState.failure_cause()` gives the saved cause. Both are saved (save version unchanged: older saves load with no failure). `GameState.best_health` keeps the highest displayed health.
- **Time stops.** The main screen sets `Clock.halted` (not saved; set again when a saved failure opens) and ends a running activity, except a sleep, which only stops (ending it would start a new avatar day after the failure). The scenario tests have no main screen, so their scenarios run on after failure as before.
- **The screen** (`scripts/ui/failure_screen.gd`, `FailureOverlay` in `scenes/main.tscn`, the style of the settings panel and the day and night buttons): the title, the avatar (sad; ill in the danger state), a short phrase per cause ("Ana lost too much weight.", "Ana's health got too low.", "Ana became too unhappy."), "The game ends here. You can start again with a new avatar.", and two buttons: **Details** and **Start a new avatar** (deletes the save and opens the creation screen; the language stays).
- **Details** (scrolls): what happened in exact words (with the values from config), the avatar's life (days lived, level and XP, highest and last health), its last measures and body, and its habits over the last `failure_screen.summary_days` (3, placeholder) avatar days from the action log: sleep, exercise and football, the share of fast-food meals and screens, each next to the recommendation (AASM 2016 sleep range of the age group, WHO 2020 60 minutes, the Canadian 2 hours of screens). Facts, not advice.
- **Details drawn, not written (user, 7 Nov 2026: "instead of showing the details in text, make it more graphical and user friendly").** Under "What happened" (the exact cause, one short paragraph): tiles in the level boxes' style (days lived, level, highest health, weight, BMI-for-age z, last health), the three measures as bars, and each habit with its picture (the request icons), its value, a gauge (`scripts/ui/habit_gauge.gd`) with the recommended zone in green and a white marker for the avatar, and the recommendation under it; meals are a green (healthy) and orange (fast food) bar. The gauges' scales are display only (sleep up to 14 h, exercise up to 2 times and screens up to 3 times the recommendation, longer if the avatar went past it).
- **Short verdicts (user, 7 Nov 2026: "give mini explanations for every measure", then "be way more pragmatic... just say too thin, too something").** Under the tiles, BMI-for-age in a few words from its WHO 2007 band (the game's cut-offs: far too thin below −3, too thin below −2, healthy weight, too heavy above +1, far too heavy (obesity) above +2); under each bar, "too low", "could be better" or "good" (`failure_screen.measure_low_below` 0.3 and `measure_good_from` 0.7, placeholders, wording only). A first version with longer explanations was cut. The Portuguese avoids gendered words ("magreza", "valor demasiado baixo").
- **The warning before failure:** while a failure timer runs (target health or happiness below its line, or the danger state), the health bar turns red and reads "Health: danger" (`HealthModel.failure_near()`).
- Texts in English and Portuguese (Claude's draft for the team to check).

## Checked

`tests/failure_test.gd` (32 checks: the warning, failure once and final, time stopped, the phrase, Details and the habit numbers, Portuguese, the saved failure, a new avatar, every cause). `tests/measures_test.gd` and `tests/danger_test.gd` now expect failure to stay when the values recover (it ended before). All tests pass. Rendered in a Godot window by day and at night, with Details closed and open. **Not checked:** a real phone, a real person reaching failure in play.

## Still open

Diseases as a failure cause (decision 9: only the risk index), the values of the failure lines and times (placeholders), `failure_screen.summary_days`, and the Portuguese wording.
