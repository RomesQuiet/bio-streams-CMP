// Tests for sleep (Milestone 10, Task 6; v1 Step 9). Run from the project folder:
//   node web/tests/sleep_test.js
// Checks that a full night repays 86% of the sleep debt and no sleep repays nothing, that 6 h
// every night settles near 4.4 h of debt, the Sleep measure (debt and oversleep), night
// quality, tiredness and the "I'm tired" state, the starting values per difficulty, and that
// loading a save never runs a new day again. Uses a test save key.
import {setup, Checks} from "./harness.js";
import {GameState} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {Storage} from "../js/core/storage.js";
import {SleepModel as sleep_model} from "../js/health/sleep_model.js";
import {format, is_equal_approx, is_zero_approx} from "../js/core/util.js";

const TOLERANCE = 0.001;
setup();
const t = new Checks("colon");
save_game.save_key = "test_save";
save_game.auto_save_enabled = false;

// debt = debt x e^(-(slept / target) x 24 / 12) + max(0, minimum - slept) (child: 9 to 12 h,
// target 10.5; 12 = 5 real days / k).
{
	const after_full = sleep_model.debt_after(4, 10.5, "child");
	console.log(format("  child, 4 h of debt, a full night (10.5 h): %.2f h left (%.1f%% repaid)", [after_full, (1 - after_full / 4) * 100]));
	t.check("a full night repays 86% of the debt", Math.abs(after_full - 4 * Math.exp(-2)) < TOLERANCE);
	t.check("no sleep repays nothing and adds the minimum (9 h)", is_equal_approx(sleep_model.debt_after(4, 0, "child"), 13));
	t.check("sleep inside the range adds no debt", is_zero_approx(sleep_model.debt_after(0, 9, "child")));
	t.check("teenager: 6 h adds 2 h (minimum 8 h)", is_equal_approx(sleep_model.debt_after(0, 6, "teenager"), 2));
	let debt = 0;
	for (let night = 0; night < 30; night++) debt = sleep_model.debt_after(debt, 6, "child");
	console.log(format("  child sleeping 6 h every night: debt settles at %.2f h (v1: 4.4)", debt));
	t.check("6 h every night settles near 4.4 h of debt", Math.abs(debt - 4.4) < 0.05);
}

// Sleep = (1 - min(1, debt / 8)) x (1 - min(0.3, 0.1 x oversleep)); night quality.
t.check("no debt, no oversleep: Sleep 1", is_equal_approx(sleep_model.sleep_measure(0, 0), 1));
t.check("4 h of debt: Sleep 0.5", is_equal_approx(sleep_model.sleep_measure(4, 0), 0.5));
t.check("8 h of debt or more: Sleep 0", is_zero_approx(sleep_model.sleep_measure(10, 0)));
t.check("teenager sleeping 12 h: 2 h of oversleep, Sleep x 0.8", is_equal_approx(sleep_model.sleep_measure(0, sleep_model.oversleep(12, "teenager")), 0.8));
t.check("oversleep costs at most 30%", is_equal_approx(sleep_model.sleep_measure(0, 6), 0.7));
t.check("night quality: 1 inside the range", is_equal_approx(sleep_model.night_quality(10, "child"), 1));
t.check("night quality: (6 / 9)^2 = 0.44 for 6 h (child)", Math.abs(sleep_model.night_quality(6, "child") - 4 / 9) < TOLERANCE);
t.check("night quality: 0.9 for 1 h of oversleep", is_equal_approx(sleep_model.night_quality(13, "child"), 0.9));
t.check("night quality: at least 0.7", is_equal_approx(sleep_model.night_quality(20, "teenager"), 0.7));

// Tiredness = max(d, (hours awake - 15) / 4); tired at 0.5 or more.
{
	const gs = new_avatar("easy");
	gs.sleep_debt = 0;
	gs.hours_awake = 10;
	t.check("rested and 10 h awake: tiredness 0", is_zero_approx(sleep_model.tiredness()));
	gs.hours_awake = 17;
	t.check("17 h awake: tiredness 0.5, tired", is_equal_approx(sleep_model.tiredness(), 0.5) && tired());
	gs.hours_awake = 30;
	t.check("30 h awake: tiredness 1", is_equal_approx(sleep_model.tiredness(), 1));
	gs.hours_awake = 0;
	gs.sleep_debt = 6;
	t.check("6 h of debt (d 0.75): tiredness 0.75, tired", is_equal_approx(sleep_model.tiredness(), 0.75) && tired());
}

// Starting debt per difficulty gives the v1 starting Sleep measure.
for (const pair of [["easy", 0.75], ["normal", 0.5], ["hard", 0.3], ["very_hard", 0.1]]) {
	const gs = new_avatar(pair[0]);
	t.check(format("%s starts with Sleep %.2f", pair), Math.abs(gs.sleep - pair[1]) < TOLERANCE);
}

// A real night: the debt and the Sleep measure change when the sleep ends, and loading a
// save made after the sleep does not run that new day a second time.
{
	const gs = new_avatar("normal");
	const debt_before = gs.sleep_debt;
	clock.debug_speed = 600;
	while (clock.day_elapsed_hours < clock.day_length_hours - 0.01) clock._process(0.1);
	Activities.start("sleep", "sleep", 10.5);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.1);
	const expected = sleep_model.debt_after(debt_before, 10.5, "child");
	t.check("after a 10.5 h night the debt follows the formula", Math.abs(gs.sleep_debt - expected) < TOLERANCE);
	t.check("...and so does the Sleep measure", Math.abs(gs.sleep - sleep_model.sleep_measure(expected, 0)) < TOLERANCE);
	t.check("after a full night the avatar is not tired", !gs.tired);
	const saved = gs.to_dict();
	save_game.save_game();
	gs.sleep_debt = 99;
	t.check("load finds the save (made while waiting for the wake button)", save_game.load_game());
	t.check("loading does not run the new day again (same debt and Sleep)",
			is_equal_approx(gs.sleep_debt, saved.sleep_debt) && is_equal_approx(gs.sleep, saved.sleep));
	clock.wake_up();
}
Storage.remove("test_save");
t.finish();

function tired() {
	sleep_model.update_tired();
	return GameState.tired;
}

function new_avatar(difficulty) {
	Activities.reset();
	Habits.reset();
	Simulation.reset();
	GameState.reset();
	clock.reset();
	GameState.start_new_avatar("Test", "child", "female", difficulty);
	return GameState;
}
