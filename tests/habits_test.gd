extends SceneTree
## Tests for the action log and avatar days (Milestone 3, Task 3; the habit scores were removed in Milestone 10). Run from the project folder:
##   Godot --headless --path . -s res://tests/habits_test.gd
## Uses a test save path, so the real save is never touched.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1

## Loaded at run time (it uses the autoloads).
var energy: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	energy = load("res://scripts/health/energy.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var h: Node = root.get_node("Habits")
	var gs: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	activities.reset()
	h.reset()
	gs.reset()
	clock.reset()

	_test_known_log(h)
	_test_old_entries_dropped(h)
	_test_real_play(h, gs, clock, activities, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## A known log over several scoring days returns the right totals per scoring day.
func _test_known_log(h: Node) -> void:
	h.reset()
	# Scoring day 0: strength 1 h, 9 h of sleep.
	h.add_entry("strength", 1.0)
	h.end_scoring_day(9.0)
	# Scoring day 1: nothing, a 0-hour day (the awake period ran out).
	h.end_scoring_day(0.0)
	# Scoring day 2: strength twice (counts as one day), 7 h of sleep.
	h.add_entry("strength", 0.5)
	h.add_entry("strength", 0.5)
	h.end_scoring_day(7.0)
	# Scoring day 3 (not closed yet): 0.5 h cardio, 0.25 h strength, 3 h of screens.
	h.add_entry("cardio", 0.5)
	h.add_entry("strength", 0.25)
	h.add_entry("screens", 3.0)
	_check("three scoring days were closed", h.days.size() == 3 and h.current_day == 3)
	_check("day 0: 9 h sleep, 60 activity min, 1 strength day", _totals_are(h.days[0], 9.0, 60.0, 1, 0.0))
	_check("day 1: 0 h sleep, nothing done, strength day 0 still counts", _totals_are(h.days[1], 0.0, 0.0, 1, 0.0))
	_check("day 2: 7 h sleep, 60 min, two sessions = one more strength day", _totals_are(h.days[2], 7.0, 60.0, 2, 0.0))
	h.end_scoring_day(9.0)
	var day3: Dictionary = h.days[-1]
	_check("day 3: 9 h sleep, 45 min, 3 strength days in the last 7, 3 h entertainment", _totals_are(day3, 9.0, 45.0, 3, 3.0))
	var per_hour := func(mety: float) -> float:
		var gs: Node = root.get_node("GameState")
		return energy.kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety)
	var expected_kcal: float = 0.5 * per_hour.call(7.0) + 0.25 * per_hour.call(5.0) + 3.0 * per_hour.call(1.3) + 9.0 * per_hour.call(0.95)
	_check("day 3: calories = BMR / 24 x METy x hours (0.5 h cardio, 0.25 h strength, 3 h screens, 9 h sleep)", absf(day3["kcal"] - expected_kcal) < TOLERANCE)
	var entry: Dictionary = h.entries.filter(func(e: Dictionary) -> bool: return e["type"] == "cardio")[0]
	_check("an entry has its intensity and calories", entry["intensity"] == "moderate_vigorous" and absf(entry["kcal"] - 0.5 * per_hour.call(7.0)) < TOLERANCE)


## Totals of a closed scoring day, compared with expected values.
func _totals_are(totals: Dictionary, sleep_hours: float, activity_minutes: float, strength_days: int,
		entertainment_hours: float) -> bool:
	var ok: bool = absf(totals["sleep_hours"] - sleep_hours) < TOLERANCE and absf(totals["activity_minutes"] - activity_minutes) < TOLERANCE \
			and totals["strength_days"] == strength_days and absf(totals["entertainment_hours"] - entertainment_hours) < TOLERANCE
	if not ok:
		print("  totals: %s" % totals)
	return ok


func _test_old_entries_dropped(h: Node) -> void:
	h.reset()
	h.add_entry("strength", 1.0)
	for day in 6:
		h.end_scoring_day(9.0)
	_check("strength 6 scoring days ago is still kept and counted", h.entries.any(func(e: Dictionary) -> bool: return e["type"] == "strength")
			and h.day_totals(h.current_day)["strength_days"] == 1)
	h.end_scoring_day(9.0)
	_check("after 7 scoring days the strength entry is dropped", not h.entries.any(func(e: Dictionary) -> bool: return e["type"] == "strength")
			and h.day_totals(h.current_day)["strength_days"] == 0)
	_check("only the last 7 closed scoring days are kept", h.days.size() == 7)


## Real play: exercise logs the hours done (Stop counts only the time done), and an avatar
## day closes when a sleep ends: a normal sleep, a nap, and the 0-hour rule.
func _test_real_play(h: Node, gs: Node, clock: Node, activities: Node, save_game: Node) -> void:
	h.reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "teenager", "male", "normal")
	clock.set_paused(false)
	clock.debug_speed = 600.0
	_check("no closed day before the first sleep", h.days.is_empty())

	_check("cardio starts", activities.start("exercise", "cardio"))
	while activities.elapsed_hours < 0.5:
		clock._process(STEP_SECONDS)
	var done_before_stop: float = activities.elapsed_hours
	activities.stop()
	_check("one entry logged", h.entries.size() == 1)
	_check("it is a cardio entry", h.entries[0]["type"] == "cardio")
	_check("only the time done is logged", absf(h.entries[0]["hours"] - done_before_stop) < TOLERANCE
			and h.entries[0]["hours"] >= 0.5 and h.entries[0]["hours"] < 1.0)
	_check("start time is logged", h.entries[0].has("start_minute") and h.entries[0]["day"] == clock.day_number)
	var cardio_hours: float = h.entries[0]["hours"]

	_check("entertainment starts", activities.start("entertainment", "screens"))
	while activities.is_running():
		clock._process(STEP_SECONDS)
	_check("two entries logged", h.entries.size() == 2)

	# A normal sleep of 9 h (teenager range 8 to 10 h).
	# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
	gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	_check("sleep starts", activities.start("sleep", "sleep", 9.0))
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	var totals: Dictionary = h.days[-1] if not h.days.is_empty() else {}
	_check("the day closes when the sleep ends, with its totals", not totals.is_empty()
			and absf(totals["sleep_hours"] - 9.0) < 0.1 and absf(totals["activity_minutes"] - cardio_hours * 60.0) < 0.01
			and totals["strength_days"] == 0 and absf(totals["screen_hours"] - 1.0) < 0.01)
	_check("the sleep is logged too", h.entries.size() == 3 and h.entries[-1]["type"] == "sleep"
			and absf(h.entries[-1]["hours"] - 9.0) < 0.1)
	_check("a new scoring day starts after the sleep", h.current_day == 1 and h.days.size() == 1)

	# The log and the days are saved and loaded.
	var saved: Dictionary = h.to_dict()
	var before_gs: Dictionary = gs.to_dict()
	save_game.save_game()
	activities.reset()
	h.reset()
	_check("log was cleared before loading", h.entries.is_empty())
	_check("load finds the save", save_game.load_game())
	_check("log and days restored", h.entries.size() == 3 and h.current_day == 1 and h.days.size() == 1 and absf(h.avatar_hours_total - saved["avatar_hours_total"]) < TOLERANCE)
	_check("game state still restored", before_gs["avatar_name"] == gs.avatar_name)

	# A nap of 1 h closes a day too (any sleep counts).
	clock.wake_up()
	# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
	gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	_check("nap starts", activities.start("sleep", "sleep", 1.0))
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	_check("a 1 h nap closes a day with 1 h of sleep", h.days.size() == 2 and absf(h.days[-1]["sleep_hours"] - 1.0) < 0.1)
	_check("the nap hours are kept", absf(gs.last_sleep_hours - 1.0) < 0.1)

	# The 0-hour rule: the awake period runs out without sleep.
	clock.wake_up()
	var days_before: int = h.days.size()
	var day: int = clock.day_number
	while clock.day_number == day:
		clock._process(STEP_SECONDS)
	_check("a day closes when the awake period runs out without sleep", h.days.size() == days_before + 1)
	_check("it counts as 0 h slept", is_zero_approx(h.days[-1]["sleep_hours"]) and is_zero_approx(gs.last_sleep_hours))


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
