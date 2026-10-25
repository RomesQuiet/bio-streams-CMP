extends SceneTree
## Tests for the WHO tables (Milestone 10, Task 1). Run from the project folder:
##   Godot --headless --path . -s res://tests/who_test.gd
## Checks the v1 example row, the z-score round trip (also beyond ±3), the median height
## and the starting weights. Nothing is saved.

## Loaded at run time: the script uses the Config autoload, which does not exist yet
## when this test script is compiled.
var who: GDScript

var _failures := 0


func _process(_delta: float) -> bool:
	who = load("res://scripts/health/who_tables.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false

	_test_v1_example()
	_test_round_trip()
	_test_extension()
	_test_height_and_interpolation()
	_print_starting_weights()

	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## v1 Step 2: boy of 10 years 0 months: L = -1.7407, M = 16.4433, S = 0.10566.
## v1 Normal start for that boy: z +1.2 gives 36.0 kg.
func _test_v1_example() -> void:
	var lms: Dictionary = who.bmi_lms("male", 120.0)
	_check("boy 10 y 0 m: L -1.7407, M 16.4433, S 0.10566", is_equal_approx(lms["L"], -1.7407)
			and is_equal_approx(lms["M"], 16.4433) and is_equal_approx(lms["S"], 0.10566))
	var weight: float = who.weight_from_z("male", 120.0, 1.2)
	print("  boy 10 y, z +1.2: %.2f kg (v1: 36.0)" % weight)
	_check("boy 10 y with z +1.2 weighs about 36.0 kg", absf(weight - 36.0) < 0.1)
	_check("the median BMI has z 0", absf(who.z_from_bmi("male", 120.0, lms["M"])) < 1e-6)


## z -> BMI -> z gives the same z, for both sexes, several ages and z beyond ±3.
func _test_round_trip() -> void:
	var worst := 0.0
	for sex in ["male", "female"]:
		for age in [61.0, 120.0, 155.0, 168.0, 227.0, 140.5]:
			for z in [-4.5, -3.5, -3.0, -2.0, 0.0, 1.2, 2.4, 3.0, 3.2, 4.5]:
				var bmi: float = who.bmi_from_z(sex, age, z)
				worst = maxf(worst, absf(who.z_from_bmi(sex, age, bmi) - z))
	print("  largest round-trip error: %s" % worst)
	_check("z -> BMI -> z round trip (both sexes, 5 to 19 years, z -4.5 to +4.5)", worst < 1e-6)


## Beyond +3 the WHO rule is a straight line: each extra z adds SD3 - SD2 of BMI.
## Also checks that z keeps rising with BMI across +3 and -3 (no jump).
func _test_extension() -> void:
	var sd2: float = who.bmi_from_z("female", 120.0, 2.0)
	var sd3: float = who.bmi_from_z("female", 120.0, 3.0)
	var sd4: float = who.bmi_from_z("female", 120.0, 4.0)
	_check("above +3: SD4 - SD3 = SD3 - SD2", is_equal_approx(sd4 - sd3, sd3 - sd2))
	_check("girl 10 y: BMI at z +2 and +3 match the WHO table (22.57 and 28.378)",
			absf(sd2 - 22.57) < 0.01 and absf(sd3 - 28.378) < 0.01)
	var sdm2: float = who.bmi_from_z("female", 120.0, -2.0)
	var sdm3: float = who.bmi_from_z("female", 120.0, -3.0)
	var sdm4: float = who.bmi_from_z("female", 120.0, -4.0)
	_check("below -3: SD-3 - SD-4 = SD-2 - SD-3", is_equal_approx(sdm3 - sdm4, sdm2 - sdm3))
	var rising := true
	var last := -INF
	for i in 81:
		var z: float = who.z_from_bmi("male", 150.0, 8.0 + i * 0.5)
		rising = rising and z > last
		last = z
	_check("z rises with BMI from 8 to 48 kg/m² (no jump at ±3)", rising)


func _test_height_and_interpolation() -> void:
	_check("boy 10 y median height 137.78 cm", absf(who.median_height_m("male", 120.0) - 1.377795) < 1e-5)
	var h120: float = who.median_height_m("female", 120.0)
	var h121: float = who.median_height_m("female", 121.0)
	var half: float = who.median_height_m("female", 120.5)
	_check("120.5 months is halfway between 120 and 121", is_equal_approx(half, (h120 + h121) / 2.0))
	var ages: Vector2 = who.age_range_months()
	_check("tables go from 61 to 228 months", ages == Vector2(61, 228))
	_check("ages outside the tables use the first or last month",
			who.median_height_m("male", 300.0) == who.median_height_m("male", 228.0)
			and who.median_height_m("male", 10.0) == who.median_height_m("male", 61.0))
	var config: Node = root.get_node("Config")
	_check("the age caps fit inside the tables (decision 8)",
			config.get_float("body.max_age_months.teenager") <= ages.y and config.get_float("body.start_age_months.child") >= ages.x)


## Starting weight and height of each difficulty, for the team (no pass or fail).
func _print_starting_weights() -> void:
	var config: Node = root.get_node("Config")
	print("  Starting weight from z (kg, at the median height):")
	for group in ["child", "teenager"]:
		var age: float = config.get_float("body.start_age_months." + group)
		for sex in ["male", "female"]:
			var line := "    %-8s %-6s %.0f cm:" % [group, sex, who.median_height_m(sex, age) * 100.0]
			for difficulty in ["easy", "normal", "hard", "very_hard"]:
				var z: float = config.get_float("health.difficulties.%s.z" % difficulty)
				line += "  %s %.1f" % [difficulty, who.weight_from_z(sex, age, z)]
			print(line)


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
