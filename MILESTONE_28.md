# Milestone 28: a 15-minute day (21 Nov 2026)

Request (user, 21 Nov 2026): "make everything the same, but adapted to a 15min day, don't forget to change the docs". Asked about the night: "Night stays 2 hours".

## Decision 98

- A day of 14 avatar hours lasts **15 real minutes** (was 20): `time.day_avatar_minutes_per_real_minute` 42 → 56. The sleep-to-day rule is the same: `day_real_minutes = day_hours * 60 / 56` (24 h = 25.7 min, 19 h = 20.4 min, 16 h = 17.1 min, 12 h = 12.9 min).
- The **night stays 2 real hours** for 10 hours of sleep (`sleep_avatar_minutes_per_real_minute` 5; user). Sleep while the game is closed (Milestone 23) is unchanged.
- **Football keeps its real length:** `minigame.football.time_slowdown` 5 → 6.6667 (5 x 56 / 42), so 60 avatar minutes still last about 7 real minutes and the help says "7 times slower". The Breath cost of a pass, shot or tackle was divided by the slowdown in the code; it is now written as the result (0.004, 0.008, 0.01), so it did not change.
- **Everything in avatar time is unchanged** (the health model, meals, training, XP per avatar hour, the minimum wake time). Only the real length of a day changes: one real minute of play is 4/3 as much avatar time, so a cardio or strength session, and the steps goal of a cardio session, last 3/4 as long in real time. Taps keep their real rhythm (cadence and press timing are real seconds).
- Not changed: the meal minigame (real seconds per swing), autosave every 30 real seconds.

## Files

`data/config.json`, `scripts/autoload/minigame.gd`, `scripts/ui/football_help.gd`, `tests/clock_test.gd`, `tests/calibration_test.gd` (comment), `CLAUDE.md`, `documentation/handoff.md`.

## Google Drive (21 Nov 2026, text replaced in place, same links)

- "Apresentação Bio-Streams v5", slide 16: "15 min reais" and "1 min real = 56 min do avatar acordado".
- "Jury Report (EN)", "Jury Report (EN) - Summary (3 pages)" and "Jury Report (EN) - Annex": "one game day lasts 15 minutes" and, in the annex, "15 real minutes ... (1 real minute = 56 avatar minutes)".
- The XP per real hour in the Jury Report and its annex (section 11): "about 60 against 212" (it was 56 against 205 with the 20-minute day; still about a quarter).

## Checked

- Run: `clock_test`, `minigame_test`, `football_test`, `minutes_slider_test`, `offline_sleep_test`, `interface_test`, `meal_test` (all pass), `calibration_test` (the same three rules fail as before this milestone, see `MILESTONE_27.md`).
- `sleep_test.gd` hung: its day loop moved time in 56-minute steps and one landed exactly at the end of the day, so the 0-hour rule started a new day again and again (with 42-minute steps rounding stopped it just short). The loop now stops each frame before the end of the day, like the other tests. All pass.
- Two cardio checks in `minigame_test.gd` were timed for the 20-minute day (a session now ends sooner in real seconds): the refill check now looks halfway, and the poor-player check uses a 2-hour session. `football_test.gd` reads the slowdown from the config.
