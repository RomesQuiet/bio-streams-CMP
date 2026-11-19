extends SceneTree
## Milestone 25: the new interface (documentation/ui_specification_v1.md; decisions 79 to 89):
## the five pills, the colours of the sky over 24 hours, the 12-hour clock, the XP level, the
## curved ground, the four buttons, the theme, the play button that replaced Wake, and the shape
## of the screen. Only the look is checked here; the pictures come from tools/render_ui_states.gd.
##   Godot --headless --path . -s res://tests/interface_test.gd

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
	_test_pills()
	_test_palette()
	_test_sun_and_moon()
	_test_clock_text()
	_test_theme()
	_test_project()
	_test_main_screen()
	DirAccess.remove_absolute("user://test_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


## The five pills are a mask over one continuous bar (4.2).
func _test_pills() -> void:
	var pills: GDScript = load("res://scripts/ui/health_pills.gd")
	_check("health 1.0: one full pill", is_equal_approx(pills.pill_fill(1.0, 0), 1.0) and pills.pill_fill(1.0, 1) == 0.0)
	_check("health 2.5: two pills and half of the third", is_equal_approx(pills.pill_fill(2.5, 1), 1.0)
			and is_equal_approx(pills.pill_fill(2.5, 2), 0.5) and pills.pill_fill(2.5, 3) == 0.0)
	_check("health 3.7: three pills and 70% of the fourth", is_equal_approx(pills.pill_fill(3.7, 3), 0.7))
	var all := true
	for i in 5:
		all = all and is_equal_approx(pills.pill_fill(5.0, i), 1.0)
	_check("health 5.0: all five full", all)
	var bar := Vector2(200, 20)
	var first: Rect2 = pills.pill_rect(bar, 0)
	var last: Rect2 = pills.pill_rect(bar, 4)
	_check("exactly five equal pills fill the bar", is_zero_approx(first.position.x) and is_equal_approx(last.end.x, bar.x)
			and is_equal_approx(first.size.x, last.size.x))


## One table of colour stops, interpolated: no jump from one minute to the next, around midnight
## too; stars at night only; a blue sky at noon (7.6).
func _test_palette() -> void:
	var palette: GDScript = load("res://scripts/ui/sky_palette.gd")
	var largest := 0.0
	for minute in range(0, 1440):
		for column in [palette.SKY_TOP, palette.SKY_MIDDLE, palette.SKY_HORIZON, palette.GROUND_TOP, palette.GROUND_BOTTOM]:
			var a: Color = palette.color(minute, column)
			var b: Color = palette.color(minute + 1, column)
			largest = maxf(largest, maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))))
	_check("the sky and ground change smoothly (largest step in a minute %.3f)" % largest, largest < 0.03)
	_check("midnight joins the end of the day to its start", palette.color(1440, palette.SKY_TOP) == palette.color(0, palette.SKY_TOP))
	_check("stars at night, none at noon", palette.stars(23 * 60) > 0.9 and palette.stars(12 * 60) == 0.0)
	var noon: Color = palette.color(12 * 60, palette.SKY_TOP)
	var night: Color = palette.color(0, palette.SKY_TOP)
	_check("noon is a bright blue, night a deep blue", noon.b > noon.r and noon.v > night.v)
	var dusk: Color = palette.color(19 * 60 + 15, palette.SKY_HORIZON)
	_check("the sunset is warm near the horizon", dusk.r > dusk.b)


## The sun rises left at 07:00, is highest in the middle, sets right at 19:00 (decision 86);
## the moon is a crescent cut by geometry.
func _test_sun_and_moon() -> void:
	var bodies: GDScript = load("res://scripts/ui/sky_bodies.gd")
	var morning: Dictionary = bodies.arc(9 * 60, 7, 19)
	var afternoon: Dictionary = bodies.arc(16 * 60 + 30, 7, 19)
	var left: Vector2 = bodies.point(morning.t, 700, 500, 300, 50)
	var right: Vector2 = bodies.point(afternoon.t, 700, 500, 300, 50)
	_check("before noon the sun is on the left, after noon on the right", morning.body == "sun" and left.x < 350
			and afternoon.body == "sun" and right.x > 350)
	_check("at 06:30 and 19:15 it is the moon's time", bodies.arc(6 * 60 + 30, 7, 19).body == "moon"
			and bodies.arc(19 * 60 + 15, 7, 19).body == "moon")
	var parts: Array = bodies.crescent(Vector2(100, 100), 30.0, 0.45)
	_check("the moon is one crescent", parts.size() == 1 and parts[0].size() > 10)


func _test_clock_text() -> void:
	var clock: Node = root.get_node("Clock")
	var cases := [[0, "12:00 AM"], [30, "12:30 AM"], [7 * 60, "7:00 AM"], [12 * 60, "12:00 PM"],
			[13 * 60 + 5, "1:05 PM"], [22 * 60 + 15, "10:15 PM"], [23 * 60 + 59, "11:59 PM"]]
	var ok := true
	for case in cases:
		clock.minute_of_day = case[0]
		ok = ok and clock.clock_text_12h("AM", "PM") == case[1]
	_check("the 12-hour clock: 12:00 AM, 7:00 AM, 12:00 PM, 1:05 PM, 10:15 PM, 11:59 PM", ok)
	clock.reset()


## The theme: the HUD and the capsule are flat (a thin white line, 5% white, no shadow), the
## balloon white with a navy outline and no shadow, Nunito everywhere.
func _test_theme() -> void:
	var theme := ThemeDB.get_project_theme()
	var hud: StyleBoxFlat = theme.get_stylebox("panel", "HudPanel")
	_check("HUD: white at 5%, a thin white line, no shadow", is_equal_approx(hud.bg_color.a, 0.05) and hud.bg_color.v == 1.0
			and hud.border_width_top == 2 and hud.shadow_size == 0)
	var capsule: StyleBoxFlat = theme.get_stylebox("panel", "Capsule")
	_check("clock capsule: the same flat look, as round as a capsule", is_equal_approx(capsule.bg_color.a, 0.05)
			and capsule.corner_radius_top_left >= 30)
	var balloon: StyleBoxFlat = theme.get_stylebox("panel", "SpeechBalloon")
	_check("balloon: white, navy outline, very round, no shadow", balloon.bg_color == Color.WHITE
			and balloon.border_color.is_equal_approx(Color("#1b2552")) and balloon.corner_radius_top_left >= 40 and balloon.shadow_size == 0)
	_check("the font is Nunito", theme.default_font is FontVariation
			and theme.default_font.base_font.resource_path.ends_with("Nunito-wght.ttf"))
	_check("the XP bar is cyan", theme.get_stylebox("fill", "XPBar").bg_color.b > 0.9)


## Decision 87: the sky fills any screen and the game keeps its proportions.
func _test_project() -> void:
	_check("stretch aspect: expand", ProjectSettings.get_setting("display/window/stretch/aspect") == "expand")


func _test_main_screen() -> void:
	var activities: Node = root.get_node("Activities")
	var minigame: Node = root.get_node("Minigame")
	var clock: Node = root.get_node("Clock")
	var gs: Node = root.get_node("GameState")
	activities.reset()
	minigame.reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_check("the main screen is the column, 720 wide", is_equal_approx(main.size.x, 720.0)
			and is_equal_approx(main.anchor_left, 0.5) and is_equal_approx(main.anchor_right, 0.5))
	_check("there is no Wake button (decision 81)", main.find_child("WakeButton", true, false) == null)
	gs.health = 2.6
	gs.xp = 270.0
	gs.changed.emit()
	_check("\"Health 2\" for health 2.6, the pills show 2.6", main.health_label.text == "Health 2"
			and is_equal_approx(main.health_pills.value, 2.6))
	_check("\"XP 70 / 100\" and level 2 -> 3", main.xp_label.text == "XP 70 / 100" and main.level_display.level == 2)
	main._refresh_clock()
	_check("the clock shows 7:00 AM", main.clock_label.text == "7:00 AM")
	# The level rolls when it changes, and the bar starts again.
	gs.xp = 310.0
	gs.changed.emit()
	_check("level up: 3 -> 4, the numbers roll", main.level_display.level == 3 and main.level_display.roll < 1.0)
	_check("...and the XP bar starts again (10%)", is_equal_approx(main.xp_bar.value, 0.1))
	gs.xp = 150.0
	gs.changed.emit()
	_check("XP can go down: level 1, rolling down", main.level_display.level == 1)
	# The four buttons go down at once when pressed and come back after.
	var button: Button = main.exercise_button
	button.button_down.emit()
	_check("a big button pressed: its body goes down at once", button.press == 1.0)
	button.button_up.emit()
	_check("...and it comes back smoothly", button._tween != null and button._tween.is_running())
	# The play button next to the clock: pause, go on, and start the day after a sleep.
	main.pause_button.pressed.emit()
	_check("pause: the day stops and the button shows play", clock.paused and main.pause_icon.kind == "play")
	main.pause_button.pressed.emit()
	_check("play: the day goes on and the button shows pause", not clock.paused and main.pause_icon.kind == "pause")
	gs.hours_awake = 6.0  # Sleep v2: past the minimum wake time
	activities.start("sleep", "sleep", 8.0)
	_check("asleep: the button cannot pause the sleep", main.pause_button.disabled)
	clock.stop_sleep()
	_check("the sleep is over: the button shows play and says it starts the day", not main.pause_button.disabled
			and main.pause_icon.kind == "play" and main.pause_button.tooltip_text == main.WAKE_TIP)
	_check("...and the avatar says to press it", main.speech_label.text.contains("Press play"))
	main.pause_button.pressed.emit()
	_check("pressing it starts the new day, as Wake did", clock.phase == clock.Phase.DAY and not clock.paused)
	activities.reset()
	# The curved ground: highest in the middle, lower at the sides.
	var ground: Control = main.ground
	_check("the ground is highest under the avatar and bends down at the sides",
			is_equal_approx(ground.top_at(ground.centre.x), ground.centre.y - 34.0)
			and ground.top_at(ground.centre.x - 300.0) > ground.top_at(ground.centre.x))
	# A request: its picture and a divider on the left of the text.
	main._write_speech("I'm hungry!", "hungry", "hungry")
	_check("a request shows its picture and a divider", main.request_icon.visible and main.speech_divider.visible
			and main.speech_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT)
	main._write_speech("Hello!", "", "hello")
	_check("a plain message is centred, without picture", not main.request_icon.visible and not main.speech_divider.visible
			and main.speech_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	root.remove_child(main)
	main.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
