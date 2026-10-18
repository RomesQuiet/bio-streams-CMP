extends SceneTree
## Tests for the Clock time rules. Run from the project folder:
##   Godot --headless --path . -s res://tests/clock_test.gd
## Prints PASS/FAIL for each check and exits with code 1 if any check fails.

const STEP_SECONDS := 0.1

var _failures := 0


func _process(_delta: float) -> bool:
	var clock: Node = root.get_node("Clock")
	_test_conversion(clock)
	_test_full_cycle(clock)
	_test_stop_sleep_early(clock)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
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
	_run_until(clock, clock.Phase.BEDTIME)
	_check("day ends at 21:00", clock.clock_text() == "21:00")
	_check("avatar is tired at bedtime", root.get_node("GameState").tired)
	clock._process(STEP_SECONDS)
	_check("time waits at bedtime (no automatic sleep)", clock.phase == clock.Phase.BEDTIME and clock.clock_text() == "21:00")
	clock.start_sleep(8.0)
	_run_until(clock, clock.Phase.SLEEP_OVER)
	_check("8 h sleep ends at 05:00", clock.clock_text() == "05:00")
	clock._process(STEP_SECONDS)
	_check("time waits for the wake button", clock.clock_text() == "05:00")
	clock.wake_up()
	_check("next day is 16 h", is_equal_approx(clock.day_length_hours, 16.0))
	_run_until(clock, clock.Phase.BEDTIME)
	_check("bedtime stays at 21:00", clock.clock_text() == "21:00")


func _test_stop_sleep_early(clock: Node) -> void:
	clock.start_sleep(10.0)
	while clock.sleep_elapsed_hours < 5.0:
		clock._process(STEP_SECONDS)
	clock.stop_sleep()
	var slept: float = clock.sleep_elapsed_hours
	clock.wake_up()
	_check("stopping early uses the hours slept", is_equal_approx(clock.day_length_hours, 24.0 - slept))


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
