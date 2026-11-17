# Milestones 19 to 22 — The team's new minigame ideas (plan)

**Status: plan, 17 November 2026. Nothing is built.** Claude's proposals, to be confirmed by the user (and the team where it says so). Read `CLAUDE.md` and `documentation/handoff.md` first.

Source: the team's "Ideias Extras v2" (16 Nov 2026) and the Portuguese "Conceito do Jogo V3" (sections 4, 5, 8 and 9). Both concept documents were updated on 17 Nov 2026 to say what is built and what is new.

## The four ideas, and how big each one is

| # | Idea | What the documents say | Size | Changes the health model? |
|---|---|---|---|---|
| A | **Cardio on a street** | The avatar is seen from behind, running down a street with trees; the avatar stays in place and the scenery comes closer and repeats. | Small | No: only what the screen shows. |
| B | **Squats or push-ups** | The player chooses squats or push-ups and must really do the chosen exercise (how: open). | Medium | No, if both count as strength (proposal). |
| C | **Eating pace** | Bring the food to the mouth at a balanced pace, neither too fast nor too slow. | Small to medium | A little: pace changes when the avatar feels full (a placeholder rule). |
| D | **The canteen** | The player walks the avatar (joystick) to the counter, picks foods by category (sides, meat, fish, fruit), builds the plate, then eats it with the meal minigame. Fast food (burgers) is one of the canteen's foods. Open: view, plate rules, portions, the foods. | Large | Yes: a plate replaces the two fixed meals (decision 3). Needs the team. |

**Proposed order (smallest and safest first):** Milestone 19 = A, Milestone 20 = B, Milestone 21 = C, Milestone 22 = D. A, B and C do not wait for the team; D needs the team's food list first, so asking them now lets it start on time. The Bio-Streams deadline is 30 November 2026 ("Dúvidas de implementação"); with that date, A, B and C fit, and D may not: see question 1.

The rules of the earlier minigames still hold for all four: a session only exists with a player, so the scenario tests and every health number stay as they are unless a decision below changes the model on purpose. All new numbers are placeholders in `data/config.json`.

## Milestone 19 — Cardio on a street (A)

- **Proposal:** during cardio the stage shows a street seen from behind the avatar: road, pavement and trees on both sides, drawn in perspective (placeholder shapes, like the other places). Each stride moves the scenery towards the player by one step, so the street "runs" as fast as the player taps; walking (empty Breath) moves it slower; waiting stops it. The minigame, its score and its numbers do not change.
- **The avatar from behind:** the team's sprite sheets only show the front. Until the team draws a back view (one picture per body, as the front sheets), the placeholder is the front picture in a dark silhouette (or the egg seen from behind). **Question for the team:** can you add a back view to the sheets (5 bodies; the face does not show)?
- **Day and night:** the sky follows the clock, as in the room's windows.
- Tasks: 1) the street place (`scenery.gd` gets "street", moved by the strides); 2) the back-view placeholder and the place in `activities.json`; 3) tests, web build, documents. About a day of work.

## Milestone 20 — Squats or push-ups (B)

- **Choice:** Exercise shows Cardio, **Squats** and **Push-ups** (instead of "Muscle strength"). Both are the strength minigame (Down, then Up = one repetition) and both train strength in the model, as now. Both are body-weight exercises that the AAP 2020 report (already the source of Milestone 13) accepts for children and teenagers.
- **"Really do the exercise" (the open point).** Options:
  1. **On trust (proposed for now):** the screen asks the player to do each repetition for real, with the avatar, and to press Down and Up as they go down and up. The press rhythm (1 second each, technique score) already matches a controlled real repetition. No device feature is needed.
  2. **Phone motion sensors (later, optional):** holding the phone (squats) or with the phone on the floor under the chest (push-ups), the browser's motion sensor counts the repetitions. It works only on phones; iPhones ask for permission first; it needs testing on real phones. Possible as a later milestone.
  3. **Camera: no.** It would film children, and the project keeps no personal data.
- **Squats and push-ups differ:** push-ups are harder for the upper body. Proposal: a placeholder factor that gives push-ups fewer repetitions than squats for the same strength (`minigame.strength.pushup_reps_share`, 0.7). Each has its own animation and placeholder picture (the art has no squat or push-up pose: the team could draw them).
- Tasks: 1) two options in `activities.json` (same training type), the factor; 2) the on-trust screen text and the pictures; 3) tests (the scenario test stays the same), web build, documents.

## Milestone 21 — Eating pace (C)

- **Science, one idea:** eating fast goes with eating more and with more overweight (Ohkuma et al. 2015, a meta-analysis; in children, Fogel et al. 2017); fullness takes time to arrive. The game already uses this idea: stopping when full means fewer kcal (decision 55, Robinson et al. 2014).
- **Proposal:** the meal minigame measures the time between bites. A **pace bar** shows it, with a green middle zone.
  - **Too fast** (bites closer than `minigame.meal.fast_bite_s`, placeholder 1.5 s): the avatar feels full later: the full point moves from 6 bites towards 8 (more kcal before "I'm full!"). The avatar says "Slow down!".
  - **Balanced:** as now (full from 6 bites).
  - **Too slow** (more than `slow_bite_s`, placeholder 6 s): no health effect; the fork waits and the meal simply takes its time (the meal still lasts its 0.5 avatar hours, so very slow eating ends with fewer bites eaten).
  - The fork still swings, so taps still need timing; the fork no longer speeds up with each bite (it would push the player to eat fast).
- **Model change (small, needs the user's yes):** the full point depends on the pace. Without a player nothing changes (scenario tests the same).
- Tasks: 1) pace in `Minigame` and the full point in `Hunger.eat()`; 2) the pace bar and messages; 3) tests, web build, documents.

## Milestone 22 — The canteen (D)

**Needs the team before it starts** (questions 4 to 7). Proposal so the team has something to react to:

- **Where:** Eat opens the canteen, seen from above (like the football field, so the joystick and drawing code are reused). The avatar walks to the counter; at the counter the player picks foods by category: sides, meat, fish, fruit (and vegetables? see question 5), plus fast food (burger, fries, soft drink). Skip meal stays.
- **The plate:** up to 4 foods, at most 2 per category (placeholders). Each food has fixed portion kcal, a satiety and a "healthy" value from 0 to 1 in `data/foods.json` (owner: Pessoa 1). Portions stay fixed (open decision "fixed portions").
- **Into the model:** the plate's kcal = the sum of its foods; its "healthy" x = the kcal-weighted average of its foods. In v1 Step 7 a meal is x = 1 (healthy) or 0 (fast food); a plate with x between 0 and 1 moves diet quality, craving and habituation part of the way, the same way part of a meal already does. **This is a model change: the team decides** (question 6). A scientific guide for a good plate: the Portuguese Food Wheel ("Roda dos Alimentos", DGS) or the Healthy Eating Plate (half vegetables and fruit, a quarter grains, a quarter protein).
- **Then:** the plate is eaten with the meal minigame (with C's pace, if built).
- **Scenario tests:** the simulated player needs a "healthy plate" and a "fast-food plate" equal to today's two meals, so v1's results stay comparable.
- Tasks (to refine with the team's answers): 1) food data and the plate's model; 2) the canteen room and walking; 3) the counter and the plate; 4) connecting to the meal minigame and saves; 5) tests, scenario comparison, web build, documents.

## Questions (proposed default in bold)

1. Order and deadline: **19 street, 20 squats or push-ups, 21 eating pace, 22 canteen; build 19 to 21 before 30 Nov and start 22 when the team's food list is ready.** Or should the canteen go first?
2. Really doing the exercise: **on trust for now; phone motion sensors maybe later; never the camera.**
3. Eating too fast: **the avatar feels full later (more kcal); too slow has no health effect.** Is a model change here OK?
4. (Team) The canteen's foods per category, each with its portion kcal and how healthy it is.
5. (Team) Categories: sides, meat, fish, fruit (from V3). **Add vegetables and drinks?**
6. (Team) A mixed plate moves diet quality part of the way (x between 0 and 1): **yes**, as a placeholder?
7. (Team) Canteen view: **from above, reusing the football field's joystick.**
8. (Team) Art: a back view of the avatar for the street, and squat and push-up poses. **Placeholders until then.**
9. How to work: **each task tested and committed; no push; you play each milestone before the next.**

## Out of scope

The screens minigame (decision 54, still open), food tastes and preferences, commitment goals, eating speed as its own health effect beyond the full point, and the web conversion (stopped).
