extends Control
## Main game screen. Shows GameState, Clock and Activities on screen and handles the buttons.
## Eat opens the meals (Milestone 10, Task 3) and, when the avatar is hungry, Skip meal.

const CREATION_SCENE := "res://scenes/ui/creation.tscn"
const MENU_SCENE := "res://scenes/ui/menu.tscn"
## Height of the minigame panel, and of the football controls on a touch screen and on a computer.
const MINIGAME_PANEL_HEIGHT := 256.0
const FOOTBALL_PAD_TOUCH := 170.0
const FOOTBALL_PAD_KEYS := 104.0
## Milestone 40 (documentation/ui_v2/changes.md, change 2): the activity dock of squats, push-ups,
## sit-ups and meals. The panel is 362 high, so the stage ends at y 790 and the feet are at y 730;
## each row's top, from the panel's top (y 886): the info line, the Muscle bar, the timing bar
## (or the Tummy bar) and the two big buttons (faces 176 high and a thickness of 8).
const DOCK_HEIGHT := 362.0
const DOCK_STRENGTH_TOPS := [0.0, 36.0, 74.0, 146.0]
const DOCK_MEAL_TOPS := [0.0, -1.0, 58.0, 146.0]
const DOCK_BAR_HEIGHT := 24.0
const DOCK_TIMING_HEIGHT := 48.0
const DOCK_LABEL_WIDTH := 88.0
const DOCK_STATUS_WIDTH := 420.0
const DOCK_FONT_SIZE := 22
const DOCK_FONT_MIN := 16
## The cardio Beat bar's height until change 4.
const BEAT_BAR_HEIGHT := 36.0
## The icon of the exercise on DOWN and UP, by option.
const EXERCISE_ICONS := {"strength": "squat", "push_ups": "pushup", "sit_ups": "situp"}
## Change 3: the pictures of squats, push-ups and sit-ups (documentation/ui_v2/changes.md): for each
## option, the picture after DOWN, after UP and before the first press or while resting, and its
## rect in the column (the feet on y 730, 60 above the stage's bottom at y 790).
const EXERCISE_PICTURES := {
	"strength": ["squat_down", "squat_up", "squat_up", Rect2(195, 295, 330, 450)],
	"push_ups": ["pushup_down", "pushup_up", "pushup_up", Rect2(110, 394, 500, 340)],
	"sit_ups": ["situp_down", "situp_up", "situp_down", Rect2(130, 374, 460, 360)],
}
const EXERCISE_STAGE_BOTTOM := 790.0
const ART_FOLDER := "res://assets/art/avatar/%s/%s.png"
## During an activity the balloon's top is at y 208 of the column (changes.md, rule 8).
const SPEECH_TOP_IN_ACTIVITY := 208.0
## The food on the fork in the meal minigame.
const MEAL_HEALTHY_COLOR := Color(0.4, 0.75, 0.35)
const MEAL_FAST_FOOD_COLOR := Color(0.85, 0.55, 0.25)
const Hunger := preload("res://scripts/health/hunger.gd")
const AvatarStates := preload("res://scripts/health/avatar_states.gd")
const HealthModel := preload("res://scripts/health/health_model.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")
const Training := preload("res://scripts/health/training.gd")
const Requests := preload("res://scripts/health/requests.gd")
const Canteen := preload("res://scripts/health/canteen.gd")
const CanteenScreen := preload("res://scripts/ui/canteen.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")
## Placeholder failure messages by cause (HealthModel.failure_cause(); the failure effect is not
## decided yet): severe thinness for too long, or target health or happiness below its line for
## too long (fail group in config). Translation keys, like every text on this screen.
const FAILURE_TEXTS := {
	"thinness": "FAILURE_THINNESS",
	"hunger": "FAILURE_HUNGER",
	"health": "FAILURE_HEALTH",
	"happiness": "FAILURE_HAPPINESS",
}
## The health part of the HUD: "Health N" (rounded down, decision 83) and its tooltip, which says
## "Health: danger" while the danger warning flashes (decision 82; Milestone 10.5 placeholder).
const HEALTH_VALUE_TEXT := "UI_HEALTH_VALUE"
const DANGER_TIP := "MEASURE_HEALTH_DANGER"
const HEALTH_TIP := "UI_HEALTH_BAR_TIP"
## The clock is 12-hour, with AM and PM (decision 80).
const AM_TEXT := "UI_AM"
const PM_TEXT := "UI_PM"
## The play button of the clock capsule: pause the day, go on, or start the day after a sleep
## (it replaces the Wake button, decision 81).
const PAUSE_TIP := "UI_PAUSE_TIP"
const PLAY_TIP := "UI_PLAY_TIP"
const WAKE_TIP := "UI_WAKE_TIP"
## The XP bar fills smoothly (real seconds).
const XP_FILL_SECONDS := 0.5
## The balloon's text: a smaller size when it would need more than SPEECH_MAX_LINES lines, and the
## balloon never covers the clock capsule (it moves down over the avatar's head instead).
const SPEECH_FONT_SIZE := 25
const SPEECH_SMALL_FONT_SIZE := 21
const SPEECH_MAX_LINES := 2
const SPEECH_GAP_UNDER_CAPSULE := 8.0
## An activity without a "scenery" (data/activities.json) shows its background colour behind
## the avatar, see-through, so day or night stays visible.
@export var activity_backdrop_alpha := 0.6
@export var backdrop_fade_seconds := 0.8
## How long the "Level up!" message stays in the speech bubble (real seconds).
@export var level_up_message_seconds := 3.0
## XP changes shown over the XP bar (user, 7 Nov 2026): they are added up and shown at most once
## per xp_change_seconds (real seconds), as a whole number, rising and fading.
@export var xp_change_seconds := 1.5
@export var xp_change_rise := 24.0
@export var xp_gain_color := Color(0.55, 1.0, 0.55)
@export var xp_loss_color := Color(1.0, 0.5, 0.45)

## The sky (whole screen), the curved ground, and the dim outside the column (Milestone 25).
@onready var background: Control = $Background
@onready var ground: Control = %Ground
@onready var outside_dim: Control = %OutsideDim
@onready var activity_backdrop: ColorRect = %ActivityBackdrop
@onready var scenery: Control = %Scenery
@onready var sky_bodies: Control = %SkyBodies
## The bedroom's blanket, in front of the avatar.
@onready var blanket: Control = %Blanket
@onready var avatar: Control = %Avatar
@onready var health_button: Button = %HealthButton
@onready var health_pills: Control = %HealthPills
@onready var heart: Control = %Heart
@onready var health_label: Label = %HealthLabel
@onready var health_panel: PanelContainer = %HealthPanel
@onready var physical_button: Button = %PhysicalButton
@onready var physical_bar: ProgressBar = %PhysicalBar
@onready var values_panel: PanelContainer = %ValuesPanel
@onready var calories_label: Label = %CaloriesLabel
@onready var muscle_label: Label = %MuscleLabel
@onready var fitness_label: Label = %FitnessLabel
@onready var weight_label: Label = %WeightLabel
@onready var height_label: Label = %HeightLabel
@onready var bmi_label: Label = %BmiLabel
@onready var diet_label: Label = %DietLabel
@onready var happiness_bar: ProgressBar = %HappinessBar
@onready var sleep_bar: ProgressBar = %SleepBar
## Sleep v2 (Milestone 27): the label shows the debt, and a thin bar today's sleep need.
@onready var sleep_label: Label = %SleepLabel
@onready var sleep_need_bar: ProgressBar = %SleepNeedBar
@onready var level_display: Control = %LevelDisplay
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var xp_change_label: Label = %XPChange
@onready var clock_label: Label = %ClockLabel
@onready var pause_button: Button = %PauseButton
@onready var pause_icon: Control = %PauseIcon
@onready var football_field: Control = %FootballField
@onready var football_pad: Control = %FootballPad
@onready var football_help: Control = %FootballHelp
@onready var meal_fork: Control = %MealFork
@onready var meal_buttons: Control = %MealButtons
@onready var bite_button: Button = %BiteButton
@onready var done_button: Button = %DoneButton
@onready var help_button: Button = %HelpButton
@onready var speech_label: Label = %SpeechLabel
@onready var speech_bubble: PanelContainer = %SpeechBubble
@onready var speech_divider: Control = %SpeechDivider
@onready var clock_capsule: Control = $ClockCapsule
@onready var _speech_bottom: float = speech_bubble.offset_bottom
@onready var request_icon: Control = %RequestIcon
@onready var stop_button: Button = %StopButton
@onready var action_buttons: Array[Button] = [%ExerciseButton, %SleepButton, %EatButton, %EntertainmentButton]
@onready var sleep_button: Button = %SleepButton
@onready var exercise_button: Button = %ExerciseButton
@onready var entertainment_button: Button = %EntertainmentButton
@onready var eat_button: Button = %EatButton
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var options_title: Label = %OptionsTitle
@onready var option_buttons: VBoxContainer = %OptionButtons
@onready var minutes_box: Control = %MinutesBox
@onready var minutes_label: Label = %MinutesLabel
@onready var minutes_slider: HSlider = %MinutesSlider
@onready var sleep_panel: PanelContainer = %SleepPanel
@onready var sleep_slider: HSlider = %SleepSlider
@onready var sleep_info_label: Label = %SleepInfoLabel
@onready var settings_overlay: Control = %SettingsOverlay
@onready var portuguese_button: Button = %PortugueseButton
@onready var english_button: Button = %EnglishButton
@onready var new_avatar_button: Button = %NewAvatarButton
@onready var action_grid: Control = %ActionGrid
@onready var minigame_panel: Control = %MinigamePanel
@onready var minigame_status: Label = %MinigameStatus
@onready var minigame_steps: Label = %MinigameSteps
@onready var reserve_label: Label = %ReserveLabel
@onready var reserve_bar: ProgressBar = %ReserveBar
@onready var tap_button: Button = %TapButton
@onready var jump_button: Button = %JumpButton
@onready var sky_game: Control = %SkyGame
@onready var strength_buttons: Control = %StrengthButtons
@onready var down_button: Button = %DownButton
@onready var up_button: Button = %UpButton
@onready var beat_bar: Control = %BeatBar
@onready var dock_gaps: Array[Control] = [%Gap1, %Gap2, %Gap3]
@onready var exercise_picture: TextureRect = %ExercisePicture
@onready var confirm_box: Control = %ConfirmBox
@onready var failure_screen: ColorRect = %FailureOverlay

## The canteen (Milestone 21): Eat opens it.
var canteen: ColorRect
var _backdrop_tween: Tween
## XP gained or lost and not shown yet, and the change being shown.
var _xp_pending := 0.0
var _xp_tween: Tween
var _xp_fill_tween: Tween
var _scenery_tween: Tween
## The level shown, to know whether the XP bar fills smoothly or starts again.
var _shown_level := -1
## What the balloon is about now (see _set_speech()).
var _speech_topic := ""
## A short message (such as "Level up!") shown instead of the normal speech for a moment:
## its translation key and the values for its format.
var _flash_key := ""
var _flash_args := []
## The activity whose options are in the options panel.
var _options_activity := ""
## Whether opening the settings paused the day, so closing them starts it again.
var _paused_by_settings := false
## What the activity dock was last laid out for (Milestone 40).
var _dock_state := ""
## The exercise pictures of the running option, loaded when it starts (never while drawing), and
## which one is shown.
var _exercise_textures := {}
var _exercise_key := ""


## The joystick's direction, on screen.
var _pad_stick := Vector2.ZERO


func _ready() -> void:
	# A new game (no save) starts on the avatar creation screen.
	if not GameState.is_created():
		get_tree().change_scene_to_file.call_deferred(CREATION_SCENE)
		return
	sleep_slider.min_value = Config.get_float("sleep_activity.slider_min_hours")
	sleep_slider.max_value = Config.get_float("time.max_sleep_hours")
	sleep_slider.step = Config.get_float("sleep_activity.slider_step_hours")
	sleep_slider.value = Config.get_float("sleep_activity.slider_default_hours")
	minutes_slider.min_value = Config.get_float("activity_slider.min_minutes")
	minutes_slider.max_value = Config.get_float("activity_slider.max_minutes")
	minutes_slider.step = Config.get_float("activity_slider.step_minutes")
	health_panel.visible = false
	values_panel.visible = false
	sleep_panel.visible = false
	options_panel.visible = false
	settings_overlay.visible = false
	var languages := ButtonGroup.new()
	portuguese_button.button_group = languages
	english_button.button_group = languages

	health_button.pressed.connect(_toggle_health_panel)
	physical_button.pressed.connect(_toggle_values_panel)
	pause_button.pressed.connect(_on_pause_pressed)
	%SettingsButton.pressed.connect(_open_settings)
	%SettingsCloseButton.pressed.connect(_close_settings)
	portuguese_button.pressed.connect(Settings.set_language.bind("pt"))
	english_button.pressed.connect(Settings.set_language.bind("en"))
	new_avatar_button.pressed.connect(_show_new_avatar_confirmation.bind(true))
	%ConfirmCancelButton.pressed.connect(_show_new_avatar_confirmation.bind(false))
	%ConfirmNewAvatarButton.pressed.connect(_start_new_avatar)
	sleep_button.pressed.connect(_on_sleep_button_pressed)
	exercise_button.pressed.connect(_open_options.bind("exercise"))
	entertainment_button.pressed.connect(_open_options.bind("entertainment"))
	# Eat opens the canteen (Milestone 21), over the screen and under the failure screen.
	canteen = CanteenScreen.new()
	add_child(canteen)
	move_child(canteen, failure_screen.get_index())
	eat_button.pressed.connect(canteen.open)
	%OptionsCancelButton.pressed.connect(options_panel.hide)
	stop_button.pressed.connect(Activities.stop)
	sleep_slider.value_changed.connect(_refresh_sleep_info.unbind(1))
	minutes_slider.value_changed.connect(_refresh_minutes.unbind(1))
	%SleepCancelButton.pressed.connect(sleep_panel.hide)
	%SleepStartButton.pressed.connect(_on_sleep_start_pressed)
	GameState.changed.connect(_refresh)
	GameState.leveled_up.connect(_on_leveled_up)
	Clock.slept_while_away.connect(_on_slept_while_away)
	GameState.xp_changed.connect(_on_xp_changed)
	# Failure is final (user, 7 Nov 2026). Shown after the step that reached it has finished.
	GameState.failed.connect(func(_cause: String) -> void: _show_failure.call_deferred())
	# After failure, a new avatar in a free place; the failed one stays in the menu's list.
	failure_screen.restart_pressed.connect(func() -> void:
		SaveGame.menu_request = "new_avatar"
		_go_to_menu())
	%MainMenuButton.pressed.connect(_go_to_menu)
	Clock.time_changed.connect(_refresh_clock)
	Clock.phase_changed.connect(_on_phase_changed)
	Clock.paused_changed.connect(_refresh_phase.unbind(1))
	Clock.day_started.connect(_refresh_phase.unbind(1))
	Activities.started.connect(_refresh_activity.unbind(2))
	Activities.ended.connect(_refresh_activity.unbind(3))
	Activities.progressed.connect(_refresh_activity_speech)
	Activities.started.connect(_warn_if_too_soon.unbind(2))
	Activities.started.connect(func(_activity_id: String, option_id: String) -> void: _on_meal_started(option_id))
	Minigame.first_stride.connect(_on_first_stride)
	GameState.wish_refused.connect(_on_wish_refused)
	tap_button.button_down.connect(Minigame.tap)
	down_button.button_down.connect(Minigame.press.bind(true))
	up_button.button_down.connect(Minigame.press.bind(false))
	Minigame.strode.connect(_on_stride.unbind(1))
	Minigame.session_changed.connect(_on_session_changed)
	Minigame.gave_up.connect(_flash.bind("SPEECH_GAVE_UP"))
	Minigame.match_ended.connect(_on_match_ended)
	football_pad.stick_moved.connect(_on_pad_stick)
	football_pad.pass_pressed.connect(Minigame.pass_ball)
	football_pad.shoot_pressed.connect(Minigame.shoot_or_tackle)
	football_pad.touch_seen.connect(_refresh_minigame)
	Minigame.football_event.connect(_on_football_event)
	help_button.pressed.connect(_open_football_help)
	bite_button.button_down.connect(Minigame.tap)
	done_button.pressed.connect(Minigame.done)
	jump_button.button_down.connect(Minigame.jump.bind(true))
	jump_button.button_up.connect(Minigame.jump.bind(false))
	Minigame.sky_run_ended.connect(sky_game.on_run_ended)
	Minigame.meal_event.connect(func(key: String) -> void: meal_fork.show_event(tr(key)))
	football_help.closed.connect(_close_football_help)
	Activities.started.connect(_open_football_help_first_time.unbind(2))
	# A game loaded in the middle of cardio goes on as a session.
	Minigame.attach()
	_open_football_help_first_time()

	# The game may have been loaded mid-activity, so show it at once (no animation either).
	health_pills.animate = false
	level_display.animate = false
	_refresh_activity(true)
	_refresh()
	health_pills.animate = true
	level_display.animate = true
	_refresh_clock()
	_refresh_sleep_info()
	# A saved failure: the failure screen again (it cannot be escaped by reloading).
	if not GameState.failed_cause.is_empty():
		_show_failure()


## The failure screen over everything. Time stops for good; an activity ends, except a sleep,
## which only stops with the clock (ending it would start a new avatar day after the failure).
func _show_failure() -> void:
	Clock.halted = true
	if Activities.is_running() and Activities.current_activity != "sleep":
		Activities.stop()
	for panel in [options_panel, sleep_panel, settings_overlay, health_panel, values_panel, canteen]:
		panel.hide()
	if football_help.visible:
		football_help.hide()
	failure_screen.open()


func _exit_tree() -> void:
	Minigame.detach()


func _process(_delta: float) -> void:
	if Minigame.running:
		_send_stick()
		_refresh_minigame()
	# The sky's horizon colour ends at the top of the curved ground (both cover the whole screen).
	background.horizon_y = ground.horizon()
	_refresh_outside_dim()
	_place_speech()


## The balloon stands over the avatar; a tall one moves down rather than cover the clock capsule
## and its play button.
func _place_speech() -> void:
	var height := speech_bubble.size.y
	var stage_bottom: float = speech_bubble.get_parent().get_global_rect().end.y
	var limit := clock_capsule.get_global_rect().end.y + SPEECH_GAP_UNDER_CAPSULE
	var bottom := _speech_bottom + maxf(0.0, limit - (stage_bottom + _speech_bottom - height))
	# During an activity its top is fixed at y 208, under the clock (Milestone 40, rule 8).
	if Activities.is_running():
		bottom = get_global_rect().position.y + SPEECH_TOP_IN_ACTIVITY + height - stage_bottom
	if not is_equal_approx(bottom, speech_bubble.offset_bottom):
		speech_bubble.offset_bottom = bottom
		speech_bubble.offset_top = bottom - height


## On a screen wider than the column, an open panel darkens the rest of the screen too.
func _refresh_outside_dim() -> void:
	var amount := 0.0
	for cover: ColorRect in [settings_overlay, football_help, failure_screen, canteen]:
		if cover and cover.visible:
			amount = maxf(amount, cover.color.a)
	outside_dim.amount = amount
	outside_dim.color = Ui.DIM_COLOR


## The button next to the clock: after a sleep it starts the day (it replaces the Wake button,
## decision 81); otherwise it pauses the day or lets it go on.
func _on_pause_pressed() -> void:
	if Clock.phase == Clock.Phase.SLEEP_OVER:
		Clock.wake_up()
	else:
		Clock.toggle_pause()


## The joystick, or the arrow keys or WASD on a computer. The screen's y goes down, the field's
## goes up. WASD reads the key's place on the keyboard, so it also works on other layouts.
func _send_stick() -> void:
	if Minigame.kind != Minigame.FOOTBALL:
		return
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	keys.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	keys.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	keys = keys.normalized()
	var direction := _pad_stick if _pad_stick != Vector2.ZERO else keys
	var wanted := Vector2(direction.x, -direction.y)
	if wanted != Minigame.game.stick:
		Minigame.set_stick(wanted)


func _on_pad_stick(direction: Vector2) -> void:
	_pad_stick = direction


func _on_match_ended(goals_us: int, goals_them: int) -> void:
	_flash("SPEECH_MATCH_RESULT", [goals_us, goals_them])


func _on_football_event(key: String) -> void:
	football_field.show_event(tr(key))


## The first time someone plays football on this device.
func _open_football_help_first_time() -> void:
	if Minigame.kind == Minigame.FOOTBALL and not Settings.football_help_seen:
		_open_football_help()


## The day pauses while the explanation is open, as with the settings.
func _open_football_help() -> void:
	if football_help.visible:
		return
	football_help.open(football_pad.touch_mode)
	if Clock.phase == Clock.Phase.DAY and not Clock.paused:
		_paused_by_settings = true
		Clock.set_paused(true)


func _close_football_help() -> void:
	Settings.mark_football_help_seen()
	if _paused_by_settings:
		_paused_by_settings = false
		Clock.set_paused(false)


## On a computer Space plays cardio, the arrow keys Down and Up play strength, and in football
## arrow keys or WASD move, Z or J passes, X, K or Space shoots or tackles, P pauses and H helps.
## In a meal Space bites and D is Done. In the video game Space, the arrow up or W jump while
## held, and P pauses.
func _unhandled_key_input(event: InputEvent) -> void:
	if not Minigame.running:
		return
	if Minigame.kind == Minigame.SKY:
		if event is InputEventKey and not event.echo:
			if event.physical_keycode in [KEY_SPACE, KEY_UP, KEY_W, KEY_ENTER]:
				Minigame.jump(event.pressed)
			elif event.physical_keycode == KEY_P and event.pressed:
				Clock.toggle_pause()
		return
	if Minigame.kind == Minigame.FOOTBALL and event is InputEventKey and event.pressed and not event.echo:
		_on_football_key(event.physical_keycode)
	if Minigame.kind == Minigame.MEAL and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_D:
		Minigame.done()
	# The key chips of DOWN and UP say S and W too (Milestone 40).
	if Minigame.kind == Minigame.STRENGTH and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_S, KEY_W]:
		Minigame.press(event.physical_keycode == KEY_S)
		return
	if event.is_action_pressed("ui_accept"):
		Minigame.tap()
		Minigame.shoot_or_tackle()
	elif event.is_action_pressed("ui_down"):
		Minigame.press(true)
	elif event.is_action_pressed("ui_up"):
		Minigame.press(false)


func _on_football_key(key: Key) -> void:
	match key:
		KEY_Z, KEY_J:
			Minigame.pass_ball()
		KEY_X, KEY_K:
			Minigame.shoot_or_tackle()
		KEY_P:
			Clock.toggle_pause()
		KEY_H:
			_open_football_help()


## Clicking the health level or the health bar shows or hides the three measures.
func _toggle_health_panel() -> void:
	health_panel.visible = not health_panel.visible
	if not health_panel.visible:
		values_panel.visible = false


## Clicking the physical bar shows or hides its values as numbers: calories spent, strength,
## fitness, weight, height, BMI-for-age z and diet quality.
func _toggle_values_panel() -> void:
	values_panel.visible = not values_panel.visible


## The language changed: every text written here is written again. Text that holds a key in the
## scenes follows by itself. _ready() may not have run yet when the language is first set.
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	_refresh()
	_refresh_sleep_info()
	_refresh_minutes()
	if options_panel.visible:
		_build_options(_options_activity)
	if not _flash_key.is_empty():
		_show_flash()


## The settings open at any moment, even during an activity. They cover the screen, so nothing
## else can be pressed. The day pauses while they are open; sleep cannot pause and keeps running.
func _open_settings() -> void:
	portuguese_button.set_pressed_no_signal(Settings.language == "pt")
	english_button.set_pressed_no_signal(Settings.language == "en")
	settings_overlay.show()
	if Clock.phase == Clock.Phase.DAY and not Clock.paused:
		_paused_by_settings = true
		Clock.set_paused(true)


## Back to how the game was before the settings opened.
func _close_settings() -> void:
	settings_overlay.hide()
	_show_new_avatar_confirmation(false)
	if _paused_by_settings:
		_paused_by_settings = false
		Clock.set_paused(false)


## "Start a new avatar" only shows the warning; nothing happens without the second press.
func _show_new_avatar_confirmation(show_it: bool) -> void:
	confirm_box.visible = show_it
	new_avatar_button.visible = not show_it


## Back to the main menu (Milestone 18): the avatar is saved, then the menu empties the game.
func _go_to_menu() -> void:
	if Activities.is_running() and Activities.current_activity != "sleep":
		Activities.stop()
	SaveGame.save_game()
	get_tree().change_scene_to_file(MENU_SCENE)


## The avatar is deleted for good and the creation screen opens. The language stays: it is in
## Settings, not in the avatar's save.
func _start_new_avatar() -> void:
	Activities.stop()
	SaveGame.delete_save()
	get_tree().change_scene_to_file(CREATION_SCENE)


## XP changes come in small amounts (every 5 avatar minutes at high health) or at once (the
## health bar's step after a sleep). They are added up; a loading save shows nothing.
func _on_xp_changed(amount: float) -> void:
	if Simulation.loading:
		return
	_xp_pending += amount
	if _xp_tween == null or not _xp_tween.is_running():
		_show_xp_change()


## Shows the whole XP added up since the last one, keeping the rest for later; a change smaller
## than 1 XP waits.
func _show_xp_change() -> void:
	var shown := roundi(_xp_pending)
	if shown == 0:
		return
	_xp_pending -= shown
	xp_change_label.text = tr("UI_XP_GAIN" if shown > 0 else "UI_XP_LOSS") % absi(shown)
	xp_change_label.add_theme_color_override("font_color", xp_gain_color if shown > 0 else xp_loss_color)
	xp_change_label.position.y = xp_bar.size.y + xp_change_rise
	xp_change_label.modulate.a = 1.0
	_xp_tween = create_tween().set_parallel()
	_xp_tween.tween_property(xp_change_label, "position:y", xp_bar.size.y, xp_change_seconds)
	_xp_tween.tween_property(xp_change_label, "modulate:a", 0.0, xp_change_seconds).set_ease(Tween.EASE_IN)
	_xp_tween.chain().tween_callback(_show_xp_change)


func _on_leveled_up(new_level: int) -> void:
	_flash("SPEECH_LEVEL_UP", [new_level])


## Milestone 23: the sleep moved on while the game was closed.
func _on_slept_while_away(hours: float) -> void:
	var minutes := roundi(hours * 60.0)
	_flash("SPEECH_SLEPT_AWAY", [GameState.avatar_name, minutes / 60, minutes % 60])


## Shows a short message in the speech bubble for level_up_message_seconds.
func _flash(key: String, args := []) -> void:
	_flash_key = key
	_flash_args = args
	_show_flash()
	get_tree().create_timer(level_up_message_seconds).timeout.connect(_end_flash)


func _show_flash() -> void:
	_write_speech(tr(_flash_key) % _flash_args, "", _flash_key)


func _end_flash() -> void:
	_flash_key = ""
	_refresh_phase()


## Writes to the speech bubble, unless a short message is being shown. request: the picture of
## a request (Requests), or "" for none. topic: what the message is about; the balloon comes in
## softly only when it changes (an activity's progress changes its numbers, not its topic).
func _set_speech(text: String, request := "", topic := "") -> void:
	if _flash_key.is_empty():
		_write_speech(text, request, topic if not topic.is_empty() else text)


## The balloon's text and picture. With a picture the text sits on the left of a divider (as in
## the mockups); without one it is centred.
func _write_speech(text: String, request: String, topic: String) -> void:
	speech_label.text = text
	request_icon.kind = request
	speech_divider.visible = not request.is_empty()
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if request.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	speech_label.add_theme_font_size_override("font_size", _speech_font_size(text, not request.is_empty()))
	if topic != _speech_topic:
		# Not for the first message of the screen.
		if not _speech_topic.is_empty() and speech_bubble.visible:
			speech_bubble.pop()
		_speech_topic = topic


## The balloon's font size: smaller when the text would need more than SPEECH_MAX_LINES lines.
func _speech_font_size(text: String, with_picture: bool) -> int:
	var font := speech_label.get_theme_font("font")
	var style := speech_bubble.get_theme_stylebox("panel")
	var width := speech_bubble.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
	if with_picture:
		width -= request_icon.custom_minimum_size.x + speech_divider.get_theme_constant("separation")
	var lines := 0.0
	for line in text.split("\n"):
		lines += ceilf(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEECH_FONT_SIZE).x / maxf(width, 1.0))
	return SPEECH_SMALL_FONT_SIZE if lines > SPEECH_MAX_LINES else SPEECH_FONT_SIZE


## The avatar's reactions (Milestone 16): each shows an effect the model already has.
## A meal: from the craving before it. The meal minigame shows it over the fork.
func _on_meal_started(option_id: String) -> void:
	if Simulation.loading:
		return
	var key := Requests.meal_reaction(option_id)
	if key.is_empty():
		return
	if Minigame.running and Minigame.kind == Minigame.MEAL:
		meal_fork.show_event(tr(key))
	else:
		_flash(key)


## Exercise really starts at the first tap or press, with its happiness cost.
func _on_first_stride() -> void:
	var key := Requests.exercise_reaction(Activities.current_option)
	if not key.is_empty():
		_flash(key)


## A wish the model counted as refused. Not over the football field or the fork.
func _on_wish_refused(wish: String) -> void:
	var covered := Minigame.running and Minigame.kind in [Minigame.FOOTBALL, Minigame.MEAL]
	if wish == Requests.SCREENS and not covered:
		_flash("SPEECH_NO_SCREENS")


## The avatar can sleep only when it is sleepy (Clock.is_sleepy()); otherwise it says so.
## The slider stops at the longest sleep allowed now.
func _on_sleep_button_pressed() -> void:
	if not Clock.is_sleepy():
		_flash("SPEECH_NOT_SLEEPY")
		return
	sleep_slider.max_value = Clock.max_sleep_hours()
	_refresh_sleep_info()
	sleep_panel.show()


## Opens the list of options of an activity (cardio and muscle strength for exercise), built
## from data/activities.json. The player first chooses the minutes on the slider, then clicks
## the option; meals have no slider because their portions are fixed.
func _open_options(activity_id: String) -> void:
	var definition: Dictionary = Activities.definitions.get(activity_id, {})
	minutes_box.visible = definition.get("minutes_slider", false)
	if minutes_box.visible:
		var first_option: Dictionary = definition.get("options", {}).values()[0]
		minutes_slider.value = float(first_option.get("duration_hours")) * Clock.MINUTES_PER_HOUR
		_refresh_minutes()
	_build_options(activity_id)
	options_panel.show()


func _refresh_minutes() -> void:
	minutes_label.text = tr("UI_MINUTES") % roundi(minutes_slider.value)


func _build_options(activity_id: String) -> void:
	# Remove the old buttons at once (not only at the end of the frame), so the
	# panel never holds the options of another activity.
	for child in option_buttons.get_children():
		option_buttons.remove_child(child)
		child.queue_free()
	var options: Dictionary = Activities.definitions.get(activity_id, {}).get("options", {})
	_options_activity = activity_id
	options_title.text = str(Activities.definitions.get(activity_id, {}).get("name", activity_id))
	for option_id in options:
		var option: Dictionary = options[option_id]
		var button := Button.new()
		button.text = tr(option.get("name", option_id)) if minutes_box.visible else tr("UI_OPTION") % [
				tr(option.get("name", option_id)), Settings.decimal_text(str(option.get("duration_hours", "?")))]
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_option_chosen.bind(activity_id, option_id))
		option_buttons.add_child(button)
	# A hungry avatar can also skip the meal: hunger stays, the 2-hour gap starts again.
	if activity_id == "eat" and Hunger.is_hungry():
		var skip := Button.new()
		skip.text = "UI_SKIP_MEAL"
		skip.custom_minimum_size = Vector2(0, 72)
		skip.pressed.connect(_on_skip_meal)
		option_buttons.add_child(skip)


func _on_skip_meal() -> void:
	options_panel.hide()
	Hunger.skip()


func _on_option_chosen(activity_id: String, option_id: String) -> void:
	options_panel.hide()
	Activities.start(activity_id, option_id, minutes_slider.value / Clock.MINUTES_PER_HOUR if minutes_box.visible else -1.0)


func _on_sleep_start_pressed() -> void:
	sleep_panel.hide()
	Activities.start("sleep", "sleep", sleep_slider.value)


func _on_phase_changed(_phase: Clock.Phase) -> void:
	_refresh_activity()


## Animation and background of the running activity (or none): its scenery (outside, a street,
## a room with windows, a bedroom; scripts/ui/scenery.gd), or else its see-through background colour.
func _refresh_activity(instant := false) -> void:
	var option := Activities.current_option_data()
	var place := ""
	var alpha := 0.0
	if Activities.is_running():
		place = str(option.get("scenery", ""))
		if place.is_empty():
			activity_backdrop.color = Color.html(str(option.get("background_color", "#000000")))
			alpha = activity_backdrop_alpha
	_refresh_animation()
	_refresh_minigame()
	_backdrop_tween = _fade([activity_backdrop], _backdrop_tween, alpha, instant)
	# A new place fades in from nothing; when the activity ends the last one fades out.
	if not place.is_empty() and place != scenery.kind:
		for layer in [scenery, blanket]:
			layer.avatar = avatar
			layer.kind = place
			layer.modulate.a = 0.0
	_scenery_tween = _fade([scenery, blanket], _scenery_tween, 0.0 if place.is_empty() else 1.0, instant)
	# On the street the avatar runs away from the player: seen from behind (Milestone 19).
	avatar.back_view = place == scenery.STREET
	_refresh_phase()


func _fade(nodes: Array, tween: Tween, alpha: float, instant: bool) -> Tween:
	if tween:
		tween.kill()
	if instant:
		for node in nodes:
			node.modulate.a = alpha
		return null
	tween = create_tween().set_parallel()
	for node in nodes:
		tween.tween_property(node, "modulate:a", alpha, backdrop_fade_seconds)
	return tween


## The running activity's repeating animation. In a minigame the avatar moves only with the
## player, and stands still while it waits. At the start of a rest it finishes its last move.
func _refresh_animation() -> void:
	if Activities.is_running() and not Minigame.running:
		avatar.play_animation(str(Activities.current_option_data().get("animation", "")))
	elif not Minigame.resting:
		avatar.stop_animation()


func _on_session_changed() -> void:
	_refresh_animation()
	_refresh_minigame()


func _on_stride() -> void:
	if Minigame.kind == Minigame.STRENGTH:
		avatar.squat(not Minigame.next_down)
	elif Minigame.kind == Minigame.CARDIO:
		avatar.stride(Minigame.walking)
		scenery.stride(Minigame.walking, Minigame.interval())
	elif Minigame.kind == Minigame.MEAL and Minigame.last_on_beat:
		avatar.chew()


## The avatar says so, and the player can still train (decision 35).
func _warn_if_too_soon() -> void:
	if Minigame.kind == Minigame.STRENGTH and Training.strength_too_soon():
		_flash("SPEECH_TOO_SOON")


## The minigame takes the place of the four buttons while a session runs.
func _refresh_minigame() -> void:
	minigame_panel.visible = Minigame.running
	action_grid.visible = not Minigame.running
	var football := Minigame.running and Minigame.kind == Minigame.FOOTBALL
	# The video game (Milestone 35) takes the avatar's place, like the football field.
	var sky := Minigame.running and Minigame.kind == Minigame.SKY
	football_field.visible = football
	sky_game.visible = sky
	var exercise := _refresh_exercise_picture()
	avatar.visible = not (football or sky or exercise)
	ground.shadow_visible = not (football or sky)
	_refresh_sky_bodies()
	# The bubble would cover the match, the game or the fork: it only comes back for a short message.
	var meal := Minigame.running and Minigame.kind == Minigame.MEAL
	speech_bubble.visible = not (football or meal or sky) or not _flash_key.is_empty()
	# Before the return below: after a meal the fork and its zone must go (they stayed during
	# the sleep that followed; user, 7 Nov 2026).
	meal_fork.visible = meal
	if not meal:
		avatar.mouth_open = false
	if not Minigame.running:
		return
	var strength := Minigame.kind == Minigame.STRENGTH
	tap_button.visible = Minigame.kind == Minigame.CARDIO
	jump_button.visible = sky
	help_button.visible = football
	meal_buttons.visible = meal
	reserve_label.get_parent().visible = not (meal or sky)
	strength_buttons.visible = strength
	football_pad.visible = football
	beat_bar.visible = not (football or sky)
	# On a computer the keys need less room, so the field is larger.
	var small_pad: bool = football and not football_pad.touch_mode
	football_pad.custom_minimum_size.y = FOOTBALL_PAD_KEYS if small_pad else FOOTBALL_PAD_TOUCH
	minigame_panel.custom_minimum_size.y = DOCK_HEIGHT if (strength or meal) else (0.0 if small_pad else MINIGAME_PANEL_HEIGHT)
	_layout_dock(strength, meal)
	reserve_label.text = tr("MINIGAME_MUSCLE" if strength else "MINIGAME_BREATH")
	reserve_bar.value = Minigame.reserve
	if football:
		_refresh_football()
		return
	if meal:
		_refresh_meal()
		return
	if sky:
		_refresh_sky_game()
		return
	if strength:
		_refresh_strength()
	else:
		var status := "MINIGAME_WAITING" if Minigame.waiting else ("MINIGAME_WALKING" if Minigame.walking else "MINIGAME_RUNNING")
		# The street stops when a tap is late: after the Beat bar's green zone (Milestone 19).
		scenery.late_after = 0.0 if Minigame.waiting else Minigame.interval() * (1.0 + Config.get_float("minigame.on_beat_share"))
		minigame_status.text = tr(status)
		minigame_steps.text = tr("MINIGAME_STEPS") % [Minigame.steps(), Minigame.steps_goal()]
	_fit_status(strength)
	var stopped := Minigame.waiting or Minigame.resting
	var elapsed := 0.0 if stopped else Minigame.seconds_since_tap / Minigame.interval()
	beat_bar.show_time(elapsed, Config.get_float("minigame.on_beat_share"), Minigame.last_on_beat)


func _refresh_football() -> void:
	var game: RefCounted = Minigame.game
	var status := "MINIGAME_PLAY_WAITING" if Minigame.waiting else ("MINIGAME_JOGGING" if Minigame.walking else "MINIGAME_PLAYING")
	minigame_status.text = tr("SPEECH_PROGRESS_MINUTES") % [tr(status), roundi(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR),
			roundi(Activities.target_hours * Clock.MINUTES_PER_HOUR)]
	minigame_steps.text = tr("MINIGAME_SCORE") % [game.goals_us, game.goals_them]
	football_field.game = game
	football_field.you_text = tr("FOOTBALL_YOU")
	football_field.hint = tr(_football_hint())
	var keys: bool = not football_pad.touch_mode
	var ask: bool = game.team_mate_has_ball()
	football_pad.pass_text = _with_key("MINIGAME_ASK" if ask else "MINIGAME_PASS", "Z", keys)
	football_pad.shoot_text = _with_key("MINIGAME_TACKLE" if game.defending() else "MINIGAME_SHOOT", "X", keys)
	football_pad.pass_enabled = game.has_ball() or ask
	football_pad.shoot_enabled = game.has_ball() or ask or game.in_tackle_reach()
	football_pad.keys_text = tr("FOOTBALL_KEYS")
	football_pad.queue_redraw()


## The video game (Milestone 35): the minutes, the score and the Jump button.
func _refresh_sky_game() -> void:
	minigame_status.text = tr("SPEECH_PROGRESS_MINUTES") % [tr("MINIGAME_PLAYING"),
			roundi(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR), roundi(Activities.target_hours * Clock.MINUTES_PER_HOUR)]
	minigame_steps.text = tr("SKY_SCORE") % Minigame.run.score()
	sky_game.run = Minigame.run
	jump_button.text = _with_key("SKY_JUMP", "Space", not football_pad.touch_mode)


## The meal minigame (Milestone 15): the fork, the mouth, the Tummy bar and the buttons.
func _refresh_meal() -> void:
	var full := Minigame.bites >= roundi(Minigame.full_share() * Config.get_float("minigame.meal.bites"))
	var status := "MEAL_WAITING" if Minigame.waiting else ("MEAL_FULL" if full else "MEAL_EATING")
	minigame_status.text = tr(status)
	minigame_steps.text = tr("MEAL_TUMMY") % [Minigame.bites, Config.get_int("minigame.meal.bites")]
	_fit_status(true)
	beat_bar.show_level(Minigame.meal_share(), Minigame.full_share(), 1.0)
	var keys: bool = not football_pad.touch_mode
	bite_button.hint = "[Space]" if keys else ""
	done_button.hint = "[D]" if keys else ""
	avatar.mouth_open = Minigame.at_mouth()
	meal_fork.fork = Minigame.fork_position()
	meal_fork.at_mouth = Minigame.at_mouth()
	meal_fork.hit_share = Config.get_float("minigame.meal.hit_share")
	meal_fork.mouth = meal_fork.get_global_transform().affine_inverse() * avatar.get_global_transform() \
			* avatar.mouth_point()
	var healthy := Activities.current_option == "healthy_meal"
	meal_fork.food_color = MEAL_HEALTHY_COLOR if healthy else MEAL_FAST_FOOD_COLOR
	# A plate of the canteen (Milestone 21): its foods come on the fork in turn.
	if not Activities.plate.is_empty():
		var food := Canteen.food(str(Activities.plate[Minigame.bites % Activities.plate.size()]))
		meal_fork.food_color = Color.html(str(food.get("color", "#888888")))


## Milestone 40 (changes.md, change 2): the dock of squats, push-ups, sit-ups and meals, at the
## tables' places: the rows of the panel are put at their tops with the gaps between them; other
## minigames keep their look until their own change.
func _layout_dock(strength: bool, meal: bool) -> void:
	# Laid out again only when something it depends on changes (it is called every frame).
	var state := "%s|%s|%s|%s|%s" % [strength, meal, Activities.current_option, football_pad.touch_mode,
			TranslationServer.get_locale()]
	if state == _dock_state:
		return
	_dock_state = state
	var dock := strength or meal
	minigame_panel.add_theme_constant_override("separation", 0 if dock else 8)
	beat_bar.custom_minimum_size.y = DOCK_TIMING_HEIGHT if dock else BEAT_BAR_HEIGHT
	beat_bar.marker_style = "ring" if strength else "bar"
	var reserve_row := reserve_label.get_parent() as HBoxContainer
	reserve_row.add_theme_constant_override("separation", 8 if dock else 12)
	reserve_label.custom_minimum_size.x = DOCK_LABEL_WIDTH if dock else 0.0
	reserve_bar.custom_minimum_size.y = DOCK_BAR_HEIGHT if dock else 28.0
	if not dock:
		for gap in dock_gaps:
			gap.visible = false
		minigame_status.remove_theme_font_size_override("font_size")
		return
	var tops: Array = DOCK_STRENGTH_TOPS if strength else DOCK_MEAL_TOPS
	var rows: Array[Control] = [minigame_status.get_parent(), reserve_row, beat_bar, strength_buttons if strength else meal_buttons]
	var y := 0.0
	for i in rows.size():
		if tops[i] < 0.0:
			continue
		if i > 0:
			var gap := dock_gaps[i - 1]
			gap.visible = true
			gap.custom_minimum_size.y = maxf(0.0, tops[i] - y)
		y = tops[i] + rows[i].get_combined_minimum_size().y
	if meal:
		dock_gaps[1].visible = false
		_style_meal_buttons()
	else:
		_style_strength_buttons()


## Change 3: during squats, push-ups and sit-ups the avatar is replaced by the exercise's
## pictures (the healthy body for every body, Q8): the "down" one after DOWN, the "up" one after UP,
## and the resting one before the first press and while resting. Returns whether one is shown.
func _refresh_exercise_picture() -> bool:
	var option := Activities.current_option
	var shown := Minigame.running and Minigame.kind == Minigame.STRENGTH and EXERCISE_PICTURES.has(option)
	exercise_picture.visible = shown
	if not shown:
		return false
	var entry: Array = EXERCISE_PICTURES[option]
	var key := "%s|%s" % [avatar.sheet, option]
	if not _exercise_textures.has(key):
		_exercise_textures.clear()
		for i in 3:
			var path := ART_FOLDER % [avatar.sheet, entry[i]]
			_exercise_textures[i] = load(path) if ResourceLoader.exists(path) else null
		_exercise_textures[key] = true
		var rect: Rect2 = entry[3]
		# The stage starts at the Margin's left margin (24), also before the first layout.
		var stage_left := float($Margin.get_theme_constant("margin_left"))
		exercise_picture.anchor_top = 1.0
		exercise_picture.anchor_bottom = 1.0
		exercise_picture.offset_left = rect.position.x - stage_left
		exercise_picture.offset_right = rect.end.x - stage_left
		exercise_picture.offset_top = rect.position.y - EXERCISE_STAGE_BOTTOM
		exercise_picture.offset_bottom = rect.end.y - EXERCISE_STAGE_BOTTOM
	# next_down: the next press is DOWN, so the last one was UP (or none yet).
	var which := 2 if (Minigame.waiting or Minigame.resting) else (1 if Minigame.next_down else 0)
	var texture: Texture2D = _exercise_textures[which]
	if texture == null:
		exercise_picture.visible = false
		return false
	if exercise_picture.texture != texture:
		exercise_picture.texture = texture
	return true


## The status on one line, made smaller (down to 16) when it is longer than 420 pixels.
func _fit_status(dock: bool) -> void:
	if not dock:
		return
	var fitted := maxi(Ui.fit_font_size(Ui.FONT_BOLD, minigame_status.text, DOCK_FONT_SIZE, DOCK_STATUS_WIDTH), DOCK_FONT_MIN)
	if minigame_status.get_theme_font_size("font_size") != fitted:
		minigame_status.add_theme_font_size_override("font_size", fitted)


## DOWN and UP (changes.md, "Squats, push-ups, sit-ups"; places from each button's top-left).
func _style_strength_buttons() -> void:
	var icon: String = EXERCISE_ICONS.get(Activities.current_option, "squat")
	var keys: bool = not football_pad.touch_mode
	for button: Button in [down_button, up_button]:
		var down := button == down_button
		button.face = Ui.MINIGAME_DOWN_COLOR if down else Ui.MINIGAME_UP_COLOR
		button.base = Ui.MINIGAME_DOWN_BASE if down else Ui.MINIGAME_UP_BASE
		button.ink = Color.WHITE if down else Ui.INK
		button.icon_kind = icon
		button.icon_rect = Rect2(32, 32, 80, 80)
		button.arrow = "down" if down else "up"
		button.arrow_rect = Rect2(126, 34, 16, 36)
		button.word_size = 40
		button.word_x = 162.0
		button.word_y = 68.0
		button.chip = ("↓  S" if down else "↑  W") if keys else ""
		button.chip_rect = Rect2(113, 122, 100, 32)
		button.chip_fill = Color(0, 0, 0, 0) if down else Ui.MINIGAME_UP_BASE
		button.queue_redraw()


## Bite and Done (changes.md, "Meal"; places from each button's top-left).
func _style_meal_buttons() -> void:
	bite_button.face = Ui.MINIGAME_UP_COLOR
	bite_button.base = Ui.MINIGAME_UP_BASE
	bite_button.icon_kind = "fork"
	bite_button.icon_rect = Rect2(48, 38, 64, 100)
	bite_button.divider = Rect2(144, 40, 3, 96)
	bite_button.word_size = 52
	bite_button.word_x = 172.0
	bite_button.word_y = 74.0
	var word_width := Ui.FONT_HEAVY.get_string_size(tr(bite_button.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
	bite_button.hint_size = 24
	bite_button.hint_centre = Vector2(172.0 + word_width * 0.5, 128.0)
	done_button.face = Ui.SLEEP_COLOR
	done_button.base = Ui.SLEEP_BASE
	done_button.word_size = 34
	done_button.word_centred = true
	done_button.word_x = 105.0
	done_button.word_y = 74.0
	done_button.hint_size = 22
	done_button.hint_centre = Vector2(105.0, 124.0)
	for button: Button in [bite_button, done_button]:
		button.queue_redraw()


func _with_key(key: String, keyboard_key: String, keys: bool) -> String:
	return "%s  [%s]" % [tr(key), keyboard_key] if keys else tr(key)


## What the player should do now.
func _football_hint() -> String:
	var game: RefCounted = Minigame.game
	if Clock.paused:
		return "FOOTBALL_PAUSED"
	if Minigame.waiting:
		return "FOOTBALL_HINT_START_TOUCH" if football_pad.touch_mode else "FOOTBALL_HINT_START_KEYS"
	if game.stopped():
		return ""
	if Minigame.walking:
		return "FOOTBALL_HINT_JOG"
	if game.has_ball():
		if game.in_shot_range():
			return "FOOTBALL_HINT_SHOOT"
		return "FOOTBALL_HINT_PASS" if game.under_pressure() else "FOOTBALL_HINT_RUN"
	if game.team_mate_has_ball():
		return "FOOTBALL_HINT_MATE_SHOOT" if game.team_mate_in_shot_range() else "FOOTBALL_HINT_ASK"
	if game.defending():
		return "FOOTBALL_HINT_TACKLE" if game.in_tackle_reach() else "FOOTBALL_HINT_CHASE"
	return "FOOTBALL_HINT_BALL"


func _refresh_strength() -> void:
	if Minigame.waiting:
		# Done for real, on trust (Milestone 20, user, 17 Nov 2026): nothing records the player.
		minigame_status.text = tr("MINIGAME_DO_REAL")
	elif Minigame.resting:
		minigame_status.text = tr("MINIGAME_RESTING")
	elif Minigame.sets_started <= Minigame.sets_goal:
		minigame_status.text = tr("MINIGAME_SET") % [Minigame.sets_started, Minigame.sets_goal]
	else:
		minigame_status.text = tr("MINIGAME_SET_EXTRA") % (Minigame.sets_started - Minigame.sets_goal)
	minigame_steps.text = tr("MINIGAME_REPS") % [Minigame.reps_in_set, Minigame.set_reps]
	down_button.disabled = Minigame.resting or not Minigame.next_down
	up_button.disabled = Minigame.resting or Minigame.next_down


## The sky, the sun or moon, the ground and the places follow the clock's minute of the day and
## nothing else (Milestone 25). The buttons look the same day and night (decision 84).
func _refresh_sky() -> void:
	var minute := Clock.minute_of_day
	background.minute = minute
	ground.minute = minute
	sky_bodies.minute = minute
	scenery.minute = minute
	scenery.daylight = Clock.daylight_amount()


func _refresh() -> void:
	# "Health N" rounded down and the pills show the same health (the bar's value, 1 to 5).
	health_label.text = tr(HEALTH_VALUE_TEXT) % GameState.health_level
	health_pills.value = GameState.health
	# The danger state of severe thinness, or a failure timer running: failure may come soon.
	var danger := HealthModel.in_danger() or HealthModel.failure_near()
	health_pills.danger = danger
	heart.flashing = danger
	health_button.tooltip_text = DANGER_TIP if danger else HEALTH_TIP
	physical_bar.value = GameState.physical
	happiness_bar.value = GameState.happiness
	sleep_bar.value = GameState.sleep
	sleep_label.text = tr("MEASURE_SLEEP_DEBT") % Settings.number(SleepModel.effective_debt(), 1)
	sleep_need_bar.value = minf(1.0, GameState.sleep_need / SleepModel.day_need(GameState.age_group))
	calories_label.text = tr("MEASURE_CALORIES") % roundi(GameState.calories_spent)
	muscle_label.text = tr("MEASURE_STRENGTH") % Settings.number(GameState.strength, 2)
	fitness_label.text = tr("MEASURE_FITNESS") % Settings.number(GameState.fitness, 2)
	weight_label.text = tr("MEASURE_WEIGHT") % Settings.number(GameState.weight_kg, 1)
	height_label.text = tr("MEASURE_HEIGHT") % (GameState.height_m * Config.get_float("units.cm_per_m"))
	bmi_label.text = tr("MEASURE_BMI") % Settings.number(GameState.weight_z, 2, true)
	diet_label.text = tr("MEASURE_DIET") % Settings.number(GameState.diet_quality, 2)
	avatar.states = AvatarStates.current()
	avatar.sheet = "%s_%s" % [GameState.age_group, GameState.sex]
	level_display.level = GameState.level
	_refresh_xp_bar()
	var per_level := Config.get_float("xp.per_level")
	xp_label.text = tr("UI_XP") % [floori(GameState.level_progress * per_level), roundi(per_level)]
	_refresh_phase()


## The XP bar fills smoothly; when the level changes (up or down) it starts again from its new
## place, while the level numbers roll.
func _refresh_xp_bar() -> void:
	var target := GameState.level_progress
	if _xp_fill_tween:
		_xp_fill_tween.kill()
	if GameState.level != _shown_level or not level_display.animate or is_equal_approx(target, xp_bar.value):
		xp_bar.value = target
	else:
		_xp_fill_tween = create_tween()
		_xp_fill_tween.tween_property(xp_bar, "value", target, XP_FILL_SECONDS).set_ease(Tween.EASE_OUT)
	_shown_level = GameState.level


func _refresh_clock() -> void:
	var text := Clock.clock_text_12h(tr(AM_TEXT), tr(PM_TEXT))
	if Clock.is_debug_speed_active():
		text += " x%d" % Clock.debug_speed
	clock_label.text = text
	_refresh_sky()


func _refresh_activity_speech() -> void:
	if not Activities.is_running():
		return
	if Activities.current_activity == "sleep":
		_set_speech(tr("SPEECH_PROGRESS") % ["Zzz...", Settings.number(Activities.elapsed_hours, 1),
				Settings.number(Activities.target_hours, 1)], "", "activity:sleep")
		return
	_set_speech(tr("SPEECH_PROGRESS_MINUTES") % ["%s..." % tr(Activities.current_option_data().get("name", "")),
			roundi(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR), roundi(Activities.target_hours * Clock.MINUTES_PER_HOUR)],
			"", "activity:" + Activities.current_option)


## Milestone 24 (decision 78): no sun or moon during football (the field fills the stage) or
## while the avatar sleeps or waits for Wake (the bedroom fills it).
func _refresh_sky_bodies() -> void:
	sky_bodies.visible = not football_field.visible and not sky_game.visible and Clock.phase == Clock.Phase.DAY


func _refresh_phase() -> void:
	var phase := Clock.phase
	_refresh_sky_bodies()
	var running := Activities.is_running()
	# While the avatar sleeps the day cannot pause; when the sleep is over the button shows play
	# and starts the day (decision 81).
	pause_button.disabled = phase == Clock.Phase.SLEEPING
	var waiting := Clock.paused or phase == Clock.Phase.SLEEP_OVER
	pause_icon.kind = "play" if waiting else "pause"
	pause_button.tooltip_text = WAKE_TIP if phase == Clock.Phase.SLEEP_OVER else (PLAY_TIP if waiting else PAUSE_TIP)
	stop_button.visible = running
	for button in action_buttons:
		button.disabled = running
	# Enabled while awake even when the avatar is not sleepy, so it can say so.
	sleep_button.disabled = running or phase != Clock.Phase.DAY
	exercise_button.disabled = not Activities.can_start("exercise")
	entertainment_button.disabled = not Activities.can_start("entertainment")
	eat_button.disabled = not Activities.can_start("eat")
	if running:
		_refresh_activity_speech()
		return
	match phase:
		Clock.Phase.DAY:
			if GameState.is_at_failure():
				_set_speech(failure_text())
			elif not Requests.current().is_empty():
				# A request stays until the avatar gets what it wants (tired: until it sleeps).
				var request := Requests.current()
				_set_speech(tr(Requests.text_key(request)), request)
			elif AvatarStates.current()["sad"]:
				_set_speech(tr("SPEECH_SAD"))
			else:
				_set_speech(tr("SPEECH_PAUSED") if Clock.paused else tr("SPEECH_HELLO"))
		Clock.Phase.SLEEP_OVER:
			var text := tr("SPEECH_SLEPT") % Settings.number(Clock.sleep_elapsed_hours, 1)
			if GameState.is_at_failure():
				text = failure_text() + "\n" + text
			_set_speech(text, "", "slept")


## The placeholder failure message for the current cause ("" when there is no failure).
func failure_text() -> String:
	return tr(FAILURE_TEXTS.get(GameState.failure_cause(), ""))


## Shows what the chosen hours mean: real sleep time and the length of the next day.
func _refresh_sleep_info() -> void:
	var hours := sleep_slider.value
	var day_hours := Clock.day_hours_after_sleep(hours)
	sleep_info_label.text = tr("SLEEP_INFO") % [
		Settings.number(hours, 1),
		roundi(Clock.avatar_hours_to_real_seconds(hours, true) / 60.0),
		Settings.number(day_hours, 1),
		Settings.number(Clock.avatar_hours_to_real_seconds(day_hours, false) / 60.0, 1),
	]
	sleep_info_label.text += "\n" + tr("SLEEP_AT_MOST") % Settings.number(Clock.max_sleep_hours(), 1)
	if Clock.phase == Clock.Phase.DAY:
		sleep_info_label.text += "\n" + tr("SLEEP_ENDS_DAY")
