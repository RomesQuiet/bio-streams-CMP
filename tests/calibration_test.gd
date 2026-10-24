extends SceneTree
## Calibration scenarios (Milestone 3, Task 6). Run from the project folder:
##   Godot --headless --path . -s res://tests/calibration_test.gd
## Simulates many avatar days with fixed habits and prints health per day. The habits
## go through the real action log (Habits) and the real daily update (GameState).
## If a scenario fails, p and the weights are NOT changed here: the result is reported
## so the values can be decided. Nothing is saved.

## How many avatar days each scenario runs.
const DAYS := 28
## Hours of one avatar day in the log.
const DAY_HOURS := 24.0
## Days of the week with muscle strength in the recommended plan (3 of 7).
const STRENGTH_WEEKDAYS := [0, 2, 4]
## The four habit types, as in data/config.json (habits).
const CARDIO := "cardio"
const STRENGTH := "strength"
const SCREENS := "entertainment"

var _failures := 0
var _gs: Node
var _habits: Node


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	_gs = root.get_node("GameState")
	_habits = root.get_node("Habits")
	root.get_node("Activities").reset()
	root.get_node("Clock").reset()

	for age_group in ["child", "teenager"]:
		_scenario_recommended(age_group)
		_scenario_short_sleep(age_group)
		_scenario_no_activity(age_group)
	_scenario_habit_change()

	print("%s (%d failed)" % ["ALL SCENARIOS PASSED" if _failures == 0 else "SOME SCENARIOS FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## 1. Recommended habits every day: health rises above 4 on Normal.
func _scenario_recommended(age_group: String) -> void:
	var sleep_hours := _recommended_sleep(age_group)
	var result := _simulate("normal", age_group, func(day: int) -> Dictionary:
		var exercise := STRENGTH if day % 7 in STRENGTH_WEEKDAYS else CARDIO
		return {"sleep": sleep_hours, "log": [[exercise, 1.0], [SCREENS, 2.0]]})
	_report("1 (%s) recommended habits: health rises above 4 on Normal" % age_group,
			"sleep %.1f h, 60 min activity, strength 3 days a week, 2 h screens" % sleep_hours,
			result, result["health"][-1] > 4.0)


## 2. 5 hours of sleep every day with lots of exercise: health never goes above 3.
func _scenario_short_sleep(age_group: String) -> void:
	var result := _simulate("normal", age_group, func(_day: int) -> Dictionary:
		return {"sleep": 5.0, "log": [[CARDIO, 1.0], [STRENGTH, 1.0], [SCREENS, 1.0]]})
	_report("2 (%s) 5 h of sleep and lots of exercise: health never goes above 3" % age_group,
			"sleep 5 h, 1 h cardio and 1 h strength every day, 1 h screens", result, result["health"].max() <= 3.0)


## 3. Good sleep but no activity and 6 h of screens: health falls below 3.
func _scenario_no_activity(age_group: String) -> void:
	var sleep_hours := _recommended_sleep(age_group)
	var result := _simulate("normal", age_group, func(_day: int) -> Dictionary:
		return {"sleep": sleep_hours, "log": [[SCREENS, 6.0]]})
	_report("3 (%s) good sleep, no activity, 6 h of screens: health falls below 3" % age_group,
			"sleep %.1f h, no exercise, 6 h screens" % sleep_hours, result, result["health"][-1] < 3.0)


## 4. Very hard: changing every habit on day 1 makes mental health drop; changing step
## by step makes it drop much less.
func _scenario_habit_change() -> void:
	var age_group := "child"
	var sleep_hours := _recommended_sleep(age_group)
	var start_mental: float = root.get_node("Config").get_float("difficulties.very_hard.mental")
	var start_sleep := 4.0  # Very hard sleeps very little at first.
	var at_once := _simulate("very_hard", age_group, func(day: int) -> Dictionary:
		var exercise := STRENGTH if day % 7 in STRENGTH_WEEKDAYS else CARDIO
		return {"sleep": sleep_hours, "log": [[exercise, 1.0], [SCREENS, 2.0]]})
	# Step by step: over 10 days, more sleep and exercise and fewer screens, a little each day.
	var step_days := 10.0
	var gradual := _simulate("very_hard", age_group, func(day: int) -> Dictionary:
		var t := minf(1.0, (day + 1) / step_days)
		var exercise := STRENGTH if day % 7 in STRENGTH_WEEKDAYS else CARDIO
		return {"sleep": lerpf(start_sleep, sleep_hours, t), "log": [[exercise, t], [SCREENS, lerpf(6.0, 2.0, t)]]})
	var drop_at_once: float = start_mental - (at_once["mental"] as Array).min()
	var drop_gradual: float = maxf(0.0, start_mental - (gradual["mental"] as Array).min())
	_print_series("4 Very hard, every habit changed on day 1", at_once)
	_print_series("4 Very hard, habits changed step by step over 10 days", gradual)
	var ok := drop_at_once > 0.0 and drop_gradual < 0.5 * drop_at_once
	print("   lowest mental: at once %.3f, step by step %.3f (start %.3f)" % [
			(at_once["mental"] as Array).min(), (gradual["mental"] as Array).min(), start_mental])
	_verdict("4 Very hard: changing every habit on day 1 makes mental drop; step by step much less", ok)


## Runs the days of one scenario. plan(day) gives {"sleep": hours, "log": [[type, hours], ...]}.
## Returns {"health": [...], "mental": [...], "physical": [...], "sleep": [...]}, one value per day,
## starting with the value before day 1.
func _simulate(difficulty: String, age_group: String, plan: Callable) -> Dictionary:
	_habits.reset()
	_gs.reset()
	_gs.start_new_avatar("Test", age_group, "female", difficulty)
	var result := {"health": [_gs.health], "mental": [_gs.mental], "physical": [_gs.physical], "sleep": [_gs.sleep]}
	for day in DAYS:
		var day_plan: Dictionary = plan.call(day)
		var start := day * DAY_HOURS
		var hour := 1.0
		for item in day_plan["log"]:
			if item[1] > 0.0:
				_habits.add_entry(item[0], start + hour, item[1])
			hour += item[1]
		# The sleep ends just before the next avatar day starts.
		_habits.avatar_hours_total = start + DAY_HOURS - 0.01
		_habits._score_sleep(day_plan["sleep"])
		for key in result:
			result[key].append(_gs.get(key))
	return result


func _recommended_sleep(age_group: String) -> float:
	var sleep_range: Vector2 = _gs.sleep_range(age_group)
	return (sleep_range.x + sleep_range.y) / 2.0


func _report(title: String, habits: String, result: Dictionary, ok: bool) -> void:
	_print_series("%s\n   habits: %s" % [title, habits], result)
	_verdict(title, ok)


func _print_series(title: String, result: Dictionary) -> void:
	print("\n== %s" % title)
	for key in ["health", "physical", "mental", "sleep"]:
		var line := "   %-8s" % key
		for i in result[key].size():
			if i % 4 == 0:
				line += " %d:%.2f" % [i, result[key][i]]
		print(line)
	print("   final: health %.2f, highest %.2f, lowest %.2f" % [result["health"][-1],
			(result["health"] as Array).max(), (result["health"] as Array).min()])


func _verdict(title: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  scenario %s" % ["PASS" if ok else "FAIL", title])
