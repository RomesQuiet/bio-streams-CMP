// Runs activities (sleep, exercise, entertainment) from data/activities.json.
// Only one activity runs at a time. Effects are applied per avatar hour as the
// Clock moves, so stopping early only counts the time actually done.
// Sleep uses the Clock's sleep time; every other activity uses day time.
import {Data} from "./data.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Minigame} from "./minigame.js";
import {Signal, get} from "./util.js";

export const Activities = {
	started: new Signal(),
	ended: new Signal(),
	// Emitted just before an activity starts or ends, while the old one (or none) still counts,
	// so Simulation can first run the minutes that belong to it.
	changing: new Signal(),
	// Emitted while an activity runs, after its effects for that frame are applied.
	progressed: new Signal(),

	// All activity definitions, by id. Tests may add their own.
	definitions: {},
	current_activity: "",
	current_option: "",
	target_hours: 0,
	elapsed_hours: 0,

	_init() {
		Activities.definitions = {};
		for (const [key, value] of Object.entries(Data.files.activities ?? {})) {
			if (!key.startsWith("_")) Activities.definitions[key] = value;
		}
	},

	_ready() {
		Clock.avatar_time_passed.connect(_on_avatar_time_passed);
		Clock.phase_changed.connect(_on_phase_changed);
	},

	is_running() {
		return Activities.current_activity !== "";
	},

	get_option(activity_id, option_id) {
		return get(get(get(Activities.definitions, activity_id, {}), "options", {}), option_id, {});
	},

	current_option_data() {
		return Activities.get_option(Activities.current_activity, Activities.current_option);
	},

	// The option the avatar is really doing: none while the minigame waits for a tap.
	doing_option() {
		return Minigame.is_waiting() ? "" : Activities.current_option;
	},

	// The option with this id in any activity (for example "cardio"), or {} if there is none.
	find_option(option_id) {
		for (const activity_id of Object.keys(Activities.definitions)) {
			const options = get(Activities.definitions[activity_id], "options", {});
			if (option_id in options) return options[option_id];
		}
		return {};
	},

	// A value of an option that may be written as {"value": ..., "status": ..., "owner": ...}.
	// Returns fallback when the option does not have it.
	option_value(option, key, fallback = null) {
		const entry = get(option, key, fallback);
		return entry !== null && typeof entry === "object" && !Array.isArray(entry) && "value" in entry ? entry.value : entry;
	},

	uses_sleep_time(activity_id) {
		return Boolean(get(get(Activities.definitions, activity_id, {}), "uses_sleep_time", false));
	},

	// Whether this activity can start now.
	can_start(activity_id) {
		if (Activities.is_running() || !(activity_id in Activities.definitions)) return false;
		if (Activities.uses_sleep_time(activity_id)) return Clock.can_start_sleep();
		return Clock.phase === Clock.Phase.DAY;
	},

	// Starts an activity option. hours is the time chosen on a slider; without it the option's
	// duration_hours is used. Sleep always needs it.
	// Returns false if it could not start.
	start(activity_id, option_id, hours = -1) {
		const a = Activities;
		const option = a.get_option(activity_id, option_id);
		if (Object.keys(option).length === 0 || !a.can_start(activity_id)) return false;
		const duration = option.duration_hours;
		a.target_hours = typeof duration === "string" || hours >= 0 ? hours : Number(duration);
		a.elapsed_hours = 0;
		a.changing.emit();
		a.current_activity = activity_id;
		a.current_option = option_id;
		// Before started, so a screen that opens at the start can pause the day again.
		if (!a.uses_sleep_time(activity_id)) Clock.set_paused(false);
		a.started.emit(activity_id, option_id);
		if (a.uses_sleep_time(activity_id)) {
			Clock.start_sleep(a.target_hours);
			if (Clock.phase !== Clock.Phase.SLEEPING && Clock.phase !== Clock.Phase.SLEEP_OVER) {
				_end();
				return false;
			}
		}
		return true;
	},

	// Ends the running activity early. Effects already applied are kept.
	stop() {
		if (!Activities.is_running()) return;
		if (Activities.uses_sleep_time(Activities.current_activity)) Clock.stop_sleep(); // The phase change then ends the activity.
		else _end();
	},

	// No activity running (new game).
	reset() {
		Activities.current_activity = "";
		Activities.current_option = "";
		Activities.target_hours = 0;
		Activities.elapsed_hours = 0;
	},

	to_dict() {
		const a = Activities;
		return {activity: a.current_activity, option: a.current_option, target_hours: a.target_hours, elapsed_hours: a.elapsed_hours};
	},

	// Restores values from to_dict(). Call after Clock.from_dict().
	from_dict(data) {
		const a = Activities;
		a.reset();
		const activity_id = String(get(data, "activity", ""));
		const option_id = String(get(data, "option", ""));
		if (Object.keys(a.get_option(activity_id, option_id)).length === 0) return;
		a.current_activity = activity_id;
		a.current_option = option_id;
		a.target_hours = Number(get(data, "target_hours", 0));
		a.elapsed_hours = Number(get(data, "elapsed_hours", 0));
		a.started.emit(a.current_activity, a.current_option);
	},
};

function _on_avatar_time_passed(hours, asleep) {
	const a = Activities;
	if (!a.is_running() || asleep !== a.uses_sleep_time(a.current_activity) || Minigame.is_waiting()) return;
	const done = Math.min(hours, a.target_hours - a.elapsed_hours);
	if (done > 0) {
		a.elapsed_hours += done;
		const option = a.current_option_data();
		GameState.apply_effects(get(option, "effects_per_hour", {}), done);
		// The calories-spent record comes from the energy spent in each step (Simulation).
	}
	a.progressed.emit();
	if (!a.uses_sleep_time(a.current_activity) && a.elapsed_hours >= a.target_hours) _end();
}

function _on_phase_changed(phase) {
	const a = Activities;
	if (!a.is_running()) return;
	const needed_phase = a.uses_sleep_time(a.current_activity) ? Clock.Phase.SLEEPING : Clock.Phase.DAY;
	if (phase !== needed_phase) _end();
}

function _end() {
	const a = Activities;
	const activity_id = a.current_activity;
	const option_id = a.current_option;
	const hours_done = a.elapsed_hours;
	a.changing.emit();
	a.reset();
	a.ended.emit(activity_id, option_id, hours_done);
}
