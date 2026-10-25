extends SceneTree
## Tests for the slow body states (Milestone 3 Task 4, Milestone 4 Task 4). Run from the project folder:
##   Godot --headless --path . -s res://tests/body_test.gd
## Simulates avatar days by giving habit scores directly. Uses a test save path.

const TOLERANCE := 0.0001
const STEP_SECONDS := 0.1
## Scores of a day with 60 min of activity and strength, good sleep and few screens.
const ACTIVE_DAY := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 1.0}
## Scores of a day without activity.
const RESTING_DAY := {"sleep": 1.0, "activity": 0.0, "strength": 0.0, "screens": 1.0}
## Intensities of a day with full activity (the usual levels move toward these).
const ACTIVE_INTENSITY := {"sleep": 0.8, "activity": 1.0, "strength": 1.0, "screens": 0.2}

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

	# Fitness and strength: tests/training_test.gd (Milestone 10, trained every step).
	_test_k(gs, config)
	_test_sleep_debt(gs, config)
	_test_mood_and_habits(gs)
	_test_habit_levels(gs, config)
	_test_milestone3_save(gs, config)
	_test_habit_cost(gs, config)
	_test_in_play(gs, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## k makes the body change faster: one avatar day runs the real-day update k times,
## so it gives exactly the same as k avatar days with k = 1.
func _test_k(gs: Node, config: Node) -> void:
	var k_entry: Dictionary = config._data["health_m4"]["k"]
	var k_saved: float = k_entry["value"]
	var k: int = roundi(k_saved)
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = 1.0
	for day in k:
		gs.update_body_states(ACTIVE_DAY, 10.5, ACTIVE_INTENSITY)
	var fitness_k1: float = gs.fitness
	var habit_k1: float = gs.usual_habits["activity"]
	var root_k1: float = gs.rootedness["activity"]
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = k_saved
	gs.update_body_states(ACTIVE_DAY, 10.5, ACTIVE_INTENSITY)
	_check("one avatar day with k = %d = %d real days with k = 1 (fitness)" % [k, k], absf(gs.fitness - fitness_k1) < TOLERANCE)
	_check("the same for the usual level H and rootedness R", absf(gs.usual_habits["activity"] - habit_k1) < TOLERANCE
			and absf(gs.rootedness["activity"] - root_k1) < TOLERANCE)
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = 1.0
	gs.update_body_states(ACTIVE_DAY, 8.0, ACTIVE_INTENSITY)
	var mood_k1: float = gs.mood
	var debt_k1: float = gs.sleep_debt
	gs.start_new_avatar("Test", "child", "female", "normal")
	k_entry["value"] = k_saved
	gs.update_body_states(ACTIVE_DAY, 8.0, ACTIVE_INTENSITY)
	_check("k does not change mood", is_equal_approx(gs.mood, mood_k1))
	_check("k does not change sleep debt (k_applies_to_sleep_debt is false)", is_equal_approx(gs.sleep_debt, debt_k1))
	k_entry["value"] = k_saved


func _test_sleep_debt(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "teenager", "male", "normal")
	var r: float = config.get_float("health_m4.r")
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
	# With enough sleep (exactly the recommended hours) the debt only shrinks by r each day:
	# it halves in about 3 avatar days (0.8^3 = 0.51).
	gs.start_new_avatar("Test", "teenager", "male", "normal")
	for day in 3:
		gs.update_body_states(ACTIVE_DAY, 5.0)
	var debt: float = gs.sleep_debt
	var halving := [debt]
	for day in 4:
		gs.update_body_states(ACTIVE_DAY, gs.recommended_sleep("teenager"))
		halving.append(gs.sleep_debt)
	print("debt with enough sleep: %s" % ", ".join(halving.map(func(v): return "%.2f" % v)))
	_check("debt halves in about 3 avatar days with enough sleep", halving[3] / debt > 0.45 and halving[3] / debt < 0.55
			and halving[2] / debt > 0.55)
	_check("sleep debt shrinks with enough sleep", _falling(values) or is_zero_approx(values[-1]))
	for day in 10:
		gs.update_body_states(ACTIVE_DAY, 10.0)
	_check("sleep debt never goes below 0", is_zero_approx(gs.sleep_debt))


func _test_mood_and_habits(gs: Node) -> void:
	# The habits stay at their usual levels here (no change cost), so only the mood target acts.
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	var mood_start: float = gs.mood
	gs.update_body_states(ACTIVE_DAY, 10.0, gs.usual_habits.duplicate())
	_check("mood moves toward the day's scores", gs.mood > mood_start and gs.mood < 100.0)
	var bad_day := {"sleep": 0.0, "activity": 0.0, "strength": 0.0, "screens": 0.0}
	var mood_before: float = gs.mood
	gs.update_body_states(bad_day, 4.0, gs.usual_habits.duplicate())
	_check("a bad day lowers mood", gs.mood < mood_before)
	var usual_start: float = gs.usual_habits["activity"]
	gs.update_body_states(ACTIVE_DAY, 10.0, ACTIVE_INTENSITY)
	_check("usual activity level moves toward the day's intensity", gs.usual_habits["activity"] > usual_start
			and gs.usual_habits["activity"] < 1.0)


## Usual level H reaches 95% of a new habit after habit_days_to_95 / k (about 13) avatar
## days. Rootedness R grows toward 1, but only on real days when the habit is stable.
func _test_habit_levels(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.usual_habits["activity"] = 0.0
	var root_start: float = gs.rootedness["activity"]
	var days_to_95: float = config.get_float("health_m4.habit_days_to_95") / gs.real_days_per_avatar_day()
	var levels := []
	for day in 15:
		gs.update_body_states(ACTIVE_DAY, 10.5, {"activity": 1.0})
		levels.append(gs.usual_habits["activity"])
	print("usual activity level H, new habit from 0: day 12 %.3f, day 13 %.3f, day 14 %.3f (95%% expected near day %.1f)" % [
			levels[11], levels[12], levels[13], days_to_95])
	_check("H is below 95% after 12 avatar days", levels[11] < 0.95)
	_check("H reaches about 95% after 13 avatar days (over 94%)", levels[12] > 0.94)
	_check("H is over 95% after 14 avatar days", levels[13] > 0.95)
	_check("rootedness R grows once the new habit is stable", gs.rootedness["activity"] > root_start and gs.rootedness["activity"] < 1.0)
	# Sleep was not in the intensities, so it counts as stable every day.
	var lambda: float = config.get_float("health_m4.habit_cost.lambda")
	var expected_R: float = 1.0 - (1.0 - root_start) * pow(1.0 - lambda, 15 * gs.real_days_per_avatar_day())
	_check("a stable habit's R follows R += lambda x (1 - R), k times per avatar day", absf(gs.rootedness["sleep"] - expected_R) < TOLERANCE)
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.usual_habits["activity"] = 0.0
	var root_before: float = gs.rootedness["activity"]
	gs.update_body_states(ACTIVE_DAY, 10.5, {"activity": 1.0})
	_check("R does not grow while the habit is changing (|A - H| above T)", is_equal_approx(gs.rootedness["activity"], root_before))
	gs.start_new_avatar("Test", "child", "female", "hard")
	_check("R starts at the difficulty's start_R (Hard 0.2)", is_equal_approx(gs.rootedness["sleep"], 0.2))
	_check("H starts at the difficulty's start_H", is_equal_approx(gs.usual_habits["screens"],
			config.get_float("health_m4.difficulties.hard.start_H.screens")))


## Milestone 4 Task 5: the team model for the cost of changing habits, on Very hard.
func _test_habit_cost(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	_check("Very hard: R starts at 0.8", is_equal_approx(gs.rootedness["activity"], 0.8))
	gs.usual_habits["activity"] = 0.0
	var same: Dictionary = gs.usual_habits.duplicate()
	var jump: Dictionary = same.duplicate()
	jump["activity"] = 1.0
	var costs: Dictionary = gs.habit_change_costs(jump)
	var p_max: float = config.get_float("health_m4.habit_cost.P_max")
	var formula: float = config.get_float("health_m4.habit_cost.alpha") * pow(0.8, 2.0) * pow(0.9, 2.0)
	print("activity 0 -> 1 in one day (R 0.8, D 0.9): 200 x 0.8^2 x 0.9^2 = %.1f, cost %.2f mood points (P_max %.0f per habit)" % [
			formula, costs["activity"], p_max])
	_check("changing activity from 0 to 1 in one day costs about 104 points, at most P_max per habit",
			absf(costs["activity"] - minf(formula, p_max)) < TOLERANCE and formula > 100.0)
	_check("habits that did not change cost nothing", is_zero_approx(costs["sleep"]) and is_zero_approx(costs["screens"]))
	var step: Dictionary = same.duplicate()
	step["activity"] = 0.2
	var step_cost: float = gs.habit_change_costs(step)["activity"]
	print("activity 0 -> 0.2 in one day: cost %.2f mood points" % step_cost)
	_check("changing by 0.2 per day costs little (about 1.3 points)", absf(step_cost - 1.28) < 0.01)
	_check("two steps of 0.2 cost less than one of 0.4 (gamma 2)", 2.0 * step_cost < gs.habit_change_costs(
			{"sleep": same["sleep"], "activity": 0.4, "strength": same["strength"], "screens": same["screens"]})["activity"])
	var more_sleep: Dictionary = same.duplicate()
	more_sleep["sleep"] = 1.0
	_check("changing sleep costs nothing (alpha_factor 0)", is_zero_approx(gs.habit_change_costs(more_sleep)["sleep"]))
	var small: Dictionary = same.duplicate()
	small["activity"] = 0.1
	_check("a change up to T (0.10) costs nothing", is_zero_approx(gs.habit_change_costs(small)["activity"]))
	var down: Dictionary = same.duplicate()
	down["screens"] = 0.0
	_check("cutting a habit costs too (|A - H|)", gs.habit_change_costs(down)["screens"] > 0.0)
	var all_jump := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 0.0}
	var all_costs: Dictionary = gs.habit_change_costs(all_jump)
	var summed := 0.0
	for habit in all_costs:
		summed += all_costs[habit]
	_check("the day's total is the sum over the habits, with no cap", is_equal_approx(gs.total_habit_cost(all_costs), summed)
			and summed > p_max)
	gs.start_new_avatar("Test", "child", "female", "hard")
	var hard_jump: Dictionary = gs.usual_habits.duplicate()
	hard_jump["activity"] = 1.0
	var hard_cost: float = gs.habit_change_costs(hard_jump)["activity"]
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	var very_hard_jump: Dictionary = gs.usual_habits.duplicate()
	very_hard_jump["activity"] = 1.0
	_check("the same jump costs much less on Hard (R 0.2) than on Very hard (R 0.8)",
			hard_cost < 0.25 * gs.habit_change_costs(very_hard_jump)["activity"])
	# The cost comes off mood: mood = mood + mood_speed x (target - mood) - cost.
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	var scores := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 1.0, "enjoyment": 1.0}
	var mood_start: float = gs.mood
	var expected_cost: float = gs.total_habit_cost(gs.habit_change_costs(all_jump))
	var expected: float = clampf(mood_start + config.get_float("health_m4.mood_speed") * (gs.mood_target(scores) - mood_start)
			- expected_cost, 0.0, 100.0)
	gs.update_body_states(scores, 10.5, all_jump)
	_check("mood = mood + mood_speed x (target - mood) - cost", absf(gs.mood - expected) < TOLERANCE
			and is_equal_approx(gs.habit_cost_total, expected_cost))
	_check("mood target = 100 x average of s, a, c and e", is_equal_approx(gs.mood_target(scores), 100.0))
	_check("mental = mood / 100", is_equal_approx(gs.mental, gs.mood / 100.0))


## A Milestone 3 save has no rootedness, and its usual levels were habit scores:
## it loads with the Normal starting H and R.
func _test_milestone3_save(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "very_hard")
	var old: Dictionary = gs.to_dict()
	old.erase("rootedness")
	old["usual_habits"] = {"sleep": 0.1, "activity": 0.075, "strength": 0.075, "screens": 0.05}
	gs.from_dict(old)
	_check("a Milestone 3 save gets the Normal start_R", is_equal_approx(gs.rootedness["activity"],
			config.get_float("health_m4.difficulties.normal.start_R")))
	_check("and the Normal start_H", is_equal_approx(gs.usual_habits["screens"],
			config.get_float("health_m4.difficulties.normal.start_H.screens")))
	_check("the rest of the save still loads", gs.difficulty == "very_hard")
	old = gs.to_dict()
	old.erase("rootedness")
	old["mood"] = 0.3
	gs.from_dict(old)
	_check("a Milestone 3 mood (0 to 1) is scaled to 0 to 100", is_equal_approx(gs.mood, 30.0))


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
	_check("fitness rises during the cardio (Milestone 10: trained every step)", gs.fitness > fitness_start)
	# The avatar can sleep only when sleepy (v1 can-sleep rule): make it sleepy.
	gs.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	activities.start("sleep", "sleep", 10.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(STEP_SECONDS)
	var saved: Dictionary = gs.to_dict()
	save_game.save_game()
	gs.reset()
	_check("load finds the save", save_game.load_game())
	_check("body states restored", is_equal_approx(gs.fitness, saved["fitness"]) and is_equal_approx(gs.mood, saved["mood"])
			and is_equal_approx(gs.sleep_debt, saved["sleep_debt"]) and is_equal_approx(gs.weight_z, saved["weight_z"])
			and is_equal_approx(gs.usual_habits["activity"], saved["usual_habits"]["activity"])
			and is_equal_approx(gs.rootedness["activity"], saved["rootedness"]["activity"]))
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
