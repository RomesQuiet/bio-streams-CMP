// Appetite and meals (v1 Step 4, Milestone 10 Task 3). Hunger is in kcal.
// Every step: hunger += (habit_share x reference / 24 x hours + (1 - habit_share) x kcal spent
// in the step) x (1 + sleep_debt_boost x d) x (1 + thin_boost_per_sd x max(0, -z)).
// Appetite is mostly habit and only partly follows the energy spent; sleep debt raises it,
// and so does being below the median weight. It grows during sleep too.
// A meal removes kcal x satiety (data/foods.json). All numbers come from Config.
import {Config} from "../core/config.js";
import {Data} from "../core/data.js";
import {GameState} from "../core/game_state.js";
import {Energy} from "./energy.js";
import {SleepModel} from "./sleep_model.js";
import {clampf, is_equal_approx, push_error} from "../core/util.js";

export const Hunger = {
	// Step 3 of the update order. Uses the kcal spent in this step (Energy.step()).
	step(hours, _asleep) {
		const gs = GameState;
		gs.hunger += Hunger.growth(hours, gs.energy_spent_step);
		gs.hours_since_meal += hours;
	},

	// How much hunger grows in this many avatar hours when kcal_spent were spent in them.
	growth(hours, kcal_spent) {
		const gs = GameState;
		const share = Config.get_float("appetite.habit_share");
		const reference = Energy.reference_kcal_per_day(gs.sex_or_default(), gs.body_age_months);
		const habit = share * reference / Config.get_float("units.hours_per_day") * hours;
		const spending = (1 - share) * kcal_spent;
		const sleep_boost = 1 + Config.get_float("appetite.sleep_debt_boost") * SleepModel.debt_factor();
		const thin_boost = 1 + Config.get_float("appetite.thin_boost_per_sd") * Math.max(0, -gs.weight_z);
		return (habit + spending) * sleep_boost * thin_boost;
	},

	// One healthy portion for the avatar now, in kcal.
	healthy_portion_kcal() {
		return Energy.healthy_portion_kcal(GameState.sex_or_default(), GameState.body_age_months);
	},

	// "I'm hungry!": hunger is at least meals.hungry_trigger healthy meals, and at least
	// meals.min_gap_h avatar hours have passed since the last meal or skip.
	is_hungry() {
		const gs = GameState;
		return _at_least(gs.hunger, Config.get_float("meals.hungry_trigger") * Hunger.healthy_portion_kcal())
				&& _at_least(gs.hours_since_meal, Config.get_float("meals.min_gap_h"));
	},

	// kcal of a meal (an eat option id from data/foods.json), for this share of it (0 to 1).
	meal_kcal(food_id, share) {
		return Hunger.food_value(food_id, "portion_factor") * Hunger.healthy_portion_kcal() * clampf(share, 0, 1);
	},

	// Eats this share of a meal and starts the meal gap again. Returns the kcal eaten.
	// full_share: the share of the portion that already fills the avatar (the meal minigame,
	// Milestone 15). Hunger falls as if share / full_share of the portion was eaten, at most a whole
	// one, x satiety. With the default 1 it is the eaten kcal x satiety, as without a minigame.
	eat(food_id, share, full_share = 1) {
		const kcal = Hunger.meal_kcal(food_id, share);
		const filled = full_share > 0 ? Math.min(share / full_share, 1) : share;
		GameState.hunger -= Hunger.meal_kcal(food_id, filled) * Hunger.food_value(food_id, "satiety");
		GameState.hours_since_meal = 0;
		GameState.changed.emit();
		return kcal;
	},

	// Skips a meal when hungry: hunger stays, the meal gap starts again. Returns false if the
	// avatar is not hungry (nothing to skip).
	skip() {
		if (!Hunger.is_hungry()) return false;
		GameState.hours_since_meal = 0;
		GameState.changed.emit();
		return true;
	},

	// Whether an option id is a meal in data/foods.json.
	is_food(food_id) {
		return food_id in _all_foods();
	},

	food_value(food_id, key) {
		const food = _all_foods()[food_id] ?? {};
		const entry = food[key];
		if (entry === undefined || entry === null) {
			push_error(`Hunger: food '${food_id}' has no '${key}'`);
			return 0;
		}
		return Number(typeof entry === "object" ? entry.value : entry);
	},
};

let _foods = null;

function _all_foods() {
	if (_foods === null) {
		_foods = {};
		for (const [key, value] of Object.entries(Data.files.foods ?? {})) {
			if (!key.startsWith("_")) _foods[key] = value;
		}
	}
	return _foods;
}

// value >= limit, also when value is a sum of steps that lands a tiny bit below it.
function _at_least(value, limit) {
	return value >= limit || is_equal_approx(value, limit);
}
