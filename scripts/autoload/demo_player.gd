extends Node
## The demo player (22 Nov 2026, for the videos the team's task list asks for, sheet 2 of
## Bio-Streams-tasks.xlsx): it plays the game by itself, for Godot's Movie Maker.
##
## It does nothing unless Godot is started with the user argument --demo=<scenario> (after "--"),
## so the normal game, the web build and the tests never run it. tools/record_demo.sh records
## every scenario into captures/ and runs Godot with a separate user folder, so the player's own
## saves and settings are never touched. Other user arguments: --lang=en|pt (the game's language
## and the captions), --shots=<folder> (where the PNG screenshots go).
##
## It plays like a person: real mouse clicks and key presses (Input.parse_input_event), a white
## ring where it taps, the minigames played on time (and sometimes badly on purpose, to show what
## the score does). The fast video (scenario "health") calls Activities directly at x1500 speed
## (Clock.debug_speed), as the scenario tests do. Captions explain what is happening; their
## wording follows the rules in CLAUDE.md (no rule is invented here). Nothing here changes a game
## rule: it only presses what a player can press.
##
## Scenarios: menu, screens, cardio, squats, push_ups, sit_ups, meal, football, video_game, sleep,
## health. Each ends with get_tree().quit().

const MAIN_SCENE := "res://scenes/main.tscn"
const THEME := "res://scenes/ui/main_theme.tres"
const SCENARIOS := ["menu", "screens", "cardio", "squats", "push_ups", "sit_ups", "meal", "football",
		"video_game", "sleep", "health"]
## The fast video's speed (sheet 2: "vídeo ultra rápido x1500").
const FAST_SPEED := 1500.0
## Fast-forwards inside the other videos (the clock shows "x" and the speed).
const EVENING_SPEED := 150.0
const NIGHT_SPEED := 400.0
## Where captions go, so they cover nothing important: over the speech balloon (minigames, where
## it is hidden), on the ground under the avatar (the main screen), between the menu's figures and
## its buttons, and over the creation screen's title.
const CAPTION_PLACES := {"top": 214.0, "ground": 800.0, "menu": 612.0, "title": 40.0}
const CAPTION_FONT := 27

const CAPTIONS := {
	"menu_title": {"en": "The main menu", "pt": "O menu principal"},
	"menu_lang": {"en": "Portuguese or English", "pt": "Português ou inglês"},
	"menu_about": {"en": "About the game", "pt": "Sobre o jogo"},
	"menu_avatars": {"en": "Up to three avatars, with backups", "pt": "Até três avatares, com cópias de segurança"},
	"menu_new": {"en": "A new avatar", "pt": "Um novo avatar"},
	"creation": {"en": "Name, age group, sex and difficulty", "pt": "Nome, idade, sexo e dificuldade"},
	"creation_start": {"en": "Start", "pt": "Começar"},
	"main_first": {"en": "The avatar's day begins", "pt": "Começa o dia do avatar"},
	"cardio_intro": {"en": "How a minigame works: cardio", "pt": "Como funciona um minijogo: cardio"},
	"choose_minutes": {"en": "Choose the minutes, then the exercise", "pt": "Escolhe os minutos e depois o exercício"},
	"cardio_tap": {"en": "Tap in rhythm: each tap is one stride", "pt": "Toca ao ritmo: cada toque é uma passada"},
	"cardio_beat": {"en": "The Beat bar shows when the next tap should come", "pt": "A barra de ritmo mostra quando deve vir o próximo toque"},
	"cardio_bad": {"en": "Taps too early or too late lower the score", "pt": "Toques cedo ou tarde demais baixam a pontuação"},
	"cardio_breath": {"en": "Breath falls while running; at 0 the avatar walks", "pt": "O fôlego desce a correr; a 0 o avatar caminha"},
	"cardio_score": {"en": "Score = rhythm + pace. Training counts minutes × score:\na better score trains fitness more", "pt": "Pontuação = ritmo + passo. O treino conta minutos × pontuação:\nmelhor pontuação treina mais a condição física"},
	"slow_change": {"en": "Fitness and strength change slowly, over days", "pt": "A condição física e a força mudam devagar, ao longo de dias"},
	"strength_intro": {"en": "Strength: squats, push-ups and sit-ups, done for real", "pt": "Força: agachamentos, flexões e abdominais, feitos a sério"},
	"strength_press": {"en": "Down, then Up, one second apart", "pt": "Baixo e depois Cima, com um segundo entre eles"},
	"strength_rush": {"en": "Rushing tires the Strength bar faster", "pt": "Apressar cansa mais depressa a barra de força"},
	"strength_rest": {"en": "A set ends at its repetitions; a short rest refills the bar", "pt": "Uma série acaba nas repetições; um descanso curto enche a barra"},
	"strength_score": {"en": "Score = technique + repetitions done:\nit multiplies the strength training", "pt": "Pontuação = técnica + repetições feitas:\nmultiplica o treino de força"},
	"meal_intro": {"en": "Eat: good food or fast food", "pt": "Comer: comida boa ou fast food"},
	"meal_plate": {"en": "Build a plate of up to four foods", "pt": "Monta um prato com até quatro alimentos"},
	"meal_fork": {"en": "Tap Bite when the fork is in the ring at the mouth", "pt": "Toca em Morder quando o garfo está no anel da boca"},
	"meal_miss": {"en": "A miss drops the food", "pt": "Se falhares, a comida cai"},
	"meal_full": {"en": "Green: the avatar is full. Done stops the meal", "pt": "Verde: o avatar está cheio. Feito acaba a refeição"},
	"meal_score": {"en": "kcal = bites ÷ 10 × portion: stopping when full means fewer kcal.\nFast food has more kcal and lowers diet quality", "pt": "kcal = dentadas ÷ 10 × porção: parar quando cheio dá menos kcal.\nA fast food tem mais kcal e baixa a qualidade da dieta"},
	"football_intro": {"en": "Football with friends", "pt": "Futebol com os amigos"},
	"football_help": {"en": "The first time, a short explanation", "pt": "Da primeira vez, uma explicação curta"},
	"football_play": {"en": "Move, pass to a free team-mate, shoot in range", "pt": "Move-te, passa a um colega livre, remata ao alcance"},
	"football_breath": {"en": "Breath falls while moving and refills standing still", "pt": "O fôlego desce a mexer e enche parado"},
	"football_score": {"en": "Score = good timing + time spent moving.\nFootball counts as cardio and as fun", "pt": "Pontuação = bom momento + tempo a mexer.\nO futebol conta como cardio e como diversão"},
	"sky_intro": {"en": "The video game: jump from cloud to cloud", "pt": "O videojogo: salta de nuvem em nuvem"},
	"sky_fall": {"en": "Falling ends the run; the best scores go to a board", "pt": "Cair acaba a corrida; as melhores pontuações vão para um quadro"},
	"sky_score": {"en": "The score never changes health.\nScreen time counts as entertainment", "pt": "A pontuação nunca muda a saúde.\nO tempo de ecrã conta como entretenimento"},
	"sleep_evening": {"en": "Later that day (fast-forward)", "pt": "Mais tarde nesse dia (avanço rápido)"},
	"sleep_tired": {"en": "In the evening the avatar gets tired", "pt": "À noite o avatar fica cansado"},
	"sleep_hours": {"en": "Choose how many hours to sleep", "pt": "Escolhe quantas horas dormir"},
	"sleep_real": {"en": "The night takes real time: 10 hours = 2 real hours", "pt": "A noite leva tempo real: 10 horas = 2 horas reais"},
	"sleep_fast": {"en": "Fast-forward", "pt": "Avanço rápido"},
	"sleep_morning": {"en": "Morning: Wake up starts the day", "pt": "Manhã: Acordar começa o dia"},
	"sleep_debt": {"en": "Less sleep than needed builds sleep debt: it lowers the Sleep measure,\ntraining and exercise capacity", "pt": "Dormir menos do que é preciso cria dívida de sono: baixa a medida do sono,\no treino e a capacidade de exercício"},
	"health_good": {"en": "×1500: good habits (healthy meals, exercise, enough sleep)", "pt": "×1500: bons hábitos (refeições saudáveis, exercício, sono suficiente)"},
	"health_top": {"en": "Health rises toward its top", "pt": "A saúde sobe até ao seu máximo"},
	"health_bad": {"en": "×1500: bad habits (fast food, screens, no sleep)", "pt": "×1500: maus hábitos (fast food, ecrãs, sem dormir)"},
	"health_falls": {"en": "Health falls until failure", "pt": "A saúde desce até à falha"},
	"health_hungry": {"en": "...and no food at all", "pt": "...e nenhuma comida"},
}

var active := false
## --verbose: every tap and caption in the log.
var verbose := false
## Captions over the video: off since 23 Nov 2026 (user: no explanations); --captions shows them.
var captions := false
var scenario := ""
var lang := "en"
var shots_dir := ""

var _overlay: CanvasLayer
var _caption_box: PanelContainer
var _caption: Label
var _caption_place := "top"
var _taps: Control
var _now := 0.0
var _error_count := 0
## Health video: what the player did today (reset when a day starts).
var _done := {}


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--demo"):
			active = true
			scenario = argument.get_slice("=", 1) if argument.contains("=") else "menu"
		elif argument.begins_with("--lang="):
			lang = argument.get_slice("=", 1)
		elif argument == "--verbose":
			verbose = true
		elif argument == "--captions":
			captions = true
		elif argument.begins_with("--shots="):
			shots_dir = argument.get_slice("=", 1)
	set_process(active)
	if not active:
		return
	if not scenario in SCENARIOS:
		push_error("DEMO ERROR: unknown scenario %s (one of %s)" % [scenario, SCENARIOS])
		get_tree().quit(1)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000
	if shots_dir.is_empty():
		shots_dir = ProjectSettings.globalize_path("user://demo_shots")
	DirAccess.make_dir_recursive_absolute(shots_dir)
	_now = Time.get_unix_time_from_system()
	Settings.set_language(lang)
	_build_overlay()
	print("DEMO: scenario %s, language %s, screenshots in %s" % [scenario, lang, shots_dir])
	_run.call_deferred()


## The device clock only counts during sleep (Milestone 23). Movie Maker renders slower or faster
## than real time, so the demo gives the Clock a clock that moves with the frames.
##
## macOS does not draw a window that other windows cover (DisplayServer.window_can_draw() is
## false), and the game's 720 x 1280 window is taller than many laptop screens, so Movie Maker
## would record the same picture again and again. The demo then draws each frame itself; it runs
## after every other node (process_priority), so the frame shows this frame's state.
func _process(delta: float) -> void:
	_now += delta
	Clock.now_override = _now
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false, delta)
	if verbose and Engine.get_process_frames() % 120 == 0:
		print("DEMO: frame %d delta %.4f drawn %d can_draw %s" % [Engine.get_process_frames(), delta,
				Engine.get_frames_drawn(), DisplayServer.window_can_draw()])


func _run() -> void:
	await _wait(0.5)
	await Callable(self, "_scenario_" + scenario).call()
	print("DEMO: done (%d problems)" % _error_count)
	await _wait(0.5)
	get_tree().quit(0 if _error_count == 0 else 2)


# --- Scenarios ---------------------------------------------------------------------------------

## The splash screen and its functions, then the creation screen (sheet 2, item 4).
func _scenario_menu() -> void:
	await _scene("Menu")
	_caption_place = "menu"
	_say("menu_title")
	await _wait(3.0)
	await _shot("menu")
	var toggle := _find(func(n: Node) -> bool: return n.get_script() == preload("res://scripts/ui/language_toggle.gd"))
	if toggle:
		_say("menu_lang")
		var rect := _rect(toggle)
		var other := Vector2(rect.position.x + rect.size.x * (0.75 if lang == "pt" else 0.25), rect.get_center().y)
		var back := Vector2(rect.position.x + rect.size.x * (0.25 if lang == "pt" else 0.75), rect.get_center().y)
		await _press_at(other)
		await _wait(2.0)
		await _press_at(back)
		await _wait(1.5)
	_say("menu_about")
	await _click(_button("MENU_ABOUT"))
	await _wait(4.0)
	await _click(_button("MENU_BACK"))
	await _wait(1.0)
	_say("menu_avatars")
	await _click(_button("MENU_AVATARS"))
	await _wait(3.5)
	await _click(_button("MENU_BACK"))
	await _wait(1.0)
	_say("menu_new")
	await _click(_button("MENU_NEW_AVATAR"))
	var creation := await _scene("Creation")
	if creation == null:
		return
	_caption_place = "title"
	_say("creation")
	await _wait(1.5)
	await _click(creation.name_edit)
	await _type("Ana")
	await _wait(0.8)
	await _click(creation.age_buttons.get_child(0))
	await _wait(0.8)
	await _click(creation.sex_buttons.get_child(1))
	await _wait(0.8)
	await _click(creation.difficulty_buttons.get_child(1))
	await _wait(2.0)
	await _shot("creation")
	_say("creation_start")
	await _click(creation.start_button)
	await _scene("Main")
	_caption_place = "ground"
	_say("main_first")
	await _wait(5.0)
	await _shot("main_first")
	_say("")
	await _wait(1.0)


## The main screen by day and by night, with no captions: images for sheet 2, item 3.
func _scenario_screens() -> void:
	var main := await _new_avatar("Rui", "child", "male", "normal")
	if main == null:
		return
	await _wait(3.0)
	await _shot("main_morning")
	await _click(main.health_button)
	await _wait(1.5)
	await _shot("main_measures")
	await _click(main.physical_button)
	await _wait(2.0)
	await _shot("main_values")
	await _click(main.health_button)
	await _wait(1.0)
	await _click(main.exercise_button)
	await _wait(2.0)
	await _shot("main_exercise_menu")
	await _click(main.options_cancel)
	await _wait(1.0)
	await _fast_until(func() -> bool: return Clock.minute_of_day >= 12 * 60, EVENING_SPEED)
	await _wait(2.0)
	await _shot("main_noon")
	await _fast_until(func() -> bool: return Clock.minute_of_day >= 19 * 60 + 15, EVENING_SPEED)
	await _wait(2.0)
	await _shot("main_sunset")
	await _fast_until(func() -> bool: return Clock.minute_of_day >= 20 * 60 + 30, EVENING_SPEED)
	await _wait(2.0)
	await _shot("main_night")
	await _click(main.sleep_button)
	await _wait(1.5)
	if main.sleep_panel.visible:
		# Long enough to end after sunrise, for the day picture of the bedroom.
		await _set_slider(main.sleep_slider, 11.5)
		await _shot("main_sleep_panel")
		await _click(main.get_node("%SleepStartButton"))
	await _wait(3.0)
	await _shot("bedroom_night")
	await _fast_until(_bed_by_day, NIGHT_SPEED)
	await _wait(2.0)
	await _shot("bedroom_day")
	await _fast_until(func() -> bool: return Clock.phase == Clock.Phase.SLEEP_OVER, NIGHT_SPEED)
	await _wait(2.5)
	await _shot("bedroom_morning")
	await _click(main.stop_button)
	await _wait(3.0)
	await _shot("main_next_morning")


## How a minigame works, step by step (sheet 2, item 1), and how its score acts (item 2).
func _scenario_cardio() -> void:
	var main := await _new_avatar("Rui", "child", "male", "normal")
	if main == null:
		return
	_say("cardio_intro")
	await _wait(2.5)
	_caption_place = "title"
	_say("choose_minutes")
	await _click(main.exercise_button)
	await _wait(1.2)
	await _set_slider(main.minutes_slider, 30.0)
	await _click(main.option_buttons.get_child(0))
	await _wait(0.6)
	await _click(main.options_start)
	_caption_place = "top"
	await _wait(1.0)
	_say("cardio_tap")
	await _tap_cardio(main, 10.0, true)
	_say("cardio_beat")
	await _tap_cardio(main, 7.0, true)
	await _shot("cardio")
	_say("cardio_bad")
	await _tap_cardio(main, 7.0, false)
	_say("cardio_breath")
	await _tap_cardio(main, 60.0, true)
	await _after_session(main, "cardio_score")


func _scenario_squats() -> void:
	await _strength_video(1, "squats")


func _scenario_push_ups() -> void:
	await _strength_video(2, "push_ups")


func _scenario_sit_ups() -> void:
	await _strength_video(3, "sit_ups")


func _strength_video(tile: int, shot_name: String) -> void:
	var main := await _new_avatar("Rui", "child", "male", "normal")
	if main == null:
		return
	_caption_place = "title"
	_say("strength_intro")
	await _click(main.exercise_button)
	await _wait(1.2)
	await _set_slider(main.minutes_slider, 25.0)
	await _click(main.option_buttons.get_child(tile))
	await _wait(0.6)
	await _click(main.options_start)
	_caption_place = "top"
	await _wait(1.5)
	_say("strength_press")
	await _press_strength(main, 9.0, false)
	await _shot(shot_name)
	_say("strength_rush")
	await _press_strength(main, 3.0, true)
	_say("strength_rest")
	await _press_strength(main, 60.0, false)
	await _after_session(main, "strength_score")


func _scenario_meal() -> void:
	var main := await _new_avatar("Ana", "child", "female", "normal")
	if main == null:
		return
	# The canteen covers the middle of the screen: captions over the HUD.
	_caption_place = "title"
	_say("meal_intro")
	await _click(main.eat_button)
	await _wait(2.0)
	var canteen: Node = main.canteen
	await _click(canteen.good_button)
	await _wait(1.2)
	await _click(canteen.continue_button)
	await _wait(1.0)
	_say("meal_plate")
	for id in ["grilled_fish", "rice", "salad", "water"]:
		await _click(_food_tile(canteen.good_grid, id))
		await _wait(0.7)
	await _wait(1.0)
	await _shot("meal_plate")
	await _click(canteen.eat_button)
	_caption_place = "top"
	await _wait(1.5)
	_say("meal_fork")
	var missed := false
	while Minigame.running and Minigame.kind == Minigame.MEAL and Minigame.bites < 7:
		if Minigame.bites == 3 and not missed:
			_say("meal_miss")
			await _wait_until(func() -> bool: return absf(Minigame.fork_position()) > 0.85, 5.0)
			await _click(main.bite_button, 0.08)
			missed = true
			await _wait(1.2)
			_say("meal_fork")
			continue
		await _wait_until(func() -> bool: return _fork_coming(), 6.0)
		await _click(main.bite_button, 0.08)
		await _wait(0.4)
		if Minigame.bites == 2:
			await _shot("meal_fork")
	_say("meal_full")
	await _wait(3.0)
	await _click(main.done_button)
	await _after_session(main, "meal_score")


func _scenario_football() -> void:
	var main := await _new_avatar("Rui", "child", "male", "normal")
	if main == null:
		return
	_caption_place = "title"
	_say("football_intro")
	await _click(main.entertainment_button)
	await _wait(1.2)
	await _set_slider(main.minutes_slider, 15.0)
	await _click(main.option_buttons.get_child(1))
	await _wait(0.6)
	await _click(main.options_start)
	_caption_place = "top"
	await _wait(1.0)
	if main.football_help.visible:
		_say("football_help")
		await _wait(5.0)
		await _click(main.football_help._play)
		await _wait(0.5)
	_say("football_play")
	await _play_football(main, 22.0)
	await _shot("football")
	_say("football_breath")
	await _play_football(main, 22.0)
	_say("")
	await _play_football(main, 14.0)
	_release_keys()
	if Minigame.running:
		await _click(main.football_stop)
	await _after_session(main, "football_score")


func _scenario_video_game() -> void:
	var main := await _new_avatar("Rui", "teenager", "male", "normal")
	if main == null:
		return
	_caption_place = "title"
	_say("sky_intro")
	await _click(main.entertainment_button)
	await _wait(1.2)
	await _set_slider(main.minutes_slider, 40.0)
	await _click(main.option_buttons.get_child(0))
	await _wait(0.6)
	await _click(main.options_start)
	_caption_place = "top"
	await _wait(2.0)
	await _play_sky(main, 5.0, true)
	_say("")
	await _play_sky(main, 9.0, true)
	await _shot("video_game")
	_say("sky_fall")
	# Stops jumping, so the run ends and the board shows.
	await _wait_until(func() -> bool: return Minigame.run == null or Minigame.run.is_over(), 12.0)
	await _wait(3.0)
	await _shot("video_game_over")
	_say("")
	await _play_sky(main, 20.0, true)
	_say("sky_score")
	await _play_sky(main, 6.0, true)
	if Activities.is_running():
		await _click(main.stop_button if main.stop_button.visible else main.cardio_stop)
	await _wait(4.0)


func _scenario_sleep() -> void:
	var main := await _new_avatar("Ana", "teenager", "female", "normal")
	if main == null:
		return
	_caption_place = "ground"
	_say("sleep_evening")
	await _fast_until(func() -> bool: return Clock.minute_of_day >= 20 * 60 + 40, EVENING_SPEED)
	_say("sleep_tired")
	await _wait(3.0)
	await _click(main.sleep_button)
	await _wait(1.0)
	_say("sleep_hours")
	await _set_slider(main.sleep_slider, 9.0)
	await _wait(1.5)
	await _click(main.get_node("%SleepStartButton"))
	await _wait(1.0)
	_caption_place = "top"
	_say("sleep_real")
	await _wait(5.0)
	await _shot("sleep_night")
	_say("sleep_fast")
	await _fast_until(func() -> bool: return Clock.phase == Clock.Phase.SLEEP_OVER, NIGHT_SPEED)
	_say("sleep_morning")
	await _wait(3.0)
	await _shot("sleep_morning")
	await _click(main.stop_button)
	await _wait(1.5)
	_caption_place = "ground"
	_say("sleep_debt")
	await _click(main.health_button)
	await _wait(6.0)
	await _click(main.health_button)
	_say("")
	await _wait(1.0)


## Health rising to its top with good habits and falling to failure with bad ones, x1500; the
## failure screen stays a few seconds (sheet 2, item 5).
func _scenario_health() -> void:
	var main := await _new_avatar("Rui", "child", "male", "normal")
	if main == null:
		return
	await _wait(1.5)
	await _click(main.health_button)
	_caption_place = "ground"
	_say("health_good")
	Clock.day_started.connect(func(_slept: bool) -> void: _done.clear())
	Clock.debug_speed = FAST_SPEED
	var history: Array[float] = []
	var last_day := Clock.day_number
	while true:
		await get_tree().process_frame
		_good_player()
		if Clock.day_number != last_day:
			last_day = Clock.day_number
			history.append(GameState.health)
			print("DEMO: day %d health %.2f target %.2f" % [last_day, GameState.health, GameState.target_health])
			if history.size() == 6:
				_say("health_top")
			var flat := history.size() >= 10 and history[-1] - history[-4] < 0.03
			if flat or GameState.health >= 4.9 or history.size() >= 40:
				break
	Activities.stop()
	_say("health_bad")
	var bad_days := 0
	while GameState.failed_cause.is_empty():
		await get_tree().process_frame
		_bad_player(bad_days >= 14)
		if Clock.day_number != last_day:
			last_day = Clock.day_number
			bad_days += 1
			print("DEMO: bad day %d health %.2f target %.2f happiness %.2f" % [bad_days, GameState.health,
					GameState.target_health, GameState.happiness])
			if bad_days == 3:
				_say("health_falls")
			if bad_days == 14:
				_say("health_hungry")
			if bad_days > 30:
				_problem("no failure after 30 bad days")
				break
	Clock.debug_speed = 1.0
	_say("")
	print("DEMO: failure %s on day %d" % [GameState.failed_cause, Clock.day_number])
	await _wait(5.0)
	await _shot("failure")
	if main.failure_screen.visible:
		await _click(main.failure_screen.details_button)
		await _wait(6.0)
		await _shot("failure_details")
	await _wait(2.0)


# --- Players of the fast video ------------------------------------------------------------------

func _good_player() -> void:
	if Clock.phase == Clock.Phase.SLEEP_OVER:
		Clock.wake_up()
		return
	if Activities.is_running() or Clock.phase == Clock.Phase.SLEEPING:
		return
	var hour := Clock.minute_of_day / 60.0
	var left := Clock.day_length_hours - Clock.day_elapsed_hours
	var target: float = SleepModelScript.recommended(GameState.age_group)["target"]
	if Hunger.is_hungry():
		Activities.start("eat", "healthy_meal")
	elif left < 1.2 or (GameState.tired and SleepModelScript.can_sleep()):
		if SleepModelScript.can_sleep():
			Activities.start("sleep", "sleep", minf(target, Clock.max_sleep_hours()))
	elif not _done.has("cardio") and hour >= 9.0:
		_done["cardio"] = true
		Activities.start("exercise", "cardio", 0.75)
	elif not _done.has("strength") and hour >= 11.0 and GameState.hours_since_strength >= 40.0:
		_done["strength"] = true
		Activities.start("exercise", "strength", 0.5)
	elif not _done.has("football") and hour >= 15.0:
		_done["football"] = true
		Activities.start("entertainment", "football", 1.0)
	elif not _done.has("screens") and hour >= 18.0:
		_done["screens"] = true
		Activities.start("entertainment", "screens", 1.0)


func _bad_player(no_food: bool) -> void:
	if Clock.phase == Clock.Phase.SLEEP_OVER:
		Clock.wake_up()
		return
	if Hunger.is_hungry() and not no_food:
		if Activities.is_running():
			Activities.stop()
		Activities.start("eat", "fast_food_meal")
	elif not Activities.is_running():
		Activities.start("entertainment", "screens", 4.0)


# --- Minigame players ---------------------------------------------------------------------------

## Cardio: taps on the beat (good) or off it (bad), for this many seconds or until it ends.
func _tap_cardio(main: Node, seconds: float, good: bool) -> void:
	var left := seconds
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	while left > 0.0 and Minigame.running and Minigame.kind == Minigame.CARDIO:
		var gap: float = Minigame.interval() * (1.0 if good else rng.randf_range(0.45, 1.7))
		await _click(main.tap_button, 0.08)
		await _wait(maxf(0.05, gap - 0.08))
		left -= gap


## Strength: Down and Up on the beat (one press_seconds apart), or rushed; waits while resting.
func _press_strength(main: Node, seconds: float, rushed: bool) -> void:
	var left := seconds
	while left > 0.0 and Minigame.running and Minigame.kind == Minigame.STRENGTH:
		if Minigame.resting:
			await _wait(0.2)
			left -= 0.2
			continue
		var button: Control = main.down_button if Minigame.next_down else main.up_button
		var gap: float = Minigame.interval() * (0.45 if rushed else 1.0)
		await _click(button, 0.08)
		await _wait(maxf(0.05, gap - 0.08))
		left -= gap


## Meal: the fork is close to the mouth and coming closer.
var _last_fork := 0.0
func _fork_coming() -> bool:
	var fork := Minigame.fork_position()
	var coming := absf(fork) < absf(_last_fork)
	_last_fork = fork
	var share: float = Config.get_float("minigame.meal.hit_share")
	return coming and absf(fork) < share * 0.9


## Football: runs to the ball, shoots in range, passes when pressed, tackles when it can.
func _play_football(_main: Node, seconds: float) -> void:
	var left := seconds
	var since_action := 0.0
	while left > 0.0 and Minigame.running and Minigame.kind == Minigame.FOOTBALL:
		var game: RefCounted = Minigame.game
		var me: Vector2 = game.positions[0]
		var goal: Vector2 = game._goal(0)
		var aim: Vector2 = game.ball
		if game.has_ball():
			aim = goal
			if since_action > 0.6 and game.in_shot_range():
				_key_tap(KEY_X)
				since_action = 0.0
			elif since_action > 0.6 and game.under_pressure():
				_key_tap(KEY_Z)
				since_action = 0.0
		elif game.team_mate_has_ball():
			aim = me.lerp(goal, 0.5)
			if since_action > 1.0:
				_key_tap(KEY_X if game.team_mate_in_shot_range() else KEY_Z)
				since_action = 0.0
		elif game.can_tackle() and game.in_tackle_reach() and since_action > 0.8:
			_key_tap(KEY_X)
			since_action = 0.0
		_steer(aim - me if me.distance_to(aim) > 8.0 else Vector2.ZERO)
		await _wait(0.1)
		left -= 0.1
		since_action += 0.1
	_release_keys()


## The video game: jumps at the end of each cloud.
func _play_sky(main: Node, seconds: float, playing: bool) -> void:
	var left := seconds
	while left > 0.0 and Minigame.running and Minigame.kind == Minigame.SKY and playing:
		var run: RefCounted = Minigame.run
		if run == null or run.state == SkyRun.State.READY or run.is_over():
			if run == null or run.state == SkyRun.State.READY or run.can_restart():
				await _click(main.jump_button, 0.08)
		elif run.state == SkyRun.State.RUNNING and run.grounded and not run._support.is_empty():
			var edge: float = run._support.x + run._support.w
			if run.x + Config.get_float("minigame.sky.dino_width") * 0.35 >= edge - run.speed * 0.06:
				await _click(main.jump_button, 0.1)
		await get_tree().process_frame
		left -= get_process_delta_time()


# --- After a session ----------------------------------------------------------------------------

func _after_session(main: Node, caption: String) -> void:
	await _wait_until(func() -> bool: return not Minigame.running, 90.0)
	_caption_place = "ground"
	await _wait(1.5)
	await _shot("%s_result" % scenario)
	_say(caption)
	await _wait(5.0)
	await _click(main.health_button)
	await _wait(1.0)
	await _click(main.physical_button)
	_say("slow_change")
	await _wait(5.0)
	await _click(main.health_button)
	_say("")
	await _wait(1.0)


# --- Setup --------------------------------------------------------------------------------------

const SleepModelScript := preload("res://scripts/health/sleep_model.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const SkyRun := preload("res://scripts/health/sky_run.gd")


## A new avatar in place 1 of the demo's own user folder, on the main screen.
func _new_avatar(avatar_name: String, age: String, sex: String, difficulty: String) -> Node:
	await _scene("Menu")
	SaveGame.start_slot(0)
	GameState.start_new_avatar(avatar_name, age, sex, difficulty)
	Clock.set_paused(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
	_caption_place = "ground"
	return await _scene("Main")


## Waits until the current scene is the one with this root name and is ready.
func _scene(root_name: String) -> Node:
	var ok := await _wait_until(func() -> bool:
		var scene := get_tree().current_scene
		return scene != null and scene.name == root_name and scene.is_node_ready(), 20.0)
	if not ok:
		_problem("scene %s did not open" % root_name)
		return null
	await _wait(0.3)
	return get_tree().current_scene


## Fast-forward (the clock shows the speed) until cond is true, then normal speed again.
## Still asleep, and the sun is up (the day picture of the bedroom).
func _bed_by_day() -> bool:
	return Clock.phase == Clock.Phase.SLEEPING and Clock.minute_of_day >= 7 * 60 + 50 and Clock.minute_of_day < 12 * 60


## The avatar eats a healthy meal whenever it is hungry meanwhile (unplayed: at a debug speed a
## meal runs without its minigame, as in the scenario tests), so it is not starving afterwards.
func _fast_until(cond: Callable, speed: float) -> void:
	Clock.debug_speed = speed
	var waited := 0.0
	while not cond.call() and waited < 120.0:
		if Hunger.is_hungry() and not Activities.is_running() and Clock.phase == Clock.Phase.DAY:
			Activities.start("eat", "healthy_meal")
		await get_tree().process_frame
		waited += get_process_delta_time()
	Clock.debug_speed = 1.0
	var scene := get_tree().current_scene
	if scene and scene.has_method("_refresh_clock"):
		scene._refresh_clock()


# --- Input --------------------------------------------------------------------------------------

## A tap on the middle of a control: a real mouse press and release where it is, and a ring.
func _click(control: Variant, hold := 0.12) -> void:
	if not control is Control or not is_instance_valid(control) or not control.is_visible_in_tree():
		_problem("cannot click %s" % [control])
		return
	await _press_at(_rect(control).get_center(), hold)


func _press_at(at: Vector2, hold := 0.12) -> void:
	if verbose:
		print("DEMO: tap at %s (frame %d)" % [at, Engine.get_process_frames()])
	_show_tap(at)
	var place: Vector2 = get_tree().root.get_final_transform() * at
	var motion := InputEventMouseMotion.new()
	motion.position = place
	motion.global_position = place
	Input.parse_input_event(motion)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = place
	down.global_position = place
	down.pressed = true
	Input.parse_input_event(down)
	await _wait(hold)
	var up: InputEventMouseButton = down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


## A slider moves to a value, with a ring on its grabber.
func _set_slider(slider: Range, value: float) -> void:
	if not slider is Control or not slider.is_visible_in_tree():
		_problem("slider not visible")
		return
	var rect := _rect(slider)
	var steps := 12
	var start := slider.value
	for i in steps + 1:
		slider.value = lerpf(start, value, float(i) / steps)
		var share := inverse_lerp(slider.min_value, slider.max_value, slider.value)
		_show_tap(Vector2(rect.position.x + rect.size.x * share, rect.get_center().y))
		await _wait(0.05)
	await _wait(0.5)


func _type(text: String) -> void:
	for character in text:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.keycode = OS.find_keycode_from_string(character.to_upper())
		event.physical_keycode = event.keycode
		event.pressed = true
		Input.parse_input_event(event)
		var release: InputEventKey = event.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		await _wait(0.25)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _key_tap(code: Key) -> void:
	_key(code, true)
	_key(code, false)


var _held: Array[Key] = []


## Football: W A S D toward a direction of the field (its y goes up, the screen's down).
func _steer(direction: Vector2) -> void:
	var wanted: Array[Key] = []
	if direction.length() > 0.0:
		var d := direction.normalized()
		if d.y > 0.38:
			wanted.append(KEY_W)
		elif d.y < -0.38:
			wanted.append(KEY_S)
		if d.x > 0.38:
			wanted.append(KEY_D)
		elif d.x < -0.38:
			wanted.append(KEY_A)
	for code in _held.duplicate():
		if not code in wanted:
			_key(code, false)
			_held.erase(code)
	for code in wanted:
		if not code in _held:
			_key(code, true)
			_held.append(code)


func _release_keys() -> void:
	_steer(Vector2.ZERO)


# --- Finding things -----------------------------------------------------------------------------

## A visible button of the current scene whose text is this key.
func _button(key: String) -> Button:
	return _find(func(n: Node) -> bool: return n is Button and n.text == key and n.is_visible_in_tree()) as Button


func _food_tile(grid: Node, id: String) -> Control:
	for tile in grid.get_children():
		if str(tile.get("food_id")) == id:
			return tile
	_problem("no food tile %s" % id)
	return null


func _find(test: Callable, from: Node = null) -> Node:
	var node := from if from else get_tree().current_scene
	if node == null:
		return null
	if test.call(node):
		return node
	for child in node.get_children():
		var found := _find(test, child)
		if found:
			return found
	return null


## A control's rectangle on the screen (the viewport's coordinates).
func _rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	return Rect2(transform.origin, control.size * transform.get_scale())


# --- Time ---------------------------------------------------------------------------------------

## Waits by counting frames (Movie Maker gives every frame the same time; a scene-tree timer
## did not always end under Movie Maker).
func _wait(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds - 0.0001:
		await get_tree().process_frame
		waited += get_process_delta_time()


func _wait_until(cond: Callable, timeout: float) -> bool:
	var waited := 0.0
	while not cond.call():
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > timeout:
			return false
	return true


# --- Screenshots, captions and taps -------------------------------------------------------------

func _shot(shot_name: String) -> void:
	# Headless (a dry run) draws nothing, so there is no picture.
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := shots_dir.path_join("%s_%s.png" % [shot_name, lang])
	if image.save_png(path) != OK:
		_problem("could not save %s" % path)
	else:
		print("DEMO: screenshot %s" % path)


func _say(key: String) -> void:
	if key.is_empty() or not captions:
		_caption_box.visible = false
		return
	if verbose:
		print("DEMO: caption %s (frame %d)" % [key, Engine.get_process_frames()])
	var texts: Dictionary = CAPTIONS.get(key, {})
	_caption.text = str(texts.get(lang, texts.get("en", key)))
	_caption_box.visible = true
	_caption_box.reset_size()
	_caption_box.position = Vector2((720.0 - _caption_box.size.x) * 0.5, CAPTION_PLACES[_caption_place])


func _problem(text: String) -> void:
	_error_count += 1
	push_warning("DEMO ERROR: " + text)
	print("DEMO ERROR: " + text)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 120
	add_child(_overlay)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load(THEME)
	_overlay.add_child(root)
	_caption_box = PanelContainer.new()
	_caption_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.25, 0.88)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.border_color = Color(1, 1, 1, 0.35)
	style.set_border_width_all(2)
	_caption_box.add_theme_stylebox_override("panel", style)
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.custom_minimum_size = Vector2(620, 0)
	_caption.add_theme_font_size_override("font_size", CAPTION_FONT)
	_caption.add_theme_color_override("font_color", Color.WHITE)
	_caption_box.add_child(_caption)
	root.add_child(_caption_box)
	_caption_box.visible = false
	_taps = TapRings.new()
	_taps.set_anchors_preset(Control.PRESET_FULL_RECT)
	_taps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_taps)


func _show_tap(at: Vector2) -> void:
	if _taps:
		_taps.add(at)


## White rings that grow and fade where the demo taps.
class TapRings extends Control:
	const SECONDS := 0.45
	var rings: Array = []

	func add(at: Vector2) -> void:
		rings.append([at, 0.0])

	func _process(delta: float) -> void:
		for ring in rings:
			ring[1] += delta
		rings = rings.filter(func(ring: Array) -> bool: return ring[1] < SECONDS)
		queue_redraw()

	func _draw() -> void:
		for ring in rings:
			var share: float = ring[1] / SECONDS
			var radius := 16.0 + 34.0 * share
			draw_circle(ring[0], 13.0, Color(1, 1, 1, 0.55 * (1.0 - share)), true, -1.0, true)
			draw_arc(ring[0], radius, 0.0, TAU, 40, Color(0.06, 0.09, 0.25, 0.8 * (1.0 - share)), 7.0, true)
			draw_arc(ring[0], radius, 0.0, TAU, 40, Color(1, 1, 1, 1.0 - share), 4.0, true)
