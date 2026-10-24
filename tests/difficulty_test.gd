extends SceneTree
## Starting values per difficulty (Milestone 3, Task 2). Run from the project folder:
##   Godot --headless --path . -s res://tests/difficulty_test.gd
## Prints the starting measures and health of each difficulty. Nothing is saved.

## Starting health the task asks for, and how far the result may be from it.
const EXPECTED_HEALTH := {"easy": 4.0, "normal": 3.0, "hard": 2.0, "very_hard": 1.3}
const HEALTH_TOLERANCE := 0.05
const TOLERANCE := 0.0001

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var config: Node = root.get_node("Config")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_check("before choosing, the Normal values are used", is_equal_approx(gs.health, 3.0))
	print("difficulty  physical mental sleep  weight_z  physical from body  health  level")
	for id in EXPECTED_HEALTH:
		gs.start_new_avatar("Test", "child", "female", id)
		var path: String = "health.difficulties." + id
		var body_physical: float = gs.physical_from_body(config.get_float(path + ".fitness"),
				config.get_float(path + ".muscle"), config.get_float(path + ".weight_z"))
		print("%-10s  %.2f     %.2f   %.2f   %+.1f      %.3f               %.2f    %d" % [
				id, gs.physical, gs.mental, gs.sleep, config.get_float(path + ".weight_z"),
				body_physical, gs.health, gs.health_level])
		_check("%s: starting health about %.1f" % [id, EXPECTED_HEALTH[id]],
				absf(gs.health - EXPECTED_HEALTH[id]) <= HEALTH_TOLERANCE)
		_check("%s: body states give the starting physical measure" % id, absf(body_physical - gs.physical) < TOLERANCE)
		_check("%s: mood / mood_max equals the starting mental measure" % id,
				is_equal_approx(config.get_float(path + ".mood") / config.get_float("health.mood_max"), gs.mental))
		_check("%s: no sleep debt at the start" % id, is_zero_approx(config.get_float(path + ".sleep_debt")))
	_check("Very hard is shown as level 1", gs.health_level == 1)
	var previous_fitness := INF
	for id in EXPECTED_HEALTH:
		var fitness: float = config.get_float("health.difficulties." + id + ".fitness")
		_check("%s: starting fitness is not higher than the easier difficulty" % id, fitness <= previous_fitness)
		previous_fitness = fitness

	_check("child sleep range 9 to 12 h", gs.sleep_range("child") == Vector2(9.0, 12.0))
	_check("teenager sleep range 8 to 10 h", gs.sleep_range("teenager") == Vector2(8.0, 10.0))
	# The CLAUDE.md example is worked out with p = 0.5 (it rounds 2.85 to 2.9), so p is set
	# to 0.5 just for this check.
	var p_entry: Dictionary = config._data["health"]["combine"]["p"]
	var p_config: float = p_entry["value"]
	p_entry["value"] = 0.5
	_check("example from CLAUDE.md with p = 0.5: 0.9, 0.6, 0.1 gives health 2.85",
			absf(gs.health_from_measures(0.9, 0.6, 0.1) - 2.85) < 0.01)
	p_entry["value"] = p_config

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
