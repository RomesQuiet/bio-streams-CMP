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
- Health system plan: "Architecture Decisions: Health System" (English) and "Decisões de Arquitetura: Sistema de Saúde" (Portuguese), plus "Por Definir: Sistema de Saúde" (what is still undefined) and "Plano de Investigação e Testes: Sistema de Saúde" (who researches each value, team decisions and test scenarios). If you cannot open them, ask the user to paste them.
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
tests/         headless test scripts (one per area: clock, save, activities, health and XP, creation, difficulty, habits, body, calibration, config)
```

Autoloads: `Config`, `GameState`, `Clock`, `Activities` (the general activity system for sleep, exercise and entertainment, reading `data/activities.json`), `Habits` (the action log and daily habit scores) and `SaveGame`. The Clock never reads the device clock for game time; it advances only with the game open (delta time).

## Game rules (confirmed)

**Measures**
- Health: 1 to 5, **calculated from the starting measures** (3 on Normal), not fixed. Health is the **weighted power mean** of the three measures (`health.combine` in `data/config.json`; p 0.5 and equal weights, placeholders; see "Health calculation (working plan)"). The formula gives the **target health**. The **displayed health** (the health bar) starts at the target and then moves part of the way toward it once per avatar day, when a sleep ends (`health.alpha_bar`, 0.37, placeholder). During the day health does not change. The **health level** is health rounded to a whole number (1 to 5).
- Physical: 0 to 1, 0.50 on Normal (calories and muscle strength; weight/height ratio may come later). Its values are kept separately in `GameState`: **fitness** and **muscle** (0 to 1, slow body states that change once per avatar day, see "Health calculation (working plan)"), the **weight z-score**, and **calories spent** (total kcal spent by exercise, never reset; a record only). Fitness takes the place of the planned "endurance".
- Mental: 0 to 1, 0.50 on Normal.
- Sleep: 0 to 1, 0.50 on Normal. It affects the other measures the most.
- The starting measures and muscle come from the chosen difficulty (`health.difficulties` in `data/config.json`). Before the player chooses, the Normal values are used.
- XP: unlimited. Health loss loses XP, health gain gains XP, and staying at high health for longer gives more. The XP bar shows the level (empty = start of a level, full = next level, then empty again). XP values per action are **not defined** (placeholders). How it works now (all numbers are placeholders in `data/config.json`, section `xp`):
  - Every health change gives or takes XP: change in health × `per_health_point`.
  - Each avatar hour at a high health level (`high_health_min` or more) gives `gain_per_avatar_hour` × a multiplier that grows with the hours spent at high health without a break (`high_health_bonus_per_hour`, up to `high_health_max_multiplier`). Dropping below the high level resets the streak.
  - Each avatar hour at a low health level (`low_health_max` or less) loses `loss_per_avatar_hour`.
  - XP never goes below 0. The level is XP ÷ `per_level` (rounded down), so losing XP can lower the level. Reaching a new level shows "Level up!" in the speech bubble for a few seconds.
- Sport and sleep drive progression. Food is built after them.
- **Player choices:** age group (child or teenager), sex (male or female) and difficulty. The age sets the recommended sleep range (child 9 to 12 h, teenager 8 to 10 h; placeholder) and the sex sets the WHO BMI-for-age tables. The player chooses them, with the avatar's name, on the **avatar creation screen**, which opens when there is no save; they are saved in `GameState`. Nothing is saved before Start is pressed.
- **Old saves do not load.** A save without the creation choices (from Milestones 1 and 2) is ignored: the creation screen opens and the player starts a new avatar. The old save is replaced when the new avatar is saved.
- **Difficulty and starting values (placeholders):** Easy about 4 (0.75, 0.75, 0.75); Normal 3 (0.50, 0.50, 0.50); Hard about 2 (0.15, 0.30, 0.30), with obesity but cheap habit changes; Very hard about 1.3 (0.05, 0.05, 0.10), shown as level 1, with severe obesity and very bad habits, where changing habits quickly costs mental health. Starting health comes from these measures.
- **Planned health calculation:** the full working plan is in the section "Health calculation (working plan)" below. The structure is decided, **all numbers are placeholders**. A first version was built in Milestone 3; Milestone 4 (`MILESTONE_4.md`) audits it and brings it in line with the team's values.
- **No fatigue system.** Exercise only spends calories and trains fitness and muscle: more exercise means more calories spent and, day by day, more fitness and muscle. "Tired" means sleepy and has nothing to do with exercise.

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

**Failure**
- **Team decision (22 Oct 2026): there is no death, only failure.** Failure happens at minimum health (effect not defined yet; show a placeholder message). Do not build any death system.

## Health calculation (working plan)

Source: "Architecture Decisions: Health System" (see Documents) and the team's "Plano de Investigação e Testes: Sistema de Saúde". The structure is decided; numbers not yet researched use an **average placeholder** in `data/config.json`, marked as a placeholder, so the team can change them at any time. A first version was built in **Milestone 3** (see "Built so far" below). **Milestone 4** (`MILESTONE_4.md` has the config keys and values) audits that code and brings it in line with this section; until a Milestone 4 task changes a part, the Milestone 3 behaviour described below is what the code does.

**Idea.** Health (1 to 5) is not set by hand. It comes from three measures (Physical, Mental, Sleep, each 0 to 1), which come from habits compared with scientific recommendations.

**Player choices and recommendations**
- Age group: child (reference age 10) or teenager (reference age 14). Sex: male or female (changes the WHO BMI-for-age tables and, later, energy use).
- Recommended sleep: child (6 to 12 years) 9 to 12 h per 24 h; teenager (13 to 18 years) 8 to 10 h. Recommended activity for both: at least 60 min/day of moderate-to-vigorous activity.
- Difficulty and starting measures: see "Difficulty and starting values" above. Starting health is **calculated** from those measures with the formula below, never set by hand. The "Hard" difficulty has low cost of changing habits; "Very hard" has high cost (`habit_change_cost`: 1 normal, 0.5 Hard, 2 Very hard; placeholders).
- **Starting body states** (in `health.difficulties`, placeholders) are chosen so that on day 1 they give the starting measures, and health does not jump after the first sleep: (fitness + muscle + weight score) ÷ 3 = physical, with fitness = muscle; mood = mental; sleep debt = 0. The weight score is 1 for z between −1 and +1 and falls to 0 at ±3 along a curve (section `physical_measure`): t² where t goes in a straight line from 1 at ±1 to 0 at ±3, so obesity (z = +2) already gives 0.25. The curve power is a placeholder; with a straight line the starting fitness of Very hard would be higher than Hard. The usual level of each habit is kept as a habit score (0 to 1): sleep = starting sleep, activity = fitness, strength = muscle, screens = starting mental.

**Body speed.** Slow body changes run faster than real life with a multiplier **k = 5** (team decision, 22 Oct 2026: the constant of how much faster health and the body change compared with the real-life average; kept in config, stated openly in the presentation). k applies to body fat, fitness, muscle, the usual level of each habit and habit rootedness (habits do **not** get a separate k). k does **not** apply to the clock, each night's sleep or the daily habit scores. Whether k applies to sleep debt is an open team decision (default: no). Implement k by running the real-day update k times per avatar day. One avatar day is about 2.5 real hours, so with k = 5 one avatar day counts as 5 days for the body.

**Six steps, run once per avatar day at wake-up** (steps 1 and 6 also run during the day):
1. **Action log:** every activity is logged with the avatar's time and its duration.
2. **Habit scores (0 to 1):** compare the last day (and the last 7 days for weekly rules) with the recommendation. 0 when far too little, 1 inside the healthy range, lower again when too much. Doing more gives no extra points.
   - Sleep s(S): 1 inside the range for the age; falls below it (0 at 4 h or less) and, slowly, above it.
   - Activity a(A) = minutes of moderate-to-vigorous activity ÷ 60, at most 1.
   - Strength w = strength days in the last 7 ÷ 3, at most 1 (vigorous activity uses the same rule).
   - Screens c(T) = 1 up to 2 h of recreational screens per day; falls to 0 (placeholder: 6 h).
3. **Slow body states** (change only part of the way each day, using k):
   - Sleep debt: new = old × r + (recommended sleep − hours slept), never below 0. r sets how fast debt is forgiven (undecided).
   - Fitness and muscle: new = fitness + k_up × a × (1 − fitness) − k_down × (1 − a) × fitness.
   - Weight: WHO BMI-for-age z-score, z = ((BMI ÷ M)^L − 1) ÷ (L × S), with L, M, S from the WHO tables for age and sex. Overweight above +1, obesity above +2.
   - Mood: moves toward a level set by sleep, activity, enjoyment, food and too much screen time.
   - Usual level of each habit: moves slowly toward what the avatar does; used for the cost of changing habits.
4. **Measures (0 to 1):**
   - Physical = mix of fitness, muscle and a weight score (1 when z is between −1 and +1, falling toward 0 near ±3). The mix is undecided.
   - Sleep = the day's sleep score, lowered by sleep debt.
   - Mental = mood ÷ 100 (mood on a 0 to 100 scale), lowered by the cost of changing habits quickly (doing much more than the usual level lowers mental health; changing step by step costs little; same rule as the gradual food transition).
   - **Habit change cost (team model, 22 Oct 2026).** For each habit, with A = today's intensity (0 to 1), H = usual level (0 to 1), R = rootedness (0 to 1, independent of H): D = max(0, |A − H| − T); P = min(P_max, α_habit × R^γ × D^γ); mood = max(0, mood − P); R grows R += λ(1 − R). Test values: T 0.10, α_habit 10, γ 1.5, P_max 10 points/day, λ 0.04. H reaches 95% of a new habit in about 66 real days (Lally 2010, k applied). Keep α_habit separate from the health-bar α.
5. **Target health** = 1 + 4 × C, where C combines the three measures (below).
6. **Displayed health** moves part of the way toward the target each day: new health = health + α × (target − health). α is undecided (example 0.3 per day). The bar changes slowly; messages and animations give immediate feedback.

**Combining the measures: weighted power mean**

`C = (w_P · P^p + w_M · M^p + w_S · S^p)^(1/p)`, with `w_P + w_M + w_S = 1`.

- p = 1 is the ordinary average (a strong measure fully makes up for a weak one). p close to 0 is the geometric mean (the weakest measure pulls everything down).
- Placeholder: p = 0.5 and equal weights (1/3 each).
- Example (physical 0.9, mental 0.6, sleep 0.1): ordinary average gives health 3.1, p = 0.5 gives 2.9, geometric mean gives 2.5.
- p and the weights are **calibrated** with test scenarios taken from the recommendations, not invented. Example scenario: "sleeping 5 hours every day can never give health above 3, even with lots of exercise". Write these scenarios as tests when the system is built.
- Sleep is not counted twice: it already lowers mental and physical health through steps 3 and 4, so the weights stay almost equal.
- **Config (Milestone 4 Task 1).** Every health value is in one `health` block in `data/config.json`, with the key names of `MILESTONE_4.md`. Each value is written as `{"value": ..., "status": "placeholder" | "team decision" | "from source", "owner": "Pessoa 1 to 4" or "team"}`; `Config.get_value()` returns its value and `Config.is_placeholder()` is true for status "placeholder". Sub-blocks: `habit_cost`, `sleep_range`, `sleep_recommended`, `weight_score`, `physical_mix`, `combine`, `log` (the log types and 24 h / 7 days), `difficulties` (starting values and `start_R` per difficulty) and `milestone3_rules` (old rules still in use, deleted in Milestone 4 Task 5). The age group key is `teenager` (MILESTONE_4.md writes `teen`), because the game saves it that way. Cardio and muscle strength have `kcal_per_hour` (300 and 200, a record only) and `activity_intensity` ("moderate_vigorous") in `data/activities.json`. **In debug builds, F6 reloads `config.json` while the game runs**; the next calculation uses the new values. No health number is left in a script (`tests/config_test.gd` checks this).
- **Built so far (Milestone 3 code, now reading the `health` block; Milestone 4 Tasks 2 to 8 still change it: k run as k real-day updates, the team habit-cost model with rootedness R, mood 0 to 100, enjoyment, the scoring day, failure, CSV log):** the health formula, the starting values per difficulty, the action log and habit scores (`Habits`), the slow body states (`GameState`), the measures and the daily health step, and a debug panel (`scenes/ui/debug_panel.tscn`, F7) that shows the habit scores, body states, usual habit levels, measures, target and displayed health. The debug panel only exists in debug builds (the editor); it removes itself from the published release build.
- **How the action log and scoring days work** (`scripts/autoload/habits.gd`, Milestone 4 Task 2): every activity that ends, and every sleep, is logged with its type (the activity option id: cardio, strength, entertainment, sleep), its scoring day, the avatar time it started (avatar hours since the game began, clock day number and time of day), the avatar hours actually done (Stop counts only the time done), its `activity_intensity` and its calories (`kcal_per_hour` × hours). A **scoring day** follows `health.score_window` = `wake_to_wake`: it runs from one wake-up to the next, so it closes when any sleep ends (a night, a nap, or the 0-hour rule, which counts as 0 h of sleep). When it closes, its totals are worked out (`Habits.day_totals()`): sleep hours, moderate-to-vigorous minutes (entries whose intensity is in `log.activity_intensities`), strength days in the last 7 scoring days (this one included; two sessions on one day count once), entertainment hours, recreational screen hours (`log.screen_types`; all entertainment for now) and calories. The totals give the four scores (sleep, activity = minutes ÷ 60, strength = days ÷ 3, screens), kept in `Habits.scores` and passed to `GameState.update_body_states()`; then the next scoring day starts. The log keeps the last 7 scoring days (`log.log_days`) and the totals of the last 7 closed days (`Habits.days`); all of it is saved. Entries from a Milestone 3 save count in the current scoring day.
- **How the slow body states work** (`GameState.update_body_states()`, numbers in the `health` block): once per avatar day, right after the habit scores, at the end of any sleep. k (body speed, 5) multiplies the speeds of fitness, muscle and the usual habit levels only, never the clock, the sleep, the scores, mood or sleep debt; each speed × k is kept at 1 or less.
  - Fitness (from the activity score a) and muscle (from the strength score w): new = x + k·k_up·score·(1 − x) − k·k_down·(1 − score)·x, with k_up and k_down 0.0056 per real day (until Task 4 runs them k times).
  - Sleep debt (hours): new = old × r + (recommended sleep for the age group − hours slept), never below 0; r = 0.8; recommended = the midpoint of the range (child 10.5 h, teenager 9 h). k is applied only if `k_applies_to_sleep_debt` is true (it is false).
  - Mood moves 0.3 of the way each day toward the average of the sleep, activity and screens scores (enjoyment and food join later).
  - Usual level of each habit (a habit score, 0 to 1) moves k × rate of the way toward that day's score, where rate = 1 − (1 − 0.95)^(1 ÷ 66) per real day (`habit_share_reached`, `habit_days_to_95`).
  - Weight z-score stays at the difficulty's value (no food yet).
  - The Milestone 2 per-hour effects on muscle, physical, mental and sleep are gone, and so is the sleep measure falling per hour awake. Exercise still adds calories spent per hour, as a record only.
- **How the measures and health work** (`GameState`, numbers in the `health` block): right after the body states, once per avatar day:
  - Physical = (fitness + muscle + weight score) ÷ 3 (`physical_mix`, `weight_score`).
  - Sleep = the sleep score of the sleep that just ended × (1 − sleep debt ÷ `debt_max`), never below 0; debt_max = 10 h. So 10 h of debt or more make it 0 (for a child, one night without sleep already gives 10.5 h). The 0-hour rule gives a sleep score of 0, so the sleep measure becomes 0.
  - Mental = mood − habit_change_cost × 0.1 × the sum, over the four habits, of how far the day's score is above its usual level by more than 0.1 (the usual levels from before that day). Doing much more than usual costs mental health; changing step by step costs little; Very hard pays twice as much, Hard half.
  - Target health = the weighted power mean of the three measures; displayed health += `alpha_bar` (0.37) × (target − health). Each change of displayed health gives or takes XP; the XP over time uses the displayed health level.
  - Before the first sleep the measures are the difficulty's starting measures.
- **Calibration scenarios** (`tests/calibration_test.gd`): simulates 28 avatar days with fixed habits through the real action log and daily update, for a child and a teenager, and prints health per day and PASS or FAIL per scenario: (1) recommended habits rise above 4 on Normal; (2) 5 h of sleep with lots of exercise never goes above 3; (3) good sleep, no activity and 6 h of screens falls below 3; (4) on Very hard, changing every habit on day 1 makes mental drop, and changing step by step over 10 days makes it drop much less. When a scenario fails, p and the weights are not changed by Claude: the result and proposed values go to the user to decide. **Current status (decision pending):** with p = 0.5, scenario 2 fails for the teenager (health ends at 3.19) and scenario 3 fails for both ages (3.10); with p = 0.1 every scenario passes (scenario 3 only just, 2.99 after 28 days). The user keeps p = 0.5 for now and will decide the calibration later.
- Normal start check: measures 0.5 · 0.5 · 0.5 give health 3. The old start values (physical 0.5, mental 0.5, sleep 1) would give 3.6, which is why Normal now starts with sleep 0.5.

**Food and energy.** Until the food system is built there is **no automatic eating**: body fat and BMI stay at the difficulty's starting value. Exercise only records calories spent and muscle. Energy balance (energy eaten minus energy used, rule of thumb about 7700 kcal per kg, a simplification) only enters the calculation once food exists.

**Still to define** (see "Por Definir: Sistema de Saúde"): curve shapes, energy model for children, k_up, k_down, r, α, the mix of the Physical measure, how mental health reacts to sleep, activity, screens and food, habit formation, a European starting point for the measures, the definition of severe obesity for children, the failure effect, calibration scenarios, the scoring-day window, XP per day, and whether active entertainment (football) counts toward the 60 minutes.

## Interface (from the user's sketch)

- Avatar in the centre, standing on a ground line. Short messages from the avatar ("I'm hungry!", "I'm tired", others).
- Top bar (positions and functions from the user's sketch; the art is placeholder):
  - **Top left:** a square **health level** box (the health level, 1 to 5) and, to its right along the top edge, the **health bar** (1 to 5).
  - **Clicking the health level box or the health bar** opens the measures panel directly under the health bar (no gap between them). It shows three bars with their names: **Physical**, **Mental** and **Sleep amount**. Clicking either again closes it.
  - **Clicking the physical bar** opens a box to the right of the measures panel with the physical **values as numbers, not bars**: calories spent, muscle and fitness (fitness takes the place of endurance). It closes with the measures panel.
  - **Top middle:** the **XP bar** along the top edge, with "XP current / needed" written on it.
  - **Top right:** a column with, from top to bottom: the **XP level** box, the **24-hour clock**, the **pause** button, the **settings** button and the **Wake** button (a button with the word "Wake" written on it, enabled only after a sleep ends).
- Bottom: four buttons in a 2x2 grid: **exercise, sleep, eat, entertainment**. Each opens its options. Exercise: cardio and muscle strength. Eat: junk food and healthy food. Sleep: a **slider** for the hours. Menus for eat, entertainment and sleep are decided later. There is **no gardening**.
- While an activity runs: the four buttons are locked, the avatar plays a short repeating animation, a **stop button above the four buttons** ends the activity, and each activity has its own background.
- Avatar states are separate (ill or not ill, tired, sad, hungry), never a progressive illness. Only the body states (muscular, thin, overweight, muscular with fat) combine with the other states.
- Screens: lobby (flashes of the creation process with music, low priority), avatar creation (name and customisation), main game, night and wake, failure screen (effect not decided), settings.

## Not decided yet (do not guess)

Researched health values (Milestone 4 uses averages; k = 5 is decided) and the calibration results; XP values and level size; failure effect; food list, tastes and menus; entertainment options; activity durations; hunger and calorie numbers; the avatar state thresholds; settings contents; server and accounts (later, optional).

## Quality checks

- After changes, run the project headless to catch script errors. On this Mac Godot is installed as `Godot 2.app`, so the binary is `"/Applications/Godot 2.app/Contents/MacOS/Godot"`, for example `"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --quit`.
- In the Godot editor, close the game window instead of pressing Stop ■, because Stop kills the game without the save on close. If it is not available, tell the user which scene to open and what to look for.
- No hard-coded game numbers in scripts. No use of the device clock for game time.
- Keep commits small, with clear messages.

## Licence

Code is intended to be open (MIT). Texts and art are intended to be open (CC BY 4.0). The original music belongs to its authors (Matilde with Senhor Carlitos), who decide its licence. Do not add third-party assets without a clear free licence.
