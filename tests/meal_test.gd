extends SceneTree
## The meal minigame (Milestone 15). Run from the project folder:
##   Godot --headless --path . -s res://tests/meal_test.gd

var _failures := 0
var gs: Node
var minigame: Node
var activities: Node
var hunger: GDScript


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	gs = root.get_node("GameState")
	minigame = root.get_node("Minigame")
	activities = root.get_node("Activities")
	hunger = load("res://scripts/health/hunger.gd")
	_test_tummy_model()
	_test_fork()
	_test_meals()
	_test_without_player()
	_test_waiting()
	_test_saving(save_game)
	minigame.detach()
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _new_avatar() -> void:
	minigame.detach()
	activities.reset()
	minigame.reset()
	root.get_node("Simulation").reset()
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Test", "child", "male", "normal")


func _start_meal(option := "healthy_meal") -> void:
	_new_avatar()
	minigame.attach()
	activities.start("eat", option)


func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 0.02)
		root.get_node("Clock")._process(step)
		minigame.advance(step)
		left -= step


## Waits for the fork to reach the mouth (or to leave it) and taps.
func _bite(hit: bool) -> void:
	for _i in 400:
		if minigame.at_mouth() == hit:
			break
		_pass_time(0.01)
	minigame.tap()


func _test_tummy_model() -> void:
	_new_avatar()
	var portion: float = hunger.meal_kcal("healthy_meal", 1.0)
	gs.hunger = 1000.0
	var kcal: float = hunger.eat("healthy_meal", 0.8, 0.8)
	_check("full at 8 of 10 bites: 80% of the kcal", is_equal_approx(kcal, portion * 0.8))
	_check("...and hunger falls as for a whole portion", is_equal_approx(gs.hunger, 1000.0 - portion))
	gs.hunger = 1000.0
	hunger.eat("healthy_meal", 1.0, 0.8)
	_check("eating on to the end gives no more fullness", is_equal_approx(gs.hunger, 1000.0 - portion))
	gs.hunger = 1000.0
	hunger.eat("healthy_meal", 0.4, 0.8)
	_check("stopping early: half as full", is_equal_approx(gs.hunger, 1000.0 - portion * 0.5))
	gs.hunger = 1000.0
	hunger.eat("healthy_meal", 0.6)
	_check("without a minigame nothing changes", is_equal_approx(gs.hunger, 1000.0 - portion * 0.6))


func _test_fork() -> void:
	_start_meal()
	_check("a meal is a session that waits", minigame.kind == "meal" and minigame.is_waiting())
	_check("the fork starts at the mouth", minigame.at_mouth())
	minigame.tap()
	_check("the first tap is a bite", minigame.bites == 1 and not minigame.is_waiting())
	_bite(false)
	_check("a tap away from the mouth drops the food", minigame.bites == 1 and minigame.misses == 1)
	_bite(true)
	_check("a tap at the mouth is a bite", minigame.bites == 2)
	_check("the fork moves", not is_equal_approx(minigame.fork_position(), 0.0) or _moves())
	activities.stop()


func _moves() -> bool:
	var before: float = minigame.fork_position()
	_pass_time(0.2)
	return not is_equal_approx(before, minigame.fork_position())


func _eat_meal(bites: int, done: bool) -> Dictionary:
	_start_meal()
	gs.hunger = 1000.0
	var eaten_before: float = _eaten()
	for _i in bites:
		_bite(true)
	if done:
		minigame.done()
	return {"kcal": _eaten() - eaten_before, "hunger": gs.hunger}


func _eaten() -> float:
	return load("res://scripts/health/energy.gd").window_total("eaten")


func _test_meals() -> void:
	var portion: float = hunger.meal_kcal("healthy_meal", 1.0)
	var full := _eat_meal(8, true)
	print("  8 bites and Done: %.0f kcal (portion %.0f), hunger %.0f" % [full["kcal"], portion, full["hunger"]])
	_check("Done at full: the meal ends", not activities.is_running())
	_check("...with 80% of the kcal", absf(full["kcal"] - portion * 0.8) < 1.0)
	var all := _eat_meal(10, false)
	print("  10 bites: %.0f kcal, hunger %.0f" % [all["kcal"], all["hunger"]])
	_check("the whole portion ends the meal by itself", not activities.is_running())
	_check("eating past full: more kcal", all["kcal"] > full["kcal"] + 1.0)
	_check("...and no less hungry", absf(all["hunger"] - full["hunger"]) < 5.0)
	var early := _eat_meal(4, true)
	_check("stopping early: hungrier", early["hunger"] > full["hunger"] + 100.0)


func _test_without_player() -> void:
	_new_avatar()
	activities.start("eat", "healthy_meal")
	_check("without a player a meal is not a session", not minigame.running)
	activities.reset()


func _test_waiting() -> void:
	_start_meal()
	gs.hunger = 1000.0
	var gap: float = gs.hours_since_meal
	_pass_time(21.0)
	_check("with no bite the meal ends after 20 s", not activities.is_running())
	_check("...and nothing was eaten", gs.hunger >= 1000.0 and gs.hours_since_meal >= gap)


func _test_saving(save_game: Node) -> void:
	_start_meal()
	_bite(true)
	_bite(true)
	_bite(true)
	save_game.save_game()
	minigame.detach()
	activities.reset()
	minigame.reset()
	save_game.load_game()
	minigame.attach()
	_check("a loaded meal goes on, waiting, with its bites", minigame.kind == "meal" and minigame.is_waiting() and minigame.bites == 3)
	minigame.detach()
	activities.reset()
	minigame.reset()
	save_game.delete_save()


func _check(label: String, ok: bool) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		_failures += 1
