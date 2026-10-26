extends SceneTree
## Tests for diet and happiness (Milestone 10, Task 7; v1 Steps 7 and 10). Run from the project folder:
##   Godot --headless --path . -s res://tests/happiness_test.gd
## Checks how Q, C and A move with each meal, the meal, exercise, screens, hunger and waking
## events, fun, screen excess and the baseline, and then plays v1 scenarios for 21 avatar days
## through the real game: the guideline plan reaches happiness near 1, and, starting with a
## fast-food craving of 0.9, an abrupt switch to healthy food drops happiness lower than a
## gradual switch over a week. Uses a test save path; the real save is never touched.

const TOLERANCE := 0.001
const DAYS := 21
const SLEEP_HOURS := 10.5

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this
## test script is compiled.
var happiness: GDScript
var diet: GDScript
var hunger: GDScript
var _failures := 0
var _lowest := 1.0


func _process(_delta: float) -> bool:
	happiness = load("res://scripts/health/happiness.gd")
	diet = load("res://scripts/health/diet.gd")
	hunger = load("res://scripts/health/hunger.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_diet()
	_test_events()
	_test_baseline()
	_test_scenarios()

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## v1 Step 7: per meal Q += (x - Q) x 0.119, C += ((1 - x) - C) x 0.083, A += ((1 - x) - A) x 0.05.
func _test_diet() -> void:
	var gs := _new_avatar("normal")
	gs.diet_quality = 0.5
	gs.craving = 0.6
	gs.habituation = 0.5
	diet.on_meal("healthy_meal", 1.0)
	_check("a healthy meal: Q moves 1/8.4 of the way to 1", absf(gs.diet_quality - (0.5 + 0.5 / 8.4)) < TOLERANCE)
	_check("...C moves 1/12 of the way to 0", absf(gs.craving - (0.6 - 0.6 / 12.0)) < TOLERANCE)
	_check("...A moves 1/20 of the way to 0", absf(gs.habituation - (0.5 - 0.5 / 20.0)) < TOLERANCE)
	gs.diet_quality = 0.5
	diet.on_meal("fast_food_meal", 0.5)
	_check("half a fast-food meal moves Q half as far, toward 0", absf(gs.diet_quality - (0.5 - 0.5 * 0.5 / 8.4)) < TOLERANCE)


func _test_events() -> void:
	var gs := _new_avatar("normal")
	gs.craving = 0.9
	gs.habituation = 0.0
	gs.happiness = 0.5
	happiness.on_meal("healthy_meal", 1.0)
	_check("a healthy meal with craving 0.9: +0.01 - 0.06 x 0.9 = -0.044", absf(gs.happiness - (0.5 - 0.044)) < TOLERANCE)
	gs.happiness = 0.5
	happiness.on_meal("fast_food_meal", 1.0)
	_check("fast food with craving 0.9, no habituation: +0.01 + 0.054 = +0.064", absf(gs.happiness - 0.564) < TOLERANCE)
	gs.habituation = 1.0
	gs.happiness = 0.5
	happiness.on_meal("fast_food_meal", 1.0)
	_check("fully habituated, fast food gives only +0.01", absf(gs.happiness - 0.51) < TOLERANCE)
	gs.happiness = 0.5
	gs.fitness = 0.4
	happiness.on_activity_started("cardio")
	_check("starting cardio at fitness 0.4: -0.03 x 0.6 = -0.018", absf(gs.happiness - 0.482) < TOLERANCE)
	gs.happiness = 0.5
	happiness.on_activity_started("football")
	_check("starting football costs nothing", is_equal_approx(gs.happiness, 0.5))
	gs.happiness = 0.5
	gs.night_quality = 1.0
	happiness.on_wake()
	_check("waking after a good night: +0.08 x 0.5 = +0.04", absf(gs.happiness - 0.54) < TOLERANCE)
	gs.happiness = 0.5
	gs.night_quality = 4.0 / 9.0
	happiness.on_wake()
	_check("waking after 6 h (child): night quality 0.44 lowers happiness", gs.happiness < 0.5)

	# The wish for screens: every 4 awake hours without screens, -0.02.
	gs = _new_avatar("normal")
	gs.hunger = 0.0
	gs.hours_without_screens = 3.99
	gs.happiness = 0.6
	gs.happiness_baseline = 0.6
	var before: float = gs.happiness
	happiness.step(1.0 / 12.0, false)
	_check("4 awake hours without screens: the step loses about 0.02", gs.hours_without_screens < 1.0
			and before - gs.happiness > 0.015)
	gs.hunger = 2.0 * hunger.healthy_portion_kcal()
	gs.hours_without_screens = 0.0
	var hungry_before: float = gs.happiness
	happiness.step(1.0, false)
	var hungry_drop: float = hungry_before - gs.happiness
	gs.hunger = 0.0
	var fed_before: float = gs.happiness
	happiness.step(1.0, false)
	_check("hungry while awake costs about 0.05 per hour more", absf((hungry_drop - (fed_before - gs.happiness)) - 0.05) < 0.01)


## Baseline = 0.15 + 0.30 P + 0.25 S + 0.10 Q + 0.20 Fun - 0.2 U - 0.10 excess - 0.1 O.
func _test_baseline() -> void:
	var gs := _new_avatar("normal")
	gs.physical = 1.0
	gs.sleep = 1.0
	gs.diet_quality = 1.0
	gs.deficit_u = 0.0
	gs.overreach = 0.0
	_check("no fun yet: baseline 0.15 + 0.30 + 0.25 + 0.10 = 0.80", absf(happiness.baseline() - 0.8) < TOLERANCE)
	var activities: Node = root.get_node("Activities")
	_play_activity("entertainment", "football", 1.0)
	print("  1 h of football: fun %.2f (60 / 90 = 0.67)" % happiness.fun())
	_check("1 h of football gives fun 60 / 90", absf(happiness.fun() - 60.0 / 90.0) < 0.01)
	gs = _new_avatar("normal")
	for i in 4:
		_play_activity("entertainment", "screens", 1.0)
	print("  4 h of screens: fun %.2f (only the first 120 min count: 120 x 0.6 / 90 = 0.8), screen excess %.2f (1.0)"
			% [happiness.fun(), happiness.screen_excess()])
	_check("only the first 2 h of screens count for fun", absf(happiness.fun() - 0.8) < 0.01)
	_check("4 h of screens: screen excess 1", absf(happiness.screen_excess() - 1.0) < 0.01)
	gs.deficit_u = 1.0
	gs.overreach = 1.0
	var low: float = happiness.baseline()
	gs.deficit_u = 0.0
	gs.overreach = 0.0
	_check("U, O and screen excess lower the baseline by 0.2 + 0.1", absf(happiness.baseline() - low - 0.3) < TOLERANCE)
	_check("a meal is still logged while the Eat activity runs", activities.can_start("eat"))


## v1 'Predicted results': the guideline plan reaches happiness near 1; with craving 0.9, an
## abrupt switch to healthy food drops happiness lower than a gradual one over a week.
func _test_scenarios() -> void:
	var guideline := _play_plan(-1, 0.6)
	var abrupt := _play_plan(0, 0.9)
	var gradual := _play_plan(7, 0.9)
	print("  after %d avatar days (v1: guidelines 1.00; abrupt lowest 0.40, gradual lowest 0.50):" % DAYS)
	for row in [["guidelines", guideline], ["abrupt switch", abrupt], ["gradual switch", gradual]]:
		print("    %-15s happiness %.2f (lowest %.2f)  Q %.2f  C %.2f  hunger %.0f kcal" % [row[0], row[1]["happiness"], row[1]["lowest"],
				row[1]["Q"], row[1]["C"], row[1]["hunger"]])
	_check("the guideline plan reaches happiness near 1 (at least 0.9)", guideline["happiness"] >= 0.9)
	_check("healthy and happy together: diet quality near 1 too", guideline["Q"] > 0.9)
	_check("abrupt switch: happiness drops lower than with a gradual switch", abrupt["lowest"] < gradual["lowest"])
	_check("both switches end in the same place (happiness near 1)", absf(abrupt["happiness"] - gradual["happiness"]) < 0.05)


## Plays DAYS avatar days of the guideline activities (a boy of 10, Normal): 1 h cardio every
## day, 1 h strength on 3 non-consecutive days a week, 1 h of screens and 10.5 h of sleep. The
## avatar eats whenever it says "I'm hungry!" (checked every half hour), as a player would.
## switch_days: -1 = always healthy meals; 0 = healthy from day 1; n = the share of healthy
## meals grows by a quarter every n / 4 days, so all are healthy after n days.
## Starts with this fast-food craving.
func _play_plan(switch_days: int, craving: float) -> Dictionary:
	var gs := _new_avatar("normal")
	gs.craving = craving
	_lowest = gs.happiness
	var simulation: Node = root.get_node("Simulation")
	var clock: Node = root.get_node("Clock")
	var track := func(_hours: float, _asleep: bool) -> void: _lowest = minf(_lowest, gs.happiness)
	simulation.stepped.connect(track)
	for day in DAYS:
		var healthy_share := 1.0
		if switch_days > 0:
			healthy_share = clampf(floorf(4.0 * (day + 1) / switch_days) / 4.0, 0.25, 1.0)
		var events := {1.0: ["exercise", "cardio"], 5.5: ["entertainment", "screens"]}
		if day % 7 in [0, 2, 4]:
			events[2.5] = ["exercise", "strength"]
		var meals := 0
		var healthy := 0
		var time := 0.0
		while time < clock.day_length_hours - 0.5:
			_idle_until(time)
			if hunger.is_hungry():
				var food := "healthy_meal" if healthy < healthy_share * (meals + 1) - TOLERANCE else "fast_food_meal"
				_play_activity("eat", food, 1.0)
				meals += 1
				healthy += 1 if food == "healthy_meal" else 0
			if events.has(time):
				_play_activity(events[time][0], events[time][1], 1.0)
			time += 0.5
		_sleep(SLEEP_HOURS)
	simulation.stepped.disconnect(track)
	return {"happiness": gs.happiness, "lowest": _lowest, "Q": gs.diet_quality, "C": gs.craving, "hunger": gs.hunger}


func _play_activity(activity_id: String, option_id: String, share: float) -> void:
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	clock.debug_speed = 600.0
	activities.start(activity_id, option_id)
	var stop_at: float = activities.target_hours * share
	while activities.is_running() and activities.elapsed_hours < stop_at - TOLERANCE:
		clock._process(minf(0.05, clock.avatar_hours_to_real_seconds(stop_at - activities.elapsed_hours, false) / 600.0 + 1e-6))
	activities.stop()
	root.get_node("Simulation").flush()


func _idle_until(day_hours: float) -> void:
	var clock: Node = root.get_node("Clock")
	clock.debug_speed = 600.0
	while clock.day_elapsed_hours < day_hours:
		clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(day_hours - clock.day_elapsed_hours, false) / 600.0 + 1e-6))


func _sleep(hours: float) -> void:
	var clock: Node = root.get_node("Clock")
	_idle_until(clock.day_length_hours - 0.01)
	root.get_node("Activities").start("sleep", "sleep", hours)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	clock.wake_up()


func _new_avatar(difficulty: String) -> Node:
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	var gs: Node = root.get_node("GameState")
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", "child", "male", difficulty)
	return gs


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
