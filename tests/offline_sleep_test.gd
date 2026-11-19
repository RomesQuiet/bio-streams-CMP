extends SceneTree
## Milestone 23: sleep continues while the game is closed or the phone is off.
##   Godot --headless --path . -s res://tests/offline_sleep_test.gd
## Prints PASS/FAIL for each check and exits with code 1 if any check fails.

const START := 1_800_000_000.0

var _failures := 0
var _clock: Node
var _away_hours := 0.0


func _process(_delta: float) -> bool:
	_clock = root.get_node("Clock")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_offline_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	_clock.slept_while_away.connect(func(h: float) -> void: _away_hours += h)
	_test_short_gap()
	_test_longer_than_sleep()
	_test_date_moved_back()
	_test_small_gap_ignored()
	_test_day_not_caught_up()
	_test_save_and_load()
	_test_same_as_open()
	_clock.now_override = -1.0
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	DirAccess.remove_absolute(save_game.save_path)
	quit(1 if _failures > 0 else 0)
	return true


func _new_sleep(hours: float) -> void:
	root.get_node("Activities").reset()
	root.get_node("Simulation").reset()
	root.get_node("GameState").reset()
	_clock.reset()
	root.get_node("GameState").hours_awake = 6.0  # Sleep v2: past the minimum wake time
	_clock.now_override = START
	_clock.start_sleep(hours)
	_away_hours = 0.0


## The device clock jumped by `seconds` before this frame (the phone was off).
func _frame_after(seconds: float) -> void:
	_clock.now_override += seconds + 0.1
	_clock._process(0.1)


func _test_short_gap() -> void:
	_new_sleep(8.0)
	_frame_after(1800.0)  # 30 real minutes = 2.5 sleep hours
	_check("30 real minutes away move the sleep 2.5 h", is_equal_approx(_away_hours, 2.5))
	_check("still sleeping", _clock.phase == _clock.Phase.SLEEPING)


func _test_longer_than_sleep() -> void:
	_new_sleep(8.0)
	_frame_after(86400.0)
	_check("a day away stops at the chosen 8 h", is_equal_approx(_clock.sleep_elapsed_hours, 8.0))
	_check("the sleep is over and waits for Wake", _clock.phase == _clock.Phase.SLEEP_OVER)


func _test_date_moved_back() -> void:
	_new_sleep(8.0)
	_frame_after(-3600.0)
	_check("a date moved back does nothing", _away_hours == 0.0 and _clock.sleep_elapsed_hours < 0.1)


func _test_small_gap_ignored() -> void:
	_new_sleep(8.0)
	_frame_after(0.5)
	_check("a gap under the minimum is ignored", _away_hours == 0.0)


func _test_day_not_caught_up() -> void:
	_new_sleep(8.0)
	_clock.stop_sleep()
	_clock.wake_up()
	var before: float = _clock.day_elapsed_hours
	_frame_after(3600.0)
	_check("the day does not move while away", _clock.day_elapsed_hours - before < 0.1)


func _test_save_and_load() -> void:
	var save_game: Node = root.get_node("SaveGame")
	_new_sleep(8.0)
	var state: Node = root.get_node("GameState")
	state.avatar_name = "Test"
	state.age_group = "child"
	state.sex = "male"
	state.difficulty = "normal"
	save_game.save_game()
	var saved := FileAccess.get_file_as_string(save_game.save_path)
	var ok := saved.find("last_seen_unix") >= 0
	# The tab is closed for an hour, then opened again.
	_clock.now_override = START + 3600.0
	if save_game.load_game():
		_clock.now_override += 0.1
		_clock._process(0.1)
	_check("the save keeps the sleep's device time", ok)
	_check("after loading, one closed hour counts as 5 h of sleep", is_equal_approx(_clock.sleep_elapsed_hours, 5.0) or absf(_clock.sleep_elapsed_hours - 5.0) < 0.05)


func _test_same_as_open() -> void:
	var state: Node = root.get_node("GameState")
	# 6 h of sleep played with the game open, frame by frame (72 real minutes).
	_new_sleep(6.0)
	while _clock.phase == _clock.Phase.SLEEPING:
		_clock.now_override += 0.5
		_clock._process(0.5)
	_clock.wake_up()
	var open_debt: float = state.sleep_debt
	var open_happiness: float = state.happiness
	# The same sleep with the phone off for all of it.
	_new_sleep(6.0)
	_frame_after(72.0 * 60.0)
	_clock.wake_up()
	_check("away and open give the same sleep debt", absf(state.sleep_debt - open_debt) < 0.001)
	_check("away and open give the same happiness", absf(state.happiness - open_happiness) < 0.01)


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
