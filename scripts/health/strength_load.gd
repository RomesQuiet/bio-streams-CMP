extends RefCounted
## How many repetitions and sets suit the avatar (Milestone 13, decisions 31 to 34).
## All numbers come from Config (group minigame; the sources are in MILESTONE_13.md).
## - Capacity (0 to 1) = strength x body x (1 - capacity_tired_cut x tiredness). The body term
##   falls with BMI-for-age z above 0, because strength per kg is lower with obesity.
## - Repetitions and sets go from the beginners' numbers of the AAP to the later ones as
##   capacity rises.

const SleepModel := preload("res://scripts/health/sleep_model.gd")


## How much of the avatar's strength it can use now, 0 to 1.
static func capacity() -> float:
	var body := maxf(Config.get_float("minigame.body_floor"),
			1.0 - Config.get_float("minigame.strength_weight_cut_per_z") * maxf(0.0, GameState.weight_z))
	return clampf(GameState.strength * body
			* (1.0 - Config.get_float("minigame.capacity_tired_cut") * SleepModel.tiredness()), 0.0, 1.0)


static func reps_per_set() -> int:
	return _between("minigame.reps_min", "minigame.reps_max")


static func sets_goal() -> int:
	return _between("minigame.sets_min", "minigame.sets_max")


static func _between(lowest: String, highest: String) -> int:
	var low := Config.get_float(lowest)
	return roundi(low + capacity() * (Config.get_float(highest) - low))
