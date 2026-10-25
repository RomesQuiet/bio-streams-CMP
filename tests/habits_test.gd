extends SceneTree
## Tests for the action log and habit scores (Milestone 3, Task 3). Run from the project folder:
##   Godot --headless --path . -s res://tests/habits_test.gd
## Uses a test save path, so the real save is never touched.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1

var _failures := 0


func _process(_delta: float) -> bool:
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
	_test_score_limits(h)
	_test_sleep_score(h)
	_test_screen_score(h)
	_test_old_entries_dropped(h)
	_test_real_play(h, gs, clock, activities, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## A known log over several scoring days returns the right totals per scoring day,
## and the right four scores.
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
	# Scoring day 3 (not closed yet): 0.5 h cardio, 0.25 h strength, 3 h entertainment.
	h.add_entry("cardio", 0.5)
	h.add_entry("strength", 0.25)
	h.add_entry("entertainment", 3.0)
	_check("three scoring days were closed", h.days.size() == 3 and h.current_day == 3)
	_check("day 0: 9 h sleep, 60 activity min, 1 strength day", _totals_are(h.days[0], 9.0, 60.0, 1, 0.0))
	_check("day 1: 0 h sleep, nothing done, strength day 0 still counts", _totals_are(h.days[1], 0.0, 0.0, 1, 0.0))
	_check("day 2: 7 h sleep, 60 min, two sessions = one more strength day", _totals_are(h.days[2], 7.0, 60.0, 2, 0.0))
	h.end_scoring_day(9.0)
	var day3: Dictionary = h.days[-1]
	_check("day 3: 9 h sleep, 45 min, 3 strength days in the last 7, 3 h entertainment", _totals_are(day3, 9.0, 45.0, 3, 3.0))
	_check("day 3: calories = 0.5 h x 300 + 0.25 h x 200 = 200 kcal", is_equal_approx(day3["kcal"], 200.0))
	var s: Dictionary = h.scores
	_check("sleep: 9 h is inside the child range", is_equal_approx(s["sleep"], 1.0))
	_check("activity: 45 min / 60 = 0.75", absf(s["activity"] - 0.75) < TOLERANCE)
	_check("strength: 3 strength days / 3 = 1", absf(s["strength"] - 1.0) < TOLERANCE)
	_check("screens: 3 h of entertainment = 0.75", absf(s["screens"] - 0.75) < TOLERANCE)
	var entry: Dictionary = h.entries.filter(func(e: Dictionary) -> bool: return e["type"] == "cardio")[0]
	_check("an entry has its intensity and calories", entry["intensity"] == "moderate_vigorous" and is_equal_approx(entry["kcal"], 150.0))
	h.reset()
	h.end_scoring_day(9.0)
	_check("empty day: activity 0, strength 0, screens 1", h.scores["activity"] == 0.0
			and h.scores["strength"] == 0.0 and h.scores["screens"] == 1.0)


## Totals of a closed scoring day, compared with expected values.
func _totals_are(totals: Dictionary, sleep_hours: float, activity_minutes: float, strength_days: int,
		entertainment_hours: float) -> bool:
	var ok: bool = absf(totals["sleep_hours"] - sleep_hours) < TOLERANCE and absf(totals["activity_minutes"] - activity_minutes) < TOLERANCE \
			and totals["strength_days"] == strength_days and absf(totals["entertainment_hours"] - entertainment_hours) < TOLERANCE
	if not ok:
		print("  totals: %s" % totals)
	return ok


## Milestone 4 Task 3: each score at its limits, with the config values.
func _test_score_limits(h: Node) -> void:
	# Sleep, teenager (range 8 to 10 h): 0 at 4 h, 1 at 8 h and 9 h, 0.8 at 12 h (2 h above x 0.1).
	_check("teenager sleep 4 h gives 0", is_zero_approx(h.sleep_score(4.0, "teenager")))
	_check("teenager sleep 8 h gives 1", is_equal_approx(h.sleep_score(8.0, "teenager"), 1.0))
	_check("teenager sleep 9 h gives 1", is_equal_approx(h.sleep_score(9.0, "teenager"), 1.0))
	_check("teenager sleep 12 h gives 0.8", absf(h.sleep_score(12.0, "teenager") - 0.8) < TOLERANCE)
	_check("teenager sleep 10 h (upper limit) gives 1", is_equal_approx(h.sleep_score(10.0, "teenager"), 1.0))
	_check("child sleep 12 h (upper limit) gives 1, 13 h gives 0.9", is_equal_approx(h.sleep_score(12.0, "child"), 1.0)
			and absf(h.sleep_score(13.0, "child") - 0.9) < TOLERANCE)
	# Activity: minutes / 60, at most 1.
	_check("activity 0 min gives 0", is_zero_approx(h.activity_score(0.0)))
	_check("activity 30 min gives 0.5", absf(h.activity_score(30.0) - 0.5) < TOLERANCE)
	_check("activity 60 min gives 1", is_equal_approx(h.activity_score(60.0), 1.0))
	_check("activity 120 min still gives 1", is_equal_approx(h.activity_score(120.0), 1.0))
	# Strength: days in the last 7 / 3, at most 1.
	_check("strength 0 days gives 0", is_zero_approx(h.strength_score(0)))
	_check("strength 1 day gives 1/3", absf(h.strength_score(1) - 1.0 / 3.0) < TOLERANCE)
	_check("strength 3 days gives 1", is_equal_approx(h.strength_score(3), 1.0))
	_check("strength 7 days still gives 1", is_equal_approx(h.strength_score(7), 1.0))
	# Screens: 1 up to 2 h, linear to 0 at 6 h.
	_check("screens 0 h gives 1", is_equal_approx(h.screen_score(0.0), 1.0))
	_check("screens 2 h gives 1", is_equal_approx(h.screen_score(2.0), 1.0))
	_check("screens 6 h gives 0, 8 h gives 0", is_zero_approx(h.screen_score(6.0)) and is_zero_approx(h.screen_score(8.0)))
	# Enjoyment: entertainment hours / 1, at most 1.
	_check("enjoyment 0 h gives 0", is_zero_approx(h.enjoyment_score(0.0)))
	_check("enjoyment 0.5 h gives 0.5", absf(h.enjoyment_score(0.5) - 0.5) < TOLERANCE)
	_check("enjoyment 1 h gives 1", is_equal_approx(h.enjoyment_score(1.0), 1.0))
	_check("enjoyment 3 h still gives 1", is_equal_approx(h.enjoyment_score(3.0), 1.0))
	# All five scores come out of a closed scoring day.
	h.reset()
	h.add_entry("entertainment", 0.5)
	h.end_scoring_day(9.0)
	_check("a scoring day gives five scores, with enjoyment 0.5 for 30 min of entertainment",
			h.scores.size() == 5 and absf(h.scores["enjoyment"] - 0.5) < TOLERANCE)


func _test_sleep_score(h: Node) -> void:
	_check("child 9 h gives 1", is_equal_approx(h.sleep_score(9.0, "child"), 1.0))
	_check("child 12 h gives 1", is_equal_approx(h.sleep_score(12.0, "child"), 1.0))
	_check("child 4 h gives 0", is_zero_approx(h.sleep_score(4.0, "child")))
	_check("child 0 h gives 0", is_zero_approx(h.sleep_score(0.0, "child")))
	_check("child 6.5 h is halfway between 4 h and 9 h (0.5)", absf(h.sleep_score(6.5, "child") - 0.5) < TOLERANCE)
	_check("teenager 8 h gives 1", is_equal_approx(h.sleep_score(8.0, "teenager"), 1.0))
	_check("teenager 6 h gives 0.5", absf(h.sleep_score(6.0, "teenager") - 0.5) < TOLERANCE)
	var above: float = h.sleep_score(12.0, "teenager")
	_check("above the range falls, but slowly", above < 1.0 and above > h.sleep_score(7.0, "teenager"))


func _test_screen_score(h: Node) -> void:
	_check("2 h of screens gives 1", is_equal_approx(h.screen_score(2.0), 1.0))
	_check("4 h gives 0.5", absf(h.screen_score(4.0) - 0.5) < TOLERANCE)
	_check("6 h or more gives 0", is_zero_approx(h.screen_score(6.0)) and is_zero_approx(h.screen_score(9.0)))


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


## Real play: exercise logs the hours done (Stop counts only the time done), and the
## scores come when a sleep ends: a normal sleep, a nap, and the 0-hour rule.
func _test_real_play(h: Node, gs: Node, clock: Node, activities: Node, save_game: Node) -> void:
	h.reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "teenager", "male", "normal")
	clock.set_paused(false)
	clock.debug_speed = 600.0
	_check("no scores before the first sleep", h.scores.is_empty())

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

	_check("entertainment starts", activities.start("entertainment", "entertainment"))
	while activities.is_running():
		clock._process(STEP_SECONDS)
	_check("two entries logged", h.entries.size() == 2)

	# A normal sleep of 9 h (teenager range 8 to 10 h).
	# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
	gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	_check("sleep starts", activities.start("sleep", "sleep", 9.0))
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	_check("scores are calculated when the sleep ends", not h.scores.is_empty())
	_check("sleep score is 1 for 9 h", is_equal_approx(h.scores["sleep"], 1.0))
	_check("activity score matches the logged cardio", absf(h.scores["activity"] - cardio_hours * 60.0 / 60.0) < TOLERANCE)
	_check("strength score is 0 (no strength)", is_zero_approx(h.scores["strength"]))
	_check("screens score is 1 (1 h of entertainment)", is_equal_approx(h.scores["screens"], 1.0))
	_check("the sleep is logged too", h.entries.size() == 3 and h.entries[-1]["type"] == "sleep"
			and absf(h.entries[-1]["hours"] - 9.0) < 0.1)
	_check("a new scoring day starts after the sleep", h.current_day == 1 and h.days.size() == 1)

	# The log and scores are saved and loaded.
	var saved: Dictionary = h.to_dict()
	var before_gs: Dictionary = gs.to_dict()
	save_game.save_game()
	activities.reset()
	h.reset()
	_check("log was cleared before loading", h.entries.is_empty())
	_check("load finds the save", save_game.load_game())
	_check("log and scores restored", h.entries.size() == 3 and h.current_day == 1 and h.days.size() == 1 and absf(h.avatar_hours_total - saved["avatar_hours_total"]) < TOLERANCE
			and absf(h.scores["activity"] - saved["scores"]["activity"]) < TOLERANCE)
	_check("game state still restored", before_gs["avatar_name"] == gs.avatar_name)

	# A nap of 1 h gives a low sleep score (any sleep counts).
	clock.wake_up()
	# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
	gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	_check("nap starts", activities.start("sleep", "sleep", 1.0))
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	_check("a 1 h nap gives a low sleep score", h.scores["sleep"] < 0.5)
	_check("the nap hours are kept", absf(h.last_sleep_hours - 1.0) < 0.1)

	# The 0-hour rule: the awake period runs out without sleep.
	clock.wake_up()
	h.scores = {}
	var day: int = clock.day_number
	while clock.day_number == day:
		clock._process(STEP_SECONDS)
	_check("scores are calculated when the day runs out without sleep", not h.scores.is_empty())
	_check("the sleep score is 0 (0 h slept)", is_zero_approx(h.scores["sleep"]) and is_zero_approx(h.last_sleep_hours))
	h.print_scores()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
