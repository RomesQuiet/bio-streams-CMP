# Milestone 10 Review: Differences from Health Calculation v1

Plasticine Tamagotchi. Copied from the team's Google Doc "Milestone 10 Review" (27 October 2026), a review of "Milestone 10: Differences from Health Calculation v1" (`documentation/milestone10_calibration.md`). Milestone 10.5 (`MILESTONE_10_5.md`) acts on it.

## Verdict

The calibration test is the right check, and the Bases fundamental rules still pass, but only one of the six proposed causes is confirmed. Difference 3 is explained. The causes given for differences 2, 4 and 6 do not reproduce when they are added to the v1 model, and the cause given for difference 1 uses a value that is the same in v1, so it cannot explain a difference. Before the team decides on the checklist, the real causes should be found with a parity run (see Method).

The review also found two gaps in the v1 design, which the game has inherited: one strength session every day scores better than the guidelines, and a severely thin avatar cannot reach failure through health. Both have a proposed fix below, and the second one answers decision 1.

## How the causes were checked

The v1 numbers came from a simulation of the v1 equations. Each proposed cause was added to that simulation and the scenario was played again: boy of 10, Normal start, 21 avatar days, v1 placeholder values. If adding a cause reproduces the game's number, the cause is confirmed. If the number does not move, the difference comes from somewhere else.

## Review of each difference

| # | Proposed cause | Check in the v1 model | Verdict | Recommendation |
|---|---|---|---|---|
| 1. Severe diet loses weight faster | The thin-avatar appetite boost (0.15) does not slow the loss enough | v1 uses the same 0.15, so it cannot explain a difference. In v1 the avatar ate about 2.3 meals a day (1,145 kcal). Adding a 30-minute wait before eating changes nothing (24.0 kg, z −3.84). | Cause not found | Compare kcal eaten per day and meals per day in the game with v1 (1,145 kcal, 2.3 meals). A lower intake points to the meal-prompt logic after a skip. Add the danger state below either way. |
| 2. Happiness about 0.1 lower in imperfect plans | The player waits up to 30 min to eat, so the hunger penalty hits more often; 4 h of cardio leaves little screen time | Waits of 0, 15 and 30 avatar minutes give the same happiness within 0.01 in the 6 h sleep, 4 h cardio and healthy-food-no-sport plans (0.83, 0.85, 0.83). The v1 4 h cardio plan already had only 1 h of screens. | Not confirmed | Check the unit of the wait: 30 real minutes would be 21 avatar hours. Find the cause with the parity run before changing the penalties. |
| 3. Strength twice a day gives more | The game's plan adds the guideline 70 minutes; v1 may not have | v1's plan was 40 min of cardio, strength 1 h at 9:00 and 1 h at 12:00 (hours after waking), 1 h of screens, no football. Adding 30 min of football gives strength 0.43, fitness 0.79, health 4.10. The game gives 0.45, 0.82, 4.16. | Confirmed | No decision needed. Describe the v1 scenario as "40 min cardio, no football" in the calibration file. |
| 4. Guideline strength lower | 1 h sessions tire fully after 45 min, so the last 15 min count for nothing | v1's guideline plan used 30-minute sessions and already had the 45-minute fatigue rule. Sessions of 30, 45 and 60 min give strength 0.70, 0.71 and 0.71. | Not confirmed | A 45-minute option is fine for the interface but will not raise strength. Look at the team's too-soon strength rule and at how minutes beyond daily capacity are counted. |
| 5. Less XP per real hour on the guidelines | The health bar moves once per avatar day (decision 1) | Cannot be tested: v1 has no slow health bar. | Plausible | Accept. Check that the failure timers and the Bases test read the true health, not the displayed one, or the 24-hour failure window grows by up to a day. |
| 6. Very hard ends lower | Higher start from decision 7; fast-food craving 0.95 | Starting happiness 0.15 or 0.30 gives the same day-21 health: 4.45 with an abrupt switch, 4.28 with a gradual one. The 0.95 craving is also in v1. The game's 4.28 equals v1's gradual result exactly. | Likely compared with the wrong v1 row | Check which food plan the Very hard test plays. If it is the gradual switch, there is no difference. |

Decision 7 does help: with starting happiness 0.30, the lowest value in the abrupt Very hard run is 0.13 instead of 0.07, so the avatar no longer dips below the 0.10 failure line at the start.

## Gaps in the v1 design

### Daily strength training scores better than the guidelines

The v1 too-soon rule counts a strength session as too soon when recovery is below 0.60. Recovery 23 hours after a full session is 0.62, so one 1-hour session every day always passes. That plan ends with strength 0.79 and health 4.85, more than the guidelines (0.70 and 4.80). This contradicts Bases fundamental (exercise done too regularly does less good) and the paediatric advice of 2 to 3 non-consecutive days a week (AAP 2020). Milestone 10 does not test this plan, and the team's too-soon decision may or may not cover it.

Proposed fix: keep the recovery rule and add a minimum gap of 36 avatar hours (clock time) between the start of one strength session and the next. Results in the v1 model, day 21:

| Plan | Strength, no gap rule | Health, no gap rule | Strength, 36 h gap | Health, 36 h gap |
|---|---|---|---|---|
| Guidelines, 30 min strength 3 days a week | 0.70 | 4.80 | 0.70 | 4.80 |
| Guidelines, 1 h strength 3 days a week | 0.71 | 4.81 | 0.71 | 4.81 |
| 1 h strength every other day | 0.75 | 4.83 | 0.75 | 4.83 |
| 1 h strength every day | 0.79 | 4.85 | 0.44 | 4.42 |
| 1 h strength twice a day | 0.43 | 4.10 | 0.43 | 4.10 |

The gap rule leaves every guideline plan unchanged and makes daily strength clearly worse. "1 h strength every day" should be added to the calibration test and to the Bases fundamental check.

### Severe thinness cannot reach failure through health

With Physical at 0 and good sleep, health stays at 1.71 (happiness 0.07) to 2.30 (happiness 0.50), above the 1.3 failure line. The v1 disease risk index counts only high BMI-for-age, so thinness has no disease path either. The only way a starving avatar fails is through happiness. In the game's severe diet the avatar reached BMI-for-age z −5.53, below the WHO limit for a biologically implausible value (z below −5). A science jury will expect the game to react long before that.

Proposed fix, as the answer to decision 1 (values to tune):

- Below z −3 (WHO severe thinness) the avatar enters a reversible danger state: it shows the Thin and Ill images and the health bar warns. Eating normally again ends it.
- If the danger state lasts 3 avatar days, or z reaches −4, it counts as a serious condition and ends in failure.
- The risk index gets a thinness term, for example 0.40 × clamp((−2 − z) ÷ 2), mirroring the obesity term.

The severe-diet plan should still lose weight, as Bases fundamental requires, so the loss itself should only be slowed if the intake comparison in difference 1 shows the game differs from v1.

## Method

- **Change one thing at a time.** The test changes the player's behaviour, decisions 1 and 7 and the too-soon rule together, so each difference has a likely cause rather than a measured one. Run a parity pass first, with the decisions switched off and the avatar eating as soon as it says "I'm hungry!". Any difference left is an implementation difference. Then switch on one decision at a time and record how each result moves.
- **State the player rule exactly.** The summary says the player eats whenever the avatar says "I'm hungry!", while difference 2 says it waits up to 30 minutes. Give the wait, its unit (avatar or real minutes) and whether it is random. If it is random, fix the seed and report the range over several runs.
- **Report failure for every scenario.** The severe diet's lowest happiness is 0.07, below the 0.10 line. Say whether the 12-hour timer fired.
- **Add the missing scenarios:** 1 h of strength every day, and the severe diet over 60 avatar days.

## Answers to the decisions list

| Difference | Recommended answer |
|---|---|
| 1 | Yes, add the reversible danger state above. Do not slow the loss by tuning `appetite.thin_boost_per_sd` until the intake comparison shows why the game loses faster than v1. |
| 2 | Research can confirm the direction of these effects (hunger is linked to lower mood and more irritability in adults, Swami 2022), not their size, because the size is a game-scale design value. Find the cause first, then choose the sizes so the scenarios give the results the team wants. |
| 3 | Resolved: v1 had 40 min of cardio and no football. No change. |
| 4 | The 45-minute option is fine for the interface but is not the cause. Look at the too-soon rule and daily capacity. |
| 5 | Accept, after checking that failure timers use the true health. |
| 6 | Check which food plan was played; it probably matches v1's gradual switch. |

## Sources

- CDC. SAS program for the WHO growth charts: BMI-for-age z-scores below −5 or above 5 are flagged as biologically implausible.
- WHO (2007). Growth reference 5 to 19 years, BMI-for-age: severe thinness below −3 SD.
- Stricker PR et al. (2020). Resistance training for children and adolescents. AAP clinical report, Pediatrics 145(6).
- Swami V et al. (2022). Hangry in the field: an experience sampling study on the impact of hunger on anger, irritability, and affect. PLOS ONE.
- Health Calculation Architecture v1 (25 October 2026), sections 6, 9, 11 and 12.
