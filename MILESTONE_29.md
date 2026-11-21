# Milestone 29: failure by hunger (21 Nov 2026)

Request (user, 21 Nov 2026): "don't you think there should be failure by hunger? implement it following science". Then: "keep working there, and register this work in a new milestone".

## What the game did before

A probe (`tools/probe/starve_probe.gd`, a boy of 10 who is never fed, one 10-hour sleep a day) showed:

| Difficulty | Weight lost a day | Failure | Cause shown |
|---|---|---|---|
| Easy | about 2.1 kg (z 0.0 → −2.7 in 3 days) | day 2.7 | happiness |
| Normal | about 2.2 kg | day 1.8 | happiness |
| Hard | about 2.5 kg | day 0.9 | happiness |

So an avatar that never ate did fail, but the game said it was too unhappy, not that it had gone without food. The weight loss itself is the v1 energy model (body speed k = 10).

## The science

- Most well-nourished healthy children keep a normal blood glucose for **15 to 18 hours of fasting**; after that, glucose falls and ketones rise. Older children and adolescents respond like adults (review in *Hormone Research in Paediatrics*, Karger 2024; Visser et al. 2011, *Pediatrics* 127: e1021, fasting tests in 167 healthy children, hypoglycaemia in 31%). Younger children reach hypoglycaemia sooner.
- Total starvation is usually fatal only after weeks (8 to 12 weeks in adults; longer with more body fat), but children have fewer reserves and a higher metabolic rate per kg. No study gives a lethal or safe fasting time for a child, so the failure time is ours.
- Long-term undernutrition is already in the game: severe thinness (BMI-for-age z below −3, WHO) is a danger state and failure (Milestone 10.5).

## Decisions (Claude's proposals; the team checks them)

| # | Decision |
|---|---|
| 99 | **Hours without food** (`GameState.hours_without_food`, saved) count clock time, awake and asleep, like meal timing (not sped up by k). A skipped meal is not food. Eating at least `fail.starve_meal_share` (0.3, 3 bites of 10) of a portion ends the fast. A new avatar starts at `fail.starve_start_h` (10 h: it has just woken). |
| 100 | **Starving** after `fail.starve_danger_h` (18 h) without food, from the 15 to 18 hours above: the speech bubble says "I'm starving! I haven't eaten for hours." before every other request, with the cutlery picture, and the heart and health pills flash (`HealthModel.failure_near()`). |
| 101 | **Failure by hunger** (`"hunger"`) after `fail.starve_failure_h` (36 h) without food, or when health or happiness reaches failure while the avatar is starving (the fast is what brought them down). Thinness still comes first. The failure screen says "Ana went without food for too long." with the exact cause in Details. |

All four values are placeholders in the `fail` group of `data/config.json` (owner Pessoa 1).

## Files

`data/config.json` (`fail.starve_danger_h`, `starve_failure_h`, `starve_meal_share`, `starve_start_h`), `scripts/autoload/game_state.gd`, `scripts/health/hunger.gd`, `scripts/health/health_model.gd` (`starving()`, `failure_cause()`, `failure_near()`), `scripts/health/requests.gd` (`STARVING`), `scripts/ui/main.gd`, `scripts/ui/failure_screen.gd`, `scripts/ui/ui_icons.gd`, `translations/strings.csv` (`SPEECH_STARVING`, `FAILURE_HUNGER`, `FAILURE_PHRASE_HUNGER`, `FAILURE_CAUSE_HUNGER`; the Portuguese is Claude's draft), `tests/hunger_failure_test.gd` (new).

## Checked

`tests/hunger_failure_test.gd`: all pass (17 h not starving, 18 h starving and first request, a skip does not end the fast, a few bites do not, a meal does, 35 h no failure, 36 h failure by hunger, happiness failing while starving is hunger, the save keeps the hours). With the new rule the never-fed probe fails by hunger: Easy and Normal on day 1.1 (36 hours without food), Hard on day 0.9 (happiness failed while starving).

Also run: `requests_test` (the count of request texts is now 7), `danger_test`, `food_test`, `meal_test`, `translation_test`, `measures_test`, `failure_test`, `save_test`, `interface_test`, `config_test`, `sleep_test`: all pass. `calibration_test`: no scenario reaches failure by hunger (the severe diet, which eats 1 meal in 3, still fails by thinness on day 16.0); the same three rules fail as before (`MILESTONE_27.md`); short sleep earns 59.6 XP per real hour against 212.2.

## Google Drive (21 Nov 2026, text replaced in place)

"Jury Report (EN)" and its "Summary (3 pages)": failure now also when "the avatar goes without food for too long". "Jury Report (EN)" and its "Annex", section 10: a paragraph "Adapted. Failure by hunger" (the science and the values), and Visser et al. (2011) in the sources. The deck is not changed (slide 17 describes failure in general).
