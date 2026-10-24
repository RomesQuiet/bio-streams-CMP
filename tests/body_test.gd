extends SceneTree
## Tests for the slow body states (Milestone 3, Task 4). Run from the project folder:
##   Godot --headless --path . -s res://tests/body_test.gd
## Simulates avatar days by giving habit scores directly. Uses a test save path.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1
## Scores of a day with 60 min of activity and strength, good sleep and few screens.
const ACTIVE_DAY := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 1.0}
## Scores of a day without activity.
const RESTING_DAY := {"sleep": 1.0, "activity": 0.0, "strength": 0.0, "screens": 1.0}

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var config: Node = root.get_node("Config")
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_test_fitness(gs)
	_test_k(gs, config)
	_test_sleep_debt(gs, config)
	_test_mood_and_habits(gs)
	_test_in_play(gs, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_fitness(gs: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	var z_start: float = gs.weight_z
	print("day  fitness  muscle   (7 active days, then 7 resting days)")
	var values := [gs.fitness]
	for day in 7:
		gs.update_body_states(ACTIVE_DAY, 10.0)
		values.append(gs.fitness)
		print("%3d  %.3f    %.3f" % [day + 1, gs.fitness, gs.muscle])
	_check("fitness rises every active day", _rising(values))
	_check("muscle rises with strength", gs.muscle > 0.25)
	var after_active: float = gs.fitness
	var rise: float = after_active - values[0]
	values = [gs.fitness]
	for day in 7:
		gs.update_body_states(RESTING_DAY, 10.0)
		values.append(gs.fitness)
		print("%3d  %.3f    %.3f" % [day + 8, gs.fitness, gs.muscle])
	_check("fitness falls every day without activity", _falling(values))
	_check("it falls slowly: less lost in 7 days than gained in 7 days", after_active - gs.fitness < rise)
	_check("fitness stays between 0 and 1", gs.fitness >= 0.0 and gs.fitness <= 1.0)
	_check("weight z-score stays at the difficulty's value", is_equal_approx(gs.weight_z, z_start))


## k makes the body change faster: one day with k = 4 changes more than with k = 1.
func _test_k(gs: Node, config: Node) -> void:
	var k_entry: Dictionary = config._data["health"]["k"]
	var k_saved: float = k_entry["value"]
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = 1.0
	gs.update_body_states(ACTIVE_DAY, 10.0)
	var gain_k1: float = gs.fitness - 0.25
	var mood_k1: float = gs.mood
	var debt_k1: float = gs.sleep_debt
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = 4.0
	gs.update_body_states(ACTIVE_DAY, 10.0)
	_check("with k = 4 fitness changes 4 times as much as with k = 1", absf((gs.fitness - 0.25) - 4.0 * gain_k1) < TOLERANCE)
	_check("k does not change mood", is_equal_approx(gs.mood, mood_k1))
	_check("k does not change sleep debt", is_equal_approx(gs.sleep_debt, debt_k1))
	k_entry["value"] = k_saved


func _test_sleep_debt(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "teenager", "male", "normal")
	var r: float = config.get_float("health.r")
	var short: float = gs.recommended_sleep("teenager") - 5.0
	_check("no sleep debt at the start", is_zero_approx(gs.sleep_debt))
	var values := [gs.sleep_debt]
	for day in 5:
		gs.update_body_states(ACTIVE_DAY, 5.0)  # Below the teenager's recommended sleep.
		values.append(gs.sleep_debt)
	print("sleep debt after 5 nights of 5 h: %.2f h" % gs.sleep_debt)
	_check("first short night: debt = recommended - 5 h", absf(values[1] - short) < TOLERANCE)
	_check("second short night: debt = debt * r + (recommended - 5 h)", absf(values[2] - (short * r + short)) < TOLERANCE)
	_check("sleep debt grows with short sleep", _rising(values))
	values = [gs.sleep_debt]
	for day in 5:
		gs.update_body_states(ACTIVE_DAY, 10.0)  # 1 h above the recommended sleep.
		values.append(gs.sleep_debt)
	print("sleep debt after 5 more nights of 10 h: %.2f h" % gs.sleep_debt)
	_check("sleep debt shrinks with enough sleep", _falling(values) or is_zero_approx(values[-1]))
	for day in 10:
		gs.update_body_states(ACTIVE_DAY, 10.0)
	_check("sleep debt never goes below 0", is_zero_approx(gs.sleep_debt))


func _test_mood_and_habits(gs: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	var mood_start: float = gs.mood
	var usual_start: float = gs.usual_habits["activity"]
	gs.update_body_states(ACTIVE_DAY, 10.0)
	_check("mood moves toward the day's scores", gs.mood > mood_start and gs.mood < 1.0)
	_check("usual activity level moves toward the activity score", gs.usual_habits["activity"] > usual_start
			and gs.usual_habits["activity"] < 1.0)
	var bad_day := {"sleep": 0.0, "activity": 0.0, "strength": 0.0, "screens": 0.0}
	var mood_before: float = gs.mood
	gs.update_body_states(bad_day, 4.0)
	_check("a bad day lowers mood", gs.mood < mood_before)


## In play: the body states change when a sleep ends, and they are saved and loaded.
func _test_in_play(gs: Node, save_game: Node) -> void:
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	activities.reset()
	root.get_node("Habits").reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "female", "normal")
	clock.debug_speed = 600.0
	var fitness_start: float = gs.fitness
	activities.start("exercise", "cardio")
	while activities.is_running():
		clock._process(STEP_SECONDS)
	_check("fitness does not change during the day", is_equal_approx(gs.fitness, fitness_start))
	activities.start("sleep", "sleep", 10.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	_check("fitness rises when the sleep ends (after 1 h of cardio)", gs.fitness > fitness_start)
	var saved: Dictionary = gs.to_dict()
	save_game.save_game()
	gs.reset()
	_check("load finds the save", save_game.load_game())
	_check("body states restored", is_equal_approx(gs.fitness, saved["fitness"]) and is_equal_approx(gs.mood, saved["mood"])
			and is_equal_approx(gs.sleep_debt, saved["sleep_debt"]) and is_equal_approx(gs.weight_z, saved["weight_z"])
			and is_equal_approx(gs.usual_habits["activity"], saved["usual_habits"]["activity"]))
	gs.print_state()


func _rising(values: Array) -> bool:
	for i in range(1, values.size()):
		if values[i] <= values[i - 1]:
			return false
	return true


func _falling(values: Array) -> bool:
	for i in range(1, values.size()):
		if values[i] >= values[i - 1]:
			return false
	return true


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
