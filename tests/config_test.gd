extends SceneTree
## Tests for the config (Milestone 4, Task 1). Run from the project folder:
##   Godot --headless --path . -s res://tests/config_test.gd
## Checks the health block, that no health number is left in the health scripts, and
## that reloading a changed config file changes the next day's calculation.
## Uses a copy of the config in user://, so data/config.json is never changed.

const TEST_CONFIG := "user://test_config.json"
## The health scripts that must not hold any game number.
const HEALTH_SCRIPTS := ["res://scripts/autoload/game_state.gd", "res://scripts/autoload/habits.gd"]
## Keys MILESTONE_4.md asks for in the health block.
const REQUIRED_KEYS := ["k", "death_enabled", "habit_days_to_95", "habit_cost.T", "habit_cost.alpha",
		"habit_cost.gamma", "habit_cost.P_max", "habit_cost.lambda", "score_window", "k_applies_to_sleep_debt",
		"sleep_range.child", "sleep_range.teenager", "sleep_recommended.child", "sleep_recommended.teenager",
		"sleep_zero_at", "sleep_over_penalty_per_h", "r", "debt_max", "activity_target_min", "strength_days_target",
		"screens_full_until_h", "screens_zero_at_h", "enjoyment_full_at_h", "mood_speed", "fitness_k_down",
		"fitness_k_up", "muscle_k_up", "muscle_k_down", "weight_score.full_within_z", "weight_score.zero_at_z",
		"physical_mix.fitness", "physical_mix.muscle", "physical_mix.weight", "combine.p",
		"combine.weights.physical", "combine.weights.mental", "combine.weights.sleep", "alpha_bar"]
const ACTIVE_DAY := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 1.0}

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var config: Node = root.get_node("Config")
	var gs: Node = root.get_node("GameState")

	_test_health_block(config)
	_test_no_numbers_in_scripts()
	_test_reload(config, gs)

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_health_block(config: Node) -> void:
	var missing: Array = []
	for key in REQUIRED_KEYS:
		var entry: Variant = _entry(config._data["health"], key)
		if not entry is Dictionary or not entry.has("value") or not entry.has("status") or not entry.has("owner"):
			missing.append(key)
	if not missing.is_empty():
		print("  missing or without status/owner: " + str(missing))
	_check("every Milestone 4 key is in the health block with value, status and owner", missing.is_empty())
	_check("k is 5 (team decision)", config.get_float("health.k") == 5.0)
	_check("alpha_bar is 0.37", is_equal_approx(config.get_float("health.alpha_bar"), 0.37))
	_check("there is no death", config.get_value("health.death_enabled") == false)
	_check("habit_cost.alpha and alpha_bar are separate keys",
			config.get_float("health.habit_cost.alpha") != config.get_float("health.alpha_bar"))
	var statuses_ok := true
	for difficulty in ["easy", "normal", "hard", "very_hard"]:
		var block: Dictionary = config._data["health"]["difficulties"][difficulty]
		statuses_ok = statuses_ok and block.has("status") and block.has("owner") and block.has("start_R")
	_check("each difficulty has start_R, status and owner", statuses_ok)
	_check("start_R: Easy 0.5, Normal 0.5, Hard 0.2, Very hard 0.8",
			config.get_float("health.difficulties.easy.start_R") == 0.5 and config.get_float("health.difficulties.normal.start_R") == 0.5
			and config.get_float("health.difficulties.hard.start_R") == 0.2 and config.get_float("health.difficulties.very_hard.start_R") == 0.8)
	_check("a placeholder status counts as a placeholder", config.is_placeholder("health.r") and not config.is_placeholder("health.k"))
	var activities: Node = root.get_node("Activities")
	var cardio: Dictionary = activities.get_option("exercise", "cardio")
	var strength: Dictionary = activities.get_option("exercise", "strength")
	_check("kcal_per_hour: cardio 300, muscle strength 200", activities.option_value(cardio, "kcal_per_hour") == 300.0
			and activities.option_value(strength, "kcal_per_hour") == 200.0)


## Any number other than 0 and 1 outside comments and strings is reported.
func _test_no_numbers_in_scripts() -> void:
	var number := RegEx.create_from_string("(?<![\\w.])\\d+(\\.\\d+)?(?![\\w.])")
	var text_in_quotes := RegEx.create_from_string("\"[^\"]*\"")
	var found: Array = []
	for path in HEALTH_SCRIPTS:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var code := text_in_quotes.sub(lines[i].split("#")[0], "\"\"", true)
			for m in number.search_all(code):
				if not m.get_string() in ["0", "1", "0.0", "1.0"]:
					found.append("%s:%d %s" % [path.get_file(), i + 1, m.get_string()])
	if not found.is_empty():
		print("  numbers found: " + str(found))
	_check("no game number in the health scripts", found.is_empty())


## Changing k in the file and reloading changes the next day's calculation.
func _test_reload(config: Node, gs: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	var start: float = gs.fitness
	gs.update_body_states(ACTIVE_DAY, 10.0)
	var gain_k5: float = gs.fitness - start

	var data: Dictionary = config._data.duplicate(true)
	data["health"]["k"]["value"] = 1
	var file := FileAccess.open(TEST_CONFIG, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var reloaded := [false]
	config.reloaded.connect(func() -> void: reloaded[0] = true)
	config.config_path = TEST_CONFIG
	config.reload()
	_check("reload reads the changed file", reloaded[0] and config.get_float("health.k") == 1.0)
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.update_body_states(ACTIVE_DAY, 10.0)
	var gain_k1: float = gs.fitness - start
	print("  fitness gain in one day: k = 5 -> %.4f, k = 1 -> %.4f" % [gain_k5, gain_k1])
	_check("with k = 1 after reload, the next day changes less", gain_k1 < gain_k5 and gain_k1 > 0.0)

	config.config_path = config.CONFIG_PATH
	config.reload()
	DirAccess.remove_absolute(TEST_CONFIG)
	_check("the real config is back (k = 5)", config.get_float("health.k") == 5.0)


## The entry at a dotted path inside a dictionary, or null.
func _entry(data: Dictionary, path: String) -> Variant:
	var node: Variant = data
	for key in path.split("."):
		if not node is Dictionary or not node.has(key):
			return null
		node = node[key]
	return node


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
