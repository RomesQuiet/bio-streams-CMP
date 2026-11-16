// Starting values per difficulty (Milestone 3, Task 2; Milestone 10 Task 8). Run from the project
// folder:  node web/tests/difficulty_test.js
// Prints the starting measures and health of each difficulty for the boy of 10 of the v1
// document and checks them against the v1 'Difficulty starts' table. Nothing is saved.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState} from "../js/core/game_state.js";
import {Clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {HealthModel} from "../js/health/health_model.js";
import {format, is_equal_approx} from "../js/core/util.js";

// v1 starting Physical, Sleep and health (boy of 10). Very hard health is about 1.48, not 1.35,
// because its starting happiness is 0.30 (decision 7, user, 25 Oct 2026).
const EXPECTED = {
	easy: {physical: 0.71, sleep: 0.75, health: 3.94},
	normal: {physical: 0.44, sleep: 0.50, health: 2.91},
	hard: {physical: 0.14, sleep: 0.30, health: 1.95},
	very_hard: {physical: 0.03, sleep: 0.10, health: 1.48},
};
// The v1 table rounds to 2 decimals.
const ROUNDING = 0.011;

setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
const gs = GameState;
Activities.reset();
Simulation.reset();
gs.reset();
Clock.reset();

t.check("before choosing, the health equals its target (Normal values)", is_equal_approx(gs.health, gs.target_health));
console.log("difficulty  physical happiness sleep  z      fitness strength  Q    C    health  level");
for (const id of Object.keys(EXPECTED)) {
	gs.start_new_avatar("Test", "child", "male", id);
	const path = "health.difficulties." + id;
	console.log(id.padEnd(10) + "  " + format("%.3f    %.2f      %.2f   %+.1f   %.2f    %.2f      %.2f %.2f %.3f   %d", [
		gs.physical, gs.happiness, gs.sleep, gs.weight_z, gs.fitness, gs.strength, gs.diet_quality, gs.craving, gs.health, gs.health_level]));
	t.check(format("%s: starting Physical %.2f (v1)", [id, EXPECTED[id].physical]), Math.abs(gs.physical - EXPECTED[id].physical) <= ROUNDING);
	t.check(format("%s: starting Sleep %.2f (v1)", [id, EXPECTED[id].sleep]), Math.abs(gs.sleep - EXPECTED[id].sleep) <= ROUNDING);
	t.check(format("%s: starting health %.2f (v1)", [id, EXPECTED[id].health]), Math.abs(gs.health - EXPECTED[id].health) <= ROUNDING);
	t.check(`${id}: v1 starting happiness, Q, C and A`,
			is_equal_approx(gs.happiness, Config.get_float(path + ".happiness"))
			&& is_equal_approx(gs.diet_quality, Config.get_float(path + ".Q"))
			&& is_equal_approx(gs.craving, Config.get_float(path + ".C"))
			&& is_equal_approx(gs.habituation, Config.get_float(path + ".A")));
}
t.check("Very hard is shown as level 1", gs.health_level === 1);
let previous = Infinity;
for (const id of Object.keys(EXPECTED)) {
	t.check(`${id}: starting health is lower than the easier difficulty`, EXPECTED[id].health < previous);
	previous = EXPECTED[id].health;
}

// v1 Step 11 check: Physical 0.9, Happiness 0.6, Sleep 0.1 give 2.85 with p = 0.5.
t.check("v1 example: 0.9, 0.6, 0.1 gives health 2.85", Math.abs(HealthModel.target_health(0.9, 0.6, 0.1) - 2.85) < 0.01);
t.check("the arithmetic mean (p 1) would give 3.13", Math.abs(with_p(1) - 3.13) < 0.01);
t.check("the geometric mean (p 0) would give 2.51", Math.abs(with_p(0) - 2.51) < 0.01);
t.finish();

// The v1 example with another p, set just for this check.
function with_p(p) {
	const entry = Config._data.health.combine.p;
	const saved = entry.value;
	entry.value = p;
	const result = HealthModel.target_health(0.9, 0.6, 0.1);
	entry.value = saved;
	return result;
}
