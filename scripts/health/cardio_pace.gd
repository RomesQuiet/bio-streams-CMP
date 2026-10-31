extends RefCounted
## The avatar's running pace and how long it can keep it (Milestone 12, decisions 22 to 26).
## All numbers come from Config (group minigame; the sources are in MILESTONE_12.md).
## - Capacity (0 to 1) = fitness x body x (1 - capacity_tired_cut x tiredness). The body term
##   falls with BMI-for-age z above 0, because peak oxygen uptake per kg is lower with obesity.
## - The running cadence goes from the moderate to the vigorous threshold of the age group
##   (CADENCE-kids) as capacity rises. One tap is one stride, steps_per_tap steps.
## - Run minutes: how long the Breath bar lasts at that pace.

const SleepModel := preload("res://scripts/health/sleep_model.gd")


## How much of the avatar's running ability it can use now, 0 to 1.
static func capacity() -> float:
	var body := maxf(Config.get_float("minigame.body_floor"),
			1.0 - Config.get_float("minigame.weight_cut_per_z") * maxf(0.0, GameState.weight_z))
	return clampf(GameState.fitness * body
			* (1.0 - Config.get_float("minigame.capacity_tired_cut") * SleepModel.tiredness()), 0.0, 1.0)


## Real seconds between taps while running.
static func run_interval() -> float:
	var moderate := _moderate_cadence()
	var vigorous := Config.get_float("minigame.vigorous_cadence." + _age_group())
	return _interval(moderate + capacity() * (vigorous - moderate))


## Real seconds between taps while walking to get the breath back.
static func walk_interval() -> float:
	return _interval(Config.get_float("minigame.walk_cadence_share") * _moderate_cadence())


## Avatar minutes of running until the Breath bar is empty.
static func run_minutes() -> float:
	return Config.get_float("minigame.run_minutes_base") + Config.get_float("minigame.run_minutes_range") * capacity()


static func _interval(cadence: float) -> float:
	return Config.get_float("minigame.steps_per_tap") * Config.get_float("units.seconds_per_minute") / cadence


static func _moderate_cadence() -> float:
	return Config.get_float("minigame.moderate_cadence." + _age_group())


static func _age_group() -> String:
	return GameState.age_group if not GameState.age_group.is_empty() else Config.get_string("defaults.age_group")
