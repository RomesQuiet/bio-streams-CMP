// The avatar's running pace and how long it can keep it (Milestone 12, decisions 22 to 26).
// All numbers come from Config (group minigame; the sources are in MILESTONE_12.md).
// - Capacity (0 to 1) = fitness x body x (1 - capacity_tired_cut x tiredness). The body term
//   falls with BMI-for-age z above 0, because peak oxygen uptake per kg is lower with obesity.
// - The running cadence goes from the moderate to the vigorous threshold of the age group
//   (CADENCE-kids) as capacity rises. One tap is one stride, steps_per_tap steps.
// - Run minutes: how long the Breath bar lasts at that pace.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {SleepModel} from "./sleep_model.js";
import {clampf} from "../core/util.js";

export const CardioPace = {
	// How much of the avatar's running ability it can use now, 0 to 1.
	capacity() {
		const body = Math.max(Config.get_float("minigame.body_floor"),
				1 - Config.get_float("minigame.weight_cut_per_z") * Math.max(0, GameState.weight_z));
		return clampf(GameState.fitness * body
				* (1 - Config.get_float("minigame.capacity_tired_cut") * SleepModel.tiredness()), 0, 1);
	},

	// Real seconds between taps while running.
	run_interval() {
		const moderate = _moderate_cadence();
		const vigorous = Config.get_float("minigame.vigorous_cadence." + _age_group());
		return _interval(moderate + CardioPace.capacity() * (vigorous - moderate));
	},

	// Real seconds between taps while walking to get the breath back.
	walk_interval() {
		return _interval(Config.get_float("minigame.walk_cadence_share") * _moderate_cadence());
	},

	// Avatar minutes of running until the Breath bar is empty.
	run_minutes() {
		return Config.get_float("minigame.run_minutes_base") + Config.get_float("minigame.run_minutes_range") * CardioPace.capacity();
	},
};

function _interval(cadence) {
	return Config.get_float("minigame.steps_per_tap") * Config.get_float("units.seconds_per_minute") / cadence;
}

function _moderate_cadence() {
	return Config.get_float("minigame.moderate_cadence." + _age_group());
}

function _age_group() {
	return GameState.age_group !== "" ? GameState.age_group : Config.get_string("defaults.age_group");
}
