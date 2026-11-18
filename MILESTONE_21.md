# Milestone 21 — The canteen: good food or bad food, then a dish

**Status: built (17 November 2026) and changed (18 November 2026), not pushed; the user has not played the new version yet.** Read `CLAUDE.md`, `documentation/handoff.md` and `MILESTONE_19.md` (the plan of Milestones 19 to 21) first.

## Decisions (user, 17 and 18 Nov 2026)

| # | Question | Decision |
|---|---|---|
| 61 | What is the canteen? | **Two steps: first good food or bad food, then one dish from many examples of that kind**, so players learn to tell them apart (18 Nov 2026: "there should be bad food, good food. And then it chooses the plate"). In Portuguese "prato" is both plate and dish; it means the dish. |
| 62 | Does it change the health model? | **No.** "It won't change the health architecture." A good dish is exactly today's healthy meal and a bad dish exactly today's fast-food meal. |
| 63 | The English word | **Dish** ("plate" is the object). |
| 64 | (replaced) | On 17 Nov 2026 a plate of up to 4 foods counted by share; it was built and then replaced by decision 61 on 18 Nov 2026. Nothing of it is left. |

Both concept documents were updated to say this.

## How it plays

- **Eat** opens the canteen: "What kind of food?" with two large buttons, **Good food** and **Bad food**, and **Skip meal** (when the avatar is hungry) and **Cancel**.
- Good food or Bad food shows "Choose a dish" with the 10 dishes of that kind, each a picture and a name. **Back** returns to the first step.
- A tap on a dish eats it: the meal minigame (Milestone 15) starts, with the dish's colour on the fork. The avatar's reactions stay ("Yes, fast food!", "Not this again...", Milestone 16).

## How it works

- `data/canteen.json`: the dishes (id, translation key, good true or false, a placeholder colour) and `meal_for` (good → `healthy_meal`, bad → `fast_food_meal`).
- `scripts/health/canteen.gd`: the dishes of each kind and the meal a dish is.
- `Activities.start_dish()` starts that meal and keeps the dish in `Activities.dish` (saved with the running meal, cleared when it ends). The dish is only shown (the fork's colour); the health code (`Hunger`, `Simulation`, `Diet`, `Happiness`) is exactly as before Milestone 21.
- `scripts/ui/canteen.gd` (the two steps) and `scripts/ui/food_tile.gd` (a dish's picture: a coloured tile with its first letter and its name).

## The dishes (Claude's placeholder list, until the team's examples)

- **Good:** vegetable soup, grilled fish with rice, chicken with salad, pasta with vegetables, lentil stew, omelette with salad, rice with beans, wholemeal sandwich, fruit salad, yoghurt with fruit.
- **Bad:** burger and fries, pizza, hot dog, fried chicken, chicken nuggets, kebab, crisps and a soft drink, doughnut, chocolate milkshake, sweets.
- **Pictures:** Claude's own placeholders (no pictures downloaded: each would need a clear free licence). The team can replace them.
- Portuguese names are Claude's draft ("Comida saudável" and "Comida pouco saudável" for Good food and Bad food).

## Checked

`tests/canteen_test.gd` (the dishes, a good or a bad dish is exactly today's meal, an unknown dish starts nothing, saving, the two steps on screen), `tests/minutes_slider_test.gd` (Eat opens the canteen), `tests/translation_test.gd` (every dish name is a key), all 33 tests, the scenario test output identical to before, renders of both steps in both languages, the web export. **Not checked:** a person playing it, a real phone.

## Out of scope

Walking in the canteen, mixing good and bad food, kcal or portions per dish, tastes and preferences, the eating pace (dropped), the screens minigame (decision 54).
