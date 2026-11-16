// Tests for health and XP (Milestone 2, Task 4.5; Milestone 10 Task 8, v1 Step 12). Run from the
// project folder:  node web/tests/health_xp_test.js
// The displayed health moves once per avatar day toward the target (decision 1); every change
// gives or takes 100 XP per point; at health 4.5 or more XP grows over time, faster the longer
// health stays high (at most x 3); XP never goes below 0. Failure reads the target health, not
// the slow bar (decision 10, Milestone 10.5). Nothing is saved.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {SaveGame} from "../js/core/save_game.js";
import {Progress as progress} from "../js/health/progress.js";
import {HealthModel as health_model} from "../js/health/health_model.js";
import {format, is_equal_approx, is_zero_approx, roundf} from "../js/core/util.js";

const TOLERANCE = 0.0001;
// Measures of a day with recommended habits, and of a day with none.
const GOOD_DAY = {physical: 0.9, happiness: 0.9, sleep: 1.0};
const BAD_DAY = {physical: 0.1, happiness: 0.1, sleep: 0.0};

setup();
const t = new Checks();
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
Activities.reset();
gs.reset();
Clock.reset();

// Health starts at the target and then moves alpha_bar of the way to it once per avatar day.
{
	gs.start_new_avatar("Test", "child", "female", "normal");
	const alpha = Config.get_float("health.alpha_bar");
	t.check("health equals the target at the start", is_equal_approx(gs.health, gs.target_health));
	t.check("health level is health rounded", gs.health_level === roundf(gs.health));
	const start = gs.health;
	set_measures(GOOD_DAY);
	t.check("the target follows the measures at once", gs.target_health > start);
	t.check("the displayed health does not change during the day", is_equal_approx(gs.health, start));
	const target = gs.target_health;
	gs.daily_update();
	t.check("once per day it moves alpha_bar (0.37) of the way to the target", Math.abs(gs.health - (start + alpha * (target - start))) < TOLERANCE);
	const values = [start, gs.health];
	for (let day = 0; day < 10; day++) {
		gs.daily_update();
		values.push(gs.health);
	}
	console.log(`  health on 11 good days: ${values.map((v) => format("%.2f", v)).join(", ")}`);
	t.check("health rises gradually, day by day", values[2] > values[1] && values.at(-1) > values[2] && values.at(-1) <= 5);
}

{
	gs.start_new_avatar("Test", "child", "female", "normal");
	gs.xp = 50;
	const per_point = Config.get_float("progress.per_health_point");
	t.check("100 XP per health point (v1)", per_point === 100);
	let before_health = gs.health;
	set_measures(GOOD_DAY);
	gs.daily_update();
	const gain = gs.health - before_health;
	t.check("a health gain gives XP", Math.abs(gs.xp - (50 + gain * per_point)) < TOLERANCE && gain > 0);
	const xp_before = gs.xp;
	before_health = gs.health;
	set_measures(BAD_DAY);
	gs.daily_update();
	const loss = before_health - gs.health;
	t.check("a health loss takes XP away", Math.abs(gs.xp - (xp_before - loss * per_point)) < TOLERANCE && loss > 0);
	gs.xp = 1;
	gs.daily_update();
	t.check("XP never goes below 0", gs.xp === 0);
}

// At health 4.5 or more: 10 XP per avatar hour x (1 + hours at that level / 48), at most x 3.
{
	gs.reset();
	gs.health = 4.5;
	gs.xp = 0;
	progress.step(1, false);
	t.check("health 4.5, first hour: 10 x (1 + 1 / 48) XP", Math.abs(gs.xp - 10 * (1 + 1 / 48)) < TOLERANCE);
	gs.high_health_hours = 200;
	let before = gs.xp;
	progress.step(1, false);
	t.check("after a long time at high health the bonus stops at x 3", Math.abs(gs.xp - before - 30) < TOLERANCE);
	gs.health = 4.4;
	before = gs.xp;
	progress.step(1, false);
	t.check("below 4.5 no XP over time, and the bonus starts again", gs.xp === before && gs.high_health_hours === 0);
	gs.health = 1.2;
	progress.step(10, false);
	t.check("low health takes no XP over time (only health losses do)", gs.xp === before);
}

{
	gs.reset();
	const per_level = Config.get_float("xp.per_level");
	const levels = [];
	gs.leveled_up.connect((level) => levels.push(level));
	gs.add_xp(per_level * 0.5);
	t.check("half a level fills half the bar", Math.abs(gs.level_progress - 0.5) < TOLERANCE && gs.level === 0);
	gs.add_xp(per_level);
	t.check("reaching a new level emits leveled_up", levels.length === 1 && levels[0] === 1 && gs.level === 1);
	gs.add_xp(-per_level);
	t.check("losing XP can lower the level", gs.level === 0);
}

// Decision 10: the health failure timer counts the hours the target health stays below
// fail.health_line, whatever the slow bar shows.
{
	const line = Config.get_float("fail.health_line");
	const hours = Config.get_float("fail.health_hours");
	gs.start_new_avatar("Test", "child", "female", "normal");
	set_measures(BAD_DAY);
	gs.health = 4;
	t.check("bad measures: the target is below the failure line, the bar is high", gs.target_health < line && gs.health > line);
	for (let hour = 0; hour < roundf(hours) - 1; hour++) health_model.step(1, false);
	t.check("one hour before fail.health_hours: no failure yet", !gs.is_at_failure());
	health_model.step(1, false);
	t.check("after fail.health_hours (24 h) with the target below the line: failure", gs.is_at_failure());

	gs.start_new_avatar("Test", "child", "female", "normal");
	set_measures(GOOD_DAY);
	gs.health = 1;
	for (let hour = 0; hour < roundf(hours) * 2; hour++) health_model.step(1, false);
	t.check("a low bar with a good target never reaches failure", !gs.is_at_failure() && is_zero_approx(gs.health_low_hours));
}
t.finish();

function set_measures(measures) {
	for (const key of Object.keys(measures)) gs[key] = measures[key];
}
