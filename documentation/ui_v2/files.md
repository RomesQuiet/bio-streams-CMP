# files.md — raster files (pass 3, 21 Nov 2026)

All pictures are in `documentation/ui_v2/assets/`: PNG, transparent background, already cropped, scaled and aligned on a canvas of a fixed size per kind, so the code only draws the whole canvas in a rect. **Where each one is drawn, and at what size, is in the tables of `changes.md`** (the rect always has the canvas's aspect). Copy them into the game under `assets/art/` with the same sub-folders and import each one as the avatar pictures are: lossy WebP quality 0.85 with mipmaps. Load a picture when its state changes, never inside `_draw()` (as the avatar does now).

## Avatar: `assets/avatar/{sheet}/`

`{sheet}`: `child_male`, `child_female`, `teen_male`, `teen_female` (the game's folders; the team's "rapaz_castanho", "rapariga_loira", "rapaz_preto", "rapariga_castanha"). Only the healthy body exists and it is used for every body (user, 21 Nov 2026).

| File | Canvas | Content | Feet / bottom in the canvas |
|---|---|---|---|
| `run_01.png` … `run_05.png` | 660 × 900 | running, seen from behind, 5 frames in order | feet 30 px above the bottom, centred |
| `squat_up.png`, `squat_down.png` | 660 × 900 | squat, standing and down | feet 30 px above the bottom, centred |
| `pushup_up.png`, `pushup_down.png` | 1000 × 680 | push-up, arms straight and chest down | 8 px above the bottom |
| `situp_down.png`, `situp_up.png` | 920 × 720 | sit-up, lying on the mat and sitting up | 8 px above the bottom |
| `bed.png` | 760 × 880 | the whole bed seen from the front, the avatar asleep in it, "Zzz" | bed feet 8 px above the bottom |
| `eat_open.png`, `eat_closed.png` | 1120 × 1120 | seated on a red chair behind a table with a red and white checked tablecloth, hands on the table; mouth open / closed; no fork. The two are aligned pixel for pixel | tablecloth edge about 40 px above the bottom |
| `tablet.png` | 720 × 700 | in a blue armchair with a tablet | armchair feet 8 px above the bottom |

Mouth point of the eating pictures, as a share of the canvas from the top-left (x, y): `child_male` (0.50, 0.450), `child_female` (0.50, 0.473), `teen_male` (0.50, 0.417), `teen_female` (0.50, 0.417).

The running frames and `squat_up` have exactly the height of the game's `healthy_happy.png` of the same sheet, feet on the same line. Within each pair the two states have the same head size, matched by eye (±5%). The running figure may move a few pixels between frames (the pictures were made one by one): if one frame jumps in the game, say which.

## Foods: `assets/food/{id}.png`

Canvas 240 × 200, the food centred, filling about 92%.

- **In the canteen, good food (10):** `vegetable_soup`, `grilled_fish`, `wholemeal_bread`, `apple`, `salad`, `orange`, `rice`, `yoghurt`, `beans`, `water`.
- **In the canteen, fast food (8):** `burger`, `fries`, `pizza`, `hot_dog`, `fried_chicken`, `soft_drink`, `doughnut`, `ice_cream`.
- **Spare (not used in the game; three are in the good-food card):** `banana`, `broccoli`, `carrot`, `pear`, `strawberries`.

## Menu: `assets/menu/`

| File | Canvas | Content |
|---|---|---|
| `eat_choice_good.png` | 520 × 260 | the "Good food" card picture: salad, carrot, apple, banana; no words |
| `eat_choice_fast.png` | 520 × 260 | the "Fast food" card picture: burger and fries; no words |

Made by Claude from the food pictures (21 Nov 2026). The team's cards with English words are in `work/menu_cards_en/` and are not used (`changes.md`, Q11).

## Scenery: `assets/scenery/`

| File | Canvas | Content |
|---|---|---|
| `window_blind.png` | 900 × 864 | a wooden window with a roller blind half down and a cord; the glass is transparent, so the sky is drawn behind it |

## Still to come (the team)

Two more fast foods, `food/{id}.png`, 240 × 200, centred, with their id, name key and Portuguese. When they come, the fast-food grid uses the five-column layout of the good food (`changes.md`).

## How the files were made

`work/normalise.py` (first zip; hand corrections in `work/manual_scale.json`), `work/normalise_v2.py` (second zip). `work/layout_spec.py` writes the tables of `changes.md` and draws the check pictures in `work/layout_check/`.
