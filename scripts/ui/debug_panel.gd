extends PanelContainer
## Debug panel (Milestone 3, Task 7). Only exists in debug builds (the Godot editor and
## debug exports); it removes itself from the published (release) game.
## Shows the habit scores, body states, measures, target and displayed health.
## F7 shows or hides it.

const Hunger := preload("res://scripts/health/hunger.gd")
const Energy := preload("res://scripts/health/energy.gd")
const BodySize := preload("res://scripts/health/body_size.gd")

@onready var info: Label = $Margin/Info


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	visible = false
	GameState.changed.connect(_refresh)
	Habits.scores_updated.connect(_refresh)
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
	lines.append("Habit scores (last sleep %.1f h)" % Habits.last_sleep_hours)
	if Habits.scores.is_empty():
		lines.append("  none yet (no sleep has ended)")
	else:
		lines.append("  sleep %.2f  activity %.2f" % [Habits.scores["sleep"], Habits.scores["activity"]])
		lines.append("  strength %.2f  screens %.2f  enjoyment %.2f" % [Habits.scores["strength"],
				Habits.scores["screens"], Habits.scores.get("enjoyment", 0.0)])
	var portion: float = Hunger.healthy_portion_kcal()
	lines.append("Food  hunger %.0f kcal (%.2f healthy meals of %.0f)  %s" % [gs.hunger, gs.hunger / portion, portion,
			"HUNGRY" if Hunger.is_hungry() else "not hungry"])
	lines.append("  %.1f h since the last meal  weight %.1f kg  body age %.1f y  METy %.2f" % [gs.hours_since_meal,
			gs.weight_kg, gs.body_age_months / Config.get_float("units.months_per_year"), Energy.mety_now()])
	lines.append("  height %.1f cm  BMI-for-age z %+.2f (weight score %.2f)  energy deficit U %.2f" % [gs.height_m * 100.0,
			gs.weight_z, BodySize.weight_score(gs.weight_z), gs.deficit_u])
	lines.append("  last 24 h: eaten %.0f kcal, spent %.0f kcal" % [Energy.window_total("eaten"), Energy.window_total("spent")])
	lines.append("Body states")
	lines.append("  fitness %.3f  muscle %.3f" % [gs.fitness, gs.muscle])
	lines.append("  sleep debt %.2f h  mood %.1f / %d" % [gs.sleep_debt, gs.mood, Config.get_int("health_m4.mood_max")])
	lines.append("  habit cost %.2f mood points %s" % [gs.habit_cost_total,
			", ".join(gs.habit_costs.keys().map(func(h): return "%s %.2f" % [h, gs.habit_costs[h]]))])
	lines.append("  weight z %+.1f (score %.2f)" % [gs.weight_z, gs.weight_score(gs.weight_z)])
	lines.append("  usual H / rooted R:")
	for habit in gs.usual_habits:
		lines.append("    %s %.3f / %.3f" % [habit, gs.usual_habits[habit], gs.rootedness.get(habit, 0.0)])
	lines.append("Measures")
	lines.append("  physical %.3f  mental %.3f" % [gs.physical, gs.mental])
	lines.append("  sleep %.3f" % gs.sleep)
	lines.append("Health target %.2f  displayed %.2f (level %d)" % [gs.target_health, gs.health, gs.health_level])
	lines.append("Scoring day %d  log entries %d  XP %.1f" % [Habits.current_day, Habits.entries.size(), gs.xp])
	lines.append("CSV log: %s" % (HealthLog.log_path if HealthLog.enabled else "off"))
	info.text = "\n".join(lines)
