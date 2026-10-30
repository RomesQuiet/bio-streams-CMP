extends SceneTree
## Tests for the settings panel (Milestone 11, Task 5). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/settings_panel_test.gd
## Opening and closing, the pause while it is open, and every text on the main screen changing
## language at once, without a reload. Uses test files, so nothing real is touched.

const TEST_SETTINGS := "user://test_settings.json"

var _failures := 0
var main: Node
var settings: Node
var clock: Node
var activities: Node


func _process(_delta: float) -> bool:
	settings = root.get_node("Settings")
	clock = root.get_node("Clock")
	activities = root.get_node("Activities")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	settings.settings_path = TEST_SETTINGS
	settings.use_web_storage = false
	settings.set_language("en")
	activities.reset()
	root.get_node("GameState").reset()
	clock.reset()
	root.get_node("GameState").start_new_avatar("Test", "child", "female", "normal")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	_test_open_and_close()
	_test_language()

	main.queue_free()
	settings.set_language("en")
	DirAccess.remove_absolute(TEST_SETTINGS)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_open_and_close() -> void:
	var button: Button = main.get_node("%SettingsButton")
	var close: Button = main.get_node("%SettingsCloseButton")
	_check("the settings start closed", not main.settings_overlay.visible)
	button.pressed.emit()
	_check("the settings button opens them", main.settings_overlay.visible)
	_check("the day pauses while they are open", clock.paused)
	close.pressed.emit()
	_check("Close closes them", not main.settings_overlay.visible)
	_check("the day runs again", not clock.paused)

	clock.set_paused(true)
	button.pressed.emit()
	close.pressed.emit()
	_check("a day the player had paused stays paused", clock.paused)
	clock.set_paused(false)

	activities.start("exercise", "cardio")
	button.pressed.emit()
	_check("they open during an activity, and the activity pauses", main.settings_overlay.visible and clock.paused and activities.is_running())
	close.pressed.emit()
	_check("...and it goes on after Close", not clock.paused and activities.is_running())
	activities.stop()

	root.get_node("GameState").hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	activities.start("sleep", "sleep", 8.0)
	button.pressed.emit()
	_check("they open during sleep, and sleep keeps running", main.settings_overlay.visible and not clock.paused
			and clock.phase == clock.Phase.SLEEPING)
	close.pressed.emit()
	activities.stop()
	clock.wake_up()


func _test_language() -> void:
	var button: Button = main.get_node("%SettingsButton")
	main._open_options("eat")
	button.pressed.emit()
	_check("the button of the language in use is pressed", main.english_button.button_pressed and not main.portuguese_button.button_pressed)
	var english_speech: String = main.speech_label.text
	main.portuguese_button.pressed.emit()
	_check("pressing a language changes it", settings.language == "pt")
	_check("the numbers follow at once", main.weight_label.text.contains(","))
	_check("the values box follows at once", main.diet_label.text.contains("Qualidade"))
	_check("an open list of options follows at once", main.option_buttons.get_child(0).text.contains("Refeição saudável"))
	_check("the sleep information follows at once", main.sleep_info_label.text.contains("de sono"))
	_check("the speech follows at once", main.speech_label.text != english_speech)
	_check("a button translates its key", main.tr(main.get_node("%EatButton").text) == "Comer")
	_check("the language buttons stay in their own language", main.tr(main.portuguese_button.text) == "Português"
			and main.tr(main.english_button.text) == "English")
	main.get_node("%SettingsCloseButton").pressed.emit()
	main._flash("SPEECH_LEVEL_UP", [3])
	_check("a Level up message is in Portuguese", main.speech_label.text == "Subiste de nível! Nível 3")
	main.english_button.pressed.emit()
	_check("...and follows the language too", main.speech_label.text == "Level up! Level 3")
	_check("back in English", main.diet_label.text.contains("Diet quality") and main.weight_label.text.contains("."))
	main.options_panel.hide()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
