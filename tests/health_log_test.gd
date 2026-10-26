extends SceneTree
## Tests for the debug CSV log (Milestone 4 Task 8; Milestone 10 Task 11). Run from the project folder:
##   Godot --headless --path . -s res://tests/health_log_test.gd
## Plays 5 avatar hours (with a meal and cardio) and checks one line per avatar hour with every
## v1 state. Writes to a test file, so the real user://health_log.csv is never touched.

const TEST_LOG := "user://test_health_log.csv"

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var log: Node = root.get_node("HealthLog")
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	_check("the log is off while a test script runs", not log.enabled)
	activities.reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "teenager", "male", "hard")

	var real_before := _file_size(log.LOG_PATH)
	_play_hours(clock, 1.0)
	_check("nothing is written to the real log while it is off", _file_size(log.LOG_PATH) == real_before)

	# An old log with another header is started again.
	var old := FileAccess.open(TEST_LOG, FileAccess.WRITE)
	old.store_line("scoring_day,clock_day,difficulty")
	old.store_line("1,1,hard")
	old.close()
	log.log_path = TEST_LOG
	log.enabled = true
	activities.start("eat", "healthy_meal")
	while activities.is_running():
		clock._process(0.05)
	activities.start("exercise", "cardio")
	while activities.is_running():
		clock._process(0.05)
	_play_hours(clock, 5.0 - clock.day_elapsed_hours + 1.0)
	log.enabled = false

	var lines := FileAccess.get_file_as_string(TEST_LOG).strip_edges().split("\n")
	print(lines[0])
	print(lines[-1])
	var header := lines[0].split(",")
	_check("an old log with another header is started again", header[0] == "avatar_hour")
	var hours: Array = []
	for i in range(1, lines.size()):
		hours.append(int(lines[i].split(",")[0]))
	print("  avatar hours written: %s" % str(hours))
	_check("one line per avatar hour, in order, none twice", hours == range(hours[0], hours[0] + hours.size()))
	_check("every line has the same number of columns", range(1, lines.size()).all(
			func(i: int) -> bool: return lines[i].split(",").size() == header.size()))
	var needed := ["weight_kg", "z", "hunger_kcal", "deficit_u", "fitness", "strength", "overreach", "sleep_debt", "tiredness",
			"diet_quality", "craving", "habituation", "fun", "happiness", "physical", "sleep", "target_health", "health", "xp",
			"health_low_hours", "risk_index", "disease_damage", "kcal_eaten_24h", "capacity_min"]
	var missing := needed.filter(func(column: String) -> bool: return not header.has(column))
	if not missing.is_empty():
		print("  missing columns: %s" % str(missing))
	_check("every v1 state is a column", missing.is_empty())
	var last := lines[-1].split(",")
	var col := func(name: String) -> float: return float(last[header.find(name)])
	_check("the last line holds the current values", absf(col.call("weight_kg") - gs.weight_kg) < 0.01
			and absf(col.call("happiness") - gs.happiness) < 0.01 and absf(col.call("fitness") - gs.fitness) < 0.001)
	var meal_line := lines[2].split(",")
	_check("the meal shows in the kcal eaten in the last 24 h", float(meal_line[header.find("kcal_eaten_24h")]) > 0.0)
	DirAccess.remove_absolute(TEST_LOG)

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _play_hours(clock: Node, hours: float) -> void:
	var end: float = clock.day_elapsed_hours + hours
	clock.debug_speed = 600.0
	while clock.day_elapsed_hours < end:
		clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(end - clock.day_elapsed_hours, false) / 600.0 + 1e-6))
	root.get_node("Simulation").flush()


## Size of a file in bytes, or -1 if it does not exist.
func _file_size(path: String) -> int:
	return FileAccess.get_file_as_bytes(path).size() if FileAccess.file_exists(path) else -1


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
