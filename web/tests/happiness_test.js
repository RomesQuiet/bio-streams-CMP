// Tests for diet and happiness (Milestone 10, Task 7; v1 Steps 7 and 10). Run from the project
// folder:  node web/tests/happiness_test.js
// Checks how Q, C and A move with each meal, the meal, exercise, screens, hunger and waking
// events, fun, screen excess and the baseline, and then plays v1 scenarios for 21 avatar days
// through the real game: the guideline plan reaches happiness near 1, and, starting with a
// fast-food craving of 0.9, an abrupt switch to healthy food drops happiness lower than a
// gradual switch over a week. Uses a test save key; the real save is never touched.
import {setup, Checks} from "./harness.js";
import {Config as config} from "../js/core/config.js";
import {GameState} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation as simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {Happiness as happiness} from "../js/health/happiness.js";
import {Diet as diet} from "../js/health/diet.js";
import {Hunger as hunger} from "../js/health/hunger.js";
import {format, clampf, is_equal_approx} from "../js/core/util.js";

const TOLERANCE = 0.001;
const DAYS = 21;
const SLEEP_HOURS = 10.5;
setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
let lowest = 1;

// v1 Step 7: per meal Q += (x - Q) x 0.119, C += ((1 - x) - C) x 0.083, A += ((1 - x) - A) x 0.05.
{
	const gs = new_avatar("normal");
	gs.diet_quality = 0.5;
	gs.craving = 0.6;
	gs.habituation = 0.5;
	diet.on_meal("healthy_meal", 1);
	t.check("a healthy meal: Q moves 1/8.4 of the way to 1", Math.abs(gs.diet_quality - (0.5 + 0.5 / 8.4)) < TOLERANCE);
	t.check("...C moves 1/12 of the way to 0", Math.abs(gs.craving - (0.6 - 0.6 / 12)) < TOLERANCE);
	t.check("...A moves 1/20 of the way to 0", Math.abs(gs.habituation - (0.5 - 0.5 / 20)) < TOLERANCE);
	gs.diet_quality = 0.5;
	diet.on_meal("fast_food_meal", 0.5);
	t.check("half a fast-food meal moves Q half as far, toward 0", Math.abs(gs.diet_quality - (0.5 - 0.5 * 0.5 / 8.4)) < TOLERANCE);
}

// Every event is x mood.speed (user, 7 Nov 2026; 1 = v1's sizes).
{
	const s = config.get_float("mood.speed");
	let gs = new_avatar("normal");
	gs.craving = 0.9;
	gs.habituation = 0;
	gs.happiness = 0.5;
	happiness.on_meal("healthy_meal", 1);
	t.check("a healthy meal with craving 0.9: (+0.01 - 0.06 x 0.9) x speed = -0.044 x speed", Math.abs(gs.happiness - (0.5 - 0.044 * s)) < TOLERANCE);
	gs.happiness = 0.5;
	happiness.on_meal("fast_food_meal", 1);
	t.check("fast food with craving 0.9, no habituation: (+0.01 + 0.054) x speed", Math.abs(gs.happiness - (0.5 + 0.064 * s)) < TOLERANCE);
	gs.habituation = 1;
	gs.happiness = 0.5;
	happiness.on_meal("fast_food_meal", 1);
	t.check("fully habituated, fast food gives only +0.01 x speed", Math.abs(gs.happiness - (0.5 + 0.01 * s)) < TOLERANCE);
	gs.happiness = 0.5;
	gs.fitness = 0.4;
	happiness.on_activity_started("cardio");
	t.check("starting cardio at fitness 0.4: -0.03 x 0.6 x speed", Math.abs(gs.happiness - (0.5 - 0.018 * s)) < TOLERANCE);
	gs.happiness = 0.5;
	happiness.on_activity_started("football");
	t.check("starting football costs nothing", is_equal_approx(gs.happiness, 0.5));
	gs.happiness = 0.5;
	gs.night_quality = 1;
	happiness.on_wake();
	t.check("waking after a good night: +0.08 x 0.5 x speed", Math.abs(gs.happiness - (0.5 + 0.04 * s)) < TOLERANCE);
	gs.happiness = 0.5;
	gs.night_quality = 4 / 9;
	happiness.on_wake();
	t.check("waking after 6 h (child): night quality 0.44 lowers happiness", gs.happiness < 0.5);

	// The wish for screens: every 4 awake hours without screens, -0.02.
	gs = new_avatar("normal");
	gs.hunger = 0;
	gs.hours_without_screens = 3.99;
	gs.happiness = 0.6;
	gs.happiness_baseline = 0.6;
	const before = gs.happiness;
	happiness.step(1 / 12, false);
	t.check("4 awake hours without screens: the step loses about 0.02 x speed", gs.hours_without_screens < 1 && before - gs.happiness > 0.015 * s);
	gs.hunger = 2 * hunger.healthy_portion_kcal();
	gs.hours_without_screens = 0;
	const hungry_before = gs.happiness;
	happiness.step(1, false);
	const hungry_drop = hungry_before - gs.happiness;
	gs.hunger = 0;
	const fed_before = gs.happiness;
	happiness.step(1, false);
	t.check("hungry while awake costs about 0.05 x speed per hour more", Math.abs((hungry_drop - (fed_before - gs.happiness)) - 0.05 * s) < 0.01 * s);

	// The move toward the baseline: 63% of the gap in tau_h / speed hours (asleep, no events).
	gs = new_avatar("normal");
	const target = happiness.baseline();
	gs.happiness = target - 0.3;
	happiness.step(config.get_float("mood.tau_h") / s, true);
	t.check(format("the time constant is tau_h / speed (%.0f h): 63%% of the gap", config.get_float("mood.tau_h") / s),
			Math.abs((gs.happiness - (target - 0.3)) / 0.3 - (1 - Math.exp(-1))) < TOLERANCE);
}

// Baseline = 0.15 + 0.30 P + 0.25 S + 0.10 Q + 0.20 Fun - 0.2 U - 0.10 excess - 0.1 O.
{
	let gs = new_avatar("normal");
	gs.physical = 1;
	gs.sleep = 1;
	gs.diet_quality = 1;
	gs.deficit_u = 0;
	gs.overreach = 0;
	t.check("no fun yet: baseline 0.15 + 0.30 + 0.25 + 0.10 = 0.80", Math.abs(happiness.baseline() - 0.8) < TOLERANCE);
	play_activity("entertainment", "football", 1);
	console.log(format("  1 h of football: fun %.2f (60 / 90 = 0.67)", happiness.fun()));
	t.check("1 h of football gives fun 60 / 90", Math.abs(happiness.fun() - 60 / 90) < 0.01);
	gs = new_avatar("normal");
	for (let i = 0; i < 4; i++) play_activity("entertainment", "screens", 1);
	console.log(format("  4 h of screens: fun %.2f (only the first 120 min count: 120 x 0.6 / 90 = 0.8), screen excess %.2f (1.0)",
		[happiness.fun(), happiness.screen_excess()]));
	t.check("only the first 2 h of screens count for fun", Math.abs(happiness.fun() - 0.8) < 0.01);
	t.check("4 h of screens: screen excess 1", Math.abs(happiness.screen_excess() - 1) < 0.01);
	gs.deficit_u = 1;
	gs.overreach = 1;
	const low = happiness.baseline();
	gs.deficit_u = 0;
	gs.overreach = 0;
	t.check("U, O and screen excess lower the baseline by 0.2 + 0.1", Math.abs(happiness.baseline() - low - 0.3) < TOLERANCE);
	t.check("a meal is still logged while the Eat activity runs", activities.can_start("eat"));
}

// v1 'Predicted results': the guideline plan reaches happiness near 1; with craving 0.9, an
// abrupt switch to healthy food drops happiness lower than a gradual one over a week.
{
	const guideline = play_plan(-1, 0.6);
	const abrupt = play_plan(0, 0.9);
	const gradual = play_plan(7, 0.9);
	console.log(`  after ${DAYS} avatar days (v1: guidelines 1.00; abrupt lowest 0.40, gradual lowest 0.50):`);
	for (const row of [["guidelines", guideline], ["abrupt switch", abrupt], ["gradual switch", gradual]]) {
		console.log(`    ${row[0].padEnd(15)} ` + format("happiness %.2f (lowest %.2f)  Q %.2f  C %.2f  hunger %.0f kcal", [row[1].happiness, row[1].lowest,
			row[1].Q, row[1].C, row[1].hunger]));
	}
	t.check("the guideline plan reaches happiness near 1 (at least 0.9)", guideline.happiness >= 0.9);
	t.check("healthy and happy together: diet quality near 1 too", guideline.Q > 0.9);
	t.check("abrupt switch: happiness drops lower than with a gradual switch", abrupt.lowest < gradual.lowest);
	t.check("both switches end in the same place (happiness near 1)", Math.abs(abrupt.happiness - gradual.happiness) < 0.05);
}
t.finish();

// Plays DAYS avatar days of the guideline activities (a boy of 10, Normal): 1 h cardio every
// day, 1 h strength on 3 non-consecutive days a week, 1 h of screens and 10.5 h of sleep. The
// avatar eats whenever it says "I'm hungry!" (checked every half hour), as a player would.
// switch_days: -1 = always healthy meals; 0 = healthy from day 1; n = the share of healthy
// meals grows by a quarter every n / 4 days, so all are healthy after n days.
function play_plan(switch_days, craving) {
	const gs = new_avatar("normal");
	gs.craving = craving;
	lowest = gs.happiness;
	const track = () => lowest = Math.min(lowest, gs.happiness);
	simulation.stepped.connect(track);
	for (let day = 0; day < DAYS; day++) {
		let healthy_share = 1;
		if (switch_days > 0) healthy_share = clampf(Math.floor(4 * (day + 1) / switch_days) / 4, 0.25, 1);
		const events = new Map([[1, ["exercise", "cardio"]], [5.5, ["entertainment", "screens"]]]);
		if ([0, 2, 4].includes(day % 7)) events.set(2.5, ["exercise", "strength"]);
		let meals = 0;
		let healthy = 0;
		let time = 0;
		while (time < clock.day_length_hours - 0.5) {
			idle_until(time);
			if (hunger.is_hungry()) {
				const food = healthy < healthy_share * (meals + 1) - TOLERANCE ? "healthy_meal" : "fast_food_meal";
				play_activity("eat", food, 1);
				meals += 1;
				healthy += food === "healthy_meal" ? 1 : 0;
			}
			if (events.has(time)) play_activity(events.get(time)[0], events.get(time)[1], 1);
			time += 0.5;
		}
		sleep(SLEEP_HOURS);
	}
	simulation.stepped.disconnect(track);
	return {happiness: gs.happiness, lowest, Q: gs.diet_quality, C: gs.craving, hunger: gs.hunger};
}

function play_activity(activity_id, option_id, share) {
	clock.debug_speed = 600;
	activities.start(activity_id, option_id);
	const stop_at = activities.target_hours * share;
	while (activities.is_running() && activities.elapsed_hours < stop_at - TOLERANCE) {
		clock._process(Math.min(0.05, clock.avatar_hours_to_real_seconds(stop_at - activities.elapsed_hours, false) / 600 + 1e-6));
	}
	activities.stop();
	simulation.flush();
}

function idle_until(day_hours) {
	clock.debug_speed = 600;
	while (clock.day_elapsed_hours < day_hours) {
		clock._process(Math.min(0.1, clock.avatar_hours_to_real_seconds(day_hours - clock.day_elapsed_hours, false) / 600 + 1e-6));
	}
}

function sleep(hours) {
	idle_until(clock.day_length_hours - 0.01);
	activities.start("sleep", "sleep", hours);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.1);
	clock.wake_up();
}

function new_avatar(difficulty) {
	activities.reset();
	Habits.reset();
	simulation.reset();
	GameState.reset();
	clock.reset();
	GameState.start_new_avatar("Test", "child", "male", difficulty);
	return GameState;
}
