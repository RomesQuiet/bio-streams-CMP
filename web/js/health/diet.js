// Diet quality and cravings (v1 Step 7, Milestone 10 Task 7). At each meal (x = 1 for a healthy
// meal, 0 for fast food, the "healthy" value in data/foods.json):
// - diet quality Q moves toward x, and fast-food craving C toward 1 - x, by
//   1 / (time constant in avatar days x meals.per_day_ref); their time constants are body
//   time (real days / body.k);
// - habituation A to fast-food pleasure moves toward 1 - x the same way, in clock time.
// A part of a meal (Stop) moves them by that share. All numbers come from Config.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Hunger} from "./hunger.js";
import {clampf} from "../core/util.js";

export const Diet = {
	// Moves Q, C and A after eating this share (0 to 1) of a meal.
	on_meal(food_id, share) {
		const gs = GameState;
		const x = Hunger.food_value(food_id, "healthy");
		const k = Config.get_float("body.k");
		gs.diet_quality += (x - gs.diet_quality) * _rate(Config.get_float("diet.quality_tau_days") / k, share);
		gs.craving += ((1 - x) - gs.craving) * _rate(Config.get_float("diet.craving_tau_days") / k, share);
		gs.habituation += ((1 - x) - gs.habituation) * _rate(Config.get_float("diet.habituation_tau_days"), share);
	},
};

// The share of the way one meal moves a value with this time constant (avatar days).
function _rate(tau_avatar_days, share) {
	return clampf(share / (tau_avatar_days * Config.get_float("meals.per_day_ref")), 0, 1);
}
