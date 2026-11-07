# Milestone 16 — The avatar's requests

**Status: built and committed (6 November 2026), not pushed.** The user plays it, then pushes. Decision 56 said "the avatar will ask for things throughout the day"; the user chose to build it after the minigames, and approved the list below ("Yes, start").

**Built:** `scripts/health/requests.gd` (the request to show and the reactions), the config group `requests` (placeholders, display only), `GameState.wish_refused` (emitted by `happiness.gd` when four hours without screens count as a refused wish; nothing else listens), `scripts/ui/request_icon.gd` (the picture in the bubble), and `tests/requests_test.gd`. Choices Claude made while building, to confirm:

- When the avatar wants both, screens come before football (the screens wish has a cost soon).
- A healthy meal while the craving is low also gets a reaction, "Just what I wanted!", because the model gives it happiness then.
- A meal's reaction appears over the fork, as the meal messages do. "You never let me watch anything." is not shown over the football field or the fork.
- "Do I have to?" or "Let's go!" comes at the first tap or press, when the model takes the happiness cost of starting.

**Checked (6 Nov 2026):** all 28 tests pass, and the scenario test prints exactly the same as before Milestone 16. `tests/measures_test.gd` now ends the short message left by a meal's reaction before it checks the failure message: the test plays days without real seconds passing, so a 3-second message never ended there. In the web build: "I'm tired." with the bed picture, "Do I have to?" at the first cardio tap, "Yes, fast food!" over the fork, and no console errors. All six pictures were drawn in a Godot window. Taps were sent by a script. **Not checked:** a real person playing it, a real phone, and the screens and football requests during play (`tests/requests_test.gd` covers them).

## Avatar art (added 6 Nov 2026, user)

The user asked to add the team's four sprite sheets to the game before playing the requests. Answers (user, 6 Nov 2026): made by the team with an AI image tool, CC BY 4.0; muscular with fat shows the overweight or obese body; the happy face from happiness 0.6 (placeholder); every sheet the same size on screen.

- The originals moved to `assets/art/avatar/source/` (ignored by Godot). `tools/cut_avatar_sheets.py` finds each figure by its transparency, splits each column at its emptiest line near each fifth (some figures touch the one above), scales each sheet by one factor and puts the feet on the bottom of 220 x 300 cells.
- `data/avatar_art.json`: the sheets, the order of bodies and faces, and the mouth height of each sheet (measured on the happy faces), where the meal fork aims.
- New avatar states: `obese` (z above +2, WHO cut-off, from source) and `happy` (`avatar_states.happy_from` 0.6, placeholder).
- Lossy WebP import (quality 0.85) keeps the web game small.
- **Second round (user, 6 Nov 2026): "1.5x its size and don't have the animations of the egg".** The avatar is now 330 x 450 (the sheets are cut again at that size, so the drawing is not stretched), and the speech bubble moved up by 150. The drawing no longer hops, squashes or breathes in activities and minigames; it only shows the asleep face while sleeping. The egg (without art) still moves. `tests/minigame_test.gd` now checks that the art stays still where it checked the hop and the squat. The published `index.pck` is now about 3.3 MB (it was 0.3 MB before the art).
- **Third round (user, 7 Nov 2026): "replace the current sprites with the newer ones upscaled 4x".** The team upscaled the cut grids with an AI tool (6008 x 8192, white background, about 94 MB in all; committed in `assets/art/avatar/source/upscaled/`, user: "commit everything"). The tool turns their white back into transparency, guided by the grid's own transparency (white inside a figure stays), and saves 100 separate pictures of 660 x 900 (twice the drawn size), because one 8192-pixel image is more than many phones can show. Mipmaps keep them smooth when scaled down. A first try drew white boxes: the picture was loaded inside `_draw()`; it is now loaded when the states change. The published `index.pck` is now about 7.2 MB.
- **Fourth round (user, 7 Nov 2026): a small fix, the places and the buttons.** "When I put him eating and then sleeping, the box and the fork remained, and sometimes the character moves a little just by changing sprite. Also make the ground grey, when he is eating put a wall and some windows with the sky behind (day/night), no building when doing exercise, and a bed behind it and everything grey when it is sleeping. Make the buttons rounded with borders, white in the day (black letters and border) and black at night (white letters and border)."
  - **The fork:** `main.gd` hid the fork only while a minigame ran, so after a meal it stayed. It is now hidden whenever no meal is running.
  - **The avatar moving:** the team's figures do not stand in the same place in their cells (the feet were up to 25 screen pixels apart). The tool now moves each picture sideways so the middle of its feet (the lowest tenth of the figure) is the middle of the picture; `tests/avatar_art_test.gd` checks it for all 100 pictures.
  - **The places:** `"scenery"` in `data/activities.json` and `scripts/ui/scenery.gd` (placeholder shapes): meals in a room with two windows showing the sky (with stars at night), cardio and strength outside (sky and ground only), sleep in a grey room with a grey bed behind the avatar. Screens keep their see-through colour and football its field (the user did not mention them). The ground is grey down to the bottom of the screen. Each place fades in and out like the old colours.
  - **The buttons:** rounded (radius 18) with a 3-pixel border. Day: white, black text, border and icons (`scenes/ui/main_theme.tres`, so the creation screen too). Night: black, white text, border and icons (`scenes/ui/night_theme.tres`, on the main screen). Night is when the sky is more night than day (`Clock.daylight_amount()` below 0.5, the `daylight` hours in config), so the buttons change with the sky, also during a sleep.
  - **Checked:** `tests/scenery_test.gd` (the place for each activity, no fork after a meal or during the sleep after it, the day and night buttons and the night sky in the windows) and every other test; the main screen rendered in a Godot window at noon and at 23:00 for idle, a meal, sleep and cardio. **Not checked:** a real phone, and a person playing it.
- **Checked:** `tests/avatar_art_test.gd` (each sheet, the cell for every state, the mouth, the egg without a sheet, no animation); in the web build at 1.5x, the tired boy, standing still while running cardio, and the meal fork at his mouth, with no console errors. **Not checked:** the other sheets and faces in play (the test covers them), a real phone.

Read `CLAUDE.md` and `documentation/handoff.md` first.

## Decisions (user, 6 Nov 2026)

| # | Question | Decision |
|---|---|---|
| 57 | What does a request change? | **Nothing new: it only shows what the health model already does.** No new effect and no health number changes, so the scenario tests stay exactly as they are. |
| 58 | How does the player answer? | **By acting.** The bubble shows the wish. Doing the activity is yes; ignoring it is no, and the model's existing effect of a refused wish happens as before. |
| 59 | Which wishes? | **Every wish related to our activities, and real-life wishes:** fast food, screens, not wanting to exercise, playing football, and more of the same kind. |
| 60 | Hungry and tired | **The same style as the other requests.** |

The concept document (section 4, "Wishes") says: the avatar wants fast food, wants screens, does not want to exercise and gets sleepy; refusing a wish lowers its happiness. The model already does all of it (v1 Step 10), but the player cannot see it.

## The requests (Claude's proposal, to confirm)

Each request comes from a value the model already has. The thresholds only decide **when the bubble shows it**; they change nothing else. They go in a new config group `requests`, all placeholders.

| Request | When it shows | What already happens in the model | Ends when |
|---|---|---|---|
| "I want fast food!" | Hungry and craving C at least 0.5 | Fast food: +0.06 C (1 − A) happiness; a healthy meal: −0.06 C | It eats or skips |
| "I'd like a healthy meal." | Hungry and craving C at most 0.15 | A healthy meal gives happiness when C is low (+0.01 − 0.06 C) | It eats or skips |
| "I'm hungry!" | Hungry, craving in between | −0.05 happiness per hour above 1.2 meals | It eats or skips |
| "I'm tired. Sleep is recommended." | Tired (as now) | Sleep debt, tiredness, kept awake | It sleeps |
| "Can I watch something?" | 3 awake hours without screens | At 4 hours: −0.02 happiness (a wish refused), and again every 4 hours | It watches screens |
| "Can I play football with my friends?" | Fun below 0.25, not tired, not hungry | Football is the biggest part of Fun (baseline) and gives +0.10 happiness per hour | It plays football |

**Reactions** (a short message, like "Level up!"), each showing an effect that already exists:

- Starting cardio or strength with fitness below 0.5: "Do I have to?"; above: "Let's go!" (−0.03 × (1 − fitness)).
- Fast food while the craving is high: "Yes, fast food!"; a healthy meal while it is high: "Not this again..."
- Four hours without screens: "You never let me watch anything."

**Only one request at a time**, in this order: failure, tired, hungry (one of the three), screens or football, sad, hello. Each request has a small placeholder picture in the bubble (a fork, a bed, a screen, a ball). The avatar asks for what it wants, not for what is healthy: the game does not give advice (concept, "Learning approach").

## The tasks

Each task is tested and committed on its own. Nothing is pushed.

1. **Request model:** `scripts/health/requests.gd`, which reads GameState and returns the request to show. Thresholds go in config `requests`. Tests: each request appears in its state, and the scenario test output is the same as before.
2. **The bubble:** the picture and the text, the order, the reactions, both languages, and the speech kept hidden during football and meals.
3. **Review and finish:** all tests, the scenario comparison, the web build, the documents. The user plays it.

## Out of scope

New happiness effects, rewards or XP for answering, food tastes and menus, and the screens minigame (decision 54).
