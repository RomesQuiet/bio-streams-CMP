extends SceneTree
## Tests for the cardio minigame (Milestone 12, Tasks 2 to 4). Run from the project folder:
##   Godot --headless --path . -s res://tests/minigame_test.gd
## The avatar's pace and how long it can run, then a session played tap by tap: rhythm, steps,
## the Breath bar, walking and waiting, and how a session reaches the health system. Time is
## passed in by the test, and the panel on the main screen. Nothing is saved.

const TOLERANCE := 0.001

## Loaded at run time: the script uses the autoloads, which do not exist yet when this test
## script is compiled.
var pace: GDScript
var load_model: GDScript
var training: GDScript
var energy: GDScript
var gs: Node
var clock: Node
var activities: Node
var minigame: Node
var _failures := 0


func _process(_delta: float) -> bool:
	pace = load("res://scripts/health/cardio_pace.gd")
	load_model = load("res://scripts/health/strength_load.gd")
	training = load("res://scripts/health/training.gd")
	energy = load("res://scripts/health/energy.gd")
	gs = root.get_node("GameState")
	clock = root.get_node("Clock")
	activities = root.get_node("Activities")
	minigame = root.get_node("Minigame")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	activities.reset()
	gs.reset()
	clock.reset()

	_test_pace()
	_test_strength_load()
	_test_when_it_runs()
	_test_score()
	_test_breath()
	_test_waiting()
	_test_saving()
	_test_strength_set()
	_test_strength_technique()
	_test_strength_tiring()
	_test_strength_more_sets()
	_test_strength_waiting()
	_test_strength_saving()
	_test_strength_health()
	_test_no_tap_counts_nothing()
	_test_played_minutes_count()
	_test_score_reaches_training()
	_test_walking_energy()
	minigame.detach()
	_test_screen()

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Task 2: capacity comes from fitness, weight and sleepiness. Each one on its own moves it.
func _test_pace() -> void:
	gs.start_new_avatar("Test", "child", "male", "normal")
	# Normal: fitness 0.4, z +1.2, 4 h of debt (tiredness 0.5).
	_check("Normal capacity = 0.4 x (1 - 0.16 x 1.2) x (1 - 0.3 x 0.5)", absf(pace.capacity() - 0.4 * 0.808 * 0.85) < TOLERANCE)
	print("difficulty  capacity  cadence interval  walk interval  run minutes")
	for id in ["easy", "normal", "hard", "very_hard"]:
		gs.start_new_avatar("Test", "child", "male", id)
		print("%-10s  %.3f     %.2f s            %.2f s          %.0f" % [id, pace.capacity(), pace.run_interval(),
				pace.walk_interval(), pace.run_minutes()])
	gs.start_new_avatar("Test", "child", "male", "normal")
	_set_body(0.8, 0.0, 0.0)
	var fit: float = pace.capacity()
	var fit_interval: float = pace.run_interval()
	var fit_minutes: float = pace.run_minutes()
	_check("no weight or sleep cut: capacity = fitness", absf(fit - 0.8) < TOLERANCE)
	_set_body(0.4, 0.0, 0.0)
	_check("less fit: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)
	_set_body(0.8, 2.0, 0.0)
	_check("obesity (z +2): capacity x 0.68, as in the study", absf(pace.capacity() - 0.8 * 0.68) < TOLERANCE)
	_check("heavier: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)
	_set_body(0.8, -1.5, 0.0)
	_check("below z 0 weight does not change capacity", absf(pace.capacity() - 0.8) < TOLERANCE)
	_set_body(0.8, 10.0, 0.0)
	_check("the weight term stops at its floor", absf(pace.capacity() - 0.8 * 0.4) < TOLERANCE)
	_set_body(0.8, 0.0, 8.0)
	_check("sleepier: slower pace and less time", pace.run_interval() > fit_interval and pace.run_minutes() < fit_minutes)

	# The cadences of CADENCE-kids: one tap is two steps.
	_set_body(0.0, 0.0, 0.0)
	_check("capacity 0: the child's moderate threshold, 115 steps/min", absf(pace.run_interval() - 120.0 / 115.0) < TOLERANCE)
	_check("capacity 0: the Breath bar lasts 10 avatar minutes", absf(pace.run_minutes() - 10.0) < TOLERANCE)
	_set_body(1.0, 0.0, 0.0)
	_check("capacity 1: the child's vigorous threshold, 130 steps/min", absf(pace.run_interval() - 120.0 / 130.0) < TOLERANCE)
	_check("capacity 1: 120 avatar minutes, the v1 tiring time", is_equal_approx(pace.run_minutes(), root.get_node("Config").get_float("train.cardio_tire_min")))
	_check("walking is slower than the slowest running", pace.walk_interval() > 120.0 / 115.0)
	gs.age_group = "teenager"
	_set_body(0.0, 0.0, 0.0)
	_check("a teenager: moderate threshold 110 steps/min", absf(pace.run_interval() - 120.0 / 110.0) < TOLERANCE)
	_set_body(1.0, 0.0, 0.0)
	_check("a teenager: vigorous threshold 125 steps/min", absf(pace.run_interval() - 120.0 / 125.0) < TOLERANCE)
	gs.age_group = "child"


## Milestone 13, Task 1: repetitions and sets come from strength, weight and sleepiness.
func _test_strength_load() -> void:
	print("difficulty  capacity  reps  sets")
	for id in ["easy", "normal", "hard", "very_hard"]:
		gs.start_new_avatar("Test", "child", "male", id)
		print("%-10s  %.3f     %d     %d" % [id, load_model.capacity(), load_model.reps_per_set(), load_model.sets_goal()])
	gs.start_new_avatar("Test", "child", "male", "normal")
	_check("Normal capacity = 0.4 x (1 - 0.12 x 1.2) x (1 - 0.3 x 0.5)", absf(load_model.capacity() - 0.4 * 0.856 * 0.85) < TOLERANCE)
	_set_strength(1.0, 0.0, 0.0)
	_check("the strongest avatar: 12 repetitions and 4 sets (AAP)", load_model.reps_per_set() == 12 and load_model.sets_goal() == 4)
	_set_strength(0.0, 0.0, 0.0)
	_check("the weakest avatar: 8 repetitions and 1 set (AAP)", load_model.reps_per_set() == 8 and load_model.sets_goal() == 1)
	_set_strength(0.8, 0.0, 0.0)
	var strong: float = load_model.capacity()
	_check("no weight or sleep cut: capacity = strength", absf(strong - 0.8) < TOLERANCE)
	_set_strength(0.8, 2.0, 0.0)
	_check("obesity (z +2): capacity x 0.76", absf(load_model.capacity() - 0.8 * 0.76) < TOLERANCE)
	_set_strength(0.8, 10.0, 0.0)
	_check("the weight term stops at its floor", absf(load_model.capacity() - 0.8 * 0.4) < TOLERANCE)
	_set_strength(0.8, -1.5, 0.0)
	_check("below z 0 weight does not change capacity", absf(load_model.capacity() - 0.8) < TOLERANCE)
	_set_strength(0.8, 0.0, 8.0)
	_check("sleepier: less capacity", load_model.capacity() < strong)


func _set_strength(strength: float, z: float, debt: float) -> void:
	_set_body(gs.fitness, z, debt)
	gs.strength = strength


## Task 3: a session needs a player, a minigame on the option and normal speed.
func _test_when_it_runs() -> void:
	_new_avatar("normal")
	activities.start("exercise", "cardio")
	_check("no player (the scenario tests): no session, and the fixed score", not minigame.running and is_equal_approx(minigame.score(), 1.0))
	activities.stop()
	minigame.attach()
	activities.start("entertainment", "football")
	_check("football has no minigame (decision 29)", not minigame.running)
	activities.stop()
	clock.debug_speed = 60.0
	activities.start("exercise", "cardio")
	_check("no session at debug speed", not minigame.running)
	activities.stop()
	clock.debug_speed = 1.0
	activities.start("exercise", "strength")
	_check("strength starts a strength session", minigame.running and minigame.kind == "strength" and minigame.is_waiting())
	activities.stop()
	_check("the session ends with its kind", minigame.kind == "")
	activities.start("exercise", "cardio")
	_check("cardio starts a session, waiting for the first tap", minigame.running and minigame.is_waiting())
	activities.stop()
	_check("the session ends with the activity", not minigame.running and not minigame.is_waiting())
	activities.start("exercise", "cardio")
	clock.debug_speed = 60.0
	minigame._process(0.1)
	_check("turning on the debug speed ends the session, the activity goes on", not minigame.running and activities.is_running())
	clock.debug_speed = 1.0
	activities.stop()
	minigame.detach()
	activities.start("exercise", "cardio")
	_check("without the main screen no session starts", not minigame.running)
	activities.stop()


## Task 3: both rhythm and pace count, and the score follows the player (decisions 20 and 22).
func _test_score() -> void:
	# A long session with a fit avatar: the Breath bar is refilled so it never walks here.
	_new_avatar("easy")
	minigame.attach()
	activities.start("exercise", "cardio", 4.0)
	minigame.tap()
	var interval: float = minigame.interval()
	_play(12, interval)
	_check("every tap on the beat: score 1", absf(minigame.score() - 1.0) < TOLERANCE)
	_check("every stride counts", minigame.strides == 13)
	_check("one tap is two steps", minigame.steps() == 26)
	_check("the steps goal is one stride per interval for the whole session", absf(minigame.steps_goal()
			- 2.0 * clock.avatar_hours_to_real_seconds(4.0, false) / pace.run_interval()) <= 1.0)
	_play(40, interval * 1.5)
	_check("too slow: rhythm falls to 0 and pace to 2/3", minigame.rhythm < 0.05 and absf(minigame.pace - 1.0 / 1.5) < 0.03)
	_check("...so the score is low", minigame.score() < 0.4)
	minigame.reserve = 1.0
	_play(40, interval)
	_check("back on the beat the score recovers", minigame.score() > 0.95)
	minigame.reserve = 1.0
	_play(40, interval * 0.6)
	_check("too fast: pace stays 1, rhythm falls to 0", minigame.rhythm < 0.05 and minigame.pace > 0.99)
	_check("...so the score is about half", absf(minigame.score() - 0.5) < 0.05)
	minigame.reserve = 1.0
	var strides_before: int = minigame.strides
	_play(1, interval)
	minigame.tap()
	_check("a tap before the minimum gap is not a stride", minigame.strides == strides_before + 1 and not minigame.last_on_beat)
	var rhythm_before: float = minigame.rhythm
	_play(5, interval)
	_check("on the beat again, rhythm rises", minigame.rhythm > rhythm_before)
	clock.set_paused(true)
	strides_before = minigame.strides
	_pass_time(interval)
	minigame.tap()
	_check("while paused a tap does nothing", minigame.strides == strides_before)
	clock.set_paused(false)
	activities.stop()


## Task 3: the Breath bar runs down, the avatar walks, and it can run again (decision 26).
func _test_breath() -> void:
	_start_session("very_hard")
	var seconds: float = clock.avatar_hours_to_real_seconds(pace.run_minutes() / 60.0, false)
	_play(int(seconds * 0.5 / minigame.interval()), minigame.interval())
	_check("half way through its time the Breath bar is about half", absf(minigame.reserve - 0.5) < 0.1 and not minigame.walking)
	var left: int = ceili(seconds * 0.6 / minigame.interval())
	_play(left, minigame.interval())
	_check("at 0 the avatar walks", minigame.walking and minigame.reserve < 0.2)
	_check("walking has its own slower beat", absf(minigame.interval() - pace.walk_interval()) < TOLERANCE)
	var walking_score: float = minigame.pace
	var strides_to_refill := ceili(clock.avatar_hours_to_real_seconds(10.0 / 60.0, false) / pace.walk_interval())
	_play(strides_to_refill - 2, pace.walk_interval())
	_check("walking refills the bar", minigame.walking and minigame.reserve > 0.3)
	_check("walking lowers the pace part of the score", walking_score <= 1.0 and minigame.pace < 0.95)
	_play(3, pace.walk_interval())
	_check("at half the bar it runs again", not minigame.walking)
	activities.stop()

	_start_session("easy")
	var slow_seconds: float = clock.avatar_hours_to_real_seconds(pace.run_minutes() / 60.0, false)
	_check("a fit avatar lasts much longer", slow_seconds > seconds * 5.0)
	_play(30, pace.run_interval())
	var on_pace: float = 1.0 - minigame.reserve
	activities.stop()
	_start_session("easy")
	_play(50, pace.run_interval() * 0.6)
	_check("running faster than the pace tires faster", (1.0 - minigame.reserve) > on_pace)
	activities.stop()

	_start_session("normal")
	var full: float = minigame.reserve
	gs.cardio_recovery = 0.4
	activities.stop()
	activities.start("exercise", "cardio")
	_check("a session right after another starts tired", absf(minigame.reserve - 0.4) < TOLERANCE and full > 0.9)
	activities.stop()


## Task 3: no tap: the avatar stands still, and after the wait the activity ends (decision 28).
func _test_waiting() -> void:
	_start_session("normal", false)
	var gave_up := [false]
	minigame.gave_up.connect(func() -> void: gave_up[0] = true)
	_pass_time(19.5)
	_check("the avatar waits for the first tap for almost 20 s", activities.is_running() and minigame.is_waiting())
	_pass_time(1.0)
	_check("after 20 s the activity ends", not activities.is_running() and not minigame.running and gave_up[0])

	_start_session("normal")
	_play(5, minigame.interval())
	_check("tapping: not waiting", not minigame.is_waiting())
	_pass_time(3.1)
	_check("3 s without a tap: it stands still", minigame.is_waiting() and activities.is_running())
	var breath_before: float = minigame.reserve
	_pass_time(10.0)
	_check("the bar does not change while it waits", is_equal_approx(minigame.reserve, breath_before))
	var strides_before: int = minigame.strides
	minigame.tap()
	_check("a tap starts it again", not minigame.is_waiting() and minigame.strides == strides_before + 1)
	_pass_time(0.5)
	_pass_time(3.0)
	_pass_time(19.0)
	_check("the wait starts again each time", activities.is_running())
	_pass_time(2.0)
	_check("...and it ends after 20 s", not activities.is_running())


## Task 3: a session survives a reload in the middle of the activity.
func _test_saving() -> void:
	var save_game: Node = root.get_node("SaveGame")
	_start_session("very_hard")
	_play(30, minigame.interval())
	var saved: Dictionary = minigame.to_dict()
	var strides: int = minigame.strides
	var breath: float = minigame.reserve
	save_game.save_game()
	activities.reset()
	minigame.reset()
	_check("reset clears the session", not minigame.running and minigame.strides == 0)
	_check("the save loads", save_game.load_game())
	minigame.detach()
	minigame.attach()
	_check("the session goes on after a reload, waiting for a tap", minigame.running and minigame.is_waiting())
	_check("with its strides and Breath bar", minigame.strides == strides and is_equal_approx(minigame.reserve, breath))
	_check("to_dict holds them", int(saved["strides"]) == strides)
	activities.stop()
	minigame.detach()
	save_game.delete_save()


## Milestone 13, Task 2: Down then Up is one repetition; a full set is followed by a rest.
func _test_strength_set() -> void:
	_start_strength("normal")
	_check("the session starts at set 1, waiting for the first press", minigame.is_waiting() and minigame.sets_started == 1)
	_check("the avatar's repetitions and sets", minigame.set_reps == 9 and minigame.sets_goal == 2)
	_check("the Muscle bar starts rested", absf(minigame.reserve - gs.strength_recovery) < TOLERANCE)
	minigame.press(false)
	_check("Up first does not start it", minigame.is_waiting())
	minigame.press(true)
	_check("Down starts it", not minigame.is_waiting() and not minigame.next_down)
	_pass_time(1.0)
	minigame.press(false)
	_check("Up finishes one repetition", minigame.reps_in_set == 1 and minigame.next_down)
	_pass_time(1.0)
	minigame.press(true)
	for i in 8:
		_repetition(1.0)
	_check("a full set: the avatar rests", minigame.resting and minigame.strides == 9)
	_check("controlled, every repetition done: score 1", absf(minigame.score() - 1.0) < TOLERANCE)
	_check("the set leaves some reserve: no training to failure", absf(minigame.reserve - 0.2) < 0.02)
	minigame.press(true)
	_check("a press does nothing during the rest", minigame.reps_in_set == 9 and minigame.next_down)
	_pass_time(2.0)
	_check("the rest refills the bar little by little", minigame.reserve > 0.3 and minigame.reserve < 0.5)
	_pass_time(4.1)
	_check("after the rest the next set starts", not minigame.resting and minigame.sets_started == 2 and minigame.reps_in_set == 0)
	_check("the bar has partly refilled", absf(minigame.reserve - 0.8) < 0.02)
	activities.stop()

	_start_strength("normal")
	minigame.press(true)
	_play_set(1.0)
	activities.stop()
	_check("Stop during a rest ends the rest too", not minigame.resting and not minigame.running)


## Milestone 13, Task 2: rushing, the wrong button and going too slowly are poor technique.
func _test_strength_technique() -> void:
	_start_strength("normal")
	minigame.press(true)
	for i in 4:
		_repetition(1.5)
	_check("too slow: technique falls", minigame.rhythm < 0.5 and not minigame.last_on_beat)
	_check("...but the repetitions count", minigame.strides == 4)
	activities.stop()

	_start_strength("normal")
	minigame.press(true)
	_pass_time(1.0)
	minigame.press(true)
	_check("the wrong button does not move the avatar", not minigame.next_down and not minigame.last_on_beat)
	_check("...and is poor technique", minigame.rhythm < 1.0)
	activities.stop()

	_start_strength("normal")
	minigame.press(true)
	for i in 3:
		_repetition(1.0)
	var steady: float = 1.0 - minigame.reserve
	activities.stop()
	_start_strength("normal")
	minigame.press(true)
	for i in 3:
		_repetition(0.5)
	_check("rushing is poor technique", minigame.rhythm < 0.5)
	_check("rushing tires the muscles faster", (1.0 - minigame.reserve) > steady * 1.5)
	activities.stop()


## Milestone 13, Task 2: tired muscles end a set early (decision 34), and it lowers the score.
func _test_strength_tiring() -> void:
	_start_strength("normal")
	gs.strength_recovery = 0.4
	activities.stop()
	activities.start("exercise", "strength")
	_check("a session soon after another starts tired", absf(minigame.reserve - 0.4) < TOLERANCE)
	minigame.press(true)
	_play_set(1.0)
	_check("the avatar stops the set early and rests", minigame.resting and minigame.reps_in_set < minigame.set_reps)
	_check("repetitions not done lower the pace part", minigame.pace < 1.0 and minigame.score() < 1.0)
	activities.stop()

	_start_strength("normal")
	minigame.press(true)
	_play_set(0.5)
	_check("rushing a whole set ends it early", minigame.resting and minigame.reps_in_set < minigame.set_reps)
	activities.stop()


## Milestone 13, Task 2: more sets follow until the chosen time ends (decision 36).
func _test_strength_more_sets() -> void:
	_start_strength("very_hard")
	_check("Very hard: one set is the avatar's goal", minigame.sets_goal == 1)
	var guard := 0
	var most_sets := 0
	while activities.is_running() and guard < 400:
		guard += 1
		most_sets = maxi(most_sets, minigame.sets_started)
		if minigame.resting:
			_pass_time(0.2)
		elif minigame.is_waiting():
			minigame.press(true)
		else:
			_pass_time(1.0)
			minigame.press(minigame.next_down)
	_check("the activity ends with the chosen time", not activities.is_running())
	_check("more sets followed the goal", most_sets > 1)


## Milestone 13, Task 2: no press: same as cardio, but the rest is not stopping (decision 37).
func _test_strength_waiting() -> void:
	_start_strength("normal")
	_pass_time(20.5)
	_check("no first press: the activity ends after 20 s", not activities.is_running())

	_start_strength("normal")
	minigame.press(true)
	_play_set(1.0)
	_check("in the rest", minigame.resting)
	_pass_time(5.5)
	_check("the rest is not waiting", not minigame.is_waiting() and minigame.resting)
	_pass_time(0.6)
	_check("the new set waits for its first press like any other", not minigame.resting and not minigame.is_waiting())
	_pass_time(3.1)
	_check("3 s without a press: the avatar stands still", minigame.is_waiting())
	_pass_time(20.5)
	_check("20 s later the activity ends", not activities.is_running())


## Milestone 13, Task 2: a session survives a reload, also during a rest.
func _test_strength_saving() -> void:
	var save_game: Node = root.get_node("SaveGame")
	_start_strength("normal")
	minigame.press(true)
	_repetition(1.0)
	_repetition(1.0)
	_reload(save_game)
	_check("in the middle of a set: it waits, with its repetitions", minigame.kind == "strength" and minigame.is_waiting()
			and minigame.reps_in_set == 2 and minigame.set_reps == 9 and minigame.sets_goal == 2)
	minigame.press(true)
	_play_set(1.0)
	_check("the set goes on from there", minigame.resting and minigame.strides == 9)
	_reload(save_game)
	_check("during a rest: the rest goes on", minigame.resting and not minigame.is_waiting())
	_pass_time(6.1)
	_check("...and the next set starts", minigame.sets_started == 2 and not minigame.resting)
	activities.stop()
	minigame.detach()
	save_game.delete_save()


## As when the page opens again: the save loads first, then the main screen opens.
func _reload(save_game: Node) -> void:
	save_game.save_game()
	minigame.detach()
	activities.reset()
	minigame.reset()
	save_game.load_game()
	minigame.attach()


## Milestone 13, Task 3: strength reaches the health system only when the avatar really moves.
func _test_strength_health() -> void:
	_start_strength("normal")
	var gap: float = gs.hours_since_strength
	_pass_time(21.0)
	_check("a session nobody played is not a session: the 36-hour gap goes on", gs.hours_since_strength >= gap
			and not activities.is_running())
	_check("...and no exercise counts", is_equal_approx(gs.exercise_minutes_today, 0.0))
	_check("...so the next one is not too soon", not training.strength_too_soon())

	activities.start("exercise", "strength")
	var happiness_before: float = gs.happiness
	minigame.press(true)
	_check("the first press starts the session", gs.hours_since_strength < 0.1 and not gs.strength_too_soon)
	_check("...with the cost of starting exercise", gs.happiness < happiness_before)
	_check("while moving, the METy of strength", is_equal_approx(energy.mety_now(), 5.0))
	var window_before: float = training.effective_minutes("strength")
	_play_set(1.0)
	_check("a played set trains strength", training.effective_minutes("strength") > window_before)
	_check("the rest keeps the METy of the session", minigame.resting and is_equal_approx(energy.mety_now(), 5.0))
	activities.stop()

	_check("right after it, the next session would be too soon", training.strength_too_soon())
	activities.start("exercise", "strength")
	_check("before the first press nothing is decided", not gs.strength_too_soon)
	minigame.press(true)
	_check("the first press marks it too soon", gs.strength_too_soon)
	var trained: float = training.effective_minutes("strength")
	_repetition(1.0)
	_repetition(1.0)
	_check("too soon: no effective minutes", training.effective_minutes("strength") <= trained)
	activities.stop()

	_new_avatar("easy")
	gs.sleep_debt = 0.0
	minigame.attach()
	activities.start("exercise", "strength")
	minigame.press(true)
	for i in 3:
		_repetition(1.0)
	_check("good technique: full performance", absf(training.performance() - 1.0) < TOLERANCE)
	for i in 6:
		_repetition(0.4)
	_check("poor technique: lower performance, never below 0.7", training.performance() < 1.0 and training.performance() >= 0.7)
	activities.stop()


## Task 4 (decision 19): a session without a tap is not done, whatever the time that passed.
func _test_no_tap_counts_nothing() -> void:
	_start_session("normal", false)
	var calories: float = gs.calories_spent
	var happiness_at_start: float = gs.happiness
	var hours_before: float = gs.sim_hours
	_check("no happiness cost before the first tap", is_equal_approx(gs.happiness, happiness_at_start))
	_check("while waiting the avatar uses idle energy", is_equal_approx(energy.mety_now(), root.get_node("Config").get_float("energy.mety_idle")))
	_check("while waiting it is doing nothing", activities.doing_option() == "")
	_pass_time(10.0)
	_check("no activity minutes pass", is_equal_approx(activities.elapsed_hours, 0.0))
	_check("no exercise minutes count", is_equal_approx(gs.exercise_minutes_today, 0.0))
	_check("no calories go to the record", is_equal_approx(calories, gs.calories_spent))
	_check("the game day goes on, and no time is lost", absf(gs.sim_hours - hours_before - clock.real_seconds_to_avatar_hours(10.0, false)) < 0.1)
	_pass_time(11.0)
	_check("the activity ends with nothing done", not activities.is_running() and is_equal_approx(gs.exercise_minutes_today, 0.0))

	_start_session("normal", false)
	var before_tap: float = gs.happiness
	minigame.tap()
	_check("the first tap brings the cost of starting exercise, once", gs.happiness < before_tap)
	var after_tap: float = gs.happiness
	_pass_time(3.1)
	minigame.tap()
	_check("a tap after a wait does not bring it again", absf(gs.happiness - after_tap) < 0.01)
	activities.stop()


## Task 4: minutes count only while the avatar moves, as for Stop (decision 20).
func _test_played_minutes_count() -> void:
	_start_session("normal")
	var interval: float = minigame.interval()
	_play(10, interval)
	var played: float = activities.elapsed_hours
	_check("tapping: the activity moves on", absf(played - clock.real_seconds_to_avatar_hours(10.0 * interval, false)) < 0.02)
	_pass_time(3.1)
	var at_wait: float = activities.elapsed_hours
	_pass_time(10.0)
	_check("waiting: it stops", is_equal_approx(activities.elapsed_hours, at_wait))
	minigame.tap()
	_pass_time(0.5)
	_check("a tap: it goes on", activities.elapsed_hours > at_wait)
	var activities_played: float = activities.elapsed_hours
	activities.stop()
	_check("training counted exactly the played minutes", absf(gs.exercise_minutes_today - activities_played * 60.0) < 0.1)


## Task 4: the score reaches performance, and without a player nothing changes.
func _test_score_reaches_training() -> void:
	_new_avatar("easy")
	gs.sleep_debt = 0.0
	var fixed: float = training.performance()
	_check("no player: performance as before, score 1", is_equal_approx(fixed, 1.0))
	minigame.attach()
	activities.start("exercise", "cardio")
	minigame.tap()
	_play(15, minigame.interval())
	_check("a perfect player: the same performance", absf(training.performance() - fixed) < TOLERANCE)
	_play(40, minigame.interval() * 1.5)
	_check("a poor player: lower performance, never below 0.7", training.performance() < 0.85 and training.performance() >= 0.7)
	activities.stop()


## Task 4: running spends the cardio METy and walking spends less.
func _test_walking_energy() -> void:
	_start_session("very_hard")
	var running_mety: float = energy.mety_now()
	_check("running uses the cardio METy", is_equal_approx(running_mety, 7.0))
	minigame.walking = true
	_check("walking uses walk_mety", is_equal_approx(energy.mety_now(), root.get_node("Config").get_float("minigame.walk_mety"))
			and energy.mety_now() < running_mety)
	activities.stop()


## Task 5: the panel takes the place of the four buttons, in both languages.
func _test_screen() -> void:
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://test_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	_new_avatar("normal")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_check("no session: the four buttons show", main.action_grid.visible and not main.minigame_panel.visible)
	activities.start("exercise", "cardio")
	_check("cardio: the panel takes their place", main.minigame_panel.visible and not main.action_grid.visible)
	_check("it asks for the first tap", main.minigame_status.text == "Tap to start!")
	var stood_still: bool = main.avatar.hop_offset == 0.0 and main.avatar._animation == null
	_check("the avatar stands still while it waits", stood_still)
	main.get_node("%TapButton").button_down.emit()
	main._refresh_minigame()
	_check("the tap button starts it", minigame.strides == 1 and main.minigame_status.text == "Running")
	_check("the avatar hops with the stride", main.avatar._animation != null)
	_check("the steps are shown", main.minigame_steps.text == "Steps: 2 / %d" % minigame.steps_goal())
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	minigame.seconds_since_tap = minigame.interval()
	main._unhandled_key_input(space)
	_check("Space is a tap on a computer", minigame.strides == 2)
	minigame.walking = true
	main._refresh_minigame()
	_check("the status says it is walking", main.minigame_status.text == "Walking: catching my breath")
	settings.set_language("pt")
	main._refresh_minigame()
	_check("the texts change language", main.minigame_status.text == "A andar: a recuperar o fôlego"
			and main.minigame_steps.text.begins_with("Passos: 4"))
	settings.set_language("en")
	minigame.walking = false
	activities.stop()
	_check("Stop brings the four buttons back", main.action_grid.visible and not main.minigame_panel.visible)
	activities.start("exercise", "cardio")
	_pass_time(21.0)
	_check("after the wait the buttons are back, with a message", main.action_grid.visible
			and main.speech_label.text == "You stopped tapping, so I stopped.")
	_test_strength_screen(main, settings)
	root.remove_child(main)
	main.free()
	_check("closing the main screen ends the player's presence", not minigame._player_present)
	DirAccess.remove_absolute("user://test_settings.json")


## Milestone 13, Task 4: the panel for strength, with main still open.
func _test_strength_screen(main: Node, settings: Node) -> void:
	activities.start("exercise", "strength")
	main._refresh_minigame()
	var down: Button = main.down_button
	var up: Button = main.up_button
	_check("strength: Down and Up in place of the tap button", main.strength_buttons.visible and not main.tap_button.visible)
	_check("the bar is the Muscle bar", main.reserve_label.text == "Muscle")
	_check("only the expected button is enabled", not down.disabled and up.disabled)
	_check("it asks for the first press", main.minigame_status.text == "Tap to start!")
	down.button_down.emit()
	main._refresh_minigame()
	_check("Down moves the avatar down", main.avatar._animation != null)
	_check("the set is shown", main.minigame_status.text == "Set 1 of %d" % minigame.sets_goal)
	_check("now Up is the expected one", down.disabled and not up.disabled)
	_pass_time(1.0)
	up.button_down.emit()
	main._refresh_minigame()
	_check("the repetitions are shown", main.minigame_steps.text == "Repetitions: 1 / %d" % minigame.set_reps)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DOWN
	_pass_time(1.0)
	main._unhandled_key_input(key)
	_pass_time(1.0)
	key.keycode = KEY_UP
	main._unhandled_key_input(key)
	_check("the arrow keys play it on a computer", minigame.reps_in_set == 2)
	_pass_time(1.0)
	down.button_down.emit()
	_play_set(1.0)
	main._refresh_minigame()
	_check("the rest is shown, with both buttons off", main.minigame_status.text == "Resting" and down.disabled and up.disabled)
	settings.set_language("pt")
	main._refresh_minigame()
	_check("the texts change language", main.minigame_status.text == "A descansar" and main.reserve_label.text == "Músculo"
			and main.minigame_steps.text.begins_with("Repetições:"))
	settings.set_language("en")
	minigame.sets_goal = 1
	minigame.sets_started = 2
	minigame.resting = false
	main._refresh_minigame()
	_check("past the goal the set is an extra one", main.minigame_status.text == "Extra set 1")
	activities.stop()
	main._end_flash()
	activities.start("exercise", "strength")
	_check("too soon: the avatar warns", main.speech_label.text == "My muscles still need rest.")
	_check("...and the player can still play", minigame.running and activities.is_running())
	activities.stop()


func _new_avatar(difficulty: String) -> void:
	activities.reset()
	minigame.reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "male", difficulty)


func _start_session(difficulty: String, first_tap := true) -> void:
	_new_avatar(difficulty)
	minigame.attach()
	activities.start("exercise", "cardio")
	if first_tap:
		minigame.tap()


func _start_strength(difficulty: String) -> void:
	_new_avatar(difficulty)
	minigame.attach()
	activities.start("exercise", "strength")


## Up after gap seconds, then Down after gap seconds: the Down of the next repetition.
func _repetition(gap: float) -> void:
	_pass_time(gap)
	minigame.press(false)
	if not minigame.resting:
		_pass_time(gap)
		minigame.press(true)


## Repetitions until the set ends.
func _play_set(gap: float) -> void:
	while activities.is_running() and not minigame.resting:
		_repetition(gap)


## Plays this many strides, one every gap seconds.
func _play(strides: int, gap: float) -> void:
	for i in strides:
		_pass_time(gap)
		minigame.tap()


## Real time passes for the Clock and the minigame, in small steps.
func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 0.02)
		clock._process(step)
		minigame.advance(step)
		left -= step


func _set_body(fitness: float, z: float, debt: float) -> void:
	gs.fitness = fitness
	gs.weight_z = z
	gs.sleep_debt = debt
	gs.hours_awake = 0.0


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
