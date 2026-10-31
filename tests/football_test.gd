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
	game.stick = Vector2.UP
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
	_check("both teams score", us > 0 and them > 0)


func _check(label: String, ok: bool) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		_failures += 1
