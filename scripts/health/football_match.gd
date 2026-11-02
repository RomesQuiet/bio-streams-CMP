extends RefCounted
## The football match of the minigame (Milestone 14, decisions 39 to 51): the idea of classic
## arcade football, seen from above. The avatar's team attacks upwards (y grows). Player 0 is the
## avatar; the others are computer players. This script knows nothing about the screen or health.
## It runs in fixed steps with its own random generator, so a seed always plays the same match.
## Numbers are in Config (group minigame.football).
## A tackle always ends: the tackler wins the ball or fails, and whoever lost is beaten for a moment
## (pushed back, standing still), so two players can never keep taking the ball from each other.
## Blue computer players never tackle or shoot by themselves: they wait for the player's button.

## What just happened, for the player. Each is a key of translations/strings.csv.
signal happened(key: String)
## A tackle ended. won: the tackler has the ball now.
signal tackled(tackler: int, carrier: int, won: bool)

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
## Real seconds each player is still beaten after losing a tackle.
var _beaten_left: Array[float] = []
## Defender -> the attacker it marks, worked out every step.
var _marks := {}
## Who made the last tackle the button asked for, or NOBODY.
var last_tackler := NOBODY


func _init(seed_value: int) -> void:
	_rng.seed = seed_value
	team_size = Config.get_int("minigame.football.team_size")
	_formation = Config.get_value("minigame.football.formation")
	width = _value("field_width")
	length = _value("field_length")
	_tick = _value("tick_seconds")
	positions.resize(team_size + team_size)
	_beaten_left.resize(positions.size())
	kick_off(true)


## Everyone back to their places. The team that kicks off has the ball.
## stop: the match stops for a moment first, so the player can see what happened.
func kick_off(ours: bool, stop := false) -> void:
	_pause_left = _value("restart_seconds") if stop else 0.0
	for i in positions.size():
		positions[i] = _home(i, false)
		_beaten_left[i] = 0.0
	owner = 0 if ours else team_size
	ball = positions[owner]
	flight = Flight.NONE
	_receiver = NOBODY
	_decide_left = _value("cpu_decide_seconds")
	_tackle_left = _value("cpu_tackle_seconds")
	_safe_left = _value("protect_seconds")


## Real seconds passed. Runs whole steps, so the frame rate does not change the match.
func advance(seconds: float) -> void:
	_left += seconds * _value("match_pace")
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


## The player the button would use to tackle: the avatar if it is close enough, or the nearest
## blue player who is, or NOBODY.
func tackler_in_reach() -> int:
	if not defending():
		return NOBODY
	var reach := _value("tackle_reach")
	if positions[0].distance_to(positions[owner]) <= reach:
		return 0
	var nearest := _nearest_computer(0, positions[owner])
	return nearest if positions[nearest].distance_to(positions[owner]) <= reach else NOBODY


func in_tackle_reach() -> bool:
	return tackler_in_reach() != NOBODY


## A player lost a tackle a moment ago.
func is_beaten(player: int) -> bool:
	return _beaten_left[player] > 0.0


## A team-mate has the ball: the player can ask for it.
func team_mate_has_ball() -> bool:
	return owner > 0 and owner < team_size


## A team-mate has the ball close enough to goal for a good shot.
func team_mate_in_shot_range() -> bool:
	return team_mate_has_ball() and positions[owner].distance_to(_goal(0)) <= shot_range


## An opponent is close to the avatar.
func under_pressure() -> bool:
	return _nearest_distance(0, 1) < _value("cpu_press_radius")


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
	_shoot(_shot_chance(0, _value("goal_chance_good") if good else _value("goal_chance_far")))
	return good


## The player pressed Shoot while a team-mate has the ball. Returns true for a good shot.
func team_mate_shoot() -> bool:
	if not team_mate_has_ball():
		return false
	var good := team_mate_in_shot_range()
	if not good:
		happened.emit("FOOTBALL_SHOT_FAR")
	_shoot(_shot_chance(owner, _value("goal_chance_good") if good else _value("goal_chance_far")))
	return good


## The player pressed Tackle, at most once per tackle time. The avatar tackles if it is close
## enough, otherwise the nearest blue player who is. Returns true if someone was within reach,
## a good tackle even if it does not always win the ball.
func tackle() -> bool:
	if not can_tackle():
		return false
	_own_tackle_left = _value("tackle_seconds")
	last_tackler = tackler_in_reach()
	if last_tackler == NOBODY:
		happened.emit("FOOTBALL_TACKLE_FAR")
		return false
	var won := _resolve_tackle(last_tackler, _value("tackle_chance"))
	happened.emit("FOOTBALL_TACKLE_WON" if won else "FOOTBALL_TACKLE_MISSED")
	return true


func _step(seconds: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= seconds
		return
	_own_tackle_left -= seconds
	_safe_left -= seconds
	_assign_marks()
	var move := stick.limit_length(1.0) * avatar_speed * seconds
	positions[0] = _on_field(positions[0] + move)
	for i in range(1, positions.size()):
		if is_beaten(i):
			_beaten_left[i] -= seconds
		else:
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
			if _team(i) != _team(_receiver) and not is_beaten(i) and positions[i].distance_to(ball) <= _value("intercept_radius"):
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


## Who has the ball, or will have it when the pass lands, or NOBODY.
func _holder() -> int:
	return owner if owner != NOBODY else _receiver


## Where a computer player wants to go.
func _target(player: int) -> Vector2:
	var team := _team(player)
	if player == owner:
		return _carrier_target(player)
	var holder := _holder()
	if holder == NOBODY:
		return ball if player == _nearest_computer(team, ball) else _support(player)
	return _support(player) if _team(holder) == team else _defend(player, holder)


## With the ball: towards goal, going around an opponent in the way. A blue player stops in
## shooting distance and waits for the player's button.
func _carrier_target(player: int) -> Vector2:
	var team := _team(player)
	var here := positions[player]
	if team == 0 and here.distance_to(_goal(team)) <= _value("mate_hold_range"):
		return here
	var way := here.direction_to(_goal(team))
	var rival := positions[_nearest_of(1 - team, here)] - here
	if rival.length() < _value("dodge_radius") and rival.dot(way) > 0.0:
		var side := way.orthogonal()
		way = (way + (-side if side.dot(rival) > 0.0 else side) * _value("dodge_share")).normalized()
	return here + way * length


## Attacking without the ball: ahead of the ball, away from the nearest opponent.
func _support(player: int) -> Vector2:
	var team := _team(player)
	var spot := _home(player, true)
	var holder := _holder()
	# Attackers run ahead of the ball, so a forward pass is possible. The last player stays back.
	if holder != NOBODY and _team(holder) == team and player != team * team_size + team_size - 1:
		var ahead := positions[holder].y + _up(team) * _value("support_push")
		spot.y = maxf(spot.y, ahead) if team == 0 else minf(spot.y, ahead)
	var away := spot - positions[_nearest_of(1 - team, spot)]
	var room := _value("support_room")
	if away.length() < room:
		spot += away.normalized() * (room - away.length())
	return _on_field(spot)


## Defending, blue: the nearest player follows whoever has the ball from behind, close enough for
## the button to use it to tackle but never in its way. Red defends better: the nearest player goes to the side of its goal, the last
## player guards the goal, and the others mark the attackers.
func _defend(player: int, holder: int) -> Vector2:
	var team := _team(player)
	if team == 0:
		var closest := player == _nearest_computer(team, positions[holder])
		return positions[holder] - positions[holder].direction_to(_goal(1)) * _value("press_gap") if closest else _home(player, true)
	var own_goal := _goal(1 - team)
	if player == _nearest_computer(team, positions[holder]):
		return positions[holder] + positions[holder].direction_to(own_goal) * _value("press_gap")
	if player == _keeper():
		return own_goal + own_goal.direction_to(ball) * _value("keeper_depth")
	if _marks.has(player):
		var mark: Vector2 = positions[_marks[player]]
		return mark + mark.direction_to(own_goal) * _value("mark_gap")
	return _home(player, true)


## Red's last defender.
func _keeper() -> int:
	return team_size + team_size - 1


## Each free red defender takes the most dangerous blue attacker left: the one nearest its goal.
func _assign_marks() -> void:
	_marks.clear()
	var holder := _holder()
	if holder == NOBODY or _team(holder) == 1:
		return
	var own_goal := _goal(0)
	var attackers: Array[int] = []
	for i in _members(0, 0):
		if i != holder:
			attackers.append(i)
	attackers.sort_custom(func(a: int, b: int) -> bool:
		return positions[a].distance_to(own_goal) < positions[b].distance_to(own_goal))
	var presser := _nearest_computer(1, positions[holder])
	var spare: Array[int] = []
	for i in _members(1, 0):
		if i != presser and i != _keeper() and not is_beaten(i):
			spare.append(i)
	for attacker in attackers:
		var best := NOBODY
		for defender in spare:
			if best == NOBODY or positions[defender].distance_to(positions[attacker]) < positions[best].distance_to(positions[attacker]):
				best = defender
		if best != NOBODY:
			_marks[best] = attacker
			spare.erase(best)


## A red player tries to take the ball from a close blue player, at most once per tackle time.
## Blue computer players only tackle when the player presses the button.
func _computer_tackle(seconds: float) -> void:
	_tackle_left -= seconds
	if _tackle_left > 0.0 or owner == NOBODY or _team(owner) == 1 or _safe_left > 0.0:
		return
	var tackler := _nearest_computer(1, positions[owner])
	if positions[tackler].distance_to(positions[owner]) > _value("cpu_tackle_reach"):
		return
	_tackle_left = _value("cpu_tackle_seconds")
	var carrier := owner
	if _resolve_tackle(tackler, _value("cpu_tackle_chance")) and carrier == 0:
		happened.emit("FOOTBALL_LOST_BALL")


## A tackle always ends here: the tackler wins the ball or fails, and the loser is beaten.
## Returns true if the tackler won.
func _resolve_tackle(tackler: int, chance: float) -> bool:
	var carrier := owner
	var won := _rng.randf() < chance
	_beat(carrier if won else tackler, tackler if won else carrier)
	if won:
		_receive(tackler)
	tackled.emit(tackler, carrier, won)
	return won


## The loser of a tackle is pushed back and stands still for a moment. The player's avatar always
## keeps moving, but it cannot tackle back at once.
func _beat(loser: int, winner: int) -> void:
	if loser == 0:
		_own_tackle_left = _value("tackle_seconds")
		return
	var away := positions[winner].direction_to(positions[loser])
	positions[loser] = _on_field(positions[loser] + (away if away != Vector2.ZERO else Vector2.RIGHT) * _value("knockback"))
	_beaten_left[loser] = _value("beaten_seconds")


## A computer player with the ball decides from time to time. Red shoots when it has a clear
## chance and only passes forward, so it keeps attacking. Blue only passes to escape pressure:
## its shots wait for the player's button.
func _computer_carrier(seconds: float) -> void:
	if owner == NOBODY or owner == 0:
		return
	_decide_left -= seconds
	if _decide_left > 0.0:
		return
	_decide_left = _value("cpu_decide_seconds")
	var team := _team(owner)
	if team == 1 and _wants_to_shoot(owner):
		_shoot(_shot_chance(owner, _value("cpu_goal_chance")))
		return
	var mate := _best_pass(owner)
	if mate == NOBODY:
		return
	var pressed := _nearest_distance(owner, 1 - team) < _value("cpu_press_radius")
	var forward := (positions[mate].y - positions[owner].y) * _up(team)
	if team == 0:
		if pressed:
			_pass_to(mate)
	elif (pressed and forward >= 0.0) or (forward >= _value("pass_gain") and _rng.randf() < _value("cpu_pass_chance")):
		_pass_to(mate)


## In range with a clear view of the goal, or so close that it does not matter.
func _wants_to_shoot(player: int) -> bool:
	var distance := positions[player].distance_to(_goal(_team(player)))
	if distance > _value("cpu_shot_range"):
		return false
	return distance <= _value("close_range") or not _shot_blocked(player)


## The goal chance of a shot, lower when a defender stands in its way.
func _shot_chance(player: int, chance: float) -> float:
	return chance * _value("block_share") if _shot_blocked(player) else chance


## A defender stands on the line of the shot. Red's last defender does not count: the goal
## chance already includes a goalkeeper, and it always stands on that line.
func _shot_blocked(player: int) -> bool:
	var team := _team(player)
	return _lane_blocked(positions[player], _goal(team), 1 - team, _value("block_radius"), _keeper())


## A player of team stands within radius of the line from from to to. A player behind the start
## (its nearest point on the line is the start itself) is not in the way.
func _lane_blocked(from: Vector2, to: Vector2, team: int, radius: float, ignored := NOBODY) -> bool:
	for i in _members(team, 0):
		if i == ignored or is_beaten(i):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(positions[i], from, to)
		if not closest.is_equal_approx(from) and closest.distance_to(positions[i]) <= radius:
			return true
	return false


## The team-mate worth passing to: free, further forward, and with no opponent in the way.
func _best_pass(player: int) -> int:
	var team := _team(player)
	var best := NOBODY
	var best_value := -INF
	for i in _members(team, 0):
		if i == player or _lane_blocked(positions[player], positions[i], 1 - team, _value("lane_radius")):
			continue
		var forward := (positions[i].y - positions[player].y) * _up(team)
		var value := _nearest_distance(i, 1 - team) + forward * _value("forward_weight")
		if value > best_value:
			best_value = value
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


## +1 for the team attacking up the field, -1 for the other.
func _up(team: int) -> float:
	return 1.0 if team == 0 else -1.0


func _members(team: int, first: int) -> Array:
	return range(team * team_size + first, team * team_size + team_size)


func _on_field(point: Vector2) -> Vector2:
	return point.clamp(Vector2.ZERO, Vector2(width, length))


func _nearest_of(team: int, point: Vector2) -> int:
	return _nearest(team, point, 0)


## The avatar is left out: the player moves it. For the other team, nobody is left out, because
## first only skips a player of the avatar's team.
func _nearest_computer(team: int, point: Vector2) -> int:
	return _nearest(team, point, 1 - team)


## The nearest player who is not beaten.
func _nearest(team: int, point: Vector2, first: int) -> int:
	var best := NOBODY
	var best_distance := INF
	for i in _members(team, first):
		if not is_beaten(i) and positions[i].distance_to(point) < best_distance:
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
