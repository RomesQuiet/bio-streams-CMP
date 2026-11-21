extends SceneTree
## Milestone 35: the screens minigame, a video game (sky jump). Run from the project folder:
##   Godot --headless --path . -s res://tests/sky_test.gd
## The run (scripts/health/sky_run.gd): it waits for the first press, runs and speeds up, lands on
## cloud tops, falls and stops when it hits a cloud's side, ends under the view, and its clouds are
## always reachable (a bot that jumps at every edge survives every seed up to the highest speed).
## The session: the score goes to the avatar's best and the device's leaderboard, screen time
## counts as before (played or not), and the activity ending during a run records it.
## Nothing real is saved: the save and the settings go to test files.

const SEED := 11
const TICK := 1.0 / 120.0

var _failures := 0
var _run_script: GDScript
var _config: Node


func _process(_delta: float) -> bool:
	_config = root.get_node("Config")
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_sky_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	var settings: Node = root.get_node("Settings")
	settings.settings_path = "user://test_sky_settings.json"
	settings.use_web_storage = false
	settings.sky_leaderboard.clear()
	_run_script = load("res://scripts/health/sky_run.gd")
	_test_start()
	_test_speed_and_score()
	_test_landing_and_falling()
	_test_side_hit()
	_test_restart()
	_test_same_seed()
	_test_reachable()
	_test_harder()
	_test_leaderboard(settings)
	_test_session(settings)
	_test_saving()
	DirAccess.remove_absolute(save_game.save_path)
	DirAccess.remove_absolute(settings.settings_path)
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _value(key: String) -> float:
	return _config.get_float("minigame.sky." + key)


func _test_start() -> void:
	var run: RefCounted = _run_script.new(SEED)
	run.advance(2.0)
	_check("before the first press the dinosaur waits on the first cloud", run.state == run.State.READY
			and is_zero_approx(run.x) and run.score() == 0 and run.grounded)
	run.press(true)
	run.advance(TICK)
	_check("the first press starts the run with a jump", run.state == run.State.RUNNING and run.vy > 0.0 and run.x > 0.0)
	run.press(false)


func _test_speed_and_score() -> void:
	var run: RefCounted = _run_script.new(SEED)
	run.clouds = [{"x": -400.0, "w": 1e7, "top": _value("start_top")}]
	run.press(true)
	run.press(false)
	run.advance(10.0)
	_check("the speed grows with time (Chrome-like)", is_equal_approx(run.speed, _value("start_speed") + _value("speed_gain") * run.run_seconds))
	_check("the score is the distance run", run.score() == floori(run.distance / _value("units_per_point")) and run.score() > 0)
	print("  after 10 s: speed %.0f, score %d" % [run.speed, run.score()])
	run.advance(300.0)
	_check("the speed stops at its highest", is_equal_approx(run.speed, _value("max_speed")))


func _test_landing_and_falling() -> void:
	var top := _value("start_top")
	var run: RefCounted = _run_script.new(SEED)
	run.clouds = [{"x": -400.0, "w": 2000.0, "top": top}]
	var ended := [-1]
	run.ended.connect(func(score: int) -> void: ended[0] = score)
	run.press(true)
	run.press(false)
	run.advance(0.4)
	_check("a jump goes up", not run.grounded and run.y > top)
	run.advance(0.6)
	_check("...and lands back on the cloud's top", run.grounded and is_equal_approx(run.y, top))
	run.advance(10.0)
	_check("running off the last cloud, it falls and the run ends", run.state == run.State.OVER and run.y < 0.0)
	_check("...with its score", ended[0] == run.score() and ended[0] > 0)
	_check("...and the score stops", run.score() == ended[0])


func _test_side_hit() -> void:
	var top := _value("start_top")
	var width := _value("dino_width")
	var run: RefCounted = _run_script.new(SEED)
	var wall := {"x": 400.0, "w": 400.0, "top": top + 150.0}
	run.clouds = [{"x": -400.0, "w": 1000.0, "top": top}, wall]
	run.press(true)
	run.press(false)
	run.advance(0.8)
	_check("a jump that comes down before a higher cloud hits its side", run.state == run.State.FALLING)
	_check("...the dinosaur stops at the side: the cloud does not move", is_equal_approx(run.x + width, wall.x))
	var x: float = run.x
	run.advance(1.0)
	_check("...and falls straight down to the end", run.state == run.State.OVER and is_equal_approx(run.x, x))
	var step: RefCounted = _run_script.new(SEED)
	step.clouds = [{"x": -400.0, "w": 1200.0, "top": top}, {"x": 800.0, "w": 2000.0, "top": top + _value("land_margin") * 0.5}]
	step.press(true)
	step.press(false)
	step.advance(2.5)
	_check("a cloud only a little higher is stepped onto, not hit", step.state == step.State.RUNNING and step.grounded)
	var under: RefCounted = _run_script.new(SEED)
	under.clouds = [{"x": -400.0, "w": 2000.0, "top": top}, {"x": -100.0, "w": 600.0, "top": top + _value("dino_height") + 100.0}]
	under.press(true)
	under.advance(0.3)
	_check("jumping into a cloud's underside is a hit too", under.state == under.State.FALLING)


func _test_restart() -> void:
	var run: RefCounted = _run_script.new(SEED)
	run.clouds = [{"x": -400.0, "w": 600.0, "top": _value("start_top")}]
	run.press(true)
	run.press(false)
	run.advance(5.0)
	_check("a run that ended a while ago can restart", run.is_over() and run.can_restart())
	var fresh: RefCounted = _run_script.new(SEED)
	fresh.clouds = run.clouds.duplicate(true)
	fresh.press(true)
	fresh.press(false)
	while not fresh.is_over():
		fresh.advance(TICK)
	_check("...but not at once", not fresh.can_restart())
	fresh.advance(_value("restart_seconds") + TICK)
	_check("...only after restart_seconds", fresh.can_restart())


func _test_same_seed() -> void:
	var a: RefCounted = _run_script.new(SEED)
	var b: RefCounted = _run_script.new(SEED)
	_check("a seed always makes the same clouds", a.clouds == b.clouds)
	var c: RefCounted = _run_script.new(SEED + 1)
	_check("another seed makes other clouds", a.clouds != c.clouds)


## A bot that jumps at the last moment on every cloud: it must never fall, at any speed.
func _test_reachable() -> void:
	var survived := 0
	var seeds := 25
	var worst := INF
	for i in seeds:
		var run: RefCounted = _run_script.new(1000 + i)
		var seconds := _play_bot(run, 200.0)
		worst = minf(worst, seconds)
		if seconds >= 200.0:
			survived += 1
		else:
			print("  seed %d fell after %.1f s at speed %.0f" % [1000 + i, seconds, run.speed])
	print("  bot: %d of %d seeds survived 200 s (highest speed after %.0f s)" % [survived, seeds,
			(_value("max_speed") - _value("start_speed")) / _value("speed_gain")])
	_check("every cloud can be reached: a jump from each edge never falls (%d seeds, 200 s)" % seeds, survived == seeds)


func _play_bot(run: RefCounted, seconds: float) -> float:
	run.press(true)
	run.press(false)
	var support: Dictionary = run.clouds[0]
	while run.run_seconds < seconds and run.state == run.State.RUNNING:
		if run.grounded:
			for cloud: Dictionary in run.clouds:
				if run.x + _value("dino_width") > cloud.x and run.x < cloud.x + cloud.w and is_equal_approx(run.y, cloud.top):
					support = cloud
			if run.x + run.speed * TICK * 2.0 >= support.x + support.w:
				run.press(true)
				run.press(false)
		run.advance(TICK)
	return run.run_seconds if run.state != run.State.RUNNING else seconds


## Later clouds are narrower and further apart than the first ones.
func _test_harder() -> void:
	var run: RefCounted = _run_script.new(SEED)
	var early := _average_cloud(run)
	run.run_seconds = 1e4
	run.speed = _value("max_speed")
	run.clouds = [run.clouds[-1]]
	run.x = run.clouds[0].x
	for i in 60:
		run._add_cloud()
	var late := _average_cloud(run)
	print("  start: width %.0f, gap %.0f, step %.0f | fastest: width %.0f, gap %.0f, step %.0f" % [early.w, early.gap, early.step,
			late.w, late.gap, late.step])
	_check("at the highest speed the gaps are wider and the steps higher", late.gap > early.gap and late.step > early.step)


func _average_cloud(run: RefCounted) -> Dictionary:
	var total := {"w": 0.0, "gap": 0.0, "step": 0.0}
	var count: int = run.clouds.size() - 1
	for i in range(1, run.clouds.size()):
		total.w += run.clouds[i].w
		total.gap += run.clouds[i].x - run.clouds[i - 1].x - run.clouds[i - 1].w
		total.step += absf(run.clouds[i].top - run.clouds[i - 1].top)
	for key in total:
		total[key] /= count
	return total


func _test_leaderboard(settings: Node) -> void:
	settings.sky_leaderboard.clear()
	_check("a score of 0 is not kept", not settings.record_sky_score("a", "Ana", 0))
	for i in 7:
		settings.record_sky_score("id%d" % i, "Avatar %d" % i, (i + 1) * 100)
	var kept: int = _config.get_int("minigame.sky.leaderboard_size")
	_check("the device keeps the best %d scores, best first" % kept, settings.sky_leaderboard.size() == kept
			and settings.sky_leaderboard[0].score == 700 and settings.sky_leaderboard[-1].score == 300)
	_check("a lower score of the same avatar changes nothing", not settings.record_sky_score("id6", "Avatar 6", 50)
			and settings.sky_leaderboard[0].score == 700)
	settings.record_sky_score("id3", "Avatar 3", 900)
	var places: Array = settings.sky_leaderboard.filter(func(e: Dictionary) -> bool: return e.id == "id3")
	_check("a better score moves the avatar up, one place per avatar", places.size() == 1 and settings.sky_leaderboard[0].id == "id3")
	settings.load_settings()
	_check("the leaderboard is saved on the device", settings.sky_leaderboard.size() == kept and settings.sky_leaderboard[0].score == 900)
	settings.sky_leaderboard.clear()


func _test_session(settings: Node) -> void:
	var minigame: Node = root.get_node("Minigame")
	var activities: Node = root.get_node("Activities")
	var gs: Node = root.get_node("GameState")
	activities.reset()
	minigame.reset()
	root.get_node("Simulation").reset()
	gs.reset()
	root.get_node("Clock").reset()
	gs.start_new_avatar("Rita", "child", "female", "normal")
	minigame.run_seed = SEED
	minigame.attach()
	activities.start("entertainment", "screens", 2.0)
	_check("the video game is a session that never waits", minigame.running and minigame.kind == "sky" and not minigame.is_waiting())
	_check("...screen time counts before the first jump", activities.doing_option() == "screens")
	_check("...and avatar time runs as before", is_equal_approx(minigame.time_share(), 1.0 / _value("time_slowdown")))
	minigame.jump(true)
	minigame.jump(false)
	var ended := []
	minigame.sky_run_ended.connect(func(score: int, best: bool) -> void: ended.append([score, best]))
	var waited := 0.0
	while not minigame.run.is_over() and waited < 60.0:
		_pass_time(0.1)
		waited += 0.1
	_check("with no more jumps the run ends", minigame.run.is_over() and ended.size() == 1)
	var score: int = ended[0][0] if not ended.is_empty() else 0
	_check("its score is the avatar's best", gs.sky_best == score and score > 0 and ended[0][1])
	_check("...and on the device's leaderboard", settings.sky_leaderboard.size() == 1 and settings.sky_leaderboard[0].id == gs.avatar_id
			and settings.sky_leaderboard[0].name == "Rita" and settings.sky_leaderboard[0].score == score)
	_check("between runs screen time still counts", activities.doing_option() == "screens")
	minigame.jump(true)
	_check("Jump right after the end does not restart yet", minigame.run.is_over())
	minigame.jump(false)
	_pass_time(_value("restart_seconds") + 0.1)
	minigame.jump(true)
	minigame.jump(false)
	_check("...a moment later it starts a new run", minigame.run.state == minigame.run.State.RUNNING)
	_pass_time(0.5)
	var playing: int = minigame.run.score()
	activities.stop()
	_check("stopping during a run records it (no new best when lower)", ended.size() == 2 and ended[1][0] == playing
			and (gs.sky_best == maxi(score, playing)))
	_check("...and ends the session", not minigame.running)
	minigame.detach()
	activities.reset()
	minigame.reset()
	activities.start("entertainment", "screens", 1.0)
	_check("without a player screens are plain screen time, as before", not minigame.running and activities.doing_option() == "screens")
	activities.reset()
	settings.sky_leaderboard.clear()


func _test_saving() -> void:
	var gs: Node = root.get_node("GameState")
	gs.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	var first_id: String = gs.avatar_id
	gs.start_new_avatar("Other", "child", "male", "normal")
	_check("every new avatar gets its own id", not first_id.is_empty() and gs.avatar_id != first_id)
	gs.sky_best = 321
	var saved: Dictionary = gs.to_dict()
	gs.sky_best = 0
	gs.from_dict(saved)
	_check("the save keeps the avatar's best and its id", gs.sky_best == 321 and gs.avatar_id == saved.avatar_id)
	saved.erase("avatar_id")
	saved.erase("sky_best")
	gs.from_dict(saved)
	_check("an older save gets an id and no best", not gs.avatar_id.is_empty() and gs.sky_best == 0)


func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 0.02)
		root.get_node("Clock")._process(step)
		root.get_node("Minigame").advance(step)
		left -= step


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
