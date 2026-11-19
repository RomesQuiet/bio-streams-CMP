# Sleep model v2: research and design (Milestone 27, 19 Nov 2026)

This document replaces the sleep part of **Health Calculation Architecture v1, Step 9** (`health_calculation_architecture_v1.md`) and the health bar rule of decision 1. It says what the science says, what was changed, what was kept, and what was adapted so the game stays playable. All numbers are in `data/config.json` (group `sleep`, and `health.alpha_bar`); the new ones are placeholders for the team (Pessoa 2: sleep; Pessoa 4: health bar).

## 1. The problems (user, 19 Nov 2026)

"The sleep bar doesn't work well": a Normal avatar starts at 7 AM with 4 h of sleep debt, and health only rises if the avatar sleeps during the day and at night. There should be a minimum wake time, the sleep debt should be dynamic instead of a fixed number, and the bars should show it a little.

What the code did (v1 as built in Milestone 10):

1. **The debt and the Sleep measure changed only when a sleep ended.** During the day they were a fixed number.
2. **The health bar also moved only when a sleep ended**, 37% of the way to the target per sleep. So health looked stuck all day, and every extra sleep (a nap) gave the bar one more step.
3. **"Tired" came from the debt alone.** Normal starts with 4 h of debt, so d = 0.5 = tired, and the avatar asked to sleep at 7:00, just after waking.
4. **The avatar could sleep at any time with 1 h of debt or more**, so with 4 h of debt it could sleep again at 7:00. There was no minimum wake time.
5. **A nap was counted as a whole short night:** debt += minimum − slept, so a 1-hour nap added 8 h of debt (child).

## 2. What the science says

| Topic | Finding | Source |
|---|---|---|
| Sleep need | 6–12 years: 9–12 h per 24 h; 13–18 years: 8–10 h per 24 h, on a regular basis. Regularly sleeping more is also linked to worse health. | AASM consensus, Paruthi et al., J Clin Sleep Med 2016;12(6):785–786 ([PMC4877308](https://pmc.ncbi.nlm.nih.gov/articles/PMC4877308)) |
| Two processes | Sleepiness comes from a homeostatic **sleep pressure** (Process S), which builds up while awake and falls during sleep, plus a circadian rhythm (Process C). | Borbély 1982; reviewed in [Frontiers in Physiology 2018](https://www.frontiersin.org/article/10.3389/fphys.2018.01529/full) |
| Pressure in children | Sleep pressure builds up faster in children (time constant 8.9 h, Tanner 1–2) than in mature adolescents (15.4 h); it falls during sleep much faster than it builds (decay about 2–3 h). | Jenni, Achermann & Carskadon, Sleep 2005 ([PDF](https://typeset.io/pdf/homeostatic-sleep-regulation-in-adolescents-4wtrtjb1az.pdf)) |
| Debt from staying awake | Under chronic restriction (4, 6, 8 h for 14 days), deficits grew almost linearly with the **wakefulness beyond a critical wake duration of 15.84 h** (s.e. 0.73 h), which means a daily need of about 8.2 h. Lost sleep adds up; people do not notice it. | Van Dongen et al., Sleep 2003;26(2):117–126 ([PubMed 12683469](https://pubmed.ncbi.nlm.nih.gov/12683469/)) |
| Recovery | Recovery from accumulated debt is slow and partial: one or a few nights do not restore it fully. | Van Dongen 2003; Belenky 2003; Kitamura 2016 (adults: 1 h of chronic debt took 4 days), already in v1 |
| Naps at school age | Most children have stopped napping by age 5 (94% in a meta-analysis), and nearly all by 7. Daytime sleep propensity is low in children and adolescents. | Staton et al., meta-analysis ([PMC4899693](https://pmc.ncbi.nlm.nih.gov/articles/PMC4899693)); MSLT data in 8–12-year-olds: a mean latency under 20 min is rare |
| Minimum wake time | There is no single published "minimum wake time" for children. Daytime sleep is unlikely soon after a full night (low pressure) and becomes possible as pressure builds; sleep deprivation shortens the time to fall asleep. | Process S above; MSLT data above (this is the basis of the game rule in 4.3) |

## 3. What changes and what stays

| Part | v1 (Milestone 10) | v2 (Milestone 27) | Status |
|---|---|---|---|
| Recommended range and target | Child 9–12 h (target 10.5), teenager 8–10 h (target 9) | Same | **Unchanged** |
| Sleep measure | (1 − min(1, debt / 8)) × oversleep factor | Same formula, **worked out every step** | Unchanged formula, now dynamic |
| Debt from short sleep | At each new day: + max(0, minimum − slept) | Sleep need builds every hour; need left unpaid when a sleep ends becomes debt; need above a normal day's counts as debt at once (4.1) | **Changed** (exactly v1's total per cycle) |
| Debt recovery | At each new day: × e^(−(slept / target) × 24 / 12) (86% per full night, k = 10) | The **same factor applied hour by hour during sleep** | Unchanged result, now dynamic |
| A day without sleep (0-hour rule) | + 9 h of debt at once when the day runs out | Nothing at once: the need keeps growing, its late part counts as debt, and the avatar stays tired (after 24 h awake: 3.4 h; after 48 h: 12.4 h) | **Changed** |
| Naps | A nap counted as a whole night (1 h nap: +8 h debt) | A nap pays its hours; only the need it leaves becomes debt (1 h nap with 2 h of need: +1.4 h) | **Changed** |
| Sleep pressure | None (hours awake only, reset by any sleep) | **Sleep need** N, in hours, shown in the Sleep bar (4.1) | **New** |
| "I'm tired" | Tiredness = max(d, (awake − 15) / 4) ≥ 0.5 | Sleepiness from today's need, earlier with debt (4.2) | **Changed** |
| Tiredness for performance (training, minigames, happiness) | max(d, (awake − 15) / 4) | Same | **Unchanged** |
| When the avatar can sleep | Debt ≥ 1 h or awake ≥ 6 h | **Minimum wake time** after any sleep, shorter with debt (4.3) | **Changed** |
| Wake-up limit | Maximum of the range + min(debt, 2 h) | Same | **Unchanged** |
| Night quality and the happiness on waking | From the hours slept | Same | **Unchanged** |
| Health bar | 37% of the way to the target once per sleep end | **The same 37% per 24 avatar hours, spread over every step** (4.4) | **Changed** (decision 1) |
| Starting debt per difficulty | Easy 2, Normal 4, Hard 5.6, Very hard 7.2 h | Same; today's need starts at 0 (the avatar just woke up) | **Unchanged** |
| Day length after sleep | 14 + (10 − slept) | Same | **Unchanged** |

## 4. The v2 model

### 4.1 Sleep need and sleep debt (dynamic)

Two numbers, both in hours of sleep:

- **Sleep need N** (`GameState.sleep_need`): the sleep owed today. Every avatar hour, awake or asleep, it grows by minimum ÷ 24 (child 9 ÷ 24 = 0.375 h, teenager 8 ÷ 24 = 0.33 h), because the need is per 24 hours (AASM). Every hour asleep it falls by 1 h. It never goes below 0. After 15 h awake a child owes 5.6 h; a night of 9 h pays it back to 0 (5.6 + 9 × 0.375 − 9 = 0).
- **Sleep debt D** (`GameState.sleep_debt`): the chronic debt. **When a sleep ends, the need it did not pay becomes debt at once**, so a short night shows in the morning, as in v1. In this game any sleep starts a new day, so this also counts for a nap, but a 1-hour nap with 2 h of need adds only 1.4 h of debt (v1: 8 h).
- **Late need counts at once.** Need above what a normal day builds (N_day = minimum × (24 − minimum) ÷ 24: child 5.6 h, teenager 5.3 h) is sleep that is already late: staying awake past the normal day, Van Dongen's wakefulness beyond the critical duration (for a child 24 − 9 = 15 h, close to the adults' 15.84 h). The **debt that counts** (`SleepModel.effective_debt()`) is D plus that late part. It is what lowers the Sleep measure, sets the debt factor d (appetite, training, capacity, risk), shortens the minimum wake time and is shown in the panel. The late part stays need, so sleep pays it back hour for hour.
- **A day without sleep** (the 0-hour rule) converts nothing: the need keeps growing and the avatar stays tired.
- **Recovery:** every hour asleep, D × e^(−(1 / target) × 24 / (τ × 24 / k)), with τ = 5 days and k = 10 as in v1. A whole night at the target repays 86%, exactly as v1.

**Same totals as v1.** Over a sleep cycle the need grows by the minimum per 24 h and sleeping s hours pays s hours, so a short night adds exactly minimum − s, as v1 did: 6 h every night settles at 4.4 h of debt on waking, as v1 predicted (scenario test: Sleep 0.45 and health 3.71 at day 21; v1 0.45 and 3.79). But now the debt that counts grows during a long day, it is repaid hour by hour during sleep, the Sleep bar moves while playing, and a nap costs only the need it leaves.

### 4.2 Sleepiness ("I'm tired")

Sleepiness = N ÷ N_day + `sleep.debt_sleepiness_weight` (0.5, placeholder) × d, with d = min(1, debt that counts ÷ 8). The avatar says "I'm tired" when sleepiness ≥ 1. With no debt that is the normal bedtime (15 h awake for a child); with Normal's 4 h of debt (d = 0.5) it is at 75% of the day, about 11 h awake. At 7 AM, just after waking, it is never tired. (Sleep-deprived people fall asleep faster: MSLT.)

### 4.3 Minimum wake time

After any sleep the avatar can sleep again only after `sleep.can_sleep_awake_h` hours awake (6 h, placeholder, as v1's "awake ≥ 6 h"), shortened by `sleep.min_wake_cut_per_debt_h` (0.5 h, placeholder) per hour of the debt that counts, never below `sleep.min_wake_floor_h` (3 h, placeholder). Normal (4 h of debt): 4 h, so the first sleep is possible from 11:00. Or at any time when it is tired (4.2). Otherwise it says "I'm not sleepy." This is a game rule built on the science in section 2 (no exact published value exists): school-age children rarely nap and fall asleep slowly after a full night.

### 4.4 Health bar (decision 1, adapted)

The displayed health still moves 37% of the way to the target health per avatar day, but in small parts every step: health += (target − health) × (1 − (1 − 0.37)^(hours ÷ 24)). So health rises while playing, at the same speed per day as before, and a nap no longer gives an extra step.

### 4.5 Shown in the bars

The Sleep bar in the measures panel is worked out every step, and its label says the debt that counts: "Sleep amount · debt 2.4 h". A thin line under it shows today's sleep need (0 just after waking, full at bedtime).

## 5. Adapted for the game to be playable

- Real sleep pressure is a saturating exponential (Process S); the game uses straight lines in hours, so the team can read and check every number, with the same totals per 24 h.
- The circadian rhythm (Process C) is not modelled: the game's day length already follows the sleep-to-day rule, and bedtime does not depend on the hour.
- The minimum wake time (4.3) and the sleepiness weight (4.2) are placeholders, not published values.
- Recovery keeps k = 10 (team decision, 25 Oct 2026), so a whole night repays 86% instead of the slower real recovery.
- The health bar keeps v1's daily speed (37%), only spread over the day.

## 6. To check with the team (Pessoa 2, Pessoa 4)

The placeholders `sleep.debt_sleepiness_weight`, `sleep.can_sleep_awake_h` (the minimum wake time), `sleep.min_wake_cut_per_debt_h` and `sleep.min_wake_floor_h`; whether the health bar should move faster now that it moves all day; whether the starting debts per difficulty should stay.

## 7. Test results (19 Nov 2026)

- `tests/sleep_test.gd` (rewritten for v2): a whole night repays 86%; 15 h awake builds 5.6 h of need and no debt; 3 h past a normal day count 1.1 h at once; a 1-hour nap adds only the need it leaves; 6 h every night settles at 4.4 h; the minimum wake time; "I'm tired" never just after waking.
- `tests/calibration_test.gd` (v1 scenarios): all rules pass except two that read the guideline plan's happiness at day 21 (at least 0.9): 0.84 now, 0.93 before. Traced day by day: the new model is a little happier every day up to day 18; on day 18 the old run fitted a fifth meal before bed and the new one does not, because the scripted player looks for "I'm hungry!" only every 30 minutes and hunger at night changed slightly (the debt now falls during the night). This is the scenario's meal timing, not the sleep model. The limits were not changed; see `MILESTONE_27.md`.
- `tests/calibration_test.gd`, "Short sleep must not pay in real time": 55.7 XP per real hour with 6 h nights against 205.2 (27%, the limit is 25%). The debt that counts rises during a long day and falls during sleep, and every rise in health gives XP (decision 92). Open question in `MILESTONE_27.md`.
- `tests/happiness_test.gd`: the same two happiness checks (0.82 at day 21, 0.91 before), for the same reason.
- The parity test (`tests/parity_test.gd`) was not run again, so `milestone10_calibration.md` still has v1 sleep numbers.
