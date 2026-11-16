// Tests for the activity system. Run from the project folder:  node web/tests/activities_test.js
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState as game_state} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits as habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {Energy as energy} from "../js/health/energy.js";
import {SleepModel} from "../js/health/sleep_model.js";
import {format, is_equal_approx} from "../js/core/util.js";

const STEP_SECONDS = 0.1;
const TOLERANCE = 0.0001;
setup();
const t = new Checks();
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
activities.reset();
game_state.reset();
clock.reset();
clock.debug_speed = 600;
let ended_hours = -1;
activities.ended.connect((_a, _o, hours) => ended_hours = hours);

// Sleep.
{
	t.check("sleep is defined in activities.json", "sleep" in activities.definitions);
	// v1 can-sleep rule: with no sleep debt and 0 h awake the avatar is not sleepy; after
	// sleep.can_sleep_awake_h awake it can nap.
	game_state.sleep_debt = 0;
	t.check("no debt, 0 h awake: not sleepy", !activities.can_start("sleep"));
	game_state.hours_awake = Config.get_float("sleep.can_sleep_awake_h");
	t.check("sleep can start during the day (nap) once sleepy", activities.can_start("sleep"));
	run_until_new_day();
	t.check("sleep starts when the avatar is tired", activities.start("sleep", "sleep", 10));
	t.check("sleep runs through the activity system", activities.is_running() && activities.current_activity === "sleep");
	t.check("clock is sleeping", clock.phase === clock.Phase.SLEEPING);
	t.check("a second activity cannot start", !activities.can_start("sleep"));
	while (activities.elapsed_hours < 5) clock._process(STEP_SECONDS);
	const slept = activities.elapsed_hours;
	activities.stop();
	t.check("stop ends the activity", !activities.is_running());
	t.check("stop reports the hours done", Math.abs(ended_hours - slept) < TOLERANCE);
	t.check("sleep has no per-hour effect", Object.keys(activities.get_option("sleep", "sleep").effects_per_hour).length === 0);
	t.check("the sleep measure comes from the debt after the hours slept (v1 Step 9)", is_equal_approx(game_state.sleep,
			SleepModel.sleep_measure(game_state.sleep_debt, SleepModel.oversleep(slept, game_state.age_group))));
	t.check("clock waits for the wake button", clock.phase === clock.Phase.SLEEP_OVER);
	clock.wake_up();
}

// A day activity.
{
	// A test-only activity, so the day path is checked before exercise exists.
	activities.definitions.test_play = {
		name: "Test",
		options: {play: {name: "Play", duration_hours: 2, effects_per_hour: {calories_spent: 10}, animation: "hop"}},
	};
	let record_before = game_state.calories_spent;
	const day_before = clock.day_elapsed_hours;
	t.check("day activity starts", activities.start("test_play", "play"));
	t.check("sleep is locked while it runs", !activities.can_start("sleep"));
	while (activities.is_running()) clock._process(STEP_SECONDS);
	t.check("day activity ends by itself after 2 h", Math.abs(ended_hours - 2) < TOLERANCE);
	t.check("full effect applied (+20 in the calories record)", Math.abs(game_state.calories_spent - (record_before + 20)) < TOLERANCE);
	t.check("day time moved on", clock.day_elapsed_hours >= day_before + 2 - TOLERANCE);
	record_before = game_state.calories_spent;
	clock.debug_speed = 60; // Smaller steps, so the stop lands close to 1 h.
	activities.start("test_play", "play");
	while (activities.elapsed_hours < 1) clock._process(STEP_SECONDS);
	const done = activities.elapsed_hours;
	activities.stop();
	t.check("stop halfway applies about half", Math.abs(game_state.calories_spent - (record_before + 10 * done)) < TOLERANCE && Math.abs(done - 1) < 0.1);
	const record_after = game_state.calories_spent;
	clock._process(STEP_SECONDS);
	t.check("no effects after the activity ends", is_equal_approx(game_state.calories_spent, record_after));
	delete activities.definitions.test_play;
}

// Cardio and muscle strength: the calories-spent record is the energy spent while exercising
// (BMR / 24 x mety, every 5-minute step). Stop halfway counts half.
{
	t.check("exercise is defined with cardio and strength", Object.keys(activities.get_option("exercise", "cardio")).length > 0
			&& Object.keys(activities.get_option("exercise", "strength")).length > 0);
	const cardio = activities.get_option("exercise", "cardio").effects_per_hour;
	const strength = activities.get_option("exercise", "strength").effects_per_hour;
	const cardio_mety = activities.option_value(activities.get_option("exercise", "cardio"), "mety");
	const strength_mety = activities.option_value(activities.get_option("exercise", "strength"), "mety");
	t.check("cardio spends more calories than strength (METy 7.0 and 5.0)", cardio_mety === 7 && strength_mety === 5);
	t.check("both are moderate-to-vigorous", activities.option_value(activities.get_option("exercise", "cardio"), "activity_intensity") === "moderate_vigorous"
			&& activities.option_value(activities.get_option("exercise", "strength"), "activity_intensity") === "moderate_vigorous");
	t.check("there is no fatigue effect", !("fatigue" in cardio) && !("fatigue" in strength));
	t.check("no per-hour muscle or physical effects", !("muscle" in cardio) && !("muscle" in strength) && !("physical" in cardio) && !("physical" in strength));
	for (const option_id of ["cardio", "strength"]) {
		const mety = activities.option_value(activities.get_option("exercise", option_id), "mety");
		let kcal = energy.kcal_per_hour(game_state.sex_or_default(), game_state.body_age_months, game_state.weight_kg, mety);
		const hours = Number(activities.get_option("exercise", option_id).duration_hours);
		t.check(`${option_id} lasts 1 avatar hour`, is_equal_approx(hours, 1));
		clock.debug_speed = 600;
		let before = snapshot();
		t.check(`${option_id} starts`, activities.start("exercise", option_id));
		t.check(`sleep is locked during ${option_id}`, !activities.can_start("sleep"));
		while (activities.is_running()) clock._process(STEP_SECONDS);
		Simulation.flush();
		// Weight changes a little during the hour (k = 10), so BMR does too: within 1 kcal.
		t.check(`${option_id}: calories spent change by BMR / 24 x METy`, Math.abs(game_state.calories_spent - (before.calories_spent + kcal * hours)) < 1);
		// Trained every step.
		t.check(`${option_id}: fitness or strength changes during it (trained every step)`,
				game_state.fitness !== before.fitness || game_state.strength !== before.strength);
		// Stop halfway: calories count only for the time done. Small steps, so the stop
		// lands close to 0.5 h.
		clock.debug_speed = 30;
		// BMR now: the weight changed during the first hour.
		kcal = energy.kcal_per_hour(game_state.sex_or_default(), game_state.body_age_months, game_state.weight_kg, mety);
		before = snapshot();
		activities.start("exercise", option_id);
		while (activities.elapsed_hours < 0.5) clock._process(STEP_SECONDS);
		const done = activities.elapsed_hours;
		activities.stop();
		t.check(`${option_id} stopped halfway: about 0.5 h done`, Math.abs(done - 0.5) < 0.05);
		console.log(format("  %s stopped at %.2f h: +%.1f kcal (expected %.1f)", [option_id, done, game_state.calories_spent - before.calories_spent, kcal * done]));
		t.check(`${option_id} stopped halfway: calories spent are in proportion`, Math.abs(game_state.calories_spent - (before.calories_spent + kcal * done)) < 1);
	}
	clock.debug_speed = 600;
}

// Entertainment has Screens and Football (decision 4), one hour each, with no per-hour effect value
// on happiness: screens are logged as screen time, and happiness changes every step (v1 Step 10).
{
	const option = activities.get_option("entertainment", "screens");
	const football = activities.get_option("entertainment", "football");
	t.check("entertainment has Screens and Football", JSON.stringify(Object.keys(activities.definitions.entertainment.options)) === JSON.stringify(["screens", "football"]));
	t.check("both last 1 avatar hour", is_equal_approx(Number(option.duration_hours ?? 0), 1) && is_equal_approx(Number(football.duration_hours ?? 0), 1));
	t.check("screens METy 1.3, football 7.5 and moderate-to-vigorous", activities.option_value(option, "mety") === 1.3
			&& activities.option_value(football, "mety") === 7.5 && activities.option_value(football, "activity_intensity") === "moderate_vigorous");
	t.check("entertainment has no per-hour effects", Object.keys(option.effects_per_hour ?? {}).length === 0);
	game_state.reset();
	const logged_before = habits.entries.length;
	const happiness_before = game_state.happiness;
	clock.debug_speed = 600;
	t.check("screens start", activities.start("entertainment", "screens"));
	while (activities.is_running()) clock._process(STEP_SECONDS);
	t.check("happiness rises during screens (v1: +0.05 per hour in the first 2 h)", game_state.happiness > happiness_before);
	t.check("screens are logged", habits.entries.length === logged_before + 1 && habits.entries.at(-1).type === "screens");
}
t.finish();

function snapshot() {
	return {calories_spent: game_state.calories_spent, strength: game_state.strength, fitness: game_state.fitness};
}

// Runs until the awake period runs out and a new day starts without sleep.
function run_until_new_day() {
	const day = clock.day_number;
	for (let i = 0; i < 100000; i++) {
		if (clock.day_number !== day) return;
		clock._process(STEP_SECONDS);
	}
	t.check("a new day started", false);
}
