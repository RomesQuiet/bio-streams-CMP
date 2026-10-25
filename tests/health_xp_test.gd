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


## Scores of a day with recommended habits, and of a day with none.
const GOOD_DAY := {"sleep": 1.0, "activity": 1.0, "strength": 1.0, "screens": 1.0}
const BAD_DAY := {"sleep": 0.0, "activity": 0.0, "strength": 0.0, "screens": 0.0}


## Health starts at the target and then moves part of the way toward it once per avatar day.
func _test_health_follows_measures(gs: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	var config: Node = root.get_node("Config")
	var alpha: float = config.get_float("health_m4.alpha_bar")
	_check("health equals the target at the start", is_equal_approx(gs.health, gs.target_health))
	_check("health level is health rounded", gs.health_level == roundi(gs.health))
	var start: float = gs.health
	gs.apply_avatar_hours(5.0, false)
	gs.apply_effects({"physical": 0.3}, 1.0)
	_check("health does not change during the day", is_equal_approx(gs.health, start))
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.update_body_states(GOOD_DAY, 10.0)
	var target: float = gs.target_health
	_check("a good day raises the target health", target > start)
	_check("health moves daily_alpha of the way to the target", absf(gs.health - (start + alpha * (target - start))) < TOLERANCE)
	var values := [start, gs.health]
	for day in 10:
		gs.update_body_states(GOOD_DAY, 10.0)
		values.append(gs.health)
	print("health on 11 good days: %s" % ", ".join(values.map(func(v): return "%.2f" % v)))
	_check("health rises gradually, day by day", values[2] > values[1] and values[-1] > values[2] and values[-1] <= 5.0)
	_check("the measures come from the body states", is_equal_approx(gs.physical, gs.physical_from_body(gs.fitness, gs.muscle, gs.weight_z)))


func _test_xp_from_health_changes(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.xp = 50.0
	var per_point: float = config.get_float("xp.per_health_point")
	var before_health: float = gs.health
	gs.update_body_states(GOOD_DAY, 10.0)
	var gain: float = gs.health - before_health
	_check("a health gain gives XP", absf(gs.xp - (50.0 + gain * per_point)) < TOLERANCE and gain > 0.0)
	var xp_before: float = gs.xp
	before_health = gs.health
	gs.update_body_states(BAD_DAY, 0.0)
	var loss: float = before_health - gs.health
	_check("a health loss takes XP away", absf(gs.xp - (xp_before - loss * per_point)) < TOLERANCE and loss > 0.0)


func _test_xp_over_time(gs: Node, config: Node) -> void:
	# Health 5 (set directly): XP grows over time.
	gs.reset()
	gs.health = 5.0
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

	# Health 1: XP falls, but never below 0.
	gs.health = 1.0
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
