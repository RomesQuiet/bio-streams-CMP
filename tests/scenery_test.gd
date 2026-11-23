extends SceneTree
## The places behind the avatar, the fork after a meal (user, 7 Nov 2026) and the buttons, the same
## by day and night (Milestone 25). Run from the project folder (after --import):
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
	_test_sky_bodies(main, activities, minigame, clock)
	_test_buttons(main, clock)
	root.remove_child(main)
	main.free()
	DirAccess.remove_absolute("user://test_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


## Milestone 24: the sun or the moon is in the sky, but not during football or sleep.
func _test_sky_bodies(main: Node, activities: Node, minigame: Node, clock: Node) -> void:
	activities.reset()
	minigame.reset()
	clock.reset()
	main._refresh_phase()
	_check("awake: the sun or moon is shown", main.sky_bodies.visible)
	activities.start("entertainment", "football")
	_check("football: no sun or moon", minigame.running and not main.sky_bodies.visible)
	activities.reset()
	minigame.reset()
	main._refresh_minigame()
	_check("after football: shown again", main.sky_bodies.visible)
	root.get_node("GameState").hours_awake = 6.0  # Sleep v2: past the minimum wake time
	activities.start("sleep", "sleep", 8.0)
	_check("sleeping: no sun or moon", not main.sky_bodies.visible)
	clock.stop_sleep()
	_check("waiting for the play button: no sun or moon", not main.sky_bodies.visible)
	clock.wake_up()
	activities.reset()
	_check("awake again: shown", main.sky_bodies.visible)


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
	_check("no blanket after a meal", main.blanket.modulate.a == 0.0)
	root.get_node("GameState").hours_awake = 6.0  # Sleep v2: past the minimum wake time
	activities.start("sleep", "sleep", 8.0)
	main._refresh_activity(true)
	_check("sleep: the bedroom", scenery.kind == "bedroom" and scenery.modulate.a == 1.0)
	_check("sleeping after a meal: no fork", not main.meal_fork.visible)
	# Milestone 40, change 8: the bed picture takes the avatar's place (no code-drawn bed or blanket),
	# the window is loaded, the four buttons at 35%, Wake up in the stop slot.
	var time_name: String = "sleep_%s.png" % scenery.sleep_time(scenery.daylight)
	_check("...the sleeping picture of the time of day in the avatar's place, no blanket", main.exercise_picture.visible
			and main.exercise_picture.texture.resource_path.ends_with("child_male/" + time_name)
			and not main.avatar.visible and not main.blanket.visible)
	_check("...its bottom on the stage's bottom (y 834)", is_equal_approx(main.exercise_picture.offset_bottom, 0.0))
	_check("...the room behind it", not scenery.front and scenery.get_index() < main.exercise_picture.get_index())
	scenery.daylight = 0.0 if time_name == "sleep_day.png" else 1.0
	main._refresh_exercise_picture()
	_check("...the other picture when day turns to night (or back)", main.exercise_picture.texture.resource_path.ends_with(
			"child_male/sleep_%s.png" % scenery.sleep_time(scenery.daylight)) and not main.exercise_picture.texture.resource_path.ends_with(time_name))
	_check("...the four buttons at 35%, not pressable", is_equal_approx(main.action_grid.modulate.a, 0.35)
			and main.exercise_button.disabled and main.exercise_button.dimmed)
	_check("...Wake up in the stop slot", main.stop_button.visible and main.stop_button.text == "WAKE_UP"
			and main.stop_button.mark == "sun")
	main.stop_button.pressed.emit()
	main._refresh_activity(true)
	var clock: Node = root.get_node("Clock")
	_check("Wake up while sleeping ends the sleep, and the game waits", not activities.is_running()
			and clock.phase == clock.Phase.SLEEP_OVER)
	_check("...Wake up stays, the avatar and the buttons are back", main.stop_button.visible and main.stop_button.text == "WAKE_UP"
			and main.avatar.visible and not main.exercise_picture.visible and main.action_grid.modulate.a == 1.0)
	main.stop_button.pressed.emit()
	_check("...and then it starts the day, as the play button", clock.phase == clock.Phase.DAY)
	main._refresh_phase()
	_check("...and the pill is Stop again for the next activity", main.stop_button.text == "UI_STOP" and not main.stop_button.visible)
	activities.start("exercise", "strength")
	main._refresh_activity(true)
	_check("strength: outside, no building", scenery.kind == "outside" and main.activity_backdrop.modulate.a == 0.0
			and not main.avatar.back_view)
	activities.stop()
	minigame.reset()
	_test_street(main, activities, minigame)
	activities.start("entertainment", "screens")
	main._refresh_activity(true)
	_check("screens: still its see-through colour", scenery.modulate.a == 0.0 and main.activity_backdrop.modulate.a > 0.0)
	activities.stop()
	main._refresh_activity(true)


## Milestone 19: cardio runs down a street seen from behind; each stride brings it closer.
func _test_street(main: Node, activities: Node, minigame: Node) -> void:
	var scenery: Control = main.scenery
	activities.start("exercise", "cardio")
	main._refresh_activity(true)
	_check("cardio: the street, the avatar seen from behind", scenery.kind == "street" and scenery.modulate.a == 1.0
			and main.avatar.back_view and main.activity_backdrop.modulate.a == 0.0)
	scenery.late_after = 1.2
	scenery.stride(false, 1.0)
	var before: float = scenery.distance
	scenery._process(0.5)
	_check("after a tap the street keeps moving between taps", scenery.distance > before and scenery.is_moving())
	var slow: float = scenery.speed
	scenery.stride(false, 1.0)
	scenery._process(0.25)
	scenery.stride(false, 1.0)
	_check("tapping faster makes it faster", scenery.speed > slow)
	scenery._process(0.5)
	scenery.stride(false, 1.0)
	var run_speed: float = scenery.speed
	scenery._process(0.5)
	scenery.stride(true, 1.0)
	_check("walking strides are shorter steps", scenery.speed < run_speed)
	scenery._process(1.3)
	var stopped_at: float = scenery.distance
	scenery._process(0.5)
	_check("a tap too late: the street stops", not scenery.is_moving() and scenery.distance == stopped_at)
	scenery.stride(false, 1.0)
	_check("the next tap starts it again at the beat's speed", scenery.is_moving()
			and is_equal_approx(scenery.speed, scenery.RUN_STEP / 1.0))
	activities.stop()
	minigame.reset()
	main._refresh_activity(true)
	_check("after cardio the avatar faces the player again", not main.avatar.back_view)


## Milestone 25 (decision 84): the buttons look the same by day and by night: the four big ones
## in their colours, the others white with navy text. There is no night theme any more. The places
## follow the clock's minute.
func _test_buttons(main: Node, clock: Node) -> void:
	var ink := Color("#1b2552")
	var style: StyleBox = ThemeDB.get_project_theme().get_stylebox("normal", "Button")
	_check("buttons: white and rounded, with a thickness under them", style is StyleBoxFlat and style.bg_color.v > 0.95
			and style.corner_radius_top_left > 0 and style.shadow_offset.y > 0)
	_check("...with navy letters", ThemeDB.get_project_theme().get_color("font_color", "Button").is_equal_approx(ink))
	var pressed: StyleBox = ThemeDB.get_project_theme().get_stylebox("pressed", "Button")
	_check("...that go down when pressed", pressed.content_margin_top > style.content_margin_top
			and pressed.shadow_offset.y < style.shadow_offset.y)
	_check("there is no night theme", not ResourceLoader.exists("res://scenes/ui/night_theme.tres"))
	var button: Button = main.exercise_button
	for hour in [12.0, 23.0]:
		clock.minute_of_day = hour * 60.0
		main._refresh_clock()
		_check("%02d:00: the screen keeps the project theme" % hour, main.theme == null)
		_check("%02d:00: the windows and the street follow the clock" % hour, main.scenery.minute == clock.minute_of_day
				and main.background.minute == clock.minute_of_day and main.ground.minute == clock.minute_of_day)
	_check("the four buttons are drawn in their colours", button.kind == "exercise" and main.eat_button.kind == "eat")
	_check("at 23:00 the windows show no daylight", main.scenery.daylight == 0.0)
	clock.minute_of_day = 12.0 * 60.0
	main._refresh_clock()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
