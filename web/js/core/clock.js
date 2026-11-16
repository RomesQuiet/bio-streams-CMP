// Avatar time. Advances only with the game open, using frame delta time.
// It never reads the device clock. All numbers come from Config.
//
// Cycle: DAY -> SLEEPING -> SLEEP_OVER (paused, waits for the wake button) -> DAY
// Sleep can start at any time during the DAY (a nap or a night) when the avatar is sleepy
// (is_sleepy(): enough sleep debt or enough hours awake). Any sleep, short or
// long, ends the current day: after it, a new day starts with length 14 + (10 - hours slept).
// If the awake period runs out and the player has not slept, it counts as 0 hours
// slept: a new day of 14 + (10 - 0) = 24 hours starts at once, the avatar stays tired
// and the sleep recommendation stays visible. Sleep is never automatic.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Minigame} from "./minigame.js";
import {Signal, get, clampf, fposmod, is_equal_approx, format} from "./util.js";
import {Debug} from "./debug.js";

// BEDTIME is no longer used (the game does not stop when the awake period runs out).
// It stays in the list so the numbers in older saves keep their meaning.
const Phase = {DAY: 0, BEDTIME: 1, SLEEPING: 2, SLEEP_OVER: 3};
const PHASE_COUNT = 4;
const MINUTES_PER_HOUR = 60;
const SECONDS_PER_MINUTE = 60;
const MINUTES_PER_DAY = 24 * 60;

export const Clock = {
	Phase, MINUTES_PER_HOUR, SECONDS_PER_MINUTE, MINUTES_PER_DAY,
	time_changed: new Signal(),
	phase_changed: new Signal(),
	paused_changed: new Signal(),
	// Emitted when a new day starts: after waking up, or when the awake period ran out
	// without sleep (then slept is false).
	day_started: new Signal(),
	// Emitted every frame that avatar time moves, with the avatar hours that passed
	// and whether the avatar was asleep.
	avatar_time_passed: new Signal(),

	phase: Phase.DAY,
	paused: false,
	// Time stopped for good after failure (user, 7 Nov 2026), and in the main menu. Not saved.
	// Cleared by reset().
	halted: false,
	day_number: 1,
	day_length_hours: 0,
	day_elapsed_hours: 0,
	sleep_target_hours: 0,
	sleep_elapsed_hours: 0,
	// Avatar time of day, in minutes since midnight (0 to 1440).
	minute_of_day: 0,
	// Debug only (?debug in the address): multiplies how fast time runs.
	debug_speed: 1,
	_debug_speed_index: 0,
	// Time of day (minutes) when the current day or sleep started.
	_phase_start_minute: 0,

	_ready() {
		Clock.reset();
		if (Debug.allowed()) Clock.print_conversion_table();
	},

	_process(delta) {
		const c = Clock;
		if (c.paused || c.halted) return;
		const real_seconds = Math.min(delta, Config.get_float("time.max_frame_seconds")) * c.debug_speed * Minigame.time_share();
		if (c.phase === Phase.DAY) {
			const hours = Math.min(c.real_seconds_to_avatar_hours(real_seconds, false), c.day_length_hours - c.day_elapsed_hours);
			c.day_elapsed_hours = Math.min(c.day_elapsed_hours + hours, c.day_length_hours);
			_advance(hours, c.day_elapsed_hours);
			if (c.day_elapsed_hours >= c.day_length_hours) _end_day();
		} else if (c.phase === Phase.SLEEPING) {
			const hours = Math.min(c.real_seconds_to_avatar_hours(real_seconds, true), c.sleep_target_hours - c.sleep_elapsed_hours);
			c.sleep_elapsed_hours = Math.min(c.sleep_elapsed_hours + hours, c.sleep_target_hours);
			_advance(hours, c.sleep_elapsed_hours);
			if (c.sleep_elapsed_hours >= c.sleep_target_hours) _end_sleep();
		}
	},

	// Debug: F9 changes the speed.
	_key_pressed(key) {
		if (!Debug.allowed() || key !== "F9") return;
		const speeds = Config.get_value("debug.speed_multipliers");
		Clock._debug_speed_index = (Clock._debug_speed_index + 1) % speeds.length;
		Clock.debug_speed = Number(speeds[Clock._debug_speed_index]);
		console.log(`Clock: debug speed x${Clock.debug_speed}`);
		Clock.time_changed.emit();
	},

	// --- Conversion (the time rules from CLAUDE.md) ---

	// Length of the next day after sleeping this many hours.
	// day_hours = day_baseline + (sleep_baseline - sleep_hours). 5 h sleep -> 19 h day.
	day_hours_after_sleep(sleep_hours) {
		const day_baseline = Config.get_float("time.day_baseline_hours");
		const sleep_baseline = Config.get_float("time.sleep_baseline_hours");
		return Math.max(0, day_baseline + (sleep_baseline - sleep_hours));
	},

	// Real seconds needed for this many avatar hours, awake (day) or asleep (night).
	avatar_hours_to_real_seconds(hours, asleep) {
		return hours * MINUTES_PER_HOUR / _avatar_minutes_per_real_minute(asleep) * SECONDS_PER_MINUTE;
	},

	// Avatar hours that pass in this many real seconds, awake (day) or asleep (night).
	real_seconds_to_avatar_hours(seconds, asleep) {
		return seconds / SECONDS_PER_MINUTE * _avatar_minutes_per_real_minute(asleep) / MINUTES_PER_HOUR;
	},

	// --- Saving (used by SaveGame) ---

	// Starts time from the beginning (first day, new avatar).
	reset() {
		const c = Clock;
		c.phase = Phase.DAY;
		c.paused = false;
		c.halted = false;
		c.day_number = 1;
		c.day_length_hours = Config.get_float("time.first_day_hours");
		c.day_elapsed_hours = 0;
		c.sleep_target_hours = 0;
		c.sleep_elapsed_hours = 0;
		c.minute_of_day = Config.get_float("time.first_day_start_hour") * MINUTES_PER_HOUR;
		c._phase_start_minute = c.minute_of_day;
		c.phase_changed.emit(c.phase);
		c.paused_changed.emit(c.paused);
		c.time_changed.emit();
	},

	to_dict() {
		const c = Clock;
		return {
			phase: c.phase,
			paused: c.paused,
			day_number: c.day_number,
			day_length_hours: c.day_length_hours,
			day_elapsed_hours: c.day_elapsed_hours,
			sleep_target_hours: c.sleep_target_hours,
			sleep_elapsed_hours: c.sleep_elapsed_hours,
			minute_of_day: c.minute_of_day,
			phase_start_minute: c._phase_start_minute,
		};
	},

	// Restores values from to_dict(). Missing keys keep their current value.
	from_dict(data) {
		const c = Clock;
		c.phase = clampf(Math.trunc(Number(get(data, "phase", c.phase))), 0, PHASE_COUNT - 1);
		const old_bedtime_save = c.phase === Phase.BEDTIME;
		if (old_bedtime_save) c.phase = Phase.DAY; // Saved by an older version, which waited at bedtime.
		c.paused = Boolean(get(data, "paused", c.paused)) && c.phase === Phase.DAY;
		c.day_number = Math.trunc(Number(get(data, "day_number", c.day_number)));
		c.day_length_hours = Number(get(data, "day_length_hours", c.day_length_hours));
		c.day_elapsed_hours = Number(get(data, "day_elapsed_hours", c.day_elapsed_hours));
		c.sleep_target_hours = Number(get(data, "sleep_target_hours", c.sleep_target_hours));
		c.sleep_elapsed_hours = Number(get(data, "sleep_elapsed_hours", c.sleep_elapsed_hours));
		c.minute_of_day = Number(get(data, "minute_of_day", c.minute_of_day));
		c._phase_start_minute = Number(get(data, "phase_start_minute", c._phase_start_minute));
		if (old_bedtime_save) _start_day_without_sleep();
		c.phase_changed.emit(c.phase);
		c.paused_changed.emit(c.paused);
		c.time_changed.emit();
	},

	// --- Controls used by the interface ---

	set_paused(value) {
		const c = Clock;
		if (c.phase !== Phase.DAY) value = false;
		if (c.paused === value) return;
		c.paused = value;
		c.paused_changed.emit(c.paused);
	},

	toggle_pause() {
		Clock.set_paused(!Clock.paused);
	},

	// Starts sleep at any time during the day (a nap or a night), if the avatar is sleepy.
	// It never sleeps longer than max_sleep_hours().
	start_sleep(hours) {
		const c = Clock;
		if (!c.can_start_sleep()) return;
		c.sleep_target_hours = clampf(hours, 0, c.max_sleep_hours());
		c.sleep_elapsed_hours = 0;
		GameState.changed.emit();
		_set_phase(Phase.SLEEPING);
		if (c.sleep_target_hours <= 0) _end_sleep();
	},

	can_start_sleep() {
		return Clock.phase === Phase.DAY && Clock.is_sleepy();
	},

	// v1 Step 9: the avatar can sleep only when its sleep debt is at least
	// sleep.can_sleep_debt_h or it has been awake at least sleep.can_sleep_awake_h.
	// Otherwise it says it is not sleepy.
	is_sleepy() {
		return _at_least(GameState.sleep_debt, Config.get_float("sleep.can_sleep_debt_h"))
				|| _at_least(GameState.hours_awake, Config.get_float("sleep.can_sleep_awake_h"));
	},

	// The longest sleep now: the top of the recommended range for the age group, plus the
	// smaller of the sleep debt and sleep.wake_extra_max_h (v1 Step 9). Never more than
	// time.max_sleep_hours (the end of the slider).
	max_sleep_hours() {
		const group = GameState.age_group !== "" ? GameState.age_group : Config.get_string("defaults.age_group");
		const longest = Config.get_float(`sleep.${group}_max_h`)
				+ Math.min(GameState.sleep_debt, Config.get_float("sleep.wake_extra_max_h"));
		return Math.min(longest, Config.get_float("time.max_sleep_hours"));
	},

	// Ends sleep early. The hours actually slept are used for the next day.
	stop_sleep() {
		if (Clock.phase === Phase.SLEEPING) _end_sleep();
	},

	// Starts the next day. Its length depends on the hours actually slept.
	wake_up() {
		const c = Clock;
		if (c.phase !== Phase.SLEEP_OVER) return;
		c.day_number += 1;
		c.day_length_hours = c.day_hours_after_sleep(c.sleep_elapsed_hours);
		c.day_elapsed_hours = 0;
		_set_phase(Phase.DAY);
		c.day_started.emit(true);
	},

	// How light the sky is at this time of day: 1 = day, 0 = night, in between at
	// dawn and dusk. Only for the look of the game; it does not change any rule.
	// Uses the current time when minute is negative.
	daylight_amount(minute = -1) {
		if (minute < 0) minute = Clock.minute_of_day;
		const start = Config.get_float("daylight.start_hour") * MINUTES_PER_HOUR;
		const end = Config.get_float("daylight.end_hour") * MINUTES_PER_HOUR;
		const twilight = Config.get_float("daylight.twilight_hours") * MINUTES_PER_HOUR;
		if (twilight <= 0) return minute >= start && minute < end ? 1 : 0;
		const dawn = clampf((minute - (start - twilight * 0.5)) / twilight, 0, 1);
		const dusk = clampf(((end + twilight * 0.5) - minute) / twilight, 0, 1);
		return Math.min(dawn, dusk);
	},

	// Time of day as "HH:MM" (24-hour clock).
	clock_text() {
		const total_minutes = Math.floor(Clock.minute_of_day);
		return String(Math.floor(total_minutes / MINUTES_PER_HOUR)).padStart(2, "0") + ":"
				+ String(total_minutes % MINUTES_PER_HOUR).padStart(2, "0");
	},

	is_debug_speed_active() {
		return Clock.debug_speed !== 1;
	},

	print_conversion_table() {
		console.log("--- Clock conversion ---");
		for (const sleep_hours of [0, 5, 8, 10, 12]) {
			const day_hours = Clock.day_hours_after_sleep(sleep_hours);
			console.log(format("sleep %.1f h = %.1f real min  ->  next day %.1f h = %.1f real min", [
				sleep_hours,
				Clock.avatar_hours_to_real_seconds(sleep_hours, true) / SECONDS_PER_MINUTE,
				day_hours,
				Clock.avatar_hours_to_real_seconds(day_hours, false) / SECONDS_PER_MINUTE,
			]));
		}
	},
};

function _avatar_minutes_per_real_minute(asleep) {
	return asleep ? Config.get_float("time.sleep_avatar_minutes_per_real_minute")
			: Config.get_float("time.day_avatar_minutes_per_real_minute");
}

// value >= limit, also when value is a sum of steps that lands a tiny bit below it.
function _at_least(value, limit) {
	return value >= limit || is_equal_approx(value, limit);
}

// Moves the clock. The time of day is worked out from the start of the phase
// (not added up frame by frame), so it lands exactly on the end of the awake period
// and on the wake-up time.
function _advance(hours, elapsed_in_phase) {
	const c = Clock;
	if (hours <= 0) return;
	c.minute_of_day = fposmod(c._phase_start_minute + elapsed_in_phase * MINUTES_PER_HOUR, MINUTES_PER_DAY);
	c.avatar_time_passed.emit(hours, c.phase === Phase.SLEEPING);
	c.time_changed.emit();
}

// The awake period ran out and the player has not slept.
function _end_day() {
	_start_day_without_sleep();
	Clock.time_changed.emit();
}

// Counts as 0 hours slept: a new day of 14 + (10 - 0) = 24 hours starts at once.
// The avatar stays tired (until it sleeps) and time keeps running.
function _start_day_without_sleep() {
	const c = Clock;
	GameState.changed.emit();
	c.day_number += 1;
	c.day_length_hours = c.day_hours_after_sleep(0);
	c.day_elapsed_hours = 0;
	c._phase_start_minute = c.minute_of_day;
	c.day_started.emit(false);
}

function _end_sleep() {
	_set_phase(Phase.SLEEP_OVER);
}

function _set_phase(new_phase) {
	const c = Clock;
	c.phase = new_phase;
	c._phase_start_minute = c.minute_of_day;
	if (c.phase !== Phase.DAY) c.set_paused(false);
	c.phase_changed.emit(c.phase);
	c.time_changed.emit();
}
