# Milestones 10 and 10.5 — scenario results and the causes of the differences from v1 (for the team)

Date: 27 October 2026 (Milestone 10.5; the first version, from Milestone 10 Task 10, is in the git history). The team's review of the first version is `documentation/milestone10_review.md`; this version answers it. Two tests produce the numbers:

- `tests/calibration_test.gd` (about 2.5 minutes): the game as it is, with every rule of the v1 "Bases fundamental check". **All rules pass.**
- `tests/parity_test.gd` (about 5 minutes): the same scenarios as close to the v1 simulation as the game allows, then one thing changed at a time. It prints numbers; it has no pass or fail.

```
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s res://tests/calibration_test.gd
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s res://tests/parity_test.gd
```

**No value was changed to make a result fit.** All numbers are the v1 placeholders in `data/config.json` plus the user's decisions. Every scenario is a boy of 10 on Normal unless it says otherwise, and day-21 values are taken on waking after the 21st night.

## The simulated player (exact rule)

Nothing is random: every run gives the same numbers.

- **Scenario test:** every 0.5 avatar hours (30 avatar minutes, about 43 real seconds) the player looks whether the avatar says "I'm hungry!" and, if so, eats a whole meal at once (healthy or fast food, by the scenario's food rule; the severe diet skips 2 hungry moments of every 3). Then it starts the activities planned for that time. It cannot look during an activity (in the game the buttons are locked), so a meal waits until the activity ends, and a meal can push the next planned activity back by half an hour.
- **Parity run:** the same, but it looks every 5-minute step, a meal takes one step instead of half an hour (v1 eats at once), the health bar follows the target health at every step (v1 has no slow bar), Very hard starts with happiness 0.15 (v1), and the 36-hour strength gap is off (v1 does not have it).

## The six differences: what causes them

| # | Difference (first version) | Measured cause | For the team |
|---|---|---|---|
| 1 | The severe diet loses weight faster (20.7 kg, z −5.53; v1 24.0 kg, z −3.85) | **The scenario, not the model.** The avatar says "I'm hungry!" at most every 2 hours, and the player cannot answer during the 1-hour screens block, so one hungry moment a day comes later and the last one falls after the end of the day: 6 moments a day instead of 7, so **2.00 meals and 981 kcal a day instead of v1's 2.33 and 1,145**. Without the screens hour the game eats **exactly 2.33 meals and 1,145 kcal a day** (23.4 kg, z −4.12 at day 21; most of the remaining 0.6 kg is that the avatar then sits idle for that hour, which spends more than screens). The player's wait and the meal length change nothing (2.00 meals in every case). | Nothing to change in the model. The danger state (Milestone 10.5) now makes the severe diet fail on day 16, at z −4.00. |
| 2 | Happiness about 0.1 lower in imperfect plans | **Mostly plan details that v1 does not describe** (decision 12). (a) If the guideline activity is 40 min of cardio + 30 min of football instead of 70 min of cardio, happiness moves to v1: guidelines 0.95 → 0.99 (v1 1.00), 6 h sleep 0.75 → 0.80 (0.83), sport and sleep with fast food 0.67 → 0.72 (0.75); football is fun (+0.10 per hour and the fun part of the baseline). (b) If the no-sport plans have 2 h of screens instead of 1 h, happiness is **exactly v1's**: 0.73 → 0.83 (v1 0.83) and 0.61 → 0.70 (v1 0.70). (c) 4 h of cardio: the half-hour meals (decision 2) cost 0.10 (0.78 → 0.68); what is left (0.78 against 0.85) is the hunger penalty: even eating at once the avatar is hungry (above 1.2 meals) 28% of its awake time, because portions are fixed and meals need 2 hours between them (v1 open decision 7). The player's wait changes happiness by 0.01 at most, as the review found. | Confirm v1's plans (football in the guideline activity? 2 h of screens without sport?). Decide whether a meal should take half an hour (decision 2). |
| 3 | Strength twice a day gives more | Confirmed by the review: v1's plan has 40 min of cardio, strength at 9 and 12 hours after waking, 1 h of screens and no football. The scenario test now plays that plan: strength 0.36, fitness 0.70, health 4.07 (v1 0.34, 0.66, 3.97). | Nothing. |
| 4 | Guideline strength 0.61 against v1's 0.70 | **The training window.** Effective minutes are summed over the last 24 hours (`train.average_window_h`), so strength trained 3 days a week rises after each session and falls on the days between: **0.60 to 0.69 from day 14 to day 21**, and day 21 comes after two rest days (0.61). Session length (30 or 60 min), doing strength before the cardio (daily capacity) and the too-soon rule change nothing: 0.61 in every case, with no session too soon. With the minutes averaged over a week (168 h) strength is steady and ends at **0.76**; health 4.75 → 4.81. | Choose the window: 24 h (now), a week, or something between. A 45-minute option would not raise strength. |
| 5 | XP per real hour 169 against 225 | **Decision 1 only:** with the bar following the target at every step the game gives 226 XP per real hour (v1 225); with the slow bar, 183. Failure now reads the target health (decision 10), so the slow bar no longer delays it. | Nothing (accepted). |
| 6 | Very hard ends lower | **Compared with the wrong v1 row.** The test plays the gradual switch: 4.26 against v1's gradual 4.28. With decision 7 off (happiness 0.15, as v1): gradual 4.32 (v1 4.28), abrupt 4.37 (v1 4.45). The starting happiness does not change the day-21 health. The lowest happiness is lower than v1's with 0.15 (0.07 gradual and 0.02 abrupt, v1 0.15 and 0.07); with decision 7 (0.30) it is 0.18 and 0.12 (review 0.13), above the failure line. | Nothing (decision 7 does its job). |

**Other findings**

- **Eating time and weight.** A meal takes half an hour (decision 2) at METy 1.5 (a placeholder added in Milestone 10; v1 has no eating time, and its idle 1.7 includes eating). That spends about 20 kcal a day less than v1, which k = 10 turns into about **+0.4 kg in 21 days** (guidelines 33.3 → 33.7 kg, z +0.04 → +0.15). The team can set the eating METy to 1.7 or keep 1.5.
- **Strength every day** (review): 1 h of strength every day gives strength 0.80 and health 4.87 without the gap (review's v1 model: 0.79 and 4.85) and **0.45 and 4.48 with the 36-hour gap** (review: 0.44 and 4.42). The scenario test plays it: 0.45, health 4.40, below the guidelines (4.74).
- **Weight and body size match v1 closely** in the parity run (guidelines 33.3 kg against 33.2, couch 48.5 against 48.6, gradual switch 34.3 against 34.3, 6 h sleep 35.7 against 35.7), so energy, hunger and growth behave as in v1.

## Game results at day 21 (`tests/calibration_test.gd`)

Ours (v1). Health is the target health; the bar is within 0.05 of it. \* = starts with a fast-food craving of 0.9. "-" = v1 does not give it.

| Scenario | kg | z | Fitness | Strength | Physical | Sleep | Happiness | Health |
|---|---|---|---|---|---|---|---|---|
| Guidelines (70 min a day, 30 min strength 3 days a week, 1 h screens, 10.5 h sleep) | 33.8 (33.2) | +0.17 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.94 (1.00) | 4.74 (4.80) |
| Couch | 48.1 (48.6) | +2.51 (+2.56) | 0.10 (0.10) | 0.10 (0.10) | 0.07 (0.07) | 0.84 (0.84) | 0.52 (0.53) | 2.62 (2.60) |
| Fast food with 3 h cardio | 36.0 (35.6) | +0.70 (+0.60) | 0.87 (0.91) | 0.50 (0.57) | 0.31 (0.32) | 1.00 (1.00) | 0.72 (0.74) | 3.57 (3.56) |
| Severe diet (1 meal in 3) | 20.7 (24.0) | −5.53 (−3.85) | 0.10 (0.10) | 0.10 (0.10) | 0.02 (0.05) | 1.00 (1.00) | 0.44 (0.53) | 2.47 (2.66) |
| Guidelines, 6 h sleep, extra cardio | 32.4 (32.3) | −0.21 (−0.27) | 0.88 (0.87) | 0.62 (0.70) | 0.83 (0.83) | 0.45 (0.45) | 0.77 (0.85) | 3.69 (3.79) |
| Guideline activity, 6 h sleep | 35.6 (35.7) | +0.62 (+0.63) | 0.82 (0.80) | 0.57 (0.67) | 0.85 (0.87) | 0.45 (0.45) | 0.75 (0.83) | 3.69 (3.81) |
| Gradual switch \* | 34.1 (34.3) | +0.27 (+0.30) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.90 (1.00) | 4.68 (4.80) |
| Abrupt switch \* | 33.8 (33.2) | +0.17 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.94 (1.00) | 4.74 (4.80) |
| Sport and sleep, fast food only \* | 42.1 (42.4) | +1.80 (+1.83) | 0.84 (0.83) | 0.61 (0.70) | 0.27 (0.27) | 1.00 (1.00) | 0.62 (0.75) | 3.36 (3.48) |
| 4 h cardio | 27.6 (28.2) | −1.98 (−1.73) | 0.86 (0.86) | 0.49 (0.50) | 0.65 (0.63) | 1.00 (1.00) | 0.68 (0.85) | 4.08 (4.23) |
| Strength twice a day (v1's plan) | 31.3 (31.1) | −0.57 (−0.63) | 0.70 (0.66) | 0.36 (0.34) | 0.54 (0.52) | 1.00 (1.00) | 0.80 (0.78) | 4.07 (3.97) |
| Guidelines, 1 h strength every day (review) | 31.6 (-) | −0.47 (-) | 0.83 (-) | 0.45 (0.44) | 0.71 (-) | 1.00 (-) | 0.85 (-) | 4.40 (4.42) |
| Healthy food, no sport | 39.1 (39.4) | +1.32 (+1.37) | 0.10 (0.10) | 0.10 (0.10) | 0.38 (0.37) | 1.00 (1.00) | 0.72 (0.83) | 3.70 (3.77) |
| Healthy food, no sport, 7 h sleep | 39.8 (40.3) | +1.44 (+1.51) | 0.10 (0.10) | 0.10 (0.10) | 0.36 (0.35) | 0.66 (0.66) | 0.61 (0.70) | 3.13 (3.22) |

**Day 60** (v1 gives z only): guidelines 35.7 kg, z −0.41 (v1 −0.4); couch 65.2 kg, z +3.15 (+3.1); sport and sleep with fast food z +2.13 (+2.0); healthy food without sport z +1.34 (+1.4); severe diet 10.3 kg, z −11.1 (failed on day 16; the model keeps running after failure, which has no effect yet).

**Failure, danger state and the player's counts** (all days played). Only the severe diet reaches the danger state (day 13.1) and failure (day 16.0, severe thinness, z −4.00); its lowest happiness is 0.07, but it stays below the 0.10 line for at most 2.2 hours in a row in all 60 days, so the 12-hour happiness timer never fires (the review's question). No scenario ever goes below the line except the severe diet, and no other scenario fails. Hungry share of awake time (above 1.2 meals): guidelines 30%, couch 13%, 4 h cardio 68%, severe diet 99%, the others 8% to 34%. Meals a day: 3.9 to 4.8 (severe diet 2.0 eaten and 4.0 skipped). Strength sessions too soon: strength twice a day 41 of 42, strength every day 20 of 21 (the 36-hour gap), all others 0.

**Bases fundamental check, all PASS:** exercise within norms raises health (2.91 → 4.74); too much or too often does less good (4 h cardio 4.08, strength twice 4.07, strength every day 4.40, guidelines 4.74); fast food makes the avatar fatter (couch z +2.51, sport and sleep with fast food +1.80); healthy food makes it slimmer (guidelines +0.17, gradual +0.27, from +1.20); fast food with a lot of exercise is thinner but not healthy (z +0.70, Physical 0.31); the severe diet is thinner, hungry and sad (z −5.53, Physical 0.02, hungry 99%, lowest happiness 0.07); short sleep slows fitness (0.75 against 0.79 at day 7), adds 9% food, Sleep 0.45, health 3.69, tired all the time; refusing wishes lowers happiness (lowest: abrupt 0.36, gradual 0.43); healthy and happy together (4.74, happiness 0.94); short sleep does not pay (2.3 against 182.9 XP per real hour). **Danger state:** the severe diet reaches it and fails before z −5; no other scenario reaches it. **Variants** (girl of 10, boy and girl of 14) and **Very hard** (starts lowest at 1.49, recovers to 4.26, no failure, abrupt dips lower than gradual): all PASS.

## Parity run at day 21 (`tests/parity_test.gd`)

Ours (v1). The closer these rows are to v1, the more the remaining differences are about the model and not about how the scenarios are played.

| Scenario | kg | z | Fitness | Strength | Physical | Sleep | Happiness | Health |
|---|---|---|---|---|---|---|---|---|
| Guidelines | 33.3 (33.2) | +0.04 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.95 (1.00) | 4.75 (4.80) |
| Couch | 48.5 (48.6) | +2.55 (+2.56) | 0.10 (0.10) | 0.10 (0.10) | 0.07 (0.07) | 0.84 (0.84) | 0.53 (0.53) | 2.63 (2.60) |
| Fast food with 3 h cardio | 35.4 (35.6) | +0.58 (+0.60) | 0.87 (0.91) | 0.50 (0.57) | 0.31 (0.32) | 1.00 (1.00) | 0.72 (0.74) | 3.57 (3.56) |
| Severe diet | 20.4 (24.0) | −5.66 (−3.85) | 0.10 (0.10) | 0.10 (0.10) | 0.02 (0.05) | 1.00 (1.00) | 0.44 (0.53) | 2.47 (2.66) |
| Guidelines, 6 h sleep, extra cardio | 31.9 (32.3) | −0.36 (−0.27) | 0.88 (0.87) | 0.62 (0.70) | 0.83 (0.83) | 0.45 (0.45) | 0.77 (0.85) | 3.69 (3.79) |
| Guideline activity, 6 h sleep | 35.7 (35.7) | +0.65 (+0.63) | 0.82 (0.80) | 0.57 (0.67) | 0.85 (0.87) | 0.45 (0.45) | 0.75 (0.83) | 3.69 (3.81) |
| Gradual switch \* | 34.3 (34.3) | +0.31 (+0.30) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.95 (1.00) | 4.75 (4.80) |
| Abrupt switch \* | 33.3 (33.2) | +0.04 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.95 (1.00) | 4.75 (4.80) |
| Sport and sleep, fast food only \* | 41.6 (42.4) | +1.72 (+1.83) | 0.84 (0.83) | 0.61 (0.70) | 0.28 (0.27) | 1.00 (1.00) | 0.67 (0.75) | 3.44 (3.48) |
| 4 h cardio | 28.7 (28.2) | −1.50 (−1.73) | 0.86 (0.86) | 0.49 (0.50) | 0.65 (0.63) | 1.00 (1.00) | 0.78 (0.85) | 4.22 (4.23) |
| Strength twice a day (v1's plan) | 31.5 (31.1) | −0.48 (−0.63) | 0.70 (0.66) | 0.36 (0.34) | 0.54 (0.52) | 1.00 (1.00) | 0.82 (0.78) | 4.09 (3.97) |
| Strength every day, no gap | 31.7 (-) | −0.42 (-) | 0.85 (-) | 0.80 (0.79) | 0.91 (-) | 1.00 (-) | 0.99 (-) | 4.87 (4.85) |
| Healthy food, no sport | 38.6 (39.4) | +1.24 (+1.37) | 0.10 (0.10) | 0.10 (0.10) | 0.40 (0.37) | 1.00 (1.00) | 0.73 (0.83) | 3.74 (3.77) |
| Healthy food, no sport, 7 h sleep | 39.3 (40.3) | +1.36 (+1.51) | 0.10 (0.10) | 0.10 (0.10) | 0.37 (0.35) | 0.66 (0.66) | 0.61 (0.70) | 3.17 (3.22) |

(For strength every day without the gap, v1 is the review's model: 0.79 and 4.85.)

**One thing at a time** (from the parity rows):

| Change | What moves |
|---|---|
| The game's player (looks every 30 minutes, never during an activity) | Almost nothing: weight ±0.6 kg at most, happiness ≤ 0.01, health ≤ 0.02. |
| Decision 2 on (a meal takes half an hour) | 4 h cardio: happiness 0.78 → 0.68, health 4.22 → 4.08, 28.7 → 27.6 kg. Other rows: about +0.4 kg (eating at METy 1.5), happiness ≤ 0.01. |
| Decision 1 on (slow health bar) | No measure moves; XP per real hour 226 → 183 (guidelines), 2.4 → 2.3 (6 h sleep). |
| Milestone 10.5 gap on (36 h between strength sessions) | Strength every day: strength 0.80 → 0.45, health 4.87 → 4.48. Guidelines and strength twice a day: nothing. |
| Decision 7 on (Very hard happiness 0.30) | Day-21 health does not move (gradual 4.32, abrupt 4.37); lowest happiness 0.07 → 0.18 (gradual), 0.02 → 0.12 (abrupt). |
| Guideline activity 40 min cardio + 30 min football | Happiness +0.02 to +0.05 on every guideline row (guidelines 0.99, 6 h sleep 0.80); health +0.03 to +0.08; weight −0.3 kg. Mean distance from v1 for happiness 0.066 → 0.025, health 0.123 → 0.089; weight 0.23 → 0.44 kg. |
| No-sport plans with 2 h of screens | Happiness 0.73 → 0.83 and 0.61 → 0.70 (exactly v1); health 3.74 → 3.84 and 3.17 → 3.26 (v1 3.77 and 3.22); weight +0.5 kg (v1 is +0.8 kg above our 1-hour rows). |
| Training minutes averaged over a week (168 h) | Strength on every guideline row 0.57 to 0.62 → 0.73 to 0.76; health +0.03 to +0.06. Strength twice a day and every day: nothing. |
| Severe diet without the screens hour | 2.00 → 2.33 meals and 981 → 1,145 kcal a day (exactly v1); 20.4 → 23.4 kg, z −5.66 → −4.12. |

## Plan details that had to be guessed (decision 12)

v1 describes its scenarios in one line each. These details are the game's guesses; the team can check them against its v1 simulation.

- **Guideline activity:** 70 min of cardio (1 h at 1 h after waking, 10 min at 2 h). v1 may have had 40 min of cardio and 30 min of football (the parity run comes much closer to v1's happiness with it, and the review mentions football for strength twice a day).
- **Guideline strength:** 30-minute sessions (review) on days 1, 3 and 5 of each week, 3 h after waking, after the cardio.
- **Screens:** 1 h at 6 h after waking in every plan except the couch (3 h). v1's two no-sport plans probably had 2 h (exactly v1's happiness with it).
- **4 h of cardio:** four hours in a row from 1 h after waking, so the avatar cannot eat for 4 hours.
- **Severe diet:** skips 2 of every 3 "I'm hungry!" and has 1 h of screens, during which it cannot answer.
- **Strength twice a day:** 40 min of cardio at 1 h; strength 1 h at 9 and 12 h after waking (review).
- **Strength every day:** the guideline plan with 1 h of strength every day instead of 30 min on 3 days.
- **Sleep:** 10.5 h; 6 h in the short-sleep plans, 7 h and 8 h where the title says so.
- **Gradual switch:** the share of healthy meals is 25%, 50%, 75% and 100% over the first week.

## Proposals for the team

1. **Check the plan guesses above** against the v1 simulation, or send it, so the scenario test can play exactly the same plans. If v1 had football and 2 h of screens, the game's happiness is within about 0.03 of v1 in every plan except 4 h of cardio.
2. **Choose the training window** (`train.average_window_h`): 24 h makes strength rise and fall through the week (closer to how a body responds to each session); a week gives a steady value (closer to v1's 0.70 at day 21, but 0.76). Something between (for example 72 h) is possible.
3. **Decide about eating time** (decision 2) and the eating METy: half-hour meals make a very active avatar hungrier (4 h of cardio: happiness −0.10) and, at METy 1.5, add about 0.4 kg in 21 days.
4. **The hunger penalty with fixed portions** (v1 open decision 7): a very active avatar is hungry for long periods even when it eats at once. Bigger portions, or a shorter gap after exercise, would fix it; Pessoa 3 can check the size of `mood.events.hungry_per_h` against research (the review: research gives the direction, not the size).
5. **Danger state values** (`fail.danger_z` −3, `fail.danger_hours` 72, `fail.danger_failure_z` −4) and the **36-hour gap** (`train.strength_min_gap_h`) are the review's numbers, kept as placeholders.
