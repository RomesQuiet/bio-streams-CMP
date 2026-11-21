# Milestone 40 — the new look from `documentation/ui_v2/`

Started 21 Nov 2026 (40 is the user's number; there are no Milestones 36 to 39).

**Source:** the second Claude account's pass 3 (`documentation/graphics_brief.md`), delivered as `ui_v2.zip` and unpacked to `documentation/ui_v2/`: `changes.md` (12 changes in order, decisions Q1 to Q11, a table for every element), `values.md` (colours), `files.md` (pictures), `licence.md`, and `assets/` (the pictures). `work/` (mockups and scripts) is not read, except one picture of `work/layout_check/` when a table is unclear. `documentation/ui_v2/.gdignore` keeps Godot from importing those files; the pictures used by the game are copied to `assets/art/`.

**How we work (user, 21 Nov 2026):** the 12 changes one at a time, in order. After each one: headless check, only the tests it touches, a commit, and what to check in the Godot editor; then wait for the user's OK. Nothing in the health model, the minigame rules or the timings changes; only the look, plus the canteen list in change 12. The fast-food canteen has 8 foods (4 columns) until the team sends two more. **No push and no publishing:** `licence.md` says the team must first confirm that the image tool allows CC BY 4.0.

**Before change 1:** the Milestone 35 work (the video game), which was built but not committed, was committed on its own (`d90bbe1`) so each change of this milestone is a clean commit.

## Changes

| # | Change | State | Commit |
|---|---|---|---|
| 1 | Colours (`values.md`) | done, waiting for the user's check | see git log |
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

## Contradictions found (to ask before the change they touch)

- **Change 7 (screen time) and Milestone 35.** `changes.md` was written for Screens as plain screen time (Q1: "decision 54 stays open"; a room, the tablet picture, a screen-time bar, Keep watching and Take a break). Since Milestone 35 Screens is the "Video game" with its own Cloud jump screen (decision 54 is answered by decisions 103 to 108). Ask the user before change 7.
