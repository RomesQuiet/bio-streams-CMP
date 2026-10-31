extends SceneTree
## Tests for the cardio minigame (Milestone 12, Tasks 2 to 4). Run from the project folder:
##   Godot --headless --path . -s res://tests/minigame_test.gd
## The avatar's pace and how long it can run. Nothing is saved.

const TOLERANCE := 0.001

## Loaded at run time: the script uses the autoloads, which do not exist yet when this test
## script is compiled.
var pace: GDScript
var gs: Node
var _failures := 0


func _process(_delta: float) -> bool:
	pace = load("res://scripts/health/cardio_pace.gd")
	gs = root.get_node("GameState")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_test_pace()

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Task 2: capacity comes from fitness, weight and sleepiness. Each one on its own moves it.
func _test_pace() -> void:
	gs.start_new_avatar("Test", "child", "male", "normal")
	# Normal: fitness 0.4, z +1.2, 4 h of debt (tiredness 0.5).
	_check("Normal capacity = 0.4 x (1 - 0.16 x 1.2) x (1 - 0.3 x 0.5)", absf(pace.capacity() - 0.4 * 0.808 * 0.85) < TOLERANCE)
	print("difficulty  capacity  cadence interval  walk interval  run minutes")
	for id in ["easy", "normal", "hard", "very_hard"]:
		gs.start_new_avatar("Test", "child", "male", id)
		print("%-10s  %.3f     %.2f s            %.2f s          %.0f" % [id, pace.capacity(), pace.run_interval(),
				pace.walk_interval(), pace.run_minutes()])
	gs.start_new_avatar("Test", "child", "male", "normal")
	_set_body(0.8, 0.0, 0.0)
	var fit: float = pace.capacity()
	var fit_interval: float = pace.run_interval()
	var fit_minutes: float = pace.run_minutes()
	_check("no weight or sleep cut: capacity = fitness", absf(fit - 0.8) < TOLERANCE)
	_set_body(0.4, 0.0, 0.0)
	_check("less fit: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)
	_set_body(0.8, 2.0, 0.0)
	_check("obesity (z +2): capacity x 0.68, as in the study", absf(pace.capacity() - 0.8 * 0.68) < TOLERANCE)
	_check("heavier: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)
	_set_body(0.8, -1.5, 0.0)
	_check("below z 0 weight does not change capacity", absf(pace.capacity() - 0.8) < TOLERANCE)
	_set_body(0.8, 10.0, 0.0)
	_check("the weight term stops at its floor", absf(pace.capacity() - 0.8 * 0.4) < TOLERANCE)
	_set_body(0.8, 0.0, 8.0)
	_check("sleepier: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)

	# The cadences of CADENCE-kids: one tap is two steps.
	_set_body(0.0, 0.0, 0.0)
	_check("capacity 0: the child's moderate threshold, 115 steps/min", absf(pace.run_interval() - 120.0 / 115.0) < TOLERANCE)
	_check("capacity 0: the Breath bar lasts 10 avatar minutes", absf(pace.run_minutes() - 10.0) < TOLERANCE)
	_set_body(1.0, 0.0, 0.0)
	_check("capacity 1: the child's vigorous threshold, 130 steps/min", absf(pace.run_interval() - 120.0 / 130.0) < TOLERANCE)
	_check("capacity 1: 120 avatar minutes, the v1 tiring time", is_equal_approx(pace.run_minutes(), root.get_node("Config").get_float("train.cardio_tire_min")))
	_check("walking is slower than the slowest running", pace.walk_interval() > 120.0 / 115.0)
	gs.age_group = "teenager"
	_set_body(0.0, 0.0, 0.0)
	_check("a teenager: moderate threshold 110 steps/min", absf(pace.run_interval() - 120.0 / 110.0) < TOLERANCE)
	_set_body(1.0, 0.0, 0.0)
	_check("a teenager: vigorous threshold 125 steps/min", absf(pace.run_interval() - 120.0 / 125.0) < TOLERANCE)
	gs.age_group = "child"


func _set_body(fitness: float, z: float, debt: float) -> void:
	gs.fitness = fitness
	gs.weight_z = z
	gs.sleep_debt = debt
	gs.hours_awake = 0.0


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
