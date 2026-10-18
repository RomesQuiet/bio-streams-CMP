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
	game_state.reset()
	clock.reset()

	# A game in the middle of a sleep, with a name and some XP.
	game_state.avatar_name = "Test Avatar"
	game_state.xp = 157.5
	game_state.physical = 0.8
	clock.debug_speed = 600.0
	while clock.phase != clock.Phase.BEDTIME:
		clock._process(0.1)
	clock.start_sleep(8.0)
	while clock.sleep_elapsed_hours < 3.0:
		clock._process(0.1)
	var saved_state: Dictionary = game_state.to_dict()
	var saved_clock: Dictionary = clock.to_dict()
	save_game.save_game()
	_check("save file written", FileAccess.file_exists(TEST_PATH))

	game_state.reset()
	clock.reset()
	_check("state was cleared before loading", game_state.avatar_name != "Test Avatar")
	_check("load finds the save", save_game.load_game())
	_check("measures, XP and name restored", _same(game_state.to_dict(), saved_state))
	_check("time restored", _same(clock.to_dict(), saved_clock))
	_check("still asleep after loading", clock.phase == clock.Phase.SLEEPING)

	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	_check("a broken save is ignored", not save_game.load_game())

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
		if a[key] is float or b[key] is float:
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
