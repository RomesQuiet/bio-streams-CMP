# Milestone 22 — XP: what is missing

**Status: closed, 18 November 2026. Nothing to build: the user decided to keep XP as it is.**

## Decisions (user, 18 Nov 2026: "1 abort, 2 abort, 3 true, 4 number")

| # | Missing part | Decision |
|---|---|---|
| 68 | 1. Other ways to lose XP | **Dropped.** XP changes only with health, as now. |
| 69 | 2. Commitment goals | **Dropped.** |
| 70 | 3. The XP values and the level size | **Kept as they are** (v1 values; 100 XP for every level). They stay placeholders the team may tune. |
| 71 | 4. What a level means | **Only a number**, a record of experience; nothing is unlocked. |

The concept documents (English and V3) were updated: no other ways to lose XP, commitment goals dropped. The proposals below are kept as a record only.

Claude's check of the code and the documents, with the proposals that were asked about: Read `CLAUDE.md` and `documentation/handoff.md` first.

## What already works (built)

- **Earning and losing XP (v1 Step 12, Milestone 10, `scripts/health/progress.gd`, config group `progress`, all placeholders):**
  - every change of the displayed health gives or takes 100 XP per point (`per_health_point`); the health bar moves once a day, when a sleep ends;
  - every avatar hour with the health bar at 4.5 or more gives 10 XP (`gain_per_avatar_hour`), times 1 + hours at that level without a break / 48 (`bonus_hours`), at most times 3 (`max_multiplier`);
  - XP has no upper limit and never goes below 0.
- **Levels:** level = XP / 100 (`xp.per_level`), rounded down, so losing XP can lower the level. "Level up!" shows in the speech bubble.
- **On screen:** the XP bar ("XP 37 / 100"), the level box ("Lv 3"), every XP change rising under the bar ("+37 XP" in green, "−20 XP" in red; Milestone 16); the level in the main menu and on the failure screen.
- **Checked:** `tests/health_xp_test.gd`, `tests/xp_change_test.gd`, and the scenario test's rule "short sleep does not pay": guideline play gives about 183 XP per real hour (v1: 225; the slow bar, decision 1), 6 hours of sleep about 2.3.

## What is missing (from the documents)

| # | Missing | Where it is said |
|---|---|---|
| 1 | **Other ways to lose XP**, "so the game is more playable and not only a series of decisions" | Concept (English and V3), "XP": "will be added (not decided yet)". Concept section 9: "the other ways to lose XP". |
| 2 | **Commitment goals:** before playing, the player commits to a goal; completing it gives much more XP, for example a whole level. Goals must reward healthy habits and gradual change (for example the recommended sleep for a week), not fast weight loss; the team's "lose 10 kg in a month" was only an example. Open: which goals, how a goal's time is counted, what happens if it is not reached. | Concept section 8, "Commitment goals" (from "Ideias Extras v2"). |
| 3 | **The XP values** (100 per health point, 10 per hour, 4.5, 48 h, × 3) and **the level size** (100) are placeholders. | v1 "Open decisions" 9; `CLAUDE.md`, "Not decided yet": "XP values and level size", "XP per day". |
| 4 | **What a level means** for the player: today a level only shows a number and "Level up!". Nothing is unlocked. | Not in the documents (concept: "XP shows how experienced the player is and for how long they have been playing"). |

## Proposals (Claude's, to confirm)

**A. Other ways to lose XP (missing 1).** Only for things the health model already counts as harmful, so no health number changes and the scenario tests stay the same. Each is a placeholder in config `progress`:

| Proposal | When | XP |
|---|---|---|
| A1. Overdoing exercise | Minutes beyond the daily capacity (the model already builds overreaching O) | −5 per avatar hour beyond capacity |
| A2. No sleep at all | The awake period runs out without sleep (the 0-hour rule) | −50 once |
| A3. Giving up a minigame | The player stops tapping and the session ends by itself after 20 s ("I gave up") | −10 once |
| A4. A good minigame | (a gain, to make it more playable) at the end of a session, by its score | + up to 20 per session |

**B. Commitment goals (missing 2).** A "Goals" button (in the settings or the menu) with a few goals based on the guidelines the game already uses. The player picks one at a time; a goal is counted in avatar days:

| Goal | Done when | Source of the number |
|---|---|---|
| B1. Sleep well for a week | 7 avatar nights in a row in the recommended range (child 9 to 12 h, teenager 8 to 10 h) | AASM, already in config `sleep` |
| B2. Active every day | 60 minutes of moderate-to-vigorous activity on 7 avatar days in a row | WHO 2020, already `train.capacity_base_min` |
| B3. Healthy meals | Only good-food plates for 3 avatar days | the canteen (Milestone 21) |
| B4. Screens in limit | At most 2 hours of screens a day for 7 avatar days | already `mood.fun.screen_max_min` |

Reward: one whole level (`xp.per_level`) when done. **Not reached:** the goal simply ends, no XP is lost (proposed: the concept asks for rewards, not punishment, and it keeps the game kind). No weight goals (the concept's scientific check).

**C. Values (missing 3).** Keep the v1 values; they pass the "short sleep does not pay" rule. Proposal: the level size stays 100 for every level (simple; good play gives a level about every 30 real minutes). The team can tune later.

**D. What a level means (missing 4).** Proposal: nothing is unlocked (the game is about health, not rewards); the level stays a record of experience, shown in the menu and on the failure screen as today.

## Questions (proposed default in bold)

1. Other ways to lose XP: **A1, A2 and A3**, and the minigame gain **A4**? Or some of them, or other ideas?
2. Commitment goals: **B1 to B4**, reward one level, **no loss when a goal is not reached**?
3. Where the goals are chosen: **a Goals button in the settings panel** (or in the main menu, or at avatar creation)?
4. Level size: **100 for every level**, or levels that get bigger?
5. How to work: **each task tested and committed; no push; you play it at the end.**

## Tasks (after the answers)

1. The new XP rules (A) in `scripts/health/progress.gd` and config `progress`; tests; the scenario test output unchanged except the XP figures, which are reported.
2. The goals model (B): a goal's progress per avatar day from the action log (`Habits`), the reward, saving.
3. The goals screen and the goal's progress on screen, both languages.
4. Review and finish: all tests, the web build, the documents. The user plays it.

## Out of scope

Unlocking things with levels, weight goals, changes to the health model, the screens minigame (decision 54).
