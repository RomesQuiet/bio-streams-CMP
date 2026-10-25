extends SceneTree
## Tests for SaveGame. Run from the project folder:
##   Godot --headless --path . -s res://tests/save_test.gd
## Uses a test file, so the real save is never touched.

const TEST_PATH := "user://test_save.json"

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	var game_state: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	save_game.save_path = TEST_PATH
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("Activities").reset()
	game_state.reset()
	clock.reset()

	# Before the avatar is created nothing is saved automatically.
	save_game.auto_save_enabled = true
	save_game._auto_save()
	save_game.auto_save_enabled = false
	_check("no autosave before the avatar is created", not FileAccess.file_exists(TEST_PATH))

	# A game in the middle of a sleep, with the creation choices and some XP.
	game_state.avatar_name = "Test Avatar"
	game_state.age_group = "teenager"
	game_state.sex = "male"
	game_state.difficulty = "hard"
	_check("avatar counts as created", game_state.is_created())
	game_state.xp = 157.5
	game_state.physical = 0.8
	game_state.muscle = 0.7
	game_state.calories_spent = 1234.0
	clock.debug_speed = 600.0
	var day: int = clock.day_number
	while clock.day_number == day:
		clock._process(0.1)
	root.get_node("Activities").start("sleep", "sleep", 8.0)
	while clock.sleep_elapsed_hours < 3.0:
		clock._process(0.1)
	var saved_state: Dictionary = game_state.to_dict()
	var saved_clock: Dictionary = clock.to_dict()
	save_game.save_game()
	_check("save file written", FileAccess.file_exists(TEST_PATH))

	var saved_activity: Dictionary = root.get_node("Activities").to_dict()
	root.get_node("Activities").reset()
	game_state.reset()
	clock.reset()
	_check("state was cleared before loading", game_state.avatar_name != "Test Avatar")
	_check("load finds the save", save_game.load_game())
	_check("measures, XP and name restored", _same(game_state.to_dict(), saved_state))
	_check("age group, sex and difficulty restored", game_state.age_group == "teenager"
			and game_state.sex == "male" and game_state.difficulty == "hard")
	_check("time restored", _same(clock.to_dict(), saved_clock))
	_check("still asleep after loading", clock.phase == clock.Phase.SLEEPING)
	_check("sleep activity restored", _same(root.get_node("Activities").to_dict(), saved_activity) and root.get_node("Activities").is_running())

	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	_check("a broken save is ignored", not save_game.load_game())

	# A save from Milestones 1 and 2 has no creation choices: it is ignored and
	# the player starts a new game.
	var old_state: Dictionary = saved_state.duplicate()
	for key in ["age_group", "sex", "difficulty"]:
		old_state.erase(key)
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "save_count": 5, "game_state": old_state,
			"clock": saved_clock, "activities": {}}))
	file.close()
	game_state.reset()
	_check("a save without the creation choices is ignored", not save_game.load_game())
	_check("so the creation screen is shown", not game_state.is_created())

	# A Milestone 3 save file: mood 0 to 1, usual levels as scores, no rootedness, a log
	# without scoring days. It loads, and the new values use the Normal starting values.
	var m3_state: Dictionary = saved_state.duplicate(true)
	m3_state.erase("rootedness")
	m3_state.erase("habit_costs")
	m3_state.erase("habit_cost_total")
	m3_state["mood"] = 0.4
	m3_state["usual_habits"] = {"sleep": 0.5, "activity": 0.25, "strength": 0.25, "screens": 0.5}
	var m3_habits := {"avatar_hours_total": 30.0, "entries": [{"type": "cardio", "start_total": 20.0, "day": 2,
			"start_minute": 600.0, "hours": 1.0}], "scores": {}, "last_sleep_hours": 9.0}
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "save_count": 7, "game_state": m3_state,
			"clock": saved_clock, "activities": {}, "habits": m3_habits}))
	file.close()
	root.get_node("Habits").reset()
	game_state.reset()
	_check("a Milestone 3 save still loads", save_game.load_game())
	var config: Node = root.get_node("Config")
	_check("its mood is scaled to 0 to 100", is_equal_approx(game_state.mood, 40.0))
	_check("rootedness and usual levels use the Normal starting values",
			is_equal_approx(game_state.rootedness["sleep"], config.get_float("health_m4.difficulties.normal.start_R"))
			and is_equal_approx(game_state.usual_habits["screens"], config.get_float("health_m4.difficulties.normal.start_H.screens")))
	var entry: Dictionary = root.get_node("Habits").entries[0]
	_check("its log entries count in the current scoring day, with intensity and calories",
			entry["scoring_day"] == 0 and entry["intensity"] == "moderate_vigorous" and entry["kcal"] > 0.0)
	_check("its choices are kept", game_state.difficulty == "hard" and game_state.age_group == "teenager")

	DirAccess.remove_absolute(TEST_PATH)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Compares two dictionaries, allowing tiny float differences from JSON.
func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.keys().size() != b.keys().size():
		return false
	for key in a:
		if not b.has(key):
			return false
		if a[key] is Dictionary and b[key] is Dictionary:
			if not _same(a[key], b[key]):
				return false
		elif a[key] is float or b[key] is float:
			if not is_equal_approx(float(a[key]), float(b[key])):
				print("  differs: %s %s != %s" % [key, a[key], b[key]])
				return false
		elif a[key] != b[key]:
			print("  differs: %s %s != %s" % [key, a[key], b[key]])
			return false
	return true


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
