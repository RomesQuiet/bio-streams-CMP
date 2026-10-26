extends SceneTree
## Tests for sleep (Milestone 10, Task 6; v1 Step 9). Run from the project folder:
##   Godot --headless --path . -s res://tests/sleep_test.gd
## Checks that a full night repays 86% of the sleep debt and no sleep repays nothing, that 6 h
## every night settles near 4.4 h of debt, the Sleep measure (debt and oversleep), night
## quality, tiredness and the "I'm tired" state, the starting values per difficulty, and that
## loading a save never runs a new day again. Uses a test save path.

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
	_test_start()
	_test_in_play_and_load(save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## debt = debt x e^(-(slept / target) x 24 / 12) + max(0, minimum - slept) (child: 9 to 12 h,
## target 10.5; 12 = 5 real days / k).
func _test_debt() -> void:
	var after_full: float = sleep_model.debt_after(4.0, 10.5, "child")
	print("  child, 4 h of debt, a full night (10.5 h): %.2f h left (%.1f%% repaid)" % [after_full, (1.0 - after_full / 4.0) * 100.0])
	_check("a full night repays 86% of the debt", absf(after_full - 4.0 * exp(-2.0)) < TOLERANCE)
	_check("no sleep repays nothing and adds the minimum (9 h)", is_equal_approx(sleep_model.debt_after(4.0, 0.0, "child"), 13.0))
	_check("sleep inside the range adds no debt", is_zero_approx(sleep_model.debt_after(0.0, 9.0, "child")))
	_check("teenager: 6 h adds 2 h (minimum 8 h)", is_equal_approx(sleep_model.debt_after(0.0, 6.0, "teenager"), 2.0))
	var debt := 0.0
	for night in 30:
		debt = sleep_model.debt_after(debt, 6.0, "child")
	print("  child sleeping 6 h every night: debt settles at %.2f h (v1: 4.4)" % debt)
	_check("6 h every night settles near 4.4 h of debt", absf(debt - 4.4) < 0.05)


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


## Tiredness = max(d, (hours awake - 15) / 4); tired at 0.5 or more.
func _test_tiredness() -> void:
	var gs := _new_avatar("easy")
	gs.sleep_debt = 0.0
	gs.hours_awake = 10.0
	_check("rested and 10 h awake: tiredness 0", is_zero_approx(sleep_model.tiredness()))
	gs.hours_awake = 17.0
	_check("17 h awake: tiredness 0.5, tired", is_equal_approx(sleep_model.tiredness(), 0.5) and _tired())
	gs.hours_awake = 30.0
	_check("30 h awake: tiredness 1", is_equal_approx(sleep_model.tiredness(), 1.0))
	gs.hours_awake = 0.0
	gs.sleep_debt = 6.0
	_check("6 h of debt (d 0.75): tiredness 0.75, tired", is_equal_approx(sleep_model.tiredness(), 0.75) and _tired())


## Starting debt per difficulty gives the v1 starting Sleep measure: Easy 0.75, Normal 0.50,
## Hard 0.30, Very hard 0.10.
func _test_start() -> void:
	for pair in [["easy", 0.75], ["normal", 0.5], ["hard", 0.3], ["very_hard", 0.1]]:
		var gs := _new_avatar(pair[0])
		_check("%s starts with Sleep %.2f" % pair, absf(gs.sleep - pair[1]) < TOLERANCE)


## A real night: the debt and the Sleep measure change when the sleep ends, and loading a
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
	var expected: float = sleep_model.debt_after(debt_before, 10.5, "child")
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
