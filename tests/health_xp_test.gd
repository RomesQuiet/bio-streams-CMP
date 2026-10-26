extends SceneTree
## Tests for health and XP (Milestone 2, Task 4.5; Milestone 10 Task 8, v1 Step 12). Run from the project folder:
##   Godot --headless --path . -s res://tests/health_xp_test.gd
## The displayed health moves once per avatar day toward the target (decision 1); every change
## gives or takes 100 XP per point; at health 4.5 or more XP grows over time, faster the longer
## health stays high (at most x 3); XP never goes below 0. Nothing is saved.

const TOLERANCE := 0.0001

## Loaded at run time: the scripts use the autoloads, which do not exist yet when this test
## script is compiled.
var progress: GDScript
var _failures := 0


func _process(_delta: float) -> bool:
	progress = load("res://scripts/health/progress.gd")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var gs: Node = root.get_node("GameState")
	var config: Node = root.get_node("Config")
	root.get_node("Activities").reset()
	gs.reset()
	root.get_node("Clock").reset()

	_test_health_follows_measures(gs, config)
	_test_xp_from_health_changes(gs, config)
	_test_xp_over_time(gs)
	_test_level_up(gs, config)

	DirAccess.remove_absolute(save_game.save_path)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


## Measures of a day with recommended habits, and of a day with none.
const GOOD_DAY := {"physical": 0.9, "happiness": 0.9, "sleep": 1.0}
const BAD_DAY := {"physical": 0.1, "happiness": 0.1, "sleep": 0.0}


## Health starts at the target and then moves alpha_bar of the way to it once per avatar day.
func _test_health_follows_measures(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	var alpha: float = config.get_float("health.alpha_bar")
	_check("health equals the target at the start", is_equal_approx(gs.health, gs.target_health))
	_check("health level is health rounded", gs.health_level == roundi(gs.health))
	var start: float = gs.health
	_set_measures(gs, GOOD_DAY)
	_check("the target follows the measures at once", gs.target_health > start)
	_check("the displayed health does not change during the day", is_equal_approx(gs.health, start))
	var target: float = gs.target_health
	gs.daily_update()
	_check("once per day it moves alpha_bar (0.37) of the way to the target", absf(gs.health - (start + alpha * (target - start))) < TOLERANCE)
	var values := [start, gs.health]
	for day in 10:
		gs.daily_update()
		values.append(gs.health)
	print("  health on 11 good days: %s" % ", ".join(values.map(func(v): return "%.2f" % v)))
	_check("health rises gradually, day by day", values[2] > values[1] and values[-1] > values[2] and values[-1] <= 5.0)


func _test_xp_from_health_changes(gs: Node, config: Node) -> void:
	gs.start_new_avatar("Test", "child", "female", "normal")
	gs.xp = 50.0
	var per_point: float = config.get_float("progress.per_health_point")
	_check("100 XP per health point (v1)", per_point == 100.0)
	var before_health: float = gs.health
	_set_measures(gs, GOOD_DAY)
	gs.daily_update()
	var gain: float = gs.health - before_health
	_check("a health gain gives XP", absf(gs.xp - (50.0 + gain * per_point)) < TOLERANCE and gain > 0.0)
	var xp_before: float = gs.xp
	before_health = gs.health
	_set_measures(gs, BAD_DAY)
	gs.daily_update()
	var loss: float = before_health - gs.health
	_check("a health loss takes XP away", absf(gs.xp - (xp_before - loss * per_point)) < TOLERANCE and loss > 0.0)
	gs.xp = 1.0
	gs.daily_update()
	_check("XP never goes below 0", gs.xp == 0.0)


## At health 4.5 or more: 10 XP per avatar hour x (1 + hours at that level / 48), at most x 3.
func _test_xp_over_time(gs: Node) -> void:
	gs.reset()
	gs.health = 4.5
	gs.xp = 0.0
	progress.step(1.0, false)
	_check("health 4.5, first hour: 10 x (1 + 1 / 48) XP", absf(gs.xp - 10.0 * (1.0 + 1.0 / 48.0)) < TOLERANCE)
	gs.high_health_hours = 200.0
	var before: float = gs.xp
	progress.step(1.0, false)
	_check("after a long time at high health the bonus stops at x 3", absf(gs.xp - before - 30.0) < TOLERANCE)
	gs.health = 4.4
	before = gs.xp
	progress.step(1.0, false)
	_check("below 4.5 no XP over time, and the bonus starts again", gs.xp == before and gs.high_health_hours == 0.0)
	gs.health = 1.2
	progress.step(10.0, false)
	_check("low health takes no XP over time (only health losses do)", gs.xp == before)


func _test_level_up(gs: Node, config: Node) -> void:
	gs.reset()
	var per_level: float = config.get_float("xp.per_level")
	var levels: Array = []
	gs.leveled_up.connect(func(level: int) -> void: levels.append(level))
	gs.add_xp(per_level * 0.5)
	_check("half a level fills half the bar", absf(gs.level_progress - 0.5) < TOLERANCE and gs.level == 0)
	gs.add_xp(per_level)
	_check("reaching a new level emits leveled_up", levels == [1] and gs.level == 1)
	gs.add_xp(-per_level)
	_check("losing XP can lower the level", gs.level == 0)


func _set_measures(gs: Node, measures: Dictionary) -> void:
	for key in measures:
		gs.set(key, measures[key])


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
