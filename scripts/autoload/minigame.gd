extends Node
## The minigames (sources in MILESTONE_12.md and MILESTONE_13.md). Training.performance() reads
## score() instead of the fixed minigame.default_score: it mixes rhythm and pace and follows the
## player. The reserve is the fatigue of one session, shown as a bar.
## Cardio (decisions 19 to 30): each tap is one stride. Rhythm: taps at the avatar's interval.
## Pace: strides as frequent as the avatar's running pace. The reserve (Breath) runs down while
## running, faster above the interval, and at 0 the avatar walks until it has partly refilled.
## Strength (decisions 31 to 38): Down then Up is one repetition. Rhythm: the technique, each
## press in turn at a controlled pace. Pace: repetitions done of those planned. The reserve
## (Muscle) falls with each repetition, faster when rushing; a set ends at its repetitions or
## with the reserve empty, and the avatar rests. More sets follow until the time ends.
## With no tap or press the avatar stands still and waits, nothing counts, and the activity ends
## after minigame.wait_seconds. The rest between sets is not waiting.
## A session only exists with the main screen open (attach()), at normal speed, for an option
## with "minigame" in data/activities.json. Otherwise nothing changes: the scenario tests have
## no player and keep the fixed score.
## Listed before Simulation, so it hears that an activity started before the health system does.

const CardioPace := preload("res://scripts/health/cardio_pace.gd")
const StrengthLoad := preload("res://scripts/health/strength_load.gd")

const CARDIO := "cardio"
const STRENGTH := "strength"

## A stride or a press was made. on_beat: it came at the right time.
signal strode(on_beat: bool)
## The first tap or press of a session: the avatar really starts the activity.
signal first_stride
## The player stopped and the wait ran out.
signal gave_up
## A session started or ended, the avatar stopped or started moving, or a rest began or ended.
signal session_changed
## Emitted just before the avatar stops, starts, walks or runs, so Simulation can first run the
## minutes that belong to what it was doing (like Activities.changing).
signal changing

var running := false
## CARDIO or STRENGTH while a session runs.
var kind := ""
## True while the avatar stands still, waiting for a tap or press.
var waiting := false
## Cardio: true while the avatar walks to get its breath back.
var walking := false
## Strength: true during the rest between sets.
var resting := false
## The fatigue of the session, 0 to 1: the Breath or Muscle bar.
var reserve := 1.0
## Share of the last strides or presses on the beat, 0 to 1.
var rhythm := 1.0
## Cardio: how close the last strides came to the running pace. Strength: repetitions done of
## those planned in the sets so far. 0 to 1.
var pace := 1.0
## Strides (cardio) or repetitions (strength) of the session.
var strides := 0
## Real seconds since the last stride or press.
var seconds_since_tap := 0.0
var last_on_beat := true
## Strength: whether Down is the next press, and the set being done.
var next_down := true
var sets_started := 0
var sets_goal := 0
var reps_in_set := 0
var set_reps := 0

var _player_present := false
## The session comes from a save: its values stay when it starts.
var _restored := false
var _moved := false
## Taps judged so far, so the first ones are a plain average.
var _judged := 0
var _waited := 0.0
## How much faster than the interval the player is going (1 = on the beat).
var _effort := 1.0
## Strength: real seconds of rest left, and the repetitions planned in the finished sets.
var _rest_left := 0.0
var _reps_planned := 0
## Strength: the next press has no press before it to be timed against.
var _untimed := true


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
	return {"walking": walking, "resting": resting, "reserve": reserve, "rhythm": rhythm, "pace": pace,
			"strides": strides, "moved": _moved, "judged": _judged, "next_down": next_down,
			"sets_started": sets_started, "sets_goal": sets_goal, "reps_in_set": reps_in_set,
			"set_reps": set_reps, "rest_left": _rest_left, "reps_planned": _reps_planned}


## Restores values from to_dict(). Call after Activities.from_dict(); the session itself starts
## in attach(), waiting for a tap or press, or going on with its rest.
func from_dict(data: Dictionary) -> void:
	_clear()
	_restored = not data.is_empty()
	walking = bool(data.get("walking", walking))
	resting = bool(data.get("resting", resting))
	reserve = float(data.get("reserve", reserve))
	rhythm = float(data.get("rhythm", rhythm))
	pace = float(data.get("pace", pace))
	strides = int(data.get("strides", strides))
	_moved = bool(data.get("moved", _moved))
	_judged = int(data.get("judged", _judged))
	next_down = bool(data.get("next_down", next_down))
	sets_started = int(data.get("sets_started", sets_started))
	sets_goal = int(data.get("sets_goal", sets_goal))
	reps_in_set = int(data.get("reps_in_set", reps_in_set))
	set_reps = int(data.get("set_reps", set_reps))
	_rest_left = float(data.get("rest_left", _rest_left))
	_reps_planned = int(data.get("reps_planned", _reps_planned))


## True while a session is waiting for the player: the avatar is not doing the activity.
func is_waiting() -> bool:
	return running and waiting


## True while a session has the avatar walking to get its breath back.
func is_walking() -> bool:
	return running and walking


## The score for Training.performance(), 0 to 1.
func score() -> float:
	if not running:
		return Config.get_float("minigame.default_score")
	var weight := Config.get_float("minigame.rhythm_weight")
	return weight * rhythm + (1.0 - weight) * pace


## Real seconds the next tap or press should come after the last one.
func interval() -> float:
	if kind == STRENGTH:
		return Config.get_float("minigame.press_seconds")
	return CardioPace.walk_interval() if walking else CardioPace.run_interval()


func steps() -> int:
	return strides * Config.get_int("minigame.steps_per_tap")


## The steps of the whole session at the avatar's running pace.
func steps_goal() -> int:
	return roundi(Clock.avatar_hours_to_real_seconds(Activities.target_hours, false) / CardioPace.run_interval()
			* Config.get_float("minigame.steps_per_tap"))


## The player tapped (cardio).
func tap() -> void:
	if not running or kind != CARDIO or Clock.paused:
		return
	if waiting:
		_start_moving()
		_stride(true)
		return
	var wanted := interval()
	if seconds_since_tap < wanted * Config.get_float("minigame.min_gap_share"):
		# Too soon to be a stride: only the rhythm notices.
		_judge(false)
		return
	_judge(_on_time(wanted))
	pace = _averaged(pace, minf(1.0, CardioPace.run_interval() / seconds_since_tap))
	_effort = wanted / seconds_since_tap
	_stride(last_on_beat)


## The player pressed Down or Up (strength). Only the expected button moves the avatar.
func press(down: bool) -> void:
	if not running or kind != STRENGTH or resting or Clock.paused:
		return
	if down != next_down:
		if not waiting:
			_judge(false)
		return
	if waiting:
		_start_moving()
	if _untimed:
		_untimed = false
		last_on_beat = true
		_effort = 1.0
	else:
		var wanted := interval()
		_judge(_on_time(wanted))
		_effort = wanted / maxf(seconds_since_tap, wanted * Config.get_float("minigame.min_gap_share"))
	seconds_since_tap = 0.0
	next_down = not down
	strode.emit(last_on_beat)
	if not down:
		_finish_repetition()


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
	if resting:
		_rest(seconds)
		return
	seconds_since_tap += seconds
	if seconds_since_tap >= Config.get_float("minigame.stall_seconds"):
		changing.emit()
		waiting = true
		_waited = 0.0
		session_changed.emit()
		return
	if kind == CARDIO:
		_update_breath(Clock.real_seconds_to_avatar_hours(seconds, false) * Config.get_float("units.minutes_per_hour"))


func _start_moving() -> void:
	changing.emit()
	waiting = false
	_effort = 1.0
	_untimed = true
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
		reserve = minf(1.0, reserve + minutes / Config.get_float("minigame.walk_recover_min"))
		if reserve >= Config.get_float("minigame.run_again_at"):
			changing.emit()
			walking = false
	else:
		reserve = maxf(0.0, reserve - minutes / CardioPace.run_minutes() * _effort)
		if reserve <= 0.0:
			changing.emit()
			walking = true


## Up finished a repetition. The set ends at its repetitions or when the muscles are tired: the
## avatar never trains to failure.
func _finish_repetition() -> void:
	strides += 1
	reps_in_set += 1
	reserve = maxf(0.0, reserve - _effort / (Config.get_float("minigame.reps_margin") * set_reps))
	if reps_in_set >= set_reps or reserve <= 0.0:
		resting = true
		_rest_left = Config.get_float("minigame.rest_seconds")
		_reps_planned += set_reps
		pace = minf(1.0, float(strides) / _reps_planned)
		session_changed.emit()


## The rest refills part of the reserve, then the next set starts.
func _rest(seconds: float) -> void:
	var share := minf(seconds, _rest_left) / Config.get_float("minigame.rest_seconds")
	reserve = minf(1.0, reserve + share * Config.get_float("minigame.rest_refill"))
	_rest_left -= seconds
	if _rest_left <= 0.0:
		_start_set()
		session_changed.emit()


func _start_set() -> void:
	resting = false
	sets_started += 1
	reps_in_set = 0
	set_reps = StrengthLoad.reps_per_set()
	next_down = true
	seconds_since_tap = 0.0
	_untimed = true


func _on_time(wanted: float) -> bool:
	return absf(seconds_since_tap - wanted) <= wanted * Config.get_float("minigame.on_beat_share")


## One more tap or press judged for the rhythm.
func _judge(on_beat: bool) -> void:
	_judged += 1
	last_on_beat = on_beat
	rhythm = _averaged(rhythm, 1.0 if on_beat else 0.0)


## The average of about the last score_window_strides values, or a plain average of the first.
func _averaged(value: float, sample: float) -> float:
	return value + (sample - value) / minf(_judged, Config.get_float("minigame.score_window_strides"))


func _on_activity_started(_activity_id: String, option_id: String) -> void:
	var option_kind := str(Activities.find_option(option_id).get("minigame", ""))
	if running or not _player_present or Clock.is_debug_speed_active() or option_kind.is_empty():
		return
	kind = option_kind
	if not _restored:
		_clear()
		if kind == STRENGTH:
			reserve = GameState.strength_recovery
			sets_goal = StrengthLoad.sets_goal()
			_start_set()
		else:
			reserve = GameState.cardio_recovery
			walking = reserve <= 0.0
	_restored = false
	running = true
	# A rest goes on by itself after a reload; anything else waits for the player.
	waiting = not resting
	session_changed.emit()


func _on_activity_ended() -> void:
	_end_session()


func _end_session() -> void:
	if running:
		running = false
		kind = ""
		waiting = false
		session_changed.emit()


func _clear() -> void:
	waiting = false
	walking = false
	resting = false
	reserve = 1.0
	rhythm = 1.0
	pace = 1.0
	strides = 0
	seconds_since_tap = 0.0
	last_on_beat = true
	next_down = true
	sets_started = 0
	sets_goal = 0
	reps_in_set = 0
	set_reps = 0
	_restored = false
	_moved = false
	_judged = 0
	_waited = 0.0
	_effort = 1.0
	_rest_left = 0.0
	_reps_planned = 0
	_untimed = true
