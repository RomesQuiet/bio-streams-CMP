// The avatar's requests (Milestone 16, decisions 57 to 60, MILESTONE_16.md). A request only
// shows a wish the health model already has (concept section 4, "Wishes"; v1 Step 10): it
// changes no value. The player answers by acting: doing the activity is yes, ignoring it is no,
// and the model's own effect of a refused wish happens as before. The thresholds in the config
// group "requests" only decide when the speech bubble shows a wish.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Hunger} from "./hunger.js";
import {Happiness} from "./happiness.js";

const NONE = "";
const TIRED = "tired";
const FAST_FOOD = "fast_food";
const HEALTHY = "healthy";
const HUNGRY = "hungry";
const SCREENS = "screens";
const FOOTBALL = "football";

// The translation key of each request.
const TEXT_KEYS = {
	[TIRED]: "SPEECH_TIRED",
	[FAST_FOOD]: "SPEECH_WANT_FAST_FOOD",
	[HEALTHY]: "SPEECH_WANT_HEALTHY",
	[HUNGRY]: "SPEECH_HUNGRY",
	[SCREENS]: "SPEECH_WANT_SCREENS",
	[FOOTBALL]: "SPEECH_WANT_FOOTBALL",
};

export const Requests = {
	NONE, TIRED, FAST_FOOD, HEALTHY, HUNGRY, SCREENS, FOOTBALL, TEXT_KEYS,

	// The request to show now, the most important first (one at a time): tired, hungry (fast food,
	// a healthy meal or either), screens, football. NONE when the avatar wants nothing.
	current() {
		const gs = GameState;
		if (gs.tired) return TIRED;
		if (Hunger.is_hungry()) {
			if (gs.craving >= _value("fast_food_craving")) return FAST_FOOD;
			if (gs.craving <= _value("healthy_craving")) return HEALTHY;
			return HUNGRY;
		}
		if (gs.hours_without_screens >= _value("screens_after_h")) return SCREENS;
		if (Happiness.fun() < _value("football_fun_below")) return FOOTBALL;
		return NONE;
	},

	text_key(request) {
		return TEXT_KEYS[request] ?? "";
	},

	// What the avatar says when a meal starts, from its craving before the meal (the happiness of a
	// meal uses that craving too): "" when it has nothing to say. option_id is a food of
	// data/foods.json; anything else gives "".
	meal_reaction(option_id) {
		if (!Hunger.is_food(option_id)) return "";
		const craving = GameState.craving;
		// x of v1 Step 7: 1 for a healthy meal, 0 for fast food.
		const healthy = Hunger.food_value(option_id, "healthy") >= 1;
		if (craving >= _value("fast_food_craving")) return healthy ? "SPEECH_NOT_AGAIN" : "SPEECH_YES_FAST_FOOD";
		if (healthy && craving <= _value("healthy_craving")) return "SPEECH_JUST_WHAT_I_WANTED";
		return "";
	},

	// What the avatar says when it starts exercising (it does not want to: the happiness cost
	// grows as fitness falls). "" for other activities.
	exercise_reaction(option_id) {
		if (Happiness.kind(option_id) !== "exercise") return "";
		return GameState.fitness >= _value("keen_fitness") ? "SPEECH_LETS_GO" : "SPEECH_DO_I_HAVE_TO";
	},
};

function _value(key) {
	return Config.get_float("requests." + key);
}
