extends SceneTree
## Simulation tests with the team's scenarios (Milestone 4, Task 7). Run from the project folder:
##   Godot --headless --path . -s res://tests/calibration_test.gd
## Simulates many avatar days with fixed habits, on each difficulty, through the real
## action log (Habits) and the real daily update (GameState), and prints health per day.
## The pass criteria come from the research plan (Phase 1). The run is repeated with
## p = 0.2, 0.5 and 1 so the team can compare; only the run with the p in config decides
## the result. If a scenario fails, NO value is changed here: the numbers are reported so
## the team can decide. Nothing is saved.

## How many avatar days each scenario runs.
const DAYS := 60
## Values of p printed for comparison (MILESTONE_4.md Task 7).
const COMPARE_P := [0.2, 0.5, 1.0]
const DIFFICULTIES := ["easy", "normal", "hard", "very_hard"]
## The scenarios use a child (reference age 10).
const AGE_GROUP := "child"
## Days of the week with muscle strength in the recommended plan (3 of 7).
const STRENGTH_WEEKDAYS := [0, 2, 4]
## Days printed in each row.
const SHOWN_DAYS := [0, 1, 3, 5, 10, 20, 30, 45, 60]
## How the criteria are read (my reading of the research plan; the team can change them):
## "reaches 5" = health level 5 (health 4.5 or more, shown rounded as 5);
## "not in the first avatar days" = not before day SLOW_DAYS;
## "the minimum" = the failure threshold (health.failure_at_health);
## "not at once" = not before day NOT_AT_ONCE_DAYS;
## "recovery is possible" = Very hard reaches health RECOVERED_HEALTH;
## "the gradual change gives better mental health" = the concept's "a gradual transition
## keeps mental health stable; without one mental health falls": a change in GRADUAL_DAYS
## days never lets mental fall below its starting value; on the difficulties where changing
## is costly (COSTLY_CHANGE) the sudden change does fall in the first TRANSITION_DAYS days
## and the gradual change keeps a higher lowest mental there; and a change in
## SLOW_CHANGE_DAYS days has a lower average mental over the first AVERAGE_DAYS days than
## the gradual one (changing too slowly is not the best plan).
const LEVEL_5_HEALTH := 4.5
const SLOW_DAYS := 10
const NOT_AT_ONCE_DAYS := 3
const RECOVERED_HEALTH := 3.0
const GRADUAL_DAYS := 10
const SLOW_CHANGE_DAYS := 40
const TRANSITION_DAYS := 10
const AVERAGE_DAYS := 30
const COSTLY_CHANGE := ["normal", "very_hard"]
## Mental below its starting value by more than this counts as a fall.
const FALL_TOLERANCE := 0.0001
## The habit types, as in data/activities.json.
const CARDIO := "cardio"
const STRENGTH := "strength"
const SCREENS := "entertainment"

var _failures := 0
var _gs: Node
var _habits: Node
var _config: Node


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	_gs = root.get_node("GameState")
	_habits = root.get_node("Habits")
	_config = root.get_node("Config")
	root.get_node("Activities").reset()
	root.get_node("Clock").reset()

	var p_entry: Dictionary = _config._data["health_m4"]["combine"]["p"]
	var p_config: float = p_entry["value"]
	# First the p in config, which decides PASS/FAIL; then the comparison values.
	var runs := [p_config]
	for p in COMPARE_P:
		if not is_equal_approx(p, p_config):
			runs.append(p)
	for i in runs.size():
		p_entry["value"] = runs[i]
		print("\n################ p = %.2f %s ################" % [runs[i], "(the value in config: decides PASS/FAIL)" if i == 0 else "(comparison only)"])
		_run_all(i == 0)
	p_entry["value"] = p_config

	print("\n%s (%d failed, with p = %.2f from config)" % ["ALL SCENARIOS PASSED" if _failures == 0 else "SOME SCENARIOS FAILED",
			_failures, p_config])
	quit(1 if _failures > 0 else 0)
	return true


func _run_all(counts: bool) -> void:
	print("   %-34s %-9s %s" % ["scenario", "level", "health on day " + ", ".join(SHOWN_DAYS.map(func(d): return str(d)))])
	for difficulty in DIFFICULTIES:
		var perfect := _simulate(difficulty, _perfect_plan)
		var athlete := _simulate(difficulty, _athlete_plan)
		var sedentary := _simulate(difficulty, _sedentary_plan)
		var ignores := _simulate(difficulty, _ignore_plan)
		var gradual := _simulate(difficulty, _gradual_plan.bind(difficulty, GRADUAL_DAYS))
		var slow := _simulate(difficulty, _gradual_plan.bind(difficulty, SLOW_CHANGE_DAYS))
		print("\n   -- %s (start health %.2f)" % [difficulty, perfect["health"][0]])

		_row("athlete, sleeps 5 h", difficulty, athlete)
		var athlete_ok: bool = _max_after_start(athlete) <= maxf(3.0, athlete["health"][0]) and athlete["health"][-1] <= 3.0
		_verdict("athlete who sleeps 5 h: health never goes above 3", difficulty, athlete_ok, counts)

		_row("sedentary, sleeps well", difficulty, sedentary)
		var sedentary_ok: bool = sedentary["health"][-1] < perfect["health"][-1] \
				and (sedentary["health"] as Array).min() > _config.get_float("health_m4.failure_at_health")
		_verdict("sedentary who sleeps well: below perfect, never at the minimum", difficulty, sedentary_ok, counts)

		_row("perfect player", difficulty, perfect)
		var day_5 := _first_day_at_least(perfect, LEVEL_5_HEALTH)
		var perfect_ok := day_5 >= SLOW_DAYS
		print("      reaches level 5 (health %.1f) on day %s" % [LEVEL_5_HEALTH, str(day_5) if day_5 >= 0 else "never"])
		_verdict("perfect player: reaches 5, but slowly (not before day %d)" % SLOW_DAYS, difficulty, perfect_ok, counts)

		_row("sudden change (perfect at once)", difficulty, perfect, "mental")
		_row("gradual change (%d days)" % GRADUAL_DAYS, difficulty, gradual, "mental")
		_row("slow change (%d days)" % SLOW_CHANGE_DAYS, difficulty, slow, "mental")
		var start_mental: float = perfect["mental"][0]
		var gradual_lowest: float = (gradual["mental"] as Array).slice(1).min()
		var sudden_low: float = (perfect["mental"] as Array).slice(1, TRANSITION_DAYS + 1).min()
		var gradual_low: float = (gradual["mental"] as Array).slice(1, TRANSITION_DAYS + 1).min()
		var gradual_average := _average(gradual["mental"], AVERAGE_DAYS)
		var slow_average := _average(slow["mental"], AVERAGE_DAYS)
		print("      start mental %.3f; lowest in days 1 to %d: sudden %.3f, gradual %.3f; gradual lowest ever %.3f; average days 1 to %d: gradual %.3f, slow %.3f" % [
				start_mental, TRANSITION_DAYS, sudden_low, gradual_low, gradual_lowest, AVERAGE_DAYS, gradual_average, slow_average])
		var stable := gradual_lowest >= start_mental - FALL_TOLERANCE
		var sudden_falls := sudden_low < start_mental - FALL_TOLERANCE and gradual_low > sudden_low
		var gradual_ok: bool = stable and (sudden_falls or not difficulty in COSTLY_CHANGE) and slow_average < gradual_average
		_verdict("gradual change keeps mental stable%s; changing too slowly is not best" % (
				", sudden change makes it fall" if difficulty in COSTLY_CHANGE else ""), difficulty, gradual_ok, counts)

		_row("ignores everything", difficulty, ignores)
		var minimum_day := _first_day_at_most(ignores, _config.get_float("health_m4.failure_at_health"))
		var ignore_ok := minimum_day >= NOT_AT_ONCE_DAYS
		print("      reaches the minimum (health %.2f) on day %s" % [_config.get_float("health_m4.failure_at_health"),
				str(minimum_day) if minimum_day >= 0 else "never"])
		_verdict("ignores everything: reaches the minimum, but not at once", difficulty, ignore_ok, counts)

		if difficulty == "very_hard":
			var recovered := _first_day_at_least(perfect, RECOVERED_HEALTH)
			print("      Very hard with perfect habits reaches health %.1f on day %s" % [RECOVERED_HEALTH,
					str(recovered) if recovered >= 0 else "never"])
			_verdict("Very hard: recovery is possible", difficulty, recovered >= 0, counts)


# --- Habit plans: plan(day) -> {"sleep": hours, "log": [[type, hours], ...]} ---

## Recommended habits: sleep in the range, 60 min of activity, strength 3 days a week,
## 2 h of screens (which also gives full enjoyment).
func _perfect_plan(day: int) -> Dictionary:
	return {"sleep": _good_sleep(), "log": [[_exercise(day), 1.0], [SCREENS, 2.0]]}


## Lots of exercise (2 h a day, strength every day) but only 5 h of sleep.
func _athlete_plan(_day: int) -> Dictionary:
	return {"sleep": 5.0, "log": [[CARDIO, 1.0], [STRENGTH, 1.0], [SCREENS, 1.0]]}


## Good sleep, no activity, 4 h of screens.
func _sedentary_plan(_day: int) -> Dictionary:
	return {"sleep": _good_sleep(), "log": [[SCREENS, 4.0]]}


## Never sleeps (the 0-hour rule every day), no activity, 6 h of screens.
func _ignore_plan(_day: int) -> Dictionary:
	return {"sleep": 0.0, "log": [[SCREENS, 6.0]]}


## From the difficulty's usual habits (start_H) to the perfect plan in change_days days.
func _gradual_plan(day: int, difficulty: String, change_days: int) -> Dictionary:
	var t := minf(1.0, (day + 1) / float(change_days))
	var path := "health_m4.difficulties.%s.start_H." % difficulty
	var intensity := "health_m4.habit_intensity."
	var start_sleep: float = _config.get_float(path + "sleep") * _config.get_float(intensity + "sleep_full_h")
	var start_activity: float = _config.get_float(path + "activity") * _config.get_float(intensity + "activity_full_min") / 60.0
	var start_screens: float = _config.get_float(path + "screens") * _config.get_float(intensity + "screens_full_h")
	return {"sleep": lerpf(start_sleep, _good_sleep(), t),
			"log": [[_exercise(day), lerpf(start_activity, 1.0, t)], [SCREENS, lerpf(start_screens, 2.0, t)]]}


func _good_sleep() -> float:
	var sleep_range: Vector2 = _gs.sleep_range(AGE_GROUP)
	return (sleep_range.x + sleep_range.y) / 2.0


func _exercise(day: int) -> String:
	return STRENGTH if day % 7 in STRENGTH_WEEKDAYS else CARDIO


# --- Simulation and output ---

## Runs DAYS scoring days. Returns {"health": [...], "mental": [...]}, one value per day,
## starting with the value before day 1.
func _simulate(difficulty: String, plan: Callable) -> Dictionary:
	_habits.reset()
	_gs.reset()
	_gs.start_new_avatar("Test", AGE_GROUP, "female", difficulty)
	var result := {"health": [_gs.health], "mental": [_gs.mental]}
	for day in DAYS:
		var day_plan: Dictionary = plan.call(day)
		for item in day_plan["log"]:
			if item[1] > 0.0:
				_habits.add_entry(item[0], item[1])
		_habits.end_scoring_day(day_plan["sleep"])
		for key in result:
			result[key].append(_gs.get(key))
	return result


func _row(name: String, _difficulty: String, result: Dictionary, key := "health") -> void:
	var values: Array = result[key]
	var shown := SHOWN_DAYS.map(func(d): return "%.2f" % values[d])
	print("   %-34s %-9s %s" % [name, key, "  ".join(shown)])


func _max_after_start(result: Dictionary) -> float:
	return (result["health"] as Array).slice(1).max()


func _first_day_at_least(result: Dictionary, value: float) -> int:
	for day in result["health"].size():
		if result["health"][day] >= value:
			return day
	return -1


func _first_day_at_most(result: Dictionary, value: float) -> int:
	for day in result["health"].size():
		if result["health"][day] <= value:
			return day
	return -1


func _average(values: Array, days: int) -> float:
	var total := 0.0
	for day in range(1, days + 1):
		total += values[day]
	return total / days


func _verdict(title: String, difficulty: String, ok: bool, counts: bool) -> void:
	if counts and not ok:
		_failures += 1
	print("   %s  %s: %s" % ["PASS" if ok else "FAIL", difficulty, title])
