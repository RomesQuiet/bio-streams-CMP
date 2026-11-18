extends SceneTree
## The canteen (Milestone 21, decisions 61 to 64): good food or bad food, then a dish. Run from
## the project folder (after --import):
##   Godot --headless --path . -s res://tests/canteen_test.gd
## A dish does not change the health model: a good dish is exactly today's healthy meal and a bad
## dish exactly today's fast-food meal. Nothing is saved.

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
	var good: Array[String] = canteen.dishes(true)
	var bad: Array[String] = canteen.dishes(false)
	_check("many examples: %d good and %d bad dishes" % [good.size(), bad.size()], good.size() >= 8 and bad.size() >= 8)
	_check("a good dish is the healthy meal, a bad dish the fast-food meal",
			canteen.meal_for(good[0]) == "healthy_meal" and canteen.meal_for(bad[0]) == "fast_food_meal")


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
	var good_dish := _eat(func() -> void: activities.start_dish("grilled_fish_rice"))
	_check("a good dish is exactly today's healthy meal", _same(healthy_meal, good_dish))
	var fast_meal := _eat(func() -> void: activities.start("eat", "fast_food_meal"))
	var bad_dish := _eat(func() -> void: activities.start_dish("burger_fries"))
	_check("a bad dish is exactly today's fast-food meal", _same(fast_meal, bad_dish))


func _test_mixed_plate() -> void:
	_check("an unknown dish does not start a meal", not activities.start_dish("no_such_dish") and not activities.is_running())


func _test_saved_plate(save_game: Node) -> void:
	_new_avatar()
	activities.start_dish("pizza")
	save_game.save_game()
	activities.reset()
	save_game.load_game()
	_check("a dish in the middle of a meal is saved and loads", activities.dish == "pizza"
			and activities.current_option == "fast_food_meal")
	activities.stop()
	_check("the dish goes when the meal ends", activities.dish.is_empty())
	activities.start("exercise", "cardio")
	_check("an activity that is not a dish has none", activities.dish.is_empty())
	activities.stop()


func _test_screen() -> void:
	_new_avatar()
	clock.debug_speed = 1.0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var screen: Node = main.canteen
	main.eat_button.pressed.emit()
	_check("Eat opens the canteen on the first step: good food or bad food", screen.visible and screen.kind_box.visible
			and not screen.dish_box.visible)
	_check("Skip meal only when hungry", screen.skip_button.visible == root.get_node("Simulation").Hunger.is_hungry())
	screen.good_button.pressed.emit()
	_check("Good food shows only the good dishes", screen.dish_box.visible and screen.good_grid.visible
			and not screen.bad_grid.visible and screen.good_grid.get_child_count() == canteen.dishes(true).size())
	screen.show_kind("")
	screen.bad_button.pressed.emit()
	_check("Bad food shows only the bad dishes", screen.bad_grid.visible and not screen.good_grid.visible
			and screen.bad_grid.get_child_count() == canteen.dishes(false).size())
	screen.bad_grid.get_child(0).pressed.emit()
	_check("a tap on a dish eats it: the fast-food meal, with the dish", not screen.visible
			and activities.current_option == "fast_food_meal" and activities.dish == canteen.dishes(false)[0])
	activities.stop()
	root.remove_child(main)
	main.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
