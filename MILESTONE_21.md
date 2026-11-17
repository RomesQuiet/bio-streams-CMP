# Milestone 21 — The canteen: build a plate with the food choosers

**Status: built (17 November 2026), not pushed; the user has not played it yet.**

**Built:** `data/canteen.json` (20 placeholder foods, 10 healthy and 10 bad, Claude's list until the team's examples), `canteen.plate_max` 4, `scripts/health/canteen.gd` (the foods, how a plate splits into the two meals, the meal it is eaten as), `Activities.start_plate()` and `Activities.plate` (saved with the running meal), `Hunger.eat_part()`, the split in `Simulation`, `scripts/ui/canteen.gd` and `scripts/ui/food_tile.gd` (the screen: two choosers in grids of 5, the plate of 4 places, Eat the plate, Skip meal when hungry, Cancel), the plate's foods on the fork in turn. **Pictures:** Claude made its own placeholders, a coloured tile with the food's first letter and its name (no pictures downloaded: each would need a clear free licence; the team can replace them). **Checked:** `tests/canteen_test.gd` (19 checks: the foods, 3 and 1 counts 3/4 and 1/4, a healthy or a bad plate is exactly today's meal, a mixed plate lies between them, saving, the screen), `tests/minutes_slider_test.gd` (Eat opens the canteen), `tests/translation_test.gd` (every food name is a key), all 33 tests, the scenario test output identical to before, renders in both languages and of a plate being eaten, the web export. **Not checked:** a person playing it, a real phone. Read `CLAUDE.md`, `documentation/handoff.md` and `MILESTONE_19.md` (the plan of Milestones 19 to 21) first.

## Decisions (user, 17 Nov 2026)

| # | Question | Decision |
|---|---|---|
| 61 | What is the canteen? | **A food chooser that builds a plate:** a healthy food chooser and a bad food chooser, with many examples so players learn to tell them apart. No walking to a counter, no food categories with limits, no kcal per food. |
| 62 | Does it change the health model? | **No.** "It won't change the health architecture." |
| 63 | A plate with healthy and bad foods | **Counts by share:** h healthy and b bad foods count as h / (h + b) of today's healthy meal and b / (h + b) of today's fast-food meal. |
| 64 | Plate size | **Up to 4 foods** (at least 1). |

Both concept documents (English and "Conceito do Jogo V3") were updated on 17 Nov 2026 to say this.

## How it plays

- **Eat** opens the canteen instead of the two meal buttons. It has two choosers, **Healthy food** and **Bad food**. Each shows many foods as a picture and a name.
- A tap on a food puts it on the plate; a tap on a food on the plate takes it off. The plate holds up to 4 foods.
- **Eat the plate** (enabled with at least one food) starts the meal minigame (Milestone 15), with the plate's foods on the fork. **Skip meal** stays when the avatar is hungry, and **Cancel** closes the canteen.
- The avatar's reactions stay ("Yes, fast food!" and "Not this again...", Milestone 16), from the plate's larger share.

## How it works (no change to the health model)

- Today a meal ends in `Simulation._on_activity_ended()`: `Hunger.eat(option_id, share, full)`, `Happiness.on_meal(option_id, share)` and `Diet.on_meal(option_id, share)`, where share is the part of the meal eaten (Stop or the minigame's bites).
- A plate runs these same three calls once for `healthy_meal` with share x h / (h + b) and once for `fast_food_meal` with share x b / (h + b). The model already handles part of a meal, so kcal, satiety, diet quality, craving, habituation and happiness work as now. **Happiness reads C and A from before the meal for both parts** (as it does now), so the order of the two parts does not change the result.
- The meal activity is the healthy or the fast-food option (its time, METy and scenery are the same); the plate's foods are kept with the running meal and saved with it.
- A plate of only healthy foods is exactly today's healthy meal; only bad foods, exactly today's fast-food meal. Without a player, nothing changes, so **the scenario tests stay the same**.

## The foods

- A new `data/canteen.json`: for each food an id, a translation key, `healthy` true or false, and a placeholder colour and shape for its picture.
- **From the team (asked on 17 Nov 2026):** 8 to 12 healthy and 8 to 12 bad examples, with names in Portuguese and English, and pictures later. Until they arrive, a placeholder list (Claude's draft, marked placeholder), for example:
  - healthy: vegetable soup, grilled fish, salad, apple, orange, rice, beans, yoghurt, water, wholemeal bread;
  - bad: burger, fries, pizza, hot dog, soft drink, crisps, sweets, fried chicken, doughnut, milkshake.
- Config: `canteen.plate_max` 4 (decision 64).

## The tasks

Each task is tested and committed on its own. Nothing is pushed.

1. **Foods and the plate's split:** `data/canteen.json`, `canteen.plate_max`, the split into the two meals in `Simulation`, and saving the plate. Tests: a full healthy or bad plate gives exactly today's meal; a 3-and-1 plate gives 3/4 and 1/4; the scenario test output is unchanged.
2. **The canteen screen:** the two choosers, the plate, Eat the plate, Skip meal, Cancel, both languages, day and night buttons.
3. **The plate in the meal minigame:** the plate's foods on the fork, the reactions.
4. **Review and finish:** all tests, the scenario comparison, the web build, the documents. The user plays it.

## Out of scope

Walking in the canteen, food categories and their limits, kcal or portions per food, tastes and preferences, the eating pace (dropped), the screens minigame (decision 54).
