extends Node
## Debug CSV log (Milestone 4 Task 8; Milestone 10 Task 11). In debug builds, writes one line
## per avatar hour to user://health_log.csv with every state of the v1 health system, so the
## team can compare the game with its spreadsheet simulation (decided in Milestone 10 Task 0).
## Never in the published (release) game, and not while a test script runs (tests turn it on
## themselves with their own file). If the file has another header (an older version of the
## log), it is started again.
## On the Mac the file is in:
##   ~/Library/Application Support/Godot/app_userdata/Plasticine Tamagotchi/health_log.csv

const LOG_PATH := "user://health_log.csv"
const SEPARATOR := ","
const Energy := preload("res://scripts/health/energy.gd")
const Training := preload("res://scripts/health/training.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")
const Happiness := preload("res://scripts/health/happiness.gd")
const BodySize := preload("res://scripts/health/body_size.gd")

## The file that is written. Tests change it.
var log_path := LOG_PATH
## Debug builds only, and only when the game itself runs (a test script replaces the main loop).
var enabled := OS.is_debug_build() and Engine.get_main_loop().get_script() == null

## The last avatar hour written (hours since the avatar was created); -1 = none yet.
var _last_hour := -1
## The file whose header was checked in this session (checked once, then lines are appended).
var _checked_path := ""


func _ready() -> void:
	Simulation.stepped.connect(_on_stepped)


## The column names, in order.
func header() -> PackedStringArray:
	return PackedStringArray(["avatar_hour", "clock_day", "time", "asleep", "activity",
			"difficulty", "age_group", "sex",
			"body_age_months", "height_cm", "weight_kg", "z", "weight_score",
			"hunger_kcal", "hours_since_meal", "kcal_eaten_24h", "kcal_spent_24h", "deficit_u", "calories_spent",
			"fitness", "strength", "cardio_recovery", "strength_recovery", "exercise_min_today", "capacity_min", "overreach",
			"sleep_debt", "tiredness", "hours_awake", "night_quality",
			"diet_quality", "craving", "habituation", "fun", "screen_excess", "happiness_baseline",
			"physical", "happiness", "sleep", "target_health", "health", "health_level", "xp",
			"health_low_hours", "happiness_low_hours", "risk_index", "disease_damage"])


## The values now, in the order of header().
func row() -> PackedStringArray:
	var gs := GameState
	var values := PackedStringArray([str(floori(gs.sim_hours)), str(Clock.day_number), Clock.clock_text(),
			str(Clock.phase == Clock.Phase.SLEEPING), Activities.current_option, gs.difficulty, gs.age_group, gs.sex])
	for value in [gs.body_age_months, gs.height_m * Config.get_float("units.cm_per_m"), gs.weight_kg, gs.weight_z,
			BodySize.weight_score(gs.weight_z),
			gs.hunger, gs.hours_since_meal, Energy.window_total("eaten"), Energy.window_total("spent"), gs.deficit_u, gs.calories_spent,
			gs.fitness, gs.strength, gs.cardio_recovery, gs.strength_recovery, gs.exercise_minutes_today, Training.capacity_min(), gs.overreach,
			gs.sleep_debt, SleepModel.tiredness(), gs.hours_awake, gs.night_quality,
			gs.diet_quality, gs.craving, gs.habituation, Happiness.fun(), Happiness.screen_excess(), gs.happiness_baseline,
			gs.physical, gs.happiness, gs.sleep, gs.target_health, gs.health]:
		values.append(_number(value))
	values.append_array([str(gs.health_level), _number(gs.xp)])
	for value in [gs.health_low_hours, gs.happiness_low_hours, gs.risk_index, gs.disease_damage]:
		values.append(_number(value))
	return values


## After every step: one line each time a new avatar hour is complete.
func _on_stepped(_hours: float, _asleep: bool) -> void:
	if not enabled or not GameState.is_created():
		return
	var hour := floori(GameState.sim_hours)
	if hour < _last_hour:
		_last_hour = -1  # A new avatar: its hours start again from 0.
	if hour > _last_hour:
		_last_hour = hour
		write_line()


## Writes the current values as one line (and the header first, in a new file).
func write_line() -> void:
	var is_new := not FileAccess.file_exists(log_path)
	if not is_new and _checked_path != log_path:
		var existing := FileAccess.open(log_path, FileAccess.READ)
		is_new = existing == null or existing.get_line() != SEPARATOR.join(header())
	_checked_path = log_path
	var file := FileAccess.open(log_path, FileAccess.WRITE if is_new else FileAccess.READ_WRITE)
	if file == null:
		push_error("HealthLog: could not write %s (error %d)" % [log_path, FileAccess.get_open_error()])
		return
	file.seek_end()
	if is_new:
		file.store_line(SEPARATOR.join(header()))
	file.store_line(SEPARATOR.join(row()))
	file.close()


func _number(value: float) -> String:
	return "%.4f" % value
