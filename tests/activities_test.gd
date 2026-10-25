extends SceneTree
## Tests for the activity system. Run from the project folder:
##   Godot --headless --path . -s res://tests/activities_test.gd

const STEP_SECONDS := 0.1
const TOLERANCE := 0.0001

## Loaded at run time (it uses the autoloads).
var energy: GDScript
var _failures := 0
var _ended_hours := -1.0


func _process(_delta: float) -> bool:
	energy = load("res://scripts/health/energy.gd")
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
	_test_exercise(activities, game_state, clock)
	_test_entertainment(activities, game_state, clock, save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_sleep_activity(activities: Node, game_state: Node, clock: Node) -> void:
	_check("sleep is defined in activities.json", activities.definitions.has("sleep"))
	# v1 can-sleep rule: a new avatar (no sleep debt on the Milestone 4 values, 0 h awake)
	# is not sleepy; after sleep.can_sleep_awake_h awake it can nap.
	_check("not sleepy at the start of the first day", not activities.can_start("sleep"))
	game_state.hours_awake = root.get_node("Config").get_float("sleep.can_sleep_awake_h")
	_check("sleep can start during the day (nap) once sleepy", activities.can_start("sleep"))
	_run_until_new_day(clock)
	_check("sleep starts when the avatar is tired", activities.start("sleep", "sleep", 10.0))
	_check("sleep runs through the activity system", activities.is_running() and activities.current_activity == "sleep")
	_check("clock is sleeping", clock.phase == clock.Phase.SLEEPING)
	_check("a second activity cannot start", not activities.can_start("sleep"))
	while activities.elapsed_hours < 5.0:
		clock._process(STEP_SECONDS)
	var slept: float = activities.elapsed_hours
	activities.stop()
	_check("stop ends the activity", not activities.is_running())
	_check("stop reports the hours done", absf(_ended_hours - slept) < TOLERANCE)
	_check("sleep has no per-hour effect", activities.get_option("sleep", "sleep")["effects_per_hour"].is_empty())
	_check("the sleep measure comes from the hours slept", is_equal_approx(game_state.sleep,
			maxf(0.0, root.get_node("Habits").sleep_score(slept, game_state.age_group)
			* (1.0 - game_state.sleep_debt / root.get_node("Config").get_float("health_m4.debt_max")))))
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


## Cardio and muscle strength add calories spent (a record only) by the values in
## data/activities.json. Milestone 10: the calories-spent record is the energy spent while
## exercising (BMR / 24 x mety, every 5-minute step). Stop halfway counts half.
func _test_exercise(activities: Node, game_state: Node, clock: Node) -> void:
	_check("exercise is defined with cardio and strength", activities.get_option("exercise", "cardio").size() > 0 and activities.get_option("exercise", "strength").size() > 0)
	var cardio: Dictionary = activities.get_option("exercise", "cardio")["effects_per_hour"]
	var strength: Dictionary = activities.get_option("exercise", "strength")["effects_per_hour"]
	var cardio_mety: float = activities.option_value(activities.get_option("exercise", "cardio"), "mety")
	var strength_mety: float = activities.option_value(activities.get_option("exercise", "strength"), "mety")
	_check("cardio spends more calories than strength (METy 7.0 and 5.0)", cardio_mety == 7.0 and strength_mety == 5.0)
	_check("both are moderate-to-vigorous", activities.option_value(activities.get_option("exercise", "cardio"), "activity_intensity") == "moderate_vigorous"
			and activities.option_value(activities.get_option("exercise", "strength"), "activity_intensity") == "moderate_vigorous")
	_check("there is no fatigue effect", not cardio.has("fatigue") and not strength.has("fatigue"))
	_check("no per-hour muscle or physical effects", not cardio.has("muscle") and not strength.has("muscle")
			and not cardio.has("physical") and not strength.has("physical"))

	for option_id in ["cardio", "strength"]:
		var mety: float = activities.option_value(activities.get_option("exercise", option_id), "mety")
		var kcal: float = energy.kcal_per_hour(game_state.sex_or_default(), game_state.body_age_months, game_state.weight_kg, mety)
		var hours: float = float(activities.get_option("exercise", option_id)["duration_hours"])
		_check("%s lasts 1 avatar hour" % option_id, is_equal_approx(hours, 1.0))
		clock.debug_speed = 600.0
		var before := _snapshot(game_state)
		_check("%s starts" % option_id, activities.start("exercise", option_id))
		_check("sleep is locked during %s" % option_id, not activities.can_start("sleep"))
		while activities.is_running():
			clock._process(STEP_SECONDS)
		root.get_node("Simulation").flush()
		# Weight changes a little during the hour (k = 10), so BMR does too: within 1 kcal.
		_check("%s: calories spent change by BMR / 24 x METy" % option_id, absf(game_state.calories_spent - (before["calories_spent"] + kcal * hours)) < 1.0)
		_check("%s: muscle and physical do not change during the day" % option_id,
				is_equal_approx(game_state.muscle, before["muscle"]) and is_equal_approx(game_state.physical, before["physical"]))

		# Stop halfway: calories count only for the time done. Small steps, so the stop
		# lands close to 0.5 h.
		clock.debug_speed = 30.0
		# BMR now: the weight changed during the first hour.
		kcal = energy.kcal_per_hour(game_state.sex_or_default(), game_state.body_age_months, game_state.weight_kg, mety)
		before = _snapshot(game_state)
		activities.start("exercise", option_id)
		while activities.elapsed_hours < 0.5:
			clock._process(STEP_SECONDS)
		var done: float = activities.elapsed_hours
		activities.stop()
		_check("%s stopped halfway: about 0.5 h done" % option_id, absf(done - 0.5) < 0.05)
		print("  %s stopped at %.2f h: +%.1f kcal (expected %.1f)" % [option_id, done, game_state.calories_spent - before["calories_spent"], kcal * done])
		_check("%s stopped halfway: calories spent are in proportion" % option_id, absf(game_state.calories_spent - (before["calories_spent"] + kcal * done)) < 1.0)
	clock.debug_speed = 600.0


## Entertainment has Screens and Football (decision 4), one hour each, with no per-hour effect
## on the mental measure: screens are logged as screen time, and mood changes once per avatar day.
func _test_entertainment(activities: Node, game_state: Node, clock: Node, _save_game: Node) -> void:
	var option: Dictionary = activities.get_option("entertainment", "screens")
	var football: Dictionary = activities.get_option("entertainment", "football")
	_check("entertainment has Screens and Football", activities.definitions.get("entertainment", {}).get("options", {}).keys() == ["screens", "football"])
	_check("both last 1 avatar hour", is_equal_approx(float(option.get("duration_hours", 0)), 1.0) and is_equal_approx(float(football.get("duration_hours", 0)), 1.0))
	_check("screens METy 1.3, football 7.5 and moderate-to-vigorous", activities.option_value(option, "mety") == 1.3
			and activities.option_value(football, "mety") == 7.5 and activities.option_value(football, "activity_intensity") == "moderate_vigorous")
	_check("entertainment has no per-hour effects", option.get("effects_per_hour", {}).is_empty())
	game_state.reset()
	var habits: Node = root.get_node("Habits")
	var logged_before: int = habits.entries.size()
	var mental_before: float = game_state.mental
	clock.debug_speed = 600.0
	_check("screens start", activities.start("entertainment", "screens"))
	while activities.is_running():
		clock._process(STEP_SECONDS)
	_check("mental does not change during entertainment", is_equal_approx(game_state.mental, mental_before))
	_check("screens are logged", habits.entries.size() == logged_before + 1 and habits.entries[-1]["type"] == "screens")


func _snapshot(game_state: Node) -> Dictionary:
	return {"calories_spent": game_state.calories_spent, "muscle": game_state.muscle, "physical": game_state.physical}


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
