# Milestone 15 — The meal minigame

**Status: built and committed (4 November 2026), not pushed.** The user plays it, then pushes.

**Checked in the web build (4 Nov 2026):** a healthy meal started, the fork swings over the avatar, the first bite counts, and the Tummy bar fills toward its green zone. Keys were sent by a script. **Not checked:** a real person playing it, a real phone, and whether the fork's speed is fun. The speech bubble is hidden during a meal so it does not cover the fork, as in football.

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
- The Tummy bar shows the share of the meal eaten. Its green zone starts at 6 bites (8 until 6 Nov 2026): there the avatar says "I'm full!".
- Done ends the meal. After 10 bites it ends by itself.
- With no tap the avatar waits, and the meal ends after 20 seconds, as in the other minigames.
- Effect when the meal ends: kcal = bites / 10 x the portion. Hunger falls as if the avatar had eaten bites / 6 of the portion, at most a whole one. Stopping in the green zone: full for fewer kcal. Eating on to 10 bites: up to 67% more kcal and no fuller.
- On a computer: Space bites, D is Done.
- Scoring meals does not exist: the result is only how many bites were eaten. Missed bites cost nothing but time.

## Easier (5 Nov 2026)

The user found it too difficult. The fork now swings slower (0.3 swings a second instead of 0.5) and speeds up less (+0.02 a bite instead of +0.06), and the target is twice as wide (35% of the swing instead of 18%). A green band at the mouth shows the target and lights up when the fork is in it. At the first bite the fork is in the target about 23% of the time, and still about 23% of a slower swing at the last bite (it was 12% before).

## In between (6 Nov 2026)

The user then found it too easy. The values are now between the two versions: 0.4 swings a second, +0.04 a bite, and a target of 25% of the swing. Each pass of the fork stays in the target about 0.2 s at the first bite and about 0.1 s at the last (hard: 0.12 and 0.06 s; easy: 0.38 and 0.24 s).

## A larger full zone (6 Nov 2026)

The user asked for a larger green zone, to be more realistic: the avatar is now full from 6 bites of 10 (`full_bites`, was 8), so the green zone covers 6 to 10 bites, twice as much of the bar. Stopping at 6 bites gives 60% of the portion's kcal and leaves the avatar as full as a whole portion.

## The tasks

1. **Tummy model** in `Hunger.eat()`: a meal can fill the avatar before the whole portion.
2. **Meal session** in `Minigame`: fork, bites, misses, Done, waiting, saving; the result reaches `Simulation` when the meal ends.
3. **On screen**: the swinging fork over the avatar, the mouth opening, Bite and Done, the Tummy bar with its green zone, short messages, both languages.
4. **Review and finish**: tests, scenario comparison, web build, documents.

## Out of scope

The screens minigame, menus and food choice, the avatar's requests (decision 56).
