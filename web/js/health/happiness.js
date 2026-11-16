// Happiness, 0 to 1 (v1 Step 10, Milestone 10 Task 7). It moves toward a baseline with the time
// constant mood.tau_h (clock time; k does not apply) and jumps with events.
// mood.speed (user, 7 Nov 2026) slows all of it by one factor, rising and falling alike: the time
// constant is tau_h / speed and every event (per hour or at once) is x speed. Both together keep
// v1's end results (an hourly event's full effect is its rate x the time constant) and only change
// how fast happiness gets there; a slower time constant alone would make every hourly event
// stronger.
// Baseline = base + physical x Physical + sleep x Sleep + diet x Q + fun x Fun - deficit x U
// - screen_excess x screen excess - overreach x O, from 0 to 1.
// - Fun = the minutes of the last 24 avatar hours of football x 1.0, screens x 0.6 (only the
//   first 120 minutes of each day) and exercise x 0.3, divided by 90, at most 1.
// - Screen excess = (screen minutes in the last 24 avatar hours - 120) / 120, from 0 to 1.
// Events (mood.events): meals, starting exercise (it does not want to), exercise within or
// beyond the daily capacity, football, screens, 4 awake hours without screens (a wish
// refused), being hungry while awake, waking up (night quality) and being kept awake while
// very tired. All numbers come from Config.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Activities} from "../core/activities.js";
import {HourWindow} from "./hour_window.js";
import {Hunger} from "./hunger.js";
import {SleepModel} from "./sleep_model.js";
import {clampf} from "../core/util.js";

const FUN = "fun";
const SCREENS = "screens";

export const Happiness = {
	FUN,
	SCREENS,

	// A window of fun minutes and screen minutes for a new avatar (empty).
	starting_window() {
		return HourWindow.create(Config.get_int("mood.fun.window_h"), {}, [FUN, SCREENS]);
	},

	// "football", "screens", "exercise" or "" for an activity option id (mood.fun types).
	kind(option_id) {
		for (const kind_name of ["football", "screen", "exercise"]) {
			if (Config.get_value(`mood.fun.${kind_name}_types`).includes(option_id)) {
				return kind_name === "screen" ? SCREENS : kind_name;
			}
		}
		return "";
	},

	fun() {
		const window_minutes = HourWindow.total(GameState.fun_window, GameState.sim_hours, FUN);
		return clampf(window_minutes / Config.get_float("mood.fun.full_at_min"), 0, 1);
	},

	screen_excess() {
		const minutes = HourWindow.total(GameState.fun_window, GameState.sim_hours, SCREENS);
		return clampf((minutes - Config.get_float("mood.screen_excess_from_min")) / Config.get_float("mood.screen_excess_range_min"), 0, 1);
	},

	baseline() {
		const gs = GameState;
		const path = "mood.baseline.";
		return clampf(Config.get_float(path + "base") + Config.get_float(path + "physical") * gs.physical
				+ Config.get_float(path + "sleep") * gs.sleep + Config.get_float(path + "diet") * gs.diet_quality
				+ Config.get_float(path + "fun") * Happiness.fun() - Config.get_float(path + "deficit") * gs.deficit_u
				- Config.get_float(path + "screen_excess") * Happiness.screen_excess() - Config.get_float(path + "overreach") * gs.overreach,
				0, 1);
	},

	// Step 8 of the update order: fun minutes, the events of this step, then the move toward
	// the baseline.
	step(hours, asleep) {
		const gs = GameState;
		const minutes = hours * Config.get_float("units.minutes_per_hour");
		const doing = Happiness.kind(Activities.doing_option());
		const events = "mood.events.";
		let change = 0;
		if (doing === "football") {
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, minutes * Config.get_float("mood.fun.football"));
			change += Config.get_float(events + "football_per_h") * hours;
		} else if (doing === SCREENS) {
			HourWindow.add(gs.fun_window, gs.sim_hours, SCREENS, minutes);
			const counted = clampf(Config.get_float("mood.fun.screen_max_min") - gs.screen_minutes_today, 0, minutes);
			gs.screen_minutes_today += minutes;
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, counted * Config.get_float("mood.fun.screens"));
			change += Config.get_float(events + "screens_per_h") * counted / Config.get_float("units.minutes_per_hour");
		} else if (doing === "exercise") {
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, minutes * Config.get_float("mood.fun.exercise"));
			const beyond = Math.min(gs.beyond_capacity_minutes_step, minutes);
			const within_hours = (minutes - beyond) / Config.get_float("units.minutes_per_hour");
			change += Config.get_float(events + "exercise_per_h") * within_hours
					* (1 - Config.get_float(events + "exercise_tired_cut") * SleepModel.tiredness());
			change += Config.get_float(events + "beyond_capacity_per_h") * beyond / Config.get_float("units.minutes_per_hour");
		}
		if (!asleep) {
			// A wish refused: every no_screens_after_h awake hours without screens.
			gs.hours_without_screens = doing === SCREENS ? 0 : gs.hours_without_screens + hours;
			if (gs.hours_without_screens >= Config.get_float(events + "no_screens_after_h")) {
				gs.hours_without_screens -= Config.get_float(events + "no_screens_after_h");
				change += Config.get_float(events + "no_screens");
				gs.wish_refused.emit("screens");
			}
			if (gs.hunger > Config.get_float(events + "hungry_at_meals") * Hunger.healthy_portion_kcal()) {
				change += Config.get_float(events + "hungry_per_h") * hours;
			}
			if (SleepModel.tiredness() >= 1) change += Config.get_float(events + "kept_awake_per_h") * hours;
		}
		gs.happiness_baseline = Happiness.baseline();
		const speed = Config.get_float("mood.speed");
		gs.happiness = clampf(gs.happiness + change * speed, 0, 1);
		gs.happiness += (gs.happiness_baseline - gs.happiness) * (1 - Math.exp(-hours * speed / Config.get_float("mood.tau_h")));
	},

	// A meal (this share of it): healthy meal + meal - meal_craving x C; fast food + meal +
	// meal_craving x C x (1 - A). Uses C and A from before the meal (Diet changes them after).
	on_meal(food_id, share) {
		const gs = GameState;
		const events = "mood.events.";
		const craving_effect = Config.get_float(events + "meal_craving") * gs.craving;
		if (Hunger.food_value(food_id, "healthy") >= 1) {
			_jump((Config.get_float(events + "meal") - craving_effect) * share);
		} else {
			_jump((Config.get_float(events + "meal") + craving_effect * (1 - gs.habituation)) * share);
		}
	},

	// Starting cardio or strength: start_exercise x (1 - fitness) (it does not want to exercise).
	on_activity_started(option_id) {
		if (Happiness.kind(option_id) === "exercise") _jump(Config.get_float("mood.events.start_exercise") * (1 - GameState.fitness));
	},

	// Waking up after a sleep: wake x (night quality - wake_mid).
	on_wake() {
		_jump(Config.get_float("mood.events.wake") * (GameState.night_quality - Config.get_float("mood.events.wake_mid")));
	},

	// A new avatar day: the screen minutes of the day start again.
	new_day() {
		GameState.screen_minutes_today = 0;
	},
};

// An event at once (meal, starting exercise, waking), x mood.speed like every event.
function _jump(change) {
	GameState.happiness = clampf(GameState.happiness + change * Config.get_float("mood.speed"), 0, 1);
	GameState.changed.emit();
}
