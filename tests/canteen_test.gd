extends SceneTree
## The canteen (Milestone 21, decisions 61 to 64). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/canteen_test.gd
## A plate does not change the health model: a plate of only healthy (or bad) foods is exactly
## today's healthy (or fast-food) meal, and a mixed plate counts by share. Nothing is saved.

const STEP_SECONDS := 0.1
const TOLERANCE := 0.000001

var _failures := 0
var gs: Node
var clock: Node
var activities: Node
var canteen: GDScript


func _process(_delta: float) -> bool:
	gs = root.get_node("GameState")
	clock = root.get_node("Clock")
	activities = root.get_node("Activities")
	canteen = load("res://scripts/health/canteen.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_canteen_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://test_canteen_settings.json"
	settings.use_web_storage = false
	settings.set_language("en")
	_test_foods()
	_test_same_as_meals()
	_test_mixed_plate()
	_test_saved_plate(save_game)
	_test_screen()
	DirAccess.remove_absolute("user://test_canteen_save.json")
	DirAccess.remove_absolute("user://test_canteen_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _test_foods() -> void:
	var healthy: Array[String] = canteen.foods(true)
	var bad: Array[String] = canteen.foods(false)
	_check("many examples: %d healthy and %d bad foods" % [healthy.size(), bad.size()], healthy.size() >= 8 and bad.size() >= 8)
	_check("healthy foods count as the healthy meal, bad foods as the fast-food meal",
			canteen.meal_for(healthy[0]) == "healthy_meal" and canteen.meal_for(bad[0]) == "fast_food_meal")
	_check("a plate holds up to 4 foods (decision 64)", root.get_node("Config").get_int("canteen.plate_max") == 4)
	var parts: Array = canteen.parts([healthy[0], healthy[1], healthy[2], bad[0]])
	_check("3 healthy and 1 bad: 3/4 healthy meal and 1/4 fast-food meal",
			parts == [["healthy_meal", 0.75], ["fast_food_meal", 0.25]])
	_check("the meal it is eaten as: the larger part; a tie is healthy",
			canteen.meal_option([bad[0], bad[1], healthy[0]]) == "fast_food_meal"
			and canteen.meal_option([bad[0], healthy[0]]) == "healthy_meal")


func _new_avatar() -> void:
	activities.reset()
	root.get_node("Habits").reset()
	root.get_node("Simulation").reset()
	gs.reset()
	clock.reset()
	gs.start_new_avatar("Test", "child", "female", "normal")
	clock.debug_speed = 600.0


## Eats until the meal ends and returns the state the meal changes.
func _eat(start: Callable) -> Dictionary:
	_new_avatar()
	start.call()
	while activities.is_running():
		clock._process(STEP_SECONDS)
	clock._process(STEP_SECONDS)
	return {"hunger": gs.hunger, "weight": gs.weight_kg, "Q": gs.diet_quality, "C": gs.craving, "A": gs.habituation,
			"happiness": gs.happiness}


func _same(a: Dictionary, b: Dictionary) -> bool:
	for key in a:
		if absf(float(a[key]) - float(b[key])) > TOLERANCE:
			print("    %s: %f against %f" % [key, a[key], b[key]])
			return false
	return true


func _test_same_as_meals() -> void:
	var healthy_meal := _eat(func() -> void: activities.start("eat", "healthy_meal"))
	var healthy_plate := _eat(func() -> void: activities.start_plate(["apple", "salad", "rice"]))
	_check("a plate of only healthy foods is exactly today's healthy meal", _same(healthy_meal, healthy_plate))
	var fast_meal := _eat(func() -> void: activities.start("eat", "fast_food_meal"))
	var bad_plate := _eat(func() -> void: activities.start_plate(["burger", "fries"]))
	_check("a plate of only bad foods is exactly today's fast-food meal", _same(fast_meal, bad_plate))


func _test_mixed_plate() -> void:
	var mixed := _eat(func() -> void: activities.start_plate(["apple", "salad", "rice", "burger"]))
	var healthy_meal := _eat(func() -> void: activities.start("eat", "healthy_meal"))
	var fast_meal := _eat(func() -> void: activities.start("eat", "fast_food_meal"))
	_check("a mixed plate is between the two meals: diet quality", mixed["Q"] < healthy_meal["Q"] and mixed["Q"] > fast_meal["Q"])
	_check("...and weight", mixed["weight"] > healthy_meal["weight"] and mixed["weight"] < fast_meal["weight"])
	_check("...closer to the healthy meal (3 of 4 foods)",
			absf(mixed["Q"] - healthy_meal["Q"]) < absf(mixed["Q"] - fast_meal["Q"]))


func _test_saved_plate(save_game: Node) -> void:
	_new_avatar()
	activities.start_plate(["apple", "burger"])
	save_game.save_game()
	activities.reset()
	save_game.load_game()
	_check("a plate in the middle of a meal is saved and loads", activities.plate == ["apple", "burger"]
			and activities.current_option == "healthy_meal")
	activities.stop()
	_check("the plate goes when the meal ends", activities.plate.is_empty())
	activities.start("exercise", "cardio")
	_check("an activity that is not a plate has none", activities.plate.is_empty())
	activities.stop()


func _test_screen() -> void:
	_new_avatar()
	clock.debug_speed = 1.0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var screen: Node = main.canteen
	main.eat_button.pressed.emit()
	_check("Eat opens the canteen with an empty plate", screen.visible and screen.plate.is_empty() and screen.eat_button.disabled)
	_check("two choosers with every food", screen.healthy_grid.get_child_count() == canteen.foods(true).size()
			and screen.bad_grid.get_child_count() == canteen.foods(false).size())
	for id in ["apple", "salad", "burger", "fries", "pizza"]:
		screen.add_food(id)
	_check("up to 4 foods: the fifth does not fit", screen.plate == ["apple", "salad", "burger", "fries"]
			and screen.healthy_grid.get_child(0).disabled)
	screen.remove_at(1)
	_check("a tap on the plate takes a food off", screen.plate == ["apple", "burger", "fries"]
			and screen.plate_label.text == "Your plate (3 of 4)")
	_check("Skip meal only when hungry", screen.skip_button.visible == root.get_node("Simulation").Hunger.is_hungry())
	screen.eat_button.pressed.emit()
	_check("Eat the plate: the meal runs with the plate, as the larger part (fast food)",
			not screen.visible and activities.current_option == "fast_food_meal" and activities.plate == ["apple", "burger", "fries"])
	activities.stop()
	root.remove_child(main)
	main.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
