# Health Calculation Architecture (v1)

Plasticine Tamagotchi. Version 1, 25 October 2026. Status: proposed. Copied from the Google Doc "Health Calculation Architecture v1".
"Bases fundamental" has priority: where this document disagrees with it, Bases fundamental wins and this document changes.

**For Claude:** this is the current target design of the health system. It replaces the older "Architecture Decisions: Health System" plan where they disagree. The code (Milestone 4) does not implement it yet. All numbers are placeholders to tune and go in `data/config.json`.

## Summary

Health (1 to 5) is a moderately strict average (power mean, p = 0.5) of three measures: **Physical, Happiness and Sleep**. Physical comes from the body: weight status (WHO BMI-for-age), fitness, strength and diet quality, with penalties for eating far too little and for training too much. Sleep comes from sleep debt. Happiness has its own baseline and reacts to events. Body changes run **k = 10** times faster than real life; the clock, the hours slept, the guideline doses and happiness do not.

Simulation (boy, 10 years, Normal, 21 avatar days, about 51 real hours of play):

- Guidelines (healthy food, 70 min activity a day, strength 3 days a week, 10.5 h sleep): health 2.9 → 4.8, happiness 1.0. Healthy and happy together is possible.
- Fast food, screens, no sport: health 2.6, BMI-for-age +1.2 → +2.6 (obesity).
- Fast food with 3 h cardio a day: loses weight but Physical stays 0.32. Severe diet: loses weight fast, Physical 0.05, hungry and sad.
- Sleeping 6 h instead of 10.5 h saves a third of real waiting time but ends at health 3.8 and earns about 1% of the XP per real hour.
- Too much exercise (4 h a day) or strength twice a day ends below the guideline plan (4.2 and 4.0 against 4.8).

## Rules the model follows

| Rule | Source | Where |
|---|---|---|
| Every action (fast food, healthy food, exercise, sleep, screens, football) has scientifically correct consequences. | Bases | All steps |
| Exercise within healthy norms raises health. Too much for the current fitness, or too often, does less good. Exercise does not yield after the avatar has already done a lot. | Bases | Step 6 |
| Fast food makes the avatar fatter at average metabolism. Healthy food makes it slimmer. | Bases | Steps 4, 5 |
| Fast food with a lot of exercise: weight falls, but not healthy. Severe diet without exercise: weight falls, but not healthy. | Bases | Steps 5, 6, 8 |
| Short sleep: fitness grows more slowly, more hunger and eating, tired, worse health. Metabolism does not slow down. | Bases (corrected 25 Oct) | Steps 3, 4, 9 |
| Wishes: the avatar wants fast food, does not want to exercise, gets sleepy and wants screens. Refusing lowers happiness. Exercise and good sleep raise it. | Bases | Step 10 |
| Happiness is part of health (WHO) and a secondary goal. Very sad, minimal health or an irreversible disease is failure. Healthy and happy must be possible together. | Bases, team | Steps 10–12 |
| The avatar cannot sleep when its sleep is up to date. Minutes are chosen on a slider. Each activity except sleep has a minigame that sets performance. | Bases | Steps 6, 9 |
| Day: 20 real minutes = 14 h. Night: 2 real hours = 10 h. The 10 h only sets the scale; recommended sleep comes from the age (child 9–12 h, teenager 8–10 h). | Bases, concept | Steps 1, 9 |
| k = 10 for everything metabolic, sleep debt included. Happiness is not sped up. | Bases, team (25 Oct) | Step 1 |

## How the system is built

### Modules

Each module owns its state and reads others only through their outputs. All numbers come from `data/config.json`; global state stays in the Autoload.

| Module | Reads | Updates | Speed |
|---|---|---|---|
| Clock | Real time, pause, sleep, wake button | Avatar time, awake/asleep, new day | Clock |
| Body size | Body age, sex | Height, BMI-for-age z, healthy reference weight | k (ageing) |
| Energy and weight | Activity, meals, body size, sleep debt | Energy spent, hunger, weight, energy deficit penalty U | k (weight) |
| Training | Minutes, activity type, minigame score, sleep debt | Fitness, strength, daily capacity, recovery, overreaching O | k (levels), clock (recovery) |
| Sleep | Sleep episodes, age range | Sleep debt, Sleep measure, tiredness | k (recovery) |
| Habits | Meals | Diet quality Q, fast-food craving C, habituation A | k (Q, C), clock (A) |
| Mood | Events, Physical, Sleep, Q, U, O | Happiness | Clock |
| Health | Physical, Happiness, Sleep | Health 1–5, failure timers | Instant |
| Risk | z, fitness, Q, sleep debt | Disease stage | k |
| Progress | Health | XP and level | Clock |
| Avatar messages | Hunger, tiredness, wishes, z, strength, happiness | Speech bubbles and images | Instant |

### Update order

Fixed steps of 5 avatar minutes (or every real second, converted). All rates are per avatar hour. Nothing runs while paused or closed.

1. Clock: advance avatar time; mark awake, asleep or in an activity.
2. Energy spent (Step 3).
3. Hunger (Step 4).
4. Weight, body age, height and z (Steps 2, 5).
5. Energy deficit penalty U (Step 5).
6. Training: capacity, recovery, overreaching, fitness, strength (Step 6).
7. Physical (Step 8).
8. Happiness baseline and continuous effects (Step 10).
9. Health, failure timers, risk and XP (Steps 11, 12).
10. Avatar messages and images.

Events are handled when they happen: a meal or skipped meal (Steps 4, 7), start and end of an activity (Steps 6, 10), and the new day after sleep, which updates sleep debt, the Sleep measure and the reference appetite (Steps 4, 9).

### Clock time and body time

| Sped up by k = 10 (body time) | Not sped up (clock time) |
|---|---|
| Weight change, body age and growth, fitness level, strength level, diet quality, fast-food craving, recovery from sleep debt, disease damage | Avatar clock, hours slept, minutes per day, sessions per week, recovery between sessions, hunger and meal timing, fast-food habituation, happiness |

Body hours = k × avatar hours. 21 avatar days = 210 body days (about 7 months).

### State variables

| Variable | Range | Meaning |
|---|---|---|
| weight | kg | Body weight |
| body age | years | Grows with body time; sets height, WHO row, BMR band, sleep range |
| z | about −5 to +5 | WHO BMI-for-age z-score |
| fitness, strength | 0–1 | Aerobic fitness, muscle strength |
| Q, C, A | 0–1 | Diet quality, fast-food craving, habituation to fast-food pleasure |
| hunger | kcal | Energy the avatar wants to eat now |
| U, O | 0–1 | Energy deficit penalty, overreaching load |
| sleep debt | hours | Unrecovered sleep |
| Physical, Sleep, Happiness | 0–1 | The three measures |
| Health | 1–5 | Main goal |
| XP | no limit | Experience |

### Configuration

Every number is a named value in `data/config.json`, written as `group.name_unit` (e.g. `sleep.debt_recovery_tau_days`). Time constants say whether they are body time (× k) or clock time. The WHO BMI-for-age table (both sexes, 5–19 years, by month) and the WHO height-for-age table go in their own data files. No number in scripts.

## Step-by-step design

### Step 1: Time and body speed

k multiplies **slow body states only** (table above). Everything a guideline is written in stays in clock time: hours slept, minutes per day, sessions per week, recovery between sessions, meal timing. Happiness is not sped up (team decision).
Reason: if k sped up recovery between workouts, two strength sessions a day would beat the guideline plan (0.92 vs 0.73 strength), teaching the opposite of the paediatric advice (2–3 non-consecutive days a week).

### Step 2: Body size and weight status

The body ages with body time (a fixed height would teach children to lose weight; AAP 2023 advises keeping weight steady while growing).

- body age += k × avatar hours ÷ 8,760.
- Height = WHO median height-for-age for sex and body age.
- BMI = weight ÷ height².
- z = ((BMI ÷ M)^L − 1) ÷ (L × S), L, M, S from WHO 2007 for sex and age in months. Above +3: z = 3 + (BMI − SD3) ÷ (SD3 − SD2), mirrored below −3. Example, boy 10 y 0 m: L = −1.7407, M = 16.4433, S = 0.10566.
- Weight score w(z): 1.0 for z in [−2, +1]; 0.5 at +2; 0.1 at +3; 0 at +4; 0.3 at −3; 0 at −4; straight lines between.

Prediction: guideline avatar loses 2.8 kg in 21 avatar days then regains as it grows; z +1.2 → 0.0 (day 21) → −0.4 (day 60). Side effect: sleep range, BMR equation and WHO row follow body age; a 10-year-old reaches 13 after about 110 avatar days.

### Step 3: Energy spent

- BMR (Schofield, WHO/FAO/UNU 1985), kcal/day: boys 10–18: 17.686 × weight + 658.2; girls 10–18: 13.384 × weight + 692.6; boys 3–10: 22.706 × weight + 504.3; girls 3–10: 20.315 × weight + 485.9.
- Energy per avatar hour = BMR ÷ 24 × METy.
- METy: sleep 0.95, normal school-day activity 1.7, screens 1.3, cardio 7.0, football 7.5, strength/calisthenics 5.0.

Prediction: guideline day ≈ 2,100 kcal (boy, 10 y); inactive ≈ 1,800 kcal.
**Decision: sleep never changes the metabolic rate.** Its effect on weight goes through appetite (Al Khatib 2017: +385 kcal/day eaten, spending unchanged). Bases fundamental corrected on 25 Oct.

### Step 4: Appetite and meals

Appetite is 70% habit and 30% current spending (Mayer 1956; Blundell 2015).

- Every avatar hour: hunger += (0.7 × reference ÷ 24 + 0.3 × energy spent this hour) × (1 + 0.2 × d) × (1 + 0.15 × max(0, −z)).
- reference = BMR at healthy weight for current age and height × 1.6.
- d = sleep debt factor (Step 9): up to +20% appetite.
- Last term: body defends against weight loss below the median.

Meals: "I'm hungry!" when hunger ≥ 0.8 of a healthy meal and ≥ 2 avatar hours since the last meal or skip. Healthy portion = reference ÷ 4 kcal. Fast-food portion = 1.3 × healthy portion in kcal. Fast-food satiety 0.83 (healthy 1.0), so fast food leads to ≈ 20% more energy eaten (Hall 2019). Eating removes kcal × satiety from hunger; skipping removes nothing. Hunger grows during sleep but the avatar only eats while awake.
Open: portions are fixed, so very active avatars can only eat more by eating more often (the 2-hour gap matters).

### Step 5: Weight and energy deficit

- Weight change per avatar hour = k × (kcal eaten − kcal spent) ÷ 7,700. BMR depends on weight, so weight settles (covers the Hall 2011 objection). Fat and muscle are not tracked separately.
- Worst case (fast food every meal, 3 h screens, 8 h sleep, no sport): +12.6 kg in 21 avatar days, z +3.1 after 60. Tune fast-food satiety if too fast.

Energy deficit penalty U (IOC 2023 REDs idea; cut-offs are design values):

- deficit = 1 − (kcal eaten in last 24 avatar h ÷ kcal spent in same hours).
- U = 0 below 30% deficit, linear to 1 at 60%.
- Effects: Physical × (1 − 0.5 × U); fitness and strength targets and gains × (1 − 0.5 × U); happiness baseline − 0.2 × U.

### Step 6: Exercise

- Minigame performance = 0.7 + 0.3 × score × (1 − 0.3 × tiredness).
- Daily capacity = (60 + 90 × fitness) × (1 − 0.3 × d) minutes of moderate-to-vigorous activity per avatar day.
- Minutes beyond capacity give no benefit and no mood boost, only −0.02 happiness per hour. Earlier minutes keep their value (no downward spiral).
- **Overreaching load O:** minutes beyond capacity and strength sessions started too soon build O = average excess minutes per day over ≈ 3 avatar days (clock time) ÷ 120, 0–1. O: Physical × (1 − 0.3 × O), training gains × (1 − 0.5 × O), happiness baseline − 0.1 × O. Fades with rest.
- **Recovery (clock time):** cardio and football fully tire after 120 continuous minutes, recover with τ = 6 h. Strength tires after 45 min, recovers with τ = 24 h (86% after 48 h). A strength session starting below 60% recovery counts as too soon (AAP 2020: 2–3 non-consecutive days).

Fitness and strength:

- Effective minutes = minutes × performance × recovery (0 beyond capacity). 24-hour averages give A_cardio (cardio + football) and A_strength.
- Fitness target = 0.1 + 0.9 × (1 − e^(−2 × (A_cardio + 0.3 × A_strength) ÷ 60)).
- Strength target = 0.1 + 0.9 × (1 − e^(−2 × (A_strength + 0.1 × A_cardio) ÷ 20)).
- They move toward targets with real τ of 30 and 42 days (3.0 and 4.2 avatar days with k = 10). Gains only × (1 − 0.5 × d) × (1 − 0.5 × U) × (1 − 0.5 × O).

Prediction: guidelines fitness 0.40 → 0.83, strength 0.40 → 0.70 in 21 days; 4 h cardio/day health 4.23; strength twice a day health 3.97 (strength 0.34).

### Step 7: Diet quality and cravings

Per meal (x = 1 healthy, 0 fast food):

- Diet quality Q += (x − Q) × 0.119 (real τ 21 days, body time).
- Fast-food craving C += ((1 − x) − C) × 0.083 (real τ 30 days, body time; 8–15 tries to accept a food).
- Habituation A += ((1 − x) − A) × 0.05 (clock time, ≈ 20 meals).

Happiness from meals: healthy +0.01 − 0.06 × C; fast food +0.01 + 0.06 × C × (1 − A).
Prediction: craving 0.9, abrupt switch → lowest happiness 0.40; one more healthy meal per day over a week → lowest 0.50 (Very hard: 0.07 vs 0.15). Same health after 21 days.
Decision: keep the small diet–mood effect the evidence supports; fast food alone does not lead to failure (open decision 2).

### Step 8: Physical

Physical = M(w, fitness, strength) × (0.4 + 0.6 × Q) × (1 − 0.5 × U) × (1 − 0.3 × O),
M = (0.5 × √w + 0.3 × √fitness + 0.2 × √strength)² (power mean p = 0.5, weights 0.5 / 0.3 / 0.2). Weight weighs most (project topic). With fast food at every meal, Physical reaches at most 40% of what the body alone gives.
Prediction: fast food + 3 h cardio 0.32; guidelines 0.88; couch with fast food 0.07.

### Step 9: Sleep

Recommended (AASM 2016): child 9–12 h (target 10.5), teenager 8–10 h (target 9). "Slept" = all sleep since the previous new day, naps included. Ignoring the night recommendation counts as 0 h.

At each new day:

- debt = debt × e^(−(slept ÷ target) × 24 ÷ 12) + max(0, minimum − slept). 12 = real recovery τ of 5 days ÷ k (Kitamura 2016, adults). A full night repays 86%; no sleep repays nothing.
- oversleep = max(0, slept − maximum).
- Sleep = (1 − min(1, debt ÷ 8)) × (1 − min(0.3, 0.1 × oversleep)).
- d = min(1, debt ÷ 8).

Effects of d: fitness/strength gains × (1 − 0.5 × d); appetite × (1 + 0.2 × d); capacity × (1 − 0.3 × d); lower minigame performance via tiredness; happiness on waking + 0.08 × (night quality − 0.5). Night quality = (slept ÷ minimum)² when short, 1 in range, 1 − 0.1 per hour of oversleep (≥ 0.7). Tiredness = max(d, (hours awake − 15) ÷ 4), at most 1.

**Can the avatar sleep?** Only if debt ≥ 1 h or awake ≥ 6 avatar hours; otherwise it says it is not sleepy. It wakes after the chosen hours, never later than maximum + min(debt, 2 h).

Prediction: 6 h sleep with guideline activity → debt 4.4 h, Sleep 0.45, 15% more food, fitness 0.71 vs 0.76 after a week, health 3.81 vs 4.80. Short sleep saves real time (34 vs 51 real hours over 21 days) but gives 2.6 XP per real hour vs 225, so it never pays. With k on sleep debt, one short night is mostly repaid by the next normal night; chronic short sleep keeps debt high.

### Step 10: Happiness

Happiness (0–1) moves toward a baseline with τ = 12 avatar hours and jumps with events. k does not apply.

Baseline = 0.15 + 0.30 × Physical + 0.25 × Sleep + 0.10 × Q + 0.20 × Fun − 0.2 × U − 0.10 × screen excess − 0.1 × O.

- Fun = 24-hour average of (football min × 1.0 + screen min × 0.6 (first 120 of the day only) + exercise min × 0.3) ÷ 90, at most 1.
- Screen excess = (average daily screen minutes − 120) ÷ 120, 0–1 (Orben and Przybylski 2019; Canadian 2 h limit).

| Event | Change in happiness |
|---|---|
| Healthy meal | +0.01 − 0.06 × C |
| Fast-food meal | +0.01 + 0.06 × C × (1 − A) |
| Starting cardio or strength (does not want to exercise) | −0.03 × (1 − fitness) |
| Cardio or strength within capacity | +0.07 per hour × (1 − 0.5 × tiredness) |
| Exercise beyond capacity | −0.02 per hour |
| Football | +0.10 per hour |
| Screens, first 120 min of the day | +0.05 per hour |
| 4 awake hours without screens (wish refused) | −0.02 |
| Hungry while awake (hunger > 1.2 healthy meals) | −0.05 per hour |
| Waking up | +0.08 × (night quality − 0.5) |
| Kept awake while very tired (not simulated yet) | −0.02 per hour |

With everything good the baseline is ≈ 0.95 and happiness reaches 1.0.

### Step 11: Health

Health = 1 + 4 × M(Physical, Happiness, Sleep), equal weights, **p = 0.5**: M = ((√Physical + √Happiness + √Sleep) ÷ 3)².

| Scenario, day 21 | p = 1 | p = 0.5 | p = 0 |
|---|---|---|---|
| Guidelines | 4.85 | 4.84 | 4.84 |
| Couch with fast food | 2.92 | 2.63 | 2.27 |
| Fast food with 3 h cardio | 3.75 | 3.61 | 3.47 |
| Severe diet, no sport | 3.12 | 2.71 | 2.22 |
| Sport and sleep, fast food only | 3.69 | 3.53 | 3.35 |
| Healthy food, no sport, 7 h sleep | 3.28 | 3.23 | 3.18 |

Arithmetic mean hides one bad measure; geometric mean makes any zero give health 1. p = 0.5 chosen (concept starting values built on it). Check (0.9, 0.6, 0.1): arithmetic 3.13, p = 0.5 2.85, geometric 2.51.

### Step 12: Failure, diseases and XP

**Failure** (to tune): health below 1.3 for 24 avatar hours; happiness below 0.10 for 12 avatar hours; an irreversible disease. A time window is needed because Very hard starts at 1.35.

**Diseases** (framework only; which diseases is not decided):

- Risk R = 0.40 × clamp((z − 1) ÷ 2) + 0.20 × (1 − fitness) + 0.25 × (1 − Q) + 0.15 × d.
- Hidden damage grows at k × (R − safe level) ÷ τ while R > safe level, falls below it.
- Stage 1 (reversible warning) can start by chance each avatar day once damage passes a threshold; goes away when damage falls.
- Stage 2 (irreversible, failure) can only follow stage 1 if damage keeps rising.
- With k = 10, one body year = 36.5 avatar days (≈ 88 real hours); set values with a health professional.

**XP** (to tune): XP += 100 × change in health, plus 10 XP per avatar hour while health ≥ 4.5, × (1 + hours at that level ÷ 48), at most × 3. Losing health loses XP. Guideline play ≈ 225 XP per real hour; every other scenario < 3.

**Avatar images:**

| Image | Condition |
|---|---|
| Hungry | Hunger ≥ 0.8 of a healthy meal |
| Tired | Tiredness ≥ 0.5 |
| Sad | Happiness < 0.3 |
| Ill | Disease stage 1 or 2 |
| Thin | z < −2 |
| Overweight | z > +1 |
| Muscular, or muscular with fat | Strength ≥ 0.7 (with fat when z > +1) |

## Predicted results

Boy 10 y, Normal start: 36.0 kg, z +1.2, fitness 0.40, strength 0.40, Physical 0.44, Sleep 0.50, Happiness 0.50, health 2.91. After 21 avatar days. \* = starts with craving 0.9.

| Scenario | kg | z | Fitness | Strength | Physical | Sleep | Happiness | Health |
|---|---|---|---|---|---|---|---|---|
| Guidelines: healthy food, 70 min/day, strength 3 days/week, 1 h screens, 10.5 h sleep | 33.2 | 0.00 | 0.83 | 0.70 | 0.88 | 1.00 | 1.00 | 4.80 |
| Couch: fast food, 3 h screens, no sport, 8 h sleep | 48.6 | 2.56 | 0.10 | 0.10 | 0.07 | 0.84 | 0.53 | 2.60 |
| Fast food with 3 h cardio a day | 35.6 | 0.60 | 0.91 | 0.57 | 0.32 | 1.00 | 0.74 | 3.56 |
| Severe diet (1 meal in 3), no sport | 24.0 | −3.85 | 0.10 | 0.10 | 0.05 | 1.00 | 0.53 (0.28 in the day) | 2.66 |
| Guidelines but 6 h sleep, extra hour of cardio | 32.3 | −0.27 | 0.87 | 0.70 | 0.83 | 0.45 | 0.85 | 3.79 |
| Guideline activity, 6 h sleep | 35.7 | 0.63 | 0.80 | 0.67 | 0.87 | 0.45 | 0.83 | 3.81 |
| Gradual switch to healthy food over a week \* | 34.3 | 0.30 | 0.83 | 0.70 | 0.88 | 1.00 | 1.00 (lowest 0.50) | 4.80 |
| Abrupt switch to healthy food \* | 33.2 | 0.00 | 0.83 | 0.70 | 0.88 | 1.00 | 1.00 (lowest 0.40) | 4.80 |
| Guideline sport and sleep, fast food only \* | 42.4 | 1.83 | 0.83 | 0.70 | 0.27 | 1.00 | 0.75 | 3.48 |
| 4 h cardio a day, healthy food | 28.2 | −1.73 | 0.86 | 0.50 | 0.63 | 1.00 | 0.85 | 4.23 |
| Strength twice a day, every day | 31.1 | −0.63 | 0.66 | 0.34 | 0.52 | 1.00 | 0.78 | 3.97 |
| Healthy food, no sport | 39.4 | 1.37 | 0.10 | 0.10 | 0.37 | 1.00 | 0.83 | 3.77 |
| Healthy food, no sport, 7 h sleep | 40.3 | 1.51 | 0.10 | 0.10 | 0.35 | 0.66 | 0.70 | 3.22 |

After 60 avatar days: guideline avatar z ≈ −0.4 while growing (35.5 kg); couch +3.1 (64 kg); sport and sleep with fast food +2.0; healthy food without sport ≈ +1.4. Same pattern for girls and teenagers.

### Bases fundamental check (each row can become an automatic test)

| Rule | Test | Result | Pass |
|---|---|---|---|
| Exercise within norms raises health | Guidelines | 2.91 → 4.80 | Yes |
| Too much or too often does less good | 4 h cardio; strength twice a day | 4.23 and 3.97 < 4.80 | Yes |
| Fast food makes the avatar fatter | Couch; sport+sleep with fast food | z +1.2 → +2.56; → +1.83 | Yes |
| Healthy food makes it slimmer | Guidelines; gradual switch | z → 0.0; → +0.3 | Yes |
| Fast food + lots of exercise: thinner, not healthy | Fast food, 3 h cardio | z +0.6, Physical 0.32 | Yes |
| Severe diet: thinner, not healthy | 1 meal in 3 | z −3.85, Physical 0.05, hungry and sad | Yes |
| Short sleep: slower fitness, more hunger, tired, worse health | 6 h sleep | Fitness 0.71 vs 0.76 day 7; +15% food; Sleep 0.45; health 3.81 | Yes |
| Refusing wishes lowers happiness; exercise and sleep raise it | Abrupt vs gradual; guidelines | Lowest 0.40 vs 0.50; happiness 1.00 | Yes |
| Healthy and happy together | Guidelines | Health 4.80, happiness 1.00 | Yes |
| Short sleep must not pay in real time | 6 h sleep | 2.6 vs 225 XP per real hour | Yes |

### Difficulty starts

| Level | z | Fitness | Strength | Q | C | Happiness | Debt (h) | Physical | Sleep | Health |
|---|---|---|---|---|---|---|---|---|---|---|
| Easy | 0.0 | 0.65 | 0.60 | 0.80 | 0.35 | 0.75 | 2.0 | 0.71 | 0.75 | 3.94 |
| Normal | +1.2 | 0.40 | 0.40 | 0.50 | 0.60 | 0.50 | 4.0 | 0.44 | 0.50 | 2.91 |
| Hard (obesity, habits cheap to change) | +2.4 | 0.15 | 0.20 | 0.25 | 0.40 | 0.30 | 5.6 | 0.14 | 0.30 | 1.95 |
| Very hard (severe obesity, very bad habits) | +3.2 | 0.05 | 0.10 | 0.10 | 0.95 | 0.15 | 7.2 | 0.03 | 0.10 | 1.35 |

From Very hard, the guidelines raise health 1.35 → 4.45 in 21 days, but happiness drops to 0.07 if food changes at once; a gradual change keeps it ≥ 0.15 (health 4.28 at day 21).

## Parameters

| Name | Value | Time | Source or reason |
|---|---|---|---|
| body.k | 10 | – | Bases fundamental |
| time.awake_avatar_min_per_real_min | 42 | – | Concept (20 min = 14 h) |
| time.sleep_avatar_min_per_real_min | 5 | – | Concept (2 h = 10 h) |
| time.step_avatar_min | 5 | – | Design |
| body.kcal_per_kg | 7,700 | – | Used with weight-dependent BMR (Hall 2011) |
| energy.pal_ref | 1.6 | – | Active child of healthy weight (IOM); calibrated |
| energy.mety_sleep / idle / screen | 0.95 / 1.7 / 1.3 | – | Youth Compendium; idle calibrated |
| energy.mety_cardio / football / strength | 7.0 / 7.5 / 5.0 | – | Youth Compendium |
| appetite.habit_share | 0.7 | – | Mayer 1956; Blundell 2015; calibrated |
| appetite.sleep_debt_boost | 0.20 | – | Al Khatib 2017 |
| appetite.thin_boost_per_sd | 0.15 | – | Design |
| meals.per_day_ref | 4 | – | School routine |
| meals.fastfood_portion | 1.3 | – | Energy-dense meals |
| meals.fastfood_satiety | 0.83 | – | Hall 2019 |
| meals.hungry_trigger / min_gap_h | 0.8 / 2 | Clock | Design |
| deficit.start / full | 0.30 / 0.60 | – | Design (IOC REDs 2023) |
| train.capacity_base_min / fit_min / sleep_cut | 60 / 90 / 0.3 | Clock | WHO 2020; design |
| train.fitness_tau_days / strength_tau_days | 30 / 42 | Body | Design |
| train.fitness_ref_min / strength_ref_min | 60 / 20 | Clock | WHO 2020; AAP 2020 |
| train.sleep_gain_cut | 0.5 | – | Bases; design |
| train.cardio_recovery_h / strength_recovery_h / strength_ready | 6 / 24 / 0.6 | Clock | AAP 2020 |
| train.overreach_tau_h / overreach_ref_min | 72 / 120 | Clock | Design |
| minigame.min_performance | 0.7 | – | Decisions matter more than skill |
| diet.quality_tau_days / craving_tau_days | 21 / 30 | Body | Repeated exposure; design |
| diet.habituation_tau_days | 5 | Clock | Design |
| sleep.child_min / max / target | 9 / 12 / 10.5 h | – | AASM 2016 |
| sleep.teen_min / max / target | 8 / 10 / 9 h | – | AASM 2016 |
| sleep.debt_recovery_tau_days | 5 | Body | Kitamura 2016 (adults) |
| sleep.debt_ref_h / oversleep_cut_per_h | 8 / 0.1 (max 0.3) | – | Design; AASM 2016 |
| sleep.can_sleep_debt_h / can_sleep_awake_h | 1 / 6 | Clock | Bases; design |
| mood.tau_h | 12 | Clock | Design |
| mood.baseline weights | 0.15 / 0.30 / 0.25 / 0.10 / 0.20 | – | Design |
| health.p | 0.5 | – | Concept starting values |
| fail.health_line / hours | 1.3 / 24 | Clock | To tune |
| fail.happiness_line / hours | 0.10 / 12 | Clock | To tune |

## Open decisions and risks

1. Very hard starting happiness: with 0.05 (concept) the avatar starts below any sensible failure line. Use 0.15, or set the happiness line below 0.05.
2. Fast food and long-term sadness: the model gives a small drop, as the evidence does. Making "never leaving fast food" lead to failure needs stronger weights than studies support.
3. Diseases: choose which exist with a health professional, and how fast. With k = 10 a short demo will not show a disease unless it gets its own speed.
4. Worst-case weight gain is steep (12.6 kg in 21 avatar days). Tune fast-food satiety if needed.
5. A severe diet reaches severe thinness in about 3 avatar weeks. Consider a reversible danger state before failure.
6. Body age grows with body time: a child becomes 13 after about 110 avatar days. Allow it or cap the age.
7. Portions are fixed, so very active avatars depend on the 2-hour meal gap to eat enough.
8. Minigame range (0.7–1.0) and can-sleep thresholds (1 h debt or 6 h awake) are design values to test with players.
9. XP values and the bonus multiplier (max 3) are placeholders.
10. Some evidence is from adults (sleep debt recovery, sleep and appetite, ultra-processed food) and is applied to children.
11. After any value change, rerun the scenarios and check every row of the Bases fundamental check still passes.

## Sources

- WHO (2007). Growth reference 5–19 years: BMI-for-age and height-for-age tables, z-score computation. https://www.who.int/tools/growth-reference-data-for-5to19-years/indicators/bmi-for-age
- Schofield WN (1985); FAO/WHO/UNU (1985). BMR equations.
- Butte NF et al. (2018). A youth compendium of physical activities. MSSE 50(2):246–256. https://www.nccor.org/tools-youthcompendium/ (application: https://pmc.ncbi.nlm.nih.gov/articles/PMC9620797/)
- Institute of Medicine (2005). Dietary Reference Intakes for energy.
- Hall KD et al. (2011). Quantification of the effect of energy imbalance on bodyweight. The Lancet.
- Hall KD et al. (2019). Ultra-processed diets cause excess calorie intake and weight gain. Cell Metabolism.
- Al Khatib HK et al. (2017). Partial sleep deprivation and energy balance. EJCN. https://www.nature.com/articles/ejcn2016201
- Mayer J et al. (1956), AJCN; Blundell JE et al. (2015), Obesity Reviews.
- Paruthi S et al. (2016). AASM pediatric sleep duration consensus. https://aasm.org/resources/pdf/pediatricsleepdurationconsensus.pdf
- Kitamura S et al. (2016). Optimal sleep duration and sleep debt. Scientific Reports. https://nature.com/articles/srep35812
- WHO (2020). Guidelines on physical activity and sedentary behaviour.
- Stricker PR et al. (2020). Resistance training for children and adolescents. AAP, Pediatrics 145(6).
- Hampl SE et al. (2023). AAP clinical practice guideline on obesity. Pediatrics 151(2).
- Mountjoy M et al. (2023). IOC consensus statement on REDs.
- Orben A, Przybylski AK (2019). Adolescent well-being and digital technology use. Nature Human Behaviour.
- Canadian 24-Hour Movement Guidelines for Children and Youth (2016).
- WHO Constitution (1948).
