extends SceneTree
## Scenario tests: the v1 "Predicted results" and the "Bases fundamental check" (Milestone 10,
## Task 10). Run from the project folder (it takes a few minutes):
##   Godot --headless --path . -s res://tests/calibration_test.gd
## Plays the v1 scenarios through the real game loop and the real Eat, exercise, entertainment
## and sleep actions (a boy of 10 on Normal; then a girl of 10 and teenagers of both sexes),
## prints each scenario's row at day 21 next to the v1 prediction (and day 60 for four of
## them), and PASS or FAIL for every rule of the "Bases fundamental check", the Very hard
## checks and XP per real hour. The player eats whenever the avatar says "I'm hungry!".
## The pass criteria are the rules, not the exact numbers: the v1 predictions came from a
## separate simulation. The health bar moves once per avatar day (decision 1), so the rows show
## the target health (compared with v1) and the displayed health.
## If a rule fails, no value is changed here: the numbers go to the team.

const SHORT := 21
const LONG := 60
const TOLERANCE := 0.001
const SLEEP_GOOD := 10.5

## v1 'Predicted results' at day 21 (boy of 10, Normal): kg, z, fitness, strength, Physical,
## Sleep, Happiness, Health. Scenarios marked * start with a fast-food craving of 0.9.
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
	"healthy_no_sport": [39.4, 1.37, 0.10, 0.10, 0.37, 1.00, 0.83, 3.77],
	"healthy_no_sport_7h": [40.3, 1.51, 0.10, 0.10, 0.35, 0.66, 0.70, 3.22],
}
const TITLES := {
	"guidelines": "Guidelines: healthy food, 70 min a day, strength 3 days a week, 1 h screens, 10.5 h sleep",
	"couch": "Couch: fast food, 3 h screens, no sport, 8 h sleep",
	"fast_food_cardio": "Fast food with 3 h of cardio a day",
	"severe_diet": "Severe diet (eats 1 meal in 3), no sport",
	"short_sleep_extra_cardio": "Guidelines but 6 h sleep, extra hour of cardio",
	"short_sleep": "Guideline activity, 6 h sleep",
	"gradual_switch": "Gradual switch to healthy food over a week *",
	"abrupt_switch": "Abrupt switch to healthy food *",
	"sport_fast_food": "Guideline sport and sleep, fast food only *",
	"cardio_4h": "4 h of cardio a day, healthy food",
	"strength_twice": "Strength twice a day, every day",
	"healthy_no_sport": "Healthy food, no sport",
	"healthy_no_sport_7h": "Healthy food, no sport, 7 h sleep",
}
## Scenarios played for LONG days (v1 gives their day-60 values); the others for SHORT.
const LONG_RUNS := ["guidelines", "couch", "sport_fast_food", "healthy_no_sport"]
## v1 at day 60: z.
const V1_DAY_60_Z := {"guidelines": -0.4, "couch": 3.1, "sport_fast_food": 2.0, "healthy_no_sport": 1.4}

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this test
## script is compiled.
var hunger: GDScript
var health_model: GDScript
var _failures := 0
var _config: Node


func _process(_delta: float) -> bool:
	hunger = load("res://scripts/health/hunger.gd")
	health_model = load("res://scripts/health/health_model.gd")
	_config = root.get_node("Config")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("HealthLog").enabled = false

	print("\n=== v1 scenarios: boy of 10, Normal (start: %s) ===" % _start_text("male", "child", "normal"))
	var results := {}
	for scenario in V1:
		var days := LONG if scenario in LONG_RUNS else SHORT
		results[scenario] = _play(scenario, "male", "child", "normal", days)
	_print_table(results)
	_check_bases(results)
	_check_variants()
	_check_very_hard()

	DirAccess.remove_absolute(save_game.save_path)
	print("\n%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


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
	_rule("Too much or too often does less good", "4 h cardio %.2f, strength twice %.2f, guidelines %.2f" % [c4["target"], s2["target"], g["target"]],
			c4["target"] < g["target"] and s2["target"] < g["target"])
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
## food switch drops happiness lower than a gradual one.
func _check_very_hard() -> void:
	print("\n=== Very hard (start: %s) ===" % _start_text("male", "child", "very_hard"))
	var lowest_start := INF
	for difficulty in ["easy", "normal", "hard"]:
		lowest_start = minf(lowest_start, _start_health("male", "child", difficulty))
	var vh_start := _start_health("male", "child", "very_hard")
	_rule("Very hard starts with the lowest health", "%.2f (the others: %.2f or more)" % [vh_start, lowest_start], vh_start < lowest_start)
	var gradual := _play("gradual_switch", "male", "child", "very_hard", SHORT)
	var abrupt := _play("abrupt_switch", "male", "child", "very_hard", SHORT)
	for row in [["gradual switch", gradual], ["abrupt switch", abrupt]]:
		var d: Dictionary = _day(row[1], SHORT)
		print("    %-15s target %.2f (bar %.2f)  happiness %.2f, lowest %.2f  z %+.2f  failure in the first 7 days: %s" % [row[0],
				d["target"], d["health"], d["happiness"], row[1]["lowest_happiness"], d["z"], "yes" if row[1]["failure_day"] in range(0, 8) else "no"])
	print("    v1: guidelines from Very hard 1.35 -> 4.45 in 21 days; happiness lowest 0.07 abrupt, 0.15 gradual")
	_rule("Very hard recovers with the guidelines", "target %.2f -> %.2f" % [vh_start, _day(gradual, SHORT)["target"]],
			_day(gradual, SHORT)["target"] >= 3.0)
	_rule("Very hard with a gradual change does not reach failure in the first days", "first failure on day %s" % (
			"none" if gradual["failure_day"] < 0 else str(gradual["failure_day"])), gradual["failure_day"] < 0 or gradual["failure_day"] > 7)
	_rule("Very hard: an abrupt food switch drops happiness lower than a gradual one",
			"lowest %.2f vs %.2f" % [abrupt["lowest_happiness"], gradual["lowest_happiness"]], abrupt["lowest_happiness"] < gradual["lowest_happiness"])


# --- Playing a scenario --------------------------------------------------------------------

## Plays a scenario for this many avatar days and returns its daily values (index 0 = start)
## and its counts: {"days": [...], "lowest_happiness", "hungry_share", "tired_share",
## "kcal_per_day", "awake_hours", "asleep_hours", "failure_day"}.
func _play(scenario: String, sex: String, group: String, difficulty: String, days: int) -> Dictionary:
	var gs := _new_avatar(sex, group, difficulty)
	if scenario in ["gradual_switch", "abrupt_switch", "sport_fast_food"]:
		gs.craving = maxf(gs.craving, 0.9)
	var result := {"days": [_snapshot(gs)], "lowest_happiness": gs.happiness, "hungry_hours": 0.0, "tired_hours": 0.0,
			"kcal_eaten": 0.0, "awake_hours": 0.0, "asleep_hours": 0.0, "failure_day": -1}
	var simulation: Node = root.get_node("Simulation")
	var on_step := func(hours: float, asleep: bool) -> void:
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
	simulation.stepped.connect(on_step)
	var hungry_moments := 0
	for day in days:
		var plan := _day_plan(scenario, day)
		var clock: Node = root.get_node("Clock")
		var time := 0.0
		while time < clock.day_length_hours - 0.5:
			_idle_until(time)
			if hunger.is_hungry():
				hungry_moments += 1
				if plan["food"] == "skip_2_of_3" and hungry_moments % 3 != 0:
					hunger.skip()
				else:
					var food := _food_for(plan, result)
					result["kcal_eaten"] += hunger.meal_kcal(food, 1.0)
					_play_activity("eat", food, 1.0)
			for event in plan["events"]:
				if is_equal_approx(event[0], time):
					_play_activity(event[1], event[2], event[3])
			time += 0.5
		_sleep(plan["sleep"])
		result["days"].append(_snapshot(gs))
		if result["failure_day"] < 0 and gs.is_at_failure():
			result["failure_day"] = day + 1
	simulation.stepped.disconnect(on_step)
	result["hungry_share"] = result["hungry_hours"] / maxf(result["awake_hours"], TOLERANCE)
	result["tired_share"] = result["tired_hours"] / maxf(result["awake_hours"], TOLERANCE)
	result["kcal_per_day"] = result["kcal_eaten"] / days
	return result


## What the avatar does on one day of a scenario: events [hour after waking, activity, option,
## share of the option's duration], the food rule and the hours of sleep.
func _day_plan(scenario: String, day: int) -> Dictionary:
	var guideline_sport := [[1.0, "exercise", "cardio", 1.0], [2.0, "exercise", "cardio", 1.0 / 6.0]]
	if day % 7 in [0, 2, 4]:
		guideline_sport.append([3.0, "exercise", "strength", 1.0])
	var screens_1h := [[6.0, "entertainment", "screens", 1.0]]
	var plan := {"events": guideline_sport + screens_1h, "food": "healthy", "sleep": SLEEP_GOOD, "day": day}
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
			plan["events"] = guideline_sport + [[4.5, "exercise", "cardio", 1.0]] + screens_1h
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
			plan["events"] = [[1.0, "exercise", "cardio", 1.0], [2.0, "exercise", "cardio", 1.0 / 6.0], [3.0, "exercise", "strength", 1.0],
					[7.0, "exercise", "strength", 1.0]] + screens_1h
		"healthy_no_sport":
			plan["events"] = screens_1h
		"healthy_no_sport_7h":
			plan["events"] = screens_1h
			plan["sleep"] = 7.0
	return plan


## Healthy or fast food for the next meal. "gradual": the share of healthy meals grows by a
## quarter every 7 / 4 days (all healthy after a week).
func _food_for(plan: Dictionary, result: Dictionary) -> String:
	match plan["food"]:
		"fast":
			return "fast_food_meal"
		"gradual":
			var share := clampf(floorf(4.0 * (plan["day"] + 1) / 7.0) / 4.0, 0.25, 1.0)
			result["meals"] = int(result.get("meals", 0)) + 1
			result["healthy_meals"] = int(result.get("healthy_meals", 0))
			var healthy: bool = result["healthy_meals"] < share * result["meals"] - TOLERANCE
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
	print("\nRows at day %d: ours (v1). Health: target (v1) and the displayed bar." % SHORT)
	print("%-62s %-14s %-15s %-11s %-11s %-11s %-11s %-11s %-18s" % ["Scenario", "kg", "z", "Fitness", "Strength", "Physical", "Sleep", "Happiness", "Health (bar)"])
	for scenario in V1:
		var d: Dictionary = _day(results[scenario], SHORT)
		var v: Array = V1[scenario]
		print("%-62s %-14s %-15s %-11s %-11s %-11s %-11s %-11s %-18s" % [TITLES[scenario].left(62),
				"%.1f (%.1f)" % [d["kg"], v[0]], "%+.2f (%+.2f)" % [d["z"], v[1]], "%.2f (%.2f)" % [d["fitness"], v[2]],
				"%.2f (%.2f)" % [d["strength"], v[3]], "%.2f (%.2f)" % [d["physical"], v[4]], "%.2f (%.2f)" % [d["sleep"], v[5]],
				"%.2f (%.2f)" % [d["happiness"], v[6]], "%.2f (%.2f) %.2f" % [d["target"], v[7], d["health"]]])
	print("\nDay %d (v1 gives z only):" % LONG)
	for scenario in LONG_RUNS:
		var d: Dictionary = _day(results[scenario], LONG)
		print("  %-60s %.1f kg  z %+.2f (v1 %+.1f)  health %.2f (bar %.2f)" % [TITLES[scenario].left(60), d["kg"], d["z"],
				V1_DAY_60_Z[scenario], d["target"], d["health"]])


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

func _play_activity(activity_id: String, option_id: String, share: float) -> void:
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	clock.debug_speed = 600.0
	if not activities.start(activity_id, option_id):
		return
	var stop_at: float = activities.target_hours * share
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
