// How many repetitions and sets suit the avatar (Milestone 13, decisions 31 to 34).
// All numbers come from Config (group minigame; the sources are in MILESTONE_13.md).
// - Capacity (0 to 1) = strength x body x (1 - capacity_tired_cut x tiredness). The body term
//   falls with BMI-for-age z above 0, because strength per kg is lower with obesity.
// - Repetitions and sets go from the beginners' numbers of the AAP to the later ones as
//   capacity rises.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {SleepModel} from "./sleep_model.js";
import {clampf, roundf} from "../core/util.js";

export const StrengthLoad = {
	// How much of the avatar's strength it can use now, 0 to 1.
	capacity() {
		const body = Math.max(Config.get_float("minigame.body_floor"),
				1 - Config.get_float("minigame.strength_weight_cut_per_z") * Math.max(0, GameState.weight_z));
		return clampf(GameState.strength * body
				* (1 - Config.get_float("minigame.capacity_tired_cut") * SleepModel.tiredness()), 0, 1);
	},

	reps_per_set() {
		return _between("minigame.reps_min", "minigame.reps_max");
	},

	sets_goal() {
		return _between("minigame.sets_min", "minigame.sets_max");
	},
};

function _between(lowest, highest) {
	const low = Config.get_float(lowest);
	return roundf(low + StrengthLoad.capacity() * (Config.get_float(highest) - low));
}
