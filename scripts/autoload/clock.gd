extends Node
## Avatar time. Advances only with the game open, using frame delta time.
## It never reads the device clock. All numbers come from Config.
##
## Cycle: DAY -> BEDTIME (day over, avatar tired, waits for the player)
##        -> SLEEPING -> SLEEP_OVER (paused, waits for the wake button) -> DAY

enum Phase { DAY, BEDTIME, SLEEPING, SLEEP_OVER }

const MINUTES_PER_HOUR := 60.0
const SECONDS_PER_MINUTE := 60.0
const MINUTES_PER_DAY := 24.0 * 60.0

signal time_changed
signal phase_changed(phase: Phase)
signal paused_changed(paused: bool)
## Emitted every frame that avatar time moves, with the avatar hours that passed
## and whether the avatar was asleep.
signal avatar_time_passed(hours: float, asleep: bool)

var phase := Phase.DAY
var paused := false
var day_number := 1
var day_length_hours: float
var day_elapsed_hours := 0.0
var sleep_target_hours := 0.0
var sleep_elapsed_hours := 0.0
## Avatar time of day, in minutes since midnight (0 to 1440).
var minute_of_day: float
## Debug only (editor): multiplies how fast time runs.
var debug_speed := 1.0

var _debug_speed_index := 0
## Time of day (minutes) when the current day or sleep started.
var _phase_start_minute: float


func _ready() -> void:
	day_length_hours = Config.get_float("time.first_day_hours")
	minute_of_day = Config.get_float("time.first_day_start_hour") * MINUTES_PER_HOUR
	_phase_start_minute = minute_of_day
	avatar_time_passed.connect(GameState.apply_avatar_hours)
	if _debug_allowed():
		print_conversion_table()


func _process(delta: float) -> void:
	if paused:
		return
	var real_seconds := minf(delta, Config.get_float("time.max_frame_seconds")) * debug_speed
	match phase:
		Phase.DAY:
			var hours := minf(real_seconds_to_avatar_hours(real_seconds, false), day_length_hours - day_elapsed_hours)
			day_elapsed_hours = minf(day_elapsed_hours + hours, day_length_hours)
			_advance(hours, day_elapsed_hours)
			if day_elapsed_hours >= day_length_hours:
				_end_day()
		Phase.SLEEPING:
			var hours := minf(real_seconds_to_avatar_hours(real_seconds, true), sleep_target_hours - sleep_elapsed_hours)
			sleep_elapsed_hours = minf(sleep_elapsed_hours + hours, sleep_target_hours)
			_advance(hours, sleep_elapsed_hours)
			if sleep_elapsed_hours >= sleep_target_hours:
				_end_sleep()


func _unhandled_input(event: InputEvent) -> void:
	if not _debug_allowed():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		var speeds: Array = Config.get_value("debug.speed_multipliers")
		_debug_speed_index = (_debug_speed_index + 1) % speeds.size()
		debug_speed = float(speeds[_debug_speed_index])
		print("Clock: debug speed x%s" % debug_speed)
		time_changed.emit()


# --- Conversion (the time rules from CLAUDE.md) ---

## Length of the next day after sleeping this many hours.
## day_hours = day_baseline + (sleep_baseline - sleep_hours). 5 h sleep -> 19 h day.
func day_hours_after_sleep(sleep_hours: float) -> float:
	var day_baseline := Config.get_float("time.day_baseline_hours")
	var sleep_baseline := Config.get_float("time.sleep_baseline_hours")
	return maxf(0.0, day_baseline + (sleep_baseline - sleep_hours))


## Real seconds needed for this many avatar hours, awake (day) or asleep (night).
func avatar_hours_to_real_seconds(hours: float, asleep: bool) -> float:
	return hours * MINUTES_PER_HOUR / _avatar_minutes_per_real_minute(asleep) * SECONDS_PER_MINUTE


## Avatar hours that pass in this many real seconds, awake (day) or asleep (night).
func real_seconds_to_avatar_hours(seconds: float, asleep: bool) -> float:
	return seconds / SECONDS_PER_MINUTE * _avatar_minutes_per_real_minute(asleep) / MINUTES_PER_HOUR


func _avatar_minutes_per_real_minute(asleep: bool) -> float:
	if asleep:
		return Config.get_float("time.sleep_avatar_minutes_per_real_minute")
	return Config.get_float("time.day_avatar_minutes_per_real_minute")


# --- Controls used by the interface ---

func set_paused(value: bool) -> void:
	if phase != Phase.DAY:
		value = false
	if paused == value:
		return
	paused = value
	paused_changed.emit(paused)


func toggle_pause() -> void:
	set_paused(not paused)


## Starts sleep. Only allowed at bedtime for now (placeholder rule).
func start_sleep(hours: float) -> void:
	if phase != Phase.BEDTIME:
		return
	sleep_target_hours = clampf(hours, 0.0, Config.get_float("time.max_sleep_hours"))
	sleep_elapsed_hours = 0.0
	GameState.tired = false
	GameState.changed.emit()
	_set_phase(Phase.SLEEPING)
	if sleep_target_hours <= 0.0:
		_end_sleep()


## Ends sleep early. The hours actually slept are used for the next day.
func stop_sleep() -> void:
	if phase == Phase.SLEEPING:
		_end_sleep()


## Starts the next day. Its length depends on the hours actually slept.
func wake_up() -> void:
	if phase != Phase.SLEEP_OVER:
		return
	day_number += 1
	day_length_hours = day_hours_after_sleep(sleep_elapsed_hours)
	day_elapsed_hours = 0.0
	_set_phase(Phase.DAY)


## Time of day as "HH:MM" (24-hour clock).
func clock_text() -> String:
	var total_minutes := floori(minute_of_day)
	return "%02d:%02d" % [floori(total_minutes / MINUTES_PER_HOUR), total_minutes % int(MINUTES_PER_HOUR)]


func is_debug_speed_active() -> bool:
	return debug_speed != 1.0


# --- Internal ---

## Moves the clock. The time of day is worked out from the start of the phase
## (not added up frame by frame), so it lands exactly on the bedtime and wake-up time.
func _advance(hours: float, elapsed_in_phase: float) -> void:
	if hours <= 0.0:
		return
	minute_of_day = fposmod(_phase_start_minute + elapsed_in_phase * MINUTES_PER_HOUR, MINUTES_PER_DAY)
	avatar_time_passed.emit(hours, phase == Phase.SLEEPING)
	time_changed.emit()


func _end_day() -> void:
	GameState.tired = true
	GameState.changed.emit()
	_set_phase(Phase.BEDTIME)


func _end_sleep() -> void:
	_set_phase(Phase.SLEEP_OVER)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_phase_start_minute = minute_of_day
	if phase != Phase.DAY:
		set_paused(false)
	phase_changed.emit(phase)
	time_changed.emit()


## The debug speed exists only when running from the Godot editor,
## so it cannot be turned on in the published (exported) game.
func _debug_allowed() -> bool:
	return OS.has_feature("editor")


func print_conversion_table() -> void:
	print("--- Clock conversion ---")
	for sleep_hours in [0.0, 5.0, 8.0, 10.0, 12.0]:
		var day_hours := day_hours_after_sleep(sleep_hours)
		print("sleep %4.1f h = %6.1f real min  ->  next day %4.1f h = %5.1f real min" % [
			sleep_hours,
			avatar_hours_to_real_seconds(sleep_hours, true) / SECONDS_PER_MINUTE,
			day_hours,
			avatar_hours_to_real_seconds(day_hours, false) / SECONDS_PER_MINUTE,
		])
