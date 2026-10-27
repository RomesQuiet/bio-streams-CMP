extends SceneTree
## Tests for the danger state of severe thinness (Milestone 10.5, Task 3; team review of 27 Oct
## 2026 and decision 11). Run from the project folder:
##   Godot --headless --path . -s res://tests/danger_test.gd
## Below BMI-for-age z fail.danger_z (-3, WHO severe thinness) the avatar is in a danger state:
## it looks thin and ill and the health bar warns. The state ends only when z is back at -3 or
## above. Failure when it lasts fail.danger_hours (72 avatar hours) or when z reaches
## fail.danger_failure_z (-4). The risk index gets a thinness term that mirrors the obesity
## term. Nothing is saved.

const TOLERANCE := 0.0001

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this test
## script is compiled.
var health_model: GDScript
var risk: GDScript
var avatar_states: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	health_model = load("res://scripts/health/health_model.gd")
	risk = load("res://scripts/health/risk.gd")
	avatar_states = load("res://scripts/health/avatar_states.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var config: Node = root.get_node("Config")
	var gs: Node = root.get_node("GameState")

	_test_danger_state(gs, config)
	_test_danger_failure(gs, config)
	_test_thinness_risk(gs, config)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## The danger state starts below -3 and ends only when z is back at -3 or above (decision 11).
func _test_danger_state(gs: Node, config: Node) -> void:
	var line: float = config.get_float("fail.danger_z")
	_new_avatar(gs)
	_check("a new Normal avatar (z +1.2) is not in danger", not health_model.in_danger() and is_zero_approx(gs.danger_hours))
	gs.weight_z = line + 0.1
	_steps(5.0)
	var states: Dictionary = avatar_states.current()
	_check("z -2.9: thin, but not in danger and not ill", states["thin"] and not states["ill"] and is_zero_approx(gs.danger_hours))
	gs.weight_z = line - 0.1
	_steps(10.0)
	states = avatar_states.current()
	_check("z -3.1: in danger, thin and ill", health_model.in_danger() and states["thin"] and states["ill"])
	_check("...and the danger hours count up (10 h)", absf(gs.danger_hours - 10.0) < TOLERANCE)
	gs.weight_z = line - 0.05
	_steps(1.0)
	_check("gaining weight but still below -3: the danger state goes on (11 h)", absf(gs.danger_hours - 11.0) < TOLERANCE)
	gs.weight_z = line
	_steps(1.0)
	_check("back at z -3: the danger state ends", not health_model.in_danger() and is_zero_approx(gs.danger_hours)
			and not avatar_states.current()["ill"])


## Failure after 72 hours in danger, or at once when z reaches -4.
func _test_danger_failure(gs: Node, config: Node) -> void:
	var hours: float = config.get_float("fail.danger_hours")
	_new_avatar(gs)
	gs.weight_z = config.get_float("fail.danger_z") - 0.5
	_steps(hours - 1.0)
	_check("71 hours in danger: no failure yet", not gs.is_at_failure() and health_model.failure_cause().is_empty())
	_steps(1.0)
	_check("72 hours in danger: failure, because of severe thinness", gs.is_at_failure() and health_model.failure_cause() == "thinness")
	gs.weight_z = config.get_float("fail.danger_z") + 0.1
	_steps(1.0)
	_check("z back above -3: the danger state and the failure end (the failure effect is not decided)",
			not gs.is_at_failure() and is_zero_approx(gs.danger_hours))
	_new_avatar(gs)
	gs.weight_z = config.get_float("fail.danger_failure_z")
	_steps(1.0)
	_check("z -4: failure at once (1 hour in danger)", gs.is_at_failure() and health_model.failure_cause() == "thinness")
	_new_avatar(gs)
	_check("a new avatar has no failure cause", health_model.failure_cause().is_empty())


## R gets thin_weight x clamp((thin_from - z) / thin_range): 0 at z -2, 0.2 at -3, 0.4 at -4
## and below. The obesity term still starts at z +1.
func _test_thinness_risk(gs: Node, config: Node) -> void:
	_new_avatar(gs)
	var at := func(z: float) -> float:
		gs.weight_z = z
		return risk.index()
	var base: float = at.call(-2.0)
	_check("no thinness risk at z -2 or above (z 0 gives the same R)", absf(at.call(0.0) - base) < TOLERANCE)
	_check("z -3: +0.20", absf(at.call(-3.0) - base - 0.2) < TOLERANCE)
	_check("z -4: +0.40 (the full thinness weight)", absf(at.call(-4.0) - base - config.get_float("risk.thin_weight")) < TOLERANCE)
	_check("z -5: still +0.40 (clamped)", absf(at.call(-5.0) - base - 0.4) < TOLERANCE)
	_check("the obesity term mirrors it: z +3 adds 0.40 over z +1", absf(at.call(3.0) - at.call(1.0) - 0.4) < TOLERANCE)


## Runs the failure timers for this many avatar hours, in 1-hour steps (z is set by the test).
func _steps(hours: float) -> void:
	for i in roundi(hours):
		health_model.step(1.0, false)


func _new_avatar(gs: Node) -> void:
	gs.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
