// Tests for the action log and avatar days (Milestone 3, Task 3; the habit scores were removed in
// Milestone 10). Run from the project folder:  node web/tests/habits_test.js
// Uses a test save key, so the real save is never touched.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits as h} from "../js/core/habits.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {Storage} from "../js/core/storage.js";
import {Energy as energy} from "../js/health/energy.js";
import {is_zero_approx} from "../js/core/util.js";

const TOLERANCE = 0.0001;
const STEP_SECONDS = 0.1;
setup();
const t = new Checks("colon");
save_game.save_key = "test_save";
save_game.auto_save_enabled = false;
activities.reset();
h.reset();
gs.reset();
clock.reset();

// A known log over several scoring days returns the right totals per scoring day.
{
	h.reset();
	// Scoring day 0: strength 1 h, 9 h of sleep.
	h.add_entry("strength", 1);
	h.end_scoring_day(9);
	// Scoring day 1: nothing, a 0-hour day (the awake period ran out).
	h.end_scoring_day(0);
	// Scoring day 2: strength twice (counts as one day), 7 h of sleep.
	h.add_entry("strength", 0.5);
	h.add_entry("strength", 0.5);
	h.end_scoring_day(7);
	// Scoring day 3 (not closed yet): 0.5 h cardio, 0.25 h strength, 3 h of screens.
	h.add_entry("cardio", 0.5);
	h.add_entry("strength", 0.25);
	h.add_entry("screens", 3);
	t.check("three scoring days were closed", h.days.length === 3 && h.current_day === 3);
	t.check("day 0: 9 h sleep, 60 activity min, 1 strength day", totals_are(h.days[0], 9, 60, 1, 0));
	t.check("day 1: 0 h sleep, nothing done, strength day 0 still counts", totals_are(h.days[1], 0, 0, 1, 0));
	t.check("day 2: 7 h sleep, 60 min, two sessions = one more strength day", totals_are(h.days[2], 7, 60, 2, 0));
	h.end_scoring_day(9);
	const day3 = h.days.at(-1);
	t.check("day 3: 9 h sleep, 45 min, 3 strength days in the last 7, 3 h entertainment", totals_are(day3, 9, 45, 3, 3));
	const per_hour = (mety) => energy.kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety);
	const expected_kcal = 0.5 * per_hour(7) + 0.25 * per_hour(5) + 3 * per_hour(1.3) + 9 * per_hour(0.95);
	t.check("day 3: calories = BMR / 24 x METy x hours (0.5 h cardio, 0.25 h strength, 3 h screens, 9 h sleep)", Math.abs(day3.kcal - expected_kcal) < TOLERANCE);
	const entry = h.entries.filter((e) => e.type === "cardio")[0];
	t.check("an entry has its intensity and calories", entry.intensity === "moderate_vigorous" && Math.abs(entry.kcal - 0.5 * per_hour(7)) < TOLERANCE);
}

{
	h.reset();
	h.add_entry("strength", 1);
	for (let day = 0; day < 6; day++) h.end_scoring_day(9);
	t.check("strength 6 scoring days ago is still kept and counted", h.entries.some((e) => e.type === "strength")
			&& h.day_totals(h.current_day).strength_days === 1);
	h.end_scoring_day(9);
	t.check("after 7 scoring days the strength entry is dropped", !h.entries.some((e) => e.type === "strength")
			&& h.day_totals(h.current_day).strength_days === 0);
	t.check("only the last 7 closed scoring days are kept", h.days.length === 7);
}

// Real play: exercise logs the hours done (Stop counts only the time done), and an avatar
// day closes when a sleep ends: a normal sleep, a nap, and the 0-hour rule.
{
	h.reset();
	gs.reset();
	clock.reset();
	gs.start_new_avatar("Test", "teenager", "male", "normal");
	clock.set_paused(false);
	clock.debug_speed = 600;
	t.check("no closed day before the first sleep", h.days.length === 0);
	t.check("cardio starts", activities.start("exercise", "cardio"));
	while (activities.elapsed_hours < 0.5) clock._process(STEP_SECONDS);
	const done_before_stop = activities.elapsed_hours;
	activities.stop();
	t.check("one entry logged", h.entries.length === 1);
	t.check("it is a cardio entry", h.entries[0].type === "cardio");
	t.check("only the time done is logged", Math.abs(h.entries[0].hours - done_before_stop) < TOLERANCE
			&& h.entries[0].hours >= 0.5 && h.entries[0].hours < 1);
	t.check("start time is logged", "start_minute" in h.entries[0] && h.entries[0].day === clock.day_number);
	const cardio_hours = h.entries[0].hours;
	t.check("entertainment starts", activities.start("entertainment", "screens"));
	while (activities.is_running()) clock._process(STEP_SECONDS);
	t.check("two entries logged", h.entries.length === 2);
	// A normal sleep of 9 h (teenager range 8 to 10 h). The avatar can sleep only when sleepy.
	gs.hours_awake = Config.get_float("sleep.can_sleep_awake_h");
	t.check("sleep starts", activities.start("sleep", "sleep", 9));
	while (clock.phase === clock.Phase.SLEEPING) clock._process(STEP_SECONDS);
	const totals = h.days.length > 0 ? h.days.at(-1) : {};
	t.check("the day closes when the sleep ends, with its totals", Object.keys(totals).length > 0
			&& Math.abs(totals.sleep_hours - 9) < 0.1 && Math.abs(totals.activity_minutes - cardio_hours * 60) < 0.01
			&& totals.strength_days === 0 && Math.abs(totals.screen_hours - 1) < 0.01);
	t.check("the sleep is logged too", h.entries.length === 3 && h.entries.at(-1).type === "sleep" && Math.abs(h.entries.at(-1).hours - 9) < 0.1);
	t.check("a new scoring day starts after the sleep", h.current_day === 1 && h.days.length === 1);
	// The log and the days are saved and loaded.
	const saved = h.to_dict();
	const before_gs = gs.to_dict();
	save_game.save_game();
	activities.reset();
	h.reset();
	t.check("log was cleared before loading", h.entries.length === 0);
	t.check("load finds the save", save_game.load_game());
	t.check("log and days restored", h.entries.length === 3 && h.current_day === 1 && h.days.length === 1
			&& Math.abs(h.avatar_hours_total - saved.avatar_hours_total) < TOLERANCE);
	t.check("game state still restored", before_gs.avatar_name === gs.avatar_name);
	// A nap of 1 h closes a day too (any sleep counts).
	clock.wake_up();
	gs.hours_awake = Config.get_float("sleep.can_sleep_awake_h");
	t.check("nap starts", activities.start("sleep", "sleep", 1));
	while (clock.phase === clock.Phase.SLEEPING) clock._process(STEP_SECONDS);
	t.check("a 1 h nap closes a day with 1 h of sleep", h.days.length === 2 && Math.abs(h.days.at(-1).sleep_hours - 1) < 0.1);
	t.check("the nap hours are kept", Math.abs(gs.last_sleep_hours - 1) < 0.1);
	// The 0-hour rule: the awake period runs out without sleep.
	clock.wake_up();
	const days_before = h.days.length;
	const day = clock.day_number;
	while (clock.day_number === day) clock._process(STEP_SECONDS);
	t.check("a day closes when the awake period runs out without sleep", h.days.length === days_before + 1);
	t.check("it counts as 0 h slept", is_zero_approx(h.days.at(-1).sleep_hours) && is_zero_approx(gs.last_sleep_hours));
}
Storage.remove("test_save");
t.finish();

// Totals of a closed scoring day, compared with expected values.
function totals_are(totals, sleep_hours, activity_minutes, strength_days, entertainment_hours) {
	const ok = Math.abs(totals.sleep_hours - sleep_hours) < TOLERANCE && Math.abs(totals.activity_minutes - activity_minutes) < TOLERANCE
			&& totals.strength_days === strength_days && Math.abs(totals.entertainment_hours - entertainment_hours) < TOLERANCE;
	if (!ok) console.log(`  totals: ${JSON.stringify(totals)}`);
	return ok;
}
