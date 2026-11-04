# Milestone 15 — The meal minigame

**Status: in progress (4 November 2026).**

Goal: meals become a fun minigame. The rules of the earlier minigames still hold: a session only exists with a player, so the scenario tests and every health number stay as they are.

## Decisions (user, 4 Nov 2026)

| # | Question | Decision |
|---|---|---|
| 52 | Which minigame next? | **Meals.** |
| 53 | What does the player do? | **Feed the mouth:** a fork swings left and right; tap when it is at the avatar's open mouth. A hit is a bite and fills the Tummy bar; a miss drops the food. Press **Done** when the Tummy bar reaches the green zone. Fun first, not too much science. |
| 54 | Screens? | **Decide later.** |
| 55 | What changes? | **Stopping when full means the avatar eats less of the portion, so fewer kcal and less weight.** It is no hungrier for it: the green zone already counts as full. |
| 56 | "The avatar will ask for things throughout the day" | **Talk about it after the minigames.** |

The idea that eating less of a meal can still leave you full comes from studies on eating slowly (Robinson et al. 2014); the game keeps only that idea. All the numbers are placeholders.

## How it plays

- A meal is 10 bites. The fork swings faster with each bite.
- The Tummy bar shows the share of the meal eaten. Its green zone starts at 8 bites: there the avatar says "I'm full!".
- Done ends the meal. After 10 bites it ends by itself.
- With no tap the avatar waits, and the meal ends after 20 seconds, as in the other minigames.
- Effect when the meal ends: kcal = bites / 10 x the portion. Hunger falls as if the avatar had eaten bites / 8 of the portion, at most a whole one. Stopping in the green zone: full for fewer kcal. Eating on to 10 bites: 25% more kcal and no fuller.
- On a computer: Space bites, D is Done.

## The tasks

1. **Tummy model** in `Hunger.eat()`: a meal can fill the avatar before the whole portion.
2. **Meal session** in `Minigame`: fork, bites, misses, Done, waiting, saving; the result reaches `Simulation` when the meal ends.
3. **On screen**: the swinging fork over the avatar, the mouth opening, Bite and Done, the Tummy bar with its green zone, short messages, both languages.
4. **Review and finish**: tests, scenario comparison, web build, documents.

## Out of scope

The screens minigame, menus and food choice, the avatar's requests (decision 56).
