# CLAUDE.md — Plasticine Tamagotchi

Instructions for Claude Code when working in this repository. Read this file fully at the start of every session.

## Project

A web game for the Bio-Streams (EU) science competition. The topic is **childhood obesity**. The player cares for an avatar who is a school student and tries to raise its health (1 to 5) through **sport, sleep and food** (food is secondary only in the order of development).
The author is a 9th-grade student competing in the national phase. Goal: win and present in Athens. The game must be scientifically sound, and everything in this repository is **public and free for anyone to use**.

## How to work with the user

- Always answer and think in **English**. Keep files in the language they already have (the game text is Portuguese and English).
- Be professional and clear. The user is a student: explain what you did in plain language and give exact steps (menus, commands) whenever the user has to do something.
- **Always read the current code before suggesting or making changes to it.** If instructions to modify code are needed and the code is not in front of you, ask the user for it first.
- Work in small steps. After each step say what changed, how to run it, and what to check.
- Do not invent game rules. If a rule is not written in this file or the concept document, use a **placeholder value in `data/config.json`**, mark it with `"placeholder": true` in a comment field, and list it in your reply.
- Do not save secrets, passwords or personal data in the repository.

## Documents (source of truth)

- Concept (English): https://docs.google.com/document/d/1R0EbQ2yzbhNdxQLjlmTEXIn4UyA-KSvChki2aoFJwrg/edit
- Development plan (Portuguese): https://docs.google.com/document/d/1fdYX6jyFzwiqxBsbWS87-_f4zdx2h0r5TUSW9UQCXoM/edit
- The summary below is the minimum. If this file and the documents disagree, tell the user and ask.

## Technical decisions (fixed)

- **Godot 4.6.3**, **GDScript**, **Compatibility renderer** (`gl_compatibility`). Do not use Forward+ or Mobile (the dev Mac is Intel with weak graphics, and Compatibility is the only one for web). Do not upgrade Godot.
- **Platform: web page for all devices** (computer, Android, iOS in the browser). Native apps are optional and only if there is time. **Test first on the Mac.**
- Portrait base resolution **720 x 1280**. On wide screens the game stays in a **centred column**. Use Control nodes with anchors and containers; stretch mode `canvas_items`, aspect `keep`.
- **No server, no accounts, no notifications, no daily limit.** The first version saves locally on the device. Keep **time and saving in separate scripts** so a server can replace them later without changing the rest.
- Web build is exported to the `docs/` folder and published with **GitHub Pages**. Keep documentation in `documentation/`, never in `docs/`.
- Data-driven: foods, activities and all tunable numbers live in `data/` (JSON), not in code.
- Texts go through Godot translations (`translations/`, CSV) with **pt** and **en**. Language is chosen in settings. Wording is scientifically correct and not simplified for small children.
- Placeholder art only for now: simple shapes (the avatar is an egg shape). Plasticine art is optional, later.

## Suggested structure

```
project.godot
CLAUDE.md  README.md  .gitignore
scenes/        main.tscn, ui/, avatar/
scripts/       autoload/ (config.gd, game_state.gd, clock.gd, save_game.gd), ui/, avatar/
data/          config.json, foods.json, activities.json
translations/  strings.csv
assets/        art/, audio/
documentation/ milestone notes
docs/          web export (GitHub Pages)
```

Autoloads: `Config`, `GameState`, `Clock`, `SaveGame`. The Clock never reads the device clock for game time; it advances only with the game open (delta time).

## Game rules (confirmed)

**Measures**
- Health: 1 to 5, starts at 3. Formula **not defined yet** (use a placeholder weighted average, weights in config).
- Physical: 0 to 1, starts at 0.5 (calories and muscle strength; weight/height ratio may come later).
- Mental: 0 to 1, starts at 0.5.
- Sleep: 0 to 1, starts at 1. It affects the other measures the most.
- XP: unlimited. Health loss loses XP, health gain gains XP, and staying at high health for longer gives more. The XP bar shows the level (empty = start of a level, full = next level, then empty again). XP values per action are **not defined** (placeholders).
- Sport and sleep drive progression. Food is built after them.
- **No fatigue system.** Exercise only spends calories and builds muscle strength: more exercise means more calories spent and more muscle. "Tired" means sleepy and has nothing to do with exercise.

**Time**
- Day = 30 real minutes = 14 avatar hours (1 real minute = 28 avatar minutes).
- Night = 2 real hours = 10 avatar hours of sleep (1 real minute = 5 avatar minutes). Sleeping less is proportional (8 h of sleep = 96 real minutes).
- **Sleep-to-day conversion (confirmed).** The baseline is 10 hours of sleep and a 14-hour day (24 hours in total). Hours slept below 10 are **added to the next day** and hours slept above 10 are **taken from it**: `day_hours = 14 + (10 - sleep_hours)`. Example: 5 hours of sleep give a 19-hour day, and 12 hours of sleep give a 12-hour day. The day's real length uses the same scale: `day_real_minutes = day_hours * 60 / 28` (19 h is about 40.7 real minutes, 14 h is 30 real minutes). The first day is 14 hours.
- Implement this as one small, well-tested conversion function in `Clock` (avatar hours to real seconds, and back), with the numbers read from `Config`. Put the maximum sleep on the slider in config (placeholder, for example 12 hours).
- A **24-hour clock** in the interface (top, between the settings button and the XP level indicator, next to the pause and wake buttons) shows the avatar's time of day. Placeholder: the first day starts at 07:00. With this conversion bedtime stays at the same clock time and the wake-up time moves with the hours slept.
- Game time only advances while the game is open. Closing the tab pauses time.
- A pause button stops the day. The night starts when the day ends, but sleep is **not automatic**: the avatar gets tired, shows a recommendation to sleep, and the player decides. When sleep ends, the game pauses and a **wake button** starts a new day.
- Sleep is optional and variable (a slider chooses the hours). Not sleeping lowers health significantly.

**Food and mood** (build later)
- The player chooses what the avatar eats when hungry (4 to 5 meals; menus decided later).
- Junk food always lowers physical health but supports mental health. Disliked food makes the avatar sad.
- A gradual junk-to-healthy transition keeps mental health stable and lets physical health recover. Without a transition, mental health falls and the avatar can enter a severe mental-illness state that lowers overall health.

**Failure and death**
- Failure at minimum health (effect not defined). Death can happen at any time, more likely at low health (probabilities not defined). After death the player restarts with a new avatar.

## Interface (from the user's sketch)

- Avatar in the centre, standing on a ground line. Short messages from the avatar ("I'm hungry!", "I'm tired", others).
- Top left: health bar (1 to 5). **Clicking it opens a panel with the three measures**; they are hidden otherwise.
- Top right: XP bar with level indicator, and the **settings button**. Between the settings button and the level indicator: the 24-hour day clock, pause button, wake button.
- Bottom: four buttons in a 2x2 grid: **exercise, sleep, eat, entertainment**. Each opens its options. Exercise: cardio and muscle strength. Eat: junk food and healthy food. Sleep: a **slider** for the hours. Menus for eat, entertainment and sleep are decided later. There is **no gardening**.
- While an activity runs: the four buttons are locked, the avatar plays a short repeating animation, a **stop button above the four buttons** ends the activity, and each activity has its own background.
- Avatar states are separate (ill or not ill, tired, sad, hungry), never a progressive illness. Only the body states (muscular, thin, overweight, muscular with fat) combine with the other states.
- Screens: lobby (flashes of the creation process with music, low priority), avatar creation (name and customisation), main game, night and wake, death and restart, settings.

## Not decided yet (do not guess)

Health formula; XP values and level size; death probabilities; failure effect; what carries over after death; food list, tastes and menus; entertainment options; activity durations; hunger and calorie numbers; the avatar state thresholds; what happens if the player ignores the sleep recommendation (a possible rule: it counts as 0 hours slept and the next day lasts 24 hours; ask before building it); settings contents; server and accounts (later, optional).

## Quality checks

- After changes, run the project headless to catch script errors. On macOS the binary is usually `/Applications/Godot.app/Contents/MacOS/Godot`, for example `Godot --headless --path . --quit`. If it is not available, tell the user which scene to open and what to look for.
- No hard-coded game numbers in scripts. No use of the device clock for game time.
- Keep commits small, with clear messages.

## Licence

Code is intended to be open (MIT). Texts and art are intended to be open (CC BY 4.0). The original music belongs to its authors (Matilde with Senhor Carlitos), who decide its licence. Do not add third-party assets without a clear free licence.
