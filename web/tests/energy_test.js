// Tests for energy, weight and body size (Milestone 10, Task 4). Run from the project folder:
//   node web/tests/energy_test.js
// Checks the energy of a guideline day and an inactive day (v1 Step 3), weight going up with
// fast food and down with healthy food (v1 Step 5), the body ageing and its cap, z from
// weight and height, the weight score w(z), the calories-spent record and the energy
// deficit penalty U. Uses a test save key; the real save is never touched.
import {setup, Checks} from "./harness.js";
import {GameState} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {Energy as energy} from "../js/health/energy.js";
import {BodySize as body_size} from "../js/health/body_size.js";
import {WhoTables as who} from "../js/health/who_tables.js";
import {format, is_equal_approx, is_zero_approx} from "../js/core/util.js";

const TOLERANCE = 0.001;
setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;

// v1 Step 3: for the boy of 10 on Normal (36.0 kg), a guideline day costs about 2,100 kcal
// (10.5 h sleep, 70 min cardio, 1 h screens, the rest idle) and an inactive day about 1,800.
{
	const weight = who.weight_from_z("male", 120, 1.2);
	const per_hour = (mety) => energy.kcal_per_hour("male", 120, weight, mety);
	const awake = 24 - 10.5;
	const inactive = 10.5 * per_hour(0.95) + awake * per_hour(1.7);
	const cardio_h = 70 / 60;
	const guideline = 10.5 * per_hour(0.95) + cardio_h * per_hour(7) + 1 * per_hour(1.3) + (awake - cardio_h - 1) * per_hour(1.7);
	console.log(format("  boy 10 y, 36.0 kg: guideline day %.0f kcal (v1: about 2,100), inactive day %.0f kcal (v1: about 1,800)", [guideline, inactive]));
	t.check("a guideline day costs about 2,100 kcal (within 5%)", Math.abs(guideline / 2100 - 1) < 0.05);
	t.check("an inactive day costs about 1,800 kcal (within 5%)", Math.abs(inactive / 1800 - 1) < 0.05);
	t.check("sleep never changes the metabolic rate (same BMR asleep or awake)", is_equal_approx(per_hour(0.95) / 0.95, per_hour(1.7) / 1.7));
}

// v1 Step 5: weight goes up with fast food at every meal and no sport, and down with healthy
// food and 1 h of cardio a day. Plays 3 avatar days through the real game loop.
{
	let gs = new_avatar("male", "child", "normal");
	const start_weight = gs.weight_kg;
	const start_z = gs.weight_z;
	for (let day = 0; day < 3; day++) play_day("fast_food_meal", false);
	const fast_food_gain = gs.weight_kg - start_weight;
	console.log(format("  3 days, fast food and no sport: %+.2f kg, z %+.2f -> %+.2f", [fast_food_gain, start_z, gs.weight_z]));
	t.check("fast food at every meal and no sport: weight goes up", fast_food_gain > 0.5);
	t.check("...and BMI-for-age z goes up", gs.weight_z > start_z);
	gs = new_avatar("male", "child", "normal");
	for (let day = 0; day < 3; day++) play_day("healthy_meal", true);
	const healthy_change = gs.weight_kg - start_weight;
	console.log(format("  3 days, healthy food and 1 h cardio: %+.2f kg, z %+.2f -> %+.2f", [healthy_change, start_z, gs.weight_z]));
	t.check("healthy food and 1 h of cardio a day: weight goes down", healthy_change < 0);
	t.check("...and BMI-for-age z goes down (the body also grows)", gs.weight_z < start_z);
	t.check("one healthy day of energy balance never gives a deficit penalty", gs.deficit_u === 0);
}

// v1 Step 2: body age += k x hours / 8,760 years, stopping at the end of the age group;
// height = WHO median; z from weight / height².
{
	const gs = new_avatar("female", "child", "easy");
	const age = gs.body_age_months;
	body_size.step(24, false);
	const expected = age + 10 * 24 / 8760 * 12;
	t.check("one avatar day ages the body by k x 24 h = 10 days (0.33 months)", Math.abs(gs.body_age_months - expected) < TOLERANCE);
	t.check("height is the WHO median for the new age", is_equal_approx(gs.height_m, who.median_height_m("female", gs.body_age_months)));
	gs.body_age_months = 154.99;
	body_size.step(24, false);
	t.check("a child stops at 12 years 11 months (155 months)", gs.body_age_months === 155);
	gs.age_group = "teenager";
	gs.body_age_months = 226.99;
	body_size.step(24, false);
	t.check("a teenager stops at 18 years 11 months (227 months)", gs.body_age_months === 227);
	gs.weight_kg = who.weight_from_z("female", 227, 2);
	body_size.step(0, false);
	t.check("z comes from weight and height (weight at z +2 gives z +2)", Math.abs(gs.weight_z - 2) < TOLERANCE);
	t.check("BMI = weight / height²", is_equal_approx(body_size.bmi(40, 1.6), 15.625));
}

// v1 Step 2: w(z) = 1 for z between -2 and +1; 0.5 at +2, 0.1 at +3, 0 at +4; 0.3 at -3, 0 at -4.
{
	const cases = [[-5, 0], [-4, 0], [-3.5, 0.15], [-3, 0.3], [-2, 1], [0, 1], [1, 1], [1.5, 0.75], [2, 0.5], [3, 0.1], [3.5, 0.05], [4, 0], [5, 0]];
	let all_ok = true;
	for (const c of cases) {
		const w = body_size.weight_score(c[0]);
		if (Math.abs(w - c[1]) > TOLERANCE) {
			all_ok = false;
			console.log(format("  w(%+.1f) = %.3f, expected %.3f", [c[0], w, c[1]]));
		}
	}
	t.check("weight score w(z) at the v1 points and between them", all_ok);
}

// The calories-spent record grows only while exercising (moderate-to-vigorous activities).
{
	const gs = new_avatar("male", "teenager", "normal");
	idle_until(1);
	t.check("no calories in the record after an idle hour", gs.calories_spent === 0);
	activities.start("entertainment", "screens");
	run();
	t.check("no calories in the record after screens", gs.calories_spent === 0);
	// The weight goes down a little while playing, so BMR does too: use the average of the
	// BMR at the start and at the end of the hour.
	const at_start = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7.5);
	activities.start("entertainment", "football");
	run();
	const football = (at_start + energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7.5)) / 2;
	console.log(format("  1 h of football: %.0f kcal in the record (BMR / 24 x 7.5 = %.0f)", [gs.calories_spent, football]));
	t.check("1 h of football adds BMR / 24 x 7.5 to the record", Math.abs(gs.calories_spent - football) < 1);
}

// U = 0 below a 30% deficit, 1 at 60%, a straight line between. A new avatar starts in
// balance (U 0); a whole avatar day without food gives U 1.
{
	t.check("eating more than spent: U 0", energy.deficit_penalty(2500, 2000) === 0);
	t.check("deficit 30%: U 0", is_zero_approx(energy.deficit_penalty(1400, 2000)));
	t.check("deficit 45%: U 0.5", Math.abs(energy.deficit_penalty(1100, 2000) - 0.5) < TOLERANCE);
	t.check("deficit 60%: U 1", is_equal_approx(energy.deficit_penalty(800, 2000), 1));
	t.check("deficit 90%: U 1", is_equal_approx(energy.deficit_penalty(200, 2000), 1));
	const gs = new_avatar("female", "child", "normal");
	t.check("a new avatar starts in energy balance (U 0)", gs.deficit_u === 0 && is_equal_approx(energy.window_total("eaten"), energy.window_total("spent")));
	idle_until(6);
	const u_after_6h = gs.deficit_u;
	idle_until(14 - 0.01);
	gs.hours_awake = 14;
	activities.start("sleep", "sleep", 10);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.1);
	console.log(format("  no food: U %.2f after 6 h, %.2f after 24 h (eaten %.0f, spent %.0f kcal in 24 h)", [u_after_6h, gs.deficit_u,
		energy.window_total("eaten"), energy.window_total("spent")]));
	// The day ends a moment before 24 h, so a sliver of the first hour is still in the window.
	t.check("after a whole avatar day without food U is 1", is_equal_approx(gs.deficit_u, 1) && energy.window_total("eaten") < 0.01 * energy.window_total("spent"));
	clock.wake_up();
}
t.finish();

// Plays one avatar day: 4 meals of this food (at 0, 4, 8 and 12 h awake), 1 h of cardio at
// 2 h if exercise, then a 10 h sleep.
function play_day(food, exercise) {
	for (const meal_hour of [0, 4, 8, 12]) {
		idle_until(meal_hour);
		activities.start("eat", food);
		run();
		if (exercise && meal_hour === 0) {
			idle_until(2);
			activities.start("exercise", "cardio");
			run();
		}
	}
	idle_until(clock.day_length_hours - 0.01);
	activities.start("sleep", "sleep", 10);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.1);
	clock.wake_up();
}

function idle_until(day_hours) {
	clock.debug_speed = 600;
	while (clock.day_elapsed_hours < day_hours) {
		clock._process(Math.min(0.1, clock.avatar_hours_to_real_seconds(day_hours - clock.day_elapsed_hours, false) / 600 + 1e-6));
	}
}

function run() {
	clock.debug_speed = 600;
	while (activities.is_running()) clock._process(0.05);
	Simulation.flush();
}

function new_avatar(sex, group, difficulty) {
	activities.reset();
	Habits.reset();
	Simulation.reset();
	GameState.reset();
	clock.reset();
	GameState.start_new_avatar("Test", group, sex, difficulty);
	return GameState;
}
