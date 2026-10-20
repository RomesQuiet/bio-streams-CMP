extends Control
## Main game screen. Shows GameState, Clock and Activities on screen and handles the buttons.
## Eat is a placeholder until its task.

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

@onready var sky: ColorRect = $Background
@onready var activity_backdrop: ColorRect = %ActivityBackdrop
@onready var avatar: Control = %Avatar
@onready var health_level_button: Button = %HealthLevelButton
@onready var health_bar_button: Button = %HealthBarButton
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_panel: PanelContainer = %HealthPanel
@onready var physical_button: Button = %PhysicalButton
@onready var physical_bar: ProgressBar = %PhysicalBar
@onready var values_panel: PanelContainer = %ValuesPanel
@onready var calories_label: Label = %CaloriesLabel
@onready var muscle_label: Label = %MuscleLabel
@onready var mental_bar: ProgressBar = %MentalBar
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
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var options_title: Label = %OptionsTitle
@onready var option_buttons: VBoxContainer = %OptionButtons
@onready var sleep_panel: PanelContainer = %SleepPanel
@onready var sleep_slider: HSlider = %SleepSlider
@onready var sleep_info_label: Label = %SleepInfoLabel

var _backdrop_tween: Tween
## A short message (such as "Level up!") shown instead of the normal speech for a moment.
var _flash_text := ""


func _ready() -> void:
	health_bar.min_value = Config.get_float("measures.health_min")
	health_bar.max_value = Config.get_float("measures.health_max")
	sleep_slider.min_value = Config.get_float("sleep_activity.slider_min_hours")
	sleep_slider.max_value = Config.get_float("time.max_sleep_hours")
	sleep_slider.step = Config.get_float("sleep_activity.slider_step_hours")
	sleep_slider.value = Config.get_float("sleep_activity.slider_default_hours")
	health_panel.visible = false
	values_panel.visible = false
	sleep_panel.visible = false
	options_panel.visible = false

	health_level_button.pressed.connect(_toggle_health_panel)
	health_bar_button.pressed.connect(_toggle_health_panel)
	physical_button.pressed.connect(_toggle_values_panel)
	pause_button.pressed.connect(Clock.toggle_pause)
	wake_button.pressed.connect(Clock.wake_up)
	sleep_button.pressed.connect(_on_sleep_button_pressed)
	exercise_button.pressed.connect(_open_options.bind("exercise"))
	entertainment_button.pressed.connect(_open_options.bind("entertainment"))
	%OptionsCancelButton.pressed.connect(options_panel.hide)
	stop_button.pressed.connect(Activities.stop)
	sleep_slider.value_changed.connect(_refresh_sleep_info.unbind(1))
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

	# The game may have been loaded mid-activity, so show it at once.
	_refresh_activity(true)
	_refresh()
	_refresh_clock()
	_refresh_sleep_info()


## Clicking the health level or the health bar shows or hides the three measures.
func _toggle_health_panel() -> void:
	health_panel.visible = not health_panel.visible
	if not health_panel.visible:
		values_panel.visible = false


## Clicking the physical bar shows or hides its values (calories and muscle).
func _toggle_values_panel() -> void:
	values_panel.visible = not values_panel.visible


func _on_leveled_up(new_level: int) -> void:
	_flash_text = "Level up! Level %d" % new_level
	speech_label.text = _flash_text
	get_tree().create_timer(level_up_message_seconds).timeout.connect(_end_flash)


func _end_flash() -> void:
	_flash_text = ""
	_refresh_phase()


## Writes to the speech bubble, unless a short message is being shown.
func _set_speech(text: String) -> void:
	if _flash_text.is_empty():
		speech_label.text = text


func _on_sleep_button_pressed() -> void:
	_refresh_sleep_info()
	sleep_panel.show()


## Opens the list of options of an activity (cardio and muscle strength for exercise),
## built from data/activities.json.
func _open_options(activity_id: String) -> void:
	# Remove the old buttons at once (not only at the end of the frame), so the
	# panel never holds the options of another activity.
	for child in option_buttons.get_children():
		option_buttons.remove_child(child)
		child.queue_free()
	var options: Dictionary = Activities.definitions.get(activity_id, {}).get("options", {})
	options_title.text = str(Activities.definitions.get(activity_id, {}).get("name", activity_id))
	for option_id in options:
		var option: Dictionary = options[option_id]
		var button := Button.new()
		button.text = "%s (%s h)" % [option.get("name", option_id), option.get("duration_hours", "?")]
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_option_chosen.bind(activity_id, option_id))
		option_buttons.add_child(button)
	options_panel.show()


func _on_option_chosen(activity_id: String, option_id: String) -> void:
	options_panel.hide()
	Activities.start(activity_id, option_id)


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
		avatar.play_animation(str(option.get("animation", "")))
		activity_backdrop.color = Color.html(str(option.get("background_color", "#000000")))
		alpha = activity_backdrop_alpha
	else:
		avatar.stop_animation()
	if _backdrop_tween:
		_backdrop_tween.kill()
	if instant:
		activity_backdrop.modulate.a = alpha
	else:
		_backdrop_tween = create_tween()
		_backdrop_tween.tween_property(activity_backdrop, "modulate:a", alpha, backdrop_fade_seconds)
	_refresh_phase()


func _refresh_sky() -> void:
	sky.color = night_sky_color.lerp(day_sky_color, Clock.daylight_amount())


func _refresh() -> void:
	health_level_button.text = str(GameState.health_level)
	health_bar.value = GameState.health
	physical_bar.value = GameState.physical
	mental_bar.value = GameState.mental
	sleep_bar.value = GameState.sleep
	calories_label.text = "Calories spent\n%d kcal" % roundi(GameState.calories_spent)
	muscle_label.text = "Muscle\n%.2f" % GameState.muscle
	level_label.text = "Lv %d" % GameState.level
	xp_bar.value = GameState.level_progress
	var per_level := Config.get_float("xp.per_level")
	xp_label.text = "XP %d / %d" % [floori(GameState.level_progress * per_level), roundi(per_level)]


func _refresh_clock() -> void:
	var text := Clock.clock_text()
	if Clock.is_debug_speed_active():
		text += "\nx%d" % Clock.debug_speed
	clock_label.text = text
	_refresh_sky()


func _refresh_activity_speech() -> void:
	if not Activities.is_running():
		return
	var label := "Zzz..." if Activities.current_activity == "sleep" else "%s..." % Activities.current_option_data().get("name", "")
	_set_speech("%s (%.1f of %.1f h)" % [label, Activities.elapsed_hours, Activities.target_hours])


func _refresh_phase() -> void:
	var phase := Clock.phase
	var running := Activities.is_running()
	pause_button.disabled = phase != Clock.Phase.DAY
	pause_button.set_pressed_no_signal(Clock.paused)
	wake_button.disabled = phase != Clock.Phase.SLEEP_OVER
	stop_button.visible = running
	for button in action_buttons:
		button.disabled = running
	sleep_button.disabled = not Activities.can_start("sleep")
	exercise_button.disabled = not Activities.can_start("exercise")
	entertainment_button.disabled = not Activities.can_start("entertainment")
	if running:
		_refresh_activity_speech()
		return
	match phase:
		Clock.Phase.DAY:
			if GameState.tired:
				# Stays visible until the avatar sleeps.
				_set_speech("I'm tired. Sleep is recommended.")
			else:
				_set_speech("Paused" if Clock.paused else "Hello!")
		Clock.Phase.SLEEP_OVER:
			_set_speech("I slept %.1f h. Press the wake button to start the day." % Clock.sleep_elapsed_hours)


## Shows what the chosen hours mean: real sleep time and the length of the next day.
func _refresh_sleep_info() -> void:
	var hours := sleep_slider.value
	var day_hours := Clock.day_hours_after_sleep(hours)
	sleep_info_label.text = "%.1f h of sleep (%d real min)\nNext day: %.1f h (%.1f real min)" % [
		hours,
		roundi(Clock.avatar_hours_to_real_seconds(hours, true) / 60.0),
		day_hours,
		Clock.avatar_hours_to_real_seconds(day_hours, false) / 60.0,
	]
	if Clock.phase == Clock.Phase.DAY:
		sleep_info_label.text += "\nSleeping now ends the current day."
