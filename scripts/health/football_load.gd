extends RefCounted
## What the avatar's body can do in the football minigame (Milestone 14, decisions 43 and 44).
## All numbers come from Config (group minigame.football; every one is a placeholder, see
## MILESTONE_14.md). Capacity is the same as in cardio: fitness, weight and sleepiness.
## - Speed: how fast the avatar crosses the field, slower while it jogs.
## - Free distance: how far a team-mate must be from any opponent to be free. A fitter avatar
##   reads the game better, so more passes are good.
## - Shot range: how far from goal a shot is good.

const CardioPace := preload("res://scripts/health/cardio_pace.gd")


## Field units per real second.
static func speed(jogging: bool) -> float:
	var running := _between("speed_min", "speed_range", CardioPace.capacity())
	return running * Config.get_float("minigame.football.jog_share") if jogging else running


static func free_distance() -> float:
	return _between("free_distance_max", "free_distance_cut", -CardioPace.capacity())


static func shot_range() -> float:
	return _between("shot_range_min", "shot_range_gain", CardioPace.capacity())


## Avatar minutes of steady play until the Breath bar is empty.
static func play_minutes() -> float:
	return CardioPace.run_minutes()


static func _between(base: String, change: String, share: float) -> float:
	return Config.get_float("minigame.football." + base) + share * Config.get_float("minigame.football." + change)
