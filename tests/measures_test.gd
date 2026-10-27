extends SceneTree
## Tests for the measures, health and failure (Milestone 4 Task 6; Milestone 10 Task 8, v1 Steps
## 8, 11 and 12). Run from the project folder:
##   Godot --headless --path . -s res://tests/measures_test.gd
## Plays avatar days with the main screen open and checks, after each sleep, that Physical, the
## target health and the health bar follow the v1 formulas and that the screen shows them. Then
## checks the failure timers and message, the avatar states, the health bar warning of the danger
## state (Milestone 10.5) and the physical values box.
## Uses a test save path; nothing is saved.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1
const DAYS := 3

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this test
## script is compiled.
var health_model: GDScript
var body_size: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	health_model = load("res://scripts/health/health_model.gd")
	body_size = load("res://scripts/health/body_size.gd")
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
	_test_physical_formula(gs)
	_test_failure(gs, main)
	_test_states_and_values(gs, main)

	main.queue_free()
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_days(gs: Node, clock: Node, activities: Node, main: Node) -> void:
	var config: Node = root.get_node("Config")
	clock.debug_speed = 600.0
	print("day  physical happiness sleep  target  health (bar)")
	for day in DAYS:
		activities.start("eat", "healthy_meal")
		while activities.is_running():
			clock._process(STEP_SECONDS)
		activities.start("exercise", "cardio")
		while activities.is_running():
			clock._process(STEP_SECONDS)
		activities.start("entertainment", "screens")
		while activities.is_running():
			clock._process(STEP_SECONDS)
		var health_before: float = gs.health
		gs.hours_awake = config.get_float("sleep.can_sleep_awake_h")
		activities.start("sleep", "sleep", 10.0)
		while clock.phase == clock.Phase.SLEEPING:
			clock._process(STEP_SECONDS)
		print("%3d  %.3f    %.3f      %.3f  %.3f   %.3f (%.3f)" % [day + 1, gs.physical, gs.happiness, gs.sleep,
				gs.target_health, gs.health, main.health_bar.value])
		_check("day %d: Physical follows the v1 formula" % (day + 1), absf(gs.physical - health_model.physical()) < TOLERANCE)
		_check("day %d: target = 1 + 4 x the power mean (p 0.5) of the three measures" % (day + 1),
				absf(gs.target_health - (1.0 + 4.0 * pow((sqrt(gs.physical) + sqrt(gs.happiness) + sqrt(gs.sleep)) / 3.0, 2.0))) < TOLERANCE)
		var expected_health: float = health_before + config.get_float("health.alpha_bar") * (gs.target_health - health_before)
		_check("day %d: health += alpha_bar x (target - health)" % (day + 1), absf(gs.health - expected_health) < TOLERANCE)
		_check("day %d: the health bar and level box show it" % (day + 1), is_equal_approx(main.health_bar.value, gs.health)
				and main.health_level_button.text == str(gs.health_level))
		_check("day %d: the measures panel shows the new values" % (day + 1), is_equal_approx(main.physical_bar.value, gs.physical)
				and is_equal_approx(main.happiness_bar.value, gs.happiness) and is_equal_approx(main.sleep_bar.value, gs.sleep))
		clock.wake_up()


## v1 Step 8: Physical = (0.5 sqrt(w) + 0.3 sqrt(fitness) + 0.2 sqrt(strength))^2 x (0.4 + 0.6 Q)
## x (1 - 0.5 U) x (1 - 0.3 O). v1 examples: Normal start 0.44; fast food with lots of
## exercise stays low because of Q.
func _test_physical_formula(gs: Node) -> void:
	gs.weight_z = 0.0
	gs.fitness = 0.81
	gs.strength = 0.64
	gs.diet_quality = 1.0
	gs.deficit_u = 0.0
	gs.overreach = 0.0
	var body := pow(0.5 * 1.0 + 0.3 * 0.9 + 0.2 * 0.8, 2.0)
	_check("a healthy body with Q 1: Physical = the body mix", absf(health_model.physical() - body) < TOLERANCE)
	gs.diet_quality = 0.0
	_check("fast food at every meal (Q 0): Physical x 0.4", absf(health_model.physical() - body * 0.4) < TOLERANCE)
	gs.diet_quality = 1.0
	gs.deficit_u = 1.0
	gs.overreach = 1.0
	_check("full deficit and overreaching: Physical x 0.5 x 0.7", absf(health_model.physical() - body * 0.35) < TOLERANCE)
	gs.deficit_u = 0.0
	gs.overreach = 0.0


## Failure (no death): target health below 1.3 for 24 avatar hours (decision 10: the target, not
## the slow bar), or happiness below 0.10 for 12 avatar hours. Only a placeholder message is shown.
func _test_failure(gs: Node, main: Node) -> void:
	var config: Node = root.get_node("Config")
	_check("there is no death", config.get_value("health.death_enabled") == false)
	# Physical and Sleep 0 with happiness 0.5: target health 1.22; the bar still shows 3.
	gs.physical = 0.0
	gs.sleep = 0.0
	gs.happiness = 0.5
	gs.health = 3.0
	gs.health_low_hours = 0.0
	gs.happiness_low_hours = 0.0
	health_model.step(23.0, false)
	gs.changed.emit()
	_check("target health below 1.3 for 23 h is not failure yet", gs.target_health < 1.3
			and not gs.is_at_failure() and main.speech_label.text != main.FAILURE_TEXTS["health"])
	health_model.step(1.0, false)
	gs.changed.emit()
	_check("target health below 1.3 for 24 h is failure, even with the bar at 3", gs.is_at_failure())
	_check("the failure message is shown", main.speech_label.text == main.FAILURE_TEXTS["health"])
	gs.physical = 0.5
	gs.sleep = 0.5
	health_model.step(1.0 / 12.0, false)
	gs.changed.emit()
	_check("the message goes away when health rises again", not gs.is_at_failure() and main.speech_label.text != main.FAILURE_TEXTS["health"])
	gs.happiness = 0.05
	health_model.step(12.0, false)
	_check("happiness below 0.10 for 12 h is failure too", gs.is_at_failure())
	gs.happiness = 0.5
	health_model.step(1.0 / 12.0, false)
	_check("...and ends when happiness rises", not gs.is_at_failure())


## v1 avatar images and the physical values box.
func _test_states_and_values(gs: Node, main: Node) -> void:
	var states_script: GDScript = load("res://scripts/health/avatar_states.gd")
	gs.weight_z = 1.5
	gs.strength = 0.75
	gs.happiness = 0.2
	var states: Dictionary = states_script.current()
	_check("z +1.5: overweight; strength 0.75: muscular (muscular with fat); happiness 0.2: sad",
			states["overweight"] and states["muscular"] and states["sad"] and not states["thin"])
	gs.weight_z = -2.5
	gs.strength = 0.4
	gs.happiness = 0.8
	states = states_script.current()
	_check("z -2.5: thin, not muscular, not sad", states["thin"] and not states["overweight"] and not states["muscular"] and not states["sad"])
	gs.changed.emit()
	_check("the avatar draws these states", main.avatar.states == states)
	_check("the physical box shows weight, height, BMI-for-age z and diet quality as numbers",
			main.weight_label.text.contains("kg") and main.height_label.text.contains("cm")
			and main.bmi_label.text.contains("z") and main.diet_label.text.contains("Diet quality"))
	_check("z -2.5: no danger warning on the health bar", main.health_label.text != main.DANGER_TEXT and not states["ill"])
	# Milestone 10.5: the danger state of severe thinness (z below -3).
	gs.weight_z = -3.5
	gs.changed.emit()
	states = states_script.current()
	_check("z -3.5: thin and ill, and the avatar draws it", states["thin"] and states["ill"] and main.avatar.states == states)
	_check("...and the health bar warns", main.health_label.text == main.DANGER_TEXT and main.health_bar.self_modulate != Color.WHITE)
	gs.weight_z = -2.5
	gs.changed.emit()
	_check("z back at -2.5: the warning goes away", main.health_label.text != main.DANGER_TEXT and main.health_bar.self_modulate == Color.WHITE)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
