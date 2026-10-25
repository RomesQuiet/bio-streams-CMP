extends SceneTree
## Tests for energy, weight and body size (Milestone 10, Task 4). Run from the project folder:
##   Godot --headless --path . -s res://tests/energy_test.gd
## Checks the energy of a guideline day and an inactive day (v1 Step 3), weight going up with
## fast food and down with healthy food (v1 Step 5), the body ageing and its cap, z from
## weight and height, the weight score w(z), the calories-spent record and the energy
## deficit penalty U. Uses a test save path; the real save is never touched.

const TOLERANCE := 0.001

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this
## test script is compiled.
var energy: GDScript
var body_size: GDScript
var who: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	energy = load("res://scripts/health/energy.gd")
	body_size = load("res://scripts/health/body_size.gd")
	who = load("res://scripts/health/who_tables.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_daily_energy()
	_test_weight_with_food()
	_test_body_size()
	_test_weight_score()
	_test_calories_record()
	_test_deficit()

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## v1 Step 3: for the boy of 10 on Normal (36.0 kg), a guideline day costs about 2,100 kcal
## (10.5 h sleep, 70 min cardio, 1 h screens, the rest idle) and an inactive day about 1,800.
func _test_daily_energy() -> void:
	var weight: float = who.weight_from_z("male", 120.0, 1.2)
	var per_hour := func(mety: float) -> float: return energy.kcal_per_hour("male", 120.0, weight, mety)
	var awake := 24.0 - 10.5
	var inactive: float = 10.5 * per_hour.call(0.95) + awake * per_hour.call(1.7)
	var cardio_h := 70.0 / 60.0
	var guideline: float = 10.5 * per_hour.call(0.95) + cardio_h * per_hour.call(7.0) + 1.0 * per_hour.call(1.3) \
			+ (awake - cardio_h - 1.0) * per_hour.call(1.7)
	print("  boy 10 y, 36.0 kg: guideline day %.0f kcal (v1: about 2,100), inactive day %.0f kcal (v1: about 1,800)" % [guideline, inactive])
	_check("a guideline day costs about 2,100 kcal (within 5%)", absf(guideline / 2100.0 - 1.0) < 0.05)
	_check("an inactive day costs about 1,800 kcal (within 5%)", absf(inactive / 1800.0 - 1.0) < 0.05)
	_check("sleep never changes the metabolic rate (same BMR asleep or awake)",
			is_equal_approx(per_hour.call(0.95) / 0.95, per_hour.call(1.7) / 1.7))


## v1 Step 5: weight goes up with fast food at every meal and no sport, and down with healthy
## food and 1 h of cardio a day. Plays 3 avatar days through the real game loop.
func _test_weight_with_food() -> void:
	var gs := _new_avatar("male", "child", "normal")
	var start_weight: float = gs.weight_kg
	var start_z: float = gs.weight_z
	for day in 3:
		_play_day("fast_food_meal", false)
	var fast_food_gain: float = gs.weight_kg - start_weight
	print("  3 days, fast food and no sport: %+.2f kg, z %+.2f -> %+.2f" % [fast_food_gain, start_z, gs.weight_z])
	_check("fast food at every meal and no sport: weight goes up", fast_food_gain > 0.5)
	_check("...and BMI-for-age z goes up", gs.weight_z > start_z)

	gs = _new_avatar("male", "child", "normal")
	for day in 3:
		_play_day("healthy_meal", true)
	var healthy_change: float = gs.weight_kg - start_weight
	print("  3 days, healthy food and 1 h cardio: %+.2f kg, z %+.2f -> %+.2f" % [healthy_change, start_z, gs.weight_z])
	_check("healthy food and 1 h of cardio a day: weight goes down", healthy_change < 0.0)
	_check("...and BMI-for-age z goes down (the body also grows)", gs.weight_z < start_z)
	_check("one healthy day of energy balance never gives a deficit penalty", gs.deficit_u == 0.0)


## v1 Step 2: body age += k x hours / 8,760 years, stopping at the end of the age group;
## height = WHO median; z from weight / height².
func _test_body_size() -> void:
	var gs := _new_avatar("female", "child", "easy")
	var age: float = gs.body_age_months
	body_size.step(24.0, false)
	var expected := age + 10.0 * 24.0 / 8760.0 * 12.0
	_check("one avatar day ages the body by k x 24 h = 10 days (0.33 months)", absf(gs.body_age_months - expected) < TOLERANCE)
	_check("height is the WHO median for the new age", is_equal_approx(gs.height_m, who.median_height_m("female", gs.body_age_months)))
	gs.body_age_months = 154.99
	body_size.step(24.0, false)
	_check("a child stops at 12 years 11 months (155 months)", gs.body_age_months == 155.0)
	gs.age_group = "teenager"
	gs.body_age_months = 226.99
	body_size.step(24.0, false)
	_check("a teenager stops at 18 years 11 months (227 months)", gs.body_age_months == 227.0)
	gs.weight_kg = who.weight_from_z("female", 227.0, 2.0)
	body_size.step(0.0, false)
	_check("z comes from weight and height (weight at z +2 gives z +2)", absf(gs.weight_z - 2.0) < TOLERANCE)
	_check("BMI = weight / height²", is_equal_approx(body_size.bmi(40.0, 1.6), 15.625))


## v1 Step 2: w(z) = 1 for z between -2 and +1; 0.5 at +2, 0.1 at +3, 0 at +4; 0.3 at -3, 0 at -4.
func _test_weight_score() -> void:
	var cases := [[-5.0, 0.0], [-4.0, 0.0], [-3.5, 0.15], [-3.0, 0.3], [-2.0, 1.0], [0.0, 1.0], [1.0, 1.0],
			[1.5, 0.75], [2.0, 0.5], [3.0, 0.1], [3.5, 0.05], [4.0, 0.0], [5.0, 0.0]]
	var all_ok := true
	for case in cases:
		var w: float = body_size.weight_score(case[0])
		if absf(w - case[1]) > TOLERANCE:
			all_ok = false
			print("  w(%+.1f) = %.3f, expected %.3f" % [case[0], w, case[1]])
	_check("weight score w(z) at the v1 points and between them", all_ok)


## The calories-spent record grows only while exercising (moderate-to-vigorous activities).
func _test_calories_record() -> void:
	var gs := _new_avatar("male", "teenager", "normal")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	_idle_until(clock, 1.0)
	_check("no calories in the record after an idle hour", gs.calories_spent == 0.0)
	activities.start("entertainment", "screens")
	_run(clock, activities)
	_check("no calories in the record after screens", gs.calories_spent == 0.0)
	# The weight goes down a little while playing, so BMR does too: use the average of the
	# BMR at the start and at the end of the hour.
	var at_start: float = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7.5)
	activities.start("entertainment", "football")
	_run(clock, activities)
	var football: float = (at_start + energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7.5)) / 2.0
	print("  1 h of football: %.0f kcal in the record (BMR / 24 x 7.5 = %.0f)" % [gs.calories_spent, football])
	_check("1 h of football adds BMR / 24 x 7.5 to the record", absf(gs.calories_spent - football) < 1.0)


## U = 0 below a 30% deficit, 1 at 60%, a straight line between. A new avatar starts in
## balance (U 0); a whole avatar day without food gives U 1.
func _test_deficit() -> void:
	_check("eating more than spent: U 0", energy.deficit_penalty(2500.0, 2000.0) == 0.0)
	_check("deficit 30%: U 0", is_zero_approx(energy.deficit_penalty(1400.0, 2000.0)))
	_check("deficit 45%: U 0.5", absf(energy.deficit_penalty(1100.0, 2000.0) - 0.5) < TOLERANCE)
	_check("deficit 60%: U 1", is_equal_approx(energy.deficit_penalty(800.0, 2000.0), 1.0))
	_check("deficit 90%: U 1", is_equal_approx(energy.deficit_penalty(200.0, 2000.0), 1.0))
	var gs := _new_avatar("female", "child", "normal")
	_check("a new avatar starts in energy balance (U 0)", gs.deficit_u == 0.0
			and is_equal_approx(energy.window_total("eaten"), energy.window_total("spent")))
	var clock: Node = root.get_node("Clock")
	_idle_until(clock, 6.0)
	var u_after_6h: float = gs.deficit_u
	_idle_until(clock, 14.0 - 0.01)
	gs.hours_awake = 14.0
	root.get_node("Activities").start("sleep", "sleep", 10.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	print("  no food: U %.2f after 6 h, %.2f after 24 h (eaten %.0f, spent %.0f kcal in 24 h)" % [u_after_6h, gs.deficit_u,
			energy.window_total("eaten"), energy.window_total("spent")])
	# The day ends a moment before 24 h, so a sliver of the first hour is still in the window.
	_check("after a whole avatar day without food U is 1", is_equal_approx(gs.deficit_u, 1.0)
			and energy.window_total("eaten") < 0.01 * energy.window_total("spent"))
	clock.wake_up()


## Plays one avatar day: 4 meals of this food (at 0, 4, 8 and 12 h awake), 1 h of cardio at
## 2 h if exercise, then a 10 h sleep.
func _play_day(food: String, exercise: bool) -> void:
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	for meal_hour in [0.0, 4.0, 8.0, 12.0]:
		_idle_until(clock, meal_hour)
		activities.start("eat", food)
		_run(clock, activities)
		if exercise and meal_hour == 0.0:
			_idle_until(clock, 2.0)
			activities.start("exercise", "cardio")
			_run(clock, activities)
	_idle_until(clock, clock.day_length_hours - 0.01)
	activities.start("sleep", "sleep", 10.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	clock.wake_up()


func _idle_until(clock: Node, day_hours: float) -> void:
	clock.debug_speed = 600.0
	while clock.day_elapsed_hours < day_hours:
		clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(day_hours - clock.day_elapsed_hours, false) / 600.0 + 1e-6))


func _run(clock: Node, activities: Node) -> void:
	clock.debug_speed = 600.0
	while activities.is_running():
		clock._process(0.05)
	root.get_node("Simulation").flush()


func _new_avatar(sex: String, group: String, difficulty: String) -> Node:
	root.get_node("Activities").reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	var gs: Node = root.get_node("GameState")
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", group, sex, difficulty)
	return gs


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
