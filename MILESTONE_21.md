# Milestone 21 — The canteen: good food or fast food, then build a plate

**Status: built (17 November 2026), changed twice (18 November 2026); the third version is committed, not pushed. The user has not played it yet.** Read `CLAUDE.md`, `documentation/handoff.md` and `MILESTONE_19.md` (the plan of Milestones 19 to 21) first.

## Decisions (user)

| # | Date | Decision |
|---|---|---|
| 62 | 17 Nov 2026 | **The canteen does not change the health model.** "It won't change the health architecture." |
| 65 | 18 Nov 2026 | **Two steps: first Good food or Fast food, then the player builds a plate of up to 4 foods of that kind** and eats it. "The plate build should keep, you removed it." Good and fast food are not mixed on one plate. |
| 66 | 18 Nov 2026 | **The bad kind is called Fast food** ("specify the bad as fast food"), in Portuguese too. |
| 67 | 18 Nov 2026 | **Write everything that is done in the .md files** ("Remember to write everything you do on the .md files"). |

Decisions 61, 63 and 64 belonged to the earlier versions (below) and are replaced.

## How it plays (third version)

- **Eat** opens the canteen: "What kind of food?" with two large buttons, **Good food** and **Fast food**, and **Skip meal** (only when the avatar is hungry) and **Cancel**.
- Good food or Fast food shows the 10 foods of that kind (a picture and a name), "Your plate (n of 4)", the hint "Tap a food to put it on your plate. Tap it on the plate to take it off.", the 4 places of the plate, **Eat the plate** (enabled with at least one food) and **Back** (to the first step; the plate starts empty again).
- A tap on a food puts it on the plate; with 4 foods the others fade and cannot be added. A tap on a food on the plate takes it off.
- Eat the plate starts the meal minigame (Milestone 15); the plate's foods come on the fork in turn (their colours). The avatar's reactions stay ("Yes, fast food!", "Not this again...", Milestone 16).

## How it works

- **No change to the health model (decision 62):** a good plate starts exactly today's healthy meal and a fast-food plate exactly today's fast-food meal (`meal_for` in `data/canteen.json`; the food values are in `data/foods.json`, decision 3 unchanged). The plate is only shown. `scripts/health/hunger.gd` and `scripts/autoload/simulation.gd` are exactly as before Milestone 21 (checked with `git diff`), and the scenario test prints exactly the same.
- `data/canteen.json`: each food has an id, a translation key (`FOOD_...`), its kind (`good` or `fast_food`) and a placeholder colour.
- `canteen.plate_max` in `data/config.json`: 4.
- `scripts/health/canteen.gd`: the foods of a kind, the meal of a kind, whether a plate can be eaten (1 to 4 known foods of one kind).
- `Activities.start_plate(foods)` starts the meal of the plate's kind and keeps the plate in `Activities.plate`; the plate is saved with the running meal and cleared when the meal ends or another activity starts. A mixed or empty plate starts nothing.
- `scripts/ui/canteen.gd` (the two steps; built in code and added to the main screen by `scripts/ui/main.gd`, under the failure screen; hidden when failure opens) and `scripts/ui/food_tile.gd` (a food's picture: a coloured tile with its first letter and its name; an empty place of the plate is a dashed square).

## The foods (Claude's placeholder list, until the team's examples)

- **Good food:** vegetable soup, grilled fish, salad, rice, beans, wholemeal bread, apple, orange, yoghurt, water.
- **Fast food:** burger, fries, pizza, hot dog, fried chicken, chicken nuggets, kebab, soft drink, milkshake, doughnut.
- **Pictures:** Claude's own placeholders (no pictures were downloaded: each would need a clear free licence). The team can replace them.
- The Portuguese names are Claude's draft ("Comida saudável" for Good food; "Fast food" stays in Portuguese).

## Checked (third version, 18 Nov 2026)

- `tests/canteen_test.gd`: the foods of each kind (10 and 10), the meal of each kind, a plate is 1 to 4 foods of one kind, a good plate is exactly today's healthy meal, a fast-food plate exactly today's fast-food meal, a mixed or empty plate starts nothing, a plate is saved and loads, the plate goes when the meal ends, and on screen: the first step, Skip meal only when hungry, Good food shows only good foods, at most 4 foods, taking one off, Back and Fast food give a new empty plate, Eat the plate starts the meal with the plate.
- `tests/minutes_slider_test.gd` (Eat opens the canteen; a plate keeps the meal's fixed time), `tests/translation_test.gd` (every food name is a key).
- All 33 tests; the scenario test output identical to before Milestone 21; renders of both steps in English and Portuguese; the web export.
- **Not checked:** a person playing it, a real phone.

## History

1. **First version (17 Nov 2026, `7192c69`):** one screen with a healthy and a bad chooser side by side; a plate of up to 4 foods of both kinds, counted by share (3 healthy and 1 bad = 3/4 of a healthy meal and 1/4 of a fast-food meal) through a new `Hunger.eat_part()` and a split in `Simulation`. The user: "it shouldn't be like that, there should be bad food, good food. And then it chooses the plate."
2. **Second version (18 Nov 2026, `a288051`):** "prato" was read as "dish": first good or bad food, then one ready dish; the plate and the split were removed and the health code restored. The user: "the plate build should keep, you removed it. Also specify the bad as fast food."
3. **Third version (18 Nov 2026, this one):** good food or fast food, then build a plate of up to 4 foods of that kind. No split by share is needed, because a plate has only one kind; the health code stays as before Milestone 21.

## Out of scope

Walking in the canteen, mixing good and fast food on one plate, kcal or portions per food, tastes and preferences, the eating pace (dropped), the screens minigame (decision 54).
