extends SceneTree
## Milestone 25: renders the main screen in the test states of the interface specification
## (documentation/ui_specification_v1.md, section 16) to PNG pictures, to check the look. It needs a
## window (not --headless). It never touches the real save. On this Mac a window that is not in
## front stops drawing after its first frames, so the state is set before the screen opens and
## each run renders one state. Run from the project folder:
##   Godot --path . --resolution 720x1280 -s res://tools/render_ui_states.gd -- <output folder> <state> [en|pt]
## State: A to F (section 16), P (a button pressed and one disabled), X (danger), R (the room),
## S (the street), Z (the bedroom), W (the sleep is over: the play button), H (the measures panel
## open, with 2.4 h of sleep debt and two thirds of today's sleep need; Milestone 27), M (the menu),
## N (the creation screen), K (squats after DOWN: the activity dock and
## the squat picture, Milestone 40), U (push-ups after DOWN), V (sit-ups before the first press), G (football), J (football on a touch screen: the joystick), Y (asleep in the day: the light stripes), O (the exercise menu), Q (the entertainment menu), L (Let's eat), T (the good-food canteen with two foods on the plate), I (the fast-food one), p (noon, health 3.7, with the rating pop-up after push-ups).

## [name, minute of the day, health, XP].
const STATES := {
	"A": ["A_dawn", 6 * 60 + 30, 2.5, 220.0],
	"B": ["B_morning", 9 * 60, 3.0, 245.0],
	"C": ["C_noon", 12 * 60, 3.5, 270.0],
	"D": ["D_afternoon", 16 * 60 + 30, 4.0, 290.0],
	"E": ["E_sunset", 19 * 60 + 15, 3.7, 298.0],
	"F": ["F_night", 22 * 60 + 15, 3.0, 300.0],
	"P": ["P_pressed_disabled", 12 * 60, 3.0, 270.0],
	"X": ["X_danger", 12 * 60, 2.2, 240.0],
	"R": ["R_room", 13 * 60, 3.0, 250.0],
	"S": ["S_street", 17 * 60, 3.0, 250.0],
	"Z": ["Z_bedroom", 22 * 60, 3.0, 250.0],
	"W": ["W_sleep_over", 6 * 60 + 40, 3.0, 250.0],
	"K": ["K_squats", 11 * 60, 3.0, 250.0],
	"U": ["U_push_ups", 11 * 60, 3.0, 250.0],
	"V": ["V_sit_ups", 11 * 60, 3.0, 250.0],
	"G": ["G_football", 16 * 60, 3.0, 250.0],
	"J": ["J_football_touch", 16 * 60, 3.0, 250.0],
	"Y": ["Y_day_sleep", 14 * 60, 3.0, 250.0],
	"O": ["O_exercise_menu", 10 * 60, 3.0, 250.0],
	"Q": ["Q_entertainment_menu", 10 * 60, 3.0, 250.0],
	"L": ["L_lets_eat", 10 * 60, 3.0, 250.0],
	"T": ["T_canteen_good", 10 * 60, 3.0, 250.0],
	"I": ["I_canteen_fast", 10 * 60, 3.0, 250.0],
	"p": ["p_feedback_popup", 12 * 60, 3.7, 250.0],
	"H": ["H_measures_sleep", 18 * 60, 3.0, 250.0],
	"g": ["g_video_game", 15 * 60, 3.0, 250.0],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://ui_states"
	var letter: String = args[1] if args.size() > 1 else "A"
	DirAccess.make_dir_recursive_absolute(out)
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://render_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://render_settings.json"
	settings.use_web_storage = false
	settings.set_language(args[2] if args.size() > 2 else "en")
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	activities.reset()
	root.get_node("Minigame").reset()
	gs.reset()
	clock.reset()
	if letter == "M" or letter == "N":
		var scene := "res://scenes/ui/menu.tscn" if letter == "M" else "res://scenes/ui/creation.tscn"
		var screen: Node = load(scene).instantiate()
		root.add_child(screen)
		if letter == "N":
			# A name and three choices made, as in the team's picture (Milestone 40).
			screen.get_node("%NameEdit").text = "Alex"
			for path in ["%AgeButtons", "%SexButtons", "%DifficultyButtons"]:
				var first: Button = screen.get_node(path).get_child(0)
				first.button_pressed = true
				first.pressed.emit()
		await _save(out, "M_menu" if letter == "M" else "N_creation")
		return
	# A fourth argument "teen" renders a teenage girl (Milestone 40: the other sheets' pictures).
	if args.size() > 3 and args[3] == "teen":
		gs.start_new_avatar("Ana", "teenager", "female", "normal")
	else:
		gs.start_new_avatar("Ana", "child", "male", "normal")
	var state: Array = STATES[letter]
	# The time of day: set the phase start too, or the Clock works it out again (handoff.md).
	clock._phase_start_minute = state[1]
	clock.minute_of_day = state[1]
	clock.day_elapsed_hours = 0.0
	gs.health = state[2]
	gs.xp = state[3]
	match letter:
		"X":
			gs.weight_z = -3.5
		"R":
			# A plate of the canteen: the fork carries its first food's picture.
			activities.start("eat", "healthy_meal")
			activities.plate = ["apple", "rice"]
		"S":
			activities.start("exercise", "cardio", 0.5)
		"K":
			activities.start("exercise", "strength", 0.5)
		"U":
			activities.start("exercise", "push_ups", 0.5)
		"V":
			activities.start("exercise", "sit_ups", 0.5)
		"G", "J":
			root.get_node("Settings").football_help_seen = true
			activities.start("entertainment", "football", 1.0)
		"Z", "Y":
			gs.hours_awake = 6.0
			activities.start("sleep", "sleep", 8.0)
		"g":
			activities.start("entertainment", "screens", 0.5)
		"H":
			gs.sleep_debt = 2.4
			gs.sleep_need = 3.75
			gs.sleep = 0.7
		"W":
			gs.hours_awake = 6.0
			activities.start("sleep", "sleep", 8.0)
			clock.stop_sleep()
	clock.halted = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if letter == "P":
		main.exercise_button.button_down.emit()
		main.eat_button.disabled = true
	if letter == "S":
		root.get_node("Minigame").tap()
	if letter == "O":
		main._open_options("exercise")
	if letter == "Q":
		main._open_options("entertainment")
	if letter == "L":
		main.canteen.open()
	if letter == "T" or letter == "I":
		main.canteen.open()
		main.canteen.show_kind("good" if letter == "T" else "fast_food")
		for id in (["salad", "grilled_fish"] if letter == "T" else ["burger", "fries"]):
			main.canteen.add_food(id)
	if letter == "p":
		main.feedback_popup.show_text(main.tr("FEEDBACK_PUSH_UPS_BAD"))
		main.feedback_popup._tween.kill()
		main.feedback_popup.modulate.a = 1.0
	if letter == "J":
		main.football_pad.touch_mode = true
	if letter == "K" or letter == "U":
		root.get_node("Minigame").press(true)
	if letter == "H":
		main._toggle_health_panel()
	if letter == "g":
		# A run 1.2 s in: the dinosaur runs on the first cloud, the next ones ahead
		# (the team's pictures, 22 Nov 2026).
		var minigame: Node = root.get_node("Minigame")
		minigame.jump(true)
		minigame.jump(false)
		minigame.run.advance(1.2)
	await _save(out, state[0])


func _save(out: String, name: String) -> void:
	for i in 12:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png(out.path_join(name + ".png"))
	print("saved ", out.path_join(name + ".png"))
	root.get_node("Clock").halted = false
	DirAccess.remove_absolute("user://render_save.json")
	DirAccess.remove_absolute("user://render_settings.json")
	quit()
