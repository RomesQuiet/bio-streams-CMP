extends Control
## Main game screen. Shows GameState, Clock and Activities on screen and handles the buttons.
## Exercise, eat and entertainment are placeholders until their tasks.

@export var day_background_color := Color(0.17, 0.2, 0.27)
@export var background_fade_seconds := 0.8

@onready var background: ColorRect = $Background
@onready var avatar: Control = %Avatar
@onready var health_button: Button = %HealthButton
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var health_panel: PanelContainer = %HealthPanel
@onready var physical_bar: ProgressBar = %PhysicalBar
@onready var mental_bar: ProgressBar = %MentalBar
@onready var sleep_bar: ProgressBar = %SleepBar
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var clock_label: Label = %ClockLabel
@onready var pause_button: Button = %PauseButton
@onready var wake_button: Button = %WakeButton
@onready var speech_label: Label = %SpeechLabel
@onready var stop_button: Button = %StopButton
@onready var action_buttons: Array[Button] = [%ExerciseButton, %SleepButton, %EatButton, %EntertainmentButton]
@onready var sleep_button: Button = %SleepButton
@onready var sleep_panel: PanelContainer = %SleepPanel
@onready var sleep_slider: HSlider = %SleepSlider
@onready var sleep_info_label: Label = %SleepInfoLabel

var _background_tween: Tween


func _ready() -> void:
	health_bar.min_value = Config.get_float("measures.health_min")
	health_bar.max_value = Config.get_float("measures.health_max")
	sleep_slider.min_value = Config.get_float("sleep_activity.slider_min_hours")
	sleep_slider.max_value = Config.get_float("time.max_sleep_hours")
	sleep_slider.step = Config.get_float("sleep_activity.slider_step_hours")
	sleep_slider.value = Config.get_float("sleep_activity.slider_default_hours")
	health_panel.visible = false
	sleep_panel.visible = false

	health_button.pressed.connect(_on_health_button_pressed)
	pause_button.pressed.connect(Clock.toggle_pause)
	wake_button.pressed.connect(Clock.wake_up)
	sleep_button.pressed.connect(_on_sleep_button_pressed)
	stop_button.pressed.connect(Activities.stop)
	sleep_slider.value_changed.connect(_refresh_sleep_info.unbind(1))
	%SleepCancelButton.pressed.connect(sleep_panel.hide)
	%SleepStartButton.pressed.connect(_on_sleep_start_pressed)
	GameState.changed.connect(_refresh)
	Clock.time_changed.connect(_refresh_clock)
	Clock.phase_changed.connect(_on_phase_changed)
	Clock.paused_changed.connect(_refresh_phase.unbind(1))
	Activities.started.connect(_refresh_activity.unbind(2))
	Activities.ended.connect(_refresh_activity.unbind(3))
	Activities.progressed.connect(_refresh_activity_speech)

	# The game may have been loaded mid-activity, so show it at once.
	_refresh_activity(true)
	_refresh()
	_refresh_clock()
	_refresh_sleep_info()


func _on_health_button_pressed() -> void:
	health_panel.visible = not health_panel.visible


func _on_sleep_button_pressed() -> void:
	_refresh_sleep_info()
	sleep_panel.show()


func _on_sleep_start_pressed() -> void:
	sleep_panel.hide()
	Activities.start("sleep", "sleep", sleep_slider.value)


func _on_phase_changed(_phase: Clock.Phase) -> void:
	_refresh_activity()


## Animation and background of the running activity (or none).
func _refresh_activity(instant := false) -> void:
	var option := Activities.current_option_data()
	if Activities.is_running():
		avatar.play_animation(str(option.get("animation", "")))
		_fade_background(Color.html(str(option.get("background_color", day_background_color.to_html()))), instant)
	else:
		avatar.stop_animation()
		var color := day_background_color
		if Clock.phase == Clock.Phase.SLEEP_OVER:
			# Still night until the wake button: keep the sleep background.
			color = Color.html(str(Activities.get_option("sleep", "sleep").get("background_color", color.to_html())))
		_fade_background(color, instant)
	_refresh_phase()


func _fade_background(color: Color, instant := false) -> void:
	if _background_tween:
		_background_tween.kill()
	if instant:
		background.color = color
		return
	_background_tween = create_tween()
	_background_tween.tween_property(background, "color", color, background_fade_seconds)


func _refresh() -> void:
	health_bar.value = GameState.health
	health_label.text = "Health %.1f" % GameState.health
	physical_bar.value = GameState.physical
	mental_bar.value = GameState.mental
	sleep_bar.value = GameState.sleep
	level_label.text = "Level %d" % GameState.level
	xp_bar.value = GameState.level_progress


func _refresh_clock() -> void:
	var text := Clock.clock_text()
	if Clock.is_debug_speed_active():
		text += "\nx%d" % Clock.debug_speed
	clock_label.text = text


func _refresh_activity_speech() -> void:
	if not Activities.is_running():
		return
	var label := "Zzz..." if Activities.current_activity == "sleep" else "%s..." % Activities.current_option_data().get("name", "")
	speech_label.text = "%s (%.1f of %.1f h)" % [label, Activities.elapsed_hours, Activities.target_hours]


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
	if running:
		_refresh_activity_speech()
		return
	match phase:
		Clock.Phase.DAY:
			speech_label.text = "Paused" if Clock.paused else "Hello!"
		Clock.Phase.BEDTIME:
			speech_label.text = "I'm tired. It's bedtime: sleep is recommended."
		Clock.Phase.SLEEP_OVER:
			speech_label.text = "I slept %.1f h. Press the wake button to start the day." % Clock.sleep_elapsed_hours


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
