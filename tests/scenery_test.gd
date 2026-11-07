extends SceneTree
## The places behind the avatar, the fork after a meal and the day and night buttons
## (user, 7 Nov 2026). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/scenery_test.gd

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://test_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	var activities: Node = root.get_node("Activities")
	var minigame: Node = root.get_node("Minigame")
	var clock: Node = root.get_node("Clock")
	var gs: Node = root.get_node("GameState")
	activities.reset()
	minigame.reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_test_places(main, activities, minigame)
	_test_buttons(main, clock)
	root.remove_child(main)
	main.free()
	DirAccess.remove_absolute("user://test_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _test_places(main: Node, activities: Node, minigame: Node) -> void:
	var scenery: Control = main.scenery
	_check("no activity: no place drawn", scenery.modulate.a == 0.0)
	activities.start("eat", "healthy_meal")
	main._refresh_activity(true)
	_check("a meal: the room with windows", scenery.kind == "room" and scenery.modulate.a == 1.0)
	_check("...and the fork", main.meal_fork.visible)
	_check("...not the see-through colour", main.activity_backdrop.modulate.a == 0.0)
	activities.stop()
	main._refresh_activity(true)
	_check("after the meal the fork and its zone are gone", not main.meal_fork.visible and not main.avatar.mouth_open)
	_check("...and so is the room", scenery.modulate.a == 0.0)
	activities.start("sleep", "sleep", 8.0)
	main._refresh_activity(true)
	_check("sleep: the bedroom", scenery.kind == "bedroom" and scenery.modulate.a == 1.0)
	_check("sleeping after a meal: no fork", not main.meal_fork.visible)
	activities.stop()
	root.get_node("Clock").wake_up()
	for option in ["cardio", "strength"]:
		activities.start("exercise", option)
		main._refresh_activity(true)
		_check("%s: outside, no building" % option, scenery.kind == "outside" and main.activity_backdrop.modulate.a == 0.0)
		activities.stop()
		minigame.reset()
	activities.start("entertainment", "screens")
	main._refresh_activity(true)
	_check("screens: still its see-through colour", scenery.modulate.a == 0.0 and main.activity_backdrop.modulate.a > 0.0)
	activities.stop()
	main._refresh_activity(true)


func _test_buttons(main: Node, clock: Node) -> void:
	var day_style: StyleBox = ThemeDB.get_project_theme().get_stylebox("normal", "Button")
	_check("day buttons: white, rounded, black border", day_style is StyleBoxFlat and day_style.bg_color == Color.WHITE
			and day_style.border_color == Color.BLACK and day_style.corner_radius_top_left > 0)
	_check("...with black letters", ThemeDB.get_project_theme().get_color("font_color", "Button") == Color.BLACK)
	clock.minute_of_day = 12.0 * 60.0
	main._refresh_clock()
	var button: Button = main.exercise_button
	_check("noon: day buttons", main.theme == null and button.get_theme_color("font_color") == Color.BLACK)
	clock.minute_of_day = 23.0 * 60.0
	main._refresh_clock()
	var night_style: StyleBox = button.get_theme_stylebox("normal")
	_check("23:00: black buttons with white letters and border", night_style.bg_color == Color.BLACK
			and night_style.border_color == Color.WHITE and button.get_theme_color("font_color") == Color.WHITE)
	_check("...and the windows show the night sky", main.scenery.daylight == 0.0 and main.scenery.sky_color == main.night_sky_color)
	clock.minute_of_day = 12.0 * 60.0
	main._refresh_clock()
	_check("day again: white buttons", button.get_theme_stylebox("normal").bg_color == Color.WHITE)


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
