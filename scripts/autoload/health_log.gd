extends Node
## Debug CSV log (Milestone 4, Task 8). In debug builds, writes one line per scoring day
## to user://health_log.csv, so the team can compare the game with its spreadsheet
## simulation. Never in the published (release) game, and not while a test script runs
## (tests turn it on themselves with their own file).
## On the Mac the file is in:
##   ~/Library/Application Support/Godot/app_userdata/Plasticine Tamagotchi/health_log.csv

const LOG_PATH := "user://health_log.csv"
const SEPARATOR := ","

## The file that is written. Tests change it.
var log_path := LOG_PATH
## Debug builds only, and only when the game itself runs (a test script replaces the main loop).
var enabled := OS.is_debug_build() and Engine.get_main_loop().get_script() == null


func _ready() -> void:
	Habits.day_closed.connect(_on_day_closed)


## The column names, in order.
func header() -> PackedStringArray:
	return PackedStringArray(["scoring_day", "clock_day", "difficulty", "age_group",
			"sleep_hours", "activity_minutes", "strength_days", "screen_hours", "entertainment_hours", "kcal",
			"sleep_debt", "fitness", "strength", "overreach", "weight_kg", "weight_z", "deficit_u",
			"diet_quality", "craving", "habituation", "happiness_baseline",
			"physical", "happiness", "sleep", "target_health", "health", "health_level", "xp"])


## The values of the avatar day that just closed, in the order of header().
func row() -> PackedStringArray:
	var gs := GameState
	var totals: Dictionary = Habits.days[-1] if not Habits.days.is_empty() else Habits.day_totals(Habits.current_day)
	var values := PackedStringArray([str(totals["scoring_day"]), str(Clock.day_number), gs.difficulty, gs.age_group,
			_number(totals["sleep_hours"]), _number(totals["activity_minutes"]), str(totals["strength_days"]),
			_number(totals["screen_hours"]), _number(totals["entertainment_hours"]), _number(totals["kcal"])])
	for value in [gs.sleep_debt, gs.fitness, gs.strength, gs.overreach, gs.weight_kg, gs.weight_z, gs.deficit_u,
			gs.diet_quality, gs.craving, gs.habituation, gs.happiness_baseline,
			gs.physical, gs.happiness, gs.sleep, gs.target_health, gs.health]:
		values.append(_number(value))
	values.append_array([str(gs.health_level), _number(gs.xp)])
	return values


func _on_day_closed() -> void:
	if not enabled:
		return
	var is_new := not FileAccess.file_exists(log_path)
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
