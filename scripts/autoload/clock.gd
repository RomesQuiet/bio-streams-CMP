extends Node
## Avatar time. Advances only with the game open, using frame delta time.
## It never reads the device clock. All numbers come from Config.
##
## Cycle: DAY -> SLEEPING -> SLEEP_OVER (paused, waits for the wake button) -> DAY
## Sleep can start at any time during the DAY (a nap or a night). Any sleep, short or
## long, ends the current day: after it, a new day starts with length 14 + (10 - hours slept).
## If the awake period runs out and the player has not slept, it counts as 0 hours
## slept: a new day of 14 + (10 - 0) = 24 hours starts at once, the avatar stays tired
## and the sleep recommendation stays visible. Sleep is never automatic.

## BEDTIME is no longer used (the game does not stop when the awake period runs out).
## It stays in the list so the numbers in older saves keep their meaning.
enum Phase { DAY, BEDTIME, SLEEPING, SLEEP_OVER }

const MINUTES_PER_HOUR := 60.0
const SECONDS_PER_MINUTE := 60.0
const MINUTES_PER_DAY := 24.0 * 60.0

signal time_changed
signal phase_changed(phase: Phase)
signal paused_changed(paused: bool)
## Emitted when a new day starts: after waking up, or when the awake period ran out
## without sleep (then slept is false).
signal day_started(slept: bool)
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
	reset()
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


# --- Saving (used by SaveGame) ---

## Starts time from the beginning (first day, new avatar).
func reset() -> void:
	phase = Phase.DAY
	paused = false
	day_number = 1
	day_length_hours = Config.get_float("time.first_day_hours")
	day_elapsed_hours = 0.0
	sleep_target_hours = 0.0
	sleep_elapsed_hours = 0.0
	minute_of_day = Config.get_float("time.first_day_start_hour") * MINUTES_PER_HOUR
	_phase_start_minute = minute_of_day
	phase_changed.emit(phase)
	paused_changed.emit(paused)
	time_changed.emit()


func to_dict() -> Dictionary:
	return {
		"phase": phase,
		"paused": paused,
		"day_number": day_number,
		"day_length_hours": day_length_hours,
		"day_elapsed_hours": day_elapsed_hours,
		"sleep_target_hours": sleep_target_hours,
		"sleep_elapsed_hours": sleep_elapsed_hours,
		"minute_of_day": minute_of_day,
		"phase_start_minute": _phase_start_minute,
	}


## Restores values from to_dict(). Missing keys keep their current value.
func from_dict(data: Dictionary) -> void:
	phase = clampi(int(data.get("phase", phase)), 0, Phase.size() - 1) as Phase
	var old_bedtime_save := phase == Phase.BEDTIME
	if old_bedtime_save:
		phase = Phase.DAY  # Saved by an older version, which waited at bedtime.
	paused = bool(data.get("paused", paused)) and phase == Phase.DAY
	day_number = int(data.get("day_number", day_number))
	day_length_hours = float(data.get("day_length_hours", day_length_hours))
	day_elapsed_hours = float(data.get("day_elapsed_hours", day_elapsed_hours))
	sleep_target_hours = float(data.get("sleep_target_hours", sleep_target_hours))
	sleep_elapsed_hours = float(data.get("sleep_elapsed_hours", sleep_elapsed_hours))
	minute_of_day = float(data.get("minute_of_day", minute_of_day))
	_phase_start_minute = float(data.get("phase_start_minute", _phase_start_minute))
	if old_bedtime_save:
		_start_day_without_sleep()
	phase_changed.emit(phase)
	paused_changed.emit(paused)
	time_changed.emit()


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


## Starts sleep at any time during the day (a nap or a night).
func start_sleep(hours: float) -> void:
	if not can_start_sleep():
		return
	sleep_target_hours = clampf(hours, 0.0, Config.get_float("time.max_sleep_hours"))
	sleep_elapsed_hours = 0.0
	GameState.tired = false
	GameState.changed.emit()
	_set_phase(Phase.SLEEPING)
	if sleep_target_hours <= 0.0:
		_end_sleep()


func can_start_sleep() -> bool:
	return phase == Phase.DAY


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
	day_started.emit(true)


## How light the sky is at this time of day: 1 = day, 0 = night, in between at
## dawn and dusk. Only for the look of the game; it does not change any rule.
## Uses the current time when minute is negative.
func daylight_amount(minute := -1.0) -> float:
	if minute < 0.0:
		minute = minute_of_day
	var start := Config.get_float("daylight.start_hour") * MINUTES_PER_HOUR
	var end := Config.get_float("daylight.end_hour") * MINUTES_PER_HOUR
	var twilight := Config.get_float("daylight.twilight_hours") * MINUTES_PER_HOUR
	if twilight <= 0.0:
		return 1.0 if minute >= start and minute < end else 0.0
	var dawn := clampf((minute - (start - twilight * 0.5)) / twilight, 0.0, 1.0)
	var dusk := clampf(((end + twilight * 0.5) - minute) / twilight, 0.0, 1.0)
	return minf(dawn, dusk)


## Time of day as "HH:MM" (24-hour clock).
func clock_text() -> String:
	var total_minutes := floori(minute_of_day)
	return "%02d:%02d" % [floori(total_minutes / MINUTES_PER_HOUR), total_minutes % int(MINUTES_PER_HOUR)]


func is_debug_speed_active() -> bool:
	return debug_speed != 1.0


# --- Internal ---

## Moves the clock. The time of day is worked out from the start of the phase
## (not added up frame by frame), so it lands exactly on the end of the awake period
## and on the wake-up time.
func _advance(hours: float, elapsed_in_phase: float) -> void:
	if hours <= 0.0:
		return
	minute_of_day = fposmod(_phase_start_minute + elapsed_in_phase * MINUTES_PER_HOUR, MINUTES_PER_DAY)
	avatar_time_passed.emit(hours, phase == Phase.SLEEPING)
	time_changed.emit()


## The awake period ran out and the player has not slept.
func _end_day() -> void:
	_start_day_without_sleep()
	time_changed.emit()


## Counts as 0 hours slept: a new day of 14 + (10 - 0) = 24 hours starts at once.
## The avatar stays tired (until it sleeps) and time keeps running.
func _start_day_without_sleep() -> void:
	GameState.tired = true
	GameState.changed.emit()
	day_number += 1
	day_length_hours = day_hours_after_sleep(0.0)
	day_elapsed_hours = 0.0
	_phase_start_minute = minute_of_day
	day_started.emit(false)


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
