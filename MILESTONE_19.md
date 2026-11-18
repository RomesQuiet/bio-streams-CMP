# Milestones 19 to 21 — The team's new minigame ideas (plan)

**Status: Milestones 19 (cardio on a street) and 20 (squats, push-ups or sit-ups) are built (17 November 2026), not pushed; the user played 19 once and asked for changes (done). Milestone 21 (the canteen) is a plan.** Claude's proposals, to be confirmed by the user (and the team where it says so).

**User's answers (17 Nov 2026):** (1) nothing that records or films the player: no camera and no phone sensors, removed; (2) sit-ups too, not only squats and push-ups; (3) the eating pace idea is dropped. Read `CLAUDE.md` and `documentation/handoff.md` first.

Source: the team's "Ideias Extras v2" (16 Nov 2026) and the Portuguese "Conceito do Jogo V3" (sections 4, 5, 8 and 9). Both concept documents were updated on 17 Nov 2026 to say what is built and what is new.

## The four ideas, and how big each one is

| # | Idea | What the documents say | Size | Changes the health model? |
|---|---|---|---|---|
| A | **Cardio on a street** | The avatar is seen from behind, running down a street with trees; the avatar stays in place and the scenery comes closer and repeats. | Small | No: only what the screen shows. |
| B | **Squats, push-ups or sit-ups** | The player chooses one and does the chosen exercise for real, on trust. | Medium | No: all three count as strength. |
| C | **The canteen** | Good food or Fast food, then build a plate of up to 4 foods of that kind (user, 18 Nov 2026). | Medium | No: a good plate is the healthy meal, a fast-food plate the fast-food meal. The team gives the examples. |

**Proposed order (smallest and safest first):** Milestone 19 = A, Milestone 20 = B, Milestone 21 = C. A and B do not wait for the team; C needs the team's food list first, so asking them now lets it start on time. The Bio-Streams deadline is 30 November 2026 ("Dúvidas de implementação"); with that date, A and B fit, and C may not: see question 1.

The rules of the earlier minigames still hold for all four: a session only exists with a player, so the scenario tests and every health number stay as they are unless a decision below changes the model on purpose. All new numbers are placeholders in `data/config.json`.

## Milestone 19 — Cardio on a street (A)

- **Proposal:** during cardio the stage shows a street seen from behind the avatar: road, pavement and trees on both sides, drawn in perspective (placeholder shapes, like the other places). Each stride moves the scenery towards the player by one step, so the street "runs" as fast as the player taps; walking (empty Breath) moves it slower; waiting stops it. The minigame, its score and its numbers do not change.
- **The avatar from behind:** the team's sprite sheets only show the front. Until the team draws a back view (one picture per body, as the front sheets), the placeholder is the front picture in a dark silhouette (or the egg seen from behind). **Question for the team:** can you add a back view to the sheets (5 bodies; the face does not show)?
- **Day and night:** the sky follows the clock, as in the room's windows.
- Tasks: 1) the street place (`scenery.gd` gets "street", moved by the strides); 2) the back-view placeholder and the place in `activities.json`; 3) tests, web build, documents. About a day of work.
- **Built (17 Nov 2026):** cardio's place is `"street"` (`data/activities.json`). `scripts/ui/scenery.gd` draws grass, pavements, the road and trees in perspective from a horizon 330 pixels above the ground line; the grey ground under the avatar is the road. The street moves all the time while the player taps, at one step (1.4 units, 0.7 walking) per gap between taps, so tapping faster makes it faster; it stops only when a tap comes too late (after the Beat bar's green zone) or the avatar waits, and the next tap starts it again (user, 17 Nov 2026; at first each tap moved it one step and then it stood still); at night it is up to 55% darker. The avatar is seen from behind as a dark silhouette of its picture (`scripts/avatar/silhouette.gdshader`, placeholder until the team draws a back view); the egg loses its face. Strength keeps the plain outside. All of these are display values in the script, not game numbers. **Shortest gap between taps (user, 17 Nov 2026: "too long"):** `minigame.min_gap_share` 0.5 → 0.25 (placeholder): a tap counts as a stride from a quarter of the beat on (about 0.25 s instead of 0.5 s). Faster taps also empty the Breath bar faster, as before. **Checked:** `tests/scenery_test.gd` (the street, the back view, it keeps moving between taps, faster taps make it faster, walking is slower, a late tap stops it, the next tap starts it, the front view after cardio), all 32 other tests, renders by day and at night in a Godot window, and the web export. **Not checked:** a person playing it, a real phone.

## Milestone 20 — Squats, push-ups or sit-ups (B)

- **Choice:** Exercise shows Cardio, **Squats**, **Push-ups** and **Sit-ups** (instead of "Muscle strength"). All three are the strength minigame (Down, then Up = one repetition) and all three train strength in the model, as now. They are body-weight exercises that the AAP 2020 report (already the source of Milestone 13) accepts for children and teenagers.
- **Doing the exercise for real, on trust (user, 17 Nov 2026):** the screen asks the player to do each repetition for real, with the avatar, and to press Down and Up as they go down and up. The press rhythm (1 second each, technique score) already matches a controlled real repetition. Nothing records or films the player: no camera, no phone sensors.
- **The three differ:** push-ups are harder for the upper body. Proposal: placeholder factors that set the repetitions of each exercise for the same strength (`minigame.strength.reps_share`: squats 1.0, sit-ups 1.0, push-ups 0.7). Each has its own animation and placeholder picture (the art has no squat, push-up or sit-up pose: the team could draw them).
- Tasks: 1) three options in `activities.json` (same training type), the factors; 2) the on-trust screen text and the pictures; 3) tests (the scenario test stays the same), web build, documents.
- **Built (17 Nov 2026):** Exercise shows Cardio, Squats, Push-ups and Sit-ups. Squats keep the option id `strength` (so saves, the scenario tests and every health number are unchanged); `push_ups` and `sit_ups` are new options in `data/activities.json` with the same minigame, METy 5.0 and intensity, and are in `train.strength_types`, `mood.fun.exercise_types` and `log.strength_types`, so all three train strength and share the recovery and the 36-hour gap. Each option has a `reps_share` (placeholder): squats 1.0, sit-ups 1.0, push-ups 0.7, which multiplies the repetitions of a set (`StrengthLoad.reps_per_set()`, at least 1): at strength 0.5, 9 squats or sit-ups and 6 push-ups. Before the first press the panel says "Do each one for real!" ("Faz cada um a sério!", Claude's draft). No pose pictures: the team's art does not move (user, 6 Nov 2026), so all three look the same until the team draws poses. **Checked:** `tests/activities_test.gd` (the four options, all three train strength, fewer push-ups), `tests/minigame_test.gd` (the on-trust text), `tests/minutes_slider_test.gd`, all 32 tests, a render in both languages, the web export. **Not checked:** a person playing it, a real phone.

## Milestone 21 — The canteen (C)

**Its own milestone: `MILESTONE_21.md`.** Built (third version, 18 Nov 2026): Good food or Fast food, then build a plate of up to 4 foods of that kind; no change to the health model.

## Questions (proposed default in bold)

1. Order: **19 street, 20 squats, push-ups or sit-ups (both built), then 21 the canteen (good food or fast food, then build a plate).**
2. (Team) The canteen's examples: good foods and fast foods, with their names in Portuguese and English.
3. (Team) Art: a back view of the avatar for the street, squat, push-up and sit-up poses, and food pictures. **Placeholders until then.**
4. How to work: **each task tested and committed; no push; you play each milestone before the next.**

## Out of scope

The screens minigame (decision 54, still open), food tastes and preferences, commitment goals, the eating pace (dropped by the user, 17 Nov 2026), anything that records or films the player (camera, phone sensors), and the web conversion (stopped).
