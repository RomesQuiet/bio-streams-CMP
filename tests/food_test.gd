extends SceneTree
## Tests for food as an activity (Milestone 10, Task 3). Run from the project folder:
##   Godot --headless --path . -s res://tests/food_test.gd
## Checks the healthy portion, how fast hunger grows (awake, asleep, with sleep debt, below
## the median weight, while exercising), the two meals, Stop halfway, the hungry message
## rules, Skip, the meal log and saving. Uses a test save path; the real save is never touched.

const TOLERANCE := 0.01
## Weight changes every step (k = 10), so BMR drifts a little within an hour: within 1 kcal.
const GROWTH_TOLERANCE := 1.0

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this
## test script is compiled.
var energy: GDScript
var hunger: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	energy = load("res://scripts/health/energy.gd")
	hunger = load("res://scripts/health/hunger.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_portion()
	_test_hunger_growth()
	_test_meals()
	_test_hungry_message()
	_test_log_and_save(save_game)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## v1 Step 4: reference = BMR at the healthy weight x 1.6; healthy portion = reference / 4.
## Boy of 10: healthy weight 31.2 kg, BMR 17.686 x 31.2 + 658.2 = 1210 kcal, reference
## about 1936 kcal, portion about 484 kcal. A fast-food meal is 1.3 portions.
func _test_portion() -> void:
	var weight: float = energy.healthy_weight_kg("male", 120.0)
	var bmr: float = energy.bmr("male", 120.0, weight)
	var reference: float = energy.reference_kcal_per_day("male", 120.0)
	print("  boy 10 y: healthy weight %.1f kg, BMR %.0f kcal/day, reference %.0f, portion %.0f" % [weight, bmr, reference, reference / 4.0])
	_check("Schofield BMR for a boy of 10 at 31.2 kg is about 1210 kcal", absf(bmr - (17.686 * weight + 658.2)) < TOLERANCE and absf(bmr - 1210.0) < 2.0)
	_check("reference = BMR x 1.6", is_equal_approx(reference, bmr * 1.6))
	_check("a girl of 8 uses the 3 to 10 years equation", is_equal_approx(energy.bmr("female", 96.0, 25.0), 20.315 * 25.0 + 485.9))
	var gs := _new_avatar("male", "child", "normal")
	_check("healthy portion = reference / 4", absf(hunger.healthy_portion_kcal() - reference / 4.0) < TOLERANCE)
	_check("a fast-food meal is 1.3 healthy portions", is_equal_approx(hunger.meal_kcal("fast_food_meal", 1.0), 1.3 * hunger.healthy_portion_kcal()))
	_check("a new avatar is ready for breakfast (hungry)", hunger.is_hungry() and gs.hunger > 0.0)


## Hunger grows by (0.7 x reference / 24 x hours + 0.3 x kcal spent) x sleep boost x thin boost.
func _test_hunger_growth() -> void:
	var gs := _new_avatar("male", "child", "normal")
	var clock: Node = root.get_node("Clock")
	var reference: float = energy.reference_kcal_per_day("male", gs.body_age_months)
	var idle_kcal: float = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7)
	gs.sleep_debt = 0.0
	var start: float = gs.hunger
	_play_hours(clock, 1.0)
	var expected := 0.7 * reference / 24.0 + 0.3 * idle_kcal
	print("  1 h awake, idle: hunger +%.1f kcal (expected %.1f)" % [gs.hunger - start, expected])
	_check("1 h awake with no activity: hunger grows by the v1 formula", absf(gs.hunger - start - expected) < GROWTH_TOLERANCE)

	gs.sleep_debt = 8.0  # d = 1: appetite x 1.2
	start = gs.hunger
	_play_hours(clock, 1.0)
	_check("with full sleep debt hunger grows 20% faster", absf(gs.hunger - start - expected * 1.2) < GROWTH_TOLERANCE)

	gs.sleep_debt = 0.0
	# Below the median: x (1 + 0.15 x 2). z comes from the weight, so set the weight.
	gs.weight_kg = load("res://scripts/health/who_tables.gd").weight_from_z("male", gs.body_age_months, -2.0)
	gs.weight_z = -2.0
	var expected_thin: float = 0.7 * reference / 24.0 + 0.3 * energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7)
	start = gs.hunger
	_play_hours(clock, 1.0)
	_check("2 SD below the median, hunger grows 30% faster", absf(gs.hunger - start - expected_thin * 1.3) < GROWTH_TOLERANCE)
	gs.weight_kg = load("res://scripts/health/who_tables.gd").weight_from_z("male", gs.body_age_months, 1.0)
	gs.weight_z = 1.0
	expected = 0.7 * reference / 24.0 + 0.3 * energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7)

	# Cardio spends more, so hunger grows faster (only 30% follows the spending).
	var activities: Node = root.get_node("Activities")
	start = gs.hunger
	var habits: Node = root.get_node("Habits")
	var time_start: float = habits.avatar_hours_total
	activities.start("exercise", "cardio")
	while activities.is_running():
		clock._process(0.1)
	root.get_node("Simulation").flush()
	# The last frame went a little past the end of the cardio: those minutes are idle.
	var idle_after: float = habits.avatar_hours_total - time_start - 1.0
	var cardio_kcal: float = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7.0)
	var expected_cardio := 0.7 * reference / 24.0 + 0.3 * cardio_kcal + idle_after * expected
	print("  1 h cardio: hunger +%.1f kcal (expected %.1f)" % [gs.hunger - start, expected_cardio])
	_check("1 h of cardio: hunger grows with the extra energy spent", absf(gs.hunger - start - expected_cardio) < GROWTH_TOLERANCE)

	# Hunger grows during sleep too.
	gs.hours_awake = 6.0
	start = gs.hunger
	activities.start("sleep", "sleep", 2.0)
	while clock.phase == clock.Phase.SLEEPING:
		clock._process(0.1)
	var sleep_kcal: float = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 0.95)
	_check("hunger grows during a 2 h sleep", absf(gs.hunger - start - 2.0 * (0.7 * reference / 24.0 + 0.3 * sleep_kcal)) < 1.0)
	_check("the avatar cannot eat while asleep (only after waking)", not activities.can_start("eat"))
	clock.wake_up()
	_check("after waking it can eat", activities.can_start("eat"))


## A meal takes 0.5 avatar hours and removes kcal x satiety from hunger when it ends.
func _test_meals() -> void:
	var gs := _new_avatar("female", "child", "normal")
	var activities: Node = root.get_node("Activities")
	var clock: Node = root.get_node("Clock")
	var portion: float = hunger.healthy_portion_kcal()
	for food in [["healthy_meal", 1.0, 1.0], ["fast_food_meal", 1.3, 0.83]]:
		gs.hunger = 2.0 * portion
		var growth_during_meal: float = _hunger_after_meal(activities, clock, food[0], gs) - 2.0 * portion
		var taken: float = food[1] * food[2] * portion
		_check("%s takes %.2f portions off hunger" % [food[0], food[1] * food[2]],
				absf(gs.hunger - (2.0 * portion + growth_during_meal - taken)) < GROWTH_TOLERANCE)
	_check("a meal lasts 0.5 avatar hours", is_equal_approx(float(activities.get_option("eat", "healthy_meal")["duration_hours"]), 0.5))
	_check("fast food fills less per kcal than healthy food", 1.3 * 0.83 < 1.3)

	# Stop halfway: half of the meal.
	gs.hunger = 2.0 * portion
	var before: float = gs.hunger
	clock.debug_speed = 10.0
	activities.start("eat", "healthy_meal")
	while activities.elapsed_hours < 0.25:
		clock._process(0.1)
	var share: float = activities.elapsed_hours / 0.5
	activities.stop()
	# Hunger also grew a little during the quarter hour of eating.
	var growth: float = hunger.growth(share * 0.5, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.5) * share * 0.5)
	var eaten: float = before + growth - gs.hunger
	print("  stopped at %.0f%% of a healthy meal: ate %.0f kcal (that share of a portion = %.0f)" % [share * 100.0, eaten, share * portion])
	_check("stopping halfway eats that share of the meal", absf(eaten - share * portion) < 1.0)
	clock.debug_speed = 600.0


## Plays a whole meal and returns how much hunger would be without the meal (start + growth).
func _hunger_after_meal(activities: Node, clock: Node, food: String, gs: Node) -> float:
	var start: float = gs.hunger
	var habits: Node = root.get_node("Habits")
	var time_start: float = habits.avatar_hours_total
	clock.debug_speed = 30.0
	activities.start("eat", food)
	while activities.is_running():
		clock._process(0.1)
	root.get_node("Simulation").flush()
	var idle_after: float = habits.avatar_hours_total - time_start - 0.5
	var growth: float = hunger.growth(0.5, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.5) * 0.5) \
			+ hunger.growth(idle_after, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.7) * idle_after)
	return start + growth


## "I'm hungry!" needs hunger of at least 0.8 healthy meals and 2 avatar hours since the
## last meal or skip. Skip works only when hungry.
func _test_hungry_message() -> void:
	var gs := _new_avatar("female", "teenager", "normal")
	var portion: float = hunger.healthy_portion_kcal()
	gs.hours_since_meal = 3.0
	gs.hunger = 0.79 * portion
	_check("0.79 meals of hunger: not hungry", not hunger.is_hungry())
	gs.hunger = 0.8 * portion
	_check("0.8 meals of hunger and 3 h since a meal: hungry", hunger.is_hungry())
	gs.hours_since_meal = 1.9
	gs.hunger = 3.0 * portion
	_check("very hungry but only 1.9 h since a meal: not hungry yet", not hunger.is_hungry())
	gs.hours_since_meal = 2.0
	_check("2 h since a meal: hungry", hunger.is_hungry())
	_check("skip works when hungry", hunger.skip())
	_check("after a skip the hunger stays", is_equal_approx(gs.hunger, 3.0 * portion))
	_check("after a skip the 2-hour gap starts again", not hunger.is_hungry() and gs.hours_since_meal == 0.0)
	_check("skip does nothing when not hungry", not hunger.skip())
	# The hungry message after 2 h of play.
	var clock: Node = root.get_node("Clock")
	_play_hours(clock, 2.0)
	_check("2 h after the skip the avatar is hungry again", hunger.is_hungry())


func _test_log_and_save(save_game: Node) -> void:
	var gs := _new_avatar("male", "teenager", "hard")
	var activities: Node = root.get_node("Activities")
	var clock: Node = root.get_node("Clock")
	var habits: Node = root.get_node("Habits")
	activities.start("eat", "fast_food_meal")
	while activities.is_running():
		clock._process(0.1)
	var entry: Dictionary = habits.entries[-1]
	_check("the meal is logged with its type and kcal eaten", entry["type"] == "fast_food_meal"
			and absf(entry["kcal_eaten"] - hunger.meal_kcal("fast_food_meal", 1.0)) < TOLERANCE)
	_check("a teenager's portion is larger than a child's",
			hunger.healthy_portion_kcal() > energy.healthy_portion_kcal("male", 120.0))
	var saved: Dictionary = gs.to_dict()
	save_game.save_game()
	gs.hunger = 0.0
	gs.hours_since_meal = 0.0
	gs.weight_kg = 0.0
	_check("load finds the save", save_game.load_game())
	_check("hunger, time since the meal, weight and body age are restored",
			is_equal_approx(gs.hunger, saved["hunger"]) and is_equal_approx(gs.hours_since_meal, saved["hours_since_meal"])
			and is_equal_approx(gs.weight_kg, saved["weight_kg"]) and is_equal_approx(gs.body_age_months, saved["body_age_months"]))
	print("  teenage boy, Hard: %.1f kg, body age %.0f months" % [gs.weight_kg, gs.body_age_months])


## Plays this many avatar hours awake with no activity, ending on a whole step.
func _play_hours(clock: Node, hours: float) -> void:
	var speed := 60.0
	clock.debug_speed = speed
	var end_hours: float = clock.day_elapsed_hours + hours
	while clock.day_elapsed_hours < end_hours - 1e-9:
		clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(end_hours - clock.day_elapsed_hours, false) / speed))
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
