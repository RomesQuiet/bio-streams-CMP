extends SceneTree
## Tests for SaveGame (Milestone 10, Task 9). Run from the project folder:
##   Godot --headless --path . -s res://tests/save_test.gd
## Plays meals, exercise, screens and a day without sleep, saves in the middle of a sleep, and
## checks that every saved value comes back: GameState (every v1 state, the hourly windows and
## the failure timers), the Clock, the running activity, the action log and Simulation's
## pending minutes. Saves of another version (Milestone 4 or earlier) and saves without the
## creation choices are ignored. Uses a test file, so the real save is never touched.

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

	# A game in the middle of a sleep, after meals, exercise and screens, with some XP.
	game_state.start_new_avatar("Test Avatar", "teenager", "male", "hard")
	_check("avatar counts as created", game_state.is_created())
	game_state.xp = 157.5
	clock.debug_speed = 600.0
	var activities: Node = root.get_node("Activities")
	for option in [["eat", "fast_food_meal"], ["exercise", "cardio"], ["exercise", "strength"], ["entertainment", "screens"],
			["entertainment", "football"], ["eat", "healthy_meal"]]:
		activities.start(option[0], option[1])
		while activities.is_running():
			clock._process(0.1)
	_check("the played hours changed the v1 states", game_state.calories_spent > 0.0 and game_state.fitness != 0.15
			and game_state.diet_quality != 0.25 and game_state.screen_minutes_today > 0.0)
	var day: int = clock.day_number
	while clock.day_number == day:
		clock._process(0.1)
	root.get_node("Activities").start("sleep", "sleep", 8.0)
	while clock.sleep_elapsed_hours < 3.0:
		clock._process(0.1)
	var saved_state: Dictionary = game_state.to_dict()
	var saved_clock: Dictionary = clock.to_dict()
	var saved_habits: Dictionary = root.get_node("Habits").to_dict()
	var saved_simulation: Dictionary = root.get_node("Simulation").to_dict()
	save_game.save_game()
	_check("save file written", FileAccess.file_exists(TEST_PATH))

	var saved_activity: Dictionary = root.get_node("Activities").to_dict()
	root.get_node("Activities").reset()
	game_state.reset()
	clock.reset()
	_check("state was cleared before loading", game_state.avatar_name != "Test Avatar")
	_check("load finds the save", save_game.load_game())
	_check("every GameState value restored (v1 states, windows, timers, XP, name)", _same(game_state.to_dict(), saved_state))
	_check("the action log restored", _same(root.get_node("Habits").to_dict(), saved_habits))
	_check("Simulation's pending minutes restored", _same(root.get_node("Simulation").to_dict(), saved_simulation))
	_check("age group, sex and difficulty restored", game_state.age_group == "teenager"
			and game_state.sex == "male" and game_state.difficulty == "hard")
	_check("time restored", _same(clock.to_dict(), saved_clock))
	_check("still asleep after loading", clock.phase == clock.Phase.SLEEPING)
	_check("sleep activity restored", _same(root.get_node("Activities").to_dict(), saved_activity) and root.get_node("Activities").is_running())

	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	_check("a broken save is ignored", not save_game.load_game())

	# A save without creation choices is ignored and the player starts a new game.
	var old_state: Dictionary = saved_state.duplicate()
	for key in ["age_group", "sex", "difficulty"]:
		old_state.erase(key)
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": save_game.SAVE_VERSION, "save_count": 5, "game_state": old_state,
			"clock": saved_clock, "activities": {}}))
	file.close()
	game_state.reset()
	_check("a save without the creation choices is ignored", not save_game.load_game())
	_check("so the creation screen is shown", not game_state.is_created())

	# Decision 6: a Milestone 4 save (version 1), even with every choice, does not load.
	_check("the save version is 2 (Milestone 10)", save_game.SAVE_VERSION == 2)
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "save_count": 9, "game_state": saved_state,
			"clock": saved_clock, "activities": {}}))
	file.close()
	game_state.reset()
	_check("a Milestone 4 save (version 1) is ignored", not save_game.load_game())
	_check("so the creation screen opens for a new avatar", not game_state.is_created())
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_check("the main screen sends the player to the creation screen", not game_state.is_created())
	main_scene.queue_free()

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
		elif a[key] is Array and b[key] is Array:
			if not _same_array(a[key], b[key]):
				print("  differs: %s %s != %s" % [key, a[key], b[key]])
				return false
		elif a[key] is float or b[key] is float:
			if not is_equal_approx(float(a[key]), float(b[key])):
				print("  differs: %s %s != %s" % [key, a[key], b[key]])
				return false
		elif a[key] != b[key]:
			print("  differs: %s %s != %s" % [key, a[key], b[key]])
			return false
	return true


## Compares two arrays of numbers or dictionaries (such as log entries) the same way.
func _same_array(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] is Dictionary and b[i] is Dictionary:
			if not _same(a[i], b[i]):
				return false
		elif (a[i] is float or a[i] is int) and (b[i] is float or b[i] is int):
			if not is_equal_approx(float(a[i]), float(b[i])):
				return false
		elif a[i] != b[i]:
			return false
	return true


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
