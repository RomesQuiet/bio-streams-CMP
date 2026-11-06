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
- Lossy WebP import (quality 0.85): the sheets add about 1.75 MB to the web game instead of 4.7 MB. The published `index.pck` is now about 2.1 MB.
- **Checked:** `tests/avatar_art_test.gd` (each sheet, the cell for every state, the mouth, the egg without a sheet); in the web build, the tired boy and the meal fork at his mouth. **Not checked:** the other sheets and faces in play (the test covers them), a real phone.

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
