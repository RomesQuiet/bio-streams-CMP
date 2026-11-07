extends SceneTree
## The failure screen (user, 7 Nov 2026): failure is final and saved, time stops, a short phrase
## per cause, Details with the cause, the life, the last measures and the habits, the health bar's
## warning before failure, and Start a new avatar. Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/failure_test.gd

const SAVE_PATH := "user://test_failure_save.json"

var _failures := 0
var gs: Node
var clock: Node
var activities: Node
var save_game: Node
var health_model: GDScript
var main: Node
var settings: Node
var _announced := []
var _frame := 0


## Frame 0 reaches failure; the screen opens after that step (deferred), so frame 1 checks it.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_start()
		_reach_failure()
		return false
	_check_failure()
	_test_details()
	root.remove_child(main)
	main.free()
	_test_saved()
	_test_phrases()
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute("user://test_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _start() -> void:
	gs = root.get_node("GameState")
	clock = root.get_node("Clock")
	activities = root.get_node("Activities")
	save_game = root.get_node("SaveGame")
	health_model = load("res://scripts/health/health_model.gd")
	save_game.save_path = SAVE_PATH
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	settings = root.get_node("Settings")
	settings.settings_path = "user://test_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	_new_avatar()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _new_avatar() -> void:
	activities.reset()
	root.get_node("Habits").reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Ana", "child", "female", "normal")


func _reach_failure() -> void:
	_check("a new avatar: no failure, no warning", not gs.is_at_failure() and main.health_label.text == main.HEALTH_TEXT)
	activities.start("entertainment", "screens")
	gs.physical = 0.0
	gs.sleep = 0.0
	health_model.step(1.0, false)
	gs.changed.emit()
	_check("target health below the line: the health bar warns before failure", not gs.is_at_failure()
			and main.health_label.text == main.DANGER_TEXT and main.health_bar.theme_type_variation == main.DANGER_BAR_STYLE)
	_check("...and the failure screen is not shown yet", not main.failure_screen.visible)
	gs.failed.connect(func(cause: String) -> void: _announced.append(cause))
	health_model.step(23.0, false)


func _check_failure() -> void:
	_check("24 hours: failure, announced once, with its day", gs.failed_cause == "health" and _announced == ["health"]
			and gs.failed_day == gs.sim_hours / 24.0)
	_check("the failure screen opens over everything", main.failure_screen.visible)
	_check("time stops and the activity ends", clock.halted and not activities.is_running())
	var minute: float = clock.minute_of_day
	clock._process(5.0)
	_check("the clock no longer moves", clock.minute_of_day == minute)
	gs.physical = 0.6
	gs.sleep = 0.6
	health_model.step(1.0, false)
	_check("failure is final: it stays when health recovers, and is not announced again",
			gs.is_at_failure() and _announced.size() == 1)
	_check("a short phrase, not the scientific cause", main.failure_screen.phrase_label.text == "Ana's health got too low.")
	_check("Details are closed", not main.failure_screen.details_box.visible
			and main.failure_screen.details_button.text == "Details")


func _test_details() -> void:
	var screen: Node = main.failure_screen
	var habits: Node = root.get_node("Habits")
	habits.reset()
	habits.avatar_hours_total = 72.0
	habits.add_entry("sleep", 6.0, {"start_total": 10.0})
	habits.add_entry("cardio", 0.5, {"start_total": 30.0})
	habits.add_entry("screens", 3.0, {"start_total": 40.0})
	habits.add_entry("healthy_meal", 0.5, {"start_total": 50.0})
	habits.add_entry("fast_food_meal", 0.5, {"start_total": 51.0})
	habits.add_entry("fast_food_meal", 0.5, {"start_total": 52.0})
	var numbers: Dictionary = screen.habit_numbers()
	_check("habits over the last 3 days: sleep, activity, screens a day; fast-food share",
			is_equal_approx(numbers["days"], 3.0) and is_equal_approx(numbers["sleep_h"], 2.0)
			and is_equal_approx(numbers["activity_min"], 10.0) and is_equal_approx(numbers["screen_h"], 1.0)
			and numbers["meals"] == 3 and is_equal_approx(numbers["fast_food_share"], 2.0 / 3.0))
	screen.details_button.pressed.emit()
	var text := _texts(screen.details)
	_check("Details open", screen.details_box.visible and screen.details_button.text == "Hide details")
	_check("...with the cause in exact words", text.contains("stayed below 1.3 for 24 avatar hours"))
	_check("...the life and body as tiles", text.contains("Ana's life") and text.contains("days lived")
			and text.contains("highest health") and text.contains("BMI-for-age z"))
	_check("...the last measures as bars", _bars(screen.details) == 3)
	_check("...with a short verdict: normal start z +1.20 is too heavy; Physical 0.60 could be better",
			text.contains("BMI-for-age: too heavy") and text.contains("could be better"))
	for case in [[-3.5, "far too thin"], [-2.5, ": too thin"], [0.0, "healthy weight"], [1.5, ": too heavy"], [2.5, "far too heavy"]]:
		_check("z %+.1f: %s" % case, screen.z_explanation(case[0]).contains(case[1]))
	_check("happiness 0.1: too low; 0.8: good", screen.measure_explanation("MEASURE_HAPPINESS", 0.1) == "too low"
			and screen.measure_explanation("MEASURE_HAPPINESS", 0.8) == "good")
	var gauges: Dictionary = screen.gauges
	_check("sleep: a gauge at 2 h with the recommended 9 to 12 h in green", is_equal_approx(gauges["sleep"].value, 2.0)
			and gauges["sleep"].zone_from == 9.0 and gauges["sleep"].zone_to == 12.0 and text.contains("Recommended: 9 to 12 h"))
	_check("exercise: 10 min, recommended at least 60", is_equal_approx(gauges["activity"].value, 10.0)
			and gauges["activity"].zone_from == 60.0 and gauges["activity"].zone_to < 0.0 and text.contains("10 min a day"))
	_check("screens: 1 h, recommended at most 2", is_equal_approx(gauges["screens"].value, 1.0)
			and gauges["screens"].zone_to == 2.0 and text.contains("Recommended: at most 2 h"))
	_check("meals: 1 healthy and 2 fast food in a two-colour bar", gauges["meals"].split
			and gauges["meals"].healthy == 1 and gauges["meals"].fast_food == 2 and text.contains("1 healthy, 2 fast food"))
	settings.set_language("pt")
	_check("Portuguese, with a decimal comma", screen.phrase_label.text == "A saúde de Ana ficou demasiado baixa."
			and _texts(screen.details).contains("2,0 h por dia"))
	settings.set_language("en")


## A saved failure loads, and a new avatar has none.
func _test_saved() -> void:
	save_game.save_game()
	gs.reset()
	_check("before loading: no failure", not gs.is_at_failure())
	save_game.load_game()
	_check("the failure is saved and loads", gs.failed_cause == "health" and gs.is_at_failure())
	clock.halted = false
	var reopened: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(reopened)
	_check("opening the game with a saved failure shows the failure screen and stops time",
			reopened.failure_screen.visible and clock.halted)
	root.remove_child(reopened)
	reopened.free()
	_new_avatar()
	_check("a new avatar has no failure and time runs", not gs.is_at_failure() and not clock.halted)


func _test_phrases() -> void:
	var screen: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(screen)
	var failure: Node = screen.failure_screen
	for cause in ["thinness", "happiness"]:
		gs.failed_cause = cause
		failure.open()
		failure.details_button.pressed.emit()
		var expected: String = {"thinness": "Ana lost too much weight.", "happiness": "Ana became too unhappy."}[cause]
		var detail: String = {"thinness": "Severe thinness: BMI-for-age z stayed below -3 for 72 avatar hours, or reached -4",
				"happiness": "Happiness stayed below 0.10 for 12 avatar hours."}[cause]
		_check("%s: \"%s\" and the exact cause in Details" % [cause, expected], failure.phrase_label.text == expected
				and _texts(failure.details).contains(detail))
	gs.failed_cause = ""
	root.remove_child(screen)
	screen.free()


## Every text shown inside a node, one per line.
func _texts(node: Node) -> String:
	var found := ""
	for child in node.get_children():
		if child is Label:
			found += child.text + "\n"
		found += _texts(child)
	return found


func _bars(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		count += int(child is ProgressBar) + _bars(child)
	return count


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
