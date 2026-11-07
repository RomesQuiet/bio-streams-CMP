extends ColorRect
## The failure screen (user, 7 Nov 2026). There is no death, only failure, and it is final: the
## player starts again with a new avatar (concept). It shows a short phrase for the cause, and
## Details, drawn rather than written (user): the cause in exact words, tiles for the avatar's
## life and body, bars for its last measures, and a gauge for each habit over the last days with
## the recommended zone in green: facts, not advice (concept, "Learning approach"). Every text is
## a translation key; the numbers come from Config and GameState.

signal restart_pressed

const Hunger := preload("res://scripts/health/hunger.gd")
const AvatarStates := preload("res://scripts/health/avatar_states.gd")
const HabitGauge := preload("res://scripts/ui/habit_gauge.gd")
const RequestIcon := preload("res://scripts/ui/request_icon.gd")
## How far each gauge reaches: sleep in hours, activity and screens as multiples of the
## recommendation (display only; the scale grows if the avatar went past it).
const SLEEP_SCALE_H := 14.0
const ACTIVITY_SCALE := 2.0
const SCREENS_SCALE := 3.0
const CAPTION_COLOR := Color(0.75, 0.77, 0.82)
const PHRASES := {
	"thinness": "FAILURE_PHRASE_THINNESS",
	"health": "FAILURE_PHRASE_HEALTH",
	"happiness": "FAILURE_PHRASE_HAPPINESS",
}

@onready var phrase_label: Label = %FailurePhrase
@onready var details_box: Control = %FailureDetailsBox
@onready var details: VBoxContainer = %FailureDetails
## The gauges of the last Details built, by habit (for tests).
var gauges := {}
@onready var details_button: Button = %FailureDetailsButton
@onready var avatar: Control = %FailureAvatar


func _ready() -> void:
	details_button.pressed.connect(_toggle_details)
	%FailureRestartButton.pressed.connect(func() -> void: restart_pressed.emit())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_write()


## Shows the screen for the saved failure, with Details closed.
func open() -> void:
	details_box.visible = false
	var states := AvatarStates.current()
	states["sad"] = true
	states["happy"] = false
	avatar.states = states
	avatar.sheet = "%s_%s" % [GameState.age_group, GameState.sex]
	_write()
	show()


func _toggle_details() -> void:
	details_box.visible = not details_box.visible
	_write()


func _write() -> void:
	var cause := GameState.failure_cause()
	phrase_label.text = tr(PHRASES.get(cause, "FAILURE_PHRASE_HEALTH")) % GameState.avatar_name
	details_button.text = tr("UI_HIDE_DETAILS" if details_box.visible else "UI_DETAILS")
	_build_details(cause)


## Details: what happened, the life and body as tiles, the last measures as bars and each habit
## as a gauge. Built again when it opens or the language changes.
func _build_details(cause: String) -> void:
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	gauges.clear()
	var gs := GameState
	_heading("FAILURE_WHAT_HAPPENED")
	_caption(cause_text(cause), 20, Color.WHITE)
	_heading(tr("FAILURE_LIFE_TITLE") % gs.avatar_name)
	_tiles([[Settings.number(gs.failed_day, 1), "FAILURE_TILE_DAYS"], [str(gs.level), "FAILURE_TILE_LEVEL"],
			[Settings.number(gs.best_health, 1), "FAILURE_TILE_BEST"]])
	_tiles([[Settings.number(gs.weight_kg, 1) + " kg", "FAILURE_TILE_WEIGHT"],
			[Settings.number(gs.weight_z, 2, true), "FAILURE_TILE_Z"], [Settings.number(gs.health, 1), "FAILURE_TILE_HEALTH"]])
	# Mini explanations (user, 7 Nov 2026): what the avatar's value means, then what the measure is.
	_caption(z_explanation(gs.weight_z), 17, CAPTION_COLOR)
	_caption(tr("FAILURE_EXPLAIN_WEIGHT") % Settings.number(gs.weight_kg, 1), 17, CAPTION_COLOR)
	_caption(tr("FAILURE_EXPLAIN_HEALTH") % Settings.number(gs.health, 1), 17, CAPTION_COLOR)
	_heading("FAILURE_END_TITLE")
	for measure in [["MEASURE_PHYSICAL", gs.physical], ["MEASURE_HAPPINESS", gs.happiness], ["MEASURE_SLEEP", gs.sleep]]:
		_measure(measure[0], measure[1])
		_caption(measure_explanation(measure[0], measure[1]), 17, CAPTION_COLOR)
	var habits := habit_numbers()
	if habits["days"] <= 0.0:
		return
	var days: float = habits["days"]
	_heading(tr("FAILURE_HABITS_TITLE") % Settings.number(days, 0 if is_equal_approx(days, roundf(days)) else 1))
	var group := gs.age_group if not gs.age_group.is_empty() else "child"
	var sleep_min := Config.get_float("sleep.%s_min_h" % group)
	var sleep_max := Config.get_float("sleep.%s_max_h" % group)
	_habit("sleep", "tired", "FAILURE_HABIT_SLEEP", tr("FAILURE_HOURS_A_DAY") % Settings.number(habits["sleep_h"], 1),
			tr("FAILURE_RECOMMENDED_RANGE") % [Settings.number(sleep_min, 0), Settings.number(sleep_max, 0)],
			habits["sleep_h"], sleep_min, sleep_max, SLEEP_SCALE_H)
	var activity_min := Config.get_float("failure_screen.activity_min_per_day")
	_habit("activity", "football", "FAILURE_HABIT_ACTIVITY", tr("FAILURE_MINUTES_A_DAY") % roundi(habits["activity_min"]),
			tr("FAILURE_RECOMMENDED_AT_LEAST") % roundi(activity_min), habits["activity_min"], activity_min, -1.0,
			activity_min * ACTIVITY_SCALE)
	var screens_max := Config.get_float("mood.fun.screen_max_min") / Clock.MINUTES_PER_HOUR
	_habit("screens", "screens", "FAILURE_HABIT_SCREENS", tr("FAILURE_HOURS_A_DAY") % Settings.number(habits["screen_h"], 1),
			tr("FAILURE_RECOMMENDED_AT_MOST") % Settings.number(screens_max, 0), habits["screen_h"], 0.0, screens_max,
			screens_max * SCREENS_SCALE)
	var meals: int = habits["meals"]
	var fast := roundi(habits["fast_food_share"] * meals)
	var gauge := _habit("meals", "hungry", "FAILURE_HABIT_MEALS", tr("FAILURE_MEALS_COUNT") % [meals - fast, fast], "",
			0.0, 0.0, -1.0, 1.0)
	gauge.split = true
	gauge.healthy = meals - fast
	gauge.fast_food = fast


func _heading(key: String) -> void:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", 24)
	details.add_child(label)


func _caption(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	details.add_child(label)
	return label


## A row of tiles in the style of the level boxes: a large number over a small name.
func _tiles(items: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for item in items:
		var tile := PanelContainer.new()
		tile.theme_type_variation = &"LevelBox"
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		for part in [[item[0], 30], [tr(item[1]), 16]]:
			var label := Label.new()
			label.text = part[0]
			label.theme_type_variation = &"LevelLabel"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", part[1])
			column.add_child(label)
		tile.add_child(column)
		row.add_child(tile)
	details.add_child(row)


## BMI-for-age z: the WHO 2007 band of the avatar's value (the same cut-offs as the game), then
## what the z is.
func z_explanation(z: float) -> String:
	var band := "FAILURE_EXPLAIN_Z_HEALTHY"
	if z < Config.get_float("fail.danger_z"):
		band = "FAILURE_EXPLAIN_Z_SEVERE_THIN"
	elif z < Config.get_float("avatar_states.thin_below_z"):
		band = "FAILURE_EXPLAIN_Z_THIN"
	elif z > Config.get_float("avatar_states.obese_above_z"):
		band = "FAILURE_EXPLAIN_Z_OBESE"
	elif z > Config.get_float("avatar_states.overweight_above_z"):
		band = "FAILURE_EXPLAIN_Z_OVER"
	return "%s %s" % [tr("FAILURE_EXPLAIN_Z") % [Settings.number(z, 2, true), tr(band)], tr("FAILURE_EXPLAIN_Z_INFO")]


## Physical, Happiness or Sleep: low, middle or good (failure_screen.measure_low_below and
## measure_good_from), then what the measure is.
func measure_explanation(key: String, amount: float) -> String:
	var band := "FAILURE_EXPLAIN_MIDDLE"
	if amount < Config.get_float("failure_screen.measure_low_below"):
		band = "FAILURE_EXPLAIN_LOW"
	elif amount >= Config.get_float("failure_screen.measure_good_from"):
		band = "FAILURE_EXPLAIN_GOOD"
	var info := tr({"MEASURE_PHYSICAL": "FAILURE_EXPLAIN_PHYSICAL_INFO", "MEASURE_HAPPINESS": "FAILURE_EXPLAIN_HAPPINESS_INFO"}.get(key, "FAILURE_EXPLAIN_SLEEP_INFO"))
	if key == "MEASURE_SLEEP":
		var group := GameState.age_group if not GameState.age_group.is_empty() else "child"
		info = info % [Settings.number(Config.get_float("sleep.%s_min_h" % group), 0), Settings.number(Config.get_float("sleep.%s_max_h" % group), 0)]
	return "%s %s" % [tr("FAILURE_EXPLAIN_MEASURE") % [tr(key), Settings.number(amount, 2), tr(band)], info]


## A measure's name and its bar, as in the measures panel.
func _measure(key: String, amount: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = tr(key)
	label.custom_minimum_size.x = 230
	label.add_theme_font_size_override("font_size", 20)
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = amount
	bar.show_percentage = false
	bar.custom_minimum_size.y = 30
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	row.add_child(bar)
	details.add_child(row)


## A habit: its picture, name and value, the gauge, and the recommendation under it.
func _habit(id: String, icon: String, name_key: String, value_text: String, recommended: String, amount: float,
		zone_from: float, zone_to: float, scale_max: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var picture: Control = RequestIcon.new()
	picture.custom_minimum_size = Vector2(40, 40)
	picture.kind = icon
	var title := Label.new()
	title.text = tr(name_key)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	var shown := Label.new()
	shown.text = value_text
	shown.add_theme_font_size_override("font_size", 20)
	row.add_child(picture)
	row.add_child(title)
	row.add_child(shown)
	details.add_child(row)
	var gauge: Control = HabitGauge.new()
	gauge.value = amount
	gauge.zone_from = zone_from
	gauge.zone_to = zone_to
	gauge.scale_max = maxf(scale_max, amount * 1.1)
	details.add_child(gauge)
	gauges[id] = gauge
	if not recommended.is_empty():
		_caption(recommended, 16, CAPTION_COLOR)
	return gauge


func cause_text(cause: String) -> String:
	match cause:
		"thinness":
			return tr("FAILURE_CAUSE_THINNESS") % [Settings.number(Config.get_float("fail.danger_z"), 0, true),
					roundi(Config.get_float("fail.danger_hours")), Settings.number(Config.get_float("fail.danger_failure_z"), 0, true),
					Settings.number(GameState.weight_z, 2, true)]
		"happiness":
			return tr("FAILURE_CAUSE_HAPPINESS") % [Settings.number(Config.get_float("fail.happiness_line"), 2),
					roundi(Config.get_float("fail.happiness_hours"))]
	return tr("FAILURE_CAUSE_HEALTH") % [Settings.number(Config.get_float("fail.health_line"), 1),
			roundi(Config.get_float("fail.health_hours"))]


## The avatar's habits over the last failure_screen.summary_days avatar days (fewer if it lived
## less), from the action log: hours slept, minutes of moderate-to-vigorous activity and hours of
## screens a day, and the meals and the share that were fast food.
static func habit_numbers() -> Dictionary:
	var window := minf(Config.get_float("failure_screen.summary_days") * Config.get_float("units.hours_per_day"),
			Habits.avatar_hours_total)
	var result := {"days": window / Config.get_float("units.hours_per_day"), "sleep_h": 0.0, "activity_min": 0.0,
			"screen_h": 0.0, "meals": 0, "fast_food_share": 0.0}
	if window <= 0.0:
		return result
	var fast_food := 0
	for entry in Habits.entries:
		if float(entry["start_total"]) < Habits.avatar_hours_total - window:
			continue
		var type: String = entry["type"]
		var hours := float(entry["hours"])
		if type in Config.get_value("log.sleep_types"):
			result["sleep_h"] += hours
		if entry["intensity"] in Config.get_value("log.activity_intensities"):
			result["activity_min"] += hours * Clock.MINUTES_PER_HOUR
		if type in Config.get_value("log.screen_types"):
			result["screen_h"] += hours
		if Hunger.is_food(type) and hours > 0.0:
			result["meals"] += 1
			if Hunger.food_value(type, "healthy") < 1.0:
				fast_food += 1
	# Per day; an avatar that lived less than a day shows that day's totals.
	for key in ["sleep_h", "activity_min", "screen_h"]:
		result[key] /= maxf(result["days"], 1.0)
	if result["meals"] > 0:
		result["fast_food_share"] = float(fast_food) / result["meals"]
	return result
