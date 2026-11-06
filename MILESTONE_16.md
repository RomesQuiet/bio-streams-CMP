# Milestone 16 — The avatar's requests

**Status: plan (6 November 2026), not started.** Decision 56 said "the avatar will ask for things throughout the day"; the user chose to build it after the minigames.

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
