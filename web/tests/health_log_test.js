// Tests for the debug CSV log (Milestone 4 Task 8; Milestone 10 Task 11). Run from the project
// folder:  node web/tests/health_log_test.js
// Plays 5 avatar hours (with a meal and cardio) and checks one line per avatar hour with every
// v1 state. Writes to a test key, so the real log is never touched.
import {setup, Checks} from "./harness.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {HealthLog as log} from "../js/core/health_log.js";
import {Storage} from "../js/core/storage.js";

const TEST_LOG = "test_health_log";
setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;
t.check("the log is off while a test script runs", !log.enabled);
activities.reset();
Habits.reset();
Simulation.reset();
gs.reset();
clock.reset();
gs.start_new_avatar("Test", "teenager", "male", "hard");

const real_before = Storage.get(log.log_path);
play_hours(1);
t.check("nothing is written to the real log while it is off", Storage.get(log.log_path) === real_before);

// An old log with another header is started again.
Storage.set(TEST_LOG, "scoring_day,clock_day,difficulty\n1,1,hard\n");
log.log_path = TEST_LOG;
log.enabled = true;
activities.start("eat", "healthy_meal");
while (activities.is_running()) clock._process(0.05);
activities.start("exercise", "cardio");
while (activities.is_running()) clock._process(0.05);
play_hours(5 - clock.day_elapsed_hours + 1);
log.enabled = false;

const lines = Storage.get(TEST_LOG).trim().split("\n");
console.log(lines[0]);
console.log(lines.at(-1));
const header = lines[0].split(",");
t.check("an old log with another header is started again", header[0] === "avatar_hour");
const hours = lines.slice(1).map((line) => Math.trunc(Number(line.split(",")[0])));
console.log(`  avatar hours written: [${hours.join(", ")}]`);
t.check("one line per avatar hour, in order, none twice", hours.every((hour, i) => hour === hours[0] + i));
t.check("every line has the same number of columns", lines.slice(1).every((line) => line.split(",").length === header.length));
const needed = ["weight_kg", "z", "hunger_kcal", "deficit_u", "fitness", "strength", "overreach", "sleep_debt", "tiredness",
	"diet_quality", "craving", "habituation", "fun", "happiness", "physical", "sleep", "target_health", "health", "xp",
	"health_low_hours", "risk_index", "disease_damage", "kcal_eaten_24h", "capacity_min"];
const missing = needed.filter((column) => !header.includes(column));
if (missing.length > 0) console.log(`  missing columns: ${missing}`);
t.check("every v1 state is a column", missing.length === 0);
const last = lines.at(-1).split(",");
const col = (name) => Number(last[header.indexOf(name)]);
t.check("the last line holds the current values", Math.abs(col("weight_kg") - gs.weight_kg) < 0.01
		&& Math.abs(col("happiness") - gs.happiness) < 0.01 && Math.abs(col("fitness") - gs.fitness) < 0.001);
const meal_line = lines[2].split(",");
t.check("the meal shows in the kcal eaten in the last 24 h", Number(meal_line[header.indexOf("kcal_eaten_24h")]) > 0);
Storage.remove(TEST_LOG);
t.finish();

function play_hours(hours) {
	const end = clock.day_elapsed_hours + hours;
	clock.debug_speed = 600;
	while (clock.day_elapsed_hours < end) {
		clock._process(Math.min(0.1, clock.avatar_hours_to_real_seconds(end - clock.day_elapsed_hours, false) / 600 + 1e-6));
	}
	Simulation.flush();
}
