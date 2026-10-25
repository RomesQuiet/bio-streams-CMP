extends SceneTree
## Tests for the 5-minute update loop (Milestone 10, Task 2). Run from the project folder:
##   Godot --headless --path . -s res://tests/simulation_test.gd
## Plays the same avatar time with small and very large frames and checks that the steps
## and the results are the same. Uses a test save path, so the real save is never touched.

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_frame_rate()
	_test_phase_boundaries()
	_test_pause()
	_test_save()

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## A day and a night with small frames (debug speed 60, 0.1 s) and with huge frames
## (debug speed 600, 0.5 s = 3.5 avatar hours per frame) give the same steps and XP.
func _test_frame_rate() -> void:
	var small := _play_day_and_night(60.0, 0.1)
	var big := _play_day_and_night(600.0, 0.5)
	print("  small frames: %d steps awake, %d asleep, XP %.4f" % [small["awake"], small["asleep"], small["xp"]])
	print("  big frames:   %d steps awake, %d asleep, XP %.4f" % [big["awake"], big["asleep"], big["xp"]])
	_check("same number of steps whatever the frame size", small["awake"] == big["awake"] and small["asleep"] == big["asleep"])
	_check("same XP whatever the frame size", is_equal_approx(small["xp"], big["xp"]))
	_check("same hours awake and asleep", is_equal_approx(small["hours_awake"], big["hours_awake"])
			and is_equal_approx(small["hours_asleep"], big["hours_asleep"]))
	var per_hour: float = 60.0 / root.get_node("Config").get_float("time.step_avatar_min")
	_check("a 14 h day is 14 x 12 = 168 steps of 5 avatar minutes", small["awake"] == roundi(14.0 * per_hour))
	_check("a 10 h sleep is 120 steps", small["asleep"] == roundi(10.0 * per_hour))
	_check("the steps add up to the avatar time", is_equal_approx(small["hours_awake"], 14.0) and is_equal_approx(small["hours_asleep"], 10.0))


## Plays the first day to its end, then sleeps 10 h. Returns the counts.
func _play_day_and_night(speed: float, frame_seconds: float) -> Dictionary:
	var clock: Node = root.get_node("Clock")
	var gs: Node = root.get_node("GameState")
	var simulation: Node = root.get_node("Simulation")
	_new_game()
	gs.start_new_avatar("Test", "child", "female", "easy")
	gs.health = 4.6  # High health, so the XP over time runs every step.
	var counts := {"awake": 0, "asleep": 0, "hours_awake": 0.0, "hours_asleep": 0.0, "xp": 0.0}
	var on_step := func(hours: float, asleep: bool) -> void:
		counts["asleep" if asleep else "awake"] += 1
		counts["hours_asleep" if asleep else "hours_awake"] += hours
	simulation.stepped.connect(on_step)
	clock.debug_speed = speed
	# Stop just before the end of the day (the 0-hour rule would start a new day).
	while clock.day_elapsed_hours < 14.0 - 0.0001 and clock.day_number == 1:
		clock._process(minf(frame_seconds, clock.avatar_hours_to_real_seconds(14.0 - clock.day_elapsed_hours, false) / speed))
	root.get_node("Activities").start("sleep", "sleep", 10.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(frame_seconds)
	simulation.stepped.disconnect(on_step)
	counts["xp"] = gs.xp
	return counts


## Time asleep and awake stay exact: a sleep of 1 h 3 min ends with a 3-minute step,
## and nothing of it is counted as awake.
func _test_phase_boundaries() -> void:
	var clock: Node = root.get_node("Clock")
	var gs: Node = root.get_node("GameState")
	var simulation: Node = root.get_node("Simulation")
	_new_game()
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.hours_awake = 6.0
	var steps: Array = []
	var on_step := func(hours: float, asleep: bool) -> void: steps.append([hours, asleep])
	simulation.stepped.connect(on_step)
	clock.debug_speed = 600.0
	root.get_node("Activities").start("sleep", "sleep", 1.05)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.5)
	simulation.stepped.disconnect(on_step)
	var asleep_hours := 0.0
	for step in steps:
		asleep_hours += step[0] if step[1] else 0.0
	_check("a 1.05 h sleep counts 1.05 h asleep", is_equal_approx(asleep_hours, 1.05))
	_check("its last step is the 3 minutes left over", steps.size() == 13 and is_equal_approx(steps[-1][0], 0.05) and steps[-1][1])
	_check("nothing is pending after the sleep ends", is_zero_approx(simulation.pending_minutes))


func _test_pause() -> void:
	var clock: Node = root.get_node("Clock")
	var simulation: Node = root.get_node("Simulation")
	_new_game()
	var count := [0]
	var on_step := func(_hours: float, _asleep: bool) -> void: count[0] += 1
	simulation.stepped.connect(on_step)
	clock.debug_speed = 600.0
	clock.set_paused(true)
	for i in 10:
		clock._process(0.5)
	simulation.stepped.disconnect(on_step)
	_check("nothing runs while paused", count[0] == 0)
	clock.set_paused(false)


## The part of a step not yet run is saved and loaded.
func _test_save() -> void:
	var clock: Node = root.get_node("Clock")
	var simulation: Node = root.get_node("Simulation")
	var save_game: Node = root.get_node("SaveGame")
	_new_game()
	root.get_node("GameState").start_new_avatar("Test", "child", "female", "normal")
	# One frame of 0.5 s (the longest frame the Clock counts) = 2 avatar minutes.
	clock.debug_speed = clock.avatar_hours_to_real_seconds(2.0 / 60.0, false) / 0.5
	clock._process(0.5)
	var pending: float = simulation.pending_minutes
	_check("2 avatar minutes are pending (less than one step)", is_equal_approx(pending, 2.0))
	save_game.save_game()
	simulation.reset()
	_check("load finds the save", save_game.load_game())
	_check("the pending minutes are restored", is_equal_approx(simulation.pending_minutes, pending))


func _new_game() -> void:
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	root.get_node("GameState").reset()
	root.get_node("Clock").reset()


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
