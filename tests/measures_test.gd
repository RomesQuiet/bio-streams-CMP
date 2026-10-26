extends SceneTree
## Tests for the measures and health (Milestone 4, Task 6). Run from the project folder:
##   Godot --headless --path . -s res://tests/measures_test.gd
## Plays avatar days with the main screen open and checks, after each sleep, that the
## measures, the target health and the health bar follow the formulas. Also checks the
## failure message. Uses a test save path; nothing is saved.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1
const DAYS := 3

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	activities.reset()
	root.get_node("Habits").reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "female", "normal")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	_test_days(gs, clock, activities, main)
	_test_failure(gs, main)

	main.queue_free()
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_days(gs: Node, clock: Node, activities: Node, main: Node) -> void:
	var config: Node = root.get_node("Config")
	var habits: Node = root.get_node("Habits")
	clock.debug_speed = 600.0
	print("day  physical happiness sleep  target  health (bar)")
	for day in DAYS:
		activities.start("exercise", "cardio")
		while activities.is_running():
			clock._process(STEP_SECONDS)
		activities.start("entertainment", "screens")
		while activities.is_running():
			clock._process(STEP_SECONDS)
		var health_before: float = gs.health
		# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
		gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
		activities.start("sleep", "sleep", 10.0)
		while clock.phase == clock.Phase.SLEEPING:
			clock._process(STEP_SECONDS)
		print("%3d  %.3f    %.3f  %.3f  %.3f   %.3f (%.3f)" % [day + 1, gs.physical, gs.happiness, gs.sleep,
				gs.target_health, gs.health, main.health_bar.value])
		_check("day %d: physical = mix of fitness, muscle and weight score" % (day + 1),
				absf(gs.physical - gs.physical_from_body(gs.fitness, gs.strength, gs.weight_z)) < TOLERANCE)
		var sleep_model: GDScript = load("res://scripts/health/sleep_model.gd")
		var expected_sleep: float = sleep_model.sleep_measure(gs.sleep_debt, sleep_model.oversleep(10.0, gs.age_group))
		_check("day %d: sleep = (1 - debt / 8) x oversleep cut (v1 Step 9)" % (day + 1), absf(gs.sleep - expected_sleep) < TOLERANCE)
		_check("day %d: happiness is between 0 and 1" % (day + 1), gs.happiness >= 0.0 and gs.happiness <= 1.0)
		var c: float = (gs.target_health - 1.0) / 4.0
		_check("day %d: target = 1 + 4 x C (power mean)" % (day + 1), absf(gs.target_health - gs.health_from_measures(gs.physical, gs.happiness, gs.sleep)) < TOLERANCE
				and c >= 0.0 and c <= 1.0)
		var expected_health: float = health_before + config.get_float("health_m4.alpha_bar") * (gs.target_health - health_before)
		_check("day %d: health += alpha_bar x (target - health)" % (day + 1), absf(gs.health - expected_health) < TOLERANCE)
		_check("day %d: health moves gradually (not straight to the target)" % (day + 1),
				absf(gs.health - gs.target_health) > TOLERANCE or is_equal_approx(health_before, gs.target_health))
		_check("day %d: the health bar and level box show it" % (day + 1), is_equal_approx(main.health_bar.value, gs.health)
				and main.health_level_button.text == str(gs.health_level))
		_check("day %d: the measures panel shows the new values" % (day + 1), is_equal_approx(main.physical_bar.value, gs.physical)
				and is_equal_approx(main.happiness_bar.value, gs.happiness) and is_equal_approx(main.sleep_bar.value, gs.sleep))
		clock.wake_up()


## Failure at minimum health shows a placeholder message. There is no death.
func _test_failure(gs: Node, main: Node) -> void:
	var config: Node = root.get_node("Config")
	_check("there is no death", config.get_value("health_m4.death_enabled") == false)
	gs.health = config.get_float("health_m4.failure_at_health") + 0.1
	gs.changed.emit()
	_check("health just above the failure line is not failure", not gs.is_at_failure() and main.speech_label.text != main.FAILURE_TEXT)
	gs.health = config.get_float("measures.health_min")
	gs.changed.emit()
	_check("health at the minimum is failure", gs.is_at_failure())
	_check("the failure message is shown", main.speech_label.text == main.FAILURE_TEXT)
	gs.health = 3.0
	gs.changed.emit()
	_check("the message goes away when health rises again", main.speech_label.text != main.FAILURE_TEXT)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
