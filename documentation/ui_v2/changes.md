# changes.md — the new look, ready to apply (pass 3, 21 Nov 2026)

Everything here is final: every position, size, colour and text is written out, so nothing has to be measured or decided while coding. Colour names are the constants of `values.md` (new ones under `## new` there). Pictures are in `documentation/ui_v2/assets/` (`files.md`). The tables at the end are written by `work/layout_spec.py` from one set of numbers, which also drew a check picture of each screen; nothing overlaps and everything fits in 720 × 1280.

## Decisions (all taken; nothing open)

- Q1. Screen time (`10`) is built as drawn, look only: no new rule (decision 54 stays open). User, 21 Nov 2026.
- Q2. The "Wake up" button comes back in the look; it does what the play button does. User, 21 Nov 2026.
- Q3. Ten foods per kind in the canteen. User, 21 Nov 2026.
- Q4. The clock always agrees with the sky; mockup `15` (3:38 PM with a night sky) is a mockup mistake. User.
- Q5. **Day ground: stays as Milestone 26 made it (greener).** The mockups' blue ground is not used. (Claude, asked by the user to choose, 21 Nov 2026.)
- Q6. **No ring around the next level** in the HUD: it repeats the XP bar and is in one mockup only. The HUD does not change. (Claude.)
- Q7. **Texts:** a text the game already has keeps its key and wording (the stop button stays `UI_STOP`, "Stop" / "Parar"; Bite and Done stay). New texts are the keys in the table "New text keys" below. (Claude.)
- Q8. Exercise, bed, meal and screen pictures exist only for the healthy body and are used whatever the body is. The standing avatar keeps its 5 bodies. User, 21 Nov 2026.
- Q9. The team makes two more fast foods. Until they come, the fast-food grid has 8 foods in 4 columns. User.
- Q10. **The ten good foods are the ten of mockup `07`, the same ids `data/canteen.json` has today:** `vegetable_soup`, `grilled_fish`, `wholemeal_bread`, `apple`, `salad`, `orange`, `rice`, `yoghurt`, `beans`, `water`. Banana, broccoli, carrot, pear and strawberries stay as spare pictures (three are in the "Let's eat" card). (Claude.)
- Q11. **The "Let's eat" cards use pictures without words**, `menu/eat_choice_good.png` and `menu/eat_choice_fast.png`, made from the food pictures; the words are text, so they translate. The team's cards with English words are kept in `work/menu_cards_en/`, not used. (Claude.)

## Rules for every screen

1. **Coordinates** are in the 720-wide column, 0 at its top-left, for a 1280-tall screen. Each element has an anchor: **T** stays where it is; **B** moves down by (screen height − 1280); **S** stretches: its top stays, its height grows by (screen height − 1280). So on a taller screen the stage grows and everything under it stays at the bottom, as now.
2. **Touch areas:** every button's touch area is at least 88 × 88 px, centred on the drawn shape (it may reach outside it). This matters for the small stop pills (48 tall) and the football help strip (64 tall).
3. **Pressed buttons:** the face moves down by its thickness (6 or 8 px, given per button) at once and comes back in `BUTTON_RETURN_SECONDS` (0.14 s), ease out, as the four big buttons do now. Disabled: alpha 0.45.
4. **Fonts:** only Nunito Bold and ExtraBold. A text that is too long is made smaller with `UiStyle.fit_font_size` down to 70% of its size, never cut. Portuguese is longer: every width was checked for the Portuguese text.
5. **Bars:** fully round ends (radius = half the height), track `TRACK`, fill as given. **Timing bars** (48 high): outline 3 px white, green zone `ZONE` inset 6 px with radius 18.
6. **Key chips** (the small "↓  S" pills) show only on a computer (`football_pad.touch_mode` false), as the "[Space]" texts do now.
7. **Pictures** are drawn in the rect given, the whole canvas, never cropped or stretched (canvas aspect = rect aspect). `{sheet}` is the avatar's folder: `child_male`, `child_female`, `teen_male`, `teen_female`.
8. **During an activity** the speech balloon has its top at y 208 (rect x 85, y 208, 550 × 76), so it never covers the clock; its tail points down from its middle. Outside activities it stays where it is now.

## The changes, in order (each one can be approved alone)

1. **Colours:** apply `values.md` (four button colours, the night sky rows, the new constants).
2. **Activity dock** (squats, push-ups, sit-ups, meal, screens): the stop pill, the info line, the bars and two big buttons, as in the tables "Squats, push-ups, sit-ups", "Meal" and "Screen time". It replaces the `MinigamePanel` look for these activities; the stage ends at y 790 and the feet are at y 730.
3. **Exercise pictures:** the avatar is replaced during squats, push-ups and sit-ups by the two pictures of the exercise: after DOWN the "down" picture, after UP the "up" one; before the first press and while resting, `squat_up`, `pushup_up` or `situp_down`.
4. **Cardio** (`01`): the panel with header, Steps, Breath, the timing box and the tap button; the running pictures `run_01` to `run_05` (next frame at each tap) replace the dark silhouette.
5. **Football** (`11`, `12`): the rounded field with stripes, a minimap and the score capsule; the panel with header, Breath, joystick or keys, Pass and Shoot, and the help strip (it is the help button). The hint text on the field stays as it is now.
6. **Meal** (`09`): the eating pictures (closed mouth, open for 0.25 s after each bite) replace the standing avatar; the fork aims at the mouth point given per sheet; the dock band behind the dock; Bite and Done.
7. **Screen time** (`10`): the room scenery (set `"scenery": "room"` for screens in `data/activities.json`), the tablet picture, a side table with a plant and a lamp drawn by code, the screen-time bar, Keep watching (no effect) and Take a break (= Stop).
8. **Sleep** (`13` to `15`): the bed picture replaces the avatar and the `Blanket` node; the window picture with the sky of the hour behind it, day and night; the four buttons at alpha 0.35 and not clickable; the Wake up pill in the stop slot. `Scenery.bedroom` keeps its wall and floor and stops drawing the bed and blanket. In the day (sun up) add three light stripes: parallelograms 40 px wide, `#ffb85c` at alpha 0.18, from the window's bottom edge (y 680) at x 170, 250, 330 down-left at 20° to y 900 (behind the bed).
9. **Exercise menu** (`02`): the panel with the minutes slider and a 2 × 2 grid of tiles; a tile only chooses, Start starts. **The entertainment menu** uses the same panel with two tiles in one row (Screens, Football at y 448) and its Cancel and Start at y 626 (panel bottom 738).
10. **Let's eat** (`06`): the panel with two cards (pictures without words, a title and a subtitle each), Cancel and Continue; Skip meal as written in the table.
11. **Canteen** (`07`, `08`): the panel with the grid (5 columns for 10 foods, 4 for 8), the plate with four slots and Back and "Eat the plate". The tiles and the plate show `assets/food/{id}.png` instead of the colour tile with a letter.
12. **Canteen list** (`data/canteen.json`): good foods unchanged (Q10). Fast foods: `burger`, `fries`, `pizza`, `hot_dog`, `fried_chicken`, `soft_drink`, `doughnut` stay; add `ice_cream` (name `FOOD_ICE_CREAM`, kind `fast_food`); remove `nuggets`, `kebab`, `milkshake`. The `color` field and `placeholder: true` go away for foods with a picture. Nothing in the health model changes.

## New text keys (`translations/strings.csv`)

| Key | en | pt |
|---|---|---|
| `WAKE_UP` | Wake up | Acordar |
| `UI_START` | Start | Começar |
| `UI_CONTINUE` | Continue | Continuar |
| `EXERCISE_CHOOSE` | Choose exercise | Escolhe o exercício |
| `ENTERTAINMENT_CHOOSE` | Choose what to do | Escolhe o que fazer |
| `EAT_CHOOSE_TITLE` | Let's eat! | Vamos comer! |
| `EAT_CHOOSE_QUESTION` | What would you like to eat? | O que queres comer? |
| `EAT_GOOD_SUB` | Vegetables, fruit, fish | Legumes, fruta, peixe |
| `EAT_FAST_SUB` | High in fat, sugar and salt | Muita gordura, açúcar e sal |
| `CARDIO_TITLE` | CARDIO | CARDIO |
| `FOOTBALL_TITLE` | FOOTBALL | FUTEBOL |
| `MINIGAME_STEPS_LABEL` | Steps | Passos |
| `TIMING` | Timing | Ritmo |
| `TIMING_HINT` | Tap in the green zone! | Toca na zona verde! |
| `SCREEN_HINT` | Enjoy it, but stop at the right time! | Aproveita, mas para na altura certa! |
| `SCREEN_TIME` | Screen time: %d / %d min | Tempo de ecrã: %d / %d min |
| `SCREEN_KEEP` | Keep watching | Continuar a ver |
| `SCREEN_BREAK` | Take a break | Fazer uma pausa |
| `FOOTBALL_CONTROLS_TOUCH` | Joystick: move • Pass • Shoot | Joystick: mover • Passe • Rematar |
| `FOOTBALL_CONTROLS_KEYS` | WASD: move • Z: pass • X: shoot | WASD: mover • Z: passe • X: rematar |
| `FOOTBALL_MOVE` | Move | Mover |
| `FOOD_ICE_CREAM` | Ice cream | Gelado |

The cardio minutes ("7 / 60 min") and football minutes use the format `"%d / %d min"` (no key: numbers only). In the info line of squats, push-ups and sit-ups the left text is the status the game shows now (`MINIGAME_DO_REAL`, `MINIGAME_SET`...) and the right text is `MINIGAME_REPS`; in the meal, `MEAL_*` and `MEAL_TUMMY`; in screen time, `SCREEN_HINT` and `SCREEN_TIME`.

## Not changed

The main screen without an activity (HUD, clock, gear, balloon, avatar, four buttons), the menu, the creation screen, the failure screen, the settings panel and the sleep hours panel have no mockup in this set and stay as they are.

## Tables: every element of every screen

### Squats, push-ups, sit-ups (03, 04, 05)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Stop pill | pill | 230 | 806 | 260 | 64 | 32 | STOP | tr("UI_STOP") | B | thickness 6 px STOP_BASE under it; pressed: face down 6 px. Left: a square 26 x 26, radius 6, INK, at x 262, y 825. Text Nunito ExtraBold 30, INK, left edge x 304, centred on y 838 |
| 2 | Info line, left | text | 24 | 886 | 420 | 28 | 0 | WHITE | status text | B | Nunito Bold 22, left aligned, one line; made smaller down to 16 if longer |
| 3 | Info line, right | text | 452 | 886 | 244 | 28 | 0 | WHITE | count text | B | Nunito Bold 22, right aligned to x 696 |
| 4 | Muscle label | text | 24 | 922 | 88 | 24 | 0 | WHITE | tr("MINIGAME_MUSCLE") | B | Nunito Bold 22, left, centred on y 934 |
| 5 | Muscle bar | pill | 120 | 922 | 576 | 24 | 12 | WHITE | fill = Minigame.reserve | B | track TRACK, fill white, as the bars now |
| 6 | Timing bar | pill | 24 | 960 | 672 | 48 | 24 | TRACK | BeatBar | B | outline 3 px white; green zone ZONE inside (inset 6 px, radius 18) where the beat bar puts it now; target: a white ring radius 22, line 5, with 4 ticks 10 px long, on the marker |
| 7 | DOWN button | box | 24 | 1032 | 327 | 176 | 32 | DOWN | tr("MINIGAME_DOWN") | B | thickness 8 px DOWN_BASE under it (to y 1216); pressed: face down 8 px. Icon of the exercise (lying figure for sit-ups and push-ups, squatting for squats) 80 x 80 white at x 56, y 1064; a down arrow 16 x 36 white at x 150, y 1066; word ExtraBold 40 white, left x 186, centred y 1100. Key chip (computer only): pill 100 x 32, outline 2 white 60%, centre (187, 1170), text "↓  S" Bold 20 white |
| 8 | UP button | box | 369 | 1032 | 327 | 176 | 32 | UP | tr("MINIGAME_UP") | B | thickness 8 px UP_BASE under it (to y 1216); pressed: face down 8 px. Same layout in INK: icon at x 401, y 1064; up arrow at x 495, y 1066; word left x 531; chip centre (532, 1170), text "↑  W", fill UP_BASE, text white |
| 9 | Speech balloon | box | 85 | 208 | 550 | 76 | 38 | WHITE | as now | T | during every activity the balloon is here (top fixed); tail 22 px down from its middle |
| 10 | Stage | zone | 0 | 210 | 720 | 580 | 0 |  | Stage | S | the place for the scenery; ground line (feet) at y 730 = stage bottom - 60 |
| 11 | Squat picture | picture | 195 | 295 | 330 | 450 | 0 |  | avatar/{sheet}/squat_up.png | B | squat_down.png the same rect; feet on y 730 |
| 12 | Push-up picture | picture | 110 | 394 | 500 | 340 | 0 |  | avatar/{sheet}/pushup_up.png | B | pushup_down.png the same rect (shown instead of squat) |
| 13 | Sit-up picture | picture | 130 | 374 | 460 | 360 | 0 |  | avatar/{sheet}/situp_down.png | B | situp_up.png the same rect (shown instead of squat) |

### Meal minigame (09)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Dock band | box | 0 | 790 | 720 | 490 | 0 | DOCK_BAND |  | B | full width of the screen (not only the column), from y 790 to the bottom of the screen; no radius, no line |
| 2 | Stop pill | pill | 230 | 806 | 260 | 64 | 32 | STOP | tr("UI_STOP") | B | thickness 6 px STOP_BASE under it; pressed: face down 6 px. Left: a square 26 x 26, radius 6, INK, at x 262, y 825. Text Nunito ExtraBold 30, INK, left edge x 304, centred on y 838 |
| 3 | Info line, left | text | 24 | 886 | 420 | 28 | 0 | WHITE | status text | B | Nunito Bold 22, left aligned, one line; made smaller down to 16 if longer |
| 4 | Info line, right | text | 452 | 886 | 244 | 28 | 0 | WHITE | count text | B | Nunito Bold 22, right aligned to x 696 |
| 5 | Tummy bar | pill | 24 | 944 | 672 | 48 | 24 | TRACK | BeatBar.show_level | B | outline 3 px white; fill white to the bites share; green zone ZONE from full_share to 1 (inset 6 px, radius 18), as now |
| 6 | Bite button | box | 24 | 1032 | 444 | 176 | 32 | UP | tr("MINIGAME_BITE") | B | thickness 8 px UP_BASE; a fork icon 64 x 100 INK at x 72, y 1070; a vertical divider 3 x 96 INK 25% at x 168, y 1072; word ExtraBold 52 INK left x 196, centred y 1106; on a computer "[Space]" Bold 24 INK centred under the word at y 1160 |
| 7 | Done button | box | 486 | 1032 | 210 | 176 | 32 | SLEEP | tr("MINIGAME_DONE") | B | thickness 8 px SLEEP_BASE; word ExtraBold 34 INK centred (591, 1106); "[D]" Bold 22 INK at (591, 1156) on a computer; disabled at 45% until full, as now |
| 8 | Stage | zone | 0 | 210 | 720 | 580 | 0 |  | Stage | S | room scenery as now (blue wall, windows); the floor is hidden by the dock band |
| 9 | Eating picture | picture | 110 | 290 | 500 | 500 | 0 |  | avatar/{sheet}/eat_closed.png | B | eat_open.png for 0.25 s after each bite; canvas bottom on y 790 (the dock band covers nothing of it). Mouth (fork target) at x 360, y = 290 + 500 x mouth share: child_male 0.450 (y 515), child_female 0.473 (527), teen_male 0.417 (498), teen_female 0.417 (498) |
| 10 | Speech balloon | box | 85 | 208 | 550 | 76 | 38 | WHITE | as now | T | only for the short reactions, as now |

### Screen time (10)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Stop pill | pill | 230 | 806 | 260 | 64 | 32 | STOP | tr("UI_STOP") | B | thickness 6 px STOP_BASE under it; pressed: face down 6 px. Left: a square 26 x 26, radius 6, INK, at x 262, y 825. Text Nunito ExtraBold 30, INK, left edge x 304, centred on y 838 |
| 2 | Info line, left | text | 24 | 886 | 420 | 28 | 0 | WHITE | status text | B | Nunito Bold 22, left aligned, one line; made smaller down to 16 if longer |
| 3 | Info line, right | text | 452 | 886 | 244 | 28 | 0 | WHITE | count text | B | Nunito Bold 22, right aligned to x 696 |
| 4 | Screen-time bar | pill | 24 | 944 | 672 | 48 | 24 | TRACK | minutes watched / minutes chosen | B | outline 3 px white; fill SCREEN_FILL (inset 6, radius 18) up to the share watched; green zone ZONE with dashed white edges (dash 6, gap 6, 2 px) from 80% to 100% of the bar; a ring SCREEN_TARGET radius 20 line 5 with 4 ticks at the fill end |
| 5 | Keep watching | box | 24 | 1032 | 327 | 176 | 32 | SLEEP | tr("SCREEN_KEEP") | B | thickness 8 px SLEEP_BASE under it (to y 1216); pressed: face down 8 px. screen icon 72 x 56 INK centred (187, 1080); word ExtraBold 32 INK centred (187, 1142); chip (computer) "←  A" pill 120 x 32 centre (187, 1184). Pressing it does nothing (no rule yet, decision 54) |
| 6 | Take a break | box | 369 | 1032 | 327 | 176 | 32 | UP | tr("SCREEN_BREAK") | B | thickness 8 px UP_BASE under it (to y 1216); pressed: face down 8 px. pause icon (two bars 16 x 56, gap 16) INK centred (532, 1080); word ExtraBold 32 INK centred (532, 1142); chip "→  D" centre (532, 1184). Pressing it = the Stop button |
| 7 | Stage | zone | 0 | 210 | 720 | 580 | 0 |  | Stage | S | room scenery (set "scenery": "room" for screens in data/activities.json) |
| 8 | Tablet picture | picture | 180 | 440 | 360 | 350 | 0 |  | avatar/{sheet}/tablet.png | B | canvas bottom on y 790 |
| 9 | Side table top | box | 34 | 700 | 126 | 16 | 6 | WOOD |  | B | outline 3 INK |
| 10 | Side table body | box | 44 | 716 | 106 | 74 | 8 | WOOD_DARK |  | B | outline 3 INK; a knob circle radius 7 INK at (97, 752) |
| 11 | Plant pot | box | 72 | 664 | 52 | 36 | 8 | PLATE |  | B | outline 3 INK; two leaves: ellipses 34 x 22 LEAF, outline 3 INK, centres (82, 646) and (114, 640), turned -30 and +30 degrees |
| 12 | Lamp shade | box | 564 | 600 | 88 | 60 | 8 | LAMP |  | B | a trapezoid: top edge x 576 to 640, bottom edge x 564 to 652; outline 3 INK; glow: draw_glow centre (608, 640) radius 130, #ffe9a8 at alpha 0.35, drawn first |
| 13 | Lamp pole | box | 604 | 660 | 8 | 124 | 4 | INK |  | B | base: ellipse centre (608, 786), 56 x 12, INK |
| 14 | Speech balloon | box | 85 | 208 | 550 | 76 | 38 | WHITE | as now | T |  |

### Cardio on the street (01)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Panel | box | 12 | 760 | 696 | 496 | 28 | PANEL_92 |  | B | line 2 px white; the stop slot above the panel is hidden |
| 2 | Runner icon | picture | 40 | 784 | 40 | 40 | 0 |  | icon runner, white | B | UiIcons runner in a 40 x 40 box |
| 3 | Title | text | 92 | 780 | 200 | 48 | 0 | WHITE | tr("CARDIO_TITLE") | B | Nunito ExtraBold 30, left, centred on y 804 |
| 4 | Minutes | text | 300 | 780 | 176 | 48 | 0 | WHITE | "7 / 60 min" | B | Nunito Bold 26, right aligned to x 476: elapsed / chosen minutes |
| 5 | Stop pill (small) | pill | 484 | 780 | 200 | 48 | 24 | STOP | tr("UI_STOP") | B | thickness 4 STOP_BASE; square 20 x 20 INK radius 5 at x 504, y 794; text ExtraBold 24 INK left x 536 |
| 6 | Steps label | text | 36 | 846 | 300 | 28 | 0 | WHITE | tr("MINIGAME_STEPS_LABEL") | B | Bold 22 left; the count "16 / 173" Bold 22 right aligned to x 684 on the same line |
| 7 | Steps bar | pill | 36 | 880 | 648 | 24 | 12 | STEPS_FILL | steps / steps goal | B | track TRACK |
| 8 | Breath label | text | 36 | 916 | 300 | 28 | 0 | WHITE | tr("MINIGAME_BREATH") | B | Bold 22 left |
| 9 | Breath bar | pill | 36 | 950 | 648 | 24 | 12 | BREATH_FILL | Minigame.reserve | B | track TRACK |
| 10 | Timing box | box | 24 | 990 | 672 | 108 | 20 | TIMING_BOX |  | B | no line |
| 11 | Timing label | text | 40 | 998 | 200 | 28 | 0 | WHITE | tr("TIMING") | B | Bold 22 left; hint tr("TIMING_HINT") Bold 20 white 80% right aligned to x 680 on the same line |
| 12 | Timing bar | pill | 40 | 1036 | 640 | 48 | 24 | TRACK | BeatBar | B | outline 3 white; zone ZONE; marker: a white bar 8 x 64, radius 4, centred on the bar |
| 13 | Tap button | box | 36 | 1112 | 648 | 112 | 40 | UP | tr("MINIGAME_TAP") | B | thickness 8 UP_BASE (to y 1232); footprints icon 56 x 64 INK at x 208, y 1136; word ExtraBold 40 INK, upper case, left x 284, centred y 1168; "[Space]" not shown |
| 14 | Stage | zone | 0 | 210 | 720 | 534 | 0 |  | Stage | S | street scenery as now; ground line at y 684 |
| 15 | Running picture | picture | 228 | 336 | 264 | 360 | 0 |  | avatar/{sheet}/run_01.png | B | shown at 80% (264 x 360, farther away on the street); feet on y 684 (the canvas bottom is 12 px below the feet); next frame at each tap: 01 → 02 → 03 → 04 → 05 → 01; run_01 while waiting |
| 16 | Speech balloon | box | 85 | 208 | 550 | 76 | 38 | WHITE | as now | T |  |

### Football (11, 12)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Field | box | 20 | 210 | 680 | 586 | 28 | STRIPE_A | FootballField | S | the field drawing is clipped to this rounded rect; line 3 px white around it; 8 horizontal stripes of equal height, alternating STRIPE_A (first, at the top) and STRIPE_B; pitch markings as now |
| 2 | Minimap | box | 36 | 226 | 90 | 100 | 8 | STRIPE_B | whole field, 1/7 scale | T | line 2 px white; players as dots radius 3 (red #fe5c65, blue #2990fe, you #fde23b); hidden if the whole field already fits |
| 3 | Score capsule | pill | 584 | 226 | 100 | 40 | 20 | CHIP | tr("MINIGAME_SCORE") | T | Bold 22 white, centred |
| 4 | Panel | box | 16 | 812 | 688 | 424 | 28 | PANEL_92 |  | B | line 2 px white; the stop slot above is hidden |
| 5 | Ball icon | picture | 40 | 828 | 44 | 44 | 0 |  | icon ball, white | B |  |
| 6 | Title | text | 100 | 828 | 220 | 48 | 0 | WHITE | tr("FOOTBALL_TITLE") | B | ExtraBold 30 left, centred on y 852 |
| 7 | Minutes | text | 320 | 828 | 168 | 48 | 0 | WHITE | "12 / 60 min" | B | Bold 26, right aligned to x 488 |
| 8 | Stop pill (small) | pill | 500 | 828 | 188 | 48 | 24 | STOP | tr("UI_STOP") | B | as the cardio one, square at x 518, text left x 550 |
| 9 | Divider | line | 40 | 890 | 640 | 0 | 0 | WHITE_25 |  | B | 2 px |
| 10 | Breath label | text | 40 | 906 | 84 | 28 | 0 | WHITE | tr("MINIGAME_BREATH") | B | Bold 22 left, centred on y 920 |
| 11 | Breath bar | pill | 132 | 908 | 548 | 24 | 12 | BREATH_FILL | Minigame.reserve | B | track TRACK |
| 12 | Joystick ring (touch) | circle | 156 | 1044 | 184 | 184 | 92 | WHITE_08 | FootballPad | B | line 3 px white 60%; 4 small triangles 14 x 10 white 60% at radius 70 (up, down, left, right); thumb: circle radius 36 white with a SHADOW circle radius 36 4 px lower |
| 13 | Keys box (computer) | box | 32 | 956 | 272 | 176 | 20 | WHITE_08 | shown instead of the joystick | B | keycaps 52 x 52 radius 10 white, base 4 TILE_BASE, letter ExtraBold 26 INK: W at (104, 984), A (48, 1044), S (104, 1044), D (160, 1044); "Move" Bold 22 white at x 224, y 1040 and "W A S D" Bold 20 white 80% at x 224, y 1070 |
| 14 | Pass button | box | 320 | 956 | 176 | 176 | 28 | PASS | tr("MINIGAME_PASS") or ASK | B | thickness 8 PASS_BASE; icon (runner and ball) 96 x 56 INK centred (408, 1004); word ExtraBold 28 INK centred (408, 1066); chip "Z" pill 56 x 30 CHIP, Bold 20 white, centre (408, 1106) (computer only); disabled 45% |
| 15 | Shoot button | box | 512 | 956 | 176 | 176 | 28 | SHOOT | tr("MINIGAME_SHOOT") or TACKLE | B | thickness 8 SHOOT_BASE; icon (goal net) 96 x 56 INK centred (600, 1004); word centred (600, 1066); chip "X" centre (600, 1106) |
| 16 | Help strip | pill | 32 | 1152 | 656 | 64 | 32 | WHITE_08 | tr("FOOTBALL_CONTROLS_TOUCH") / _KEYS | B | line 2 white 25%; a white circle radius 20 at (76, 1184) with "?" ExtraBold 26 INK (it is the HelpButton, the whole strip is its touch area); text Bold 20 white left x 112, centred y 1184 |

### Sleeping (13, 14, 15)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Stage | zone | 0 | 210 | 720 | 624 | 0 |  | Stage | S | bedroom scenery: wall and floor as now, the bed is no longer drawn by code |
| 2 | Window (day and night) | picture | 160 | 296 | 400 | 384 | 0 |  | scenery/window_blind.png | B | behind the bed; the sky of the hour (SkyPalette at the clock minute) drawn by code first in the glass rect x 186, y 330, w 348, h 330 |
| 3 | Floor shadow | ellipse | 360 | 778 | 360 | 36 | 0 | SHADOW |  | B | INK at alpha 0.35, under the bed |
| 4 | Bed picture | picture | 210 | 431 | 300 | 347 | 0 |  | avatar/{sheet}/bed.png | B | the avatar and the Blanket node are hidden while it sleeps; canvas bottom on y 778 |
| 5 | Wake up pill | pill | 212 | 850 | 296 | 64 | 32 | SLEEP | tr("WAKE_UP") | B | in the stop slot; thickness 6 SLEEP_BASE; a half sun 44 x 28 INK (half circle radius 14 on a line 44 long, 5 rays 8 long) at x 244, y 866; text ExtraBold 30 INK left x 304, centred y 882. No function (decision 81): pressing it does what the play button does |
| 6 | Four buttons | zone | 24 | 930 | 672 | 318 | 0 |  | as now | B | while sleeping: modulate alpha 0.35, not clickable |

### Exercise menu (02); the entertainment menu uses the same panel

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Panel | box | 40 | 214 | 640 | 690 | 28 | PANEL |  | T | line 2 px white; the rest of the screen is dimmed as now |
| 2 | Icon | picture | 336 | 222 | 48 | 48 | 0 |  | icon runner, white | T |  |
| 3 | Title | text | 72 | 274 | 576 | 48 | 0 | WHITE | tr("EXERCISE_CHOOSE") | T | ExtraBold 40 centred on (360, 298) |
| 4 | Divider | line | 80 | 330 | 560 | 0 | 0 | WHITE_25 |  | T | 2 px |
| 5 | Minutes | text | 72 | 344 | 576 | 32 | 0 | WHITE | tr("UI_MINUTES") % minutes | T | Bold 26 centred on (360, 360) |
| 6 | Slider | pill | 72 | 398 | 576 | 12 | 6 | SLIDER | MinutesSlider | T | track TRACK; fill SLIDER to the value; handle: white circle radius 16 with SHADOW 3 px below; touch area 48 high (y 380 to 428) |
| 7 | Tile ACTIVITY_CARDIO | box | 72 | 448 | 280 | 150 | 24 | TILE | tr("ACTIVITY_CARDIO") | T | thickness 6 TILE_BASE; icon runner 64 x 64 INK centred (212, 500); name Bold 28 INK centred (212, 564); chosen: face EXERCISE, base UP_BASE, badge circle radius 18 BADGE with a white check (line 4) at (334, 466) |
| 8 | Tile ACTIVITY_SQUATS | box | 368 | 448 | 280 | 150 | 24 | TILE | tr("ACTIVITY_SQUATS") | T | thickness 6 TILE_BASE; icon squat 64 x 64 INK centred (508, 500); name Bold 28 INK centred (508, 564); chosen: face EXERCISE, base UP_BASE, badge circle radius 18 BADGE with a white check (line 4) at (630, 466) |
| 9 | Tile ACTIVITY_PUSH_UPS | box | 72 | 614 | 280 | 150 | 24 | TILE | tr("ACTIVITY_PUSH_UPS") | T | thickness 6 TILE_BASE; icon pushup 64 x 64 INK centred (212, 666); name Bold 28 INK centred (212, 730); chosen: face EXERCISE, base UP_BASE, badge circle radius 18 BADGE with a white check (line 4) at (334, 632) |
| 10 | Tile ACTIVITY_SIT_UPS | box | 368 | 614 | 280 | 150 | 24 | TILE | tr("ACTIVITY_SIT_UPS") | T | thickness 6 TILE_BASE; icon situp 64 x 64 INK centred (508, 666); name Bold 28 INK centred (508, 730); chosen: face EXERCISE, base UP_BASE, badge circle radius 18 BADGE with a white check (line 4) at (630, 632) |
| 11 | Cancel | box | 72 | 792 | 280 | 80 | 26 | TILE | "✕  " + tr("UI_CANCEL") | T | thickness 8 TILE_BASE; ExtraBold 30 INK centred |
| 12 | Start | box | 368 | 792 | 280 | 80 | 26 | UP | "▶  " + tr("UI_START") | T | thickness 8 UP_BASE; ExtraBold 30 INK centred. Tapping a tile only chooses it; Start starts the chosen option. The menu opens with the last option chosen (Cardio the first time) |

### Let's eat (06)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Panel | box | 52 | 214 | 616 | 656 | 28 | PANEL |  | T | line 2 px white |
| 2 | Apple icon | picture | 332 | 224 | 56 | 56 | 0 |  | icon apple, white | T |  |
| 3 | Title | text | 80 | 280 | 560 | 48 | 0 | WHITE | tr("EAT_CHOOSE_TITLE") | T | ExtraBold 44 centred on (360, 304) |
| 4 | Divider | line | 148 | 336 | 424 | 0 | 0 | WHITE_25 |  | T | 2 px |
| 5 | Question | text | 80 | 350 | 560 | 34 | 0 | WHITE | tr("EAT_CHOOSE_QUESTION") | T | Bold 26 centred on (360, 367) |
| 6 | Card CANTEEN_GOOD | box | 80 | 400 | 560 | 156 | 28 | TILE |  | T | thickness 8 TILE_BASE; chosen: face EXERCISE, base UP_BASE and a badge circle radius 22 BADGE with a white check at (612, 428) |
| 7 | Card picture CANTEEN_GOOD | picture | 96 | 413 | 260 | 130 | 0 |  | menu/eat_choice_good.png | T |  |
| 8 | Card divider CANTEEN_GOOD | line | 372 | 430 | 0 | 96 | 0 | INK |  | T | 2 px, INK at 25% |
| 9 | Card title CANTEEN_GOOD | text | 392 | 440 | 232 | 40 | 0 | INK | tr("CANTEEN_GOOD") | T | ExtraBold 34 left, centred on y 460 |
| 10 | Card subtitle CANTEEN_GOOD | text | 392 | 488 | 232 | 30 | 0 | SUBTITLE | tr("EAT_GOOD_SUB") | T | Bold 20 left, centred on y 504; may wrap to 2 lines of 22 px |
| 11 | Card CANTEEN_FAST | box | 80 | 578 | 560 | 156 | 28 | TILE |  | T | thickness 8 TILE_BASE; chosen: face EXERCISE, base UP_BASE and a badge circle radius 22 BADGE with a white check at (612, 606) |
| 12 | Card picture CANTEEN_FAST | picture | 96 | 591 | 260 | 130 | 0 |  | menu/eat_choice_fast.png | T |  |
| 13 | Card divider CANTEEN_FAST | line | 372 | 608 | 0 | 96 | 0 | INK |  | T | 2 px, INK at 25% |
| 14 | Card title CANTEEN_FAST | text | 392 | 618 | 232 | 40 | 0 | INK | tr("CANTEEN_FAST") | T | ExtraBold 34 left, centred on y 638 |
| 15 | Card subtitle CANTEEN_FAST | text | 392 | 666 | 232 | 30 | 0 | SUBTITLE | tr("EAT_FAST_SUB") | T | Bold 20 left, centred on y 682; may wrap to 2 lines of 22 px |
| 16 | Cancel | box | 80 | 760 | 270 | 76 | 26 | TILE | "✕  " + tr("UI_CANCEL") | T | thickness 8 TILE_BASE; ExtraBold 30 INK centred |
| 17 | Continue | box | 370 | 760 | 270 | 76 | 26 | UP | "▶  " + tr("UI_CONTINUE") | T | thickness 8 UP_BASE. The panel opens with Good food chosen; Continue opens the canteen of that kind. "Skip meal" (when hungry) stays as a third button under the cards: when it is shown the panel grows 92 px (Skip at y 760, w 560, h 76, TILE; Cancel and Continue move to y 852, the panel bottom to 962) |

### Canteen (07, 08)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Panel | box | 24 | 210 | 672 | 1022 | 28 | PANEL |  | T | line 2 px white; covers the four buttons |
| 2 | Cutlery icon | picture | 168 | 226 | 56 | 56 | 0 |  | icon cutlery (good) / burger (fast), white | T |  |
| 3 | Title | text | 232 | 226 | 320 | 56 | 0 | WHITE | tr("CANTEEN_GOOD") / tr("CANTEEN_FAST") | T | ExtraBold 44 left, centred on y 254 |
| 4 | Food tile 1 | box | 45 | 306 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (104, 364); name Bold 20 INK centred in x 49 to 159, y 416 to 476, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (149, 320) |
| 5 | Food tile 2 | box | 173 | 306 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (232, 364); name Bold 20 INK centred in x 177 to 287, y 416 to 476, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (277, 320) |
| 6 | Food tile 3 | box | 301 | 306 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (360, 364); name Bold 20 INK centred in x 305 to 415, y 416 to 476, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (405, 320) |
| 7 | Food tile 4 | box | 429 | 306 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (488, 364); name Bold 20 INK centred in x 433 to 543, y 416 to 476, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (533, 320) |
| 8 | Food tile 5 | box | 557 | 306 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (616, 364); name Bold 20 INK centred in x 561 to 671, y 416 to 476, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (661, 320) |
| 9 | Food tile 6 | box | 45 | 502 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (104, 560); name Bold 20 INK centred in x 49 to 159, y 612 to 672, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (149, 516) |
| 10 | Food tile 7 | box | 173 | 502 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (232, 560); name Bold 20 INK centred in x 177 to 287, y 612 to 672, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (277, 516) |
| 11 | Food tile 8 | box | 301 | 502 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (360, 560); name Bold 20 INK centred in x 305 to 415, y 612 to 672, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (405, 516) |
| 12 | Food tile 9 | box | 429 | 502 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (488, 560); name Bold 20 INK centred in x 433 to 543, y 612 to 672, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (533, 516) |
| 13 | Food tile 10 | box | 557 | 502 | 118 | 184 | 20 | TILE | food/{id}.png + name | T | picture 100 x 83 centred on (616, 560); name Bold 20 INK centred in x 561 to 671, y 612 to 672, up to 2 lines of 24 px; chosen: face EXERCISE and a badge radius 16 BADGE with a white check at (661, 516) |
| 14 | Plate title | text | 45 | 724 | 630 | 36 | 0 | WHITE | tr("CANTEEN_PLATE") % [n, 4] | T | Bold 28 centred on (360, 742); a 2 px line WHITE_60 from x 45 to (text left - 16) and from (text right + 16) to 675 at y 742 |
| 15 | Plate shadow | ellipse | 360 | 884 | 600 | 200 | 0 | SHADOW |  | T | INK at alpha 0.30, 12 px below the plate |
| 16 | Plate | ellipse | 360 | 872 | 600 | 200 | 0 | PLATE |  | T | rim: a second ellipse 540 x 160, same centre, PLATE_RIM line 3 px |
| 17 | Plate slots | zone | 96 | 822 | 528 | 100 | 0 |  | 4 slots 120 x 100, gap 16 | T | slot x 96, 232, 368, 504; y 822; empty: dashed outline 2 px SLOT_LINE (dash 10, gap 8), radius 20; full: the food picture 120 x 100; tap a full slot to take the food off |
| 18 | Hint | text | 45 | 990 | 630 | 28 | 0 | WHITE_60 | tr("CANTEEN_PLATE_HINT") | T | Bold 20 centred on (360, 1004), one line, made smaller down to 15 |
| 19 | Back | box | 48 | 1120 | 300 | 84 | 26 | SLEEP | "←  " + tr("CANTEEN_BACK") | T | thickness 8 SLEEP_BASE; ExtraBold 32 INK centred |
| 20 | Eat the plate | box | 372 | 1120 | 300 | 84 | 26 | UP | tr("CANTEEN_EAT") | T | thickness 8 UP_BASE; ExtraBold 32 INK; disabled 45% while the plate is empty |

### Canteen, fast food with 8 foods (08)

| # | Element | Kind | x | y | w | h | Radius | Colour | Content | Anchor | Details |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Food tile 1 | box | 45 | 306 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (120, 364); with 10 foods use the five-column grid |
| 2 | Food tile 2 | box | 205 | 306 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (280, 364); with 10 foods use the five-column grid |
| 3 | Food tile 3 | box | 365 | 306 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (440, 364); with 10 foods use the five-column grid |
| 4 | Food tile 4 | box | 525 | 306 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (600, 364); with 10 foods use the five-column grid |
| 5 | Food tile 5 | box | 45 | 502 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (120, 560); with 10 foods use the five-column grid |
| 6 | Food tile 6 | box | 205 | 502 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (280, 560); with 10 foods use the five-column grid |
| 7 | Food tile 7 | box | 365 | 502 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (440, 560); with 10 foods use the five-column grid |
| 8 | Food tile 8 | box | 525 | 502 | 150 | 184 | 20 | TILE | food/{id}.png + name | T | as the good-food tiles: picture 100 x 83 centred on (600, 560); with 10 foods use the five-column grid |
