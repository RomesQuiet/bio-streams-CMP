extends SceneTree
## Tests for training (Milestone 10, Task 5; v1 Step 6). Run from the project folder:
##   Godot --headless --path . -s res://tests/training_test.gd
## Checks the daily capacity, minutes beyond it, recovery (strength 86% after 48 h), a strength
## session that starts too soon (low recovery, or within 36 h of the previous start: Milestone
## 10.5), the starting window, and then plays four plans for 21 avatar days through the real
## game: the guideline plan raises fitness and strength; 4 h of cardio a day, strength twice a
## day and strength every day end with less strength and build overreaching.
## Uses a test save path; the real save is never touched.

const TOLERANCE := 0.001
const DAYS := 21
const SLEEP_HOURS := 10.5

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this
## test script is compiled.
var training: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	training = load("res://scripts/health/training.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_capacity_and_performance()
	_test_recovery()
	_test_too_soon_and_beyond_capacity()
	_test_minimum_gap()
	_test_starting_window()
	_test_plans()

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Capacity = (60 + 90 x fitness) x (1 - 0.3 x d); performance = 0.7 + 0.3 x score x (1 - 0.3 x tiredness).
func _test_capacity_and_performance() -> void:
	var gs := _new_avatar("normal")
	gs.sleep_debt = 0.0
	gs.hours_awake = 0.0
	_check("fitness 0.4, no sleep debt: capacity 96 minutes", absf(training.capacity_min() - 96.0) < TOLERANCE)
	gs.fitness = 1.0
	_check("fitness 1: capacity 150 minutes", absf(training.capacity_min() - 150.0) < TOLERANCE)
	gs.sleep_debt = 8.0
	_check("full sleep debt (d = 1): capacity x 0.7", absf(training.capacity_min() - 105.0) < TOLERANCE)
	gs.sleep_debt = 0.0
	_check("rested, minigame score 1: performance 1", is_equal_approx(training.performance(), 1.0))
	gs.sleep_debt = 8.0
	_check("fully tired: performance 0.7 + 0.3 x 0.7 = 0.91", absf(training.performance() - 0.91) < TOLERANCE)


## Strength tires fully after 45 minutes and recovers with a 24 h time constant: 86% after
## 48 h. Cardio recovers with 6 h, so daily cardio stays fully useful.
func _test_recovery() -> void:
	var gs := _new_avatar("normal")
	gs.strength_recovery = 0.0
	gs.cardio_recovery = 0.0
	_steps(48.0)
	print("  48 h after a full strength session: %.1f%% recovered" % (gs.strength_recovery * 100.0))
	_check("strength is about 86% recovered 48 h after a session", absf(gs.strength_recovery - (1.0 - exp(-2.0))) < TOLERANCE)
	gs = _new_avatar("normal")
	gs.cardio_recovery = 0.0
	_steps(24.0)
	_check("cardio is fully recovered (over 98%) a day later", gs.cardio_recovery > 0.98)
	gs = _new_avatar("normal")
	gs.hours_awake = 6.0
	_play_activity("exercise", "strength", 0.75)
	_check("45 minutes of strength tire it fully (recovery 0)", gs.strength_recovery < 0.01)
	gs = _new_avatar("normal")
	_play_activity("exercise", "cardio", 1.0)
	_check("1 h of cardio uses half of the cardio recovery (fully tired after 120 min)", absf(gs.cardio_recovery - 0.5) < 0.01)


func _test_too_soon_and_beyond_capacity() -> void:
	var gs := _new_avatar("normal")
	_play_activity("exercise", "strength", 1.0)
	_check("a rested strength session is not too soon", not gs.strength_too_soon and is_zero_approx(gs.overreach))
	var effective_before: float = training.effective_minutes("strength")
	_play_activity("exercise", "strength", 1.0)
	_check("a second strength session right after is too soon and builds O", gs.strength_too_soon and gs.overreach > 0.0)
	# The sliding window keeps losing a little of its oldest hour, so the sum may go down; it
	# must not go up.
	_check("...and gives no effective minutes (user decision)", training.effective_minutes("strength") <= effective_before + TOLERANCE)

	gs = _new_avatar("normal")
	var capacity: float = training.capacity_min()
	_play_activity("exercise", "cardio", 1.0)
	var effective_1h: float = training.effective_minutes("cardio")
	_check("1 h of cardio is within the 96-minute capacity: no O", is_zero_approx(gs.overreach))
	_play_activity("exercise", "cardio", 1.0)
	var effective_2h: float = training.effective_minutes("cardio")
	var gained := effective_2h - effective_1h
	print("  capacity %.0f min: 2nd hour of cardio adds %.1f effective minutes (only %.0f min within capacity), O %.2f"
			% [capacity, gained, capacity - 60.0, gs.overreach])
	_check("minutes beyond the capacity give no benefit", gained <= (capacity - 60.0) + TOLERANCE)
	_check("...and build the overreaching load O", gs.overreach > 0.0 and is_equal_approx(gs.exercise_minutes_today, 120.0))
	var overreach_before: float = gs.overreach
	_steps(24.0 * 7.0)
	_check("O fades with rest (a week: under 10% of it is left)", gs.overreach < 0.1 * overreach_before)


## Milestone 10.5 (team review): a strength session that starts less than train.strength_min_gap_h
## (36 h) after the start of the previous one is too soon, even when the muscles have recovered
## past train.strength_ready (0.6, reached about 23 h after a full session).
func _test_minimum_gap() -> void:
	var gap: float = root.get_node("Config").get_float("train.strength_min_gap_h")
	var gs := _new_avatar("normal")
	_check("a new avatar's first strength session is never too soon by the gap", gs.hours_since_strength >= gap)
	_play_activity("exercise", "strength", 1.0)
	_steps(23.0)
	print("  24 h after the last start: recovery %.2f (ready at 0.60), %.1f h since that start (gap %.0f h)"
			% [gs.strength_recovery, gs.hours_since_strength, gap])
	_check("24 h later the muscles have recovered past 0.6", gs.strength_recovery >= 0.6)
	var effective_before: float = training.effective_minutes("strength")
	var overreach_before: float = gs.overreach
	_play_activity("exercise", "strength", 1.0)
	_check("...but a session 24 h after the last start is too soon (36 h gap)", gs.strength_too_soon)
	_check("...so it gives no effective minutes and builds O", training.effective_minutes("strength") <= effective_before + TOLERANCE
			and gs.overreach > overreach_before)
	gs = _new_avatar("normal")
	_play_activity("exercise", "strength", 1.0)
	_steps(47.0)
	_play_activity("exercise", "strength", 1.0)
	_check("a session 48 h after the last start is not too soon", not gs.strength_too_soon)


## A new avatar's window gives its starting fitness and strength as targets, so the levels
## stay put until the player does something different; with no exercise they fall slowly.
func _test_starting_window() -> void:
	for difficulty in ["easy", "normal", "hard"]:
		var gs := _new_avatar(difficulty)
		_check("%s: starting targets = starting fitness and strength" % difficulty,
				absf(training.fitness_target() - gs.fitness) < TOLERANCE and absf(training.strength_target() - gs.strength) < TOLERANCE)
	var gs := _new_avatar("normal")
	var start: float = gs.fitness
	_steps(1.0)
	_check("the first hour does not move fitness", absf(gs.fitness - start) < TOLERANCE)
	_steps(48.0)
	_check("with no exercise for 2 days fitness falls (the window empties)", gs.fitness < start)
	# Milestone 10.5: a longer window averages the minutes per day over it.
	var config: Node = root.get_node("Config")
	var hours: Variant = config._data["train"]["average_window_h"]["value"]
	config._data["train"]["average_window_h"]["value"] = 168
	gs = _new_avatar("normal")
	_check("a one-week window also gives the starting fitness and strength as targets",
			absf(training.fitness_target() - gs.fitness) < TOLERANCE and absf(training.strength_target() - gs.strength) < TOLERANCE)
	config._data["train"]["average_window_h"]["value"] = hours


## v1 'Predicted results': guideline plan vs 4 h of cardio a day vs strength twice a day; and
## strength every day (team review, Milestone 10.5).
func _test_plans() -> void:
	var guideline := _play_plan("guideline")
	var cardio_4h := _play_plan("cardio_4h")
	var strength_2x := _play_plan("strength_2x")
	var strength_daily := _play_plan("strength_daily")
	print("  after %d avatar days (v1: guideline fitness 0.83 strength 0.70; 4 h cardio 0.86 / 0.50; strength twice 0.66 / 0.34;" % DAYS
			+ " review: strength every day 0.44 with the 36 h gap)")
	for row in [["guideline", guideline], ["4 h cardio", cardio_4h], ["strength twice", strength_2x], ["strength daily", strength_daily]]:
		print("    %-15s fitness %.2f  strength %.2f  O %.2f" % [row[0], row[1]["fitness"], row[1]["strength"], row[1]["overreach"]])
	_check("strength every day: less strength than the guideline plan (36 h gap)", strength_daily["strength"] < guideline["strength"])
	_check("strength every day builds overreaching", strength_daily["overreach"] > 0.2)
	_check("the guideline plan raises fitness and strength (from 0.40)", guideline["fitness"] > 0.6 and guideline["strength"] > 0.55)
	_check("the guideline plan builds no overreaching", guideline["overreach"] < 0.05)
	_check("4 h of cardio a day: less strength than the guideline plan", cardio_4h["strength"] < guideline["strength"])
	_check("4 h of cardio a day builds overreaching", cardio_4h["overreach"] > 0.3)
	_check("strength twice a day: less strength than the guideline plan", strength_2x["strength"] < guideline["strength"])
	_check("strength twice a day: less fitness than the guideline plan", strength_2x["fitness"] < guideline["fitness"])
	_check("strength twice a day builds overreaching", strength_2x["overreach"] > 0.3)


## Plays DAYS avatar days of a plan (a boy of 10, Normal) and returns the levels at the end.
## Every day: healthy meals at 0, 4.5, 8 and 12 h awake, then 10.5 h of sleep.
## guideline: 1 h cardio every day, 1 h strength on 3 non-consecutive days a week.
## cardio_4h: 4 h cardio every day. strength_2x: 1 h cardio and 1 h strength twice every day.
## strength_daily: 1 h cardio and 1 h strength every day.
func _play_plan(plan: String) -> Dictionary:
	var gs := _new_avatar("normal")
	for day in DAYS:
		var events: Array = [[0.0, "eat", "healthy_meal"], [4.5, "eat", "healthy_meal"], [8.0, "eat", "healthy_meal"], [12.0, "eat", "healthy_meal"]]
		match plan:
			"guideline":
				events.append([1.0, "exercise", "cardio"])
				if day % 7 in [0, 2, 4]:
					events.append([2.5, "exercise", "strength"])
			"cardio_4h":
				for hour in [0.5, 1.5, 2.5, 3.5]:
					events.append([hour, "exercise", "cardio"])
			"strength_2x":
				events.append([1.0, "exercise", "cardio"])
				events.append([2.5, "exercise", "strength"])
				events.append([6.0, "exercise", "strength"])
			"strength_daily":
				events.append([1.0, "exercise", "cardio"])
				events.append([2.5, "exercise", "strength"])
		events.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		for event in events:
			_idle_until(event[0])
			_play_activity(event[1], event[2], 1.0)
		_sleep(SLEEP_HOURS)
	return {"fitness": gs.fitness, "strength": gs.strength, "overreach": gs.overreach}


## Plays an activity for this share of its duration (1 = to the end).
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


## Runs this many avatar hours of 5-minute steps directly (no activity).
func _steps(hours: float) -> void:
	var simulation: Node = root.get_node("Simulation")
	var step_hours: float = simulation.step_minutes() / 60.0
	for i in roundi(hours / step_hours):
		simulation._step(step_hours, false)


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
