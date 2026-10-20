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
- Health system plan: "Architecture Decisions: Health System" (English) and "Decisões de Arquitetura: Sistema de Saúde" (Portuguese), plus "Por Definir: Sistema de Saúde" (what is still undefined). If you cannot open them, ask the user to paste them.
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
scripts/       autoload/ (config.gd, game_state.gd, clock.gd, save_game.gd, activities.gd), ui/, avatar/
data/          config.json, foods.json, activities.json
translations/  strings.csv
assets/        art/, audio/
documentation/ milestone notes
docs/          web export (GitHub Pages)
tests/         headless test scripts (one per area: clock, save, activities, health and XP)
```

Autoloads: `Config`, `GameState`, `Clock`, `SaveGame`, `Activities` (the general activity system for sleep, exercise and entertainment, reading `data/activities.json`). The Clock never reads the device clock for game time; it advances only with the game open (delta time).

## Game rules (confirmed)

**Measures**
- Health: 1 to 5, **calculated from the starting measures** (3 on Normal), not fixed. Formula numbers **not defined yet**: until a milestone asks for the new system, keep the placeholder weighted average (weights in config). Health **always equals the health formula**, so it rises and falls with the measures at every moment. The **health level** is health rounded to a whole number (1 to 5).
- Physical: 0 to 1, 0.50 on Normal (calories and muscle strength; weight/height ratio may come later). Its values are kept separately in `GameState`: **muscle** (0 to 1, raised by exercise, mostly muscle strength) and **calories spent** (total kcal spent by exercise, never reset). **Endurance** is planned as the value that cardio trains, but it does not exist in the game yet.
- Mental: 0 to 1, 0.50 on Normal.
- Sleep: 0 to 1, 0.50 on Normal. It affects the other measures the most.
- The starting measures depend on the difficulty (below). The code from Milestone 1 still uses the old start values (physical 0.5, mental 0.5, sleep 1), which give health about 3.9 with the placeholder formula; change them only when a milestone says so.
- XP: unlimited. Health loss loses XP, health gain gains XP, and staying at high health for longer gives more. The XP bar shows the level (empty = start of a level, full = next level, then empty again). XP values per action are **not defined** (placeholders). How it works now (all numbers are placeholders in `data/config.json`, section `xp`):
  - Every health change gives or takes XP: change in health × `per_health_point`.
  - Each avatar hour at a high health level (`high_health_min` or more) gives `gain_per_avatar_hour` × a multiplier that grows with the hours spent at high health without a break (`high_health_bonus_per_hour`, up to `high_health_max_multiplier`). Dropping below the high level resets the streak.
  - Each avatar hour at a low health level (`low_health_max` or less) loses `loss_per_avatar_hour`.
  - XP never goes below 0. The level is XP ÷ `per_level` (rounded down), so losing XP can lower the level. Reaching a new level shows "Level up!" in the speech bubble for a few seconds.
- Sport and sleep drive progression. Food is built after them.
- **Player choices:** age group (child or teenager), sex (male or female) and difficulty. The age sets the recommended sleep range (child 9 to 12 h, teenager 8 to 10 h; placeholder) and the sex sets the WHO BMI-for-age tables.
- **Difficulty and starting values (placeholders):** Easy about 4 (0.75, 0.75, 0.75); Normal 3 (0.50, 0.50, 0.50); Hard about 2 (0.15, 0.30, 0.30), with obesity but cheap habit changes; Very hard about 1.3 (0.05, 0.05, 0.10), shown as level 1, with severe obesity and very bad habits, where changing habits quickly costs mental health. Starting health comes from these measures.
- **Planned health calculation (working plan, numbers undecided):** once per avatar day, at wake-up, habit scores (sleep, activity, strength, screens, each compared with a recommended range) change slow body states (fitness, muscle, weight as WHO BMI-for-age z-score, sleep debt, mood), which give the three measures. Health combines them with a weighted power mean (p about 0.5, equal weights; placeholders), moving gradually toward the target. The body changes faster than real life with a multiplier k (placeholder 4, in config). Do not build this until a milestone asks for it.
- **No fatigue system.** Exercise only spends calories and builds muscle strength: more exercise means more calories spent and more muscle. "Tired" means sleepy and has nothing to do with exercise.

**Time**
- Day = 30 real minutes = 14 avatar hours (1 real minute = 28 avatar minutes).
- Night = 2 real hours = 10 avatar hours of sleep (1 real minute = 5 avatar minutes). Sleeping less is proportional (8 h of sleep = 96 real minutes).
- **Sleep-to-day conversion (confirmed).** The baseline is 10 hours of sleep and a 14-hour day (24 hours in total). Hours slept below 10 are **added to the next day** and hours slept above 10 are **taken from it**: `day_hours = 14 + (10 - sleep_hours)`. Example: 5 hours of sleep give a 19-hour day, and 12 hours of sleep give a 12-hour day. The day's real length uses the same scale: `day_real_minutes = day_hours * 60 / 28` (19 h is about 40.7 real minutes, 14 h is 30 real minutes). The first day is 14 hours.
- Implement this as one small, well-tested conversion function in `Clock` (avatar hours to real seconds, and back), with the numbers read from `Config`. Put the maximum sleep on the slider in config (placeholder, for example 12 hours).
- A **24-hour clock** in the interface (in the top-right column, under the XP level box, above the pause button) shows the avatar's time of day. Placeholder: the first day starts at 07:00. With this conversion bedtime stays at the same clock time and the wake-up time moves with the hours slept.
- Game time only advances while the game is open. Closing the tab pauses time.
- A pause button stops the day. The night starts when the day ends, but sleep is **not automatic**: the avatar gets tired, shows a recommendation to sleep, and the player decides. When sleep ends, the game pauses and a **wake button** starts a new day.
- Sleep is optional and variable (a slider chooses the hours). Not sleeping lowers health significantly.
- **Sleep at any time (confirmed).** The sleep button works at any moment of the day, not only at bedtime. A nap is simply a short sleep and follows the same rule: when any sleep ends, a new day starts whose length is `14 + (10 - hours slept)`, so one sleep plus the awake period after it always adds up to 24 hours.
- **Ignoring the sleep recommendation (confirmed).** If the awake period runs out and the player has not slept, it counts as **0 hours slept**: a new 24-hour day starts at once, the avatar stays tired and the sleep measure keeps falling. The recommendation stays visible, and the player can still sleep at any time.

**Food and mood** (build later)
- The player chooses what the avatar eats when hungry (4 to 5 meals; menus decided later).
- Junk food always lowers physical health but supports mental health. Disliked food makes the avatar sad.
- A gradual junk-to-healthy transition keeps mental health stable and lets physical health recover. Without a transition, mental health falls and the avatar can enter a severe mental-illness state that lowers overall health.

**Failure and death**
- Failure at minimum health (effect not defined). Death can happen at any time, more likely at low health (probabilities not defined). After death the player restarts with a new avatar.

## Interface (from the user's sketch)

- Avatar in the centre, standing on a ground line. Short messages from the avatar ("I'm hungry!", "I'm tired", others).
- Top bar (positions and functions from the user's sketch; the art is placeholder):
  - **Top left:** a square **health level** box (the health level, 1 to 5) and, to its right along the top edge, the **health bar** (1 to 5).
  - **Clicking the health level box or the health bar** opens the measures panel directly under the health bar (no gap between them). It shows three bars with their names: **Physical**, **Mental** and **Sleep amount**. Clicking either again closes it.
  - **Clicking the physical bar** opens a box to the right of the measures panel with the physical **values as numbers, not bars**: calories spent and muscle (endurance will be added when it exists). It closes with the measures panel.
  - **Top middle:** the **XP bar** along the top edge, with "XP current / needed" written on it.
  - **Top right:** a column with, from top to bottom: the **XP level** box, the **24-hour clock**, the **pause** button, the **settings** button and the **Wake** button (a button with the word "Wake" written on it, enabled only after a sleep ends).
- Bottom: four buttons in a 2x2 grid: **exercise, sleep, eat, entertainment**. Each opens its options. Exercise: cardio and muscle strength. Eat: junk food and healthy food. Sleep: a **slider** for the hours. Menus for eat, entertainment and sleep are decided later. There is **no gardening**.
- While an activity runs: the four buttons are locked, the avatar plays a short repeating animation, a **stop button above the four buttons** ends the activity, and each activity has its own background.
- Avatar states are separate (ill or not ill, tired, sad, hungry), never a progressive illness. Only the body states (muscular, thin, overweight, muscular with fat) combine with the other states.
- Screens: lobby (flashes of the creation process with music, low priority), avatar creation (name and customisation), main game, night and wake, death and restart, settings.

## Not decided yet (do not guess)

Health formula numbers (p, weights, curves, k, speeds) and the calibration scenarios (a placeholder formula is in use); XP values and level size (placeholders are in use); whether the level can go down when XP is lost; endurance (how it is measured and changed); death probabilities; failure effect; what carries over after death; food list, tastes and menus; entertainment options; activity durations; hunger and calorie numbers; the avatar state thresholds; settings contents; server and accounts (later, optional).

## Quality checks

- After changes, run the project headless to catch script errors. On this Mac Godot is installed as `Godot 2.app`, so the binary is `"/Applications/Godot 2.app/Contents/MacOS/Godot"`, for example `"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --quit`.
- In the Godot editor, close the game window instead of pressing Stop ■, because Stop kills the game without the save on close. If it is not available, tell the user which scene to open and what to look for.
- No hard-coded game numbers in scripts. No use of the device clock for game time.
- Keep commits small, with clear messages.

## Licence

Code is intended to be open (MIT). Texts and art are intended to be open (CC BY 4.0). The original music belongs to its authors (Matilde with Senhor Carlitos), who decide its licence. Do not add third-party assets without a clear free licence.
