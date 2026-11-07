extends SceneTree
## XP changes shown over the XP bar (user, 7 Nov 2026). The XP rules are unchanged (v1 Step 12,
## tests/health_xp_test.gd). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/xp_change_test.gd

var _failures := 0
var _changes: Array[float] = []


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://test_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	var gs: Node = root.get_node("GameState")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	_test_signal(gs)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_test_screen(main, gs, settings)
	root.remove_child(main)
	main.free()
	DirAccess.remove_absolute("user://test_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _test_signal(gs: Node) -> void:
	gs.xp_changed.connect(func(amount: float) -> void: _changes.append(amount))
	gs.xp = 0.0
	gs.add_xp(37.0)
	_check("a gain is sent", _changes == [37.0])
	gs.add_xp(-50.0)
	_check("a loss is sent as the real change (XP stops at 0)", _changes == [37.0, -37.0] and gs.xp == 0.0)
	gs.add_xp(-10.0)
	_check("at 0 XP a loss changes nothing and sends nothing", _changes.size() == 2)


func _test_screen(main: Node, gs: Node, settings: Node) -> void:
	var label: Label = main.xp_change_label
	_check("nothing shown at the start", label.modulate.a == 0.0)
	gs.add_xp(37.4)
	_check("a gain: +37 XP, in green", label.text == "+37 XP" and label.modulate.a == 1.0
			and label.get_theme_color("font_color") == main.xp_gain_color)
	gs.add_xp(0.8)
	gs.add_xp(0.8)
	_check("small gains wait while one is shown", label.text == "+37 XP" and absf(main._xp_pending - 2.0) < 0.001)
	main._xp_tween.kill()
	main._show_xp_change()
	_check("...then show added up", label.text == "+2 XP" and absf(main._xp_pending) < 0.001)
	main._xp_tween.kill()
	gs.add_xp(0.3)
	_check("less than 1 XP waits", label.text == "+2 XP" and absf(main._xp_pending - 0.3) < 0.001)
	main._xp_pending = 0.0
	gs.add_xp(-20.0)
	_check("a loss: −20 XP, in red", label.text == "−20 XP" and label.get_theme_color("font_color") == main.xp_loss_color)
	main._xp_tween.kill()
	settings.set_language("pt")
	gs.add_xp(5.0)
	_check("Portuguese", label.text == "+5 XP")
	settings.set_language("en")
	main._xp_tween.kill()
	main._xp_pending = 0.0
	root.get_node("Simulation").loading = true
	gs.add_xp(50.0)
	root.get_node("Simulation").loading = false
	_check("a loading save shows nothing", label.text == "+5 XP" and main._xp_pending == 0.0)


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
