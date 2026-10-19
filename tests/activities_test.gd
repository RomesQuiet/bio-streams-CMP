extends SceneTree
## Tests for the activity system. Run from the project folder:
##   Godot --headless --path . -s res://tests/activities_test.gd

const STEP_SECONDS := 0.1
const TOLERANCE := 0.0001

var _failures := 0
var _ended_hours := -1.0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var activities: Node = root.get_node("Activities")
	var game_state: Node = root.get_node("GameState")
	var clock: Node = root.get_node("Clock")
	activities.reset()
	game_state.reset()
	clock.reset()
	clock.debug_speed = 600.0
	activities.ended.connect(func(_a, _o, hours): _ended_hours = hours)

	_test_sleep_activity(activities, game_state, clock)
	_test_day_activity(activities, game_state, clock)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_sleep_activity(activities: Node, game_state: Node, clock: Node) -> void:
	_check("sleep is defined in activities.json", activities.definitions.has("sleep"))
	_check("sleep can start during the day (nap)", activities.can_start("sleep"))
	_run_until_new_day(clock)
	var sleep_before: float = game_state.sleep
	_check("sleep starts when the avatar is tired", activities.start("sleep", "sleep", 10.0))
	_check("sleep runs through the activity system", activities.is_running() and activities.current_activity == "sleep")
	_check("clock is sleeping", clock.phase == clock.Phase.SLEEPING)
	_check("a second activity cannot start", not activities.can_start("sleep"))
	while activities.elapsed_hours < 5.0:
		clock._process(STEP_SECONDS)
	var slept: float = activities.elapsed_hours
	activities.stop()
	var gain: float = activities.get_option("sleep", "sleep")["effects_per_hour"]["sleep"]
	_check("stop ends the activity", not activities.is_running())
	_check("stop reports the hours done", absf(_ended_hours - slept) < TOLERANCE)
	_check("sleep effect counts only the hours slept", absf(game_state.sleep - (sleep_before + gain * slept)) < TOLERANCE)
	_check("clock waits for the wake button", clock.phase == clock.Phase.SLEEP_OVER)
	clock.wake_up()


func _test_day_activity(activities: Node, game_state: Node, clock: Node) -> void:
	# A test-only activity, so the day path is checked before exercise exists.
	activities.definitions["test_play"] = {
		"name": "Test",
		"options": {"play": {
			"name": "Play",
			"duration_hours": 2,
			"effects_per_hour": {"mental": 0.1},
			"background_color": "#336633",
			"animation": "hop",
		}},
	}
	var mental_before: float = game_state.mental
	var day_before: float = clock.day_elapsed_hours
	_check("day activity starts", activities.start("test_play", "play"))
	_check("sleep is locked while it runs", not activities.can_start("sleep"))
	while activities.is_running():
		clock._process(STEP_SECONDS)
	_check("day activity ends by itself after 2 h", absf(_ended_hours - 2.0) < TOLERANCE)
	_check("full effect applied (+0.2 mental)", absf(game_state.mental - (mental_before + 0.2)) < TOLERANCE)
	_check("day time moved on", clock.day_elapsed_hours >= day_before + 2.0 - TOLERANCE)

	mental_before = game_state.mental
	clock.debug_speed = 60.0  # Smaller steps, so the stop lands close to 1 h.
	activities.start("test_play", "play")
	while activities.elapsed_hours < 1.0:
		clock._process(STEP_SECONDS)
	var done: float = activities.elapsed_hours
	activities.stop()
	_check("stop halfway applies about half", absf(game_state.mental - (mental_before + 0.1 * done)) < TOLERANCE and absf(done - 1.0) < 0.1)
	var mental_after: float = game_state.mental
	clock._process(STEP_SECONDS)
	_check("no effects after the activity ends", is_equal_approx(game_state.mental, mental_after))
	activities.definitions.erase("test_play")


## Runs until the awake period runs out and a new day starts without sleep.
func _run_until_new_day(clock: Node) -> void:
	var day: int = clock.day_number
	for i in 100000:
		if clock.day_number != day:
			return
		clock._process(STEP_SECONDS)
	_check("a new day started", false)


func _run_until_phase(clock: Node, phase: int) -> void:
	for i in 100000:
		if clock.phase == phase:
			return
		clock._process(STEP_SECONDS)
	_check("reached phase %d" % phase, false)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
