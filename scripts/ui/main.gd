extends Control
## Main game screen. Shows GameState, Clock and Activities on screen and handles the buttons.
## Eat opens the meals (Milestone 10, Task 3) and, when the avatar is hungry, Skip meal.

const CREATION_SCENE := "res://scenes/ui/creation.tscn"
const Hunger := preload("res://scripts/health/hunger.gd")
const AvatarStates := preload("res://scripts/health/avatar_states.gd")
const HealthModel := preload("res://scripts/health/health_model.gd")
const Training := preload("res://scripts/health/training.gd")
## Placeholder failure messages by cause (HealthModel.failure_cause(); the failure effect is not
## decided yet): severe thinness for too long, or target health or happiness below its line for
## too long (fail group in config). Translation keys, like every text on this screen.
const FAILURE_TEXTS := {
	"thinness": "FAILURE_THINNESS",
	"health": "FAILURE_HEALTH",
	"happiness": "FAILURE_HAPPINESS",
}
## Placeholder health bar warning in the danger state of severe thinness (Milestone 10.5).
const DANGER_TEXT := "MEASURE_HEALTH_DANGER"
const HEALTH_TEXT := "MEASURE_HEALTH"

## Sky colours. The sky follows the clock (daylight hours in config), not whether
## the avatar is awake or asleep.
@export var day_sky_color := Color(0.3, 0.45, 0.62)
@export var night_sky_color := Color(0.06, 0.07, 0.14)
## The running activity's background is shown behind the avatar, see-through,
## so day or night stays visible.
@export var activity_backdrop_alpha := 0.6
@export var backdrop_fade_seconds := 0.8
## How long the "Level up!" message stays in the speech bubble (real seconds).
@export var level_up_message_seconds := 3.0
## Health bar colour in the danger state of severe thinness (placeholder warning).
@export var danger_bar_color := Color(1.0, 0.4, 0.35)

@onready var sky: ColorRect = $Background
@onready var activity_backdrop: ColorRect = %ActivityBackdrop
@onready var avatar: Control = %Avatar
@onready var health_level_button: Button = %HealthLevelButton
@onready var health_bar_button: Button = %HealthBarButton
@onready var health_bar: ProgressBar = %HealthBar
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
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var clock_label: Label = %ClockLabel
@onready var pause_button: Button = %PauseButton
@onready var wake_button: Button = %WakeButton
@onready var speech_label: Label = %SpeechLabel
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
@onready var strength_buttons: Control = %StrengthButtons
@onready var down_button: Button = %DownButton
@onready var up_button: Button = %UpButton
@onready var beat_bar: Control = %BeatBar
@onready var confirm_box: Control = %ConfirmBox

var _backdrop_tween: Tween
## A short message (such as "Level up!") shown instead of the normal speech for a moment:
## its translation key and the values for its format.
var _flash_key := ""
var _flash_args := []
## The activity whose options are in the options panel.
var _options_activity := ""
## Whether opening the settings paused the day, so closing them starts it again.
var _paused_by_settings := false


func _ready() -> void:
	# A new game (no save) starts on the avatar creation screen.
	if not GameState.is_created():
		get_tree().change_scene_to_file.call_deferred(CREATION_SCENE)
		return
	health_bar.min_value = Config.get_float("measures.health_min")
	health_bar.max_value = Config.get_float("measures.health_max")
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

	health_level_button.pressed.connect(_toggle_health_panel)
	health_bar_button.pressed.connect(_toggle_health_panel)
	physical_button.pressed.connect(_toggle_values_panel)
	pause_button.pressed.connect(Clock.toggle_pause)
	%SettingsButton.pressed.connect(_open_settings)
	%SettingsCloseButton.pressed.connect(_close_settings)
	portuguese_button.pressed.connect(Settings.set_language.bind("pt"))
	english_button.pressed.connect(Settings.set_language.bind("en"))
	new_avatar_button.pressed.connect(_show_new_avatar_confirmation.bind(true))
	%ConfirmCancelButton.pressed.connect(_show_new_avatar_confirmation.bind(false))
	%ConfirmNewAvatarButton.pressed.connect(_start_new_avatar)
	wake_button.pressed.connect(Clock.wake_up)
	sleep_button.pressed.connect(_on_sleep_button_pressed)
	exercise_button.pressed.connect(_open_options.bind("exercise"))
	entertainment_button.pressed.connect(_open_options.bind("entertainment"))
	eat_button.pressed.connect(_open_options.bind("eat"))
	%OptionsCancelButton.pressed.connect(options_panel.hide)
	stop_button.pressed.connect(Activities.stop)
	sleep_slider.value_changed.connect(_refresh_sleep_info.unbind(1))
	minutes_slider.value_changed.connect(_refresh_minutes.unbind(1))
	%SleepCancelButton.pressed.connect(sleep_panel.hide)
	%SleepStartButton.pressed.connect(_on_sleep_start_pressed)
	GameState.changed.connect(_refresh)
	GameState.leveled_up.connect(_on_leveled_up)
	Clock.time_changed.connect(_refresh_clock)
	Clock.phase_changed.connect(_on_phase_changed)
	Clock.paused_changed.connect(_refresh_phase.unbind(1))
	Clock.day_started.connect(_refresh_phase.unbind(1))
	Activities.started.connect(_refresh_activity.unbind(2))
	Activities.ended.connect(_refresh_activity.unbind(3))
	Activities.progressed.connect(_refresh_activity_speech)
	Activities.started.connect(_warn_if_too_soon.unbind(2))
	tap_button.button_down.connect(Minigame.tap)
	down_button.button_down.connect(Minigame.press.bind(true))
	up_button.button_down.connect(Minigame.press.bind(false))
	Minigame.strode.connect(_on_stride.unbind(1))
	Minigame.session_changed.connect(_on_session_changed)
	Minigame.gave_up.connect(_flash.bind("SPEECH_GAVE_UP"))
	# A game loaded in the middle of cardio goes on as a session.
	Minigame.attach()

	# The game may have been loaded mid-activity, so show it at once.
	_refresh_activity(true)
	_refresh()
	_refresh_clock()
	_refresh_sleep_info()


func _exit_tree() -> void:
	Minigame.detach()


func _process(_delta: float) -> void:
	if Minigame.running:
		_refresh_minigame()


## On a computer Space plays cardio, and the arrow keys Down and Up play strength.
func _unhandled_key_input(event: InputEvent) -> void:
	if not Minigame.running:
		return
	if event.is_action_pressed("ui_accept"):
		Minigame.tap()
	elif event.is_action_pressed("ui_down"):
		Minigame.press(true)
	elif event.is_action_pressed("ui_up"):
		Minigame.press(false)


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


## The avatar is deleted for good and the creation screen opens. The language stays: it is in
## Settings, not in the avatar's save.
func _start_new_avatar() -> void:
	Activities.stop()
	SaveGame.delete_save()
	get_tree().change_scene_to_file(CREATION_SCENE)


func _on_leveled_up(new_level: int) -> void:
	_flash("SPEECH_LEVEL_UP", [new_level])


## Shows a short message in the speech bubble for level_up_message_seconds.
func _flash(key: String, args := []) -> void:
	_flash_key = key
	_flash_args = args
	_show_flash()
	get_tree().create_timer(level_up_message_seconds).timeout.connect(_end_flash)


func _show_flash() -> void:
	speech_label.text = tr(_flash_key) % _flash_args


func _end_flash() -> void:
	_flash_key = ""
	_refresh_phase()


## Writes to the speech bubble, unless a short message is being shown.
func _set_speech(text: String) -> void:
	if _flash_key.is_empty():
		speech_label.text = text


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


## Animation and background of the running activity (or none).
func _refresh_activity(instant := false) -> void:
	var option := Activities.current_option_data()
	var alpha := 0.0
	if Activities.is_running():
		activity_backdrop.color = Color.html(str(option.get("background_color", "#000000")))
		alpha = activity_backdrop_alpha
	_refresh_animation()
	_refresh_minigame()
	if _backdrop_tween:
		_backdrop_tween.kill()
	if instant:
		activity_backdrop.modulate.a = alpha
	else:
		_backdrop_tween = create_tween()
		_backdrop_tween.tween_property(activity_backdrop, "modulate:a", alpha, backdrop_fade_seconds)
	_refresh_phase()


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
	else:
		avatar.stride(Minigame.walking)


## The avatar says so, and the player can still train (decision 35).
func _warn_if_too_soon() -> void:
	if Minigame.kind == Minigame.STRENGTH and Training.strength_too_soon():
		_flash("SPEECH_TOO_SOON")


## The minigame takes the place of the four buttons while a session runs.
func _refresh_minigame() -> void:
	minigame_panel.visible = Minigame.running
	action_grid.visible = not Minigame.running
	if not Minigame.running:
		return
	var strength := Minigame.kind == Minigame.STRENGTH
	tap_button.visible = not strength
	strength_buttons.visible = strength
	reserve_label.text = tr("MINIGAME_MUSCLE" if strength else "MINIGAME_BREATH")
	reserve_bar.value = Minigame.reserve
	if strength:
		_refresh_strength()
	else:
		var status := "MINIGAME_WAITING" if Minigame.waiting else ("MINIGAME_WALKING" if Minigame.walking else "MINIGAME_RUNNING")
		minigame_status.text = tr(status)
		minigame_steps.text = tr("MINIGAME_STEPS") % [Minigame.steps(), Minigame.steps_goal()]
	var stopped := Minigame.waiting or Minigame.resting
	var elapsed := 0.0 if stopped else Minigame.seconds_since_tap / Minigame.interval()
	beat_bar.show_time(elapsed, Config.get_float("minigame.on_beat_share"), Minigame.last_on_beat)


func _refresh_strength() -> void:
	if Minigame.waiting:
		minigame_status.text = tr("MINIGAME_WAITING")
	elif Minigame.resting:
		minigame_status.text = tr("MINIGAME_RESTING")
	elif Minigame.sets_started <= Minigame.sets_goal:
		minigame_status.text = tr("MINIGAME_SET") % [Minigame.sets_started, Minigame.sets_goal]
	else:
		minigame_status.text = tr("MINIGAME_SET_EXTRA") % (Minigame.sets_started - Minigame.sets_goal)
	minigame_steps.text = tr("MINIGAME_REPS") % [Minigame.reps_in_set, Minigame.set_reps]
	down_button.disabled = Minigame.resting or not Minigame.next_down
	up_button.disabled = Minigame.resting or Minigame.next_down


func _refresh_sky() -> void:
	sky.color = night_sky_color.lerp(day_sky_color, Clock.daylight_amount())


func _refresh() -> void:
	health_level_button.text = str(GameState.health_level)
	health_bar.value = GameState.health
	# The danger state of severe thinness: the health bar warns.
	var danger := HealthModel.in_danger()
	health_bar.self_modulate = danger_bar_color if danger else Color.WHITE
	health_label.text = DANGER_TEXT if danger else HEALTH_TEXT
	physical_bar.value = GameState.physical
	happiness_bar.value = GameState.happiness
	sleep_bar.value = GameState.sleep
	calories_label.text = tr("MEASURE_CALORIES") % roundi(GameState.calories_spent)
	muscle_label.text = tr("MEASURE_STRENGTH") % Settings.number(GameState.strength, 2)
	fitness_label.text = tr("MEASURE_FITNESS") % Settings.number(GameState.fitness, 2)
	weight_label.text = tr("MEASURE_WEIGHT") % Settings.number(GameState.weight_kg, 1)
	height_label.text = tr("MEASURE_HEIGHT") % (GameState.height_m * Config.get_float("units.cm_per_m"))
	bmi_label.text = tr("MEASURE_BMI") % Settings.number(GameState.weight_z, 2, true)
	diet_label.text = tr("MEASURE_DIET") % Settings.number(GameState.diet_quality, 2)
	avatar.states = AvatarStates.current()
	level_label.text = tr("UI_LEVEL") % GameState.level
	xp_bar.value = GameState.level_progress
	var per_level := Config.get_float("xp.per_level")
	xp_label.text = tr("UI_XP") % [floori(GameState.level_progress * per_level), roundi(per_level)]
	_refresh_phase()


func _refresh_clock() -> void:
	var text := Clock.clock_text()
	if Clock.is_debug_speed_active():
		text += "\nx%d" % Clock.debug_speed
	clock_label.text = text
	_refresh_sky()


func _refresh_activity_speech() -> void:
	if not Activities.is_running():
		return
	if Activities.current_activity == "sleep":
		_set_speech(tr("SPEECH_PROGRESS") % ["Zzz...", Settings.number(Activities.elapsed_hours, 1),
				Settings.number(Activities.target_hours, 1)])
		return
	_set_speech(tr("SPEECH_PROGRESS_MINUTES") % ["%s..." % tr(Activities.current_option_data().get("name", "")),
			roundi(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR), roundi(Activities.target_hours * Clock.MINUTES_PER_HOUR)])


func _refresh_phase() -> void:
	var phase := Clock.phase
	var running := Activities.is_running()
	pause_button.disabled = phase != Clock.Phase.DAY
	pause_button.set_pressed_no_signal(Clock.paused)
	wake_button.disabled = phase != Clock.Phase.SLEEP_OVER
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
			elif GameState.tired:
				# Stays visible until the avatar sleeps.
				_set_speech(tr("SPEECH_TIRED"))
			elif Hunger.is_hungry():
				_set_speech(tr("SPEECH_HUNGRY"))
			elif AvatarStates.current()["sad"]:
				_set_speech(tr("SPEECH_SAD"))
			else:
				_set_speech(tr("SPEECH_PAUSED") if Clock.paused else tr("SPEECH_HELLO"))
		Clock.Phase.SLEEP_OVER:
			var text := tr("SPEECH_SLEPT") % Settings.number(Clock.sleep_elapsed_hours, 1)
			if GameState.is_at_failure():
				text = failure_text() + "\n" + text
			_set_speech(text)


## The placeholder failure message for the current cause ("" when there is no failure).
func failure_text() -> String:
	return tr(FAILURE_TEXTS.get(HealthModel.failure_cause(), ""))


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
