// Tests for training (Milestone 10, Task 5; v1 Step 6). Run from the project folder:
//   node web/tests/training_test.js
// Checks the daily capacity, minutes beyond it, recovery (strength 86% after 48 h), a strength
// session that starts too soon (low recovery, or within 36 h of the previous start: Milestone
// 10.5), the starting window, and then plays four plans for 21 avatar days through the real
// game: the guideline plan raises fitness and strength; 4 h of cardio a day, strength twice a
// day and strength every day end with less strength and build overreaching.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation as simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {Training as training} from "../js/health/training.js";
import {format, is_equal_approx, is_zero_approx, roundf} from "../js/core/util.js";

const TOLERANCE = 0.001;
const DAYS = 21;
const SLEEP_HOURS = 10.5;
setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;

// Capacity = (60 + 90 x fitness) x (1 - 0.3 x d); performance = 0.7 + 0.3 x score x (1 - 0.3 x tiredness).
{
	const gs = new_avatar("normal");
	gs.sleep_debt = 0;
	gs.hours_awake = 0;
	t.check("fitness 0.4, no sleep debt: capacity 96 minutes", Math.abs(training.capacity_min() - 96) < TOLERANCE);
	gs.fitness = 1;
	t.check("fitness 1: capacity 150 minutes", Math.abs(training.capacity_min() - 150) < TOLERANCE);
	gs.sleep_debt = 8;
	t.check("full sleep debt (d = 1): capacity x 0.7", Math.abs(training.capacity_min() - 105) < TOLERANCE);
	gs.sleep_debt = 0;
	t.check("rested, minigame score 1: performance 1", is_equal_approx(training.performance(), 1));
	gs.sleep_debt = 8;
	t.check("fully tired: performance 0.7 + 0.3 x 0.7 = 0.91", Math.abs(training.performance() - 0.91) < TOLERANCE);
}

// Strength tires fully after 45 minutes and recovers with a 24 h time constant: 86% after
// 48 h. Cardio recovers with 6 h, so daily cardio stays fully useful.
{
	let gs = new_avatar("normal");
	gs.strength_recovery = 0;
	gs.cardio_recovery = 0;
	steps(48);
	console.log(format("  48 h after a full strength session: %.1f%% recovered", gs.strength_recovery * 100));
	t.check("strength is about 86% recovered 48 h after a session", Math.abs(gs.strength_recovery - (1 - Math.exp(-2))) < TOLERANCE);
	gs = new_avatar("normal");
	gs.cardio_recovery = 0;
	steps(24);
	t.check("cardio is fully recovered (over 98%) a day later", gs.cardio_recovery > 0.98);
	gs = new_avatar("normal");
	gs.hours_awake = 6;
	play_activity("exercise", "strength", 0.75);
	t.check("45 minutes of strength tire it fully (recovery 0)", gs.strength_recovery < 0.01);
	gs = new_avatar("normal");
	play_activity("exercise", "cardio", 1);
	t.check("1 h of cardio uses half of the cardio recovery (fully tired after 120 min)", Math.abs(gs.cardio_recovery - 0.5) < 0.01);
}

{
	let gs = new_avatar("normal");
	play_activity("exercise", "strength", 1);
	t.check("a rested strength session is not too soon", !gs.strength_too_soon && is_zero_approx(gs.overreach));
	const effective_before = training.effective_minutes("strength");
	play_activity("exercise", "strength", 1);
	t.check("a second strength session right after is too soon and builds O", gs.strength_too_soon && gs.overreach > 0);
	// The sliding window keeps losing a little of its oldest hour, so the sum may go down; it
	// must not go up.
	t.check("...and gives no effective minutes (user decision)", training.effective_minutes("strength") <= effective_before + TOLERANCE);
	gs = new_avatar("normal");
	const capacity = training.capacity_min();
	play_activity("exercise", "cardio", 1);
	const effective_1h = training.effective_minutes("cardio");
	t.check("1 h of cardio is within the 96-minute capacity: no O", is_zero_approx(gs.overreach));
	play_activity("exercise", "cardio", 1);
	const effective_2h = training.effective_minutes("cardio");
	const gained = effective_2h - effective_1h;
	console.log(format("  capacity %.0f min: 2nd hour of cardio adds %.1f effective minutes (only %.0f min within capacity), O %.2f",
		[capacity, gained, capacity - 60, gs.overreach]));
	t.check("minutes beyond the capacity give no benefit", gained <= (capacity - 60) + TOLERANCE);
	t.check("...and build the overreaching load O", gs.overreach > 0 && is_equal_approx(gs.exercise_minutes_today, 120));
	const overreach_before = gs.overreach;
	steps(24 * 7);
	t.check("O fades with rest (a week: under 10% of it is left)", gs.overreach < 0.1 * overreach_before);
}

// Milestone 10.5 (team review): a strength session that starts less than train.strength_min_gap_h
// (36 h) after the start of the previous one is too soon, even when the muscles have recovered
// past train.strength_ready (0.6, reached about 23 h after a full session).
{
	const gap = Config.get_float("train.strength_min_gap_h");
	let gs = new_avatar("normal");
	t.check("a new avatar's first strength session is never too soon by the gap", gs.hours_since_strength >= gap);
	play_activity("exercise", "strength", 1);
	steps(23);
	console.log(format("  24 h after the last start: recovery %.2f (ready at 0.60), %.1f h since that start (gap %.0f h)",
		[gs.strength_recovery, gs.hours_since_strength, gap]));
	t.check("24 h later the muscles have recovered past 0.6", gs.strength_recovery >= 0.6);
	const effective_before = training.effective_minutes("strength");
	const overreach_before = gs.overreach;
	play_activity("exercise", "strength", 1);
	t.check("...but a session 24 h after the last start is too soon (36 h gap)", gs.strength_too_soon);
	t.check("...so it gives no effective minutes and builds O", training.effective_minutes("strength") <= effective_before + TOLERANCE
			&& gs.overreach > overreach_before);
	gs = new_avatar("normal");
	play_activity("exercise", "strength", 1);
	steps(47);
	play_activity("exercise", "strength", 1);
	t.check("a session 48 h after the last start is not too soon", !gs.strength_too_soon);
}

// A new avatar's window gives its starting fitness and strength as targets, so the levels
// stay put until the player does something different; with no exercise they fall slowly.
{
	for (const difficulty of ["easy", "normal", "hard"]) {
		const gs = new_avatar(difficulty);
		t.check(`${difficulty}: starting targets = starting fitness and strength`,
				Math.abs(training.fitness_target() - gs.fitness) < TOLERANCE && Math.abs(training.strength_target() - gs.strength) < TOLERANCE);
	}
	let gs = new_avatar("normal");
	const start = gs.fitness;
	steps(1);
	t.check("the first hour does not move fitness", Math.abs(gs.fitness - start) < TOLERANCE);
	steps(48);
	t.check("with no exercise for 2 days fitness falls (the window empties)", gs.fitness < start);
	// Milestone 10.5: a longer window averages the minutes per day over it.
	const hours = Config._data.train.average_window_h.value;
	Config._data.train.average_window_h.value = 168;
	gs = new_avatar("normal");
	t.check("a one-week window also gives the starting fitness and strength as targets",
			Math.abs(training.fitness_target() - gs.fitness) < TOLERANCE && Math.abs(training.strength_target() - gs.strength) < TOLERANCE);
	Config._data.train.average_window_h.value = hours;
}

// v1 'Predicted results': guideline plan vs 4 h of cardio a day vs strength twice a day; and
// strength every day (team review, Milestone 10.5).
{
	const guideline = play_plan("guideline");
	const cardio_4h = play_plan("cardio_4h");
	const strength_2x = play_plan("strength_2x");
	const strength_daily = play_plan("strength_daily");
	console.log(`  after ${DAYS} avatar days (v1: guideline fitness 0.83 strength 0.70; 4 h cardio 0.86 / 0.50; strength twice 0.66 / 0.34;`
			+ " review: strength every day 0.44 with the 36 h gap)");
	for (const row of [["guideline", guideline], ["4 h cardio", cardio_4h], ["strength twice", strength_2x], ["strength daily", strength_daily]]) {
		console.log(`    ${row[0].padEnd(15)} ` + format("fitness %.2f  strength %.2f  O %.2f", [row[1].fitness, row[1].strength, row[1].overreach]));
	}
	t.check("strength every day: less strength than the guideline plan (36 h gap)", strength_daily.strength < guideline.strength);
	t.check("strength every day builds overreaching", strength_daily.overreach > 0.2);
	t.check("the guideline plan raises fitness and strength (from 0.40)", guideline.fitness > 0.6 && guideline.strength > 0.55);
	t.check("the guideline plan builds no overreaching", guideline.overreach < 0.05);
	t.check("4 h of cardio a day: less strength than the guideline plan", cardio_4h.strength < guideline.strength);
	t.check("4 h of cardio a day builds overreaching", cardio_4h.overreach > 0.3);
	t.check("strength twice a day: less strength than the guideline plan", strength_2x.strength < guideline.strength);
	t.check("strength twice a day: less fitness than the guideline plan", strength_2x.fitness < guideline.fitness);
	t.check("strength twice a day builds overreaching", strength_2x.overreach > 0.3);
}
t.finish();

// Plays DAYS avatar days of a plan (a boy of 10, Normal) and returns the levels at the end.
function play_plan(plan) {
	const gs = new_avatar("normal");
	for (let day = 0; day < DAYS; day++) {
		const events = [[0, "eat", "healthy_meal"], [4.5, "eat", "healthy_meal"], [8, "eat", "healthy_meal"], [12, "eat", "healthy_meal"]];
		if (plan === "guideline") {
			events.push([1, "exercise", "cardio"]);
			if ([0, 2, 4].includes(day % 7)) events.push([2.5, "exercise", "strength"]);
		} else if (plan === "cardio_4h") {
			for (const hour of [0.5, 1.5, 2.5, 3.5]) events.push([hour, "exercise", "cardio"]);
		} else if (plan === "strength_2x") {
			events.push([1, "exercise", "cardio"], [2.5, "exercise", "strength"], [6, "exercise", "strength"]);
		} else if (plan === "strength_daily") {
			events.push([1, "exercise", "cardio"], [2.5, "exercise", "strength"]);
		}
		events.sort((a, b) => a[0] - b[0]);
		for (const event of events) {
			idle_until(event[0]);
			play_activity(event[1], event[2], 1);
		}
		sleep(SLEEP_HOURS);
	}
	return {fitness: gs.fitness, strength: gs.strength, overreach: gs.overreach};
}

// Plays an activity for this share of its duration (1 = to the end).
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

// Runs this many avatar hours of 5-minute steps directly (no activity).
function steps(hours) {
	const step_hours = simulation.step_minutes() / 60;
	for (let i = 0; i < roundf(hours / step_hours); i++) simulation._step(step_hours, false);
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
