extends SceneTree
## Tests for the debug CSV log (Milestone 4, Task 8). Run from the project folder:
##   Godot --headless --path . -s res://tests/health_log_test.gd
## Writes to a test file, so the real user://health_log.csv is never touched.

const TEST_LOG := "user://test_health_log.csv"

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var log: Node = root.get_node("HealthLog")
	var habits: Node = root.get_node("Habits")
	var gs: Node = root.get_node("GameState")
	_check("the log is off while a test script runs", not log.enabled)
	root.get_node("Activities").reset()
	habits.reset()
	gs.start_new_avatar("Test", "teenager", "male", "hard")

	var real_before := _file_size(log.LOG_PATH)
	habits.end_scoring_day(9.0)
	_check("nothing is written to the real log while it is off", _file_size(log.LOG_PATH) == real_before)

	log.log_path = TEST_LOG
	log.enabled = true
	DirAccess.remove_absolute(TEST_LOG)
	habits.add_entry("cardio", 1.0)
	habits.add_entry("screens", 2.0)
	habits.end_scoring_day(8.5)
	habits.add_entry("strength", 0.5)
	habits.end_scoring_day(0.0)
	log.enabled = false

	var lines := FileAccess.get_file_as_string(TEST_LOG).strip_edges().split("\n")
	print(lines[0])
	print(lines[1])
	_check("one header line and one line per scoring day", lines.size() == 3)
	var header := lines[0].split(",")
	var first := lines[1].split(",")
	var second := lines[2].split(",")
	_check("every line has the same number of columns", first.size() == header.size() and second.size() == header.size())
	var col := func(row: PackedStringArray, name: String) -> String: return row[header.find(name)]
	_check("the scoring day and difficulty are written", col.call(first, "scoring_day") == "1" and col.call(first, "difficulty") == "hard")
	_check("the day's totals are written (8.5 h sleep, 60 min, 2 h screens)", float(col.call(first, "sleep_hours")) == 8.5
			and float(col.call(first, "activity_minutes")) == 60.0 and float(col.call(first, "screen_hours")) == 2.0)
	_check("the second line is the 0-hour day with the last values", float(col.call(second, "sleep_hours")) == 0.0
			and absf(float(col.call(second, "health")) - gs.health) < 0.0001 and absf(float(col.call(second, "mood")) - gs.mood) < 0.0001)
	_check("H and R of every habit are written", header.has("H_sleep") and header.has("R_screens") and header.has("A_activity"))
	DirAccess.remove_absolute(TEST_LOG)

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Size of a file in bytes, or -1 if it does not exist.
func _file_size(path: String) -> int:
	return FileAccess.get_file_as_bytes(path).size() if FileAccess.file_exists(path) else -1


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
