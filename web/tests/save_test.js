// Tests for SaveGame (Milestone 10, Task 9). Run from the project folder:
//   node web/tests/save_test.js
// Plays meals, exercise, screens and a day without sleep, saves in the middle of a sleep, and
// checks that every saved value comes back: GameState (every v1 state, the hourly windows and
// the failure timers), the Clock, the running activity, the action log and Simulation's
// pending minutes. Saves of another version (Milestone 4 or earlier) and saves without the
// creation choices are ignored. Uses a test key, so the real save is never touched.
import {setup, Checks} from "./harness.js";
import {GameState as game_state} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {Storage} from "../js/core/storage.js";
import {is_equal_approx} from "../js/core/util.js";

const TEST_KEY = "test_save";
setup();
const t = new Checks();
save_game.save_key = TEST_KEY;
save_game._deleted_key = "test_deleted_save";
save_game.auto_save_enabled = false;
Storage.remove(TEST_KEY);
activities.reset();
game_state.reset();
clock.reset();

// Before the avatar is created nothing is saved automatically.
save_game.auto_save_enabled = true;
clock.paused_changed.emit(false);
save_game.auto_save_enabled = false;
t.check("no autosave before the avatar is created", Storage.get(TEST_KEY) === "");

// A game in the middle of a sleep, after meals, exercise and screens, with some XP.
game_state.start_new_avatar("Test Avatar", "teenager", "male", "hard");
t.check("avatar counts as created", game_state.is_created());
game_state.xp = 157.5;
clock.debug_speed = 600;
for (const option of [["eat", "fast_food_meal"], ["exercise", "cardio"], ["exercise", "strength"], ["entertainment", "screens"],
	["entertainment", "football"], ["eat", "healthy_meal"]]) {
	activities.start(option[0], option[1]);
	while (activities.is_running()) clock._process(0.1);
}
t.check("the played hours changed the v1 states", game_state.calories_spent > 0 && game_state.fitness !== 0.15
		&& game_state.diet_quality !== 0.25 && game_state.screen_minutes_today > 0);
const day = clock.day_number;
while (clock.day_number === day) clock._process(0.1);
activities.start("sleep", "sleep", 8);
while (clock.sleep_elapsed_hours < 3) clock._process(0.1);
const saved_state = game_state.to_dict();
const saved_clock = clock.to_dict();
const saved_habits = Habits.to_dict();
const saved_simulation = Simulation.to_dict();
save_game.save_game();
t.check("save file written", Storage.get(TEST_KEY) !== "");

const saved_activity = activities.to_dict();
activities.reset();
game_state.reset();
clock.reset();
t.check("state was cleared before loading", game_state.avatar_name !== "Test Avatar");
t.check("load finds the save", save_game.load_game());
t.check("every GameState value restored (v1 states, windows, timers, XP, name)", same(game_state.to_dict(), saved_state));
t.check("the action log restored", same(Habits.to_dict(), saved_habits));
t.check("Simulation's pending minutes restored", same(Simulation.to_dict(), saved_simulation));
t.check("age group, sex and difficulty restored", game_state.age_group === "teenager" && game_state.sex === "male" && game_state.difficulty === "hard");
t.check("time restored", same(clock.to_dict(), saved_clock));
t.check("still asleep after loading", clock.phase === clock.Phase.SLEEPING);
t.check("sleep activity restored", same(activities.to_dict(), saved_activity) && activities.is_running());

Storage.set(TEST_KEY, "not json");
t.check("a broken save is ignored", !save_game.load_game());

// A save without creation choices is ignored and the player starts a new game.
const old_state = {...saved_state};
for (const key of ["age_group", "sex", "difficulty"]) delete old_state[key];
Storage.set(TEST_KEY, JSON.stringify({version: save_game.SAVE_VERSION, save_count: 5, game_state: old_state, clock: saved_clock, activities: {}}));
game_state.reset();
t.check("a save without the creation choices is ignored", !save_game.load_game());
t.check("so the creation screen is shown", !game_state.is_created());

// Decision 6: a Milestone 4 save (version 1), even with every choice, does not load.
t.check("the save version is 2 (Milestone 10)", save_game.SAVE_VERSION === 2);
Storage.set(TEST_KEY, JSON.stringify({version: 1, save_count: 9, game_state: saved_state, clock: saved_clock, activities: {}}));
game_state.reset();
t.check("a Milestone 4 save (version 1) is ignored", !save_game.load_game());
t.check("so the creation screen opens for a new avatar", !game_state.is_created());

// "Start a new avatar": a copy that is not newer than the deleted save is ignored, and the new
// avatar's saves count on from it so they still load.
{
	game_state.start_new_avatar("Old", "child", "male", "normal");
	save_game.save_game();
	const old_copy = Storage.get(TEST_KEY);
	save_game.delete_save();
	Storage.set(TEST_KEY, old_copy);
	game_state.reset();
	t.check("a deleted save that comes back is ignored", !save_game.load_game() && !game_state.is_created());
	game_state.start_new_avatar("New", "child", "male", "normal");
	save_game.save_game();
	game_state.reset();
	t.check("the new avatar after it loads", save_game.load_game() && game_state.avatar_name === "New");
}

// The Godot web version's save (the same storage key and format) loads in the converted game.
{
	game_state.start_new_avatar("Godot", "teenager", "female", "easy");
	const godot_save = JSON.stringify({version: 2, save_count: 100, game_state: game_state.to_dict(), clock: clock.to_dict(),
		activities: {}, minigame: {}, habits: Habits.to_dict(), simulation: Simulation.to_dict()}, null, "\t");
	save_game.select_slot(0);
	Storage.remove(save_game.WEB_DELETED_KEY);
	Storage.set(save_game.WEB_STORAGE_KEY, godot_save);
	game_state.reset();
	t.check("a save written by the Godot web game loads (same key, same format)", save_game.load_game() && game_state.avatar_name === "Godot");
	Storage.remove(save_game.WEB_STORAGE_KEY);
}

Storage.remove(TEST_KEY);
Storage.remove("test_deleted_save");
t.finish();

// Compares two objects, allowing tiny number differences.
function same(a, b) {
	const keys = Object.keys(a);
	if (keys.length !== Object.keys(b).length) return false;
	for (const key of keys) {
		if (!(key in b)) return false;
		if (!same_value(a[key], b[key])) {
			console.log(`  differs: ${key} ${JSON.stringify(a[key])} != ${JSON.stringify(b[key])}`);
			return false;
		}
	}
	return true;
}

function same_value(a, b) {
	if (Array.isArray(a) && Array.isArray(b)) return a.length === b.length && a.every((value, i) => same_value(value, b[i]));
	if (a !== null && b !== null && typeof a === "object" && typeof b === "object") return same(a, b);
	if (typeof a === "number" && typeof b === "number") return is_equal_approx(a, b);
	return a === b;
}
