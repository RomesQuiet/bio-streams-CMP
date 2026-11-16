// Action log and avatar days (Milestone 3 Task 3, Milestone 4 Task 2, Milestone 10).
// Every activity (and every sleep) is logged with its type, the avatar time it started,
// the avatar hours actually done (Stop counts only the time done), its intensity, its
// calories and, for a meal, the kcal eaten. An avatar day runs from one wake-up to the
// next, so it closes when any sleep ends (a night, a nap, or the 0-hour rule); then its
// totals are kept and GameState.daily_update() runs. The last log_days days are kept.
// The Milestone 4 habit scores were removed in Milestone 10 Task 7.
// All numbers come from Config.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Activities} from "./activities.js";
import {Signal, get, deep_copy} from "./util.js";
import {Hunger} from "../health/hunger.js";
import {Energy} from "../health/energy.js";

export const Habits = {
	// Emitted when an avatar day closed (after any sleep, or the 0-hour rule).
	day_closed: new Signal(),
	// Avatar hours since the start of the game (awake and asleep). Start times use it.
	avatar_hours_total: 0,
	// Number of the scoring day that is running now (the first one is 0).
	current_day: 0,
	// Log entries: {type, scoring_day, start_total, day, start_minute, hours, intensity, kcal,
	// kcal_eaten}.
	entries: [],
	// Totals of the closed scoring days (see day_totals()), oldest first.
	days: [],
	// The activity that is running now: type and where it started.
	_pending: {},

	_ready() {
		Clock.avatar_time_passed.connect(_on_avatar_time_passed);
		Clock.day_started.connect(_on_day_started);
		Activities.started.connect(_on_activity_started);
		Activities.ended.connect(_on_activity_ended);
	},

	// New game: empty log.
	reset() {
		Habits.avatar_hours_total = 0;
		Habits.current_day = 0;
		Habits.entries = [];
		Habits.days = [];
		Habits._pending = {};
	},

	to_dict() {
		return {
			avatar_hours_total: Habits.avatar_hours_total,
			current_day: Habits.current_day,
			entries: deep_copy(Habits.entries),
			days: deep_copy(Habits.days),
			pending: deep_copy(Habits._pending),
		};
	},

	// Restores values from to_dict(). Call after Activities.from_dict().
	from_dict(data) {
		const h = Habits;
		h.reset();
		h.avatar_hours_total = Number(get(data, "avatar_hours_total", 0));
		h.current_day = Math.trunc(Number(get(data, "current_day", 0)));
		for (const entry of get(data, "entries", [])) {
			if (entry !== null && typeof entry === "object") {
				const restored = {...entry};
				// The scoring day and the clock day are whole numbers.
				restored.scoring_day = Math.trunc(Number(get(restored, "scoring_day", h.current_day)));
				restored.day = Math.trunc(Number(get(restored, "day", 0)));
				h.entries.push(restored);
			}
		}
		for (const day of get(data, "days", [])) {
			if (day !== null && typeof day === "object") h.days.push(day);
		}
		const pending = get(data, "pending", {});
		if (Activities.is_running()) {
			// A save in the middle of an activity: keep where it started (if known).
			h._pending = pending !== null && typeof pending === "object" && Object.keys(pending).length > 0
					? pending : _new_pending(Activities.current_option);
		}
	},

	// Adds one entry to the current scoring day. Intensity and calories come from the
	// activity option in activities.json. start: {start_total, day, start_minute}
	// (where the activity started); empty = now. Used when an activity ends, and by tests.
	add_entry(type, hours, start = {}) {
		const option = Activities.find_option(type);
		Habits.entries.push({
			type,
			scoring_day: Habits.current_day,
			start_total: Number(get(start, "start_total", Habits.avatar_hours_total)),
			day: Math.trunc(Number(get(start, "day", Clock.day_number))),
			start_minute: Number(get(start, "start_minute", Clock.minute_of_day)),
			hours,
			intensity: String(Activities.option_value(option, "activity_intensity", "")),
			kcal: _kcal_spent(option, hours),
			kcal_eaten: _meal_kcal(type, hours, option),
		});
	},

	// Totals of one scoring day: sleep hours, moderate-to-vigorous activity minutes,
	// strength days in the last log_days scoring days (this one included), entertainment
	// hours, recreational screen hours and calories.
	day_totals(day) {
		const totals = {scoring_day: day, sleep_hours: 0, activity_minutes: 0, strength_days: 0,
			entertainment_hours: 0, screen_hours: 0, kcal: 0};
		const sleep_types = Config.get_value("log.sleep_types");
		const activity_intensities = Config.get_value("log.activity_intensities");
		const strength_types = Config.get_value("log.strength_types");
		const entertainment_types = Config.get_value("log.entertainment_types");
		const screen_types = Config.get_value("log.screen_types");
		const oldest_day = day - Config.get_int("log.log_days") + 1;
		const strength_days = new Set();
		for (const entry of Habits.entries) {
			const entry_day = entry.scoring_day;
			const type = entry.type;
			const hours = entry.hours;
			if (strength_types.includes(type) && hours > 0 && entry_day >= oldest_day && entry_day <= day) strength_days.add(entry_day);
			if (entry_day !== day) continue;
			if (sleep_types.includes(type)) totals.sleep_hours += hours;
			if (activity_intensities.includes(entry.intensity)) totals.activity_minutes += hours * Clock.MINUTES_PER_HOUR;
			if (entertainment_types.includes(type)) totals.entertainment_hours += hours;
			if (screen_types.includes(type)) totals.screen_hours += hours;
			totals.kcal += Number(entry.kcal);
		}
		totals.strength_days = strength_days.size;
		return totals;
	},

	// Closes the current avatar day after a sleep of this many hours (0 for the 0-hour rule):
	// logs the sleep, keeps the day's totals, runs GameState.daily_update() and starts the next
	// day. start: where the sleep started (empty = now).
	end_scoring_day(sleep_hours, start = {}) {
		const h = Habits;
		if (sleep_hours > 0) h.add_entry(Config.get_value("log.sleep_types")[0], sleep_hours, start);
		h.days.push(h.day_totals(h.current_day));
		GameState.daily_update();
		h.current_day += 1;
		_prune();
		h.day_closed.emit();
	},
};

// kcal spent in an activity of this many hours: BMR / 24 x its mety (Milestone 10).
function _kcal_spent(option, hours) {
	const gs = GameState;
	const mety = Number(Activities.option_value(option, "mety", 0));
	return Energy.kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety) * hours;
}

// kcal of a meal entry: the share of the meal eaten in these hours (0 if not a meal).
function _meal_kcal(type, hours, option) {
	const duration = Number(get(option, "duration_hours", 0));
	if (!Hunger.is_food(type) || !(duration > 0)) return 0;
	return Hunger.meal_kcal(type, hours / duration);
}

function _on_avatar_time_passed(hours, _asleep) {
	Habits.avatar_hours_total += hours;
}

function _on_activity_started(_activity_id, option_id) {
	Habits._pending = _new_pending(option_id);
}

function _new_pending(option_id) {
	return {type: option_id, start_total: Habits.avatar_hours_total, day: Clock.day_number, start_minute: Clock.minute_of_day};
}

function _on_activity_ended(activity_id, option_id, hours_done) {
	const start = Habits._pending;
	Habits._pending = {};
	if (Activities.uses_sleep_time(activity_id)) Habits.end_scoring_day(hours_done, start);
	else if (hours_done > 0) Habits.add_entry(String(get(start, "type", option_id)), hours_done, start);
}

// The awake period ran out without sleep: it counts as 0 hours slept.
function _on_day_started(slept) {
	if (!slept) Habits.end_scoring_day(0);
}

// Keeps only the last log_days scoring days (entries and totals).
function _prune() {
	const oldest_day = Habits.current_day - Config.get_int("log.log_days") + 1;
	Habits.entries = Habits.entries.filter((entry) => entry.scoring_day >= oldest_day);
	Habits.days = Habits.days.filter((day) => day.scoring_day >= oldest_day - 1);
}
