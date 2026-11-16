// Tests for the 5-minute update loop (Milestone 10, Task 2). Run from the project folder:
//   node web/tests/simulation_test.js
// Plays the same avatar time with small and very large frames and checks that the steps
// and the results are the same. Uses a test save key, so the real save is never touched.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation as simulation} from "../js/core/simulation.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {Storage} from "../js/core/storage.js";
import {format, is_equal_approx, is_zero_approx, roundf} from "../js/core/util.js";

setup();
const t = new Checks("colon");
save_game.save_key = "test_save";
save_game.auto_save_enabled = false;

// A day and a night with small frames (debug speed 60, 0.1 s) and with huge frames
// (debug speed 600, 0.5 s = 3.5 avatar hours per frame) give the same steps and XP.
{
	const small = play_day_and_night(60, 0.1);
	const big = play_day_and_night(600, 0.5);
	console.log(format("  small frames: %d steps awake, %d asleep, XP %.4f", [small.awake, small.asleep, small.xp]));
	console.log(format("  big frames:   %d steps awake, %d asleep, XP %.4f", [big.awake, big.asleep, big.xp]));
	t.check("same number of steps whatever the frame size", small.awake === big.awake && small.asleep === big.asleep);
	t.check("same XP whatever the frame size", is_equal_approx(small.xp, big.xp));
	t.check("same hours awake and asleep", is_equal_approx(small.hours_awake, big.hours_awake) && is_equal_approx(small.hours_asleep, big.hours_asleep));
	const per_hour = 60 / Config.get_float("time.step_avatar_min");
	t.check("a 14 h day is 14 x 12 = 168 steps of 5 avatar minutes", small.awake === roundf(14 * per_hour));
	t.check("a 10 h sleep is 120 steps", small.asleep === roundf(10 * per_hour));
	t.check("the steps add up to the avatar time", is_equal_approx(small.hours_awake, 14) && is_equal_approx(small.hours_asleep, 10));
}

// Time asleep and awake stay exact: a sleep of 1 h 3 min ends with a 3-minute step,
// and nothing of it is counted as awake.
{
	new_game();
	gs.start_new_avatar("Test", "child", "female", "normal");
	gs.hours_awake = 6;
	const steps = [];
	const on_step = (hours, asleep) => steps.push([hours, asleep]);
	simulation.stepped.connect(on_step);
	clock.debug_speed = 600;
	Activities.start("sleep", "sleep", 1.05);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(0.5);
	simulation.stepped.disconnect(on_step);
	let asleep_hours = 0;
	for (const step of steps) asleep_hours += step[1] ? step[0] : 0;
	t.check("a 1.05 h sleep counts 1.05 h asleep", is_equal_approx(asleep_hours, 1.05));
	t.check("its last step is the 3 minutes left over", steps.length === 13 && is_equal_approx(steps.at(-1)[0], 0.05) && steps.at(-1)[1]);
	t.check("nothing is pending after the sleep ends", is_zero_approx(simulation.pending_minutes));
}

{
	new_game();
	const count = [0];
	const on_step = () => count[0] += 1;
	simulation.stepped.connect(on_step);
	clock.debug_speed = 600;
	clock.set_paused(true);
	for (let i = 0; i < 10; i++) clock._process(0.5);
	simulation.stepped.disconnect(on_step);
	t.check("nothing runs while paused", count[0] === 0);
	clock.set_paused(false);
}

// The part of a step not yet run is saved and loaded.
{
	new_game();
	gs.start_new_avatar("Test", "child", "female", "normal");
	// One frame of 0.5 s (the longest frame the Clock counts) = 2 avatar minutes.
	clock.debug_speed = clock.avatar_hours_to_real_seconds(2 / 60, false) / 0.5;
	clock._process(0.5);
	const pending = simulation.pending_minutes;
	t.check("2 avatar minutes are pending (less than one step)", is_equal_approx(pending, 2));
	save_game.save_game();
	simulation.reset();
	t.check("load finds the save", save_game.load_game());
	t.check("the pending minutes are restored", is_equal_approx(simulation.pending_minutes, pending));
}
Storage.remove("test_save");
t.finish();

// Plays the first day to its end, then sleeps 10 h. Returns the counts.
function play_day_and_night(speed, frame_seconds) {
	new_game();
	gs.start_new_avatar("Test", "child", "female", "easy");
	gs.health = 4.6; // High health, so the XP over time runs every step.
	const counts = {awake: 0, asleep: 0, hours_awake: 0, hours_asleep: 0, xp: 0};
	const on_step = (hours, asleep) => {
		counts[asleep ? "asleep" : "awake"] += 1;
		counts[asleep ? "hours_asleep" : "hours_awake"] += hours;
	};
	simulation.stepped.connect(on_step);
	clock.debug_speed = speed;
	// Stop just before the end of the day (the 0-hour rule would start a new day).
	while (clock.day_elapsed_hours < 14 - 0.0001 && clock.day_number === 1) {
		clock._process(Math.min(frame_seconds, clock.avatar_hours_to_real_seconds(14 - clock.day_elapsed_hours, false) / speed));
	}
	Activities.start("sleep", "sleep", 10);
	while (clock.phase === clock.Phase.SLEEPING) clock._process(frame_seconds);
	simulation.stepped.disconnect(on_step);
	counts.xp = gs.xp;
	return counts;
}

function new_game() {
	Activities.reset();
	Habits.reset();
	simulation.reset();
	gs.reset();
	clock.reset();
}
