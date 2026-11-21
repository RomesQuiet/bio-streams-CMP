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
| 2 | Activity dock (squats, push-ups, sit-ups, meal, screens) | | |
| 3 | Exercise pictures | | |
| 4 | Cardio panel and running pictures | | |
| 5 | Football field, minimap, score, panel | | |
| 6 | Meal: eating pictures, dock band | | |
| 7 | Screen time | | |
| 8 | Sleep: bed, window, Wake up | | |
| 9 | Exercise and entertainment menus | | |
| 10 | Let's eat | | |
| 11 | Canteen with pictures | | |
| 12 | Canteen list (`data/canteen.json`) | | |

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

## Contradictions found (to ask before the change they touch)

- **Change 7 (screen time) and Milestone 35.** `changes.md` was written for Screens as plain screen time (Q1: "decision 54 stays open"; a room, the tablet picture, a screen-time bar, Keep watching and Take a break). Since Milestone 35 Screens is the "Video game" with its own Cloud jump screen (decision 54 is answered by decisions 103 to 108). Ask the user before change 7.
