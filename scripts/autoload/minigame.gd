extends Node
## The cardio minigame (Milestone 12, decisions 19 to 30; sources in MILESTONE_12.md).
## Each tap is one stride. The score follows the player: it mixes rhythm (taps at the avatar's
## interval) and pace (strides as frequent as the avatar's running pace), both averaged over the
## last strides. Training.performance() reads it instead of the fixed minigame.default_score.
## The Breath bar is the fatigue of one session: it runs down while running, faster when the
## player goes faster than the interval, and at 0 the avatar walks until it has partly refilled.
## With no tap the avatar stands still and waits, nothing counts, and the activity ends after
## minigame.wait_seconds.
## A session only exists with the main screen open (attach()), at normal speed, for an option
## with "minigame" in data/activities.json. Otherwise nothing changes: the scenario tests have
## no player and keep the fixed score.
## Listed before Simulation, so it hears that an activity started before the health system does.

const CardioPace := preload("res://scripts/health/cardio_pace.gd")

## A stride was taken. on_beat: it came at the right time.
signal strode(on_beat: bool)
## The first tap of a session: the avatar really starts the activity.
signal first_stride
## The player stopped tapping and the wait ran out.
signal gave_up
## A session started or ended.
signal session_changed

var running := false
## True while the avatar stands still, waiting for a tap.
var waiting := false
## True while the avatar walks to get its breath back.
var walking := false
## The Breath bar, 0 to 1.
var breath := 1.0
## Share of the last strides on the beat, 0 to 1.
var rhythm := 1.0
## How close the last strides came to the running pace, 0 to 1.
var pace := 1.0
var strides := 0
## Real seconds since the last stride.
var seconds_since_tap := 0.0
var last_on_beat := true

var _player_present := false
## The session comes from a save: its values stay when it starts.
var _restored := false
var _moved := false
## Taps judged so far, so the first ones are a plain average.
var _judged := 0
var _waited := 0.0
## How much faster than the interval the player is going (1 = on the beat).
var _effort := 1.0


func _ready() -> void:
	Activities.started.connect(_on_activity_started)
	Activities.ended.connect(_on_activity_ended.unbind(3))


func _process(delta: float) -> void:
	if not running:
		return
	if Clock.is_debug_speed_active():
		_end_session()
	elif not Clock.paused:
		advance(delta)


## The main screen is open: there is a player. A loaded activity goes on as a session.
func attach() -> void:
	_player_present = true
	if Activities.is_running():
		_on_activity_started("", Activities.current_option)


func detach() -> void:
	_player_present = false
	_end_session()


## No session (new avatar).
func reset() -> void:
	_end_session()
	_clear()


func to_dict() -> Dictionary:
	if not running:
		return {}
	return {"walking": walking, "breath": breath, "rhythm": rhythm, "pace": pace, "strides": strides,
			"moved": _moved, "judged": _judged}


## Restores values from to_dict(). Call after Activities.from_dict(); the session itself starts
## in attach(), waiting for a tap.
func from_dict(data: Dictionary) -> void:
	_clear()
	_restored = not data.is_empty()
	walking = bool(data.get("walking", walking))
	breath = float(data.get("breath", breath))
	rhythm = float(data.get("rhythm", rhythm))
	pace = float(data.get("pace", pace))
	strides = int(data.get("strides", strides))
	_moved = bool(data.get("moved", _moved))
	_judged = int(data.get("judged", _judged))


## True while a session is waiting for a tap: the avatar is not doing the activity.
func is_waiting() -> bool:
	return running and waiting


## The score for Training.performance(), 0 to 1.
func score() -> float:
	if not running:
		return Config.get_float("minigame.default_score")
	var weight := Config.get_float("minigame.rhythm_weight")
	return weight * rhythm + (1.0 - weight) * pace


## Real seconds the next tap should come after the last one.
func interval() -> float:
	return CardioPace.walk_interval() if walking else CardioPace.run_interval()


func steps() -> int:
	return strides * Config.get_int("minigame.steps_per_tap")


## The steps of the whole session at the avatar's running pace.
func steps_goal() -> int:
	return roundi(Clock.avatar_hours_to_real_seconds(Activities.target_hours, false) / CardioPace.run_interval()
			* Config.get_float("minigame.steps_per_tap"))


## The player tapped.
func tap() -> void:
	if not running or Clock.paused:
		return
	if waiting:
		_start_moving()
		return
	var wanted := interval()
	if seconds_since_tap < wanted * Config.get_float("minigame.min_gap_share"):
		# Too soon to be a stride: only the rhythm notices.
		_judged += 1
		rhythm = _averaged(rhythm, 0.0)
		last_on_beat = false
		return
	_judged += 1
	last_on_beat = absf(seconds_since_tap - wanted) <= wanted * Config.get_float("minigame.on_beat_share")
	rhythm = _averaged(rhythm, 1.0 if last_on_beat else 0.0)
	pace = _averaged(pace, minf(1.0, CardioPace.run_interval() / seconds_since_tap))
	_effort = wanted / seconds_since_tap
	_stride(last_on_beat)


## Real time passed while the game is not paused.
func advance(seconds: float) -> void:
	if not running:
		return
	if waiting:
		_waited += seconds
		if _waited >= Config.get_float("minigame.wait_seconds"):
			Activities.stop()
			gave_up.emit()
		return
	seconds_since_tap += seconds
	if seconds_since_tap >= Config.get_float("minigame.stall_seconds"):
		waiting = true
		_waited = 0.0
		session_changed.emit()
		return
	_update_breath(Clock.real_seconds_to_avatar_hours(seconds, false) * Config.get_float("units.minutes_per_hour"))


func _start_moving() -> void:
	waiting = false
	_effort = 1.0
	_stride(true)
	session_changed.emit()
	if not _moved:
		_moved = true
		first_stride.emit()


func _stride(on_beat: bool) -> void:
	seconds_since_tap = 0.0
	strides += 1
	strode.emit(on_beat)


func _update_breath(minutes: float) -> void:
	if walking:
		breath = minf(1.0, breath + minutes / Config.get_float("minigame.walk_recover_min"))
		walking = breath < Config.get_float("minigame.run_again_at")
	else:
		breath = maxf(0.0, breath - minutes / CardioPace.run_minutes() * _effort)
		walking = breath <= 0.0


## The average of about the last score_window_strides values.
func _averaged(value: float, sample: float) -> float:
	return value + (sample - value) / minf(_judged, Config.get_float("minigame.score_window_strides"))


func _on_activity_started(_activity_id: String, option_id: String) -> void:
	if running or not _player_present or Clock.is_debug_speed_active() \
			or not Activities.find_option(option_id).has("minigame"):
		return
	if not _restored:
		_clear()
		breath = GameState.cardio_recovery
		walking = breath <= 0.0
	_restored = false
	running = true
	waiting = true
	session_changed.emit()


func _on_activity_ended() -> void:
	_end_session()


func _end_session() -> void:
	if running:
		running = false
		waiting = false
		session_changed.emit()


func _clear() -> void:
	waiting = false
	walking = false
	breath = 1.0
	rhythm = 1.0
	pace = 1.0
	strides = 0
	seconds_since_tap = 0.0
	last_on_beat = true
	_restored = false
	_moved = false
	_judged = 0
	_waited = 0.0
	_effort = 1.0
