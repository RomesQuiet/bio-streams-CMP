extends Node
## Holds the avatar's current state. All numbers come from Config.
## Time (Clock) and saving (SaveGame) live in their own scripts.

signal changed

## Values that always stay between 0 and 1.
const MEASURES_0_TO_1 := ["physical", "mental", "sleep", "hunger"]

# Measures: physical, mental and sleep go from 0 to 1. Health goes from 1 to 5.
var physical: float
var mental: float
var sleep: float
var health: float
var hunger: float
## Tired means sleepy. Placeholder rule: the Clock sets this to true when the day ends.
var tired: bool
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
	hunger = Config.get_float("measures.hunger_start")
	tired = false
	xp = Config.get_float("xp.start")
	avatar_name = Config.get_string("defaults.avatar_name")
	language = Config.get_string("defaults.language")
	changed.emit()


## Everything that must be saved. Used by SaveGame (and later, maybe a server).
func to_dict() -> Dictionary:
	return {
		"physical": physical,
		"mental": mental,
		"sleep": sleep,
		"health": health,
		"hunger": hunger,
		"tired": tired,
		"xp": xp,
		"avatar_name": avatar_name,
		"language": language,
	}


## Restores values from to_dict(). Missing keys keep their current value.
func from_dict(data: Dictionary) -> void:
	physical = float(data.get("physical", physical))
	mental = float(data.get("mental", mental))
	sleep = float(data.get("sleep", sleep))
	health = float(data.get("health", health))
	hunger = float(data.get("hunger", hunger))
	tired = bool(data.get("tired", tired))
	xp = float(data.get("xp", xp))
	avatar_name = str(data.get("avatar_name", avatar_name))
	language = str(data.get("language", language))
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


## Called by the Clock as avatar time passes.
func apply_avatar_hours(hours: float, asleep: bool) -> void:
	_apply_sleep_measure(hours, asleep)
	_apply_xp(hours)
	changed.emit()


## Adds activity effects: {"value name": change per avatar hour} for this many hours.
## Called by Activities. Unknown names are reported and skipped.
func apply_effects(effects_per_hour: Dictionary, hours: float) -> void:
	for key in effects_per_hour:
		if not key in self:
			push_error("GameState: unknown effect '%s'" % key)
			continue
		var value: float = get(key) + float(effects_per_hour[key]) * hours
		if key in MEASURES_0_TO_1:
			value = clampf(value, 0.0, 1.0)
		set(key, value)
	changed.emit()


## Placeholder: the sleep measure falls while awake. (Sleeping raises it through
## the sleep activity's effects in data/activities.json.)
func _apply_sleep_measure(hours: float, asleep: bool) -> void:
	if not asleep:
		sleep = clampf(sleep - Config.get_float("sleep_activity.measure_loss_per_avatar_hour_awake") * hours, 0.0, 1.0)


## Placeholder XP rule: gain at high health, loss at low health. XP never goes below 0.
func _apply_xp(hours: float) -> void:
	var rounded_health := roundi(health)
	if rounded_health >= Config.get_int("xp.high_health_min"):
		xp += Config.get_float("xp.gain_per_avatar_hour") * hours
	elif rounded_health <= Config.get_int("xp.low_health_max"):
		xp = maxf(0.0, xp - Config.get_float("xp.loss_per_avatar_hour") * hours)


func _xp_per_level() -> float:
	return maxf(1.0, Config.get_float("xp.per_level"))


func print_state() -> void:
	print("--- GameState ---")
	print("avatar_name='%s' language=%s" % [avatar_name, language])
	print("physical=%.2f mental=%.2f sleep=%.2f" % [physical, mental, sleep])
	print("hunger=%.2f tired=%s" % [hunger, tired])
	print("health=%.2f (placeholder formula gives %.2f)" % [health, calculate_health()])
	print("xp=%.1f level=%d progress=%.2f" % [xp, level, level_progress])
