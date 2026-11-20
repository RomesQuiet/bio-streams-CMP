# Graphics brief — My Healthy Avatar

A brief for a second Claude (or anyone) who works on the game's look **away from the coding session**. You have the whole repository. Do all the design work, calculations and pictures on your side; the coding session only copies your final values into the code, so it must receive **text with final numbers, not pictures to interpret**.

## 1. The project in short

- A web game for the Bio-Streams (EU) science competition on **childhood obesity**, made by a 9th-grade student and team. The player cares for an avatar (a school student) and raises its health (1 to 5) through sport, sleep and food.
- Players are school students; the tone is friendly but **scientifically correct, not childish**.
- Everything is public and free: art is **CC BY 4.0**. Do not use third-party assets without a clear free licence.
- Read first: `CLAUDE.md` (sections "Interface" and "Technical decisions"), `documentation/ui_specification_v1.md` (the team's current interface rules, in Portuguese) and `documentation/ui_mockups/`.
- To see the game as it is now, open the published web version (GitHub Pages, built from `docs/`), or open the project in Godot 4.6.3.

## 2. Limits you must design within

- **Engine:** Godot 4.6.3, Compatibility renderer, runs in a phone browser. No shaders, no heavy effects, no blur. Everything except the avatar is drawn by code from simple shapes: rounded rectangles, circles, ellipses, lines, vertical gradients, soft glows.
- **Layout:** a portrait column **720 px wide**, at least 1280 tall (HUD at the top, four buttons at the bottom). On wider or taller screens the sky, ground and backgrounds fill the rest, so design the space around the column too.
- **Font:** Nunito (bold and extra bold, `assets/fonts/nunito/`). Text exists in **English and Portuguese**; Portuguese is often about 30% longer, so leave room.
- **Images (only if really needed):** PNG with a transparent background, at **2x the on-screen size**, never larger than 4096 px on a side. The avatar pictures are 660 x 900 (shown at 330 x 450) with the feet at the bottom centre; new avatar art must follow `data/avatar_art.json` and `tools/cut_avatar_sheets.py` (5 bodies x 5 faces per sheet, 4 sheets).
- **Do not change** game rules, what information is on screen, or the order of the four buttons (exercise, sleep, eat, entertainment) without the team's agreement.

## 3. What has a look (and where it lives in the code)

| Part | File |
|---|---|
| Colours, line widths, corner radii, button depth, ground shape | `scripts/ui/ui_style.gd` (constants) |
| Icons (heart, gear, pause, play, runner, bed, apple, controller, cutlery, burger, screen, ball) | `scripts/ui/ui_icons.gd` |
| Sky, ground and star colours by hour of the day | `scripts/ui/sky_palette.gd` (`STOPS`: one row per hour = sky top, middle, horizon, ground top, ground bottom, stars) |
| Sun and moon | `scripts/ui/sky_bodies.gd` |
| Four big buttons | `scripts/ui/action_button.gd` |
| Small buttons, panels, text sizes | `scenes/ui/main_theme.tres` |
| Health pills, XP level, speech balloon, request pictures | `health_pills.gd`, `level_display.gd`, `speech_balloon.gd`, `request_icon.gd` in `scripts/ui/` |
| Backgrounds: room, outside, street, bedroom | `scripts/ui/scenery.gd` |
| Football field, meal fork, canteen food tiles, failure screen gauges | `football_field.gd`, `meal_fork.gd`, `food_tile.gd`, `habit_gauge.gd` |
| Screens | main game, menu, creation, settings, failure, the minigames (cardio, strength, football, meal), canteen |

States to cover: day and night, sleeping, waiting for the play button, buttons normal / pressed / disabled, the danger state (heart and health pills flash), an activity running (stop button, its background).

## 4. What to send back (the only part the coding session reads)

Put everything in **one folder: `documentation/ui_v2/`**. Do not edit any other file in the repository. Keep mockups and working files in `documentation/ui_v2/work/`; the coding session **will not open them** (pictures cost too much to read). Only these text files are read:

### 4.1 `values.md`: every changed number, final

Use the **exact constant names** from the files above, one per line, with the old value so mistakes are easy to spot. Units: pixels on the 720-wide layout, hex colours (`#rrggbbaa` when see-through), seconds. Nothing left to calculate.

```
## scripts/ui/ui_style.gd
BUTTON_CORNER_RADIUS = 34        (was 30)
EXERCISE_COLOR = #6fe0c4         (was #84f2da)
HUD_LINE = #ffffffcc             (was white at 0.85)

## scripts/ui/sky_palette.gd  (whole STOPS table, one row per hour)
6:00  top #1b2a6b  middle #3a4fa0  horizon #f2a27a  ground_top #4b7a5a  ground_bottom #2f5240  stars 0.3
...
```

A new value that has no constant yet goes under `## new`, with a name, its value and the part it belongs to.

### 4.2 `changes.md`: everything that is not just a number

A numbered list, one short sentence each, naming the exact part, with every measurement written out:

```
1. Speech balloon: the tail comes from the bottom left corner, 28 px wide, 22 px tall.
2. Gear icon: 6 teeth instead of 8; inner hole radius 0.35 of the icon box.
3. Bedroom: add a window 160 x 120 at x 80, y 200 (column coordinates), showing the sky.
```

For a new or changed **icon or background drawn by code**, describe it as shapes with coordinates: circles (centre, radius), rounded rectangles (x, y, width, height, radius), lines (from, to, width), polygons (list of points), each with its colour. Use a box of 100 x 100 for icons (the code scales it); use column coordinates (0 to 720 wide, 0 at the top, the ground line at 1280 − 60) for backgrounds.

For an animation: what moves, from what to what, how long (seconds), and the easing (linear, ease out, bounce).

### 4.3 `files.md` (only if there are new image files)

One line per file in `documentation/ui_v2/assets/`: file name, pixel size, anchor point ("feet at bottom centre", "centre"), and when it is shown. Example:
`blanket.png — 700 x 420 — anchor top centre — over the avatar while it sleeps`

### 4.4 `licence.md`

Who made each image and with which tool, and that it is CC BY 4.0.

## 5. How to work

- Change in small, numbered steps, so the team can approve or reject each one.
- When you are unsure what the team wants, write the question at the top of `changes.md` instead of guessing.
- Check that text and white elements stay readable on both the brightest day sky and the darkest night sky.
- Check that tapping targets are at least 88 px on the 720-wide layout (44 px on a phone).
