extends RefCounted
## The football match of the minigame (Milestone 14, decisions 39 to 46): the idea of classic
## arcade football, seen from above. The avatar's team attacks upwards (y grows). Player 0 is the
## avatar; the others are computer players. This script knows nothing about the screen or health.
## It runs in fixed steps with its own random generator, so a seed always plays the same match.
## Numbers are in Config (group minigame.football).

## What just happened, for the player. Each is a key of translations/strings.csv.
signal happened(key: String)

const NOBODY := -1
enum Flight {NONE, PASS, SHOT}

## Every player: the avatar's team first, then the other team.
var positions: Array[Vector2] = []
var team_size := 0
var width := 0.0
var length := 0.0
## Who has the ball, or NOBODY while it flies or is loose.
var owner := NOBODY
var ball := Vector2.ZERO
var flight := Flight.NONE
var goals_us := 0
var goals_them := 0
## The direction the player wants, length 0 to 1.
var stick := Vector2.ZERO
## Set from FootballLoad.
var avatar_speed := 0.0
var free_distance := 0.0
var shot_range := 0.0

var _rng := RandomNumberGenerator.new()
var _values := {}
var _formation: Array = []
var _left := 0.0
var _tick := 0.0
var _decide_left := 0.0
var _tackle_left := 0.0
var _own_tackle_left := 0.0
var _receiver := NOBODY
var _ball_target := Vector2.ZERO
var _ball_speed := 0.0
var _shot_scores := false
var _shooter_team := 0
## Real seconds left of the stop after a goal or a miss.
var _pause_left := 0.0
## Real seconds in which a player who just got the ball cannot be tackled.
var _safe_left := 0.0


func _init(seed_value: int) -> void:
	_rng.seed = seed_value
	team_size = Config.get_int("minigame.football.team_size")
	_formation = Config.get_value("minigame.football.formation")
	width = _value("field_width")
	length = _value("field_length")
	_tick = _value("tick_seconds")
	positions.resize(team_size + team_size)
	kick_off(true)


## Everyone back to their places. The team that kicks off has the ball.
## stop: the match stops for a moment first, so the player can see what happened.
func kick_off(ours: bool, stop := false) -> void:
	_pause_left = _value("restart_seconds") if stop else 0.0
	for i in positions.size():
		positions[i] = _home(i, false)
	owner = 0 if ours else team_size
	ball = positions[owner]
	flight = Flight.NONE
	_receiver = NOBODY
	_decide_left = _value("cpu_decide_seconds")
	_tackle_left = _value("cpu_tackle_seconds")
	_safe_left = _value("protect_seconds")


## Real seconds passed. Runs whole steps, so the frame rate does not change the match.
func advance(seconds: float) -> void:
	_left += seconds
	while _left >= _tick:
		_left -= _tick
		_step(_tick)


func has_ball() -> bool:
	return owner == 0


## An opponent has the ball.
func defending() -> bool:
	return owner != NOBODY and _team(owner) == 1


func can_tackle() -> bool:
	return defending() and _own_tackle_left <= 0.0


func in_tackle_reach() -> bool:
	return defending() and positions[0].distance_to(positions[owner]) <= _value("tackle_reach")


## A team-mate has the ball: the player can ask for it.
func team_mate_has_ball() -> bool:
	return owner > 0 and owner < team_size


## The match is stopped for a moment after a goal or a miss.
func stopped() -> bool:
	return _pause_left > 0.0


## True if no opponent is within free_distance of this player.
func is_free(player: int) -> bool:
	return _nearest_distance(player, 1 - _team(player)) >= free_distance


## True if the avatar is close enough to goal for a good shot.
func in_shot_range() -> bool:
	return positions[0].distance_to(_goal(0)) <= shot_range


## The team-mate a pass would go to: the one nearest the stick's direction, or the nearest.
func best_receiver() -> int:
	var best := NOBODY
	var best_value := -INF
	for i in range(1, team_size):
		var offset := positions[i] - positions[0]
		var value := stick.normalized().dot(offset.normalized()) * length - offset.length()
		if value > best_value:
			best_value = value
			best = i
	return best


## The avatar passes. Returns true for a good pass: the team-mate was free.
func pass_ball() -> bool:
	if not has_ball():
		return false
	var receiver := best_receiver()
	var good := is_free(receiver)
	_pass_to(receiver)
	happened.emit("FOOTBALL_PASS_GOOD" if good else "FOOTBALL_PASS_MARKED")
	return good


## The avatar asks the team-mate with the ball for a pass.
func call_for_ball() -> void:
	if team_mate_has_ball():
		_pass_to(0)


## The avatar shoots. Returns true for a good shot: it was in range.
func shoot() -> bool:
	if not has_ball():
		return false
	var good := in_shot_range()
	if not good:
		happened.emit("FOOTBALL_SHOT_FAR")
	_shoot(_value("goal_chance_good") if good else _value("goal_chance_far"))
	return good


## The avatar tries to tackle, at most once per tackle time. Returns true if the opponent was
## within reach, a good tackle even if it does not always win the ball.
func tackle() -> bool:
	if not can_tackle():
		return false
	_own_tackle_left = _value("tackle_seconds")
	if not in_tackle_reach():
		happened.emit("FOOTBALL_TACKLE_FAR")
		return false
	if _rng.randf() < _value("tackle_chance"):
		_receive(0)
		happened.emit("FOOTBALL_TACKLE_WON")
	else:
		happened.emit("FOOTBALL_TACKLE_MISSED")
	return true


func _step(seconds: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= seconds
		return
	_own_tackle_left -= seconds
	_safe_left -= seconds
	var move := stick.limit_length(1.0) * avatar_speed * seconds
	positions[0] = _on_field(positions[0] + move)
	for i in range(1, positions.size()):
		positions[i] = _on_field(positions[i].move_toward(_target(i), _value("cpu_speed") * seconds))
	if flight != Flight.NONE:
		_move_ball(seconds)
	elif owner != NOBODY:
		ball = positions[owner]
	else:
		_pick_up()
	_computer_tackle(seconds)
	_computer_carrier(seconds)


func _move_ball(seconds: float) -> void:
	if flight == Flight.PASS:
		_ball_target = positions[_receiver]
		for i in positions.size():
			if _team(i) != _team(_receiver) and positions[i].distance_to(ball) <= _value("intercept_radius"):
				if _team(i) == 1:
					happened.emit("FOOTBALL_INTERCEPTED")
				_receive(i)
				return
	ball = ball.move_toward(_ball_target, _ball_speed * seconds)
	if not ball.is_equal_approx(_ball_target):
		return
	if flight == Flight.PASS:
		_receive(_receiver)
	else:
		if _shot_scores and _shooter_team == 0:
			goals_us += 1
			happened.emit("FOOTBALL_GOAL")
		elif _shot_scores:
			goals_them += 1
			happened.emit("FOOTBALL_GOAL_THEM")
		else:
			happened.emit("FOOTBALL_MISSED")
		# After a goal or a miss the other team restarts the game.
		kick_off(_shooter_team == 1, true)


func _receive(player: int) -> void:
	owner = player
	flight = Flight.NONE
	_receiver = NOBODY
	ball = positions[player]
	_decide_left = _value("cpu_decide_seconds")
	_safe_left = _value("protect_seconds")


func _pick_up() -> void:
	var nearest := _nearest_of(0, ball)
	var other := _nearest_of(1, ball)
	if positions[other].distance_to(ball) < positions[nearest].distance_to(ball):
		nearest = other
	if positions[nearest].distance_to(ball) <= _value("control_radius"):
		_receive(nearest)


func _pass_to(receiver: int) -> void:
	owner = NOBODY
	flight = Flight.PASS
	_receiver = receiver
	_ball_speed = _value("pass_speed")


func _shoot(chance: float) -> void:
	_shooter_team = _team(owner)
	_ball_target = _goal(_shooter_team)
	owner = NOBODY
	flight = Flight.SHOT
	_ball_speed = _value("shot_speed")
	_shot_scores = _rng.randf() < chance


## Where a computer player wants to go.
func _target(player: int) -> Vector2:
	var team := _team(player)
	if player == owner:
		return _goal(team)
	if owner == NOBODY:
		return ball if player == _nearest_computer(team, ball) else _home(player, true)
	if _team(owner) != team and player == _nearest_computer(team, positions[owner]):
		return positions[owner]
	return _home(player, true)


## A computer player tries to take the ball from a close opponent, at most once per tackle time.
func _computer_tackle(seconds: float) -> void:
	_tackle_left -= seconds
	if _tackle_left > 0.0 or owner == NOBODY or _safe_left > 0.0:
		return
	_tackle_left = _value("cpu_tackle_seconds")
	var tackler := _nearest_computer(1 - _team(owner), positions[owner])
	if positions[tackler].distance_to(positions[owner]) <= _value("cpu_tackle_reach") \
			and _rng.randf() < _value("cpu_tackle_chance"):
		if owner == 0:
			happened.emit("FOOTBALL_LOST_BALL")
		_receive(tackler)


## A computer player with the ball decides from time to time: shoot, pass or keep running.
func _computer_carrier(seconds: float) -> void:
	if owner == NOBODY or owner == 0:
		return
	_decide_left -= seconds
	if _decide_left > 0.0:
		return
	_decide_left = _value("cpu_decide_seconds")
	var team := _team(owner)
	if positions[owner].distance_to(_goal(team)) <= _value("cpu_shot_range"):
		_shoot(_value("cpu_goal_chance"))
	elif _nearest_distance(owner, 1 - team) < _value("cpu_press_radius") or _rng.randf() < _value("cpu_pass_chance"):
		_pass_to(_freest_team_mate(owner))


func _freest_team_mate(player: int) -> int:
	var team := _team(player)
	var best := NOBODY
	var best_distance := -INF
	for i in positions.size():
		if i != player and _team(i) == team and _nearest_distance(i, 1 - team) > best_distance:
			best_distance = _nearest_distance(i, 1 - team)
			best = i
	return best


## A player's place: from the formation, mirrored for the other team. In play the whole team
## follows the ball up and down the field.
func _home(player: int, following: bool) -> Vector2:
	var team := _team(player)
	var place: Array = _formation[player - team * team_size]
	var y := float(place[1]) * length
	if following:
		y += (ball.y / length - _value("field_middle")) * _value("follow_share") * length
	y = y if team == 0 else length - y
	return _on_field(Vector2(float(place[0]) * width, y))


func _goal(team: int) -> Vector2:
	return Vector2(width * _value("field_middle"), length if team == 0 else 0.0)


func _team(player: int) -> int:
	return 0 if player < team_size else 1


func _on_field(point: Vector2) -> Vector2:
	return point.clamp(Vector2.ZERO, Vector2(width, length))


func _nearest_of(team: int, point: Vector2) -> int:
	return _nearest(team, point, 0)


## The avatar is left out: the player moves it.
func _nearest_computer(team: int, point: Vector2) -> int:
	return _nearest(team, point, 1)


func _nearest(team: int, point: Vector2, first: int) -> int:
	var best := NOBODY
	var best_distance := INF
	for i in range(team * team_size + first if team == 0 else team_size, team_size + team * team_size):
		if positions[i].distance_to(point) < best_distance:
			best_distance = positions[i].distance_to(point)
			best = i
	return best


func _nearest_distance(player: int, team: int) -> float:
	return positions[player].distance_to(positions[_nearest_of(team, positions[player])])


## Config values are read once per key: the match asks for them many times per step.
func _value(key: String) -> float:
	if not _values.has(key):
		_values[key] = Config.get_float("minigame.football." + key)
	return _values[key]
