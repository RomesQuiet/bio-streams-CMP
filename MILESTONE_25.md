# Milestone 25: the new interface, drawn by code (18 Nov 2026)

Request (user, 18 Nov 2026): rebuild the interface from the team's specification
(`plasticTamagotchi01.rtf`, copied to `documentation/ui_specification_v1.md`) and the approved mockups
(`documentation/ui_mockups/`). "Don't change any rules of the current game, except for the wake button,
that is supposed to disappear. You will do the activity backgrounds in this same task."
`documentation/ui_art_brief.md` (the image-generator brief) is no longer the rule: the user deleted it,
and it is removed from the repository.

Everything is drawn by code (shapes, outlines, gradients, see-through colours and text): no mockup
picture and no sprite per state. The avatar keeps the team's art. Game logic, data and navigation do
not change.

## Decisions (user, 18 Nov 2026; answers to Claude's questions)

| # | Decision |
|---|---|
| 79 | The specification v1 and its mockups are the rule for the interface. The old brief is deleted. |
| 80 | The clock shows 12-hour time with AM and PM (replaces decision 76). |
| 81 | The Wake button disappears, as in the mockups. The rule that the game waits after a sleep stays (Claude's reading: "don't change any rules ... except the wake button"): the clock capsule's button shows ▶ while the day waits, and pressing it starts the day, as Wake did. |
| 82 | The danger warning flashes: the heart and the red part of the health pills pulse (replaces the red bar and "Health: danger"; the health tooltip still says "Health: danger"). |
| 83 | "Health N" shows the health rounded down, so the number never says more than the pills show (2.6 is "Health 2" with 2.6 pills). `GameState.health_level` is now rounded down. |
| 84 | Colours as in the mockups, the same by day and night (the black night buttons are gone). |
| 85 | The ground is curved and its colour follows the sky (replaces the grey ground). |
| 86 | Sunrise at 07:00 and sunset at 19:00 (the `daylight` hours stay). |
| 87 | On screens of other shapes the sky and the ground fill the whole screen, and the game keeps its proportions: a column 720 wide, as tall as the screen (HUD at the top, buttons at the bottom). Stretch aspect `expand`. |
| 88 | Font: Nunito (SIL Open Font License), from Google Fonts' official repository. |
| 89 | The activity backgrounds (room, outside, street, bedroom, football field) are redrawn in this milestone, in the same style. |

## What is built

- **Design tokens and drawing helpers:** `scripts/ui/ui_style.gd` (colours, line widths, corner
  radii, press offset and depth, section 14 of the specification) and `scripts/ui/ui_icons.gd`
  (heart, gear, pause, play, runner, bed with Z, apple, game controller, and the request pictures).
- **Theme** (`scenes/ui/main_theme.tres`, every screen): Nunito Bold, white labels, pressable
  neutral buttons (they move down when pressed), navy panels, flat see-through bars, a cyan XP bar.
  `scenes/ui/night_theme.tres` is deleted.
- **Dynamic background** (`scripts/ui/sky_palette.gd`, `sky_background.gd`, `curved_ground.gd`,
  `sky_bodies.gd`): one table of colour stops by hour (sky top, middle and horizon, ground, stars),
  interpolated from the game's clock only. Fixed stars that fade in as it gets dark, a cream sun with
  a soft glow and a warm glow near the horizon, a crescent moon cut by geometry, and a curved ground
  with the avatar's shadow.
- **HUD** (one flat box): heart, "Health N", five pills that are a mask over one continuous bar
  (`scripts/ui/health_pills.gd`), "XP 70 / 100" and its bar, "XP Level" with the level and the next
  one (`scripts/ui/level_display.gd`, numbers roll up or down when the level changes). Clicking the
  health part opens the measures panel under the HUD, as before.
- **Clock and pause** in one capsule, centred; **settings** is only a white gear.
- **Speech balloon** (`scripts/ui/speech_balloon.gd`): white, navy outline, a tail pointing to the
  avatar, the request picture and a divider on the left.
- **Four buttons** (`scripts/ui/action_button.gd`): mint, lavender, salmon and gold, icon over text,
  a thickness below, a short shadow; pressing moves the body down 7 pixels at once and it comes back
  smoothly; disabled ones are paler.
- **Activity backgrounds** (`scripts/ui/scenery.gd`): a blue room with windows to the real sky, the
  outside (the main background), a street with round trees, a bedroom seen from above with a lavender
  blanket. The football field, its controls, the beat bar and the meal fork use the same colours.
- **Screen shape** (`project.godot`: aspect `expand`): the main screen, the menu and the creation
  screen are a 720-wide column in the middle; their backgrounds fill the whole screen; open panels dim
  the whole screen.

## Tests

- New: `tests/interface_test.gd` (the five pills, the colour table with no jumps, sun left before noon
  and right after, the crescent, the 12-hour clock, the theme tokens, aspect `expand`, the main
  screen: "Health 2" for 2.6, "XP 70 / 100", the rolling level, a button pressed, the play button
  that pauses, goes on and starts the day after a sleep, no Wake button, the curved ground, the
  balloon with and without a picture).
- Changed: `scenery_test.gd` (no night buttons; the places follow the clock's minute),
  `measures_test.gd` and `failure_test.gd` (the flashing warning instead of the red bar),
  `health_xp_test.gd` (health rounded down), `clock_test.gd` (12-hour text).
- The scenario and parity tests were not run: no health, XP or time number changed.

## Pictures

`tools/render_ui_states.gd` renders the main screen with a window (one state per run, because a
window that is not in front stops drawing on this Mac): the six moments of the specification
(A 06:30, B 09:00, C 12:00, D 16:30, E 19:15, F 22:15 after a level up), P (a button pressed and one
disabled), X (danger), R (the room), S (the street), Z (the bedroom), W (the sleep is over: ▶), M (the
menu), N (the creation screen). They were checked at 720 x 1280, on a wide window (1600 x 1000) and on
a tall phone (1080 x 2340).

## Done

- Design tokens, icons, the Nunito font (276,932 bytes, `Nunito[wght].ttf` and `OFL.txt` from
  `github.com/google/fonts`, `ofl/nunito`), Bold and ExtraBold variations.
- The theme for every screen; the night theme deleted.
- The dynamic background (sky, stars, sun and moon, curved ground), behind everything with negative
  `z_index`; the main menu (morning sky and ground) and the creation screen (morning sky) use it.
- The HUD, the clock capsule (12-hour), the gear, the balloon, the four buttons.
- The Wake button removed: the play button next to the clock starts the day; `SPEECH_SLEPT` now says
  to press it. Translation keys: new `UI_HEALTH_VALUE`, `UI_XP_LEVEL`, `UI_PLAY_TIP`, `UI_AM`,
  `UI_PM`; removed `UI_WAKE`, `UI_LEVEL`, `UI_HEALTH_LEVEL_TIP`, `MEASURE_HEALTH`. The Portuguese is
  Claude's draft ("Saúde 3", "Nível XP", "Continuar", AM/PM kept as in the mockups).
- The places (room, outside, street, bedroom), the football field and controls, the beat bar and the
  meal fork in the new colours.
- Aspect `expand`: the main screen, menu and creation screen are a 720-wide column as tall as the
  screen; open panels darken the whole screen (`scripts/ui/outside_dim.gd`).
- The balloon: a long text (more than two lines) uses a smaller font, and a tall balloon moves down
  over the avatar's head rather than cover the clock capsule and its ▶ button. `SPEECH_SLEPT` is
  shorter: "I slept %s h. Press play, by the clock, to start the day." ("Dormi %s h. Carrega em
  continuar, junto ao relógio, para começar o dia.").
- The menu and the creation screen show a morning sky (09:00; the sky's `minute` can be set in a scene).
- The web build is exported to `docs/` (not pushed). In the browser pane it loads and draws the menu,
  the creation screen and the main screen (07:01 AM, the sun rising on the left).
- All 35 tests that ran pass (every test except the scenario and parity tests). Committed on 19 Nov 2026 (user: "commit"), not pushed.
- `tools/` is left out of the web export. `assets/art/ui/pause.svg` and `settings.svg` are no longer
  used by the game; they stayed for the web conversion in `web/`, and were deleted with it on 20 Nov 2026.

## Still to check

- A real phone (Android and iOS), and the look in the user's own browser.
- The team: the Portuguese wording; whether AM/PM stays in Portuguese (Portugal uses 24 hours); the
  colour stops of the sky (read from the mockups by eye).
- At noon the sun is behind the avatar's head (it is at the top of its arch, as the specification
  asks); say if it should pass higher or lower.
