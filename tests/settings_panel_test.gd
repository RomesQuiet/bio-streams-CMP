extends SceneTree
## Tests for the settings panel (Milestone 11, Task 5). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/settings_panel_test.gd
## Opening and closing, the pause while it is open, and every text on the main screen changing
## language at once, without a reload, and "Start a new avatar" (Task 7). Uses test files, so
## nothing real is touched.

const TEST_SETTINGS := "user://test_settings.json"
const TEST_SAVE := "user://test_save.json"

var _failures := 0
var main: Node
var settings: Node
var clock: Node
var activities: Node
## Frames since the new avatar was confirmed; the scene changes at the end of a frame.
var _frames_after_confirm := -1


func _process(_delta: float) -> bool:
	if _frames_after_confirm >= 0:
		_frames_after_confirm += 1
		return _frames_after_confirm >= 2 and _finish()
	settings = root.get_node("Settings")
	clock = root.get_node("Clock")
	activities = root.get_node("Activities")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = TEST_SAVE
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
	_test_new_avatar(save_game)
	_frames_after_confirm = 0
	return false


func _finish() -> bool:
	_check("the creation screen opens", current_scene != null and current_scene.name == "Creation")
	_check("game time is paused there", clock.paused)
	_check("the page closing now saves nothing, so the old avatar cannot come back", _autosave_saves_nothing())
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


func _test_new_avatar(save_game: Node) -> void:
	var game_state: Node = root.get_node("GameState")
	var button: Button = main.get_node("%NewAvatarButton")
	var confirm: Button = main.get_node("%ConfirmNewAvatarButton")
	settings.set_language("pt")
	save_game.save_game()
	main.get_node("%SettingsButton").pressed.emit()
	_check("no warning at first", not main.confirm_box.visible and button.visible)
	button.pressed.emit()
	_check("the first press only shows the warning", main.confirm_box.visible and game_state.is_created()
			and FileAccess.file_exists(TEST_SAVE))
	main.get_node("%ConfirmCancelButton").pressed.emit()
	_check("Cancel keeps the avatar and hides the warning", not main.confirm_box.visible and button.visible
			and game_state.is_created() and FileAccess.file_exists(TEST_SAVE))
	button.pressed.emit()
	main.get_node("%SettingsCloseButton").pressed.emit()
	_check("Close keeps the avatar and hides the warning too", not main.confirm_box.visible and game_state.is_created())
	main.get_node("%SettingsButton").pressed.emit()
	activities.start("exercise", "cardio")
	button.pressed.emit()
	confirm.pressed.emit()
	_check("the second press deletes the avatar", not game_state.is_created())
	_check("the save is gone", not FileAccess.file_exists(TEST_SAVE))
	_check("no activity is left running", not activities.is_running())
	_check("the clock starts again", clock.day_number == 1 and clock.phase == clock.Phase.DAY)
	_check("the language stays", settings.language == "pt")


func _autosave_saves_nothing() -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.auto_save_enabled = true
	save_game._auto_save()
	save_game.auto_save_enabled = false
	return not FileAccess.file_exists(TEST_SAVE)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
