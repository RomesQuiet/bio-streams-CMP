extends SceneTree
## Tests for the Clock time rules. Run from the project folder:
##   Godot --headless --path . -s res://tests/clock_test.gd
## Prints PASS/FAIL for each check and exits with code 1 if any check fails.

const STEP_SECONDS := 0.1

var _failures := 0


func _process(_delta: float) -> bool:
	var clock: Node = root.get_node("Clock")
	# Never touch the real save: use a test file, and start from a new game.
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("Activities").reset()
	root.get_node("GameState").reset()
	clock.reset()
	_test_conversion(clock)
	_test_full_cycle(clock)
	_test_stop_sleep_early(clock)
	_test_five_hours_sleep(clock)
	_test_nap(clock)
	_test_daylight(clock)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	DirAccess.remove_absolute(save_game.save_path)
	quit(1 if _failures > 0 else 0)
	return true


func _test_conversion(clock: Node) -> void:
	# Sleep hours -> next day hours (CLAUDE.md: day_hours = 14 + (10 - sleep_hours)).
	for pair in [[0.0, 24.0], [5.0, 19.0], [8.0, 16.0], [10.0, 14.0], [12.0, 12.0]]:
		_check("sleep %s h gives a %s h day" % pair, is_equal_approx(clock.day_hours_after_sleep(pair[0]), pair[1]))
	# Real minutes for avatar hours.
	_check("14 h day = 30 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(14.0, false), 30.0 * 60.0))
	_check("16 h day = 34.29 real min", absf(clock.avatar_hours_to_real_seconds(16.0, false) / 60.0 - 34.2857) < 0.001)
	_check("19 h day = 40.71 real min", absf(clock.avatar_hours_to_real_seconds(19.0, false) / 60.0 - 40.7143) < 0.001)
	_check("10 h sleep = 120 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(10.0, true), 120.0 * 60.0))
	_check("8 h sleep = 96 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(8.0, true), 96.0 * 60.0))
	_check("back conversion", is_equal_approx(clock.real_seconds_to_avatar_hours(96.0 * 60.0, true), 8.0))


func _test_full_cycle(clock: Node) -> void:
	clock.debug_speed = 600.0
	_check("first day starts at 07:00", clock.clock_text() == "07:00")
	_check("first day is 14 h", is_equal_approx(clock.day_length_hours, 14.0))
	clock.set_paused(true)
	clock._process(STEP_SECONDS)
	_check("pause stops time", clock.clock_text() == "07:00")
	clock.set_paused(false)
	var game_state: Node = root.get_node("GameState")
	var sleep_at_start: float = game_state.sleep
	_run_until(clock, clock.Phase.BEDTIME)
	_check("day ends at 21:00", clock.clock_text() == "21:00")
	_check("avatar is tired at bedtime", game_state.tired)
	var sleep_at_bedtime: float = game_state.sleep
	_check("sleep measure falls during the day", sleep_at_bedtime < sleep_at_start)
	clock._process(STEP_SECONDS)
	_check("time waits at bedtime (no automatic sleep)", clock.phase == clock.Phase.BEDTIME and clock.clock_text() == "21:00")
	root.get_node("Activities").start("sleep", "sleep", 8.0)
	_run_until(clock, clock.Phase.SLEEP_OVER)
	_check("8 h sleep ends at 05:00", clock.clock_text() == "05:00")
	_check("sleep measure rises during sleep", game_state.sleep > sleep_at_bedtime)
	_check("avatar is not tired after sleep", not game_state.tired)
	clock._process(STEP_SECONDS)
	_check("time waits for the wake button", clock.clock_text() == "05:00")
	clock.wake_up()
	_check("next day is 16 h", is_equal_approx(clock.day_length_hours, 16.0))
	_run_until(clock, clock.Phase.BEDTIME)
	_check("bedtime stays at 21:00", clock.clock_text() == "21:00")


func _test_stop_sleep_early(clock: Node) -> void:
	root.get_node("Activities").start("sleep", "sleep", 10.0)
	while clock.sleep_elapsed_hours < 5.0:
		clock._process(STEP_SECONDS)
	root.get_node("Activities").stop()
	var slept: float = clock.sleep_elapsed_hours
	clock.wake_up()
	_check("stopping early uses the hours slept", is_equal_approx(clock.day_length_hours, 24.0 - slept))


func _test_five_hours_sleep(clock: Node) -> void:
	_run_until(clock, clock.Phase.BEDTIME)
	root.get_node("Activities").start("sleep", "sleep", 5.0)
	_run_until(clock, clock.Phase.SLEEP_OVER)
	clock.wake_up()
	_check("5 h sleep gives a 19 h day", is_equal_approx(clock.day_length_hours, 19.0))


## Milestone 2, Task 2: a 1 h nap at 14:00 starts a 23 h day that ends at 14:00
## the next day (24 h in total), and a normal 10 h sleep still gives a 14 h day.
func _test_nap(clock: Node) -> void:
	var activities: Node = root.get_node("Activities")
	root.get_node("GameState").reset()
	clock.reset()
	# Exactly one avatar hour per step, so the clock lands on 14:00.
	clock.debug_speed = clock.avatar_hours_to_real_seconds(1.0, false) / 0.5
	for i in 7:
		clock._process(0.5)
	_check("clock reaches 14:00 during the day", _near_minute(clock, 14 * 60))
	_check("nap starts during the day", activities.start("sleep", "sleep", 1.0))
	_run_until(clock, clock.Phase.SLEEP_OVER)
	_check("1 h nap ends at 15:00", _near_minute(clock, 15 * 60))
	clock.wake_up()
	_check("1 h nap starts a 23 h day", is_equal_approx(clock.day_length_hours, 23.0))
	clock.debug_speed = 600.0
	_run_until(clock, clock.Phase.BEDTIME)
	_check("that day ends at 14:00 the next day (24 h after the nap started)", _near_minute(clock, 14 * 60))
	activities.start("sleep", "sleep", 10.0)
	_run_until(clock, clock.Phase.SLEEP_OVER)
	clock.wake_up()
	_check("a normal 10 h sleep still gives a 14 h day", is_equal_approx(clock.day_length_hours, 14.0))


## Task 2.5: the sky looks like day from 07:00 to 19:00 and like night otherwise,
## with a 1 h dawn and dusk. It depends only on the clock, not on sleeping.
func _test_daylight(clock: Node) -> void:
	for pair in [[12.0, 1.0], [0.0, 0.0], [3.0, 0.0], [6.0, 0.0], [7.0, 0.5], [8.0, 1.0], [18.0, 1.0], [19.0, 0.5], [20.0, 0.0]]:
		_check("sky at %02d:00 is %.1f light" % pair, is_equal_approx(clock.daylight_amount(pair[0] * 60.0), pair[1]))
	# A nap at noon still shows a day sky.
	var activities: Node = root.get_node("Activities")
	root.get_node("GameState").reset()
	clock.reset()
	clock.debug_speed = clock.avatar_hours_to_real_seconds(1.0, false) / 0.5
	for i in 5:
		clock._process(0.5)
	activities.start("sleep", "sleep", 1.0)
	clock.debug_speed = 60.0
	clock._process(0.1)
	_check("napping at noon: avatar asleep, sky still day", clock.phase == clock.Phase.SLEEPING and clock.daylight_amount() == 1.0)
	activities.stop()


func _near_minute(clock: Node, minute: float) -> bool:
	return absf(clock.minute_of_day - minute) < 0.01


func _run_until(clock: Node, phase: int) -> void:
	for i in 100000:
		if clock.phase == phase:
			return
		clock._process(STEP_SECONDS)
	_check("reached phase %d" % phase, false)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
