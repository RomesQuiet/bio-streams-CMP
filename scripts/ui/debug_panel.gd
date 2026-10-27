extends PanelContainer
## Debug panel (Milestone 3 Task 7; Milestone 10 Task 11: every v1 state). Only exists in debug builds (the Godot editor and
## debug exports); it removes itself from the published (release) game.
## Shows food, body, training, sleep, diet, happiness, measures, target and displayed health.
## F7 shows or hides it.

const Hunger := preload("res://scripts/health/hunger.gd")
const Energy := preload("res://scripts/health/energy.gd")
const BodySize := preload("res://scripts/health/body_size.gd")
const Training := preload("res://scripts/health/training.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")
const Happiness := preload("res://scripts/health/happiness.gd")
const AvatarStates := preload("res://scripts/health/avatar_states.gd")
const HealthModel := preload("res://scripts/health/health_model.gd")

@onready var info: Label = $Margin/Info


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	visible = false
	GameState.changed.connect(_refresh)
	Habits.day_closed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		visible = not visible
		_refresh()


func _refresh() -> void:
	if not visible:
		return
	var gs := GameState
	var lines: Array[String] = []
	lines.append("DEBUG (F7)  %s, %s, %s" % [gs.difficulty, gs.age_group, gs.sex])
	var portion: float = Hunger.healthy_portion_kcal()
	lines.append("Food  hunger %.0f kcal (%.2f healthy meals of %.0f)  %s" % [gs.hunger, gs.hunger / portion, portion,
			"HUNGRY" if Hunger.is_hungry() else "not hungry"])
	lines.append("  %.1f h since the last meal  weight %.1f kg  body age %.1f y  METy %.2f" % [gs.hours_since_meal,
			gs.weight_kg, gs.body_age_months / Config.get_float("units.months_per_year"), Energy.mety_now()])
	lines.append("  height %.1f cm  BMI-for-age z %+.2f (weight score %.2f)  energy deficit U %.2f" % [gs.height_m * 100.0,
			gs.weight_z, BodySize.weight_score(gs.weight_z), gs.deficit_u])
	lines.append("  last 24 h: eaten %.0f kcal, spent %.0f kcal" % [Energy.window_total("eaten"), Energy.window_total("spent")])
	lines.append("Body states")
	lines.append("  fitness %.3f  strength %.3f  overreaching O %.2f  capacity %.0f min (%.0f used today)" % [gs.fitness,
			gs.strength, gs.overreach, Training.capacity_min(), gs.exercise_minutes_today])
	lines.append("  recovery: cardio %.2f  strength %.2f  last strength start %.1f h ago (gap %.0f h)" % [gs.cardio_recovery,
			gs.strength_recovery, gs.hours_since_strength, Config.get_float("train.strength_min_gap_h")])
	lines.append("  sleep debt %.2f h  tiredness %.2f  %.1f h awake  last sleep %.1f h (night quality %.2f)" % [gs.sleep_debt,
			SleepModel.tiredness(), gs.hours_awake, gs.last_sleep_hours, gs.night_quality])
	lines.append("  calories spent while exercising (record) %.0f kcal%s" % [gs.calories_spent,
			"  strength session started too soon" if gs.strength_too_soon and Activities.is_running() else ""])
	lines.append("Diet  quality Q %.2f  craving C %.2f  habituation A %.2f" % [gs.diet_quality, gs.craving, gs.habituation])
	lines.append("Happiness %.3f -> baseline %.3f  fun %.2f  screen excess %.2f" % [gs.happiness, gs.happiness_baseline,
			Happiness.fun(), Happiness.screen_excess()])
	lines.append("Measures")
	lines.append("  physical %.3f  happiness %.3f  sleep %.3f" % [gs.physical, gs.happiness, gs.sleep])
	lines.append("Health target %.2f  displayed %.2f (level %d)" % [gs.target_health, gs.health, gs.health_level])
	lines.append("Failure timers: target health below line %.1f h, happiness below line %.1f h, danger (z below %.0f) %.1f h%s" % [
			gs.health_low_hours, gs.happiness_low_hours, Config.get_float("fail.danger_z"), gs.danger_hours,
			"  FAILURE (%s)" % HealthModel.failure_cause() if gs.is_at_failure() else ""])
	lines.append("Risk index R %.2f  hidden damage %.3f (no disease stages yet)" % [gs.risk_index, gs.disease_damage])
	lines.append("Avatar states: %s" % ", ".join(AvatarStates.current().keys().filter(func(k): return AvatarStates.current()[k])))
	lines.append("Scoring day %d  log entries %d  XP %.1f" % [Habits.current_day, Habits.entries.size(), gs.xp])
	lines.append("CSV log: %s" % (HealthLog.log_path if HealthLog.enabled else "off"))
	info.text = "\n".join(lines)
