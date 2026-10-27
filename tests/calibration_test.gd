extends SceneTree
## Scenario tests: the v1 "Predicted results" and the "Bases fundamental check" (Milestone 10,
## Task 10; Milestone 10.5, Task 4). Run from the project folder (it takes a few minutes):
##   Godot --headless --path . -s res://tests/calibration_test.gd
## Plays the v1 scenarios through the real game loop and the real Eat, exercise, entertainment
## and sleep actions (a boy of 10 on Normal; then a girl of 10 and teenagers of both sexes),
## prints each scenario's row at day 21 next to the v1 prediction (and day 60 for five of
## them), failure and the danger state for every scenario, and PASS or FAIL for every rule of
## the "Bases fundamental check", the danger state, the Very hard checks and XP per real hour.
## The simulated player is the same in every run (nothing is random, so every run gives the
## same numbers): every check_hours avatar hours (0.5 h = 30 avatar minutes, about 43 real
## seconds) it looks whether the avatar says "I'm hungry!" and, if so, eats a whole meal at once
## (healthy or fast food by the scenario's food rule; the severe diet skips 2 hungry moments of
## every 3). Then it starts the activities planned for that time. It does not look during an
## activity, so a meal waits until the activity ends, and a meal can push the next planned
## activity back by half an hour. tests/parity_test.gd plays the same scenarios with a player
## that looks every 5-minute step.
## v1's plans are only partly known (decision 12): the guideline strength sessions are 30
## minutes and strength twice a day has 40 minutes of cardio (team review); how v1 made up the
## guideline 70 minutes is not known, so they are cardio here.
## The pass criteria are the rules, not the exact numbers: the v1 predictions came from a
## separate simulation. The health bar moves once per avatar day (decision 1), so the rows show
## the target health (compared with v1) and the displayed health.
## If a rule fails, no value is changed here: the numbers go to the team.

const SHORT := 21
const LONG := 60
const TOLERANCE := 0.001
const SLEEP_GOOD := 10.5
## The player stops looking for meals this many avatar hours before the awake period ends (a
## meal takes half an hour), and an activity is cut this long before the end, so nothing runs
## into the 0-hour rule.
const LAST_CHECK_BEFORE_END_H := 0.5
const DAY_END_MARGIN_H := 0.01

## v1 'Predicted results' at day 21 (boy of 10, Normal): kg, z, fitness, strength, Physical,
## Sleep, Happiness, Health. Scenarios marked * start with a fast-food craving of 0.9. null =
## not given. Strength every day is not in v1: its strength and health come from the team
## review's v1 model with the 36-hour gap (Milestone 10.5).
const V1 := {
	"guidelines": [33.2, 0.00, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	"couch": [48.6, 2.56, 0.10, 0.10, 0.07, 0.84, 0.53, 2.60],
	"fast_food_cardio": [35.6, 0.60, 0.91, 0.57, 0.32, 1.00, 0.74, 3.56],
	"severe_diet": [24.0, -3.85, 0.10, 0.10, 0.05, 1.00, 0.53, 2.66],
	"short_sleep_extra_cardio": [32.3, -0.27, 0.87, 0.70, 0.83, 0.45, 0.85, 3.79],
	"short_sleep": [35.7, 0.63, 0.80, 0.67, 0.87, 0.45, 0.83, 3.81],
	"gradual_switch": [34.3, 0.30, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	"abrupt_switch": [33.2, 0.00, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	"sport_fast_food": [42.4, 1.83, 0.83, 0.70, 0.27, 1.00, 0.75, 3.48],
	"cardio_4h": [28.2, -1.73, 0.86, 0.50, 0.63, 1.00, 0.85, 4.23],
	"strength_twice": [31.1, -0.63, 0.66, 0.34, 0.52, 1.00, 0.78, 3.97],
	"strength_daily": [null, null, null, 0.44, null, null, null, 4.42],
	"healthy_no_sport": [39.4, 1.37, 0.10, 0.10, 0.37, 1.00, 0.83, 3.77],
	"healthy_no_sport_7h": [40.3, 1.51, 0.10, 0.10, 0.35, 0.66, 0.70, 3.22],
}
const TITLES := {
	"guidelines": "Guidelines: healthy food, 70 min a day, 30 min strength 3 days a week, 1 h screens, 10.5 h sleep",
	"couch": "Couch: fast food, 3 h screens, no sport, 8 h sleep",
	"fast_food_cardio": "Fast food with 3 h of cardio a day",
	"severe_diet": "Severe diet (eats 1 meal in 3), no sport",
	"short_sleep_extra_cardio": "Guidelines but 6 h sleep, extra hour of cardio",
	"short_sleep": "Guideline activity, 6 h sleep",
	"gradual_switch": "Gradual switch to healthy food over a week *",
	"abrupt_switch": "Abrupt switch to healthy food *",
	"sport_fast_food": "Guideline sport and sleep, fast food only *",
	"cardio_4h": "4 h of cardio a day, healthy food",
	"strength_twice": "Strength twice a day (v1: 40 min cardio, strength 9 and 12 h after waking)",
	"strength_daily": "Guidelines but 1 h strength every day (review)",
	"healthy_no_sport": "Healthy food, no sport",
	"healthy_no_sport_7h": "Healthy food, no sport, 7 h sleep",
}
## Scenarios played for LONG days (v1 gives the day-60 z of the first four); the others for SHORT.
const LONG_RUNS := ["guidelines", "couch", "sport_fast_food", "healthy_no_sport", "severe_diet"]
## v1 at day 60: z.
const V1_DAY_60_Z := {"guidelines": -0.4, "couch": 3.1, "sport_fast_food": 2.0, "healthy_no_sport": 1.4}

## The simulated player looks whether the avatar is hungry every check_hours avatar hours
## (tests/parity_test.gd looks every 5-minute step).
var check_hours := 0.5
## The guideline activity of a day (tests/parity_test.gd tries other plans): minutes of cardio
## and of football, the strength session's minutes (3 non-consecutive days a week), and whether
## strength comes before the rest.
var guideline := {"cardio_min": 70.0, "football_min": 0.0, "strength_min": 30.0, "strength_first": false}
## True: the health bar follows the target health at every step (decision 1 off; parity test).
var instant_bar := false

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this test
## script is compiled.
var hunger: GDScript
var health_model: GDScript
var progress: GDScript
var _failures := 0
var _config: Node


func _process(_delta: float) -> bool:
	_prepare()
	print("\n=== v1 scenarios: boy of 10, Normal (start: %s) ===" % _start_text("male", "child", "normal"))
	print("Player: looks for \"I'm hungry!\" every %.0f avatar minutes and eats at once; never during an activity." % (check_hours * 60.0))
	var results := {}
	for scenario in V1:
		var days := LONG if scenario in LONG_RUNS else SHORT
		results[scenario] = _play(scenario, "male", "child", "normal", days)
	_print_table(results)
	_print_failures(results)
	_check_bases(results)
	_check_danger(results)
	_check_variants()
	_check_very_hard()
	_finish()
	return true


## Loads the scripts and keeps the real save and the CSV log out of the way.
func _prepare() -> void:
	hunger = load("res://scripts/health/hunger.gd")
	health_model = load("res://scripts/health/health_model.gd")
	progress = load("res://scripts/health/progress.gd")
	_config = root.get_node("Config")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("HealthLog").enabled = false


func _finish() -> void:
	DirAccess.remove_absolute(root.get_node("SaveGame").save_path)
	print("\n%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)


# --- Rules ---------------------------------------------------------------------------------

## Every row of the v1 "Bases fundamental check" table.
func _check_bases(r: Dictionary) -> void:
	print("\n=== Bases fundamental check (day %d; target health) ===" % SHORT)
	var g: Dictionary = _day(r["guidelines"], SHORT)
	var start: Dictionary = _day(r["guidelines"], 0)
	_rule("Exercise within norms raises health", "guidelines %.2f -> %.2f" % [start["target"], g["target"]],
			g["target"] > start["target"] + 1.0)
	var c4: Dictionary = _day(r["cardio_4h"], SHORT)
	var s2: Dictionary = _day(r["strength_twice"], SHORT)
	var sd: Dictionary = _day(r["strength_daily"], SHORT)
	_rule("Too much or too often does less good", "4 h cardio %.2f, strength twice %.2f, strength every day %.2f, guidelines %.2f" % [
			c4["target"], s2["target"], sd["target"], g["target"]],
			c4["target"] < g["target"] and s2["target"] < g["target"] and sd["target"] < g["target"])
	var couch: Dictionary = _day(r["couch"], SHORT)
	var sport_ff: Dictionary = _day(r["sport_fast_food"], SHORT)
	_rule("Fast food makes the avatar fatter", "z +%.2f -> couch %+.2f, sport and sleep with fast food %+.2f" % [start["z"], couch["z"], sport_ff["z"]],
			couch["z"] > start["z"] and sport_ff["z"] > start["z"])
	var gradual: Dictionary = _day(r["gradual_switch"], SHORT)
	_rule("Healthy food makes it slimmer", "z +%.2f -> guidelines %+.2f, gradual switch %+.2f" % [start["z"], g["z"], gradual["z"]],
			g["z"] < start["z"] and gradual["z"] < start["z"])
	var ff_cardio: Dictionary = _day(r["fast_food_cardio"], SHORT)
	_rule("Fast food with a lot of exercise: thinner, not healthy", "z %+.2f, Physical %.2f (guidelines %.2f)" % [ff_cardio["z"], ff_cardio["physical"], g["physical"]],
			ff_cardio["z"] < start["z"] and ff_cardio["physical"] < 0.5 * g["physical"])
	var severe: Dictionary = _day(r["severe_diet"], SHORT)
	_rule("Severe diet without exercise: thinner, not healthy (hungry and sad)",
			"z %+.2f, Physical %.2f, hungry (above 1.2 meals) %.0f%% of awake time (guidelines %.0f%%), lowest happiness %.2f" % [severe["z"],
			severe["physical"], r["severe_diet"]["hungry_share"] * 100.0, r["guidelines"]["hungry_share"] * 100.0, r["severe_diet"]["lowest_happiness"]],
			severe["z"] < start["z"] and severe["physical"] < 0.2 and r["severe_diet"]["hungry_share"] > 0.5
			and r["severe_diet"]["lowest_happiness"] < _config.get_float("avatar_states.sad_below"))
	var short: Dictionary = r["short_sleep"]
	var g7: Dictionary = _day(r["guidelines"], 7)
	var s7: Dictionary = _day(short, 7)
	var more_food: float = short["kcal_per_day"] / r["guidelines"]["kcal_per_day"] - 1.0
	_rule("Short sleep: slower fitness gain, more hunger, tired, worse health",
			"fitness day 7 %.2f vs %.2f; food %+.0f%%; Sleep %.2f; health %.2f vs %.2f; tired %.0f%% of awake time" % [s7["fitness"], g7["fitness"],
			more_food * 100.0, _day(short, SHORT)["sleep"], _day(short, SHORT)["target"], g["target"], short["tired_share"] * 100.0],
			s7["fitness"] < g7["fitness"] and more_food > 0.05 and _day(short, SHORT)["sleep"] < 0.7
			and _day(short, SHORT)["target"] < g["target"] and short["tired_share"] > r["guidelines"]["tired_share"])
	var abrupt: Dictionary = r["abrupt_switch"]
	_rule("Refusing wishes lowers happiness; exercise and sleep raise it",
			"lowest happiness: abrupt %.2f vs gradual %.2f; guidelines happiness %.2f" % [abrupt["lowest_happiness"],
			r["gradual_switch"]["lowest_happiness"], g["happiness"]],
			abrupt["lowest_happiness"] < r["gradual_switch"]["lowest_happiness"] and g["happiness"] > 0.85)
	_rule("Healthy and happy together", "guidelines health %.2f, happiness %.2f" % [g["target"], g["happiness"]],
			g["target"] >= 4.5 and g["happiness"] >= 0.85)
	var xp_good: float = _xp_per_real_hour(r["guidelines"], SHORT)
	var xp_short: float = _xp_per_real_hour(short, SHORT)
	_rule("Short sleep must not pay in real time", "%.1f XP per real hour with 6 h sleep against %.1f with 10.5 h (v1: 2.6 against 225)" % [xp_short, xp_good],
			xp_short < 0.25 * xp_good)


## Milestone 10.5 (team review): the severe diet reaches the danger state of severe thinness and
## then failure, before z -5 (biologically implausible); no other scenario reaches the danger state.
func _check_danger(r: Dictionary) -> void:
	print("\n=== Danger state of severe thinness (Milestone 10.5) ===")
	var severe: Dictionary = r["severe_diet"]
	_rule("The severe diet reaches the danger state, then failure before z -5",
			"danger from day %s; failure %s" % [_day_text(severe["danger_day"]), _failure_text(severe)],
			severe["danger_day"] >= 0.0 and severe["failure_cause"] == "thinness" and severe["failure_z"] > -5.0)
	var others: Array = []
	for scenario in r:
		if scenario != "severe_diet" and r[scenario]["danger_day"] >= 0.0:
			others.append(scenario)
	_rule("No other scenario reaches the danger state", "reached: %s" % ("none" if others.is_empty() else ", ".join(others)), others.is_empty())


## The same pattern for a girl of 10 and teenagers of both sexes (v1: "The same behaviour gives
## the same pattern"): guidelines raise health and lower z; the couch raises z.
func _check_variants() -> void:
	print("\n=== Variants (day %d) ===" % SHORT)
	for variant in [["female", "child"], ["male", "teenager"], ["female", "teenager"]]:
		var guide := _play("guidelines", variant[0], variant[1], "normal", SHORT)
		var couch := _play("couch", variant[0], variant[1], "normal", SHORT)
		var start: Dictionary = _day(guide, 0)
		var g: Dictionary = _day(guide, SHORT)
		var c: Dictionary = _day(couch, SHORT)
		_rule("%s %s: guidelines raise health and lower z, the couch raises z" % [variant[0], variant[1]],
				"start %.2f z %+.2f; guidelines %.2f z %+.2f; couch %.2f z %+.2f" % [start["target"], start["z"], g["target"], g["z"], c["target"], c["z"]],
				g["target"] > start["target"] + 1.0 and g["z"] < start["z"] and c["z"] > start["z"] and c["target"] < g["target"])


## Very hard (happiness 0.30, decision 7): starts with the lowest health, recovers with the
## guidelines, does not reach failure in the first days with a gradual change, and an abrupt
## food switch drops happiness lower than a gradual one. v1 (starting happiness 0.15): health
## 4.45 at day 21 with an abrupt switch, 4.28 with a gradual one; lowest happiness 0.07 abrupt
## (0.13 with 0.30, team review), 0.15 gradual.
func _check_very_hard() -> void:
	print("\n=== Very hard (start: %s) ===" % _start_text("male", "child", "very_hard"))
	var lowest_start := INF
	for difficulty in ["easy", "normal", "hard"]:
		lowest_start = minf(lowest_start, _start_health("male", "child", difficulty))
	var vh_start := _start_health("male", "child", "very_hard")
	_rule("Very hard starts with the lowest health", "%.2f (the others: %.2f or more)" % [vh_start, lowest_start], vh_start < lowest_start)
	var gradual := _play("gradual_switch", "male", "child", "very_hard", SHORT)
	var abrupt := _play("abrupt_switch", "male", "child", "very_hard", SHORT)
	for row in [["gradual switch", gradual, 4.28, "0.15"], ["abrupt switch", abrupt, 4.45, "0.07; 0.13 with 0.30"]]:
		var d: Dictionary = _day(row[1], SHORT)
		print("    %-15s target %.2f (v1 %.2f; bar %.2f)  happiness %.2f, lowest %.2f (v1 %s)  z %+.2f  failure %s" % [row[0],
				d["target"], row[2], d["health"], d["happiness"], row[1]["lowest_happiness"], row[3], d["z"], _failure_text(row[1])])
	_rule("Very hard recovers with the guidelines", "target %.2f -> %.2f" % [vh_start, _day(gradual, SHORT)["target"]],
			_day(gradual, SHORT)["target"] >= 3.0)
	_rule("Very hard with a gradual change does not reach failure in the first days", "failure %s" % _failure_text(gradual),
			gradual["failure_day"] < 0.0 or gradual["failure_day"] > 7.0)
	_rule("Very hard: an abrupt food switch drops happiness lower than a gradual one",
			"lowest %.2f vs %.2f" % [abrupt["lowest_happiness"], gradual["lowest_happiness"]], abrupt["lowest_happiness"] < gradual["lowest_happiness"])


# --- Playing a scenario --------------------------------------------------------------------

## Plays a scenario for this many avatar days and returns its daily values (index 0 = start)
## and its counts: {"days": [...], "lowest_happiness", "hungry_share", "tired_share",
## "kcal_per_day", "meals", "skipped", "awake_hours", "asleep_hours", "failure_day",
## "failure_cause", "failure_z", "danger_day", "strength_sessions", "too_soon"}. Days are avatar
## days since the start (24 avatar hours each), with decimals; -1 = never.
func _play(scenario: String, sex: String, group: String, difficulty: String, days: int) -> Dictionary:
	var gs := _new_avatar(sex, group, difficulty)
	if scenario in ["gradual_switch", "abrupt_switch", "sport_fast_food"]:
		gs.craving = maxf(gs.craving, 0.9)
	var result := {"days": [_snapshot(gs)], "lowest_happiness": gs.happiness, "hungry_hours": 0.0, "tired_hours": 0.0,
			"kcal_eaten": 0.0, "meals": 0, "skipped": 0, "awake_hours": 0.0, "asleep_hours": 0.0, "failure_day": -1.0,
			"failure_cause": "", "failure_z": 0.0, "danger_day": -1.0, "strength_sessions": 0, "too_soon": 0}
	var simulation: Node = root.get_node("Simulation")
	var activities: Node = root.get_node("Activities")
	var clock: Node = root.get_node("Clock")
	var on_step := func(hours: float, asleep: bool) -> void:
		_record_step(result, hours, asleep)
	# Simulation hears an activity start first, so strength_too_soon is already set here.
	var on_started := func(_activity_id: String, option_id: String) -> void:
		if option_id in _config.get_value("train.strength_types"):
			result["strength_sessions"] += 1
			if gs.strength_too_soon:
				result["too_soon"] += 1
	simulation.stepped.connect(on_step)
	activities.started.connect(on_started)
	var hungry_moments := 0
	for day in days:
		var plan := _day_plan(scenario, day)
		var slot := 0
		while slot * check_hours < clock.day_length_hours - LAST_CHECK_BEFORE_END_H:
			var time := slot * check_hours
			_idle_until(time)
			if hunger.is_hungry():
				hungry_moments += 1
				if plan["food"] == "skip_2_of_3" and hungry_moments % 3 != 0:
					hunger.skip()
					result["skipped"] += 1
				else:
					var food := _food_for(plan, result)
					result["kcal_eaten"] += hunger.meal_kcal(food, 1.0)
					result["meals"] += 1
					_play_activity("eat", food, 1.0)
			for event in plan["events"]:
				if absf(event[0] - time) < check_hours * 0.5:
					_play_activity(event[1], event[2], event[3])
			slot += 1
		_sleep(plan["sleep"])
		result["days"].append(_snapshot(gs))
	simulation.stepped.disconnect(on_step)
	activities.started.disconnect(on_started)
	result["hungry_share"] = result["hungry_hours"] / maxf(result["awake_hours"], TOLERANCE)
	result["tired_share"] = result["tired_hours"] / maxf(result["awake_hours"], TOLERANCE)
	result["kcal_per_day"] = result["kcal_eaten"] / days
	return result


## After every 5-minute step of a scenario: the hours awake, asleep, hungry and tired, the
## lowest happiness, and the first danger state and failure. With instant_bar the health bar
## jumps to the target (and the change gives or takes XP, as when the bar moves).
func _record_step(result: Dictionary, hours: float, asleep: bool) -> void:
	var gs: Node = root.get_node("GameState")
	if instant_bar:
		var change: float = gs.target_health - gs.health
		gs.health = gs.target_health
		progress.on_health_change(change)
	result["lowest_happiness"] = minf(result["lowest_happiness"], gs.happiness)
	if asleep:
		result["asleep_hours"] += hours
	else:
		result["awake_hours"] += hours
		# Hungry while awake as v1 Step 10 defines it: hunger above 1.2 healthy meals (a skipped
		# meal silences "I'm hungry!" for 2 hours, but the avatar stays hungry).
		if gs.hunger > _config.get_float("mood.events.hungry_at_meals") * hunger.healthy_portion_kcal():
			result["hungry_hours"] += hours
		if gs.tired:
			result["tired_hours"] += hours
	var day: float = gs.sim_hours / _config.get_float("units.hours_per_day")
	if result["danger_day"] < 0.0 and health_model.in_danger():
		result["danger_day"] = day
	if result["failure_day"] < 0.0 and gs.is_at_failure():
		result["failure_day"] = day
		result["failure_cause"] = health_model.failure_cause()
		result["failure_z"] = gs.weight_z


## What the avatar does on one day of a scenario: events [hour after waking, activity, option,
## share of the option's duration], the food rule and the hours of sleep.
func _day_plan(scenario: String, day: int) -> Dictionary:
	var sport := _guideline_sport(day % 7 in [0, 2, 4], guideline["strength_min"])
	var screens_1h := [[6.0, "entertainment", "screens", 1.0]]
	var plan := {"events": sport + screens_1h, "food": "healthy", "sleep": SLEEP_GOOD, "day": day}
	match scenario:
		"couch":
			plan["events"] = [[2.0, "entertainment", "screens", 1.0], [3.0, "entertainment", "screens", 1.0], [4.0, "entertainment", "screens", 1.0]]
			plan["food"] = "fast"
			plan["sleep"] = 8.0
		"fast_food_cardio":
			plan["events"] = [[1.0, "exercise", "cardio", 1.0], [2.0, "exercise", "cardio", 1.0], [3.0, "exercise", "cardio", 1.0]] + screens_1h
			plan["food"] = "fast"
		"severe_diet":
			plan["events"] = screens_1h
			plan["food"] = "skip_2_of_3"
		"short_sleep_extra_cardio":
			plan["events"] = sport + [[4.5, "exercise", "cardio", 1.0]] + screens_1h
			plan["sleep"] = 6.0
		"short_sleep":
			plan["sleep"] = 6.0
		"gradual_switch":
			plan["food"] = "gradual"
		"sport_fast_food":
			plan["food"] = "fast"
		"cardio_4h":
			plan["events"] = [[1.0, "exercise", "cardio", 1.0], [2.0, "exercise", "cardio", 1.0], [3.0, "exercise", "cardio", 1.0],
					[4.0, "exercise", "cardio", 1.0]] + screens_1h
		"strength_twice":
			# v1's plan (team review): 40 min of cardio, strength 1 h at 9 and 12 hours after
			# waking, 1 h of screens, no football.
			plan["events"] = [[1.0, "exercise", "cardio", 40.0 / 60.0], [9.0, "exercise", "strength", 1.0],
					[12.0, "exercise", "strength", 1.0]] + screens_1h
		"strength_daily":
			plan["events"] = _guideline_sport(true, 60.0) + screens_1h
		"healthy_no_sport":
			plan["events"] = screens_1h
		"healthy_no_sport_7h":
			plan["events"] = screens_1h
			plan["sleep"] = 7.0
	return plan


## The guideline activity of one day: guideline.cardio_min of cardio in blocks of at most 1 h,
## then guideline.football_min of football, one block per hour from 1 h after waking; on a
## strength day a strength session of strength_min after them (or first, with strength_first).
func _guideline_sport(strength_day: bool, strength_min: float) -> Array:
	var blocks: Array = []
	var cardio: float = guideline["cardio_min"]
	while cardio > TOLERANCE:
		blocks.append(["exercise", "cardio", minf(cardio, 60.0) / 60.0])
		cardio -= 60.0
	if guideline["football_min"] > 0.0:
		blocks.append(["entertainment", "football", guideline["football_min"] / 60.0])
	if strength_day:
		var session := ["exercise", "strength", strength_min / 60.0]
		if guideline["strength_first"]:
			blocks.push_front(session)
		else:
			blocks.append(session)
	var events: Array = []
	for i in blocks.size():
		events.append([1.0 + i] + blocks[i])
	return events


## Healthy or fast food for the next meal. "gradual": the share of healthy meals grows by a
## quarter every 7 / 4 days (all healthy after a week).
func _food_for(plan: Dictionary, result: Dictionary) -> String:
	match plan["food"]:
		"fast":
			return "fast_food_meal"
		"gradual":
			var share := clampf(floorf(4.0 * (plan["day"] + 1) / 7.0) / 4.0, 0.25, 1.0)
			result["gradual_meals"] = int(result.get("gradual_meals", 0)) + 1
			result["healthy_meals"] = int(result.get("healthy_meals", 0))
			var healthy: bool = result["healthy_meals"] < share * result["gradual_meals"] - TOLERANCE
			if healthy:
				result["healthy_meals"] += 1
			return "healthy_meal" if healthy else "fast_food_meal"
	return "healthy_meal"


func _snapshot(gs: Node) -> Dictionary:
	return {"kg": gs.weight_kg, "z": gs.weight_z, "fitness": gs.fitness, "strength": gs.strength, "physical": gs.physical,
			"sleep": gs.sleep, "happiness": gs.happiness, "target": gs.target_health, "health": gs.health, "xp": gs.xp}


func _day(result: Dictionary, day: int) -> Dictionary:
	return result["days"][mini(day, result["days"].size() - 1)]


## XP earned per real hour of play over these days (awake: 42 avatar minutes per real minute,
## asleep: 5; the same conversion as the Clock).
func _xp_per_real_hour(result: Dictionary, days: int) -> float:
	var clock: Node = root.get_node("Clock")
	var ratio: float = float(days) / (result["days"].size() - 1)
	var real_seconds: float = (clock.avatar_hours_to_real_seconds(result["awake_hours"], false)
			+ clock.avatar_hours_to_real_seconds(result["asleep_hours"], true)) * ratio
	return (_day(result, days)["xp"] - _day(result, 0)["xp"]) / (real_seconds / 3600.0)


# --- Output --------------------------------------------------------------------------------

func _print_table(results: Dictionary) -> void:
	print("\nRows at day %d: ours (v1; - = not given). Health: target (v1) and the displayed bar." % SHORT)
	print("%-62s %-14s %-15s %-11s %-11s %-11s %-11s %-11s %-18s" % ["Scenario", "kg", "z", "Fitness", "Strength", "Physical", "Sleep", "Happiness", "Health (bar)"])
	for scenario in V1:
		var d: Dictionary = _day(results[scenario], SHORT)
		var v: Array = V1[scenario]
		print("%-62s %-14s %-15s %-11s %-11s %-11s %-11s %-11s %-18s" % [TITLES[scenario].left(62),
				_pair("%.1f", d["kg"], v[0]), _pair("%+.2f", d["z"], v[1]), _pair("%.2f", d["fitness"], v[2]),
				_pair("%.2f", d["strength"], v[3]), _pair("%.2f", d["physical"], v[4]), _pair("%.2f", d["sleep"], v[5]),
				_pair("%.2f", d["happiness"], v[6]), _pair("%.2f", d["target"], v[7]) + " %.2f" % d["health"]])
	print("\nDay %d (v1 gives z only):" % LONG)
	for scenario in LONG_RUNS:
		var d: Dictionary = _day(results[scenario], LONG)
		print("  %-60s %.1f kg  %s  health %.2f (bar %.2f)" % [TITLES[scenario].left(60), d["kg"],
				_pair("z %+.2f", d["z"], V1_DAY_60_Z.get(scenario)), d["target"], d["health"]])


## Failure, the danger state and the player's counts for every scenario (team review, Method).
func _print_failures(results: Dictionary) -> void:
	print("\nEvery scenario, all days played: failure (day, cause, z), first day in the danger state, lowest happiness,")
	print("hungry share of awake time (above 1.2 meals), meals eaten and skipped and kcal eaten per day, strength sessions too soon.")
	for scenario in V1:
		var r: Dictionary = results[scenario]
		var days: float = r["days"].size() - 1
		print("  %-44s failure %-30s danger %-5s lowest %.2f  hungry %3.0f%%  %.2f meals (+%.2f skipped) %4.0f kcal a day  too soon %d of %d" % [
				TITLES[scenario].left(44), _failure_text(r), _day_text(r["danger_day"]), r["lowest_happiness"], r["hungry_share"] * 100.0,
				r["meals"] / days, r["skipped"] / days, r["kcal_per_day"], r["too_soon"], r["strength_sessions"]])


## "ours (v1)" with this format; "-" when v1 does not give the value.
func _pair(format: String, ours: float, v1: Variant) -> String:
	return "%s (%s)" % [format % ours, "-" if v1 == null else format % float(v1)]


func _failure_text(result: Dictionary) -> String:
	if result["failure_day"] < 0.0:
		return "none"
	return "day %.1f (%s, z %+.2f)" % [result["failure_day"], result["failure_cause"], result["failure_z"]]


func _day_text(day: float) -> String:
	return "none" if day < 0.0 else "%.1f" % day


func _rule(name: String, numbers: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s\n      %s" % ["PASS" if ok else "FAIL", name, numbers])


func _start_text(sex: String, group: String, difficulty: String) -> String:
	var gs := _new_avatar(sex, group, difficulty)
	return "%.1f kg, z %+.1f, Physical %.2f, Sleep %.2f, Happiness %.2f, health %.2f" % [gs.weight_kg, gs.weight_z,
			gs.physical, gs.sleep, gs.happiness, gs.health]


func _start_health(sex: String, group: String, difficulty: String) -> float:
	return _new_avatar(sex, group, difficulty).health


# --- Driving the game ----------------------------------------------------------------------

## Plays an activity for this share of its duration, never into the end of the awake period
## (the 0-hour rule would start a new day).
func _play_activity(activity_id: String, option_id: String, share: float) -> void:
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	clock.debug_speed = 600.0
	if not activities.start(activity_id, option_id):
		return
	var stop_at: float = minf(activities.target_hours * share, clock.day_length_hours - clock.day_elapsed_hours - DAY_END_MARGIN_H)
	while activities.is_running() and activities.elapsed_hours < stop_at - TOLERANCE:
		clock._process(minf(0.05, clock.avatar_hours_to_real_seconds(stop_at - activities.elapsed_hours, false) / 600.0 + 1e-6))
	activities.stop()
	root.get_node("Simulation").flush()


func _idle_until(day_hours: float) -> void:
	var clock: Node = root.get_node("Clock")
	clock.debug_speed = 600.0
	while clock.day_elapsed_hours < day_hours and clock.phase == clock.Phase.DAY:
		clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(day_hours - clock.day_elapsed_hours, false) / 600.0 + 1e-6))


func _sleep(hours: float) -> void:
	var clock: Node = root.get_node("Clock")
	_idle_until(clock.day_length_hours - 0.01)
	root.get_node("Activities").start("sleep", "sleep", hours)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	clock.wake_up()


func _new_avatar(sex: String, group: String, difficulty: String) -> Node:
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	var gs: Node = root.get_node("GameState")
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", group, sex, difficulty)
	return gs
