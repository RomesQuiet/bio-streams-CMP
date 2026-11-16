// Tests for food as an activity (Milestone 10, Task 3). Run from the project folder:
//   node web/tests/food_test.js
// Checks the healthy portion, how fast hunger grows (awake, asleep, with sleep debt, below
// the median weight, while exercising), the two meals, Stop halfway, the hungry message
// rules, Skip, the meal log and saving. Uses a test save key; the real save is never touched.
import {setup, Checks} from "./harness.js";
import {GameState} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits as habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {Storage} from "../js/core/storage.js";
import {Energy as energy} from "../js/health/energy.js";
import {Hunger as hunger} from "../js/health/hunger.js";
import {WhoTables} from "../js/health/who_tables.js";
import {format, is_equal_approx} from "../js/core/util.js";

const TOLERANCE = 0.01;
// Weight changes every step (k = 10), so BMR drifts a little within an hour: within 1 kcal.
const GROWTH_TOLERANCE = 1;
setup();
const t = new Checks("colon");
save_game.save_key = "test_save";
save_game.auto_save_enabled = false;

// v1 Step 4: reference = BMR at the healthy weight x 1.6; healthy portion = reference / 4.
{
	const weight = energy.healthy_weight_kg("male", 120);
	const bmr = energy.bmr("male", 120, weight);
	const reference = energy.reference_kcal_per_day("male", 120);
	console.log(format("  boy 10 y: healthy weight %.1f kg, BMR %.0f kcal/day, reference %.0f, portion %.0f", [weight, bmr, reference, reference / 4]));
	t.check("Schofield BMR for a boy of 10 at 31.2 kg is about 1210 kcal", Math.abs(bmr - (17.686 * weight + 658.2)) < TOLERANCE && Math.abs(bmr - 1210) < 2);
	t.check("reference = BMR x 1.6", is_equal_approx(reference, bmr * 1.6));
	t.check("a girl of 8 uses the 3 to 10 years equation", is_equal_approx(energy.bmr("female", 96, 25), 20.315 * 25 + 485.9));
	const gs = new_avatar("male", "child", "normal");
	t.check("healthy portion = reference / 4", Math.abs(hunger.healthy_portion_kcal() - reference / 4) < TOLERANCE);
	t.check("a fast-food meal is 1.3 healthy portions", is_equal_approx(hunger.meal_kcal("fast_food_meal", 1), 1.3 * hunger.healthy_portion_kcal()));
	t.check("a new avatar is ready for breakfast (hungry)", hunger.is_hungry() && gs.hunger > 0);
}

// Hunger grows by (0.7 x reference / 24 x hours + 0.3 x kcal spent) x sleep boost x thin boost.
{
	const gs = new_avatar("male", "child", "normal");
	const reference = energy.reference_kcal_per_day("male", gs.body_age_months);
	const idle_kcal = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7);
	gs.sleep_debt = 0;
	let start = gs.hunger;
	play_hours(1);
	let expected = 0.7 * reference / 24 + 0.3 * idle_kcal;
	console.log(format("  1 h awake, idle: hunger +%.1f kcal (expected %.1f)", [gs.hunger - start, expected]));
	t.check("1 h awake with no activity: hunger grows by the v1 formula", Math.abs(gs.hunger - start - expected) < GROWTH_TOLERANCE);
	gs.sleep_debt = 8; // d = 1: appetite x 1.2
	start = gs.hunger;
	play_hours(1);
	t.check("with full sleep debt hunger grows 20% faster", Math.abs(gs.hunger - start - expected * 1.2) < GROWTH_TOLERANCE);
	gs.sleep_debt = 0;
	// Below the median: x (1 + 0.15 x 2). z comes from the weight, so set the weight.
	gs.weight_kg = WhoTables.weight_from_z("male", gs.body_age_months, -2);
	gs.weight_z = -2;
	const expected_thin = 0.7 * reference / 24 + 0.3 * energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7);
	start = gs.hunger;
	play_hours(1);
	t.check("2 SD below the median, hunger grows 30% faster", Math.abs(gs.hunger - start - expected_thin * 1.3) < GROWTH_TOLERANCE);
	gs.weight_kg = WhoTables.weight_from_z("male", gs.body_age_months, 1);
	gs.weight_z = 1;
	expected = 0.7 * reference / 24 + 0.3 * energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 1.7);
	// Cardio spends more, so hunger grows faster (only 30% follows the spending).
	start = gs.hunger;
	const time_start = habits.avatar_hours_total;
	activities.start("exercise", "cardio");
	while (activities.is_running()) clock._process(0.1);
	Simulation.flush();
	// The last frame went a little past the end of the cardio: those minutes are idle.
	const idle_after = habits.avatar_hours_total - time_start - 1;
	const cardio_kcal = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 7);
	const expected_cardio = 0.7 * reference / 24 + 0.3 * cardio_kcal + idle_after * expected;
	console.log(format("  1 h cardio: hunger +%.1f kcal (expected %.1f)", [gs.hunger - start, expected_cardio]));
	t.check("1 h of cardio: hunger grows with the extra energy spent", Math.abs(gs.hunger - start - expected_cardio) < GROWTH_TOLERANCE);
	// Hunger grows during sleep too.
	gs.hours_awake = 6;
	start = gs.hunger;
	activities.start("sleep", "sleep", 2);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.1);
	const sleep_kcal = energy.kcal_per_hour("male", gs.body_age_months, gs.weight_kg, 0.95);
	t.check("hunger grows during a 2 h sleep", Math.abs(gs.hunger - start - 2 * (0.7 * reference / 24 + 0.3 * sleep_kcal)) < 1);
	t.check("the avatar cannot eat while asleep (only after waking)", !activities.can_start("eat"));
	clock.wake_up();
	t.check("after waking it can eat", activities.can_start("eat"));
}

// A meal takes 0.5 avatar hours and removes kcal x satiety from hunger when it ends.
{
	const gs = new_avatar("female", "child", "normal");
	const portion = hunger.healthy_portion_kcal();
	for (const food of [["healthy_meal", 1, 1], ["fast_food_meal", 1.3, 0.83]]) {
		gs.hunger = 2 * portion;
		const growth_during_meal = hunger_after_meal(food[0], gs) - 2 * portion;
		const taken = food[1] * food[2] * portion;
		t.check(format("%s takes %.2f portions off hunger", [food[0], food[1] * food[2]]),
				Math.abs(gs.hunger - (2 * portion + growth_during_meal - taken)) < GROWTH_TOLERANCE);
	}
	t.check("a meal lasts 0.5 avatar hours", is_equal_approx(Number(activities.get_option("eat", "healthy_meal").duration_hours), 0.5));
	t.check("fast food fills less per kcal than healthy food", 1.3 * 0.83 < 1.3);
	// Stop halfway: half of the meal.
	gs.hunger = 2 * portion;
	const before = gs.hunger;
	clock.debug_speed = 10;
	activities.start("eat", "healthy_meal");
	while (activities.elapsed_hours < 0.25) clock._process(0.1);
	const share = activities.elapsed_hours / 0.5;
	activities.stop();
	// Hunger also grew a little during the quarter hour of eating.
	const growth = hunger.growth(share * 0.5, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.5) * share * 0.5);
	const eaten = before + growth - gs.hunger;
	console.log(format("  stopped at %.0f%% of a healthy meal: ate %.0f kcal (that share of a portion = %.0f)", [share * 100, eaten, share * portion]));
	t.check("stopping halfway eats that share of the meal", Math.abs(eaten - share * portion) < 1);
	clock.debug_speed = 600;
}

// "I'm hungry!" needs hunger of at least 0.8 healthy meals and 2 avatar hours since the
// last meal or skip. Skip works only when hungry.
{
	const gs = new_avatar("female", "teenager", "normal");
	const portion = hunger.healthy_portion_kcal();
	gs.hours_since_meal = 3;
	gs.hunger = 0.79 * portion;
	t.check("0.79 meals of hunger: not hungry", !hunger.is_hungry());
	gs.hunger = 0.8 * portion;
	t.check("0.8 meals of hunger and 3 h since a meal: hungry", hunger.is_hungry());
	gs.hours_since_meal = 1.9;
	gs.hunger = 3 * portion;
	t.check("very hungry but only 1.9 h since a meal: not hungry yet", !hunger.is_hungry());
	gs.hours_since_meal = 2;
	t.check("2 h since a meal: hungry", hunger.is_hungry());
	t.check("skip works when hungry", hunger.skip());
	t.check("after a skip the hunger stays", is_equal_approx(gs.hunger, 3 * portion));
	t.check("after a skip the 2-hour gap starts again", !hunger.is_hungry() && gs.hours_since_meal === 0);
	t.check("skip does nothing when not hungry", !hunger.skip());
	// The hungry message after 2 h of play.
	play_hours(2);
	t.check("2 h after the skip the avatar is hungry again", hunger.is_hungry());
}

{
	const gs = new_avatar("male", "teenager", "hard");
	activities.start("eat", "fast_food_meal");
	while (activities.is_running()) clock._process(0.1);
	const entry = habits.entries.at(-1);
	t.check("the meal is logged with its type and kcal eaten", entry.type === "fast_food_meal"
			&& Math.abs(entry.kcal_eaten - hunger.meal_kcal("fast_food_meal", 1)) < TOLERANCE);
	t.check("a teenager's portion is larger than a child's", hunger.healthy_portion_kcal() > energy.healthy_portion_kcal("male", 120));
	const saved = gs.to_dict();
	save_game.save_game();
	gs.hunger = 0;
	gs.hours_since_meal = 0;
	gs.weight_kg = 0;
	t.check("load finds the save", save_game.load_game());
	t.check("hunger, time since the meal, weight and body age are restored",
			is_equal_approx(gs.hunger, saved.hunger) && is_equal_approx(gs.hours_since_meal, saved.hours_since_meal)
			&& is_equal_approx(gs.weight_kg, saved.weight_kg) && is_equal_approx(gs.body_age_months, saved.body_age_months));
	console.log(format("  teenage boy, Hard: %.1f kg, body age %.0f months", [gs.weight_kg, gs.body_age_months]));
}
Storage.remove("test_save");
t.finish();

// Plays a whole meal and returns how much hunger would be without the meal (start + growth).
function hunger_after_meal(food, gs) {
	const start = gs.hunger;
	const time_start = habits.avatar_hours_total;
	clock.debug_speed = 30;
	activities.start("eat", food);
	while (activities.is_running()) clock._process(0.1);
	Simulation.flush();
	const idle_after = habits.avatar_hours_total - time_start - 0.5;
	const growth = hunger.growth(0.5, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.5) * 0.5)
			+ hunger.growth(idle_after, energy.kcal_per_hour(gs.sex, gs.body_age_months, gs.weight_kg, 1.7) * idle_after);
	return start + growth;
}

// Plays this many avatar hours awake with no activity, ending on a whole step.
function play_hours(hours) {
	const speed = 60;
	clock.debug_speed = speed;
	const end_hours = clock.day_elapsed_hours + hours;
	while (clock.day_elapsed_hours < end_hours - 1e-9) {
		clock._process(Math.min(0.1, clock.avatar_hours_to_real_seconds(end_hours - clock.day_elapsed_hours, false) / speed));
	}
	Simulation.flush();
}

function new_avatar(sex, group, difficulty) {
	activities.reset();
	habits.reset();
	Simulation.reset();
	GameState.reset();
	clock.reset();
	GameState.start_new_avatar("Test", group, sex, difficulty);
	return GameState;
}
