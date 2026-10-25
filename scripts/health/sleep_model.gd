extends RefCounted
## Sleep (v1 Step 9, Milestone 10). Task 3 only needs the sleep debt factor d for appetite;
## the rest of the sleep model comes in Task 6. Until then the debt is the Milestone 4
## sleep_debt. All numbers come from Config.


## Sleep debt factor d = min(1, debt / sleep.debt_ref_h), from 0 to 1.
static func debt_factor() -> float:
	return clampf(GameState.sleep_debt / Config.get_float("sleep.debt_ref_h"), 0.0, 1.0)
