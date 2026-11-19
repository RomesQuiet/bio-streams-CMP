extends RefCounted
## Sleep (v1 Step 9, Milestone 10 Task 6; sleep model v2, Milestone 27,
## documentation/sleep_model_v2.md). All numbers come from Config (group sleep).
## Every step (step()), so the debt and the Sleep measure move while playing:
## - Sleep need N (GameState.sleep_need, hours): + minimum / 24 per avatar hour, awake or asleep
##   (the need is per 24 h, AASM 2016); - 1 per hour asleep; never below 0.
## - N above what a normal day builds (day_need(): minimum x (24 - minimum) / 24) is sleep that
##   is late (wakefulness beyond the critical duration; Van Dongen 2003): it counts as debt at once
##   (effective_debt()), and it stays need, so sleep pays it back hour for hour.
## - During sleep the debt is repaid: x e^(-(hours / target) x 24 / (debt_recovery_tau_days x 24
##   / k)) per step, so a whole night at the target repays 86% (v1, k = 10).
## - Sleep measure = (1 - min(1, debt / debt_ref_h)) x (1 - min(oversleep_cut_max,
##   oversleep_cut_per_h x hours above the maximum in the last sleep)).
## - When a sleep ends, the need it did not pay becomes debt at once (a short night shows in the
##   morning). The 0-hour rule converts nothing; the need keeps growing.
## Over each cycle this is exactly v1's debt x factor + max(0, minimum - slept) (6 h every night
## settles at 4.4 h of debt), but the debt is repaid hour by hour, a day without sleep counts as
## its need grows (not 9 h at once), and a nap only adds the need it leaves.
## At each new avatar day (when any sleep ends, or by the 0-hour rule, which counts as 0 h):
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
	# Sleep v2: the need still unpaid when the avatar wakes is sleep it missed: debt at once, so a
	# short night shows in the morning. Over a cycle this is exactly v1's + max(0, minimum -
	# slept). The 0-hour rule (no sleep) converts nothing: the need keeps growing, its late part
	# already counts as debt (effective_debt()), and the avatar stays tired.
	if slept > 0.0:
		gs.sleep_debt += gs.sleep_need
		gs.sleep_need = 0.0
	gs.sleep = sleep_measure(effective_debt(), oversleep(slept, gs.age_group))
	gs.night_quality = night_quality(slept, gs.age_group)
	gs.last_sleep_hours = slept
	update_tired()


## Sleep v2, every step: the sleep need, the debt it leaves, the repayment during sleep and the
## Sleep measure.
static func step(hours: float, asleep: bool) -> void:
	var gs := GameState
	var range_h := recommended(gs.age_group)
	var per_day := Config.get_float("units.hours_per_day")
	gs.sleep_need += range_h["min"] / per_day * hours
	if asleep:
		gs.sleep_need = maxf(0.0, gs.sleep_need - hours)
		gs.sleep_debt *= repaid_share(hours, gs.age_group)
	gs.sleep = sleep_measure(effective_debt(), oversleep(gs.last_sleep_hours, gs.age_group))


## The debt that counts now (sleep v2): the chronic debt plus today's need above a normal day's,
## which is sleep already late (wakefulness beyond the critical duration, Van Dongen 2003). Used by
## the Sleep measure, the debt factor d, the minimum wake time and the debt shown in the panel.
static func effective_debt() -> float:
	return GameState.sleep_debt + maxf(0.0, GameState.sleep_need - day_need(GameState.age_group))


## The share of the debt left after this many hours asleep (v1's recovery, hour by hour).
static func repaid_share(hours: float, age_group: String) -> float:
	var tau_hours := Config.get_float("sleep.debt_recovery_tau_days") * Config.get_float("units.hours_per_day") \
			/ Config.get_float("body.k")
	return exp(-(hours / recommended(age_group)["target"]) * Config.get_float("units.hours_per_day") / tau_hours)


## The sleep need a normal day builds: minimum x (24 - minimum) / 24 (child 5.6 h, teenager 5.3 h).
## Above it the need is late.
static func day_need(age_group: String) -> float:
	var per_day := Config.get_float("units.hours_per_day")
	var minimum: float = recommended(age_group)["min"]
	return minimum * (per_day - minimum) / per_day


## Sleepiness (sleep v2, 4.2): today's need / day_need + debt_sleepiness_weight x d. "I'm tired"
## at 1 or more: at the normal bedtime without debt, earlier with debt, never just after waking.
static func sleepiness() -> float:
	return GameState.sleep_need / day_need(GameState.age_group) \
			+ Config.get_float("sleep.debt_sleepiness_weight") * debt_factor()


## Minimum wake time (sleep v2, 4.3): the hours awake after any sleep before the avatar can sleep
## again, shortened by the debt.
static func min_wake_hours() -> float:
	return maxf(Config.get_float("sleep.min_wake_floor_h"), Config.get_float("sleep.can_sleep_awake_h")
			- Config.get_float("sleep.min_wake_cut_per_debt_h") * effective_debt())


## Whether the avatar can fall asleep now: after the minimum wake time, or when it is tired.
static func can_sleep() -> bool:
	var awake := GameState.hours_awake
	var limit := min_wake_hours()
	return awake >= limit or is_equal_approx(awake, limit) or sleepiness() >= 1.0


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
	return clampf(effective_debt() / Config.get_float("sleep.debt_ref_h"), 0.0, 1.0)


## Tiredness, 0 to 1 (v1 Step 9): the larger of d and (hours awake - sleep.tired_awake_from_h)
## / sleep.tired_awake_range_h.
static func tiredness() -> float:
	var awake := (GameState.hours_awake - Config.get_float("sleep.tired_awake_from_h")) \
			/ Config.get_float("sleep.tired_awake_range_h")
	return clampf(maxf(debt_factor(), awake), 0.0, 1.0)


## "I'm tired" (GameState.tired) when sleepiness is 1 or more (sleep v2). Tiredness (above) still
## lowers performance, as in v1.
static func update_tired() -> void:
	GameState.tired = sleepiness() >= 1.0
