extends SceneTree
## Starting values per difficulty (Milestone 3, Task 2; Milestone 10 Task 8). Run from the project folder:
##   Godot --headless --path . -s res://tests/difficulty_test.gd
## Prints the starting measures and health of each difficulty for the boy of 10 of the v1
## document and checks them against the v1 'Difficulty starts' table. Nothing is saved.

## v1 starting Physical, Sleep and health (boy of 10). Very hard health is about 1.48, not 1.35,
## because its starting happiness is 0.30 (decision 7, user, 25 Oct 2026).
const EXPECTED := {
	"easy": {"physical": 0.71, "sleep": 0.75, "health": 3.94},
	"normal": {"physical": 0.44, "sleep": 0.50, "health": 2.91},
	"hard": {"physical": 0.14, "sleep": 0.30, "health": 1.95},
	"very_hard": {"physical": 0.03, "sleep": 0.10, "health": 1.48},
}
## The v1 table rounds to 2 decimals.
const ROUNDING := 0.011
const TOLERANCE := 0.0001

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var config: Node = root.get_node("Config")
	var health_model: GDScript = load("res://scripts/health/health_model.gd")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_check("before choosing, the health equals its target (Normal values)", is_equal_approx(gs.health, gs.target_health))
	print("difficulty  physical happiness sleep  z      fitness strength  Q    C    health  level")
	for id in EXPECTED:
		gs.start_new_avatar("Test", "child", "male", id)
		var path: String = "health.difficulties." + id
		print("%-10s  %.3f    %.2f      %.2f   %+.1f   %.2f    %.2f      %.2f %.2f %.3f   %d" % [
				id, gs.physical, gs.happiness, gs.sleep, gs.weight_z, gs.fitness, gs.strength,
				gs.diet_quality, gs.craving, gs.health, gs.health_level])
		_check("%s: starting Physical %.2f (v1)" % [id, EXPECTED[id]["physical"]], absf(gs.physical - EXPECTED[id]["physical"]) <= ROUNDING)
		_check("%s: starting Sleep %.2f (v1)" % [id, EXPECTED[id]["sleep"]], absf(gs.sleep - EXPECTED[id]["sleep"]) <= ROUNDING)
		_check("%s: starting health %.2f (v1)" % [id, EXPECTED[id]["health"]], absf(gs.health - EXPECTED[id]["health"]) <= ROUNDING)
		_check("%s: v1 starting happiness, Q, C and A" % id,
				is_equal_approx(gs.happiness, config.get_float(path + ".happiness"))
				and is_equal_approx(gs.diet_quality, config.get_float(path + ".Q"))
				and is_equal_approx(gs.craving, config.get_float(path + ".C"))
				and is_equal_approx(gs.habituation, config.get_float(path + ".A")))
	_check("Very hard is shown as level 1", gs.health_level == 1)
	var previous := INF
	for id in EXPECTED:
		_check("%s: starting health is lower than the easier difficulty" % id, EXPECTED[id]["health"] < previous)
		previous = EXPECTED[id]["health"]

	# v1 Step 11 check: Physical 0.9, Happiness 0.6, Sleep 0.1 give 2.85 with p = 0.5.
	_check("v1 example: 0.9, 0.6, 0.1 gives health 2.85", absf(health_model.target_health(0.9, 0.6, 0.1) - 2.85) < 0.01)
	_check("the arithmetic mean (p 1) would give 3.13", absf(_with_p(config, 1.0, health_model) - 3.13) < 0.01)
	_check("the geometric mean (p 0) would give 2.51", absf(_with_p(config, 0.0, health_model) - 2.51) < 0.01)

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## The v1 example with another p, set just for this check.
func _with_p(config: Node, p: float, health_model: GDScript) -> float:
	var entry: Dictionary = config._data["health"]["combine"]["p"]
	var saved: float = entry["value"]
	entry["value"] = p
	var result: float = health_model.target_health(0.9, 0.6, 0.1)
	entry["value"] = saved
	return result


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
