// What the avatar's body can do in the football minigame (Milestone 14, decisions 43 and 44).
// All numbers come from Config (group minigame.football; every one is a placeholder, see
// MILESTONE_14.md). Capacity is the same as in cardio: fitness, weight and sleepiness.
// - Speed: how fast the avatar crosses the field, slower while it jogs.
// - Free distance: how far a team-mate must be from any opponent to be free. A fitter avatar
//   reads the game better, so more passes are good.
// - Shot range: how far from goal a shot is good.
import {Config} from "../core/config.js";
import {CardioPace} from "./cardio_pace.js";

export const FootballLoad = {
	// Field units per real second.
	speed(jogging) {
		const running = _between("speed_min", "speed_range", CardioPace.capacity());
		return jogging ? running * Config.get_float("minigame.football.jog_share") : running;
	},

	free_distance() {
		return _between("free_distance_max", "free_distance_cut", -CardioPace.capacity());
	},

	shot_range() {
		return _between("shot_range_min", "shot_range_gain", CardioPace.capacity());
	},

	// Avatar minutes of steady play until the Breath bar is empty.
	play_minutes() {
		return CardioPace.run_minutes();
	},
};

function _between(base, change, share) {
	return Config.get_float("minigame.football." + base) + share * Config.get_float("minigame.football." + change);
}
