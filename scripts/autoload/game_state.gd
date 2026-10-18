extends Node
## Holds the avatar's current state. All numbers come from Config.
## Time (Clock) and saving (SaveGame) live in their own scripts.

signal changed

# Measures: physical, mental and sleep go from 0 to 1. Health goes from 1 to 5.
var physical: float
var mental: float
var sleep: float
var health: float
var fatigue: float
var hunger: float
var xp: float
var avatar_name: String
var language: String

## Level shown next to the XP bar. Starts at 0.
var level: int:
	get:
		return floori(xp / _xp_per_level())

## How full the XP bar is inside the current level (0 to 1).
var level_progress: float:
	get:
		return fmod(xp, _xp_per_level()) / _xp_per_level()


func _ready() -> void:
	reset()
	if OS.is_debug_build():
		print_state()


## Sets every value to its start value from Config (new avatar).
func reset() -> void:
	physical = Config.get_float("measures.physical_start")
	mental = Config.get_float("measures.mental_start")
	sleep = Config.get_float("measures.sleep_start")
	health = Config.get_float("measures.health_start")
	fatigue = Config.get_float("measures.fatigue_start")
	hunger = Config.get_float("measures.hunger_start")
	xp = Config.get_float("xp.start")
	avatar_name = Config.get_string("defaults.avatar_name")
	language = Config.get_string("defaults.language")
	changed.emit()


## Placeholder health formula: weighted average of the three measures,
## mapped from 0..1 to health_min..health_max. Weights are in config.
func calculate_health() -> float:
	var w_physical := Config.get_float("health_weights.physical")
	var w_mental := Config.get_float("health_weights.mental")
	var w_sleep := Config.get_float("health_weights.sleep")
	var total_weight := w_physical + w_mental + w_sleep
	if total_weight <= 0.0:
		push_error("GameState: health weights must add up to more than 0")
		return health
	var average := (physical * w_physical + mental * w_mental + sleep * w_sleep) / total_weight
	var health_min := Config.get_float("measures.health_min")
	var health_max := Config.get_float("measures.health_max")
	return lerpf(health_min, health_max, clampf(average, 0.0, 1.0))


func update_health() -> void:
	health = calculate_health()
	changed.emit()


## Placeholder XP rule, called by the Clock as avatar time passes:
## gain at high health, loss at low health. XP never goes below 0.
func apply_avatar_hours(hours: float) -> void:
	var rounded_health := roundi(health)
	if rounded_health >= Config.get_int("xp.high_health_min"):
		xp += Config.get_float("xp.gain_per_avatar_hour") * hours
	elif rounded_health <= Config.get_int("xp.low_health_max"):
		xp = maxf(0.0, xp - Config.get_float("xp.loss_per_avatar_hour") * hours)
	changed.emit()


func _xp_per_level() -> float:
	return maxf(1.0, Config.get_float("xp.per_level"))


func print_state() -> void:
	print("--- GameState ---")
	print("avatar_name='%s' language=%s" % [avatar_name, language])
	print("physical=%.2f mental=%.2f sleep=%.2f" % [physical, mental, sleep])
	print("fatigue=%.2f hunger=%.2f" % [fatigue, hunger])
	print("health=%.2f (placeholder formula gives %.2f)" % [health, calculate_health()])
	print("xp=%.1f level=%d progress=%.2f" % [xp, level, level_progress])
