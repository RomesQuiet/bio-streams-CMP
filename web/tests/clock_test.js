// Tests for the Clock time rules. Run from the project folder:  node web/tests/clock_test.js
// Prints PASS/FAIL for each check and exits with code 1 if any check fails.
import {setup, Checks} from "./harness.js";
import {GameState as game_state} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {SaveGame} from "../js/core/save_game.js";
import {SleepModel} from "../js/health/sleep_model.js";
import {format, is_equal_approx} from "../js/core/util.js";

const STEP_SECONDS = 0.1;
setup();
const t = new Checks();
// Never touch the real save: use a test key, and start from a new game.
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
activities.reset();
game_state.reset();
clock.reset();

// Sleep hours -> next day hours (CLAUDE.md: day_hours = 14 + (10 - sleep_hours)).
for (const pair of [[0, 24], [5, 19], [8, 16], [10, 14], [12, 12]]) {
	t.check(format("sleep %.1f h gives a %.1f h day", pair), is_equal_approx(clock.day_hours_after_sleep(pair[0]), pair[1]));
}
// Milestone 10 (v1): day = 20 real minutes = 14 avatar hours (42 avatar min per real min).
t.check("14 h day = 20 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(14, false), 20 * 60));
t.check("16 h day = 22.86 real min", Math.abs(clock.avatar_hours_to_real_seconds(16, false) / 60 - 22.8571) < 0.001);
t.check("19 h day = 27.14 real min", Math.abs(clock.avatar_hours_to_real_seconds(19, false) / 60 - 27.1429) < 0.001);
t.check("10 h sleep = 120 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(10, true), 120 * 60));
t.check("8 h sleep = 96 real min", is_equal_approx(clock.avatar_hours_to_real_seconds(8, true), 96 * 60));
t.check("back conversion", is_equal_approx(clock.real_seconds_to_avatar_hours(96 * 60, true), 8));

// The full cycle.
{
	clock.debug_speed = 600;
	t.check("first day starts at 07:00", clock.clock_text() === "07:00");
	t.check("first day is 14 h", is_equal_approx(clock.day_length_hours, 14));
	clock.set_paused(true);
	clock._process(STEP_SECONDS);
	t.check("pause stops time", clock.clock_text() === "07:00");
	clock.set_paused(false);
	const sleep_at_start = game_state.sleep;
	run_until_new_day();
	t.check("awake period ends at 21:00", clock.clock_text() === "21:00");
	t.check("avatar is tired when the awake period ends", game_state.tired);
	const sleep_at_bedtime = game_state.sleep;
	t.check("sleep measure falls during the day", sleep_at_bedtime < sleep_at_start);
	t.check("sleep is not automatic", clock.phase === clock.Phase.DAY);
	activities.start("sleep", "sleep", 8);
	run_until(clock.Phase.SLEEP_OVER);
	t.check("8 h sleep ends at 05:00", clock.clock_text() === "05:00");
	// The sleep measure is worked out when the sleep ends, from the new sleep debt (v1 Step 9).
	const expected_sleep = SleepModel.sleep_measure(game_state.sleep_debt, SleepModel.oversleep(8, game_state.age_group));
	t.check("sleep measure is recalculated when the sleep ends", Math.abs(game_state.sleep - expected_sleep) < 0.0001);
	t.check("avatar is not tired after sleep", !game_state.tired);
	clock._process(STEP_SECONDS);
	t.check("time waits for the wake button", clock.clock_text() === "05:00");
	clock.wake_up();
	t.check("next day is 16 h", is_equal_approx(clock.day_length_hours, 16));
	run_until_new_day();
	t.check("awake period ends at 21:00 again", clock.clock_text() === "21:00");
}

// Stopping a sleep early.
{
	activities.start("sleep", "sleep", 10);
	while (clock.sleep_elapsed_hours < 5) clock._process(STEP_SECONDS);
	activities.stop();
	const slept = clock.sleep_elapsed_hours;
	clock.wake_up();
	t.check("stopping early uses the hours slept", is_equal_approx(clock.day_length_hours, 24 - slept));
}

// Five hours of sleep.
run_until_new_day();
activities.start("sleep", "sleep", 5);
run_until(clock.Phase.SLEEP_OVER);
clock.wake_up();
t.check("5 h sleep gives a 19 h day", is_equal_approx(clock.day_length_hours, 19));

// Milestone 2, Task 2: a 1 h nap at 14:00 starts a 23 h day that ends at 14:00 the next day
// (24 h in total), and a normal 10 h sleep still gives a 14 h day.
{
	game_state.reset();
	clock.reset();
	// Exactly one avatar hour per step, so the clock lands on 14:00.
	clock.debug_speed = clock.avatar_hours_to_real_seconds(1, false) / 0.5;
	for (let i = 0; i < 7; i++) clock._process(0.5);
	t.check("clock reaches 14:00 during the day", near_minute(14 * 60));
	t.check("nap starts during the day", activities.start("sleep", "sleep", 1));
	run_until(clock.Phase.SLEEP_OVER);
	t.check("1 h nap ends at 15:00", near_minute(15 * 60));
	clock.wake_up();
	t.check("1 h nap starts a 23 h day", is_equal_approx(clock.day_length_hours, 23));
	clock.debug_speed = 600;
	run_until_new_day();
	t.check("that day ends at 14:00 the next day (24 h after the nap started)", near_minute(14 * 60));
	activities.start("sleep", "sleep", 10);
	run_until(clock.Phase.SLEEP_OVER);
	clock.wake_up();
	t.check("a normal 10 h sleep still gives a 14 h day", is_equal_approx(clock.day_length_hours, 14));
}

// Task 2.5: the sky looks like day from 07:00 to 19:00 and like night otherwise,
// with a 1 h dawn and dusk. It depends only on the clock, not on sleeping.
{
	for (const pair of [[12, 1], [0, 0], [3, 0], [6, 0], [7, 0.5], [8, 1], [18, 1], [19, 0.5], [20, 0]]) {
		t.check(`sky at ${String(pair[0]).padStart(2, "0")}:00 is ${format("%.1f", pair[1])} light`, is_equal_approx(clock.daylight_amount(pair[0] * 60), pair[1]));
	}
	// A nap at 13:00 (6 h awake, so the avatar is sleepy) still shows a day sky.
	game_state.reset();
	clock.reset();
	clock.debug_speed = clock.avatar_hours_to_real_seconds(1, false) / 0.5;
	for (let i = 0; i < 6; i++) clock._process(0.5);
	activities.start("sleep", "sleep", 1);
	clock.debug_speed = 60;
	clock._process(0.1);
	t.check("napping at 13:00: avatar asleep, sky still day", clock.phase === clock.Phase.SLEEPING && clock.daylight_amount() === 1);
	activities.stop();
}

// Milestone 2, Task 3: if the awake period runs out and the player has not slept, it counts as
// 0 hours slept: a new 24 h day starts at once, the avatar stays tired and the sleep measure
// keeps falling. The player can still sleep at any time.
{
	game_state.reset();
	clock.reset();
	clock.debug_speed = 600;
	const sleep_at_start = game_state.sleep;
	const day_at_start = clock.day_number;
	const new_days = [];
	clock.day_started.connect((slept) => new_days.push(slept));
	run_until_new_day();
	t.check("a day without sleep starts a new day at once", clock.day_number === day_at_start + 1 && clock.phase === clock.Phase.DAY);
	t.check("the new day starts without a stop at 21:00", clock.clock_text() === "21:00" && !clock.paused);
	t.check("the new day lasts 24 h", is_equal_approx(clock.day_length_hours, 24));
	t.check("the new day is reported as not slept", JSON.stringify(new_days) === "[false]");
	t.check("the sleep measure is lower than at the start", game_state.sleep < sleep_at_start);
	t.check("the avatar stays tired", game_state.tired);
	const sleep_after_day_1 = game_state.sleep;
	run_until_new_day();
	t.check("a second day without sleep is 24 h again", is_equal_approx(clock.day_length_hours, 24) && clock.clock_text() === "21:00");
	t.check("the avatar is still tired", game_state.tired);
	t.check("the sleep measure keeps falling", game_state.sleep < sleep_after_day_1 || game_state.sleep === 0);
	t.check("the player can still sleep", activities.start("sleep", "sleep", 8));
	// v1: one night does not repay two nights without sleep, so the avatar may stay tired.
	t.check("asleep, the tired message is not shown (the bubble shows Zzz)", clock.phase === clock.Phase.SLEEPING);
	run_until(clock.Phase.SLEEP_OVER);
	clock.wake_up();
	t.check("after sleeping the normal rule applies (16 h day)", is_equal_approx(clock.day_length_hours, 16));
	t.check("waking is reported as slept", JSON.stringify(new_days) === "[false,false,true]");
}

// Milestone 10 Task 2 (v1 Step 9): the avatar can sleep only with at least 1 h of sleep debt or
// after 6 h awake, and never sleeps longer than the top of its range plus min(debt, 2 h).
{
	game_state.start_new_avatar("Test", "child", "female", "normal");
	clock.reset();
	game_state.sleep_debt = 0;
	game_state.hours_awake = 0;
	t.check("no debt, 0 h awake: not sleepy", !clock.is_sleepy() && !activities.can_start("sleep"));
	t.check("sleep does not start when not sleepy", !activities.start("sleep", "sleep", 8) && clock.phase === clock.Phase.DAY);
	// Run the clock to 5 h and then 6 h awake (hours awake come from Simulation).
	clock.debug_speed = clock.avatar_hours_to_real_seconds(1, false) / 0.5;
	for (let i = 0; i < 5; i++) clock._process(0.5);
	t.check("5 h awake: still not sleepy", Math.abs(game_state.hours_awake - 5) < 0.001 && !clock.is_sleepy());
	clock._process(0.5);
	t.check("6 h awake: sleepy", clock.is_sleepy() && activities.can_start("sleep"));
	game_state.hours_awake = 0;
	game_state.sleep_debt = 1;
	t.check("1 h of sleep debt: sleepy", clock.is_sleepy());
	game_state.sleep_debt = 0;
	t.check("child, no debt: at most 12 h", is_equal_approx(clock.max_sleep_hours(), 12));
	game_state.age_group = "teenager";
	t.check("teenager, no debt: at most 10 h", is_equal_approx(clock.max_sleep_hours(), 10));
	game_state.sleep_debt = 1;
	t.check("teenager, 1 h debt: at most 11 h", is_equal_approx(clock.max_sleep_hours(), 11));
	game_state.sleep_debt = 5;
	t.check("teenager, 5 h debt: at most 12 h (10 + 2)", is_equal_approx(clock.max_sleep_hours(), 12));
	game_state.sleep_debt = 1;
	activities.start("sleep", "sleep", 12);
	t.check("a 12 h sleep is cut to 11 h", is_equal_approx(clock.sleep_target_hours, 11));
	clock.debug_speed = 600;
	run_until(clock.Phase.SLEEP_OVER);
	t.check("after a sleep, the hours awake start again from 0", game_state.hours_awake === 0);
	clock.wake_up();
}
t.finish();

function near_minute(minute) {
	return Math.abs(clock.minute_of_day - minute) < 0.01;
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

function run_until(phase) {
	for (let i = 0; i < 100000; i++) {
		if (clock.phase === phase) return;
		clock._process(STEP_SECONDS);
	}
	t.check(`reached phase ${phase}`, false);
}
