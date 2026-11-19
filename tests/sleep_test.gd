extends SceneTree
## Tests for sleep (Milestone 10, Task 6; v1 Step 9; sleep model v2, Milestone 27,
## documentation/sleep_model_v2.md). Run from the project folder:
##   Godot --headless --path . -s res://tests/sleep_test.gd
## Checks the dynamic sleep need and debt (a full night repays 86%, 6 h every night settles near
## 4.4 h of debt as in v1, a nap pays only its own hours), the Sleep measure, night quality,
## tiredness, sleepiness and "I'm tired" (never just after waking), the minimum wake time, the
## starting values per difficulty, and that loading a save never runs a new day again.

const TOLERANCE := 0.001

## Loaded at run time: the script uses the autoloads, which do not exist yet when this test
## script is compiled.
var sleep_model: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	sleep_model = load("res://scripts/health/sleep_model.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_debt()
	_test_measure_and_quality()
	_test_tiredness()
	_test_min_wake()
	_test_start()
	_test_in_play_and_load(save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Sleep v2: the need grows by minimum / 24 per hour, sleep pays 1 h per hour, need above a normal
## day's becomes debt, and sleep repays the debt by v1's factor (86% for a whole night at 10.5 h).
func _test_debt() -> void:
	var gs := _new_avatar("easy")
	gs.sleep_debt = 4.0
	gs.sleep_need = 5.25
	_run(10.5, true)
	print("  child, 4 h of debt, a full night (10.5 h): %.2f h left (%.1f%% repaid)" % [gs.sleep_debt, (1.0 - gs.sleep_debt / 4.0) * 100.0])
	_check("a full night repays 86% of the debt", absf(gs.sleep_debt - 4.0 * exp(-2.0)) < TOLERANCE)
	_check("...and pays today's need back to 0", is_zero_approx(gs.sleep_need))
	gs.sleep_debt = 0.0
	_run(15.0, false)
	_check("15 h awake builds a normal day's need (5.6 h), not debt",
			absf(gs.sleep_need - 9.0 * 15.0 / 24.0) < TOLERANCE and is_zero_approx(gs.sleep_debt))
	_run(9.0, true)
	_check("9 h asleep pays it back: no debt", is_zero_approx(gs.sleep_need) and is_zero_approx(gs.sleep_debt))
	_run(18.0, false)
	_check("3 h awake past a normal day: the late need (1.1 h) counts as debt at once",
			absf(sleep_model.effective_debt() - 3.0 * 9.0 / 24.0) < TOLERANCE and is_zero_approx(gs.sleep_debt))
	_check("...and lowers the Sleep measure", absf(gs.sleep - sleep_model.sleep_measure(3.0 * 9.0 / 24.0, 0.0)) < TOLERANCE)
	sleep_model.new_day(0.0)
	_check("the 0-hour rule converts nothing: the avatar keeps its need and stays tired", gs.sleep_need > 6.0 and _tired())
	gs.sleep_need = 0.0
	gs.sleep_debt = 0.0
	gs.sleep_need = 2.0
	_run(1.0, true)
	_check("a 1-hour nap pays 1 h of need minus the hour's own need",
			absf(gs.sleep_need - (2.0 + 9.0 / 24.0 - 1.0)) < TOLERANCE and is_zero_approx(gs.sleep_debt))
	sleep_model.new_day(1.0)
	_check("on waking, the need it left unpaid (1.4 h) becomes debt (v1 added 8 h for a 1-hour nap)",
			absf(gs.sleep_debt - (2.0 + 9.0 / 24.0 - 1.0)) < TOLERANCE and is_zero_approx(gs.sleep_need))
	gs.sleep_debt = 0.0
	gs.sleep_need = 0.0
	for night in 30:
		_run(18.0, false)
		_run(6.0, true)
		sleep_model.new_day(6.0)
	print("  child sleeping 6 h every night: debt settles at %.2f h on waking (v1: 4.4)" % gs.sleep_debt)
	_check("6 h every night settles at 4.4 h of debt (as v1)", absf(gs.sleep_debt - 4.4) < 0.05)
	_check("...and the Sleep measure follows the debt every step", absf(gs.sleep - sleep_model.sleep_measure(gs.sleep_debt, 0.0)) < TOLERANCE)


## Runs the sleep model for this many hours in 5-minute steps.
func _run(hours: float, asleep: bool) -> void:
	var steps := roundi(hours * 12.0)
	for i in steps:
		sleep_model.step(1.0 / 12.0, asleep)


## Sleep = (1 - min(1, debt / 8)) x (1 - min(0.3, 0.1 x oversleep)); night quality.
func _test_measure_and_quality() -> void:
	_check("no debt, no oversleep: Sleep 1", is_equal_approx(sleep_model.sleep_measure(0.0, 0.0), 1.0))
	_check("4 h of debt: Sleep 0.5", is_equal_approx(sleep_model.sleep_measure(4.0, 0.0), 0.5))
	_check("8 h of debt or more: Sleep 0", is_zero_approx(sleep_model.sleep_measure(10.0, 0.0)))
	_check("teenager sleeping 12 h: 2 h of oversleep, Sleep x 0.8",
			is_equal_approx(sleep_model.sleep_measure(0.0, sleep_model.oversleep(12.0, "teenager")), 0.8))
	_check("oversleep costs at most 30%", is_equal_approx(sleep_model.sleep_measure(0.0, 6.0), 0.7))
	_check("night quality: 1 inside the range", is_equal_approx(sleep_model.night_quality(10.0, "child"), 1.0))
	_check("night quality: (6 / 9)^2 = 0.44 for 6 h (child)", absf(sleep_model.night_quality(6.0, "child") - 4.0 / 9.0) < TOLERANCE)
	_check("night quality: 0.9 for 1 h of oversleep", is_equal_approx(sleep_model.night_quality(13.0, "child"), 0.9))
	_check("night quality: at least 0.7", is_equal_approx(sleep_model.night_quality(20.0, "teenager"), 0.7))


## Tiredness for performance = max(d, (hours awake - 15) / 4) (v1, unchanged). "I'm tired" comes
## from sleepiness = need / day need + 0.5 x d >= 1 (sleep v2).
func _test_tiredness() -> void:
	var gs := _new_avatar("easy")
	gs.sleep_debt = 0.0
	gs.hours_awake = 10.0
	_check("rested and 10 h awake: tiredness 0", is_zero_approx(sleep_model.tiredness()))
	gs.hours_awake = 17.0
	_check("17 h awake: tiredness 0.5", is_equal_approx(sleep_model.tiredness(), 0.5))
	gs.hours_awake = 30.0
	_check("30 h awake: tiredness 1", is_equal_approx(sleep_model.tiredness(), 1.0))
	gs.hours_awake = 0.0
	gs.sleep_debt = 6.0
	_check("6 h of debt (d 0.75): tiredness 0.75", is_equal_approx(sleep_model.tiredness(), 0.75))
	gs.sleep_debt = 4.0
	gs.sleep_need = 0.0
	_check("Normal's 4 h of debt just after waking: not tired (sleep v2)", not _tired())
	gs.sleep_need = 0.75 * sleep_model.day_need("child")
	_check("4 h of debt: tired at 75% of a normal day's need", _tired())
	gs.sleep_debt = 0.0
	gs.sleep_need = 0.9 * sleep_model.day_need("child")
	_check("no debt: not tired before the normal bedtime", not _tired())
	gs.sleep_need = sleep_model.day_need("child")
	_check("no debt: tired at the normal bedtime", _tired())


## Minimum wake time (sleep v2): 6 h after any sleep, 0.5 h less per hour of debt, at least 3 h;
## or at any time when tired.
func _test_min_wake() -> void:
	var gs := _new_avatar("normal")
	gs.sleep_need = 0.0
	for case in [[0.0, 6.0], [2.0, 5.0], [4.0, 4.0], [10.0, 3.0]]:
		gs.sleep_debt = case[0]
		gs.hours_awake = case[1] - 0.1
		var before: bool = sleep_model.can_sleep()
		gs.hours_awake = case[1]
		_check("%.0f h of debt: can sleep after %.0f h awake, not before" % case, not before and sleep_model.can_sleep())
	gs.sleep_debt = 0.0
	gs.hours_awake = 1.0
	gs.sleep_need = sleep_model.day_need("child")
	_check("when tired it can sleep at any time", sleep_model.can_sleep())


## Starting debt per difficulty gives the v1 starting Sleep measure: Easy 0.75, Normal 0.50,
## Hard 0.30, Very hard 0.10.
func _test_start() -> void:
	for pair in [["easy", 0.75], ["normal", 0.5], ["hard", 0.3], ["very_hard", 0.1]]:
		var gs := _new_avatar(pair[0])
		_check("%s starts with Sleep %.2f" % pair, absf(gs.sleep - pair[1]) < TOLERANCE)


## A real night: the debt is repaid during the sleep (86% for 10.5 h), and loading a
## save made after the sleep does not run that new day a second time.
func _test_in_play_and_load(save_game: Node) -> void:
	var gs := _new_avatar("normal")
	var clock: Node = root.get_node("Clock")
	var debt_before: float = gs.sleep_debt
	clock.debug_speed = 600.0
	while clock.day_elapsed_hours < clock.day_length_hours - 0.01:
		clock._process(0.1)
	root.get_node("Activities").start("sleep", "sleep", 10.5)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	var expected: float = debt_before * exp(-2.0)
	_check("after a 10.5 h night the debt follows the formula", absf(gs.sleep_debt - expected) < TOLERANCE)
	_check("...and so does the Sleep measure", absf(gs.sleep - sleep_model.sleep_measure(expected, 0.0)) < TOLERANCE)
	_check("after a full night the avatar is not tired", not gs.tired)
	var saved: Dictionary = gs.to_dict()
	save_game.save_game()
	gs.sleep_debt = 99.0
	_check("load finds the save (made while waiting for the wake button)", save_game.load_game())
	_check("loading does not run the new day again (same debt and Sleep)",
			is_equal_approx(gs.sleep_debt, saved["sleep_debt"]) and is_equal_approx(gs.sleep, saved["sleep"]))
	clock.wake_up()


func _tired() -> bool:
	sleep_model.update_tired()
	return root.get_node("GameState").tired


func _new_avatar(difficulty: String) -> Node:
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	var gs: Node = root.get_node("GameState")
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", "child", "female", difficulty)
	return gs


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
