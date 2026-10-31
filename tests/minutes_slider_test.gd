extends SceneTree
## Tests for the minutes slider (Milestone 12, Task 1). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/minutes_slider_test.gd
## The player chooses the minutes first and then clicks the activity. Meals have no slider,
## because their portions are fixed. Nothing is saved.

var _failures := 0
var main: Node
var activities: Node
var settings: Node


func _process(_delta: float) -> bool:
	settings = root.get_node("Settings")
	settings.settings_path = "user://test_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	activities = root.get_node("Activities")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	activities.reset()
	root.get_node("GameState").reset()
	root.get_node("Clock").reset()
	root.get_node("GameState").start_new_avatar("Test", "child", "female", "normal")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	_test_exercise()
	_test_entertainment()
	_test_meals()
	_test_language()

	main.queue_free()
	settings.set_language("en")
	DirAccess.remove_absolute("user://test_settings.json")
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_exercise() -> void:
	var config: Node = root.get_node("Config")
	main.get_node("%ExerciseButton").pressed.emit()
	_check("exercise shows the slider", main.minutes_box.visible)
	_check("it starts at the activity's duration", is_equal_approx(main.minutes_slider.value, 60.0))
	_check("its limits come from config", main.minutes_slider.min_value == config.get_float("activity_slider.min_minutes")
			and main.minutes_slider.max_value == config.get_float("activity_slider.max_minutes"))
	_check("the label shows the minutes", main.minutes_label.text == "Minutes: 60")
	_check("the options show no fixed time", main.option_buttons.get_child(0).text == "Cardio")
	main.minutes_slider.value = 40.0
	_check("the label follows the slider", main.minutes_label.text == "Minutes: 40")
	main.option_buttons.get_child(0).pressed.emit()
	_check("the activity runs for the chosen minutes", activities.current_option == "cardio"
			and is_equal_approx(activities.target_hours, 40.0 / 60.0))
	_check("the speech bubble counts in minutes", main.speech_label.text == "Cardio... (0 of 40 min)")
	activities.stop()
	main.get_node("%ExerciseButton").pressed.emit()
	_check("the slider starts again at the duration next time", is_equal_approx(main.minutes_slider.value, 60.0))
	main.minutes_slider.value = 240.0
	main.option_buttons.get_child(1).pressed.emit()
	_check("4 hours are possible, for the too-much-exercise rule", activities.current_option == "strength"
			and is_equal_approx(activities.target_hours, 4.0))
	activities.stop()


func _test_entertainment() -> void:
	main.get_node("%EntertainmentButton").pressed.emit()
	_check("entertainment shows the slider", main.minutes_box.visible)
	main.minutes_slider.value = 120.0
	main.option_buttons.get_child(0).pressed.emit()
	_check("screens run for the chosen minutes", activities.current_option == "screens" and is_equal_approx(activities.target_hours, 2.0))
	activities.stop()


func _test_meals() -> void:
	main.get_node("%EatButton").pressed.emit()
	_check("meals have no slider (fixed portions)", not main.minutes_box.visible)
	_check("meals still show their time", main.option_buttons.get_child(0).text == "Healthy meal (0.5 h)")
	main.option_buttons.get_child(0).pressed.emit()
	_check("a meal keeps its fixed time", is_equal_approx(activities.target_hours, 0.5))
	activities.stop()


func _test_language() -> void:
	main.get_node("%ExerciseButton").pressed.emit()
	main.minutes_slider.value = 35.0
	settings.set_language("pt")
	_check("changing the language keeps the minutes", is_equal_approx(main.minutes_slider.value, 35.0))
	_check("the label changes language", main.minutes_label.text == "Minutos: 35")
	_check("the options change language", main.option_buttons.get_child(1).text == "Força muscular")
	main.options_panel.hide()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
