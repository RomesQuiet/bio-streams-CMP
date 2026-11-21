# Handoff — state of the project and how to continue
- **21 Nov 2026: Milestone 40, the new look from `documentation/ui_v2/` (`MILESTONE_40.md`), started:** the second account's pass 3 (12 changes, decisions Q1 to Q11, tables for every element, pictures in `ui_v2/assets/`). One change at a time, each committed and checked by the user; no push or publishing until the team confirms the licence of the image tool. `documentation/ui_v2/.gdignore` keeps the delivery out of the Godot import (the game's copies go to `assets/art/`). Milestone 35 was committed first on its own (`d90bbe1`). Change 1 (colours) done; pictures copied; the main menu rebuilt from the team's splash picture (an extra step the user asked for; `menu_backdrop.gd`, `menu_button.gd`, `language_toggle.gd`). Lesson: a pill drawn with `rounded_rect_points` at radius exactly half its height has duplicate points and `draw_polygon` fails to triangulate; use half the height minus 0.5. Open: change 7 (screen time) was written before Milestone 35 made Screens the video game.
- **21 Nov 2026: Milestone 35, the video game (decisions 103 to 108, `MILESTONE_35.md`):** Screens became "Video game", the Cloud jump minigame (a dinosaur jumping from cloud to cloud with one button, Geometry Dash-like platforms, faster with time like Chrome's dinosaur), with the avatar's best and a device leaderboard. The score never changes health. Lesson: a cloud course is only fair if each cloud is made from what a jump can do at the speed the dinosaur will have there; `tests/sky_test.gd` checks it with a bot that jumps at every edge (25 seeds, 200 s). Testing tip: in the browser pane a window narrower than 768 px is treated as a phone (the name opens a pop-up box); at 768 px wide, click the name field, then press keys one at a time.
- **21 Nov 2026: Milestone 30, football restarts (decision 102, `MILESTONE_30.md`):** goal kick after a miss, 3 s stop, the kicker protected from every tackle for 3 s.
- **21 Nov 2026: Milestone 29, failure by hunger (decisions 99 to 101, `MILESTONE_29.md`):** starving after 18 h without food, failure after 36 h or when health or happiness fail while starving; a never-fed avatar used to fail "by happiness".
- **21 Nov 2026: Milestone 28, a 15-minute day (decision 98, `MILESTONE_28.md`):** 56 avatar minutes per real minute; the night stays 2 real hours; football slowdown 6.67 so a match lasts as before.
- **20 Nov 2026: renamed to "My Healthy Avatar"** (project name, menu title, page title, documents); the storage keys `plasticine_tamagotchi_*` stay so browser saves keep loading. On the Mac the editor's save folder is now `app_userdata/My Healthy Avatar/`.

Last updated: 18 November 2026, after Milestone 25 (the new interface). Before that: 17 November 2026, after Milestone 18, the paused web conversion and the minigame ideas in the documents. Read this after `CLAUDE.md` when a new session starts. `CLAUDE.md` describes the game and the code; this file says **where the work stands, what was decided along the way, what is still open, and the lessons learned**, so nothing has to be found out again.

## 1. Where the work stands

- **Milestone 25 (the new interface, `MILESTONE_25.md`) is built and committed, not pushed (18 and 19 Nov 2026):** the team's specification (`documentation/ui_specification_v1.md`, a copy of `plasticTamagotchi01.rtf`) and its mockups (`documentation/ui_mockups/`) are the rule; `ui_art_brief.md` is deleted. Everything is drawn by code: design tokens (`scripts/ui/ui_style.gd`), icons (`ui_icons.gd`), a sky by colour stops (`sky_palette.gd`, `sky_background.gd`), the curved ground (`curved_ground.gd`), the HUD (`health_pills.gd`, `level_display.gd`, `ui_icon.gd`), the balloon (`speech_balloon.gd`), the four buttons (`action_button.gd`), the places (`scenery.gd`), Nunito, aspect `expand`. Decisions 79 to 89 (Wake gone, its job on the play button; 12-hour clock; flashing danger; health rounded down). Checked with pictures from `tools/render_ui_states.gd` at the six moments of the specification, the other states, a wide window and a tall phone; the web build is checked in the browser pane. A real phone is not confirmed.
- **Milestone 27 (sleep model v2, `MILESTONE_27.md`, `documentation/sleep_model_v2.md`) is built, not pushed (19 Nov 2026):** dynamic sleep need and debt (exactly v1's totals per cycle), naps fixed, "I'm tired" from today's need, a minimum wake time, the health bar moves every step, the debt and need shown in the measures panel (decisions 93 to 97). Open: two happiness checks of the guideline scenario fail because of meal timing at bedtime, not the sleep model, and "short sleep must not pay" fails narrowly (27% of the XP rate, limit 25%); the parity test was not run again. The Google documents and the v5 deck were updated on 19 Nov 2026 (list in `MILESTONE_27.md`).
- **Milestone 26 (fixes after the review of the new look, `MILESTONE_26.md`) is built, not pushed (19 Nov 2026):** XP is never lost (decision 90), the sun and moon above the head, a ring at the mouth, a greener ground by day, "7:15 PM". The "level doesn't change" report (decision 91) found no display bug: the level rolls correctly in a web build; the old up-and-down XP was the likely cause.
- **Milestone 24 (a sun and a moon, `MILESTONE_24.md`) is built, not pushed (18 Nov 2026):** three patches (position maths, drawing, hiding during football and sleep); decisions 76 to 78. Checked in a local web build at 10:00 (sun) and 20:00 (moon). Testing tip: in the web build the browser's keyboard does not reach Godot's name field, so a save made headlessly can be put into localStorage instead (write it again on `beforeunload`, `pagehide` and `visibilitychange`, or the game's own save on close replaces it).
- **Milestone 23 (sleep while the game is closed, `MILESTONE_23.md`) is built, not pushed (18 Nov 2026):** while the avatar sleeps, the device clock counts the real time away (phone off, tab closed) as sleep, never past the hours chosen; the Wake button stays; the day never uses the device clock (decisions 73 to 75). Same code on every device and OS: two device-clock readings, no page events. A real phone is not confirmed.
- **Milestone 22 (XP, `MILESTONE_22.md`) is built and committed, not pushed (18 Nov 2026):** XP follows the target health every step, at any level, plus the hourly bonus at 4.5 or more (decision 72). Decisions 68 to 71: no other ways to lose XP, no goals, values kept, a level is only a number. Only the XP-related tests were run, as the user asked.
- **New minigame ideas (team, "Ideias Extras v2", 16 Nov 2026), not built:** strength: the player chooses squats, push-ups or sit-ups and does the chosen exercise for real, on trust (user, 17 Nov 2026: nothing records or films the player, no camera and no phone sensors); cardio: the avatar seen from behind, running down a street with trees, the scenery coming closer and repeating; eating: a canteen (built in Milestone 21: Good food or Fast food, then build a plate of that kind; user, 18 Nov 2026). Both concept documents were updated on 17 Nov 2026 to say what is built and what is new (English concept section 8 and 9; Portuguese "Conceito do Jogo V3", which already had the ideas). The eating pace idea was dropped (user, 17 Nov 2026). Plan: `MILESTONE_19.md` (19 street, 20 squats, push-ups or sit-ups, 21 canteen). **Milestones 19 and 20 are built and committed, not pushed (17 Nov 2026).** The user played 19 once (street moving all the time, faster with faster taps, `minigame.min_gap_share` 0.25: done); 20 is not played yet. **Milestone 21 (the canteen, `MILESTONE_21.md`) is built and committed, not pushed (18 Nov 2026), in its third version: Good food or Fast food, then build a plate of up to 4 foods of that kind; a good plate is the healthy meal and a fast-food plate the fast-food meal (no change to the health model). Claude's placeholder foods and letter tiles until the team sends its examples and pictures. History of the three versions in `MILESTONE_21.md`.**
- **Web conversion (16 to 17 Nov 2026), stopped by the user and deleted on 20 Nov 2026 (user: "eliminate the javascript build"; `web/`, `pause.svg` and `settings.svg` removed, the `web-source` server too; it is in the git history before the delete):** the game logic, the logic tests and every screen were converted to plain HTML, CSS and JavaScript in `web/` (commits `d6787f6`, `91fa6a7`, `4aa6493`), side by side with the Godot project. The JavaScript scenario and parity tests print exactly what Godot prints; all 20 logic tests pass; the screens were checked in the browser (`web-source` server in `.claude/launch.json`, port 8070, page `/web/index.html`). Not done: the screen tests, the swap (serving from the repository root, deleting the Godot project), the Open Sans font. The user stopped it (17 Nov 2026); **the Godot game is still the published one** and still the source of truth. Do not continue the conversion unless the user asks.
- **Milestone 18 (the main menu, `MILESTONE_18.md`) is built and committed, not pushed (7 Nov 2026).** Continue, New avatar, Avatars (3 places), Load a backup, About, language.
- **Milestone 17 (the failure screen, `MILESTONE_17.md`) is built and committed, not pushed (7 Nov 2026).** A short phrase, Details drawn (tiles, bars, habit gauges) with short verdicts ("too thin", "could be better"). Short verdicts on the main screen were tried and undone at the user's request (`7f1750c`, reverted by `427a84e`).
- **After Milestone 16 (7 Nov 2026, in `MILESTONE_16.md`):** the team's upscaled avatar art, the places behind the activities (room, outside, bedroom from above with a blanket), day and night buttons, XP changes shown under the XP bar, one look for every bar, happiness 2 times slower (`mood.speed`), every figure the same height, and the level box in the game's style.
- **Milestone 16 (the avatar's requests, `MILESTONE_16.md`) is built and committed, not pushed (6 Nov 2026).** Decisions 57 to 60: requests only show what the model already does, the player answers by acting, every wish tied to our activities, hungry and tired in the same style. The user played the rounds after it (7 Nov 2026); Milestones 16 to 18 wait for the user's push. The team's avatar art (four sprite sheets, AI tool, CC BY 4.0) was added the same day, before playing (`MILESTONE_16.md`, "Avatar art").
- **Milestone 15 (the meal minigame, `MILESTONE_15.md`) is complete: the user played it and is happy with it (6 Nov 2026).** Tuned twice (fork speed and target between the first and the easy version; full from 6 bites). Pushed (`adb0ffe`, 6 Nov 2026). Decisions 52 to 56 are in `MILESTONE_15.md`; the user asked for it "fun, not too much science".
- **Milestone 14 (the football minigame, `MILESTONE_14.md`) is pushed up to `b040049`.** The third and fourth rounds (decisions 49 to 51 and more goals, `MILESTONE_14.md`, 1 and 2 Nov 2026) are pushed up to `2ce404d`; the user played them and is happy with them (4 Nov 2026). A real phone is not confirmed.
- **Milestone 13 (the strength minigame, `MILESTONE_13.md`) is complete and pushed.** The user played it and is happy with it. A real phone is not confirmed.
- **Milestone 12 (minutes slider and the cardio minigame, `MILESTONE_12.md`) is complete, pushed up to `839cd05`.** The taps in the web check were sent by a script, so how it feels for a person, and on a real phone, is not checked.
- **Milestone 11 (settings panel and European Portuguese, `MILESTONE_11.md`) is complete and pushed (`25aada7`).** Still to do: the team checks the Portuguese (Claude's draft, above all the health terms), and someone tries it on a real phone (the pop-up name box in Portuguese was not tried there).
- **Name on phones: the pop-up box stays (user, 30 Oct 2026).** `fe5c4c3` (`window.prompt`) is confirmed on a real Android phone. The virtual keyboard attempt `adfe369` never reached GitHub and was reverted untested on a real phone. The pop-up box was reported as doing nothing on 28 Oct, for an unknown reason (a cached old page is possible). Always confirm a push with `git ls-remote origin refs/heads/main` and the published file size: that push from GitHub Desktop failed silently.
- **Milestone 10.5 is complete and pushed** (27 Oct 2026, published on GitHub Pages; the user checked the game in the Godot editor first; `MILESTONE_10_5.md`). It acts on the team's review of the Milestone 10 differences (`documentation/milestone10_review.md`): failure reads the target health, a 36-hour gap between strength sessions, a danger state for severe thinness, a better scenario test and a parity test that found the causes of the differences (`documentation/milestone10_calibration.md`).
- **Milestone 10** (food as an activity + the whole health system rebuilt to Health Calculation Architecture v1) is pushed (`e3e6a89`, plus the handoff commit `6d3639b`).
- **All 33 tests pass** (7 Nov 2026, with the main menu, Milestone 18) (`tests/*_test.gd`; `calibration_test.gd` takes about 2.5 minutes and `parity_test.gd` about 5; the parity test prints numbers for the team and only fails if it crashes).
- **Waiting on the team:** the plan guesses, the training window, eating time and the hunger penalty, the danger-state and gap values (`documentation/milestone10_calibration.md`, "Proposals for the team"). No value was changed to fit the tests.

### Commit history of Milestones 12 to 18 and the web conversion

| Milestone | Commits |
|---|---|
| 12 (minutes slider, cardio) | `c892ecb` Task 1, `2fdf35e` Task 2, `096ef99` Task 3, `fba7c68` Task 4, `6912989` Task 5, `839cd05` and `4c7ca4b` Task 6 |
| 13 (strength) | `4b5235f` Task 1, `2c1a1e9` Task 2, `2087d08` Task 3, `c894f95` Task 4, `5461691`, `0817f91`, `8b7f38e` Task 5, `ac04189` played |
| 14 (football) | `a7ecc1a` Task 1, `4f8e644` Tasks 2 and 3, `a423c4a` Task 4, `56ba660` Task 5, `5eddda7` Task 6, `dec13a2` and `b67ae18` second round, `b040049` played, `4f2ab59` third round, `2ce404d` fourth round, `154e51e` pushed |
| 15 (meal) | `34e32b0` and `d9bc339` plan, `63f6711` built, `5292703`, `0befa12`, `4f73cbc` tuning, `adb0ffe` complete |
| 16 (requests) and after | `80bb167` plan, `79f4733` Task 1, `78737db` Task 2, `a187926` Task 3; `0c0cf5e`, `ccca5c4`, `7b735da` avatar art; `3211879` places and buttons; `d1e3dce` bed from above; `eb4542b` XP changes; `a9120a3` pillow and bars; `806eaec`, `520d40a` happiness 2 times slower; `5697095` level box |
| 17 (failure screen) | `bf82b25` built, `95e949c` explanations, `381ad23` short verdicts, `7f1750c` main-screen verdicts (undone by `427a84e`) |
| 18 (main menu) | `42bc2c8` |
| Web conversion (stopped) | `d6787f6`, `91fa6a7`, `4aa6493` |

### Commit history of Milestone 11

| Commit | What |
|---|---|
| `a4a9cc1` | Task 0: plan (`MILESTONE_11.md`) |
| `03c4ead` | Task 2: `Settings` autoload, language at start, `translations/strings.csv` |
| see `git log` | Task 3: every text a key; Task 4: Portuguese draft; Task 5: settings panel; Task 6: creation language buttons; Task 7: Start a new avatar; a fix for the deleted avatar coming back on the web; Task 8: Portuguese layout; Task 9: tests, export, docs |

### Commit history of Milestone 10.5

| Commit | What |
|---|---|
| `f89926e` | Task 0: plan (`MILESTONE_10_5.md`) and a copy of the team's review |
| `2d9ac90` | Task 1: failure reads the target health (decision 10) |
| `47e5d0b` | Task 2: 36-hour minimum gap between strength sessions |
| `2b8fce2` | Task 3: danger state of severe thinness, Ill look, health bar warning, failure causes, thinness risk term |
| `e3c6f06` | Task 4: scenario test method (exact player rule, failure for every scenario, new scenarios and rules) |
| `1926e49` | Task 5: parity test and the causes of differences 1, 2 and 4; training window averaged per day |
| `d761cef` | Task 6: docs and web export |

### Commit history of Milestone 10

| Commit | What |
|---|---|
| `7040dc1` | Milestone 4 leftovers (habit cost, gradual vs sudden), committed before starting |
| `d68119c` | Plan: v1 copy, `MILESTONE_10.md`, `documentation/milestone10_plan.md` |
| `e356e50` | Task 1: v1 config groups, WHO tables, `who_tables.gd` |
| `480c0ce` | Task 2: 20-minute day, `Simulation` (5-minute steps), can-sleep rule |
| `d35e37a` | Task 3: food as an activity, hunger, meals, energy spent |
| `a9e96d9` | Task 4: weight, body growth, z, energy deficit U, Screens and Football |
| `c8dd219` | Task 5: training (capacity, recovery, overreaching) |
| `bb22f0f` | Task 6: v1 sleep debt, Sleep measure, tiredness |
| `882518a` | Task 7: diet (Q, C, A) and Happiness (Mental removed) |
| `44fdb90` | Task 8: v1 Physical, health, failure, risk, XP, avatar looks |
| `2aebbe3` | Task 9: saves (version 2; Milestone 4 saves ignored) |
| `71c3530` | Task 10: v1 scenario tests (Bases fundamental check) |
| `e3e6a89` | Task 11: hourly CSV log, debug view, docs, web export, CLAUDE.md rewrite |

## 2. Decisions taken by the user (keep them)

Recorded in `MILESTONE_10.md` ("Decisions") and `documentation/milestone10_plan.md` ("Approval").

| # | Decision |
|---|---|
| 1 | Keep the slow health bar: v1 health is the **target**; the bar moves `health.alpha_bar` (0.37) of the way once per avatar day, when a sleep ends. |
| 2 | A meal takes avatar time (0.5 h, placeholder). |
| 3 | Only two meals for now: healthy meal and fast-food meal. |
| 4 | Entertainment has Screens and Football. |
| 5 | Minigame score fixed at 1 until minigames exist. |
| 6 | Saves from Milestone 4 or earlier do not load (save version 2). |
| 7 | Very hard starts with happiness **0.30** (not v1's 0.15), so it is playable; Very hard starts at health 1.49. |
| 8 | The body grows only inside its age group (child stops at 12 y 11 m, teenager at 18 y 11 m). |
| 9 | Diseases: only the risk index and hidden damage, in the debug panel; no stages. |
| A | CSV log: one line per avatar hour. |
| B | Rename Mental to Happiness in English only; Portuguese and English translations in a later milestone. |
| Task 5 | A strength session that starts below 60% recovery is "too soon": **no effective minutes**, only overreaching. |
| Task 0 | A meal counts when it ends, in proportion to the time eaten (planned as spread over the half hour; changed in Task 3, recorded in the plan). |
| 10 | (Milestone 10.5) Failure reads the **target health**, not the slow bar (replaces the failure part of decision 1; XP still uses the bar). |
| 11 | (Milestone 10.5) The danger state of severe thinness ends **only when z is back at −3 or above**. |
| 12 | (Milestone 10.5) Scenario plans: use what we know (our plans + the review's corrections) and list every guessed detail for the team. |
| 13 | (Milestone 10.5) Work through all tasks in a row, committing each; no push; the user reviews at the end. |
| 14 | (Milestone 11) Settings hold the language and "Start a new avatar" with a confirmation. Music and sound wait for the music. |
| 15 | (Milestone 11) First start follows the browser's language (any Portuguese gives Portuguese, otherwise English); the creation screen also has PT and EN buttons. |
| 16 | (Milestone 11) All tasks in a row, each committed; no push; the user reviews at the end. |
| 17 | (Milestone 12) The first minigame is cardio. |
| 18 | (Milestone 12) The minutes slider is built before the minigame. |
| 19 | (Milestone 12) If the player does not tap, the activity is not done: the avatar does not do it and returns to normal after some seconds. |
| 20 | (Milestone 12) The minigame score counts as the player goes, not once per session. |
| 21 | (Milestone 12) How the player scores well and how long they tap are decided during development (answered by 22 and 27). |
| 22 | (Milestone 12) Cardio scores both rhythm and steps; the time between steps and their number depend on the avatar, and it tires. Follow the science. |
| 23 | (Milestone 12) Those values come from fitness, BMI-for-age z and sleepiness, not the Physical bar. |
| 24 | (Milestone 12) One tap is one stride, two steps (replaces the concept's "each click is one step"). |
| 25 | (Milestone 12) The new fatigue applies inside each session only (replaces the concept's "no separate fatigue system"). |
| 26 | (Milestone 12) When the Breath bar is empty the avatar walks until it refills. |
| 27 | (Milestone 12) The player taps for the whole session. |
| 28 | (Milestone 12) With no tap the avatar stands still and waits up to 20 seconds, then the activity ends. |
| 29 | (Milestone 12) Football has no minigame for now and keeps the fixed score. |
| 30 | (Milestone 12) All steps in a row, each reviewed and committed; no push; the user reviews at the end. |
| 31 | (Milestone 13) A strength session is sets, repetitions and rest; Down then Up is one repetition. |
| 32 | (Milestone 13) Repetitions and sets come from strength, BMI-for-age z and sleepiness. |
| 33 | (Milestone 13) The score is half technique, half finishing the repetitions. |
| 34 | (Milestone 13) Tired muscles end a set early and the avatar rests; it never trains to failure. |
| 35 | (Milestone 13) A session started too soon: the avatar warns, and the player can still play. |
| 36 | (Milestone 13) When the avatar's sets are done and minutes are left, more sets follow until the time ends. |
| 37 | (Milestone 13) Stopping works as in cardio; the rest between sets is not stopping. |
| 38 | (Milestone 13) All steps in a row, each reviewed and committed; no push; the user reviews at the end. |

Other team decisions that still hold: k = 10 (applies to sleep debt too); there is no death, only failure; p = 0.5 for health. The team's review (27 Oct 2026) added the 36-hour strength gap, the danger state (z −3, 72 h, z −4) and the thinness risk term (placeholders).

Decisions 39 to 51 (Milestone 14, football) are in `MILESTONE_14.md`. Decision 39 replaces decision 29. Decisions 52 to 56 (meals) are in `MILESTONE_15.md`, and 57 to 60 (the avatar's requests) in `MILESTONE_16.md`. Decisions 73 to 75 (Milestone 23, user, 18 Nov 2026): 73 the device clock is read only during sleep, to count time away; 74 the Wake button stays after a sleep that ended while away; 75 no limit on the time away (the sleep is the limit), and it must work on every device and OS. Decisions 76 to 78 (Milestone 24, user, 18 Nov 2026): 76 the clock stays 24-hour, no AM/PM (replaced by 80); 77 a sun and a moon cross the sky in an arch, left to right, on the `daylight` hours; 78 hidden during football and sleep. Decision 90 (Milestone 26, user, 19 Nov 2026): XP is never lost (it replaces the "down" half of decision 72); Decisions 93 to 97 (Milestone 27, sleep model v2, Claude's proposals built on the user's request, table in `MILESTONE_27.md`). Decision 92 (19 Nov 2026): every rise gives XP, also after a fall, so XP can be farmed (the user wants that; at health 5 the hourly bonus and every rise keep XP coming). Decisions 79 to 89 (Milestone 25, user, 18 Nov 2026, table in `MILESTONE_25.md`): 79 the team's interface specification is the rule; 80 12-hour clock with AM/PM; 81 the Wake button disappears (the play button next to the clock starts the day; the game still waits after a sleep); 82 the danger warning flashes; 83 "Health N" is rounded down; 84 colours of the mockups, the same day and night; 85 curved ground following the sky; 86 sunrise 07:00, sunset 19:00; 87 the sky fills any screen, the game keeps its proportions (aspect `expand`); 88 Nunito; 89 the activity backgrounds redrawn in the same task.

## 3. What is still open

**For the team** (with numbers and proposals in `documentation/milestone10_calibration.md`, Milestone 10.5): the causes of the six differences are found. (1) The severe diet: the scenario's screens hour blocks one hungry moment a day (without it the game eats exactly v1's 2.33 meals and 1,145 kcal); not a model difference. (2) Happiness: mostly plan details v1 does not describe (30 min of football in the guideline activity, 2 h of screens without sport), plus half-hour meals and the hunger penalty for 4 h of cardio. (3) Resolved by the review. (4) Guideline strength: the 24-hour training window makes strength rise and fall through the week; a one-week window gives 0.76. (5) Decision 1 only. (6) Compared with the wrong row. To decide: the plan guesses, `train.average_window_h`, eating time and METy, the hunger penalty with fixed portions, the danger-state and gap values.

**Graphics done elsewhere (20 Nov 2026):** `documentation/graphics_brief.md` is the brief for a second Claude account. It arrived on 21 Nov 2026 (Milestone 40). Read only `values.md`, `changes.md`, `files.md` and `licence.md` (never the pictures in `work/`), copy the values into the code, then run only the UI tests they touch.

**Not decided** (do not guess; see `CLAUDE.md`, "Not decided yet"): researched values for every placeholder; diseases; food menus and tastes; full entertainment menu; whether football counts toward the 60 minutes (it does for now); activity durations; avatar art; other settings; the Portuguese wording until it is checked; server and accounts.

**Proposed in Milestone 11, not confirmed by the user or team:** European Portuguese for all browsers, wording that does not depend on the avatar's sex, the decimal comma, the pause while settings are open, English in the debug panel and logs.

**Likely next** (ask the user): the plan in `MILESTONE_19.md` (the street run, squats, push-ups or sit-ups, the canteen; section 1); a minigame for screens (decision 54); the team's answers to the Milestone 10.5 proposals; food menus and tastes; the lobby's pictures and music; plasticine art. (A 45-minute strength option would not raise strength: Milestone 10.5 parity run.)

**Placeholders added in Milestone 10.5:** the Ill look (pale, greenish body), the health bar warning (red bar, "Health: danger") and the failure messages by cause; the review's numbers (`train.strength_min_gap_h` 36, `fail.danger_z` −3, `fail.danger_hours` 72, `fail.danger_failure_z` −4, `risk.thin_weight` 0.4, `risk.thin_from` −2, `risk.thin_range` 2).

**Placeholders added by Claude during Milestone 10** (not in v1; the team should check them): starting habituation A = 1 − Q; new avatar's hunger 0.8 meals; `risk.safe_level` 0.3 and `risk.damage_tau_days` 365; owners (Pessoa 1 to 4) of every new config value; METy while eating 1.5; default sex female before the player chooses; which activities count as cardio, strength, football, screens and exercise.

## 4. How to work with this user (what worked)

- **Write everything that is done in the .md files** (user, 18 Nov 2026), with each change: the milestone file, `CLAUDE.md` and this handoff.
- **Run only the necessary tests when a milestone is finished** (user, 18 Nov 2026): the tests that touch what changed, plus the scenario test when the health or XP numbers could move.
- **When a request is ambiguous, ask with the two readings side by side before building** (Milestone 21: "prato" is both plate and dish, and "two choosers" was read three ways; two rebuilds followed).

- The user is a 9th-grade student. Plain language, exact steps, and after each step: what changed, how to run it, what to check.
- **One task at a time.** The user replies "Commit Task N, then start Task N+1" (or "Commit Task N"). Each task ends with a summary, the test results and the question whether to commit; nothing is committed without that. Exception: for Milestones 10.5 and 11 the user chose "all tasks in a row, each committed, review at the end" (decisions 13 and 16); ask again at the start of each milestone.
- When a new team decision contradicts an earlier user decision (example: the review said failure should read the true health, decision 1 said the bar), ask the user before changing it, with a proposed default.
- **Never push without asking.** Pushing publishes the game on GitHub Pages. (This shell has no GitHub login, so the user pushes from GitHub Desktop: give them the steps, then confirm with `git ls-remote origin refs/heads/main`. The commit "Milestone 10.5: status pushed" and earlier ones went up that way.)
- When a test result differs from v1 or a rule fails, **do not change values to make it pass**: report the numbers, propose options, and let the user decide (example: the too-soon strength rule in Task 5).
- Questions to the user go with a proposed default; record their answers in the milestone file.
- Be honest about own mistakes and fix them (example: the CLAUDE.md cut-off in Task 8, found and repaired in Task 11).

## 5. Lessons learned (technical)

- **Godot binary:** `"/Applications/Godot 2.app/Contents/MacOS/Godot"`. Check scripts: `... --headless --path . --quit`.
- **Slowing a value that relaxes toward a target and gets pushed per hour:** a longer time constant alone makes every per-hour push stronger (its full effect is rate x time constant), so dips get deeper. To change only the pace, divide the time constant and multiply every push by the same factor (`mood.speed`, 7 Nov 2026).
- **Hide minigame pieces before an early return.** `_refresh_minigame()` in `scripts/ui/main.gd` returns early when no minigame runs; anything hidden only after that return stays on screen when the minigame ends (the meal fork and its zone stayed through the next sleep, 7 Nov 2026).
- **To set the time of day in a script, set the Clock's phase start.** `Clock.minute_of_day` is worked out again every frame from `_phase_start_minute`, so setting it alone is undone at once.
- **Do not `load()` a texture inside `_draw()`.** It is drawn as a white box (seen in the Compatibility renderer on the Mac and on the web); load it when the state changes and keep it in a variable (`scripts/avatar/avatar.gd`, 7 Nov 2026). Headless tests cannot see this: render a frame in a window (`--path . --resolution 720x1280 -s <script>` and `root.get_texture().get_image().save_png()`) to check drawing.
- **Textures larger than 4096 pixels fail on many phones.** Keep each texture below that (the avatar art is 100 pictures of 660 x 900).
- **Changing an `.import` file's settings and running `--import` headless re-imports the texture** (lossy WebP and mipmaps were set this way for the avatar art).
- **Tests hang on script errors.** A test that hits a script error never calls `quit()`, so Godot runs it forever. Always run tests with a time limit:
  `perl -e 'alarm 300; exec @ARGV' "/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s res://tests/<name>_test.gd`
- **Scripts in `scripts/health/` use the autoloads (`Config`, `GameState`, …).** A test script is compiled before the autoloads exist, so tests must `load()` these scripts at run time, not `preload` them. Game scripts (autoloads, UI) can preload them.
- **No numbers in the health scripts** (`tests/config_test.gd` checks with a regex; only 0 and 1 are allowed). Even `2.0` in `pow(x, 2.0)` or `1e-6` fails; use the `units` group in config, `x * x`, or `log(0) = -inf`.
- **Autoload order matters.** `Simulation` is listed before `Activities`, so it hears each frame's time while the activity still runs; it splits a frame at the end of a day activity, and `Activities.changing` (emitted just before an activity starts or ends) flushes the pending minutes. Without this, the last minutes of an activity get the wrong METy.
- **Loading a save repeats events.** `Clock.from_dict()` emits `phase_changed` and `Activities.from_dict()` emits `started`; `SaveGame.load_game()` sets `Simulation.loading` so no new day or activity start runs again, and resets `Simulation` first.
- **JSON reads every number as a decimal.** Convert whole numbers back on load (the `hour` of the hourly windows, the `day` of log entries); compare saved values with a tolerance.
- **Hourly windows** (`scripts/health/hour_window.gd`) keep one slot per hour plus one; the oldest counts only for the part still inside the 24 hours, so sums are true sliding sums. New windows are pre-filled so a new avatar starts in balance (energy) or steady (training).
- **Simulated players in scenario tests must eat when the avatar is hungry** (as a real player), not at fixed times; fixed meals left the avatar hungry and unhappy and gave wrong conclusions (found in Task 7).
- **Web build check:** start the `web-build` server in `.claude/launch.json` (port 8060). In the browser, Godot reads single key presses, not pasted text (the name field needs key presses).
- **Scripted edits of documents:** after a Python replace, check the end of the file still exists (`grep -n "^## " CLAUDE.md`); in Task 8 a slice without its tail cut CLAUDE.md in half.
- The data files `foods.json` and the WHO tables are included in the web export through `include_filter="data/*.json"` in `export_presets.cfg`.
- **A test can extend another test.** `tests/parity_test.gd` starts with `extends "res://tests/calibration_test.gd"`, overrides `_process` and `_record_step` (calling `super(...)`), and changes config values in memory through `Config._data` (never the file). Activity lengths can be changed in memory in `Activities.definitions`.
- **Scenario tests: find the cause before blaming the model.** In Milestone 10.5 two of the "model" differences were how the scenario was played: a planned activity blocked a hungry moment (the player cannot answer during an activity), and the 24-hour training window made the day-21 value depend on the weekday. Print counts (meals, skips, too-soon sessions, minutes beyond capacity) and day-by-day values, and change one thing at a time.
- **k = 10 magnifies small energy differences:** 20 kcal a day (half an hour of eating at METy 1.5 instead of idle 1.7) is about 0.4 kg in 21 avatar days.
- **Activities must not run into the end of the awake period** in tests: the 0-hour rule starts a new day. The scenario test cuts an activity 0.01 h before the end.
- **New test scripts get their `.uid` file only when the Godot editor scans the project**; commit the `.uid` files it creates.
- **Translations:** after changing `translations/strings.csv`, run `Godot --headless --path . --import` before headless tests; the `.translation` files are ignored by git (`MILESTONE_11.md`). `tests/translation_test.gd` checks both languages, the formats, that every key exists and is used, and that no scene holds plain text. Tests that read text call `TranslationServer.set_locale("en")` or `Settings.set_language()` first, because the game follows the computer's language.
- **Never trust an empty diff of two runs:** check first that both really finished. In Milestone 12 a before-and-after comparison of the scenario test was empty because both runs had been killed by the time limit, with the game open in the browser pane using the CPU. Count the PASS lines first.
- **Comparing two versions of the project:** `git archive <commit> | tar -x -C <folder>` in the scratchpad gives a clean copy with no git link. It needs its own `--import`.
- **Sending keys or touches to the web build from a script:** `new KeyboardEvent` or `new TouchEvent` dispatched on the canvas reach Godot, so a session can be played from `setInterval`.
- **The AAP 2020 report** is at `https://ncys.org/wp-content/uploads/2022/10/Resistance-Training-for-Youth_AAP-Position-Paper.pdf`. WebFetch reads it badly; save it and extract the text with PDFKit through `osascript -l JavaScript` (`ObjC.import('Quartz')`), because this Mac has no pdftoppm or pypdf.
- **A test can print ALL PASSED after SCRIPT ERROR lines:** always look for those too (`grep -E "SCRIPT ERROR|^ERROR"`), as the time-limit advice above does not catch them.
- **Reading the cadence paper:** PMC shows a reCAPTCHA to scripts and Springer asks for a login. The public Europe PMC API has the full text: `https://www.ebi.ac.uk/europepmc/webservices/rest/PMC5828000/fullTextXML`.
- **Deleting on the web is not immediate.** `DirAccess.remove_absolute` on `user://` does not reach IndexedDB at once, so a deleted save can return after a reload, and a headless test cannot see this. Use something written to localStorage, which is immediate (`WEB_DELETED_KEY` in `save_game.gd`), and test with a real reload in the browser.
- **The web build takes about 20 seconds to boot in the browser pane.** Do not read the Godot splash as a hang: check the console log first. To try another browser language, open a file on the fresh origin `127.0.0.1:8060`, override `navigator.language` on `Navigator.prototype`, load `/index.js` and call `new Engine(config).startGame()`; rewriting the page with `document.write` does not work.
- **Shell:** macOS `sed` has no `\b`; use `perl -pi -e`. The Edit tool needs the file read first with the Read tool.
- **Text fields on phones (web):** any new text field needs the pop-up box of `scripts/ui/creation.gd` (web + touch screen: the field never takes focus, a tap calls `window.prompt` through `JavaScriptBridge.eval`). Without it the keyboard opens but no letters arrive. The alternative, the export option `html/experimental_virtual_keyboard`, worked in phone emulation but was never tried on a real phone; if it is ever used, its text arrives through `set_text`, which does not emit `text_changed`, and the option is stored in `index.html`, not the .pck. GitHub Pages lets phones keep old files for up to 10 minutes.
- **Testing phone input in the browser pane:** `resize_window` preset mobile (the page then reports a touch screen), a fresh origin (a new port such as `127.0.0.1:8062`; the game re-saves when the page closes, so an origin with a save skips the creation screen), refresh cached files with `fetch(url, {cache: 'reload'})` for `'/'`, `index.html` and `index.pck`, then check `GODOT_CONFIG` really says `experimentalVK: true`. Send a real touch (`new TouchEvent('touchstart'/'touchend')` with a `Touch` on the canvas), check that a hidden `INPUT` is the `document.activeElement`, and type with the `computer` tool. A real Android phone is still the only full test.

- A test whose autoloads load a real save starts from that save. Reset `Simulation` with the others, or its pending minutes run into the new state (Milestone 14: `difficulty_test.gd`). Running tests with `HOME` set to an empty folder shows whether a failure comes from a save.
- In `football_match.gd` y grows towards the other goal, the opposite of the screen, so a stick up is `Vector2(0, 1)`.

- A test player must be human-like to judge a match: the perfect one won 8 to 0 while one with human reactions lost 2 to 23 against the same values (`_human_match` in `tests/football_test.gd`).
- `Activities.start()` now unpauses before `started`, so a screen opening at the start can pause the day.

- A match can look healthy and still stall: count who holds the ball and who shoots. Red once passed sideways for ever, and very few goals were the only sign.

- A rule can quietly apply to every case: the last defender always stood on the shot line, so every shot was "blocked". When a number is far from what players see, look for a condition that is always true.

- Running tests with `HOME` set to an empty folder hides Godot's export templates too: export with the normal `HOME`.
- The user wants minigames fun first. Keep the science to one idea and one line; do not lead with studies.

- **Milestone 25 lessons (drawing):** a `top_level` Control is drawn on top of the others, so a full-screen background needs a negative `z_index` (sky −3, sun and moon −2, ground −1 in `ui_style.gd`). Set its anchors to top-left before setting its size, or Godot warns. Polygons have no antialiasing in the Compatibility renderer: draw a thin antialiased polyline of the same colours around them (`Ui.fill_vertical_gradient`). `Geometry2D.clip_polygons` cuts the crescent moon and `intersect_polygons` the half-full pill. A panel's script `_draw()` runs after its stylebox, so the balloon's tail can cover the outline.
- **Rendering pictures on this Mac:** a Godot window that is not in front stops drawing after its first frames (even `RenderingServer.frame_post_draw` never comes), so `tools/render_ui_states.gd` sets the whole state before the screen opens and renders one state per run. An early frame drawn before the first layout can show wrong values (the stage has no size yet): guard such reads.
- **Colours in tests:** `==` on colours is exact; a theme stores rounded numbers, so compare with `is_equal_approx`, or write the token's exact value in the `.tres`.
- **Translation keys used only in scripts must start with a known prefix** (`UI_`, `SPEECH_`, ...; `tests/translation_test.gd`), or the test reports them as unused.

## 6. Commands

```
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --quit
for t in tests/*_test.gd; do perl -e 'alarm 400; exec @ARGV' "/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s "res://$t" 2>&1 | grep -E "ALL PASSED|SOME FAILED" | sed "s|^|$t: |"; done
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --export-release "Web" docs/index.html
"/Applications/Godot 2.app/Contents/MacOS/Godot" --path . --resolution 720x1280 -s res://tools/render_ui_states.gd -- <folder> <state: A to F, P, X, R, S, Z, W, M, N> [en|pt]
```

Debug keys in the editor: F6 reload config, F7 debug panel, F9 time speed. The debug CSV log is in `~/Library/Application Support/Godot/app_userdata/My Healthy Avatar/health_log.csv`; the save is `save.json` in the same folder (delete it to start a new avatar).
