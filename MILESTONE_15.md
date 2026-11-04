# Milestone 15 — The meal minigame

**Status: in progress (4 November 2026).**

Goal: meals become a minigame. The concept says every activity except sleep has one; football, cardio and strength are done, screens wait (decision 54).

Read `CLAUDE.md`, `documentation/handoff.md` and `MILESTONE_12.md` first. The rules of the earlier minigames still hold: a session only exists with a player, so the scenario tests and every health number stay as they are.

## Decisions (user, 4 Nov 2026)

| # | Question | Decision |
|---|---|---|
| 52 | Which minigame next? | **Meals.** |
| 53 | What does the player do? | **Both:** take bites at a calm pace (wait for the chewing to finish), and press Done when the Fullness bar is full. |
| 54 | Screens? | **Decide later.** |
| 55 | What changes? | **A calm eater is full sooner, so it eats less of the portion and takes fewer kcal; less weight follows.** It is no hungrier afterwards. |
| 56 | "The avatar will ask for things throughout the day" | **Talk about it after the minigames.** |

## The science

| Fact | Source | Used for |
|---|---|---|
| Slower eating lowers energy intake (22 studies, standardised mean difference 0.45), with no difference in hunger at the end of the meal or up to 3.5 hours later. | Robinson et al. 2014, Am J Clin Nutr 100(1):123–151 (abstract) | Calm eating makes the avatar full on less food; hunger after the meal is the same as after a full portion. |
| Children of 4.5 who ate faster ate much more energy at a lunch (r = 0.61 with eating rate), with larger bites and fewer chews per gram. Observational: one meal. | GUSTO cohort (Fogel et al. 2017, Br J Nutr) | Rushed bites (fewer chews) count against calm eating. |

The size of the effect in grams is not taken from a study: `calm_cut` (a calm eater is full at 85% of the portion) is a placeholder.

## How it plays

The meal is fixed (a healthy or a fast-food portion). The player taps **Take a bite**; each bite is 1/12 of the portion. The avatar chews for 2 seconds; a bite before the chewing ends is rushed. The **Fullness** bar rises with each bite, faster when the bites so far were calm. When it is full the avatar says "I'm full!" and the player presses **Done**. Eating on past full is allowed: those kcal give no more fullness. With no bite the avatar waits, and the meal ends after 20 seconds, eaten or not (as in the other minigames).

Effect, worked out when the meal ends: kcal = bites eaten / 12 x the portion. Hunger falls as if the avatar had eaten (bites / the share at which it is full) of the portion, at most one portion. A rushed eater is full only at the whole portion, as before.

## The tasks

1. **Fullness model** in `Hunger.eat()`: a meal can be full before the whole portion.
2. **Meal session** in `Minigame`: bites, calm, Fullness, Done, waiting, saving; the result reaches `Simulation` when the meal ends.
3. **On screen**: Take a bite and Done, the Fullness bar, the chewing bar, the avatar chewing, "I'm full!", texts in both languages. Space or Enter bites, D is Done.
4. **Review and finish**: tests, scenario comparison, web build, documents.

## Out of scope

The screens minigame, menus and food choice, the avatar's requests (decision 56), and any health value except the new placeholders.
