extends RefCounted
## Sleep (v1 Step 9, Milestone 10 Task 6). All numbers come from Config (group sleep).
## At each new avatar day (when any sleep ends, or by the 0-hour rule, which counts as 0 h):
## - debt = debt x e^(-(slept / target) x 24 / (debt_recovery_tau_days x 24 / k)) + max(0,
##   minimum - slept). The recovery time constant is body time (k applies; team, 25 Oct 2026):
##   with k = 10 a full night repays 86% of the debt, and no sleep repays nothing.
## - Sleep measure = (1 - min(1, debt / debt_ref_h)) x (1 - min(oversleep_cut_max,
##   oversleep_cut_per_h x hours above the maximum)).
## - Night quality = (slept / minimum)^night_quality_power when short, 1 in the range, and
##   1 - oversleep_cut_per_h per hour above it (at least 1 - oversleep_cut_max).
## The recommended range and target come from the age group (child or teenager).


## Minimum, maximum and target sleep (hours) for the age group: {"min", "max", "target"}.
static func recommended(age_group: String) -> Dictionary:
	var group := age_group if not age_group.is_empty() else Config.get_string("defaults.age_group")
	var path := "sleep.%s_" % group
	return {"min": Config.get_float(path + "min_h"), "max": Config.get_float(path + "max_h"),
			"target": Config.get_float(path + "target_h")}


## A new avatar day after sleeping this many hours: sleep debt, Sleep measure and night quality.
static func new_day(slept: float) -> void:
	var gs := GameState
	gs.sleep_debt = debt_after(gs.sleep_debt, slept, gs.age_group)
	gs.sleep = sleep_measure(gs.sleep_debt, oversleep(slept, gs.age_group))
	gs.night_quality = night_quality(slept, gs.age_group)
	gs.last_sleep_hours = slept
	update_tired()


## Sleep debt after a sleep of this many hours.
static func debt_after(debt: float, slept: float, age_group: String) -> float:
	var range_h := recommended(age_group)
	var tau_hours := Config.get_float("sleep.debt_recovery_tau_days") * Config.get_float("units.hours_per_day") \
			/ Config.get_float("body.k")
	var repaid := exp(-(slept / range_h["target"]) * Config.get_float("units.hours_per_day") / tau_hours)
	return debt * repaid + maxf(0.0, range_h["min"] - slept)


## Hours slept above the top of the recommended range.
static func oversleep(slept: float, age_group: String) -> float:
	return maxf(0.0, slept - recommended(age_group)["max"])


static func sleep_measure(debt: float, oversleep_hours: float) -> float:
	return (1.0 - minf(1.0, debt / Config.get_float("sleep.debt_ref_h"))) \
			* (1.0 - minf(Config.get_float("sleep.oversleep_cut_max"), Config.get_float("sleep.oversleep_cut_per_h") * oversleep_hours))


static func night_quality(slept: float, age_group: String) -> float:
	var range_h := recommended(age_group)
	if slept < range_h["min"]:
		return pow(slept / range_h["min"], Config.get_float("sleep.night_quality_power"))
	return 1.0 - minf(Config.get_float("sleep.oversleep_cut_max"), Config.get_float("sleep.oversleep_cut_per_h") * oversleep(slept, age_group))


## Sleep debt factor d = min(1, debt / sleep.debt_ref_h), from 0 to 1.
static func debt_factor() -> float:
	return clampf(GameState.sleep_debt / Config.get_float("sleep.debt_ref_h"), 0.0, 1.0)


## Tiredness, 0 to 1 (v1 Step 9): the larger of d and (hours awake - sleep.tired_awake_from_h)
## / sleep.tired_awake_range_h.
static func tiredness() -> float:
	var awake := (GameState.hours_awake - Config.get_float("sleep.tired_awake_from_h")) \
			/ Config.get_float("sleep.tired_awake_range_h")
	return clampf(maxf(debt_factor(), awake), 0.0, 1.0)


## "I'm tired" (GameState.tired) when tiredness is at least avatar_states.tired_at.
static func update_tired() -> void:
	GameState.tired = tiredness() >= Config.get_float("avatar_states.tired_at")
