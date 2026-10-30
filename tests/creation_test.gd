extends SceneTree
## Tests for the avatar creation screen. Run from the project folder:
##   Godot --headless --path . -s res://tests/creation_test.gd
## Nothing is saved, so the real save is never touched.

const TEST_SETTINGS := "user://test_settings.json"

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	var game_state: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	var settings: Node = root.get_node("Settings")
	settings.settings_path = TEST_SETTINGS
	settings.use_web_storage = false
	settings.set_language("en")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("Activities").reset()
	game_state.reset()
	clock.reset()
	_check("a new game is not created yet", not game_state.is_created())

	var screen: Control = load("res://scenes/ui/creation.tscn").instantiate()
	root.add_child(screen)
	_check("game time is paused on the creation screen", clock.paused)
	_check("on a computer the name field has the keyboard focus at once", screen.get_node("%NameEdit").has_focus())
	var start: Button = screen.get_node("%StartButton")
	_check("Start is disabled before choosing", start.disabled)
	_check("two age groups", screen.get_node("%AgeButtons").get_child_count() == 2)
	_check("two sexes", screen.get_node("%SexButtons").get_child_count() == 2)
	_check("four difficulties", screen.get_node("%DifficultyButtons").get_child_count() == 4)

	screen.get_node("%AgeButtons").get_child(1).pressed.emit()
	screen.get_node("%SexButtons").get_child(1).pressed.emit()
	screen.get_node("%DifficultyButtons").get_child(3).pressed.emit()
	_check("Start stays disabled without a name", start.disabled)
	var name_edit: LineEdit = screen.get_node("%NameEdit")
	name_edit.text = "   "
	name_edit.text_changed.emit(name_edit.text)
	_check("a name of only spaces is not accepted", start.disabled)
	name_edit.text = "  Rui "
	name_edit.text_changed.emit(name_edit.text)
	_check("Start is enabled with all four choices", not start.disabled)

	start.pressed.emit()
	_check("name stored without spaces", game_state.avatar_name == "Rui")
	_check("age group stored", game_state.age_group == "teenager")
	_check("sex stored", game_state.sex == "female")
	_check("difficulty stored", game_state.difficulty == "very_hard")
	_check("the avatar is created", game_state.is_created())
	_check("Very hard starting measures are used (v1; happiness 0.30, decision 7)", absf(game_state.physical - 0.03) < 0.01
			and is_equal_approx(game_state.happiness, 0.3) and is_equal_approx(game_state.sleep, 0.1))
	_check("game time runs again after Start", not clock.paused)

	_test_browser_name_box(game_state, clock)
	_test_language_buttons(game_state, clock)

	DirAccess.remove_absolute(TEST_SETTINGS)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Phones and tablets in a browser (bug fix, 27 Oct 2026): the name field never takes focus, a
## tap asks the browser's text box (window.prompt; outside a browser it answers nothing), and
## the typed name goes into the field.
func _test_browser_name_box(game_state: Node, clock: Node) -> void:
	game_state.reset()
	clock.reset()
	var screen: Control = load("res://scenes/ui/creation.tscn").instantiate()
	root.add_child(screen)
	screen.use_browser_name_box()
	var name_edit: LineEdit = screen.get_node("%NameEdit")
	name_edit.release_focus()
	_check("touch screen in a browser: the name field cannot take focus", name_edit.focus_mode == Control.FOCUS_NONE)
	_check("...and its hint says to tap it", name_edit.placeholder_text == screen.TAP_HINT)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	for pressed in [true, false]:
		tap.pressed = pressed
		name_edit.gui_input.emit(tap)
	_check("a tap does not give the field focus (Godot would open its own keyboard box)", not name_edit.has_focus())
	_check("outside a browser the text box answers nothing and the name stays empty", name_edit.text.is_empty())
	screen.get_node("%AgeButtons").get_child(0).pressed.emit()
	screen.get_node("%SexButtons").get_child(0).pressed.emit()
	screen.get_node("%DifficultyButtons").get_child(1).pressed.emit()
	var start: Button = screen.get_node("%StartButton")
	screen.set_typed_name("  Ana  ")
	_check("a name typed in the browser's box goes into the field, without spaces", name_edit.text == "Ana")
	_check("...and Start is enabled", not start.disabled)
	screen.set_typed_name(null)
	_check("Cancel in the browser's box keeps the name", name_edit.text == "Ana")
	screen.set_typed_name("A very long name that goes on and on")
	_check("a long name is cut to the longest allowed", name_edit.text.length() == name_edit.max_length)
	screen.set_typed_name("   ")
	_check("only spaces: no name, Start is disabled", name_edit.text.is_empty() and start.disabled)
	screen.queue_free()


## Milestone 11, Task 6: the PT and EN buttons change the language at once. What was typed and
## chosen stays, and the description of the chosen difficulty changes language.
func _test_language_buttons(game_state: Node, clock: Node) -> void:
	var settings: Node = root.get_node("Settings")
	settings.set_language("en")
	game_state.reset()
	clock.reset()
	var screen: Control = load("res://scenes/ui/creation.tscn").instantiate()
	root.add_child(screen)
	var info: Label = screen.get_node("%DifficultyInfo")
	var english: Button = screen.get_node("%EnglishButton")
	var portuguese: Button = screen.get_node("%PortugueseButton")
	_check("the button of the language in use is pressed", english.button_pressed and not portuguese.button_pressed)
	screen.get_node("%NameEdit").text = "Rui"
	var age: Button = screen.get_node("%AgeButtons").get_child(0)
	var difficulty: Button = screen.get_node("%DifficultyButtons").get_child(1)
	age.button_pressed = true
	age.pressed.emit()
	screen.get_node("%SexButtons").get_child(1).pressed.emit()
	difficulty.button_pressed = true
	difficulty.pressed.emit()
	_check("the description is in English", screen.tr(info.text).begins_with("Starts with average habits"))
	portuguese.button_pressed = true
	portuguese.pressed.emit()
	_check("PT changes the language", settings.language == "pt")
	_check("the description changes language", screen.tr(info.text).begins_with("Começa com hábitos medianos"))
	_check("a choice button changes language", screen.tr(difficulty.text) == "Normal" and screen.tr(age.text).begins_with("Criança"))
	_check("the name stays", screen.get_node("%NameEdit").text == "Rui")
	_check("the choices stay", age.button_pressed and difficulty.button_pressed)
	_check("Start stays enabled", not screen.get_node("%StartButton").disabled)
	english.button_pressed = true
	english.pressed.emit()
	_check("EN changes it back", settings.language == "en" and screen.tr(info.text).begins_with("Starts with average habits"))
	screen.queue_free()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
