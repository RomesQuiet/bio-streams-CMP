extends Control
## Main game screen. Shows GameState on screen and handles the top bar buttons.
## Activity buttons are placeholders until their tasks.

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


func _ready() -> void:
	health_bar.min_value = Config.get_float("measures.health_min")
	health_bar.max_value = Config.get_float("measures.health_max")
	health_panel.visible = false
	health_button.pressed.connect(_on_health_button_pressed)
	GameState.changed.connect(_refresh)
	_refresh()


func _on_health_button_pressed() -> void:
	health_panel.visible = not health_panel.visible


func _refresh() -> void:
	health_bar.value = GameState.health
	health_label.text = "Health %.1f" % GameState.health
	physical_bar.value = GameState.physical
	mental_bar.value = GameState.mental
	sleep_bar.value = GameState.sleep
	level_label.text = "Level %d" % GameState.level
	xp_bar.value = GameState.level_progress
	# Placeholder until the Clock exists (Task 4): show the first day's start time.
	var start_hour := Config.get_float("time.first_day_start_hour")
	clock_label.text = "%02d:%02d" % [floori(start_hour), roundi(fmod(start_hour, 1.0) * 60.0)]
