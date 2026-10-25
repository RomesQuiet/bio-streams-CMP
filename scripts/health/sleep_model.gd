extends RefCounted
## Sleep (v1 Step 9, Milestone 10). Tasks 3 and 5 need the sleep debt factor d and tiredness;
## the rest of the sleep model comes in Task 6. Until then the debt is the Milestone 4
## sleep_debt. All numbers come from Config.


## Sleep debt factor d = min(1, debt / sleep.debt_ref_h), from 0 to 1.
static func debt_factor() -> float:
	return clampf(GameState.sleep_debt / Config.get_float("sleep.debt_ref_h"), 0.0, 1.0)


## Tiredness, 0 to 1 (v1 Step 9): the larger of d and (hours awake - sleep.tired_awake_from_h)
## / sleep.tired_awake_range_h.
static func tiredness() -> float:
	var awake := (GameState.hours_awake - Config.get_float("sleep.tired_awake_from_h")) \
			/ Config.get_float("sleep.tired_awake_range_h")
	return clampf(maxf(debt_factor(), awake), 0.0, 1.0)
