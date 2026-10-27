extends "res://tests/calibration_test.gd"
## Parity run (Milestone 10.5, Task 5; team review, "Method"). Run from the project folder (it
## takes a few minutes):
##   Godot --headless --path . -s res://tests/parity_test.gd
## Plays the v1 scenarios as close to the v1 simulation as the game allows, then changes one
## thing at a time and prints how each result moves, to find the real causes of the
## differences from v1 (documentation/milestone10_calibration.md).
## Parity: the user's decisions are off (the health bar follows the target at every step,
## decision 1; a meal takes one 5-minute step instead of half an hour, decision 2; Very hard
## starts with happiness 0.15, decision 7), the 36-hour strength gap of Milestone 10.5 is off
## (v1 does not have it; the danger state changes no value), and the player looks for
## "I'm hungry!" every 5-minute step and eats at once. The too-soon rule stays (user decision of
## Milestone 10 Task 5): v1's 0.34 for strength twice a day is only reached when a too-soon
## session gives no effective minutes. Plans that v1 does not describe are guesses (decision
## 12); the run also tries other guesses and prints which ones come closer to v1.
## Nothing here is a pass or fail of the game: it prints numbers for the team. It ends with
## ALL PASSED when every run has finished. data/config.json is never written.

## The rows that use the guideline activity (for the plan guesses).
const GUIDELINE_ROWS := ["guidelines", "short_sleep", "short_sleep_extra_cardio", "gradual_switch", "abrupt_switch",
		"sport_fast_food", "strength_daily"]
## Difference 2: the imperfect plans whose happiness is about 0.1 below v1, and the guidelines.
const HAPPINESS_ROWS := ["guidelines", "short_sleep", "short_sleep_extra_cardio", "cardio_4h", "healthy_no_sport",
		"healthy_no_sport_7h"]
## Columns of a row: the snapshot keys in the order of V1, their names and formats.
const COLUMNS := ["kg", "z", "fitness", "strength", "physical", "sleep", "happiness", "target"]
const NAMES := ["kg", "z", "fitness", "strength", "Physical", "Sleep", "Happiness", "health"]
const FORMATS := ["%.1f", "%+.2f", "%.2f", "%.2f", "%.2f", "%.2f", "%.2f", "%.2f"]
## v1's severe diet (team review): about 2.3 meals and 1,145 kcal a day.
const V1_SEVERE_MEALS := 2.3
const V1_SEVERE_KCAL := 1145.0
## The happiness parts are averaged over the last LAST_DAYS avatar days of a run (near steady state).
const LAST_DAYS := 7
## A move smaller than this is not printed.
const SMALL := 0.005

var happiness_script: GDScript
var _step_hours := 0.0
## Config values before the parity run changed them, and the game's meal lengths.
var _config_original := {}
var _game_meal_hours := {}


func _process(_delta: float) -> bool:
	_prepare()
	happiness_script = load("res://scripts/health/happiness.gd")
	_step_hours = root.get_node("Simulation").step_minutes() / _config.get_float("units.minutes_per_hour")
	_set_parity()
	print("\n=== Parity run (boy of 10, Normal): decisions 1, 2 and 7 off, no 36 h strength gap; the player eats as soon as")
	print("    the avatar is hungry (checked every %.0f avatar minutes). Rows at day %d: ours (v1; - = not given). ===" % [check_hours * 60.0, SHORT])
	var parity := {}
	for scenario in V1:
		parity[scenario] = _play(scenario, "male", "child", "normal", SHORT)
	_print_rows(parity)
	_print_counts(parity)

	print("\n=== One thing at a time (from the parity run) ===")
	check_hours = 0.5
	var player := _play_rows(["severe_diet"] + HAPPINESS_ROWS)
	_print_moves("The game's player: looks every 30 avatar minutes (and never during an activity)", parity, player)
	check_hours = _step_hours
	_set_quick_meals(false)
	var meals := _play_rows(["severe_diet"] + HAPPINESS_ROWS)
	_print_moves("Decision 2 on: a meal takes half an hour", parity, meals)
	_set_quick_meals(true)
	instant_bar = false
	var bar := _play_rows(["guidelines", "short_sleep"])
	_print_moves("Decision 1 on: the health bar moves once a day (the target health does not change)", parity, bar)
	print("    XP per real hour: guidelines %.0f -> %.0f, 6 h sleep %.1f -> %.1f (v1 225 and 2.6)" % [
			_xp_per_real_hour(parity["guidelines"], SHORT), _xp_per_real_hour(bar["guidelines"], SHORT),
			_xp_per_real_hour(parity["short_sleep"], SHORT), _xp_per_real_hour(bar["short_sleep"], SHORT)])
	instant_bar = true
	_set_config("train.strength_min_gap_h", _config_original["train.strength_min_gap_h"])
	var gap := _play_rows(["guidelines", "strength_daily", "strength_twice"])
	_print_moves("Milestone 10.5 on: 36 h between strength sessions", parity, gap)
	_set_config("train.strength_min_gap_h", 0.0)
	_check_very_hard_parity()

	print("\n=== Plan guesses (decision 12): which plans come closer to v1? ===")
	guideline["cardio_min"] = 40.0
	guideline["football_min"] = 30.0
	var football := _play_rows(GUIDELINE_ROWS)
	guideline["cardio_min"] = 70.0
	guideline["football_min"] = 0.0
	_print_moves("Guideline activity = 40 min cardio + 30 min football (instead of 70 min cardio)", parity, football)
	_print_distance("  Distance from v1 over these rows, 70 min cardio -> 40 cardio + 30 football:", parity, football, GUIDELINE_ROWS)
	screens["no_sport_h"] = 2.0
	var screens_2h := _play_rows(["healthy_no_sport", "healthy_no_sport_7h"])
	screens["no_sport_h"] = 1.0
	_print_moves("No-sport plans with 2 h of screens a day (instead of 1 h)", parity, screens_2h)

	print("\n=== Checks of the causes found ===")
	screens["severe_diet_h"] = 0.0
	var no_screens := _play_rows(["severe_diet"])
	screens["severe_diet_h"] = 1.0
	guideline["strength_first"] = true
	var first := _play_rows(["guidelines"])
	guideline["strength_first"] = false
	guideline["strength_min"] = 60.0
	var long_sessions := _play_rows(["guidelines"])
	guideline["strength_min"] = 30.0
	_set_config("train.average_window_h", 168)
	var weekly := _play_rows(GUIDELINE_ROWS + ["strength_twice"])
	_set_config("train.average_window_h", _config_original["train.average_window_h"])
	_print_moves("Effective training minutes averaged over a week (train.average_window_h 168 instead of 24)", parity, weekly)
	_print_distance("  Distance from v1 over these rows, 24 h -> 168 h:", parity, weekly, GUIDELINE_ROWS + ["strength_twice"])

	_print_difference_1(parity, player, meals, no_screens)
	_print_difference_2(parity, football, screens_2h)
	_print_difference_4(parity, first, long_sessions, football, weekly)
	_finish()
	return true


# --- Settings ------------------------------------------------------------------------------

func _set_parity() -> void:
	check_hours = _step_hours
	instant_bar = true
	_set_config("health.difficulties.very_hard.happiness", 0.15)
	_set_config("train.strength_min_gap_h", 0.0)
	_set_quick_meals(true)


## Changes a config value in memory for this run only (data/config.json is never written) and
## remembers the value it had.
func _set_config(path: String, value: Variant) -> void:
	var keys := path.split(".")
	var node: Dictionary = _config._data
	for i in keys.size() - 1:
		node = node[keys[i]]
	var last: String = keys[-1]
	var has_value: bool = node[last] is Dictionary and node[last].has("value")
	if not _config_original.has(path):
		_config_original[path] = node[last]["value"] if has_value else node[last]
	if has_value:
		node[last]["value"] = value
	else:
		node[last] = value


## Meal length: one 5-minute step when quick (v1 eats at once), or the game's half hour (decision
## 2). Changes the activities in memory only.
func _set_quick_meals(quick: bool) -> void:
	var options: Dictionary = root.get_node("Activities").definitions["eat"]["options"]
	for food in options:
		if not _game_meal_hours.has(food):
			_game_meal_hours[food] = options[food]["duration_hours"]
		options[food]["duration_hours"] = _step_hours if quick else _game_meal_hours[food]


# --- Playing -------------------------------------------------------------------------------

func _play_rows(rows: Array) -> Dictionary:
	var results := {}
	for scenario in rows:
		results[scenario] = _play(scenario, "male", "child", "normal", SHORT)
	return results


## As in the scenario test, plus: the parts of happiness over the last LAST_DAYS days, and the
## minutes of strength done and done beyond the daily capacity.
func _record_step(result: Dictionary, hours: float, asleep: bool) -> void:
	super(result, hours, asleep)
	var gs: Node = root.get_node("GameState")
	var activities: Node = root.get_node("Activities")
	if activities.is_running() and activities.current_option in _config.get_value("train.strength_types"):
		result["strength_min_done"] = result.get("strength_min_done", 0.0) + hours * _config.get_float("units.minutes_per_hour")
		result["strength_min_beyond"] = result.get("strength_min_beyond", 0.0) + gs.beyond_capacity_minutes_step
	if gs.sim_hours / _config.get_float("units.hours_per_day") <= SHORT - LAST_DAYS:
		return
	var path := "mood.baseline."
	var parts := {
		"happiness": gs.happiness,
		"baseline": gs.happiness_baseline,
		"physical": _config.get_float(path + "physical") * gs.physical,
		"sleep": _config.get_float(path + "sleep") * gs.sleep,
		"diet": _config.get_float(path + "diet") * gs.diet_quality,
		"fun": _config.get_float(path + "fun") * happiness_script.fun(),
		"deficit": -_config.get_float(path + "deficit") * gs.deficit_u,
		"screen_excess": -_config.get_float(path + "screen_excess") * happiness_script.screen_excess(),
		"overreach": -_config.get_float(path + "overreach") * gs.overreach,
	}
	for key in parts:
		result["late_" + key] = result.get("late_" + key, 0.0) + parts[key] * hours
	result["late_hours"] = result.get("late_hours", 0.0) + hours
	if not asleep and gs.hunger > _config.get_float("mood.events.hungry_at_meals") * hunger.healthy_portion_kcal():
		result["late_hungry_hours"] = result.get("late_hungry_hours", 0.0) + hours


## Average of a part of happiness over the last days.
func _late(result: Dictionary, key: String) -> float:
	return result.get("late_" + key, 0.0) / maxf(result.get("late_hours", 0.0), TOLERANCE)


# --- Output --------------------------------------------------------------------------------

func _print_rows(results: Dictionary) -> void:
	print("%-44s %s" % ["Scenario", "  ".join(NAMES.map(func(name: String) -> String: return "%-15s" % name))])
	for scenario in results:
		var d: Dictionary = _day(results[scenario], SHORT)
		var v: Array = V1[scenario]
		var cells: Array = []
		for i in COLUMNS.size():
			cells.append("%-15s" % _pair(FORMATS[i], d[COLUMNS[i]], v[i]))
		print("%-44s %s" % [TITLES[scenario].left(44), "  ".join(cells)])


func _print_counts(results: Dictionary) -> void:
	print("\nFailure, danger state, lowest happiness, hungry share, meals and kcal a day, strength sessions too soon:")
	for scenario in results:
		var r: Dictionary = results[scenario]
		var days: float = r["days"].size() - 1
		print("  %-44s failure %-30s danger %-5s lowest %.2f  hungry %3.0f%%  %.2f meals (+%.2f skipped) %4.0f kcal  too soon %d of %d" % [
				TITLES[scenario].left(44), _failure_text(r), _day_text(r["danger_day"]), r["lowest_happiness"], r["hungry_share"] * 100.0,
				r["meals"] / days, r["skipped"] / days, r["kcal_per_day"], r["too_soon"], r["strength_sessions"]])


## How the rows move when one thing changes: "before -> after" for every column that moves,
## and the lowest happiness.
func _print_moves(title: String, before: Dictionary, after: Dictionary) -> void:
	print("\n" + title)
	for scenario in after:
		var a: Dictionary = _day(before[scenario], SHORT)
		var b: Dictionary = _day(after[scenario], SHORT)
		var moves: Array = []
		for i in COLUMNS.size():
			if absf(b[COLUMNS[i]] - a[COLUMNS[i]]) >= SMALL:
				moves.append("%s %s -> %s" % [NAMES[i], FORMATS[i] % a[COLUMNS[i]], FORMATS[i] % b[COLUMNS[i]]])
		var low_a: float = before[scenario]["lowest_happiness"]
		var low_b: float = after[scenario]["lowest_happiness"]
		if absf(low_b - low_a) >= SMALL:
			moves.append("lowest happiness %.2f -> %.2f" % [low_a, low_b])
		print("  %-44s %s" % [TITLES[scenario].left(44), "nothing moves" if moves.is_empty() else ", ".join(moves)])


## Mean distance |ours - v1| per column over these rows, before -> after (only where v1 gives it).
func _print_distance(title: String, before: Dictionary, after: Dictionary, rows: Array) -> void:
	var cells: Array = []
	for i in COLUMNS.size():
		var sums := [0.0, 0.0]
		var count := 0
		for scenario in rows:
			var v1: Variant = V1[scenario][i]
			if v1 == null:
				continue
			sums[0] += absf(_day(before[scenario], SHORT)[COLUMNS[i]] - float(v1))
			sums[1] += absf(_day(after[scenario], SHORT)[COLUMNS[i]] - float(v1))
			count += 1
		if count > 0:
			cells.append("%s %.3f -> %.3f" % [NAMES[i], sums[0] / count, sums[1] / count])
	print(title + "\n    " + ", ".join(cells))


## Very hard with decision 7 off (happiness 0.15, as v1) and on (0.30).
func _check_very_hard_parity() -> void:
	var rows := {}
	for happiness in [0.15, 0.30]:
		_set_config("health.difficulties.very_hard.happiness", happiness)
		for food in ["gradual_switch", "abrupt_switch"]:
			rows["%s %.2f" % [food, happiness]] = _play(food, "male", "child", "very_hard", SHORT)
	_set_config("health.difficulties.very_hard.happiness", 0.15)
	print("\nVery hard, decision 7 off (starting happiness 0.15, as v1) and on (0.30). v1: gradual 4.28 (lowest happiness 0.15),")
	print("abrupt 4.45 (lowest 0.07; 0.13 with 0.30, team review):")
	for key in rows:
		var d: Dictionary = _day(rows[key], SHORT)
		print("  %-22s health %.2f  happiness %.2f, lowest %.2f  z %+.2f  failure %s" % [key, d["target"], d["happiness"],
				rows[key]["lowest_happiness"], d["z"], _failure_text(rows[key])])


## Difference 1: what the severe diet eats, against v1 (about 2.3 meals and 1,145 kcal a day).
func _print_difference_1(parity: Dictionary, player: Dictionary, meals: Dictionary, no_screens: Dictionary) -> void:
	print("\n=== Difference 1: the severe diet (v1: about %.1f meals and %.0f kcal a day; 24.0 kg, z -3.85 at day 21) ===" % [
			V1_SEVERE_MEALS, V1_SEVERE_KCAL])
	print("\"I'm hungry!\" comes at most every 2 h; the player skips 2 of every 3. During the screens hour it cannot answer,")
	print("so one moment a day comes later and the last one falls after the end of the day.")
	for row in [["parity", parity], ["the game's 30-minute player", player], ["30-minute meals (decision 2)", meals],
			["no screens hour (nothing blocks it)", no_screens]]:
		var r: Dictionary = row[1]["severe_diet"]
		var days: float = r["days"].size() - 1
		var d: Dictionary = _day(r, SHORT)
		print("  %-36s %.2f meals eaten and %.2f skipped a day, %4.0f kcal a day; day 21: %.1f kg, z %+.2f; hungry %.0f%% of awake time" % [
				row[0], r["meals"] / days, r["skipped"] / days, r["kcal_per_day"], d["kg"], d["z"], r["hungry_share"] * 100.0])


## Difference 2: where happiness comes from in the last days of each run (baseline parts and the
## events, which are what keeps happiness away from its baseline).
func _print_difference_2(parity: Dictionary, football: Dictionary, screens_2h: Dictionary) -> void:
	print("\n=== Difference 2: happiness over days %d to %d, parity run (v1 happiness at day 21 in brackets) ===" % [SHORT - LAST_DAYS, SHORT])
	print("Baseline = 0.15 + Physical + Sleep + diet + fun parts - deficit - screen excess - overreaching; events = happiness - baseline.")
	print("The hunger penalty is the share of it from being hungry while awake (0.05 per hour, kept for about 12 h).")
	var rows := {}
	for scenario in HAPPINESS_ROWS:
		rows[scenario] = parity[scenario]
	for scenario in GUIDELINE_ROWS:
		if football.has(scenario) and scenario in HAPPINESS_ROWS:
			rows[scenario + " (football plan)"] = football[scenario]
	for scenario in screens_2h:
		rows[scenario + " (2 h screens)"] = screens_2h[scenario]
	for key in rows:
		var r: Dictionary = rows[key]
		var scenario: String = key.split(" (")[0]
		var hungry_rate: float = r.get("late_hungry_hours", 0.0) / maxf(r.get("late_hours", 0.0), TOLERANCE) \
				* _config.get_float("mood.events.hungry_per_h")
		print("  %-38s happiness %.2f (v1 %.2f)  baseline %.2f = Physical %.2f + Sleep %.2f + diet %.2f + fun %.2f %+.2f deficit %+.2f screens %+.2f overreaching;  events %+.2f, of which hunger about %+.2f" % [
				(TITLES[scenario].left(30) + key.substr(scenario.length())).left(38), _late(r, "happiness"), V1[scenario][6],
				_late(r, "baseline"), _late(r, "physical"), _late(r, "sleep"), _late(r, "diet"), _late(r, "fun"), _late(r, "deficit"),
				_late(r, "screen_excess"), _late(r, "overreach"), _late(r, "happiness") - _late(r, "baseline"),
				hungry_rate * _config.get_float("mood.tau_h")])


## Difference 4: guideline strength (v1 0.70) with the strength session after or before the rest
## of the day's activity (daily capacity), with 30 or 60-minute sessions, and with the effective
## minutes averaged over a week instead of the last 24 hours; and strength day by day.
func _print_difference_4(parity: Dictionary, first: Dictionary, long_sessions: Dictionary, football: Dictionary,
		weekly: Dictionary) -> void:
	print("\n=== Difference 4: guideline strength at day %d (v1 0.70) ===" % SHORT)
	for row in [["30 min after 70 min of cardio (parity)", parity], ["30 min before the cardio", first],
			["60 min after the cardio", long_sessions], ["30 min after 40 cardio + 30 football", football],
			["minutes averaged over a week (168 h)", weekly]]:
		var r: Dictionary = row[1]["guidelines"]
		print("  %-40s strength %.2f  fitness %.2f  too soon %d of %d  strength minutes beyond the daily capacity %.0f of %.0f" % [row[0],
				_day(r, SHORT)["strength"], _day(r, SHORT)["fitness"], r["too_soon"], r["strength_sessions"],
				r.get("strength_min_beyond", 0.0), r.get("strength_min_done", 0.0)])
	print("  Strength on waking, days %d to %d (strength sessions on days 14, 16 and 18; day 21 = after day 20):" % [SHORT - LAST_DAYS, SHORT])
	for row in [["24 h window", parity], ["168 h window", weekly]]:
		var values: Array = []
		for day in range(SHORT - LAST_DAYS, SHORT + 1):
			values.append("%.2f" % _day(row[1]["guidelines"], day)["strength"])
		print("    %-14s %s" % [row[0], "  ".join(values)])
