extends SceneTree
## Starting values per difficulty (Milestone 3, Task 2; Milestone 10). Run from the project folder:
##   Godot --headless --path . -s res://tests/difficulty_test.gd
## Prints the starting measures and health of each difficulty. Nothing is saved.
## Until Task 8 the starting Physical measure is the Milestone 4 value (health_m4.difficulties);
## happiness, sleep debt, fitness, strength, z, Q, C and A come from the v1 table.

## Starting health expected, and how far the result may be from it. Very hard is about 1.5,
## not 1.3, because its starting happiness is 0.30 (decision 7, user, 25 Oct 2026).
const EXPECTED_HEALTH := {"easy": 4.0, "normal": 3.0, "hard": 2.0, "very_hard": 1.5}
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
	var sleep_model: GDScript = load("res://scripts/health/sleep_model.gd")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_check("before choosing, the Normal values are used", is_equal_approx(gs.health, 3.0))
	print("difficulty  physical happiness sleep  z      fitness strength  Q    C    health  level")
	for id in EXPECTED_HEALTH:
		gs.start_new_avatar("Test", "child", "female", id)
		var path: String = "health.difficulties." + id
		print("%-10s  %.2f     %.2f      %.2f   %+.1f   %.2f    %.2f      %.2f %.2f %.2f    %d" % [
				id, gs.physical, gs.happiness, gs.sleep, gs.weight_z, gs.fitness, gs.strength,
				gs.diet_quality, gs.craving, gs.health, gs.health_level])
		_check("%s: starting health about %.1f" % [id, EXPECTED_HEALTH[id]],
				absf(gs.health - EXPECTED_HEALTH[id]) <= HEALTH_TOLERANCE)
		_check("%s: v1 starting happiness, Q, C and A" % id,
				is_equal_approx(gs.happiness, config.get_float(path + ".happiness"))
				and is_equal_approx(gs.diet_quality, config.get_float(path + ".Q"))
				and is_equal_approx(gs.craving, config.get_float(path + ".C"))
				and is_equal_approx(gs.habituation, config.get_float(path + ".A")))
		_check("%s: Sleep comes from the starting sleep debt" % id,
				absf(gs.sleep - sleep_model.sleep_measure(config.get_float(path + ".sleep_debt"), 0.0)) < TOLERANCE)
	_check("Very hard is shown as level 1", gs.health_level == 1)
	var previous_fitness := INF
	for id in EXPECTED_HEALTH:
		var fitness: float = config.get_float("health.difficulties." + id + ".fitness")
		_check("%s: starting fitness is not higher than the easier difficulty" % id, fitness <= previous_fitness)
		previous_fitness = fitness

	_check("child sleep range 9 to 12 h", sleep_model.recommended("child")["min"] == 9.0 and sleep_model.recommended("child")["max"] == 12.0)
	_check("teenager sleep range 8 to 10 h", sleep_model.recommended("teenager")["min"] == 8.0 and sleep_model.recommended("teenager")["max"] == 10.0)
	# The CLAUDE.md example is worked out with p = 0.5 (it rounds 2.85 to 2.9), so p is set
	# to 0.5 just for this check.
	var p_entry: Dictionary = config._data["health_m4"]["combine"]["p"]
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
