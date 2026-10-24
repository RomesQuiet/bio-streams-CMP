extends PanelContainer
## Debug panel (Milestone 3, Task 7). Only exists in debug builds (the Godot editor and
## debug exports); it removes itself from the published (release) game.
## Shows the habit scores, body states, measures, target and displayed health.
## F7 shows or hides it.

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
		lines.append("  strength %.2f  screens %.2f" % [Habits.scores["strength"], Habits.scores["screens"]])
	lines.append("Body states")
	lines.append("  fitness %.3f  muscle %.3f" % [gs.fitness, gs.muscle])
	lines.append("  sleep debt %.2f h  mood %.3f" % [gs.sleep_debt, gs.mood])
	lines.append("  weight z %+.1f (score %.2f)" % [gs.weight_z, gs.weight_score(gs.weight_z)])
	lines.append("  usual: sleep %.2f activity %.2f" % [gs.usual_habits.get("sleep", 0.0), gs.usual_habits.get("activity", 0.0)])
	lines.append("         strength %.2f screens %.2f" % [gs.usual_habits.get("strength", 0.0), gs.usual_habits.get("screens", 0.0)])
	lines.append("Measures")
	lines.append("  physical %.3f  mental %.3f" % [gs.physical, gs.mental])
	lines.append("  sleep %.3f" % gs.sleep)
	lines.append("Health target %.2f  displayed %.2f (level %d)" % [gs.target_health, gs.health, gs.health_level])
	lines.append("Scoring day %d  log entries %d  XP %.1f" % [Habits.current_day, Habits.entries.size(), gs.xp])
	info.text = "\n".join(lines)
