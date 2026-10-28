extends SceneTree
## Tests for the avatar creation screen. Run from the project folder:
##   Godot --headless --path . -s res://tests/creation_test.gd
## Nothing is saved, so the real save is never touched.

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	var game_state: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
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

	_test_name_without_text_changed(game_state, clock)

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Phones and tablets in a browser (bug fix, 28 Oct 2026): with the web export option
## html/experimental_virtual_keyboard the keyboard's text arrives through LineEdit.set_text (the
## engine calls it for the focused field), which does not emit text_changed. The screen must
## notice the name anyway, or Start would stay disabled.
func _test_name_without_text_changed(game_state: Node, clock: Node) -> void:
	game_state.reset()
	clock.reset()
	var screen: Control = load("res://scenes/ui/creation.tscn").instantiate()
	root.add_child(screen)
	var name_edit: LineEdit = screen.get_node("%NameEdit")
	var start: Button = screen.get_node("%StartButton")
	var heard := []
	name_edit.text_changed.connect(func(typed: String) -> void: heard.append(typed))
	screen.get_node("%AgeButtons").get_child(0).pressed.emit()
	screen.get_node("%SexButtons").get_child(0).pressed.emit()
	screen.get_node("%DifficultyButtons").get_child(1).pressed.emit()
	_check("the three choices are made, no name yet: Start is disabled", start.disabled)
	# Exactly what the web virtual keyboard does with the text of its hidden box.
	root.push_text_input("Maria")
	_check("the keyboard's text reaches the field", name_edit.text == "Maria")
	_check("...without text_changed (this is why the screen looks at the name itself)", heard.is_empty())
	screen._process(0.0)
	_check("the next frame enables Start", not start.disabled)
	root.push_text_input("   ")
	screen._process(0.0)
	_check("a name of only spaces disables Start again", start.disabled)
	root.push_text_input("A very long name that goes on and on")
	screen._process(0.0)
	_check("a long name is cut to the longest allowed", name_edit.text.length() == name_edit.max_length)
	screen.queue_free()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
