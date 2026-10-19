extends SceneTree
## Tests for health and XP (Milestone 2, Task 4.5). Run from the project folder:
##   Godot --headless --path . -s res://tests/health_xp_test.gd

const TOLERANCE := 0.0001

var _failures := 0


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var config: Node = root.get_node("Config")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_test_health_follows_measures(gs)
	_test_xp_from_health_changes(gs, config)
	_test_xp_over_time(gs, config)
	_test_level_up(gs, config)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_health_follows_measures(gs: Node) -> void:
	gs.reset()
	_check("health equals the formula at the start", is_equal_approx(gs.health, gs.calculate_health()))
	_check("health level is health rounded", gs.health_level == roundi(gs.health))
	var start: float = gs.health
	gs.apply_avatar_hours(5.0, false)  # Awake: the sleep measure falls.
	_check("health falls when the sleep measure falls", gs.health < start)
	var low: float = gs.health
	gs.apply_effects({"physical": 0.3}, 1.0)  # Like exercise.
	_check("health rises when the physical measure rises", gs.health > low)
	_check("health stays equal to the formula", is_equal_approx(gs.health, gs.calculate_health()))


func _test_xp_from_health_changes(gs: Node, config: Node) -> void:
	gs.reset()
	gs.xp = 50.0
	var per_point: float = config.get_float("xp.per_health_point")
	var before_health: float = gs.health
	gs.apply_effects({"physical": 0.2}, 1.0)
	var gain: float = gs.health - before_health
	_check("a health gain gives XP", absf(gs.xp - (50.0 + gain * per_point)) < TOLERANCE and gain > 0.0)
	var xp_before: float = gs.xp
	before_health = gs.health
	gs.apply_effects({"mental": -0.2}, 1.0)
	var loss: float = before_health - gs.health
	_check("a health loss takes XP away", absf(gs.xp - (xp_before - loss * per_point)) < TOLERANCE and loss > 0.0)


func _test_xp_over_time(gs: Node, config: Node) -> void:
	# Full measures: health 5. Asleep, so the sleep measure does not fall and health stays 5.
	gs.reset()
	gs.physical = 1.0
	gs.mental = 1.0
	gs.sleep = 1.0
	gs.apply_effects({}, 0.0)
	_check("full measures give health 5", is_equal_approx(gs.health, 5.0))
	var xp0: float = gs.xp
	gs.apply_avatar_hours(1.0, true)
	var first_hour: float = gs.xp - xp0
	for i in 20:
		gs.apply_avatar_hours(1.0, true)
	var xp1: float = gs.xp
	gs.apply_avatar_hours(1.0, true)
	var later_hour: float = gs.xp - xp1
	_check("high health gives XP every hour", first_hour > 0.0)
	_check("staying at high health longer gives more XP per hour", later_hour > first_hour)
	var max_rate: float = config.get_float("xp.gain_per_avatar_hour") * config.get_float("xp.high_health_max_multiplier")
	_check("the hourly gain has a maximum", later_hour <= max_rate + TOLERANCE)

	# Empty measures: health 1. XP falls, but never below 0.
	gs.physical = 0.0
	gs.mental = 0.0
	gs.sleep = 0.0
	gs.apply_effects({}, 0.0)
	var xp2: float = gs.xp
	gs.apply_avatar_hours(1.0, true)
	_check("low health loses XP over time", gs.xp < xp2)
	_check("the high-health streak is reset", gs.high_health_hours == 0.0)
	for i in 1000:
		gs.apply_avatar_hours(1.0, true)
	_check("XP never goes below 0", gs.xp == 0.0)


func _test_level_up(gs: Node, config: Node) -> void:
	gs.reset()
	var per_level: float = config.get_float("xp.per_level")
	var levels: Array = []
	gs.leveled_up.connect(func(level): levels.append(level))
	gs.add_xp(per_level - 1.0)
	_check("level 0 just before the first level", gs.level == 0 and levels.is_empty())
	gs.add_xp(2.0)
	_check("reaching per_level XP gives level 1", gs.level == 1 and levels == [1])
	_check("the XP bar starts again after a level up", gs.level_progress < 0.05)
	gs.add_xp(per_level * 2.0)
	_check("more XP gives more levels", gs.level == 3 and levels == [1, 3])


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
