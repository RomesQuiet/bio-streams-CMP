# Milestone 40 — the new look from `documentation/ui_v2/`

Started 21 Nov 2026 (40 is the user's number; there are no Milestones 36 to 39).

**Source:** the second Claude account's pass 3 (`documentation/graphics_brief.md`), delivered as `ui_v2.zip` and unpacked to `documentation/ui_v2/`: `changes.md` (12 changes in order, decisions Q1 to Q11, a table for every element), `values.md` (colours), `files.md` (pictures), `licence.md`, and `assets/` (the pictures). `work/` (mockups and scripts) is not read, except one picture of `work/layout_check/` when a table is unclear. `documentation/ui_v2/.gdignore` keeps Godot from importing those files; the pictures used by the game are copied to `assets/art/`.

**How we work (user, 21 Nov 2026):** the 12 changes one at a time, in order. After each one: headless check, only the tests it touches, a commit, and what to check in the Godot editor; then wait for the user's OK. Nothing in the health model, the minigame rules or the timings changes; only the look, plus the canteen list in change 12. The fast-food canteen has 8 foods (4 columns) until the team sends two more. **No push and no publishing:** `licence.md` says the team must first confirm that the image tool allows CC BY 4.0.

**Before change 1:** the Milestone 35 work (the video game), which was built but not committed, was committed on its own (`d90bbe1`) so each change of this milestone is a clean commit.

## Changes

| # | Change | State | Commit |
|---|---|---|---|
| 1 | Colours (`values.md`) | done, waiting for the user's check | see git log |
| — | The splash screen (main menu), asked by the user | done, waiting for the user's check | see git log |
| 2 | Activity dock (squats, push-ups, sit-ups, meal; screens waits for the change 7 question) | done, waiting for the user's check | see git log |
| 3 | Exercise pictures | done, waiting for the user's check | see git log |
| 4 | Cardio panel and running pictures | done, waiting for the user's check | see git log |
| 5 | Football field, minimap, score, panel | done, waiting for the user's check | see git log |
| 6 | Meal: eating pictures, dock band | done, waiting for the user's check | see git log |
| 7 | Screen time | **skipped (user, 21 Nov 2026)**: Screens is the video game (Milestone 35) | — |
| 8 | Sleep: bed, window, Wake up | done, waiting for the user's check | see git log |
| 9 | Exercise and entertainment menus | done, waiting for the user's check | see git log |
| 10 | Let's eat | done, waiting for the user's check | see git log |
| 11 | Canteen with pictures | done, waiting for the user's check | see git log |
| 12 | Canteen list (`data/canteen.json`) | done, waiting for the user's check | see git log |

### Change 1: colours

- `scripts/ui/ui_style.gd`: the four big buttons: exercise `#93f7e0` (was `#84f2da`), sleep `#d9c6fd` (was `#cdbcf7`), eat `#fea6b5` (was `#ffa6a6`), entertainment `#ffe385` (was `#ffe27a`). The video game's Jump button uses the entertainment colour, so it changes too.
- `scripts/ui/sky_palette.gd`: the night rows 0:00 and 4:45: top `#151a5f`, middle `#1d2471`, horizon `#2b3184` (unchanged), ground top `#252d85`, ground bottom `#22287a`. The 24:00 row is the same as 0:00 (it closes the day; the interface test checks that midnight joins), so it changed with it. Every other row stays (the day ground keeps Milestone 26's green, Q5).
- The new constants of `values.md` (`## new`) are added with the change that first uses each one, so no constant sits unused.
- Not changed: `meal_fork.gd` has its own copy of the old mint (`GOOD_COLOR`, the green zone); change 6 replaces it with `ZONE`.
- Checked: headless start without errors; `interface_test` (sky palette, buttons) ALL PASSED.

### Pictures copied (`a4d22f4`)

`documentation/ui_v2/assets/` copied to `assets/art/` with the same sub-folders (`avatar/<sheet>/` beside the existing pictures, no name clash; `food/`, `menu/`, `scenery/`), 86 PNG files, imported as lossy WebP quality 0.85 with mipmaps (the `.import` files were set, then `--import` again).

### The splash screen (the main menu), asked by the user on 21 Nov 2026

The user sent a picture of the main menu (900 x 1600, the team's splash screen) and asked for it to be built before going on. It is not in `changes.md` (which says the menu stays), so it is an extra step between changes 1 and 2. Everything was measured from the picture and scaled by 0.8 to the 720 x 1280 column; the colours were read from its pixels (median of a 5 x 5 patch).

- `scripts/ui/menu_backdrop.gd` (new): the background over the whole screen: a sky that is a sunset on the left and night on the right (an 11 x 3 table of colours, interpolated on a mesh), the sun at (74, 318), the crescent moon at (634, 296), 14 stars on the right, three soft clouds, and a round blue hill (top at y 596) with a light rim; the shadows under the figures. It does not follow the game's clock.
- The four figures stand on the hill, from the team's art: `child_male/healthy_happy`, `teen_female/obese_sad`, `child_female/healthy_happy` and `teen_male/bed.png` (from the ui_v2 pictures). The splash shows the boy running and the girl eating an apple: there are no front pictures for those poses, so they stand (to change when the team makes them).
- The title "My Healthy Avatar" (ExtraBold 64, white with a thick navy outline and shadow, made smaller if it does not fit, so "O Meu Avatar Saudável" fits) and the subtitle (ExtraBold 24, the existing text).
- `scripts/ui/menu_button.gd` (new): the menu buttons: x 90, width 540, faces 86 high and a 6-pixel thickness at y 691, 799, 908 and 1016; mint New avatar (a person with a plus), blue Avatars (three people), lavender Load a backup (a cloud with an arrow), pink About (an "i"). Icons drawn in `ui_icons.gd`; colours `MENU_*` in `ui_style.gd`. Pressed: the face moves down by its thickness and comes back in 0.14 s.
- `scripts/ui/language_toggle.gd` (new): the PT / EN switch (238 x 56 at y 1142): the chosen half is a light pill with a cyan line. It replaces the "Português" and "English" buttons.
- **Continue is not in the splash; it is kept** (Claude's choice, so a player can go straight back to the last avatar): when there is a save, a gold Continue button (a play icon, "Continue" and the avatar's line under it) comes first and the five buttons are a little closer together (tops 644, 740, 836, 932, 1028; 84 high). Without a save the screen is exactly the splash.
- The buttons and the switch keep their distance from the bottom of the screen; the title, the figures and the hill keep theirs from the top (as before). The Avatars and About pages did not change.
- Checked: headless start without errors; `menu_test`, `translation_test`, `interface_test`, `settings_test` ALL PASSED; the menu rendered with `tools/render_ui_states.gd` (state M) in English and Portuguese and compared with the picture.

### Change 2: the activity dock (user's go-ahead, 21 Nov 2026: "continue the big task")

For squats, push-ups, sit-ups and meals, at the places of the tables "Squats, push-ups, sit-ups" and "Meal" (changes.md).

- **Where:** the minigame panel is 362 high during these activities, so the stage ends at y 790 and the feet are at y 730; the stop slot is y 806 to 870 and the panel starts at y 886, as the tables say. The panel stays a column of rows (`MinigamePanel`); three spacers (`Gap1` to `Gap3` in `scenes/main.tscn`) put each row at its top: info line y 886, Muscle bar y 922, timing bar y 960 (meal: the Tummy bar at y 944), the two buttons at y 1032. `main.gd`: `_layout_dock()` (only when the minigame, option, keys or language change), `_style_strength_buttons()`, `_style_meal_buttons()`, `_fit_status()` (the status on one line, 22 down to 16). Cardio, football and the video game keep their look until changes 4 and 5.
- **Stop pill** (`scripts/ui/stop_pill.gd`, new; the `StopButton`): 260 x 64 at x 230, y 806, STOP colour, a 6-pixel thickness, a navy square and "Stop" (ExtraBold 30). The button is 88 high around the pill (touch area, rule 2). It is the stop button of every activity for now (changes 4, 5 and 8 give cardio, football and sleep their own).
- **Big buttons** (`scripts/ui/dock_button.gd`, new; `DownButton`, `UpButton`, `BiteButton`, `DoneButton`): DOWN 327 x 176 (DOWN colour, white icon, arrow and word, chip "↓  S" outlined), UP (UP colour, navy, chip "↑  W" filled), Bite 444 x 176 (a fork, a divider, "Bite!" ExtraBold 52, "[Space]" under it on a computer), Done 210 x 176 (SLEEP colour, "[D]"); radius 32, a thickness of 8, pressed: the face moves down 8 and comes back in 0.14 s; disabled: 45%. The exercise icon is a squat for squats and a figure lying down for push-ups and sit-ups (`ui_icons.gd`: "squat", "pushup", "situp", "fork").
- **Timing bar** (`scripts/ui/beat_bar.gd`, rule 5): round ends, a 3-pixel white outline, the green zone (`ZONE_COLOR`) inset 6 with radius 18; for strength the marker is a white ring (radius 22, line 5, 4 ticks of 10). The Tummy bar: the same, with the white fill to the bites eaten and the zone from "full" to the end. Cardio's Beat bar gets the new track and zone now (its height and marker in change 4).
- **The speech balloon** has its top at y 208 during every activity (rule 8).
- **Keys:** the chips say S and W, so S and W now press DOWN and UP too (the arrows still work). Only an input; no rule changed.
- **Not as the table says, on purpose:** Done is **not** disabled until the avatar is full. The table says "disabled at 45% until full, as now", but today Done always works (`Minigame.done()`), and the minigame rules must not change. To decide by the user.
- **Screen time is not in this change:** its dock (screen-time bar, Keep watching, Take a break) is for plain screen time, but Screens is the video game since Milestone 35 (see below).
- New colours in `ui_style.gd`: `STOP_COLOR`, `STOP_BASE`, `MINIGAME_UP_COLOR`, `MINIGAME_UP_BASE`, `MINIGAME_DOWN_COLOR`, `MINIGAME_DOWN_BASE`, `SLEEP_BASE`, `ZONE_COLOR`, `CHIP_COLOR`, `DISABLED_ALPHA`.
- `tools/render_ui_states.gd`: a new state K (squats).
- Checked: headless start without errors; `minigame_test`, `meal_test`, `canteen_test`, `interface_test`, `translation_test`, `requests_test`, `scenery_test` ALL PASSED; squats (K) and a meal (R) rendered in English, the meal in Portuguese too, and compared with the tables.

### Change 3: exercise pictures (user: "OK, do change 3", 21 Nov 2026)

- During squats, push-ups and sit-ups the avatar is hidden and `ExercisePicture` (a TextureRect in the stage, `scenes/main.tscn`) shows the exercise's picture of the avatar's sheet: after DOWN the "down" one, after UP the "up" one; before the first press and while resting `squat_up`, `pushup_up` or `situp_down`. The healthy body is used for every body (Q8).
- Rects from the tables, kept at the same distance from the stage's bottom (y 790), so the feet are on y 730: squats 195, 295, 330 x 450; push-ups 110, 394, 500 x 340; sit-ups 130, 374, 460 x 360 (each the canvas's own aspect, never cropped or stretched).
- `main.gd`: `EXERCISE_PICTURES`, `_refresh_exercise_picture()`; the three pictures are loaded when the option or sheet changes, never while drawing. The ground's shadow under the avatar stays.
- `tests/minigame_test.gd`: new checks (the down and up pictures, the rest picture, sit-ups resting lying down, the rect, the avatar back after the exercise). `tools/render_ui_states.gd`: K is now squats after DOWN; new U (push-ups after DOWN) and V (sit-ups before the first press).
- Checked: headless start without errors; `minigame_test` ALL PASSED; K, U and V rendered: the three figures stand on the ground line.

### Change 4: cardio (user: "OK, do change 4", 21 Nov 2026)

Table "Cardio on the street (01)".

- `scripts/ui/cardio_panel.gd` (new; `CardioPanel` in the minigame panel, 488 high from y 760): the panel (x 12, y 760, 696 x 496, radius 28, navy at 92%, a white line), the runner icon, "CARDIO" (ExtraBold 30), the minutes "7 / 60 min" (Bold 26, right to x 476), Steps with "16 / 173" and the Steps bar (`STEPS_FILL`), Breath and its bar (`BREATH_FILL`), the timing box (INK at 35%) with "Timing" and "Tap in the green zone!".
- Its children: `CardioStop` (the small Stop pill, 200 x 48 at x 484, y 780, a thickness of 4; the stop slot above the panel is hidden), `CardioBeat` (the timing bar 640 x 48 at x 40, y 1036, its marker a white bar 8 x 64 with radius 4) and the `TapButton` (648 x 112 at x 36, y 1112, radius 40, footprints and "TAP TO RUN" in capitals; "[Space]" not shown; Space still taps).
- The stage ends at y 744 (feet on y 684). The dark silhouette is replaced by the running pictures `run_01` to `run_05` (seen from behind) at 80%: rect 228, 336, 264 x 360; a new frame at each tap, `run_01` while waiting.
- **The status ("Tap to start!", "Running", "Walking: catching my breath") is not in the table**, so it is not shown any more (it is still worked out, in the hidden info line, and the tests read it). To decide by the user whether it should come back somewhere.
- New keys: `CARDIO_TITLE`, `MINIGAME_STEPS_LABEL`, `TIMING`, `TIMING_HINT` (Portuguese from `changes.md`); `tests/translation_test.gd` knows the `CARDIO_` and `TIMING` keys and reads `cardio_panel.gd`. New: `ui_style.gd` `STEPS_FILL`, `BREATH_FILL`, `PANEL_92`; `ui_icons.gd` "footprints"; `beat_bar.gd` `marker_height` and `marker_radius`; `dock_button.gd` `upper`.
- `tests/minigame_test.gd`: new checks (the panel and the hidden stop slot, `run_01` while waiting, the next frame after a tap, the panel's steps and minutes, the stop slot back for strength).
- Checked: headless start without errors; `minigame_test`, `translation_test`, `interface_test`, `scenery_test` ALL PASSED; state S rendered in English and Portuguese.

### Change 5: football (user: "OK, do change 5", 21 Nov 2026)

Table "Football (11, 12)". For a circle the table's x and y are its centre (as for the plate's ellipses); the check picture `work/layout_check/football.png` confirms it (the joystick at 156, 1044 with radius 92 ends above the help strip).

- **Field:** x 20, y 210, 680 wide, down to y 796 (it stretches with the screen). `scripts/ui/field_mask.gd` (new; `FieldMask` around `FootballField`) draws the rounded shape (radius 28) and clips the field to it with `clip_children` (checked in a render: it works with the Compatibility renderer). `football_field.gd`: 8 fixed stripes (`FIELD_STRIPE_A` at the top, then B), a 3-pixel white line around, the minimap 90 x 100 at the field's top left (`FIELD_STRIPE_B`, a white line, the players as dots of radius 3: red, blue, the avatar yellow; hidden when the whole field fits), the score in a capsule 100 x 40 at the top right (INK at 35%). The markings, arrows, players, ball and hint banner are as before. The plain backdrop colour of football is no longer drawn (it showed as a box at the rounded corners).
- **Panel:** `scripts/ui/football_panel.gd` (new; `FootballPanel`, 436 high from y 812): the panel (16, 812, 688 x 424), the ball icon, "FOOTBALL", the minutes, a divider, Breath and its bar. The stop slot above it is hidden; its own small Stop pill (`FootballStop`, 188 x 48 at x 500, y 828).
- **Controls:** `scripts/ui/football_pad.gd` rewritten to the table: on a touch screen the joystick (centre 156, 1044, radius 92, four small arrows, a white thumb with a shadow); on a computer the keys box (W A S D keycaps, "Move", "W A S D"); Pass (`PASS_COLOR`, a runner with a ball, chip "Z") and Shoot or Tackle (`SHOOT_COLOR`, a goal with a net, chip "X"), 176 x 176 with a thickness of 8, the face down 8 when pressed; disabled at 45%. The keys are the same as before (arrows or WASD, Z or J, X, K or Space, P, H).
- **Help strip:** `scripts/ui/help_strip.gd` (new; the `HelpButton`, moved from the info line): a see-through pill 656 x 64 at y 1152 with a white "?" and "Joystick: move • Pass • Shoot" or "WASD: move • Z: pass • X: shoot"; the whole strip opens the help, 88 high to touch.
- Texts: new `FOOTBALL_TITLE`, `FOOTBALL_CONTROLS_TOUCH`, `FOOTBALL_CONTROLS_KEYS`, `FOOTBALL_MOVE`; `FOOTBALL_KEYS` (the old list of keys under the joystick) is deleted, as nothing shows it now. The status ("Playing (12 of 60 min)") is not shown any more (the minutes are in the panel's header).
- New colours in `ui_style.gd`: `PASS_COLOR`, `PASS_BASE`, `SHOOT_COLOR`, `SHOOT_BASE`, `FIELD_STRIPE_A`, `FIELD_STRIPE_B`, `TILE_BASE`, `WHITE_08`, `WHITE_25`, `WHITE_60`, `SHADOW_INK`; icons "pass" and "goal". `tools/render_ui_states.gd`: G (football) and J (football on a touch screen).
- Checked: headless start without errors; `minigame_test`, `football_test`, `translation_test`, `interface_test`, `settings_panel_test`, `scenery_test` ALL PASSED; G in English and Portuguese and J rendered and compared with the table.

### Change 6: the meal (user: "OK, do change 6", 21 Nov 2026)

Table "Meal minigame (09)".

- The standing avatar is replaced by the eating picture (seated at the table): `eat_closed.png`, and `eat_open.png` for 0.25 s after each bite; rect 110, 290, 500 x 500, the canvas's bottom on y 790. The fork aims at the picture's mouth: x 360 and y 290 + 500 x the sheet's share (`eat_mouth_y` in `data/avatar_art.json`: child_male 0.450, child_female 0.473, teen_male and teen_female 0.417). The ring at the mouth turns the timing zones' green (`meal_fork.gd`).
- The dock band (`DockBand` in the stage, after the scenery): navy at 85% across the whole width of the screen, from y 790 to the bottom, behind the dock; it hides the room's floor.
- **Fixed on the way (changes 3 and 4):** the activity pictures were looked up in a folder named after the sheet (`teenager_male`), but the teenagers' folders are `teen_male` and `teen_female`, so teenagers kept the normal avatar during exercise and cardio. The pictures now come from the sheet's folder in `data/avatar_art.json` (`avatar.art_folder()`). A new test checks a teenager.
- `tests/minigame_test.gd`: new checks (eat_closed, the band, the fork's aim, eat_open after a bite, both gone after the meal, a teenager's pictures). `tools/render_ui_states.gd`: a fourth argument `teen` renders a teenage girl.
- Checked: headless start without errors; `minigame_test`, `meal_test`, `avatar_art_test`, `canteen_test`, `scenery_test` ALL PASSED; state R rendered for a boy and a teenage girl.

### Change 8: sleep (user: "Skip change 7", 21 Nov 2026, so the next change)

Table "Sleeping (13, 14, 15)".

- **The bed picture** (`bed.png`: the whole bed from the front, the avatar asleep, "Zzz") takes the avatar's place while it sleeps: rect 210, 431, 300 x 347, the canvas's bottom on y 778 (56 above the stage's bottom at y 834). The avatar and the `Blanket` node are hidden. It is shown again after loading a game in the middle of a sleep.
- **The bedroom** (`scenery.gd`): the dark blue boards as before ("wall and floor as now": the old bedroom was seen from above, all boards, so the boards are the wall behind the window); the code-drawn bed, pillow and blanket are deleted. New: the sky of the hour (`SkyPalette`, with stars at night) in the glass (186, 330, 348 x 330), the window picture `scenery/window_blind.png` over it (160, 296, 400 x 384; loaded when the bedroom starts, never while drawing), by day three light stripes (40 wide, `#ffb85c` at 18% x the daylight, from y 680 at x 170, 250, 330, down-left at 20 degrees to y 900), and the floor shadow (centre 360, 778, 360 x 36, INK at 35%).
- **The four buttons** are at 35% while the avatar sleeps and cannot be pressed (as before); `action_button.gd` has `dimmed`, so they are not paled a second time.
- **Wake up** (`WAKE_UP`, "Wake up" / "Acordar"): the stop slot's pill becomes a lavender pill (296 x 64 at x 212, y 850, a half sun) while the avatar sleeps and when the sleep is over. **How it works (Claude's reading of Q2 and decision 81, to confirm):** while the avatar sleeps it ends the sleep, as Stop did (the play button cannot be pressed then); when the sleep is over it does what the play button does (`Clock.wake_up()`, the day starts). So no rule changes. Afterwards the pill is Stop again.
- `tests/scenery_test.gd`: new checks (the bed picture, no blanket, the window, the buttons at 35%, Wake up during and after the sleep, Stop again). `tools/render_ui_states.gd`: new state Y (asleep at 2 PM, for the light stripes).
- Checked: headless start without errors; `scenery_test`, `translation_test`, `interface_test`, `minigame_test`, `offline_sleep_test`, `sleep_test` ALL PASSED; Z (night), Y (day) and W (sleep over) rendered and compared with the table.

### Change 9: the exercise and entertainment menus (user: "OK, do change 9", 21 Nov 2026)

Table "Exercise menu (02)"; the entertainment menu uses the same panel.

- `OptionsPanel` is now a dimmed cover of the column (`scripts/ui/options_menu.gd`, new; the outside of the column is dimmed too) with the panel (x 40, y 214, 640 wide, radius 28, a white line), the icon at its top (a runner; a game controller for entertainment), the title ("Choose exercise", "Choose what to do"; ExtraBold 40), a divider, the minutes (Bold 26) and the slider (`scripts/ui/menu_slider.gd`, new: a track 12 high, the cyan fill, a white handle of radius 16 with a shadow; 48 high to touch).
- **Tiles** (`scripts/ui/menu_tile.gd`, new): 280 x 150 with a thickness of 6, an icon and the name; Cardio, Squats, Push-ups and Sit-ups in two rows (y 448 and 614), Video game and Football in one row. **A tile only chooses** (mint, a green thickness and a green badge with a white check); **Start starts** the chosen option with the minutes of the slider. The menu opens with the last option chosen for that activity (the first one the first time; kept while the game is open). The video game's tile shows a game controller, football's a ball.
- **Cancel and Start** (the `DockButton` style): 280 x 80 with a thickness of 8, radius 26, "✕  Cancel" on the light tile colour and "▶  Start" in mint; at y 792 (exercise; the panel ends at y 904) or y 626 (entertainment; the panel ends at y 738).
- The old "Skip meal" button of this panel is gone with the meal options (since Milestone 21 Eat opens the canteen, which has its own Skip meal).
- New keys `UI_START`, `EXERCISE_CHOOSE`, `ENTERTAINMENT_CHOOSE`; new colours `TILE_COLOR`, `BADGE_COLOR`; icon "controller" (one colour); `dock_button.gd` `prefix`.
- `tests/minutes_slider_test.gd`: the tiles choose and Start starts; new checks (Cardio chosen first, a tile only chooses, the last option chosen, the places of Start and the panel's bottom for both menus, Cancel). `tools/render_ui_states.gd`: O (exercise menu) and Q (entertainment menu).
- Checked: headless start without errors; `minutes_slider_test`, `settings_panel_test`, `translation_test`, `interface_test`, `minigame_test` ALL PASSED; O in English and Q in Portuguese rendered and compared with the table.

### Change 10: Let's eat (user: "OK, do change 10", 21 Nov 2026)

Table "Let's eat (06)": the first step of the canteen (`scripts/ui/canteen.gd`).

- The panel (x 52, y 214, 616 wide, radius 28, a white line; drawn by the canteen), a white apple (icon "apple_line"), "Let's eat!" (ExtraBold 44), a divider, "What would you like to eat?" (Bold 26).
- **Two cards** (`scripts/ui/eat_card.gd`, new): 560 x 156 with a thickness of 8, the team's pictures without words (`menu/eat_choice_good.png`, `eat_choice_fast.png`, 260 x 130, loaded when the card is made), a thin divider, the title ("Good food", "Fast food"; ExtraBold 34) and the subtitle ("Vegetables, fruit, fish", "High in fat, sugar and salt"; Bold 20, `SUBTITLE_COLOR`, two lines at most). **A card only chooses** (mint, a green badge with a white check); it opens with Good food chosen; **Continue** opens the plate of the chosen kind.
- **Skip meal** (only when hungry) at y 760, 560 wide; **Cancel** and **Continue** (270 x 76, a thickness of 8) at y 760, or y 852 with Skip meal; the panel ends at y 870 or 962.
- **One small change from the table:** a card's title is made smaller so that it ends 8 px before the badge (in Portuguese "Comida saudável" ran under the check). In English it does not change.
- The second step (the plate) keeps its old look until change 11.
- New keys `UI_CONTINUE`, `EAT_CHOOSE_TITLE`, `EAT_CHOOSE_QUESTION`, `EAT_GOOD_SUB`, `EAT_FAST_SUB`; `CANTEEN_CHOOSE` ("What kind of food?") is deleted, as nothing shows it now. New colour `SUBTITLE_COLOR`.
- `tests/canteen_test.gd`: a card chooses and Continue opens; new checks (Good food chosen at first, a card only chooses, the buttons' places with and without Skip meal). `tools/render_ui_states.gd`: L (Let's eat).
- Checked: headless start without errors; `canteen_test`, `minutes_slider_test`, `translation_test`, `interface_test`, `settings_panel_test` ALL PASSED; L rendered in English and Portuguese and compared with the table.

### Change 11: the canteen's plate (user: "OK, do change 11", 21 Nov 2026)

Tables "Canteen (07, 08)": the second step of `scripts/ui/canteen.gd`, at the table's places.

- A tall panel (x 24, y 210, 672 x 1022; it covers the four buttons), the kind's icon (white cutlery for good food, a one-colour burger, "burger_line", for fast food) and its title (ExtraBold 44).
- **The grid** (`scripts/ui/food_tile.gd` rewritten): tiles 118 x 184 in 5 columns for 10 foods, 150 x 184 in 4 columns for 8, rows at y 306 and 502; each shows the team's picture (`assets/art/food/<id>.png`, 100 x 83, loaded when the food is set) and the name (Bold 20, two lines at most). A food on the plate is mint with a green badge; when the plate is full the others are at 45%. A food without a picture keeps the old placeholder (a coloured tile with its first letter): today nuggets, kebab and milkshake, which change 12 removes.
- "Your plate (2 of 4)" (Bold 28) with a line on each side; **the plate** drawn by code (an ellipse 600 x 200 with a rim 540 x 160 and a shadow 12 px lower); **its 4 places** (120 x 100 at x 96, 232, 368, 504, y 822): a dashed outline when empty, the food's picture when full (a tap takes it off).
- The hint (Bold 20, white at 60%, one line, smaller down to 15), **Back** (lavender, "←  Back") and **Eat the plate** (mint; at 45% while the plate is empty), 300 x 84 with a thickness of 8.
- The key `CANTEEN_TITLE` ("Canteen") is deleted (nothing shows it now). New colours `PLATE_COLOR`, `PLATE_RIM`, `SLOT_LINE`.
- `tests/canteen_test.gd`: new checks (5 columns at the table's places, the plate's places, a food on the plate is chosen and in the first place). `tools/render_ui_states.gd`: T (good food) and I (fast food), two foods on the plate.
- Checked: headless start without errors; `canteen_test`, `minutes_slider_test`, `translation_test`, `meal_test`, `interface_test` ALL PASSED; T and I rendered in Portuguese and compared with the tables.

### Change 12: the canteen list (user: "OK, do change 12", 21 Nov 2026)

- `data/canteen.json`: the good foods are unchanged (Q10). Fast foods: burger, fries, pizza, hot dog, fried chicken, soft drink and doughnut stay; **ice cream** is added (`FOOD_ICE_CREAM`, "Ice cream" / "Gelado"); nuggets, kebab and milkshake are removed (and their keys). Every food now has the team's picture, so `color` and `placeholder` are gone from all of them. The fast-food grid has 8 foods in 4 columns until the team sends two more (then the 5-column grid of good food, by itself).
- The meal fork took the food's `color`; without it, it keeps the meal's own colour (green for a good plate, orange for fast food) (`main.gd`).
- **Nothing in the health model changes:** a good plate is still the healthy meal and a fast-food plate the fast-food meal.
- `tests/canteen_test.gd`: new checks (the two lists, every food has its picture, 4 columns of 150 for 8 fast foods).
- Checked: headless start without errors; `canteen_test`, `translation_test`, `meal_test`, `minutes_slider_test`, `minigame_test` ALL PASSED; I (fast food) rendered.

### After change 12: a football on the Entertainment button (user, 21 Nov 2026)

The user asked "add a football ball to the button" and chose the Entertainment button. Its icon (`ui_icons.gd`, kind "entertainment") is now the brown game controller, a little smaller and to the left, with a football over its lower right (entertainment is the video game and football). The menu's icon and the tiles are unchanged. Checked: `interface_test` ALL PASSED; state C rendered.

**Change 7 again (user, 21 Nov 2026: "unskip change 7"):** not built. A new "Watch" option was proposed and the user said no; the user has not yet chosen between "replace the video game" and "around the video game".

### The team's task list (Google Drive "Bio-Streams-tasks.xlsx", sheet 1, 21 Nov 2026)

The user asked to fix the rows with a description on the right; the user chose the details:
- **Health pills:** each pill fills in quarter steps, rounded down (3.7 shows three pills and half of the fourth; `health_pills.gd` `pill_fill`). "Health N" unchanged.
- **While the avatar sleeps** the balloon says "Zzz... (x of y h) The night takes real time: you can wait, or close the game and come back later." (`SPEECH_SLEEPING_WAIT`; `SPEECH_PROGRESS` deleted).
- **When a played minigame ends** (cardio, squats, push-ups, sit-ups, football, a meal; not the video game) a short pop-up for about 3 s gives one line from its score (`minigame.feedback_great_from` 0.8 and `feedback_good_from` 0.5, placeholders): e.g. "Great running rhythm!", "You did the push-ups badly.", "You ate bad food." (`scripts/ui/feedback_popup.gd`, `Minigame.session_result`, `FEEDBACK_*` keys). Only the look.
- Checked: `minigame_test`, `interface_test`, `translation_test`, `config_test`, `clock_test`, `measures_test`, `failure_test`, `scenery_test`, `requests_test` ALL PASSED. `failure_test` also prints "triangulation failed" twice; it did so already before these changes (not fixed yet).

### The creation screen and the menu's first button (user, 21 Nov 2026)

- **The creation screen** is rebuilt from the user's picture (`scenes/ui/creation.tscn` at absolute places; colours read from the picture's pixels): a blue-to-peach background with faint stars (`scripts/ui/creation_backdrop.gd`), PT and EN pills at the top right (the chosen one mint), "Create your avatar" (ExtraBold 60), a white name field with a cyan line, and the choices as coloured buttons (`scripts/ui/choice_button.gd`): Child (cyan, a small figure) and Teenager (lavender, a taller one) with their ages on a second line, Male (orange, ♂) and Female (sage, ♀), Easy (green), Normal (yellow), Hard (salmon) and Very hard (crimson, white text). **The chosen button has a navy check** (user: "the buttons with a tick are the selected"); every button keeps its own colour. The difficulty's description stays the existing text. Start (mint, "▶  Start", at 45% until everything is chosen) and Back (lavender, "←  Back"). New icons "child", "teen", "male", "female". The ages lost their brackets ("Child\n6 to 12 years").
- **The menu:** Continue takes New avatar's place (the first, mint button, a play icon); New avatar is on the first screen only while there is no avatar at all (it is in the Avatars page for every empty place). If the place played last is empty, Continue opens the first place with an avatar. The four buttons always use the splash's places; the five-button layout and the gold Continue colours are deleted.
- Checked: headless start without errors; `creation_test`, `menu_test` (a new check: with an avatar, no New avatar and Continue in the first place), `translation_test` ALL PASSED; N rendered in Portuguese and English and compared with the picture. `tools/render_ui_states.gd` N now shows a name and three choices.

### The team's updated zip (user, 22 Nov 2026: "update all the different sprites in this zip")

`My-Healthy-Avatar-Atualizado.zip` holds the team's 174 full-size originals (one canvas each, not cropped). Compared by pixels with the game's pictures (`documentation/ui_v2/assets/`, the same as `assets/art/`), the characters are child_male = rapaz_castanho, child_female = rapariga_loira, teen_male = rapaz_preto, teen_female = rapariga_castanha. What changed and what was done:
- **The same drawings as before, only larger** (foods, beds, the tablet, the window, the medium body's exercise and eating pictures): kept as they are, nothing to change. Nuggets, kebab and milkshake are in the zip but stay out of the canteen (change 12).
- **Running:** two frames now (left foot up, right foot up, seen from behind), used in turn at each tap; the five old frames are deleted (the zip says not to use them). `run_left.png`, `run_right.png`.
- **Three body sizes** for running, squats, push-ups, sit-ups and eating (corpo_01 fuller, corpo_02 medium, corpo_03 slim): `<name>_full.png`, `<name>.png`, `<name>_slim.png`. Obese and overweight bodies use the fuller pictures, thin ones the slim pictures, healthy and muscular ones the medium ones (`data/avatar_art.json` "activity_builds", `avatar.activity_suffix()`; Claude's choice, the zip does not say). The bed has one size. Each new picture uses exactly the scale and place of the old medium one (fitted on its pixels; the three sizes share the canvas and framing in the zip), so feet, the table and the mouth point stay where they were. Normal starts overweight (z +1.2), so a new Normal avatar now runs, trains and eats with the fuller body.
- **The video game:** the team's dinosaur (standing before the first jump, two running steps in turn on a cloud, the jump in the air), the team's flat sky colour (#3aa8fd, `ceu.png` is one colour) and the team's clouds (`assets/art/videogame/`). A cloud of any width is the small cloud's left end, its middle hump once or more (a little wider or narrower), and its right end, cut where its top dips beside the hump; the dips are the top the dinosaur stands on, the picture's bottom the underside, so the collision box is unchanged. The medium and large clouds are the faint clouds far behind. The run's rules and numbers did not change.
- **The menu's background:** the team's pictures (`assets/art/menu/menu_portrait.png` on a phone, `menu_wide.png` on a wider screen, its figures the same size and place as the vertical one's). The figures (a boy running, a girl with obesity, a girl eating an apple, a boy asleep) and their shadows are in the picture, so the menu's own figures and the code-drawn sunset sky, hill, sun, moon, clouds and stars are deleted. The sky is flat now (the zip: flat fills, no gradients).
- **Not used:** the two "Let's eat" cards and the Jump and End game buttons have English words drawn in them, which cannot be translated (the same reason as Q11); `icone_videogame.png` (a controller and a football) is the Entertainment icon the game already draws; `comer_mesa.png` (eating at the table) is not needed since the eating minigame has its own pictures; `previsualizacoes/` are index sheets.
- `tools/render_ui_states.gd`: new state g (the video game, 1.2 s into a run).
- Checked: headless start without errors; `minigame_test` (three new checks: Normal is overweight and uses the fuller pictures, a thin avatar's squats are slim, a muscular one runs with the medium body), `avatar_art_test`, `scenery_test`, `menu_test`, `translation_test`, `sky_test`, `interface_test` ALL PASSED; rendered S, K, R, U (teenager), g, and M at 720 x 1280, 960 x 1280 and 1600 x 900.

### The team's activity sheets (user, 22 Nov 2026: "replace all the activity/minigame sprites", the zip `261122a.zip`)

Eight sheets in a new, simpler style (the standing avatar's style): for each character an activity sheet (8 rows: run_left, run_right, squat_up, squat_down, situp_up, situp_down, pushup_down, pushup_up) and an eating sheet (eat_open, eat_closed, and a bed under them), each row with the **five bodies** (obese, overweight, healthy, thin, muscular). Saved in `assets/art/avatar/source/activity/<character>_activity.png` and `_eat.png` (not imported, `.gdignore`).
- **One picture per body now** (it replaces the three sizes above): `<name>_<body>.png`, for example `run_left_obese.png`; `avatar.activity_suffix()` is `"_" + body_name()`, and `activity_builds` is removed from `data/avatar_art.json`. A muscular avatar now has its own muscular pictures.
- `tools/cut_activity_sheets.py` cuts the sheets onto the canvases the game already uses (so the rects in `main.gd` did not change): one scale per sheet, so the healthy body standing is as tall as the medium body was (child_male and teen_female a little smaller, so every figure fits its canvas), each figure kept in its place in its cell, the feet on the old feet line. The eating pictures are scaled so the healthy one is as tall as the old one, on the old bottom. Imported as lossy WebP (0.85) with mipmaps, like before. The figures are upscaled about 4 times from the sheets (the team's sheets are 1122 x 1402), so they are a little softer than the old pictures.
- `eat_mouth_y` follows the new pictures (found by the tool, the healthy body's open mouth): child_male 0.382, child_female 0.414, teen_male 0.328, teen_female 0.352. The other bodies are within 0.01.
- **Not replaced yet (user):** the sleeping pictures (`bed.png`, the beds in the eating sheets) and the standing avatar (`<body>_<face>.png`).
- The old activity pictures (`<name>.png`, `_full`, `_slim`) are deleted (they are in the git history).
- Checked: headless start without errors; `minigame_test` (the body checks now ask for `_overweight`, `_thin` and `_muscular`; the fork test reads `eat_mouth_y` from the data instead of 0.45), `avatar_art_test`, `scenery_test` ALL PASSED; rendered R, S, K, U and V at 720 x 1280. Not committed.

### Boxes with 4 numbers on the buttons (user, 22 Nov 2026)

The buttons showed boxes with a hex code (2190, 2191, 2193, 25B6, 2715) in the web build. Those characters (← ↑ ↓ ▶ ✕) are not in the Nunito font, and the browser has no other font to fall back on. On the Mac the system fonts filled the gap, so nobody saw it there. Fixed:
- `scripts/ui/dock_button.gd` now draws its symbols: `prefix` is a symbol's name ("play", "cross", "back"), drawn before the word, and the key chip draws `chip_arrow` ("down", "up") before its letter. Used in `main.gd` (Cancel and Start in the menus, the Down and Up chips), `creation.gd` (Start, Back) and `canteen.gd` (Back, Cancel, Continue). The XP level's arrow was already drawn.
- `tests/translation_test.gd` checks that every text in `strings.csv` and every character in the scripts' code (not their comments) is in Nunito. It fails on the old code.
- Checked: `translation_test`, `interface_test`, `minigame_test`, `creation_test`, `menu_test` ALL PASSED; rendered K, O, T and N; the web build exported again and the creation screen checked in the browser.

### Avatars that disappear on GitHub Pages and on phones (user, 22 Nov 2026)

Tested in the web build: an avatar made in an older published build (`5f7ff6c`) and in the current one is still there after the current build is loaded at the same address, and after the build is exported again. So a new version of the game does not delete avatars: the save keys, the save version and the checks did not change. A save belongs to one address and one browser. What can lose it: another browser or device, a link opened inside an app (WhatsApp, Instagram... their browsers often forget sites), a private tab, the player clearing site data, and Safari on iPhones, which clears script-written data after about 7 days without a visit.
- **Done (the user's choice):** `SaveGame._ask_persistent_storage()` asks the browser to keep the site's data (`navigator.storage.persist()`) at start. Checked: no error, the saves load. In the browser pane Chrome answered "not persistent": Chrome decides alone from how much the site is used (a bookmark or an installed app helps), so this protects some players, not all.
- **A note on the menu (user: "Yes, add it"):** between the buttons and the PT/EN switch (moved 34 down), in the web build only (`menu.show_save_note`). With an avatar: "Your avatars are saved only in this browser, on this device. Make a backup in Avatars to keep them safe." Without one: "Avatars are saved only in the browser and device where they were made. Have a backup file? Use Load a backup." (`MENU_SAVE_NOTE`, `MENU_SAVE_NOTE_EMPTY`; the Portuguese is Claude's draft.)
- `save_test`, `menu_test` (two new checks: no note off the web; with an avatar, the backup note above the switch), `translation_test` and `interface_test` ALL PASSED; the web build exported again and both notes checked in the browser in English and Portuguese.

### The upscaled exercise sheets (user, 22 Nov 2026: "replace them, don't change the sleeping and eating, only the exercise")

The team upscaled the four activity sheets 8 times with an AI upscaler (8976 x 11216, transparent background). They were in `assets/art/avatar/` (where Godot would import them as game pictures) and are moved to `assets/art/avatar/source/activity/<character>_activity_upscaled.png` (`upscaled.png` was teen_female, `upscaled female child.png` child_female, `upscaled male child.png` child_male, `upscaled male teen exercise.png` teen_male; about 40 MB each). A 3.2-times teen_female sheet in Downloads was replaced by the 8-times one.
- `tools/cut_activity_sheets.py` uses `<name>_activity_upscaled.png` when it exists, and `python3 tools/cut_activity_sheets.py exercise` makes only the running, squat, push-up and sit-up pictures. The scale comes from the sheet (exactly the small sheet's divided by 8), so every picture keeps its size and place; the outlines are smooth now instead of enlarged pixels.
- The 160 exercise pictures are made again; the eating pictures, the bed and the standing avatar are unchanged (checked: no change in git).
- The pictures stay at twice their size on screen (the canvases), so a phone with 3 times dense pixels still enlarges them a little; larger canvases would be a further step.
- `minigame_test`, `avatar_art_test`, `scenery_test` ALL PASSED; rendered S, K, U, V; the web build exported again.

## Where Milestone 40 stands

All 12 changes are done (7 skipped by the user), plus the splash screen. Each was committed alone. **Not pushed, and not to be published** until the team confirms that the image tool's terms allow CC BY 4.0 (`documentation/ui_v2/licence.md`); the web build in `docs/` was not exported again. Open for the user: Done always enabled (change 2), the cardio status not shown (change 4), how Wake up works (change 8), whether `documentation/ui_v2/work/` should be committed (the old pictures in `documentation/ui_v2/assets/` were moved to the Trash by the user's request, 22 Nov 2026: the game's copies are in `assets/art/`). Not checked on a real phone.

## Contradictions found (to ask before the change they touch)

- **Change 7 (screen time) and Milestone 35.** `changes.md` was written for Screens as plain screen time (Q1: "decision 54 stays open"; a room, the tablet picture, a screen-time bar, Keep watching and Take a break). Since Milestone 35 Screens is the "Video game" with its own Cloud jump screen (decision 54 is answered by decisions 103 to 108). **The user chose "Skip change 7" (21 Nov 2026):** the video game stays as it is; the screen-time dock of change 2 and the keys `SCREEN_*` are not added; `tablet.png` and the side table, plant and lamp are not used for now.


## After Milestone 40: no screen-time penalty (decision 109, 22 Nov 2026)

The user asked to remove the screen penalty and give a very small boost instead. Done: `scripts/health/happiness.gd` has no `screen_excess()` and no baseline term; `data/config.json` loses `mood.baseline.screen_excess`, `mood.screen_excess_from_min` and `mood.screen_excess_range_min` and gains `mood.events.screens_after_cap_per_h` (0.005 per hour, placeholder); the debug panel, the CSV log (`screen_excess` column gone) and `tests/parity_test.gd` follow. `tests/happiness_test.gd` checks the boost; it still has its two Milestone 27 failures (guideline happiness, switches end in the same place).

## After Milestone 40: only the images the game uses go into the web build (22 Nov 2026)

Every image Godot imports under `assets/` (outside `source/` folders) was checked against the scenes, `scripts/`, `data/*.json` and the names built at run time (`<body>_<face>.png`, `<name>_<body>.png`, `assets/art/food/<id>.png`). 9 were unused and were moved out of the game with the user's OK (they stay in git history too):
- `tablet.png` of the four avatar folders → `assets/art/avatar/source/unused/<folder>_tablet.png` (ignored by Godot through `source/.gdignore`);
- `banana`, `broccoli`, `carrot`, `pear` and `strawberries` (not among the canteen's 18 foods) → `assets/art/food/source/` (new `.gdignore`).
Their `.import` files were deleted. `avatar_art_test`, `canteen_test`, `scenery_test` and `menu_test` pass. `docs/index.pck`: 30,677,512 → 30,190,392 bytes (about 0.5 MB less; the rest of the 30 MB is pictures the game really uses, mostly the avatar folders). Checked in the web build: the menu, a new avatar, the canteen and the meal, squats and the video game show their pictures, no console errors; sleep was not opened (the new avatar was not sleepy), and the bed picture was not touched.
**Note:** a new folder `assets/art/avatar/261122b/` (8 large pictures, 12 MB, untracked, added at 21:11 by someone else) is imported by Godot and would go into the build; it was left out of this export only (the preset was put back as it was). Move it under `source/` or use it before the next export.


## 22 Nov 2026: the team's sleeping pictures

**22 Nov 2026, the team's sleeping pictures (user):** one per character for the day (yellow light stripes) and one for the night, the window, the bed and the avatar in one picture (`sleep_day.png`, `sleep_night.png`, chosen by `Clock.daylight_amount()` at 0.5), cut by `tools/cut_sleep_pictures.py` (the purple background and the glass made transparent, the same glass width and floor line in every picture; the glass rectangles in `data/sleep_glass.json`); the bedroom now draws the room's own wall and floor (the meal room's colours, darker at night) and the sky of the hour behind the glass; the code-drawn light stripes and bed shadow are gone, and the old `bed.png` and `window_blind.png` moved to `assets/art/avatar/source/unused/old_sleep/` (not in the build). Sources in `assets/art/avatar/source/sleep/`. The food pictures come next. Not committed. `tests/scenery_test.gd` checks the picture of the time of day and the switch; ALL PASSED.


## 22 Nov 2026: the team's new eating pictures

**22 Nov 2026, the team's new eating pictures (user):** one sheet (`assets/art/avatar/source/activity/eat_all.jpg`, on black: mouth closed above the white line, open under it; child and teenager, boys left, girls right, 5 bodies). `python3 tools/cut_activity_sheets.py eating` splits it into the four `<name>_eat.png` (black background made transparent, black hair and the outline kept, specks removed) and cuts `eat_open_<body>.png` and `eat_closed_<body>.png` as before (same size and place as the old pictures); `eat_mouth_y` in `data/avatar_art.json` is the new mouth (child boy 0.462, child girl 0.514, teen boy 0.44, teen girl 0.465). The old eating sheets are replaced (in git history). The source is small, so the pictures are a little soft when made 6 times bigger. `tests/minigame_test.gd` ALL PASSED. Not committed.


## 22 Nov 2026: the plate's food on the fork

**22 Nov 2026, the team's task list, sheet 2 (`Bio-Streams-tasks.xlsx` in Google Drive), the "jogo" part:** the food on the fork is the picture of one of the foods the player put on the plate (the plate's foods in turn, one per bite; `scripts/ui/meal_fork.gd` `food_texture`, loaded by `main.gd` `_food_picture()`, 84 wide, its middle 14 under the tines); without a plate (a meal started without the canteen) the fork keeps the round coloured bite. `tests/minigame_test.gd` checks it (ALL PASSED); `tools/render_ui_states.gd` R shows a plate of apple and rice. The rest of sheet 2 is about the presentation videos and notes for the team, not the game. Not committed.


## 22 Nov 2026: demo videos (sheet 2)

**22 Nov 2026, demo videos for the presentation (the team's task list, sheet 2, user):** `scripts/autoload/demo_player.gd` (autoload `DemoPlayer`, last) plays the game by itself, only with the user argument `--demo=<scenario>` (otherwise it does nothing: normal game, web build and tests unchanged). `tools/record_demo.sh [en|pt] [scenario ...]` records each scenario with Godot's Movie Maker (a real window, 720 x 1280, 60 fps), converts it with ffmpeg to `captures/<lang>/<scenario>.mp4` (H.264, AAC; silent, the game has no music yet) and saves PNG screenshots in `captures/<lang>/shots/`. While it records, a temporary `override.cfg` makes Godot use its own user folder (`~/Library/Application Support/My Healthy Avatar demo`), so the player's saves and settings are never touched; it is removed at the end. `captures/` and `override.cfg` are in `.gitignore`, and `captures/.gdignore` keeps the files out of the game. Scenarios: menu (the splash screen's functions and the creation screen), screens (the main screen by day and night: images), cardio (how a minigame works, step by step), squats, push_ups, sit_ups, meal (canteen, plate, fork), football, video_game, sleep, health (x1500: health rises with good habits to about 4.8 in 25 avatar days, then bad habits (fast food, screens, no sleep) bring failure by low health in about 13 days; the failure screen and its Details stay a few seconds). The demo taps with real mouse events (a white ring shows each tap) and real keys, and shows short captions (English and Portuguese, Claude's wording from the rules in this file). Lessons: under Movie Maker a SceneTreeTimer did not always end, so the demo waits by counting frames; macOS does not draw a covered window (`DisplayServer.window_can_draw()` false, and the 1280-high window is taller than the laptop screen), so the demo calls `RenderingServer.force_draw()` itself then; with a custom user folder macOS puts it straight in `~/Library/Application Support/`. Do not run Godot while a recording runs (the override.cfg would send it to the demo folder). Recorded on 22 and 23 Nov 2026: 11 videos in English (`captures/en/`) and 11 in Portuguese (`captures/pt/`), 32 s to 163 s each, 720 x 1280, 60 fps, with 35 screenshots per language in `shots/` (193 MB in all); the demo reported no problems; menu, save, config and translation tests still pass. Not committed.

- **23 Nov 2026: the demo videos have no captions** (user: "tira as explicações"): `DemoPlayer` shows them only with the user argument `--captions`; the tap rings stay. The videos must be recorded again.

- **23 Nov 2026: the menu's wide background is the team's upscaled picture** (user): `assets/art/menu/upscaled.png` (13896 x 7240, 124 MB) moved to `assets/art/menu/source/menu_wide_upscaled.png` (`.gdignore`, not in the build) and made 3476 x 1811 as `menu_wide.png` (phones' 4096-pixel texture limit); `menu_backdrop.gd`'s figure numbers are scaled by 2.001 and the edge colours read again. The vertical picture (phones) is unchanged. `menu_test.gd` ALL PASSED. Not committed.
