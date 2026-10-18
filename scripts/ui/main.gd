extends Control
## Main game screen. Shows GameState and Clock on screen and handles the buttons.
## Exercise, eat and entertainment are placeholders until their tasks.

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
@onready var action_buttons: Array[Button] = [%ExerciseButton, %SleepButton, %EatButton, %EntertainmentButton]
@onready var sleep_button: Button = %SleepButton


func _ready() -> void:
	health_bar.min_value = Config.get_float("measures.health_min")
	health_bar.max_value = Config.get_float("measures.health_max")
	health_panel.visible = false
	health_button.pressed.connect(_on_health_button_pressed)
	pause_button.pressed.connect(Clock.toggle_pause)
	wake_button.pressed.connect(Clock.wake_up)
	sleep_button.pressed.connect(_on_sleep_button_pressed)
	GameState.changed.connect(_refresh)
	Clock.time_changed.connect(_refresh_clock)
	Clock.phase_changed.connect(_refresh_phase.unbind(1))
	Clock.paused_changed.connect(_refresh_phase.unbind(1))
	_refresh()
	_refresh_clock()
	_refresh_phase()


func _on_health_button_pressed() -> void:
	health_panel.visible = not health_panel.visible


## Temporary until Task 5 adds the slider: sleep the baseline hours.
func _on_sleep_button_pressed() -> void:
	Clock.start_sleep(Config.get_float("time.sleep_baseline_hours"))


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


func _refresh_phase() -> void:
	var phase := Clock.phase
	pause_button.disabled = phase != Clock.Phase.DAY
	pause_button.set_pressed_no_signal(Clock.paused)
	wake_button.disabled = phase != Clock.Phase.SLEEP_OVER
	for button in action_buttons:
		button.disabled = phase == Clock.Phase.SLEEPING
	sleep_button.disabled = phase != Clock.Phase.BEDTIME
	match phase:
		Clock.Phase.DAY:
			speech_label.text = "Paused" if Clock.paused else "Hello!"
		Clock.Phase.BEDTIME:
			speech_label.text = "I'm tired. It's bedtime: sleep is recommended."
		Clock.Phase.SLEEPING:
			speech_label.text = "Zzz..."
		Clock.Phase.SLEEP_OVER:
			speech_label.text = "I'm awake! Press the wake button to start the day."
