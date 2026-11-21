extends RefCounted
## One run of the screens minigame (Milestone 35, user, 21 Nov 2026): a video game. A dinosaur
## runs to the right by itself and jumps from cloud to cloud with one button, like the platforms
## of Geometry Dash. Landing on a cloud's top is safe. Hitting a cloud's side (or its underside)
## stops the dinosaur where it is, the cloud does not move, and it falls. Falling under the view
## ends the run. The run gets faster with time, like Chrome's dinosaur game, and the clouds get
## narrower, further apart and more uneven. Clouds are random but always reachable: a jump from
## the edge of a cloud clears the next one's side and lands on it.
## This script knows nothing about the screen or health; the score never changes health. It runs
## in fixed steps with its own random generator, so a seed always makes the same clouds.
## Numbers are in Config (group minigame.sky). World units: y goes up, 0 is the bottom of the view.

## The run ended (the dinosaur fell out of the view), with this score.
signal ended(score: int)

## READY: standing on the first cloud until the first press. RUNNING: running and jumping.
## FALLING: it hit a cloud and falls straight down. OVER: the run has ended.
enum State {READY, RUNNING, FALLING, OVER}

var state := State.READY
## The dinosaur: x is its back (left edge), y its feet.
var x := 0.0
var y := 0.0
var vy := 0.0
var speed := 0.0
var distance := 0.0
var grounded := true
## The button is held down: it jumps again on every landing.
var held := false
## Real seconds since the run started, and since it ended.
var run_seconds := 0.0
var over_seconds := 0.0
## The clouds around the dinosaur, left to right: {"x": left edge, "w": width, "top": top}.
var clouds: Array = []

var _rng := RandomNumberGenerator.new()
var _values := {}
var _left := 0.0
var _tick := 0.0
var _buffer_left := 0.0
var _coyote_left := 0.0
var _support := {}


func _init(seed_value: int) -> void:
	_rng.seed = seed_value
	_tick = _value("tick_seconds")
	speed = _value("start_speed")
	y = _value("start_top")
	clouds.append({"x": -_value("start_back"), "w": _value("start_width"), "top": y})
	_support = clouds[0]
	_fill()


## The player pressed (down) or let go of the button. The first press starts the run.
func press(down: bool) -> void:
	held = down
	if not down or state == State.FALLING or state == State.OVER:
		return
	_buffer_left = _value("buffer_seconds")
	if state == State.READY:
		state = State.RUNNING


func score() -> int:
	return floori(distance / _value("units_per_point"))


## 0 at the start of a run, 1 at the highest speed.
func difficulty() -> float:
	var start := _value("start_speed")
	return clampf((speed - start) / (_value("max_speed") - start), 0.0, 1.0)


## A new run may start: this one ended a moment ago.
func can_restart() -> bool:
	return state == State.OVER and over_seconds >= _value("restart_seconds")


func is_over() -> bool:
	return state == State.OVER


## Real seconds passed. Runs whole steps, so the frame rate does not change the run.
func advance(seconds: float) -> void:
	_left += seconds
	while _left >= _tick:
		_left -= _tick
		_step(_tick)


## The highest a jump goes above where it started.
func apex() -> float:
	var jump := _value("jump_speed")
	return jump * jump / (_value("gravity") + _value("gravity"))


func _step(dt: float) -> void:
	if state == State.OVER:
		over_seconds += dt
		return
	if state == State.READY:
		return
	_buffer_left -= dt
	if state == State.RUNNING:
		run_seconds += dt
		speed = minf(_value("max_speed"), _value("start_speed") + _value("speed_gain") * run_seconds)
		_run(speed * dt)
	if state == State.RUNNING and not _support.is_empty() and not _overlaps(_support):
		# It ran off the edge: a press just after still jumps.
		_support = {}
		grounded = false
		_coyote_left = _value("coyote_seconds")
	if state == State.RUNNING:
		if grounded and (held or _buffer_left > 0.0):
			_jump()
		elif not grounded:
			_coyote_left -= dt
			if _coyote_left > 0.0 and _buffer_left > 0.0:
				_jump()
	if not grounded:
		_fall(dt)
	if y + _value("dino_height") < _value("fall_out_y"):
		state = State.OVER
		over_seconds = 0.0
		ended.emit(score())
	elif state == State.RUNNING:
		_fill()


## Moves forward; the front may hit the side of a cloud, unless the feet are just under its top,
## which steps onto it.
func _run(dx: float) -> void:
	var width := _value("dino_width")
	var front_before := x + width
	x += dx
	distance += dx
	for cloud in clouds:
		if front_before > cloud.x or x + width <= cloud.x:
			continue
		var top: float = cloud.top
		if y >= top - _value("land_margin") and y <= top:
			_land(cloud)
		elif y < top and y + _value("dino_height") > top - _value("cloud_thickness"):
			var stopped_at: float = cloud.x - width
			distance -= x - stopped_at
			x = stopped_at
			_crash()
			return


func _fall(dt: float) -> void:
	var before := y
	vy -= _value("gravity") * dt
	y += vy * dt
	if state != State.RUNNING:
		return
	for cloud in clouds:
		if not _overlaps(cloud):
			continue
		var top: float = cloud.top
		var bottom := top - _value("cloud_thickness")
		var height := _value("dino_height")
		if vy <= 0.0 and before >= top and y <= top:
			_land(cloud)
			return
		if vy > 0.0 and before + height <= bottom and y + height > bottom:
			_crash()
			return


func _jump() -> void:
	vy = _value("jump_speed")
	grounded = false
	_support = {}
	_buffer_left = 0.0
	_coyote_left = 0.0


func _land(cloud: Dictionary) -> void:
	y = cloud.top
	vy = 0.0
	grounded = true
	_support = cloud


## The cloud does not move: the dinosaur stops and falls straight down, through everything.
func _crash() -> void:
	state = State.FALLING
	grounded = false
	_support = {}
	vy = minf(vy, 0.0)


func _overlaps(cloud: Dictionary) -> bool:
	return x + _value("dino_width") > cloud.x and x < cloud.x + cloud.w


## Clouds ahead of the dinosaur, and none far behind it.
func _fill() -> void:
	while clouds[-1].x + clouds[-1].w < x + _value("ahead"):
		_add_cloud()
	while clouds.size() > 1 and clouds[0].x + clouds[0].w < x - _value("behind") and not is_same(clouds[0], _support):
		clouds.pop_front()


## The next cloud, from the last one. Its height is a random step up or down; its gap a random
## share of a jump's reach at the speed the dinosaur will have there (a higher cloud is far enough
## to rise above its top first); it is long enough for a jump from the edge of the last cloud to
## land on it.
func _add_cloud() -> void:
	var last: Dictionary = clouds[-1]
	var hard := difficulty()
	var jump := _value("jump_speed")
	var gravity := _value("gravity")
	var rise := lerpf(_value("rise_easy"), _value("rise_hard"), hard) * apex()
	var drop := lerpf(_value("drop_easy"), _value("drop_hard"), hard)
	# Up or down at random; a step that would leave the view goes the other way.
	var change := _rng.randf_range(0.0, rise) if _rng.randf() < _value("up_share") else -_rng.randf_range(0.0, drop)
	var top: float = last.top + change
	if top > _value("max_top") or top < _value("min_top"):
		top = last.top - change
	top = clampf(top, maxf(_value("min_top"), last.top - drop), minf(_value("max_top"), last.top + rise))
	var step_up: float = top - last.top
	var root := sqrt(maxf(0.0, jump * jump - (gravity + gravity) * step_up))
	var air := (jump + root) / gravity
	var rising := (jump - root) / gravity if step_up > 0.0 else 0.0
	var edge: float = last.x + last.w
	var arrival := minf(_value("max_speed"), speed + _value("speed_gain") * maxf(0.0, edge - x) / speed)
	var reach := arrival * air
	var share := _rng.randf_range(lerpf(_value("gap_low_easy"), _value("gap_low_hard"), hard),
			lerpf(_value("gap_high_easy"), _value("gap_high_hard"), hard))
	var gap := maxf(_value("gap_min"), share * reach)
	if step_up > 0.0:
		# A jump from the edge: the front, one body ahead of the back, must be above the top
		# before it gets to the higher cloud.
		gap = maxf(gap, arrival * rising + _value("dino_width") + _value("rise_clearance") * reach)
	var width := _rng.randf_range(_value("width_min"), _value("width_max")) * (1.0 - _value("width_cut") * hard)
	width = maxf(width, reach - gap + _value("landing_room"))
	clouds.append({"x": edge + gap, "w": width, "top": top})


## Config values are read once per key: the run asks for them many times per step.
func _value(key: String) -> float:
	if not _values.has(key):
		_values[key] = Config.get_float("minigame.sky." + key)
	return _values[key]
