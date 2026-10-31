extends SceneTree
## The football minigame (Milestone 14). Run from the project folder:
##   Godot --headless --path . -s res://tests/football_test.gd

const SEED := 7
const STEP := 0.05

var _failures := 0
var _load: GDScript
var _match_script: GDScript


func _process(_delta: float) -> bool:
	var save_game: Node = root.get_node("SaveGame")
	save_game.save_path = "user://test_save.json"
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	root.get_node("Activities").reset()
	root.get_node("Simulation").reset()
	root.get_node("GameState").reset()
	root.get_node("Clock").reset()
	_load = load("res://scripts/health/football_load.gd")
	_match_script = load("res://scripts/health/football_match.gd")
	_test_load()
	_test_kick_off()
	_test_actions()
	_test_whole_match()
	_test_human_match()
	_test_session()
	_test_breath()
	_test_score()
	_test_stopping()
	_test_saving(save_game)
	_test_slow_time()
	_test_events()
	_test_asking_for_the_ball()
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _new_match() -> RefCounted:
	var game: RefCounted = _match_script.new(SEED)
	game.avatar_speed = _load.speed(false)
	game.free_distance = _load.free_distance()
	game.shot_range = _load.shot_range()
	return game


func _test_load() -> void:
	var gs: Node = root.get_node("GameState")
	print("difficulty  speed  jog   free  shot  minutes")
	var last := {}
	for id in ["easy", "normal", "hard", "very_hard"]:
		gs.start_new_avatar("Test", "child", "male", id)
		print("%-10s  %.1f   %.1f   %.1f   %.1f  %.0f" % [id, _load.speed(false), _load.speed(true),
				_load.free_distance(), _load.shot_range(), _load.play_minutes()])
		if not last.is_empty():
			_check("%s is slower, reads less and tires sooner" % id, _load.speed(false) < last["speed"]
					and _load.free_distance() > last["free"] and _load.shot_range() < last["shot"]
					and _load.play_minutes() < last["minutes"])
		last = {"speed": _load.speed(false), "free": _load.free_distance(), "shot": _load.shot_range(), "minutes": _load.play_minutes()}
	gs.start_new_avatar("Test", "child", "male", "normal")
	var rested: float = _load.speed(false)
	gs.hours_awake = 19.0
	_check("a sleepy avatar is slower", _load.speed(false) < rested)
	gs.hours_awake = 0.0
	_check("jogging is slower", _load.speed(true) < rested)


func _test_kick_off() -> void:
	var game := _new_match()
	_check("8 players, 4 a side", game.positions.size() == 8 and game.team_size == 4)
	_check("the avatar kicks off", game.has_ball())
	_check("all in their own half", game.positions[0].y < game.length * 0.5 and game.positions[4].y > game.length * 0.5)
	game.kick_off(false)
	_check("the other team can kick off", game.defending() and game.owner == 4)


func _test_actions() -> void:
	var game := _new_match()
	game.positions[1] = Vector2(5, 5)
	for i in range(4, 8):
		game.positions[i] = Vector2(25, 40)
	game.stick = Vector2(-1, -1).normalized()
	_check("the stick chooses the receiver", game.best_receiver() == 1)
	_check("a pass to a free team-mate is good", game.pass_ball())
	_check("the ball flies", game.owner == -1 and game.flight == 1)
	game.stick = Vector2.ZERO
	for _i in 200:
		game.advance(STEP)
		if game.flight == 0:
			break
	_check("a team-mate receives it", game.owner == 1)

	game = _new_match()
	game.positions[1] = Vector2(5, 5)
	game.positions[4] = Vector2(5, 6)
	game.stick = Vector2(-1, -1).normalized()
	_check("a pass to a marked team-mate is not good", not game.pass_ball())

	game = _new_match()
	_check("a shot from far away is not good", not game.shoot())
	game = _new_match()
	game.positions[0] = Vector2(15, 40)
	_check("a shot close to goal is good", game.shoot())

	game = _new_match()
	game.kick_off(false)
	game.positions[0] = game.positions[4] + Vector2(10, 0)
	_check("a tackle out of reach fails", not game.tackle() and game.defending())
	game.positions[0] = game.positions[4] + Vector2(1, 0)
	game.advance(1.1)
	game.positions[0] = game.positions[4] + Vector2(1, 0)
	var won := false
	for _i in 20:
		if game.can_tackle() and game.tackle():
			won = game.has_ball()
		if won:
			break
		game.advance(1.1)
		if game.defending():
			game.positions[0] = game.positions[game.owner] + Vector2(1, 0)
	_check("tackles within reach win the ball", won)
	_check("no second tackle at once", not game.can_tackle())

	game = _new_match()
	game.stick = Vector2(0, 1)
	game.advance(1.0)
	_check("the frame rate does not change the match", _same_after(0.05, 0.016))


func _same_after(first: float, second: float) -> bool:
	var one := _new_match()
	var two := _new_match()
	one.stick = Vector2(0.3, 1).normalized()
	two.stick = one.stick
	for _i in roundi(20.0 / first):
		one.advance(first)
	for _i in roundi(20.0 / second):
		two.advance(second)
	return one.positions[0].distance_to(two.positions[0]) < 1.0


## A simple player: runs at the ball or goal, shoots in range, passes when pressed, tackles.
func _bot_match(seed_value: int, seconds: float) -> RefCounted:
	var game: RefCounted = _match_script.new(seed_value)
	game.avatar_speed = 9.0
	game.free_distance = 5.0
	game.shot_range = 16.0
	var left := 0.0
	while left < seconds:
		left += STEP
		if game.has_ball():
			game.stick = (Vector2(15, 45) - game.positions[0]).normalized()
			if game.in_shot_range():
				game.shoot()
		else:
			game.stick = (game.ball - game.positions[0]).normalized()
			game.tackle()
		game.advance(STEP)
		for point in game.positions:
			if point.x < 0.0 or point.x > 30.0 or point.y < 0.0 or point.y > 45.0:
				_check("a player left the field", false)
				return game
	return game


## A human-like player: the normal speed, reacts late, misjudges a little. Prints how the match
## goes, so the computer team's values can be chosen by people and not by a perfect player.
func _human_match(seed_value: int, seconds: float, speed: float) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var game: RefCounted = _match_script.new(seed_value)
	game.avatar_speed = speed
	game.free_distance = 6.0
	game.shot_range = 14.0
	var left := 0.0
	var think := 0.0
	var owned := 0.0
	while left < seconds:
		left += STEP
		think -= STEP
		owned += STEP if game.has_ball() else 0.0
		if think <= 0.0:
			think = 0.3 + random.randf() * 0.3
			if game.has_ball():
				game.stick = (Vector2(15, 45) - game.positions[0]).normalized()
				var pressed: bool = game.positions[0].distance_to(game.positions[game._nearest_of(1, game.positions[0])]) < 5.0
				if game.in_shot_range():
					game.shoot()
				elif pressed and random.randf() < 0.5:
					game.pass_ball()
			else:
				game.stick = (game.ball - game.positions[0]).normalized()
				if game.team_mate_has_ball() and random.randf() < 0.2:
					game.call_for_ball()
				if game.in_tackle_reach() and game.can_tackle():
					game.tackle()
		game.advance(STEP)
	return {"us": game.goals_us, "them": game.goals_them, "owned": owned / seconds}


func _test_human_match() -> void:
	var total := {"us": 0.0, "them": 0.0, "owned": 0.0}
	var slow := {"us": 0.0, "them": 0.0, "owned": 0.0}
	for i in 8:
		var one := _human_match(i + 1, 430.0, 7.4)
		var two := _human_match(i + 1, 430.0, 6.1)
		for key in total:
			total[key] += one[key] / 8.0
			slow[key] += two[key] / 8.0
	print("  human-like player, 7 minutes, Normal speed: %.1f to %.1f, has the ball %.0f%% of the time" % [total["us"], total["them"], total["owned"] * 100.0])
	print("  human-like player, 7 minutes, Very hard speed: %.1f to %.1f, has the ball %.0f%% of the time" % [slow["us"], slow["them"], slow["owned"] * 100.0])
	_check("a human-like player scores and concedes", total["us"] > 0.0 and total["them"] > 0.0)


func _test_whole_match() -> void:
	var one := _bot_match(SEED, 86.0)
	var two := _bot_match(SEED, 86.0)
	_check("the same seed plays the same match", one.goals_us == two.goals_us and one.goals_them == two.goals_them
			and one.positions[0].is_equal_approx(two.positions[0]))
	var us := 0
	var them := 0
	for i in 20:
		var game := _bot_match(i + 1, 86.0)
		us += game.goals_us
		them += game.goals_them
	print("  20 matches of 86 s: %.1f to %.1f goals a match" % [us / 20.0, them / 20.0])
	_check("a perfect player scores", us > 0)


func _start(difficulty: String, first_move := true) -> void:
	var minigame: Node = root.get_node("Minigame")
	root.get_node("Activities").reset()
	minigame.reset()
	root.get_node("Simulation").reset()
	root.get_node("GameState").reset()
	root.get_node("Clock").reset()
	root.get_node("GameState").start_new_avatar("Test", "child", "male", difficulty)
	minigame.match_seed = SEED
	minigame.attach()
	root.get_node("Activities").start("entertainment", "football")
	if first_move:
		minigame.set_stick(Vector2(0, 1))


func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 0.02)
		root.get_node("Clock")._process(step)
		root.get_node("Minigame").advance(step)
		left -= step


func _test_session() -> void:
	var minigame: Node = root.get_node("Minigame")
	var activities: Node = root.get_node("Activities")
	_start("normal", false)
	_check("football is a session that waits", minigame.kind == "football" and minigame.is_waiting())
	_check("while waiting the avatar is not playing", activities.doing_option() == "")
	var before: Vector2 = minigame.game.positions[1]
	_pass_time(1.0)
	_check("the match stops while waiting", minigame.game.positions[1] == before)
	minigame.set_stick(Vector2(0, 1))
	_check("the joystick starts it", not minigame.is_waiting() and activities.doing_option() == "football")
	var y: float = minigame.game.positions[0].y
	_pass_time(1.0)
	_check("the avatar moves up", minigame.game.positions[0].y > y)
	minigame.detach()
	activities.reset()
	minigame.reset()
	activities.start("entertainment", "football")
	_check("without a player football keeps the fixed score", not minigame.running
			and is_equal_approx(minigame.score(), root.get_node("Config").get_float("minigame.default_score")))
	activities.reset()


func _test_breath() -> void:
	var minigame: Node = root.get_node("Minigame")
	_start("normal")
	var full: float = minigame.reserve
	_pass_time(5.0)
	_check("moving costs Breath", minigame.reserve < full)
	var moving: float = minigame.reserve
	minigame.set_stick(Vector2.ZERO)
	_pass_time(2.0)
	_check("quiet moments refill Breath", minigame.reserve > moving)
	minigame.game.kick_off(true)
	var before: float = minigame.reserve
	minigame.shoot_or_tackle()
	_check("a shot costs Breath", minigame.reserve < before)
	minigame.reserve = 0.0001
	minigame.set_stick(Vector2(0, 1))
	_pass_time(1.0)
	_check("at an empty bar the avatar jogs", minigame.is_walking())
	_check("jogging is slower", is_equal_approx(minigame.game.avatar_speed, _load.speed(true)))
	_pass_time(80.0)
	_check("it runs again after recovering", not minigame.is_walking())


func _test_score() -> void:
	var minigame: Node = root.get_node("Minigame")
	_start("normal")
	_pass_time(20.0)
	_check("moving all the time gives a full active share", minigame.pace > 0.99)
	var rhythm: float = minigame.rhythm
	minigame.game.kick_off(true)
	minigame.game.positions[0] = Vector2(15, 5)
	minigame.shoot_or_tackle()
	_check("a shot from far away lowers the timing", minigame.rhythm < rhythm)
	var score: float = minigame.score()
	_check("score is half timing and half active", is_equal_approx(score, 0.5 * minigame.rhythm + 0.5 * minigame.pace))
	minigame.set_stick(Vector2.ZERO)
	for _i in 10:
		_pass_time(2.0)
		minigame.game.kick_off(true)
		minigame.set_stick(Vector2.ZERO)
		minigame.pass_ball()
	_check("standing still lowers the active share", minigame.pace < 0.6)


func _test_stopping() -> void:
	var minigame: Node = root.get_node("Minigame")
	var activities: Node = root.get_node("Activities")
	_start("normal")
	minigame.set_stick(Vector2.ZERO)
	_pass_time(3.1)
	_check("after 3 s with no input the avatar waits", minigame.is_waiting())
	_pass_time(20.1)
	_check("20 s later the activity ends", not activities.is_running() and not minigame.running)
	_start("normal")
	var scores := []
	minigame.match_ended.connect(func(us: int, them: int) -> void: scores.append([us, them]))
	minigame.game.goals_us = 2
	minigame.game.goals_them = 1
	activities.stop()
	_check("the end of a match gives its score", scores == [[2, 1]])


func _test_slow_time() -> void:
	var minigame: Node = root.get_node("Minigame")
	var clock: Node = root.get_node("Clock")
	var activities: Node = root.get_node("Activities")
	_start("normal", false)
	var waiting_share: float = minigame.time_share()
	minigame.set_stick(Vector2(0, 1))
	_check("time only slows while the avatar plays", is_equal_approx(waiting_share, 1.0) and is_equal_approx(minigame.time_share(), 0.2))
	var before: float = clock.minute_of_day
	_pass_time(10.0)
	var minutes: float = clock.minute_of_day - before
	print("  10 real seconds of football: %.2f avatar minutes" % minutes)
	_check("10 real seconds are 1.4 avatar minutes (5 times slower)", absf(minutes - 1.4) < 0.05)
	_check("the activity counts the same slower time", absf(activities.elapsed_hours * 60.0 - minutes) < 0.05)
	activities.stop()
	_check("after the match time runs normally", is_equal_approx(minigame.time_share(), 1.0))


func _test_events() -> void:
	var game := _new_match()
	var seen := []
	game.happened.connect(func(key: String) -> void: seen.append(key))
	game.shoot()
	_check("a far shot says so", seen.has("FOOTBALL_SHOT_FAR"))
	for _i in 100:
		game.advance(STEP)
		if not game.stopped() and game.flight == 0:
			break
	_check("a shot ends in a message and a kick-off for the other team", (seen.has("FOOTBALL_MISSED") or seen.has("FOOTBALL_GOAL")) and game.defending())
	game.kick_off(true, true)
	var before: Vector2 = game.positions[1]
	game.advance(1.0)
	_check("the match stops for a moment after a restart", game.stopped() and game.positions[1] == before)
	game.advance(1.5)
	_check("then it goes on", not game.stopped())


func _test_asking_for_the_ball() -> void:
	var game := _new_match()
	game.owner = 1
	game.ball = game.positions[1]
	_check("a team-mate has the ball", game.team_mate_has_ball())
	for i in range(4, 8):
		game.positions[i] = Vector2(0, 45)
	game.call_for_ball()
	for _i in 200:
		game.advance(STEP)
		if game.flight == 0:
			break
	_check("asking for the ball brings it to the avatar", game.has_ball())


func _test_saving(save_game: Node) -> void:
	var minigame: Node = root.get_node("Minigame")
	var activities: Node = root.get_node("Activities")
	_start("normal")
	_pass_time(3.0)
	minigame.game.goals_us = 3
	minigame.game.goals_them = 2
	var reserve: float = minigame.reserve
	save_game.save_game()
	minigame.detach()
	activities.reset()
	minigame.reset()
	save_game.load_game()
	minigame.attach()
	_check("a loaded match goes on, waiting", minigame.kind == "football" and minigame.is_waiting())
	_check("with its score", minigame.game.goals_us == 3 and minigame.game.goals_them == 2)
	_check("and its Breath", is_equal_approx(minigame.reserve, reserve))
	minigame.detach()
	activities.reset()
	minigame.reset()
	save_game.delete_save()


func _check(label: String, ok: bool) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		_failures += 1
