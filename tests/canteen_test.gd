extends SceneTree
## The canteen (Milestone 21, third version, decisions 65 and 66): good food or fast food, then a
## plate of that kind. Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/canteen_test.gd
## A plate does not change the health model: a good plate is exactly today's healthy meal and a
## fast-food plate exactly today's fast-food meal. Nothing is saved.

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
	var good: Array[String] = canteen.foods(canteen.GOOD)
	var fast: Array[String] = canteen.foods(canteen.FAST_FOOD)
	_check("many examples: %d good foods and %d fast foods" % [good.size(), fast.size()], good.size() >= 8 and fast.size() >= 8)
	# Milestone 40, change 12: the team's lists; every food has its picture.
	_check("10 good foods and the team's 8 fast foods (ice cream in; nuggets, kebab, milkshake out)", good.size() == 10
			and fast == ["burger", "fries", "pizza", "hot_dog", "fried_chicken", "soft_drink", "doughnut", "ice_cream"])
	var missing: Array[String] = []
	for id in good + fast:
		if not ResourceLoader.exists("res://assets/art/food/%s.png" % id):
			missing.append(id)
	_check("every food has its picture %s" % [missing], missing.is_empty())
	_check("good food is the healthy meal, fast food the fast-food meal",
			canteen.meal_for(canteen.GOOD) == "healthy_meal" and canteen.meal_for(canteen.FAST_FOOD) == "fast_food_meal")
	_check("a plate holds up to 4 foods", root.get_node("Config").get_int("canteen.plate_max") == 4)
	_check("a plate is 1 to 4 foods of one kind", canteen.is_plate(good.slice(0, 4)) and not canteen.is_plate(good.slice(0, 5))
			and not canteen.is_plate([]) and not canteen.is_plate([good[0], fast[0]]))


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
	var good_plate := _eat(func() -> void: activities.start_plate(["grilled_fish", "rice", "salad", "water"]))
	_check("a good plate is exactly today's healthy meal", _same(healthy_meal, good_plate))
	var fast_meal := _eat(func() -> void: activities.start("eat", "fast_food_meal"))
	var fast_plate := _eat(func() -> void: activities.start_plate(["burger", "fries"]))
	_check("a fast-food plate is exactly today's fast-food meal", _same(fast_meal, fast_plate))


func _test_mixed_plate() -> void:
	_check("a mixed or empty plate does not start a meal", not activities.start_plate(["apple", "burger"])
			and not activities.start_plate([]) and not activities.is_running())


func _test_saved_plate(save_game: Node) -> void:
	_new_avatar()
	activities.start_plate(["pizza", "soft_drink"])
	save_game.save_game()
	activities.reset()
	save_game.load_game()
	_check("a plate in the middle of a meal is saved and loads", activities.plate == ["pizza", "soft_drink"]
			and activities.current_option == "fast_food_meal")
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
	_check("Eat opens the canteen on the first step: good food or fast food", screen.visible and screen.kind_box.visible
			and not screen.plate_box.visible and screen.fast_button.text == "CANTEEN_FAST")
	_check("Skip meal only when hungry", screen.skip_button.visible == root.get_node("Simulation").Hunger.is_hungry())
	# Milestone 40, change 10: Good food is chosen when it opens; a card only chooses; Continue opens.
	_check("it opens with Good food chosen", screen.good_button.chosen and not screen.fast_button.chosen)
	screen._place_choice_buttons(true)
	_check("with Skip meal, Cancel and Continue move to y 852 and the panel ends at y 962",
			is_equal_approx(screen.continue_button.position.y, 852.0) and is_equal_approx(screen._choice_bottom, 962.0))
	screen._place_choice_buttons(false)
	_check("without it, at y 760, and the panel ends at y 870", not screen.skip_button.visible
			and is_equal_approx(screen.continue_button.position.y, 760.0) and is_equal_approx(screen._choice_bottom, 870.0))
	screen.fast_button.pressed.emit()
	_check("a card only chooses", screen.fast_button.chosen and not screen.good_button.chosen and screen.kind_box.visible)
	screen.good_button.pressed.emit()
	screen.continue_button.pressed.emit()
	_check("Good food: build a plate from the good foods only", screen.plate_box.visible and screen.good_grid.visible
			and not screen.fast_grid.visible and screen.good_grid.get_child_count() == canteen.foods(canteen.GOOD).size()
			and screen.plate.is_empty() and screen.eat_button.disabled)
	# Milestone 40, change 11: 10 good foods in 5 columns of 118 (x 45 + 128 per column, rows y 306
	# and 502); the plate's places at x 96, 232, 368, 504 and y 822; a food on the plate is chosen.
	var fifth: Control = screen.good_grid.get_child(4)
	var sixth: Control = screen.good_grid.get_child(5)
	_check("good food: 5 columns, the table's places", is_equal_approx(fifth.position.x, 557.0) and is_equal_approx(fifth.size.x, 118.0)
			and is_equal_approx(sixth.position.y, 502.0) and is_equal_approx(screen.plate_row.get_child(3).position.x, 504.0))
	screen.add_food("vegetable_soup")
	_check("a food on the plate is chosen, and shows in the first place", screen.good_grid.get_child(0).chosen
			and screen.plate_row.get_child(0).food_id == "vegetable_soup" and not screen.eat_button.disabled)
	screen.remove_at(0)
	for id in ["vegetable_soup", "grilled_fish", "rice", "water", "apple"]:
		screen.add_food(id)
	_check("up to 4 foods: the fifth does not fit", screen.plate == ["vegetable_soup", "grilled_fish", "rice", "water"]
			and screen.good_grid.get_child(0).disabled)
	screen.remove_at(0)
	_check("a tap on the plate takes a food off", screen.plate == ["grilled_fish", "rice", "water"]
			and screen.plate_label.text == "Your plate (3 of 4)")
	screen.show_kind("")
	screen.fast_button.pressed.emit()
	screen.continue_button.pressed.emit()
	_check("Back and Fast food: a new, empty plate of fast foods", screen.fast_grid.visible and not screen.good_grid.visible
			and screen.plate.is_empty())
	var fourth: Control = screen.fast_grid.get_child(3)
	_check("8 fast foods: 4 columns of 150 (x 45 + 160 per column)", is_equal_approx(fourth.position.x, 525.0)
			and is_equal_approx(fourth.size.x, 150.0) and is_equal_approx(screen.fast_grid.get_child(4).position.y, 502.0))
	screen.add_food("burger")
	screen.add_food("fries")
	screen.eat_button.pressed.emit()
	_check("Eat the plate: the fast-food meal runs with the plate", not screen.visible
			and activities.current_option == "fast_food_meal" and activities.plate == ["burger", "fries"])
	activities.stop()
	root.remove_child(main)
	main.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
