// The health update loop (Milestone 10, Task 2; v1 "Update order").
// The Clock moves avatar time every frame by a different amount. Simulation adds it up and
// runs the health system in fixed steps of time.step_avatar_min avatar minutes, so the
// result is the same whatever the frame rate or the debug speed (one big frame = many
// steps). When the Clock changes phase (sleep starts, sleep ends), the part of a step
// not yet run is run at once as a shorter step, so time asleep and time awake stay exact.
// Nothing runs while the game is paused or closed, because the Clock does not move then.
// Simulation starts before Activities, so it hears each frame's time while the activity of
// that frame still runs; and just before an activity starts or ends (Activities.changing) or
// the minigame's avatar changes what it is doing (Minigame.changing) the minutes not yet run
// are run, so each step uses the right METy.
// A frame that goes past the end of a day activity is split: the part after the end is
// counted when the activity has ended.
// All numbers come from Config.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Activities} from "./activities.js";
import {Minigame} from "./minigame.js";
import {Signal, get, is_equal_approx} from "./util.js";
import {Energy} from "../health/energy.js";
import {Hunger} from "../health/hunger.js";
import {BodySize} from "../health/body_size.js";
import {Training} from "../health/training.js";
import {SleepModel} from "../health/sleep_model.js";
import {Diet} from "../health/diet.js";
import {Happiness} from "../health/happiness.js";
import {HealthModel} from "../health/health_model.js";
import {Risk} from "../health/risk.js";
import {Progress} from "../health/progress.js";

export const Simulation = {
	// Emitted after each step, with the avatar hours of that step and whether the avatar slept.
	stepped: new Signal(),
	// Avatar minutes that have passed but are not a whole step yet.
	pending_minutes: 0,
	// Whether those minutes were asleep.
	pending_asleep: false,
	// Avatar hours of the current frame that come after the running day activity ends.
	_after_activity_hours: 0,
	// True while SaveGame restores a save: the Clock and Activities then repeat their events
	// (phase change, activity start), which must not run a new day or change the state again.
	loading: false,

	_ready() {
		Clock.avatar_time_passed.connect(_on_avatar_time_passed);
		Clock.phase_changed.connect(_on_phase_changed);
		Activities.changing.connect(Simulation.flush);
		Activities.started.connect(_on_activity_started);
		Clock.day_started.connect(_on_day_started);
		Activities.ended.connect(_on_activity_ended);
		Minigame.changing.connect(Simulation.flush);
		Minigame.first_stride.connect(_on_first_stride);
	},

	// Length of one step, in avatar minutes.
	step_minutes() {
		return Config.get_float("time.step_avatar_min");
	},

	// New game: nothing pending.
	reset() {
		Simulation.pending_minutes = 0;
		Simulation.pending_asleep = false;
		Simulation._after_activity_hours = 0;
	},

	to_dict() {
		return {pending_minutes: Simulation.pending_minutes, pending_asleep: Simulation.pending_asleep};
	},

	from_dict(data) {
		Simulation.pending_minutes = Number(get(data, "pending_minutes", 0));
		Simulation.pending_asleep = Boolean(get(data, "pending_asleep", false));
	},

	// Runs the minutes not yet run as one shorter step.
	flush() {
		const s = Simulation;
		if (s.pending_minutes > 0) {
			const minutes = s.pending_minutes;
			s.pending_minutes = 0;
			_step(minutes / Config.get_float("units.minutes_per_hour"), s.pending_asleep);
		}
	},
};

function _on_avatar_time_passed(hours, asleep) {
	let now = hours;
	if (Activities.is_running() && !Activities.uses_sleep_time(Activities.current_activity) && !Minigame.is_waiting()) {
		const left = Math.max(0, Activities.target_hours - Activities.elapsed_hours);
		if (hours > left) {
			now = left;
			Simulation._after_activity_hours = hours - left;
		}
	}
	_add(now, asleep);
}

// Adds avatar hours and runs every whole step in them.
function _add(hours, asleep) {
	const s = Simulation;
	if (asleep !== s.pending_asleep) s.flush();
	s.pending_asleep = asleep;
	s.pending_minutes += hours * Config.get_float("units.minutes_per_hour");
	const step = s.step_minutes();
	while (s.pending_minutes >= step || is_equal_approx(s.pending_minutes, step)) {
		s.pending_minutes = Math.max(0, s.pending_minutes - step);
		_step(step / Config.get_float("units.minutes_per_hour"), asleep);
	}
}

function _on_phase_changed(phase) {
	if (Simulation.loading) return;
	Simulation.flush();
	// Any sleep that ends (a night or a nap) resets the hours awake and starts a new avatar day.
	if (phase === Clock.Phase.SLEEP_OVER) {
		GameState.hours_awake = 0;
		SleepModel.new_day(Clock.sleep_elapsed_hours);
		Training.new_day();
		Happiness.new_day();
		Happiness.on_wake();
	}
}

// The 0-hour rule (the awake period ran out without sleep) also starts a new avatar day.
function _on_day_started(slept) {
	if (!slept && !Simulation.loading) {
		Simulation.flush();
		SleepModel.new_day(0);
		Training.new_day();
		Happiness.new_day();
	}
}

// With a minigame the avatar only really starts at the first tap or press (decision 19), so an
// activity nobody played neither costs happiness nor counts as a strength session.
function _on_activity_started(_activity_id, option_id) {
	if (!Simulation.loading && !Minigame.is_waiting()) _avatar_started(option_id);
}

function _on_first_stride() {
	_avatar_started(Activities.current_option);
}

function _avatar_started(option_id) {
	Training.on_activity_started(option_id);
	Happiness.on_activity_started(option_id);
}

// A meal counts when it ends, in proportion to the time eaten (Stop = part of a meal).
// Its minutes were already run (Activities.changing), so hunger is up to date.
function _on_activity_ended(_activity_id, option_id, hours_done) {
	if (Hunger.is_food(option_id)) {
		const duration = Number(get(Activities.find_option(option_id), "duration_hours", 0));
		let share = duration > 0 ? hours_done / duration : 1;
		let full = 1;
		// A meal the player played (Milestone 15): its bites, not its time, say how much was eaten.
		const played = Minigame.take_meal_result(option_id);
		const was_played = Object.keys(played).length > 0;
		if (was_played) {
			share = played.share;
			full = played.full_share;
		}
		if (!was_played || share > 0) {
			Energy.add_eaten(Hunger.eat(option_id, share, full));
			// The meal's happiness uses C and A from before it; then Q, C and A move.
			Happiness.on_meal(option_id, share);
			Diet.on_meal(option_id, share);
		}
	}
	// The rest of the frame, after the activity.
	if (Simulation._after_activity_hours > 0) {
		const hours = Simulation._after_activity_hours;
		Simulation._after_activity_hours = 0;
		_add(hours, false);
	}
}

// One step of the v1 update order.
function _step(hours, asleep) {
	// 1. Clock: awake or asleep (the Clock already moved the time).
	GameState.sim_hours += hours;
	if (!asleep) GameState.hours_awake += hours;
	// 2. Energy spent.
	Energy.step(hours, asleep);
	// 3. Hunger.
	Hunger.step(hours, asleep);
	// 4. Body age, height and z (weight changed in step 2 and at meals).
	BodySize.step(hours, asleep);
	// 5. Energy deficit penalty U.
	Energy.update_deficit();
	// 6. Training: capacity, recovery, overreaching, fitness and strength.
	Training.step(hours, asleep);
	// Tiredness for "I'm tired" (sleep debt and hours awake; the debt changes at each new day).
	SleepModel.update_tired();
	// 7. Physical.
	HealthModel.update_physical();
	// 8. Happiness: fun, events and the move toward its baseline.
	Happiness.step(hours, asleep);
	// 9. Health (its target follows the measures; the bar moves once per avatar day), failure
	// timers, risk and XP.
	HealthModel.step(hours, asleep);
	Risk.step(hours, asleep);
	Progress.step(hours, asleep);
	GameState.changed.emit();
	// 10. Avatar messages and images: the main screen listens to GameState.changed.
	Simulation.stepped.emit(hours, asleep);
}

// For the tests (the Godot tests call this underscored function too).
Simulation._step = _step;
