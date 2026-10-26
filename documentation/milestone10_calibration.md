# Milestone 10 — Task 10: scenario results (for the team)

Date: 26 October 2026. Produced by `tests/calibration_test.gd`, which plays every scenario of the v1 "Predicted results" through the real game (the real 5-minute update loop and the real Eat, exercise, entertainment and sleep actions). The simulated player eats whenever the avatar says "I'm hungry!" (checked every half hour). Run it with:

```
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s res://tests/calibration_test.gd
```

It takes about two minutes. **No value was changed to make these results fit.** All numbers are the v1 placeholders in `data/config.json`, with the user's decisions (decision 1: the health bar moves once per avatar day; decision 7: Very hard starts with happiness 0.30; and the too-soon strength rule of Task 5).

## Result: every rule of the "Bases fundamental check" passes

| Rule | Our numbers (day 21) | Pass |
|---|---|---|
| Exercise within norms raises health | guidelines 2.91 → 4.71 | Yes |
| Too much or too often does less good | 4 h cardio 4.08, strength twice 4.16, guidelines 4.71 | Yes |
| Fast food makes the avatar fatter | z +1.20 → couch +2.51; sport and sleep with fast food +1.67 | Yes |
| Healthy food makes it slimmer | z +1.20 → guidelines −0.04; gradual switch +0.24 | Yes |
| Fast food with a lot of exercise: thinner, not healthy | z +0.70, Physical 0.31 (guidelines 0.87) | Yes |
| Severe diet without exercise: thinner, not healthy (hungry and sad) | z −5.53, Physical 0.02, hungry 98% of awake time, lowest happiness 0.07 | Yes |
| Short sleep: slower fitness gain, more hunger, tired, worse health | fitness day 7: 0.74 vs 0.79; food +9%; Sleep 0.45; health 3.65 vs 4.71; tired all the time | Yes |
| Refusing wishes lowers happiness; exercise and sleep raise it | lowest happiness: abrupt 0.36 vs gradual 0.42; guidelines happiness 0.92 | Yes |
| Healthy and happy together | guidelines health 4.71, happiness 0.92 | Yes |
| Short sleep must not pay in real time | 2.2 XP per real hour with 6 h sleep against 168.7 with 10.5 h (v1: 2.6 against 225) | Yes |

**Variants** (girl of 10, boy of 14, girl of 14): in every one the guidelines raise health to about 4.7 and lower z, and the couch raises z. Pass.

**Very hard** (boy of 10): starts at 1.49 (the lowest; the others 1.95 or more); with the guidelines and a gradual food change it reaches 4.28 in 21 days without ever reaching failure; an abrupt food switch drops happiness to 0.11, a gradual one to 0.15. Pass. (v1: 1.35 → 4.45; lowest 0.07 abrupt, 0.15 gradual.)

## Every scenario at day 21: ours (v1)

Boy of 10, Normal start: 36.0 kg, z +1.2, Physical 0.44, Sleep 0.50, Happiness 0.50, health 2.91. Health is the **target health**; the health bar (decision 1) is within 0.05 of it at day 21. \* = starts with a fast-food craving of 0.9.

| Scenario | kg | z | Fitness | Strength | Physical | Sleep | Happiness | Health |
|---|---|---|---|---|---|---|---|---|
| Guidelines | 33.0 (33.2) | −0.04 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.92 (1.00) | 4.71 (4.80) |
| Couch | 48.1 (48.6) | +2.51 (+2.56) | 0.10 (0.10) | 0.10 (0.10) | 0.07 (0.07) | 0.84 (0.84) | 0.52 (0.53) | 2.62 (2.60) |
| Fast food with 3 h cardio | 36.0 (35.6) | +0.70 (+0.60) | 0.87 (0.91) | 0.50 (0.57) | 0.31 (0.32) | 1.00 (1.00) | 0.72 (0.74) | 3.57 (3.56) |
| Severe diet (1 meal in 3) | **20.7 (24.0)** | **−5.53 (−3.85)** | 0.10 (0.10) | 0.10 (0.10) | 0.02 (0.05) | 1.00 (1.00) | 0.44 (0.53) | 2.47 (2.66) |
| Guidelines, 6 h sleep, extra cardio | 31.7 (32.3) | −0.43 (−0.27) | 0.86 (0.87) | 0.61 (0.70) | 0.81 (0.83) | 0.45 (0.45) | 0.72 (0.85) | 3.59 (3.79) |
| Guideline activity, 6 h sleep | 35.5 (35.7) | +0.59 (+0.63) | 0.82 (0.80) | 0.57 (0.67) | 0.84 (0.87) | 0.45 (0.45) | 0.73 (0.83) | 3.65 (3.81) |
| Gradual switch \* | 34.0 (34.3) | +0.24 (+0.30) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.94 (1.00) | 4.74 (4.80) |
| Abrupt switch \* | 33.0 (33.2) | −0.04 (0.00) | 0.84 (0.83) | 0.61 (0.70) | 0.87 (0.88) | 1.00 (1.00) | 0.92 (1.00) | 4.71 (4.80) |
| Sport and sleep, fast food only \* | 41.3 (42.4) | +1.67 (+1.83) | 0.84 (0.83) | 0.61 (0.70) | 0.28 (0.27) | 1.00 (1.00) | 0.67 (0.75) | 3.45 (3.48) |
| 4 h cardio, healthy food | 27.6 (28.2) | −1.98 (−1.73) | 0.86 (0.86) | 0.49 (0.50) | 0.65 (0.63) | 1.00 (1.00) | **0.68 (0.85)** | 4.08 (4.23) |
| Strength twice a day | 30.4 (31.1) | −0.85 (−0.63) | **0.82 (0.66)** | **0.45 (0.34)** | 0.60 (0.52) | 1.00 (1.00) | 0.80 (0.78) | **4.16 (3.97)** |
| Healthy food, no sport | 39.1 (39.4) | +1.32 (+1.37) | 0.10 (0.10) | 0.10 (0.10) | 0.38 (0.37) | 1.00 (1.00) | 0.72 (0.83) | 3.70 (3.77) |
| Healthy food, no sport, 7 h sleep | 39.8 (40.3) | +1.44 (+1.51) | 0.10 (0.10) | 0.10 (0.10) | 0.36 (0.35) | 0.66 (0.66) | 0.61 (0.70) | 3.13 (3.22) |

**Day 60** (v1 gives z only): guidelines z −0.45 (v1 −0.4); couch +3.15 (+3.1, 65 kg); sport and sleep with fast food +1.94 (+2.0); healthy food without sport +1.34 (+1.4).

## Differences from v1, and proposals (for the team to decide)

The rules all pass, and most numbers are within a few hundredths of v1. These are the differences worth discussing. None was changed.

1. **The severe diet loses weight faster than v1** (20.7 kg, z −5.5 at day 21; v1 24.0 kg, z −3.85), and happiness reaches 0.07, just below the failure line (0.10). This is v1 open decision 5 ("a severe diet reaches severe thinness in about 3 avatar weeks; consider a reversible danger state before failure"). Proposal: decide on the danger state; if the loss should be slower, the setting to look at is `appetite.thin_boost_per_sd` (0.15), which makes a thin avatar hungrier, not the diet itself.
2. **Happiness is about 0.1 lower than v1 in imperfect plans** (6 h of sleep 0.72 against 0.85; 4 h cardio 0.68 against 0.85; healthy food without sport 0.72 against 0.83). Likely causes: our player waits up to half an hour to eat, so the hunger penalty (−0.05 per hour above 1.2 meals) counts more often, and with 4 h of cardio there is less room in the day for screens (the wish for screens costs −0.02 every 4 h). Proposal: Pessoa 3 checks `mood.events.hungry_per_h` and `no_screens` against the research; nothing has to change for the rules to pass.
3. **Strength twice a day** ends with more strength and fitness than v1 (0.45 and 0.82 against 0.34 and 0.66) and health 4.16 against 3.97; it is still clearly below the guidelines (4.71), so the rule passes. Our plan adds the guideline 70 minutes of cardio, which v1 may not have done. Proposal: none needed; check what v1's scenario included.
4. **Guideline strength is 0.61 against 0.70.** Our strength sessions are 1 hour (the option's fixed length) and tire fully after 45 minutes, so the last 15 minutes count for nothing. Proposal: a 45-minute strength option, when activity durations are decided.
5. **XP per real hour** with the guidelines is 169 against v1's 225, because the health bar moves once per avatar day (decision 1), so health stays at 4.5 or above for fewer hours in 21 days. The rule (short sleep never pays) passes by a wide margin. No change needed.
6. **Very hard** reaches 4.28 (v1 4.45 from 1.35). It starts higher (1.49) because of decision 7, and its fast-food craving is 0.95, which makes the healthy meals cost happiness for longer. No change needed.
