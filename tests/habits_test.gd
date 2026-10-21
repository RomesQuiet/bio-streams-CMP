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
	_test_sleep_score(h)
	_test_screen_score(h)
	_test_old_entries_dropped(h)
	_test_real_play(h, gs, clock, activities, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## A log with known entries gives the expected four scores.
func _test_known_log(h: Node) -> void:
	h.reset()
	h.avatar_hours_total = 100.0
	# Last avatar day (started less than 24 h ago): 0.5 h cardio, 0.25 h strength, 3 h entertainment.
	h.add_entry("cardio", 90.0, 0.5)
	h.add_entry("strength", 95.0, 0.25)
	h.add_entry("entertainment", 80.0, 3.0)
	# Older: strength 2 days ago and 5 days ago, and a cardio hour 3 days ago (not in the last day).
	h.add_entry("strength", 52.0, 1.0)
	h.add_entry("strength", 4.0, 1.0)
	h.add_entry("cardio", 28.0, 1.0)
	var s: Dictionary = h.calculate_scores(9.0, "child")
	_check("sleep: 9 h is inside the child range", is_equal_approx(s["sleep"], 1.0))
	_check("activity: 45 min of cardio and strength / 60 = 0.75", absf(s["activity"] - 0.75) < TOLERANCE)
	# Strength days: today (95), 2 days ago (52) and 4 days ago (start 4.0 -> age 96 h) = 3 days / 3 = 1.
	_check("strength: 3 different days with strength / 3 = 1", absf(s["strength"] - 1.0) < TOLERANCE)
	_check("screens: 3 h of entertainment = 0.75", absf(s["screens"] - 0.75) < TOLERANCE)
	h.reset()
	h.avatar_hours_total = 100.0
	h.add_entry("strength", 99.0, 1.0)
	h.add_entry("strength", 98.0, 1.0)  # Same day: counts once.
	_check("strength: two sessions on one day count once (1/3)",
			absf(h.calculate_scores(9.0, "child")["strength"] - 1.0 / 3.0) < TOLERANCE)
	_check("activity: 2 h of exercise is at most 1", is_equal_approx(h.calculate_scores(9.0, "child")["activity"], 1.0))
	h.reset()
	_check("empty log: activity, strength 0 and screens 1", h.calculate_scores(9.0, "child")["activity"] == 0.0
			and h.calculate_scores(9.0, "child")["strength"] == 0.0 and h.calculate_scores(9.0, "child")["screens"] == 1.0)


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
	h.avatar_hours_total = 10.0
	h.add_entry("cardio", 10.0, 1.0)
	h.avatar_hours_total = 10.0 + 7.0 * 24.0 - 1.0
	h.add_entry("cardio", h.avatar_hours_total, 1.0)
	_check("an entry less than 7 avatar days old is kept", h.entries.size() == 2)
	h.avatar_hours_total += 2.0
	h.add_entry("cardio", h.avatar_hours_total, 1.0)
	_check("an entry older than 7 avatar days is dropped", h.entries.size() == 2)


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
	_check("sleep starts", activities.start("sleep", "sleep", 9.0))
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	_check("scores are calculated when the sleep ends", not h.scores.is_empty())
	_check("sleep score is 1 for 9 h", is_equal_approx(h.scores["sleep"], 1.0))
	_check("activity score matches the logged cardio", absf(h.scores["activity"] - cardio_hours * 60.0 / 60.0) < TOLERANCE)
	_check("strength score is 0 (no strength)", is_zero_approx(h.scores["strength"]))
	_check("screens score is 1 (1 h of entertainment)", is_equal_approx(h.scores["screens"], 1.0))
	_check("sleep is not logged as an exercise type", h.entries.size() == 2)

	# The log and scores are saved and loaded.
	var saved: Dictionary = h.to_dict()
	var before_gs: Dictionary = gs.to_dict()
	save_game.save_game()
	activities.reset()
	h.reset()
	_check("log was cleared before loading", h.entries.is_empty())
	_check("load finds the save", save_game.load_game())
	_check("log and scores restored", h.entries.size() == 2 and absf(h.avatar_hours_total - saved["avatar_hours_total"]) < TOLERANCE
			and absf(h.scores["activity"] - saved["scores"]["activity"]) < TOLERANCE)
	_check("game state still restored", before_gs["avatar_name"] == gs.avatar_name)

	# A nap of 1 h gives a low sleep score (any sleep counts).
	clock.wake_up()
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
