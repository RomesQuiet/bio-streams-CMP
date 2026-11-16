// The avatar's requests (Milestone 16). Run from the project folder:
//   node web/tests/requests_test.js
import {setup, Checks} from "./harness.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {Minigame} from "../js/core/minigame.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {Requests as requests} from "../js/health/requests.js";
import {Hunger as hunger} from "../js/health/hunger.js";
import {HourWindow as hour_window} from "../js/health/hour_window.js";
import {Happiness as happiness} from "../js/health/happiness.js";

setup();
const t = new Checks();
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;

function new_avatar() {
	Activities.reset();
	Minigame.reset();
	Simulation.reset();
	gs.reset();
	Clock.reset();
	gs.start_new_avatar("Test", "child", "male", "normal");
	// A calm avatar: not tired, not hungry, screens just watched, plenty of fun.
	gs.tired = false;
	gs.hunger = 0;
	gs.hours_without_screens = 0;
	hour_window.add(gs.fun_window, gs.sim_hours, "fun", 1000);
}

function make_hungry() {
	gs.hunger = 2 * hunger.healthy_portion_kcal();
	gs.hours_since_meal = 10;
}

new_avatar();
t.check("a calm avatar asks for nothing", requests.current() === "");
gs.fun_window = happiness.starting_window();
t.check("no fun in the last day: it asks for football", requests.current() === "football");
gs.hours_without_screens = 3;
t.check("3 hours without screens comes before football", requests.current() === "screens");
gs.craving = 0.3;
make_hungry();
t.check("hungry comes before screens", requests.current() === "hungry");
gs.tired = true;
t.check("tired comes first", requests.current() === "tired");
t.check("tired uses the old text", requests.text_key("tired") === "SPEECH_TIRED");
t.check("every request has a text", Object.keys(requests.TEXT_KEYS).length === 6);

new_avatar();
make_hungry();
gs.craving = 0.8;
t.check("high craving: fast food", requests.current() === "fast_food");
gs.craving = 0.5;
t.check("craving at the threshold: fast food", requests.current() === "fast_food");
gs.craving = 0.1;
t.check("low craving: a healthy meal", requests.current() === "healthy");
gs.craving = 0.3;
t.check("in between: hungry", requests.current() === "hungry");

new_avatar();
gs.craving = 0.8;
t.check("fast food with a high craving", requests.meal_reaction("fast_food_meal") === "SPEECH_YES_FAST_FOOD");
t.check("healthy with a high craving", requests.meal_reaction("healthy_meal") === "SPEECH_NOT_AGAIN");
gs.craving = 0.1;
t.check("healthy with a low craving", requests.meal_reaction("healthy_meal") === "SPEECH_JUST_WHAT_I_WANTED");
t.check("fast food with a low craving says nothing", requests.meal_reaction("fast_food_meal") === "");
gs.craving = 0.3;
t.check("in between says nothing", requests.meal_reaction("healthy_meal") === "");
t.check("not a meal", requests.meal_reaction("cardio") === "");
gs.fitness = 0.2;
t.check("unfit: do I have to?", requests.exercise_reaction("cardio") === "SPEECH_DO_I_HAVE_TO");
gs.fitness = 0.8;
t.check("fit: let's go", requests.exercise_reaction("strength") === "SPEECH_LETS_GO");
t.check("football is not exercise here", requests.exercise_reaction("football") === "");

{
	new_avatar();
	const refused = [];
	const listener = (wish) => refused.push(wish);
	gs.wish_refused.connect(listener);
	gs.hours_without_screens = 3.99;
	happiness.step(0.05, false);
	t.check("4 hours without screens is a refused wish", refused.length === 1 && refused[0] === "screens");
	happiness.step(0.05, false);
	t.check("only once", refused.length === 1);
	t.check("the request goes away", requests.current() !== "screens");
	gs.wish_refused.disconnect(listener);
}

// Asking changes no value (decision 57).
{
	new_avatar();
	make_hungry();
	gs.craving = 0.8;
	const before = JSON.stringify(gs.to_dict());
	for (let i = 0; i < 10; i++) {
		requests.current();
		requests.meal_reaction("healthy_meal");
		requests.exercise_reaction("cardio");
	}
	t.check("asking changes no value", JSON.stringify(gs.to_dict()) === before);
}
t.finish();
