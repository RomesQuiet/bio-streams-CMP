extends SceneTree
## Milestone 29: starving and failure by hunger. Run from the project folder:
##   Godot --headless --path . -s res://tests/hunger_failure_test.gd
## No food for fail.starve_danger_h (18) avatar hours: starving (the bubble says so, the health
## bar warns). No food for fail.starve_failure_h (36): failure "hunger". Health or happiness
## failing while starving is failure by hunger too. A skipped meal is not food; a meal of at least
## fail.starve_meal_share of a portion ends the fast. Nothing is saved.

var hunger: GDScript
var health_model: GDScript
var requests: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	hunger = load("res://scripts/health/hunger.gd")
	health_model = load("res://scripts/health/health_model.gd")
	requests = load("res://scripts/health/requests.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_hunger_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var config: Node = root.get_node("Config")
	var gs: Node = root.get_node("GameState")

	_new_avatar(gs)
	var start: float = config.get_float("fail.starve_start_h")
	var danger: float = config.get_float("fail.starve_danger_h")
	var limit: float = config.get_float("fail.starve_failure_h")
	_check("a new avatar has gone %d h without food (a night) and is not starving" % roundi(start),
			is_equal_approx(gs.hours_without_food, start) and not health_model.starving())
	_steps(danger - start - 1.0)
	_check("17 h without food: not starving yet", not health_model.starving())
	_steps(1.0)
	_check("18 h without food: starving", health_model.starving())
	_check("...the health bar warns", health_model.failure_near())
	_check("...and the avatar says it is starving (before every other request)", requests.current() == "starving")
	gs.hunger = 10000.0
	gs.hours_since_meal = 10.0
	hunger.skip()
	_check("skipping a meal does not end the fast", health_model.starving())
	hunger.eat("healthy_meal", config.get_float("fail.starve_meal_share") * 0.5)
	_check("a few bites (less than the share) do not end it", health_model.starving())
	hunger.eat("healthy_meal", 1.0)
	_check("a real meal ends it", is_zero_approx(gs.hours_without_food) and not health_model.starving())

	_new_avatar(gs)
	_steps(limit - start - 1.0)
	_check("35 h without food: no failure yet", health_model.failure_cause().is_empty())
	_steps(1.0)
	_check("36 h without food: failure by hunger", health_model.failure_cause() == "hunger")

	_new_avatar(gs)
	_steps(danger - start)
	gs.happiness_low_hours = config.get_float("fail.happiness_hours")
	_check("happiness failing while starving: failure by hunger", health_model.failure_cause() == "hunger")
	gs.hours_without_food = 0.0
	_check("happiness failing after a meal: failure by happiness", health_model.failure_cause() == "happiness")

	_new_avatar(gs)
	gs.hours_without_food = 20.0
	var saved: Dictionary = gs.to_dict()
	gs.hours_without_food = 0.0
	gs.from_dict(saved)
	_check("the save keeps the hours without food", is_equal_approx(gs.hours_without_food, 20.0))

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Hunger and the failure timers for this many avatar hours, in 1-hour steps, awake.
func _steps(hours: float) -> void:
	for i in roundi(hours):
		hunger.step(1.0, false)
		health_model.step(1.0, false)


func _new_avatar(gs: Node) -> void:
	gs.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
