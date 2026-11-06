extends SceneTree
## The avatar's requests (Milestone 16). Run from the project folder:
##   Godot --headless --path . -s res://tests/requests_test.gd

var _failures := 0
var gs: Node
var requests: GDScript
var hunger: GDScript
var hour_window: GDScript


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	gs = root.get_node("GameState")
	requests = load("res://scripts/health/requests.gd")
	hunger = load("res://scripts/health/hunger.gd")
	hour_window = load("res://scripts/health/hour_window.gd")
	_test_order()
	_test_hunger_requests()
	_test_reactions()
	_test_screens_refused()
	_test_changes_nothing()
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _new_avatar() -> void:
	root.get_node("Activities").reset()
	root.get_node("Minigame").reset()
	root.get_node("Simulation").reset()
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	# A calm avatar: not tired, not hungry, screens just watched, plenty of fun.
	gs.tired = false
	gs.hunger = 0.0
	gs.hours_without_screens = 0.0
	hour_window.add(gs.fun_window, gs.sim_hours, "fun", 1000.0)


func _make_hungry() -> void:
	gs.hunger = 2.0 * hunger.healthy_portion_kcal()
	gs.hours_since_meal = 10.0


func _test_order() -> void:
	_new_avatar()
	_check("a calm avatar asks for nothing", requests.current() == "")
	gs.fun_window = load("res://scripts/health/happiness.gd").starting_window()
	_check("no fun in the last day: it asks for football", requests.current() == "football")
	gs.hours_without_screens = 3.0
	_check("3 hours without screens comes before football", requests.current() == "screens")
	gs.craving = 0.3
	_make_hungry()
	_check("hungry comes before screens", requests.current() == "hungry")
	gs.tired = true
	_check("tired comes first", requests.current() == "tired")
	_check("tired uses the old text", requests.text_key("tired") == "SPEECH_TIRED")
	_check("every request has a text", requests.TEXT_KEYS.size() == 6)


func _test_hunger_requests() -> void:
	_new_avatar()
	_make_hungry()
	gs.craving = 0.8
	_check("high craving: fast food", requests.current() == "fast_food")
	gs.craving = 0.5
	_check("craving at the threshold: fast food", requests.current() == "fast_food")
	gs.craving = 0.1
	_check("low craving: a healthy meal", requests.current() == "healthy")
	gs.craving = 0.3
	_check("in between: hungry", requests.current() == "hungry")


func _test_reactions() -> void:
	_new_avatar()
	gs.craving = 0.8
	_check("fast food with a high craving", requests.meal_reaction("fast_food_meal") == "SPEECH_YES_FAST_FOOD")
	_check("healthy with a high craving", requests.meal_reaction("healthy_meal") == "SPEECH_NOT_AGAIN")
	gs.craving = 0.1
	_check("healthy with a low craving", requests.meal_reaction("healthy_meal") == "SPEECH_JUST_WHAT_I_WANTED")
	_check("fast food with a low craving says nothing", requests.meal_reaction("fast_food_meal") == "")
	gs.craving = 0.3
	_check("in between says nothing", requests.meal_reaction("healthy_meal") == "")
	_check("not a meal", requests.meal_reaction("cardio") == "")
	gs.fitness = 0.2
	_check("unfit: do I have to?", requests.exercise_reaction("cardio") == "SPEECH_DO_I_HAVE_TO")
	gs.fitness = 0.8
	_check("fit: let's go", requests.exercise_reaction("strength") == "SPEECH_LETS_GO")
	_check("football is not exercise here", requests.exercise_reaction("football") == "")


func _test_screens_refused() -> void:
	_new_avatar()
	var refused := []
	var listener := func(wish: String) -> void: refused.append(wish)
	gs.wish_refused.connect(listener)
	gs.hours_without_screens = 3.99
	var happiness: GDScript = load("res://scripts/health/happiness.gd")
	happiness.step(0.05, false)
	_check("4 hours without screens is a refused wish", refused == ["screens"])
	happiness.step(0.05, false)
	_check("only once", refused.size() == 1)
	_check("the request goes away", requests.current() != "screens")
	gs.wish_refused.disconnect(listener)


## Asking changes no value (decision 57).
func _test_changes_nothing() -> void:
	_new_avatar()
	_make_hungry()
	gs.craving = 0.8
	var before: Dictionary = gs.to_dict()
	for _i in 10:
		requests.current()
		requests.meal_reaction("healthy_meal")
		requests.exercise_reaction("cardio")
	_check("asking changes no value", gs.to_dict() == before)


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
