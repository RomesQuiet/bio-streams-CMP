# Milestone 1 — Playable skeleton

Goal: a web-exportable Godot project that runs on the Mac with the main screen, the time system, the three measures (placeholders), one activity (sleep) and local saving. Work through the tasks in order. Read `CLAUDE.md` first. After each task, say how to run it and what to check.

## Task 1 — Project setup
- Godot 4.6.3 project, Compatibility renderer, portrait 720x1280, stretch `canvas_items`, aspect `keep`.
- Create the folder structure from `CLAUDE.md`, a Godot `.gitignore`, and `README.md` (what the game is, how to run it, link to the published game once it exists).
- Done when: the empty project opens in Godot with no errors and runs a blank main scene.

## Task 2 — Config and global state
- `data/config.json` with every tunable number (time scales, measure start values, health weights, XP placeholders, thresholds). Mark placeholders.
- Autoloads `Config` (loads the JSON) and `GameState` (physical, mental, sleep, health 1 to 5, xp, level, hunger, avatar name, language).
- Placeholder health = weighted average of the three measures mapped to 1 to 5 (weights in config). Placeholder XP: small gain per avatar hour at health 4 or 5, small loss at health 1 or 2.
- Done when: values print correctly at startup and changing config changes the result.

## Task 3 — Main screen layout (placeholders)
- Build `scenes/main.tscn` following the sketch in `CLAUDE.md`: avatar egg and ground line, health bar top left (click opens a panel with the three measures), XP bar and level and settings button top right, day clock, pause and wake buttons between them, four buttons in a 2x2 grid, and a stop button above them.
- Centred column on wide screens. Test by resizing the window.
- Done when: the layout matches the sketch, the health panel opens and closes on click, and the layout survives resizing.

## Task 4 — Time system
- `Clock` autoload: day 30 real minutes for the first 14-hour day (28 avatar minutes per real minute), sleep 5 avatar minutes per real minute (10 hours = 2 real hours). Uses delta time only.
- Conversion function (see `CLAUDE.md`): `day_hours = 14 + (10 - sleep_hours)`, and day real minutes = `day_hours * 60 / 28`. Cover it with simple tests or a debug printout for 0, 5, 8, 10 and 12 hours of sleep.
- 24-hour clock label in the top bar showing the avatar's time of day (placeholder start 07:00).
- Pause button stops the day. When the day ends the night starts, the avatar shows "I'm tired" and a sleep recommendation, and sleep is not automatic. Wake button appears after sleep.
- Add a **debug speed multiplier** (key press) so the whole cycle can be tested in seconds, and make it impossible to enable in the published build.
- Done when: a full day and night cycle can be run with the debug multiplier and the clock shows avatar time.

## Task 5 — Sleep activity
- Sleep button opens a slider (hours). Starting it locks the four buttons and shows the stop button. The avatar plays a placeholder repeating animation. A sleep background.
- Real duration of sleep = hours x 60 / 5 minutes. Sleep adds to the sleep measure (placeholder values). When sleep ends: pause and show the wake button. The next day then starts with the length given by the conversion function.
- Done when: sleeping 8 hours lasts 96 real minutes and is followed by a 16-hour day (about 34.3 real minutes), and sleeping 5 hours is followed by a 19-hour day (check with the debug multiplier). The stop button ends sleep early, and the hours actually slept are used in the conversion.

## Task 6 — Local saving
- `SaveGame` autoload, separate from `Clock`. Save to `user://` as JSON at key moments (action end, pause, wake, page close) and load on start. Must work in the web export.
- Closing the game pauses time (nothing happens while closed).
- Done when: closing and reopening restores measures, XP, time and the avatar name, both on the Mac editor and in the web export.

## Task 7 — Web export and publishing
- Add the web export preset (Compatibility), export to `docs/`, and explain how to enable GitHub Pages (Settings, Pages, branch `main`, folder `/docs`).
- Done when: the game opens from the public GitHub Pages link in a browser and keeps its save after a reload.

## Out of scope for this milestone
Food, sport, entertainment, avatar states and art, death and failure, settings contents, translations, lobby, server and accounts.
