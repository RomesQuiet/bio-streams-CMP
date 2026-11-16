// Parity run (Milestone 10.5, Task 5; team review, "Method"). Run from the project folder (it
// takes a minute):  node web/tests/parity_test.js
// Plays the v1 scenarios as close to the v1 simulation as the game allows, then changes one
// thing at a time and prints how each result moves, to find the real causes of the
// differences from v1 (documentation/milestone10_calibration.md).
// Parity: the user's decisions are off (the health bar follows the target at every step,
// decision 1; a meal takes one 5-minute step instead of half an hour, decision 2; Very hard
// starts with happiness 0.15, decision 7), the 36-hour strength gap of Milestone 10.5 is off,
// and the player looks for "I'm hungry!" every 5-minute step and eats at once. The too-soon rule
// stays. Plans that v1 does not describe are guesses (decision 12); the run also tries other
// guesses and prints which ones come closer to v1.
// Nothing here is a pass or fail of the game: it prints numbers for the team. It ends with
// ALL PASSED when every run has finished. data/config.json is never written.
import {Calibration, V1, TITLES, SHORT, TOLERANCE, pad} from "./calibration_test.js";
import {Config} from "../js/core/config.js";
import {GameState} from "../js/core/game_state.js";
import {Activities} from "../js/core/activities.js";
import {Simulation} from "../js/core/simulation.js";
import {Happiness} from "../js/health/happiness.js";
import {Hunger} from "../js/health/hunger.js";
import {format} from "../js/core/util.js";

// The rows that use the guideline activity (for the plan guesses).
const GUIDELINE_ROWS = ["guidelines", "short_sleep", "short_sleep_extra_cardio", "gradual_switch", "abrupt_switch",
	"sport_fast_food", "strength_daily"];
// Difference 2: the imperfect plans whose happiness is about 0.1 below v1, and the guidelines.
const HAPPINESS_ROWS = ["guidelines", "short_sleep", "short_sleep_extra_cardio", "cardio_4h", "healthy_no_sport", "healthy_no_sport_7h"];
// Columns of a row: the snapshot keys in the order of V1, their names and formats.
const COLUMNS = ["kg", "z", "fitness", "strength", "physical", "sleep", "happiness", "target"];
const NAMES = ["kg", "z", "fitness", "strength", "Physical", "Sleep", "Happiness", "health"];
const FORMATS = ["%.1f", "%+.2f", "%.2f", "%.2f", "%.2f", "%.2f", "%.2f", "%.2f"];
// v1's severe diet (team review): about 2.3 meals and 1,145 kcal a day.
const V1_SEVERE_MEALS = 2.3;
const V1_SEVERE_KCAL = 1145;
// The happiness parts are averaged over the last LAST_DAYS avatar days of a run (near steady state).
const LAST_DAYS = 7;
// A move smaller than this is not printed.
const SMALL = 0.005;

class Parity extends Calibration {
	constructor() {
		super();
		this._step_hours = 0;
		// Config values before the parity run changed them, and the game's meal lengths.
		this._config_original = {};
		this._game_meal_hours = {};
	}

	run() {
		this._prepare();
		this._step_hours = Simulation.step_minutes() / Config.get_float("units.minutes_per_hour");
		this._set_parity();
		console.log("\n=== Parity run (boy of 10, Normal): decisions 1, 2 and 7 off, no 36 h strength gap; the player eats as soon as");
		console.log(format("    the avatar is hungry (checked every %.0f avatar minutes). Rows at day %d: ours (v1; - = not given). ===", [this.check_hours * 60, SHORT]));
		const parity = {};
		for (const scenario of Object.keys(V1)) parity[scenario] = this._play(scenario, "male", "child", "normal", SHORT);
		this._print_rows(parity);
		this._print_counts(parity);

		console.log("\n=== One thing at a time (from the parity run) ===");
		this.check_hours = 0.5;
		const player = this._play_rows(["severe_diet", ...HAPPINESS_ROWS]);
		this._print_moves("The game's player: looks every 30 avatar minutes (and never during an activity)", parity, player);
		this.check_hours = this._step_hours;
		this._set_quick_meals(false);
		const meals = this._play_rows(["severe_diet", ...HAPPINESS_ROWS]);
		this._print_moves("Decision 2 on: a meal takes half an hour", parity, meals);
		this._set_quick_meals(true);
		this.instant_bar = false;
		const bar = this._play_rows(["guidelines", "short_sleep"]);
		this._print_moves("Decision 1 on: the health bar moves once a day (the target health does not change)", parity, bar);
		console.log(format("    XP per real hour: guidelines %.0f -> %.0f, 6 h sleep %.1f -> %.1f (v1 225 and 2.6)", [
			this._xp_per_real_hour(parity.guidelines, SHORT), this._xp_per_real_hour(bar.guidelines, SHORT),
			this._xp_per_real_hour(parity.short_sleep, SHORT), this._xp_per_real_hour(bar.short_sleep, SHORT)]));
		this.instant_bar = true;
		this._set_config("train.strength_min_gap_h", this._config_original["train.strength_min_gap_h"]);
		const gap = this._play_rows(["guidelines", "strength_daily", "strength_twice"]);
		this._print_moves("Milestone 10.5 on: 36 h between strength sessions", parity, gap);
		this._set_config("train.strength_min_gap_h", 0);
		this._check_very_hard_parity();

		console.log("\n=== Plan guesses (decision 12): which plans come closer to v1? ===");
		this.guideline.cardio_min = 40;
		this.guideline.football_min = 30;
		const football = this._play_rows(GUIDELINE_ROWS);
		this.guideline.cardio_min = 70;
		this.guideline.football_min = 0;
		this._print_moves("Guideline activity = 40 min cardio + 30 min football (instead of 70 min cardio)", parity, football);
		this._print_distance("  Distance from v1 over these rows, 70 min cardio -> 40 cardio + 30 football:", parity, football, GUIDELINE_ROWS);
		this.screens.no_sport_h = 2;
		const screens_2h = this._play_rows(["healthy_no_sport", "healthy_no_sport_7h"]);
		this.screens.no_sport_h = 1;
		this._print_moves("No-sport plans with 2 h of screens a day (instead of 1 h)", parity, screens_2h);

		console.log("\n=== Checks of the causes found ===");
		this.screens.severe_diet_h = 0;
		const no_screens = this._play_rows(["severe_diet"]);
		this.screens.severe_diet_h = 1;
		this.guideline.strength_first = true;
		const first = this._play_rows(["guidelines"]);
		this.guideline.strength_first = false;
		this.guideline.strength_min = 60;
		const long_sessions = this._play_rows(["guidelines"]);
		this.guideline.strength_min = 30;
		this._set_config("train.average_window_h", 168);
		const weekly = this._play_rows([...GUIDELINE_ROWS, "strength_twice"]);
		this._set_config("train.average_window_h", this._config_original["train.average_window_h"]);
		this._print_moves("Effective training minutes averaged over a week (train.average_window_h 168 instead of 24)", parity, weekly);
		this._print_distance("  Distance from v1 over these rows, 24 h -> 168 h:", parity, weekly, [...GUIDELINE_ROWS, "strength_twice"]);

		this._print_difference_1(parity, player, meals, no_screens);
		this._print_difference_2(parity, football, screens_2h);
		this._print_difference_4(parity, first, long_sessions, football, weekly);
		this._finish();
	}

	// --- Settings ---

	_set_parity() {
		this.check_hours = this._step_hours;
		this.instant_bar = true;
		this._set_config("health.difficulties.very_hard.happiness", 0.15);
		this._set_config("train.strength_min_gap_h", 0);
		this._set_quick_meals(true);
	}

	// Changes a config value in memory for this run only (data/config.json is never written) and
	// remembers the value it had.
	_set_config(path, value) {
		const keys = path.split(".");
		let node = Config._data;
		for (const key of keys.slice(0, -1)) node = node[key];
		const last = keys.at(-1);
		const has_value = node[last] !== null && typeof node[last] === "object" && "value" in node[last];
		if (!(path in this._config_original)) this._config_original[path] = has_value ? node[last].value : node[last];
		if (has_value) node[last].value = value;
		else node[last] = value;
	}

	// Meal length: one 5-minute step when quick (v1 eats at once), or the game's half hour
	// (decision 2). Changes the activities in memory only.
	_set_quick_meals(quick) {
		const options = Activities.definitions.eat.options;
		for (const food of Object.keys(options)) {
			if (!(food in this._game_meal_hours)) this._game_meal_hours[food] = options[food].duration_hours;
			options[food].duration_hours = quick ? this._step_hours : this._game_meal_hours[food];
		}
	}

	// --- Playing ---

	_play_rows(rows) {
		const results = {};
		for (const scenario of rows) results[scenario] = this._play(scenario, "male", "child", "normal", SHORT);
		return results;
	}

	// As in the scenario test, plus: the parts of happiness over the last LAST_DAYS days, and the
	// minutes of strength done and done beyond the daily capacity.
	_record_step(result, hours, asleep) {
		super._record_step(result, hours, asleep);
		const gs = GameState;
		if (Activities.is_running() && Config.get_value("train.strength_types").includes(Activities.current_option)) {
			result.strength_min_done = (result.strength_min_done ?? 0) + hours * Config.get_float("units.minutes_per_hour");
			result.strength_min_beyond = (result.strength_min_beyond ?? 0) + gs.beyond_capacity_minutes_step;
		}
		if (gs.sim_hours / Config.get_float("units.hours_per_day") <= SHORT - LAST_DAYS) return;
		const path = "mood.baseline.";
		const parts = {
			happiness: gs.happiness,
			baseline: gs.happiness_baseline,
			physical: Config.get_float(path + "physical") * gs.physical,
			sleep: Config.get_float(path + "sleep") * gs.sleep,
			diet: Config.get_float(path + "diet") * gs.diet_quality,
			fun: Config.get_float(path + "fun") * Happiness.fun(),
			deficit: -Config.get_float(path + "deficit") * gs.deficit_u,
			screen_excess: -Config.get_float(path + "screen_excess") * Happiness.screen_excess(),
			overreach: -Config.get_float(path + "overreach") * gs.overreach,
		};
		for (const key of Object.keys(parts)) result["late_" + key] = (result["late_" + key] ?? 0) + parts[key] * hours;
		result.late_hours = (result.late_hours ?? 0) + hours;
		if (!asleep && gs.hunger > Config.get_float("mood.events.hungry_at_meals") * Hunger.healthy_portion_kcal()) {
			result.late_hungry_hours = (result.late_hungry_hours ?? 0) + hours;
		}
	}

	// Average of a part of happiness over the last days.
	_late(result, key) {
		return (result["late_" + key] ?? 0) / Math.max(result.late_hours ?? 0, TOLERANCE);
	}

	// --- Output ---

	_print_rows(results) {
		console.log(`${pad("Scenario", 44)} ${NAMES.map((name) => pad(name, 15)).join("  ")}`);
		for (const scenario of Object.keys(results)) {
			const d = this._day(results[scenario], SHORT);
			const v = V1[scenario];
			const cells = COLUMNS.map((column, i) => pad(this._pair(FORMATS[i], d[column], v[i]), 15));
			console.log(`${pad(TITLES[scenario].slice(0, 44), 44)} ${cells.join("  ")}`);
		}
	}

	_print_counts(results) {
		console.log("\nFailure, danger state, lowest happiness, hungry share, meals and kcal a day, strength sessions too soon:");
		for (const scenario of Object.keys(results)) {
			const r = results[scenario];
			const days = r.days.length - 1;
			console.log(`  ${pad(TITLES[scenario].slice(0, 44), 44)} failure ${pad(this._failure_text(r), 30)} danger ${pad(this._day_text(r.danger_day), 5)} `
					+ format("lowest %.2f  hungry %s%%  %.2f meals (+%.2f skipped) %s kcal  too soon %d of %d", [r.lowest_happiness,
						format("%.0f", r.hungry_share * 100).padStart(3), r.meals / days, r.skipped / days, format("%.0f", r.kcal_per_day).padStart(4),
						r.too_soon, r.strength_sessions]));
		}
	}

	// How the rows move when one thing changes: "before -> after" for every column that moves,
	// and the lowest happiness.
	_print_moves(title, before, after) {
		console.log("\n" + title);
		for (const scenario of Object.keys(after)) {
			const a = this._day(before[scenario], SHORT);
			const b = this._day(after[scenario], SHORT);
			const moves = [];
			COLUMNS.forEach((column, i) => {
				if (Math.abs(b[column] - a[column]) >= SMALL) moves.push(`${NAMES[i]} ${format(FORMATS[i], a[column])} -> ${format(FORMATS[i], b[column])}`);
			});
			const low_a = before[scenario].lowest_happiness;
			const low_b = after[scenario].lowest_happiness;
			if (Math.abs(low_b - low_a) >= SMALL) moves.push(format("lowest happiness %.2f -> %.2f", [low_a, low_b]));
			console.log(`  ${pad(TITLES[scenario].slice(0, 44), 44)} ${moves.length === 0 ? "nothing moves" : moves.join(", ")}`);
		}
	}

	// Mean distance |ours - v1| per column over these rows, before -> after (only where v1 gives it).
	_print_distance(title, before, after, rows) {
		const cells = [];
		COLUMNS.forEach((column, i) => {
			const sums = [0, 0];
			let count = 0;
			for (const scenario of rows) {
				const v1 = V1[scenario][i];
				if (v1 === null) continue;
				sums[0] += Math.abs(this._day(before[scenario], SHORT)[column] - v1);
				sums[1] += Math.abs(this._day(after[scenario], SHORT)[column] - v1);
				count += 1;
			}
			if (count > 0) cells.push(format("%s %.3f -> %.3f", [NAMES[i], sums[0] / count, sums[1] / count]));
		});
		console.log(title + "\n    " + cells.join(", "));
	}

	// Very hard with decision 7 off (happiness 0.15, as v1) and on (0.30).
	_check_very_hard_parity() {
		const rows = {};
		for (const happiness of [0.15, 0.30]) {
			this._set_config("health.difficulties.very_hard.happiness", happiness);
			for (const food of ["gradual_switch", "abrupt_switch"]) rows[format("%s %.2f", [food, happiness])] = this._play(food, "male", "child", "very_hard", SHORT);
		}
		this._set_config("health.difficulties.very_hard.happiness", 0.15);
		console.log("\nVery hard, decision 7 off (starting happiness 0.15, as v1) and on (0.30). v1: gradual 4.28 (lowest happiness 0.15),");
		console.log("abrupt 4.45 (lowest 0.07; 0.13 with 0.30, team review):");
		for (const key of Object.keys(rows)) {
			const d = this._day(rows[key], SHORT);
			console.log(`  ${pad(key, 22)} ` + format("health %.2f  happiness %.2f, lowest %.2f  z %+.2f  failure %s", [d.target, d.happiness,
				rows[key].lowest_happiness, d.z, this._failure_text(rows[key])]));
		}
	}

	// Difference 1: what the severe diet eats, against v1 (about 2.3 meals and 1,145 kcal a day).
	_print_difference_1(parity, player, meals, no_screens) {
		console.log(format("\n=== Difference 1: the severe diet (v1: about %.1f meals and %.0f kcal a day; 24.0 kg, z -3.85 at day 21) ===", [
			V1_SEVERE_MEALS, V1_SEVERE_KCAL]));
		console.log("\"I'm hungry!\" comes at most every 2 h; the player skips 2 of every 3. During the screens hour it cannot answer,");
		console.log("so one moment a day comes later and the last one falls after the end of the day.");
		for (const row of [["parity", parity], ["the game's 30-minute player", player], ["30-minute meals (decision 2)", meals],
			["no screens hour (nothing blocks it)", no_screens]]) {
			const r = row[1].severe_diet;
			const days = r.days.length - 1;
			const d = this._day(r, SHORT);
			console.log(`  ${pad(row[0], 36)} ` + format("%.2f meals eaten and %.2f skipped a day, %s kcal a day; day 21: %.1f kg, z %+.2f; hungry %.0f%% of awake time", [
				r.meals / days, r.skipped / days, format("%.0f", r.kcal_per_day).padStart(4), d.kg, d.z, r.hungry_share * 100]));
		}
	}

	// Difference 2: where happiness comes from in the last days of each run (baseline parts and the
	// events, which are what keeps happiness away from its baseline).
	_print_difference_2(parity, football, screens_2h) {
		console.log(`\n=== Difference 2: happiness over days ${SHORT - LAST_DAYS} to ${SHORT}, parity run (v1 happiness at day 21 in brackets) ===`);
		console.log("Baseline = 0.15 + Physical + Sleep + diet + fun parts - deficit - screen excess - overreaching; events = happiness - baseline.");
		console.log("The hunger penalty is the share of it from being hungry while awake (0.05 per hour, kept for about 12 h).");
		const rows = {};
		for (const scenario of HAPPINESS_ROWS) rows[scenario] = parity[scenario];
		for (const scenario of GUIDELINE_ROWS) if (scenario in football && HAPPINESS_ROWS.includes(scenario)) rows[scenario + " (football plan)"] = football[scenario];
		for (const scenario of Object.keys(screens_2h)) rows[scenario + " (2 h screens)"] = screens_2h[scenario];
		for (const key of Object.keys(rows)) {
			const r = rows[key];
			const scenario = key.split(" (")[0];
			const hungry_rate = (r.late_hungry_hours ?? 0) / Math.max(r.late_hours ?? 0, TOLERANCE) * Config.get_float("mood.events.hungry_per_h");
			const name = (TITLES[scenario].slice(0, 30) + key.slice(scenario.length)).slice(0, 38);
			console.log(`  ${pad(name, 38)} ` + format("happiness %.2f (v1 %.2f)  baseline %.2f = Physical %.2f + Sleep %.2f + diet %.2f + fun %.2f %+.2f deficit %+.2f screens %+.2f overreaching;  events %+.2f, of which hunger about %+.2f", [
				this._late(r, "happiness"), V1[scenario][6], this._late(r, "baseline"), this._late(r, "physical"), this._late(r, "sleep"),
				this._late(r, "diet"), this._late(r, "fun"), this._late(r, "deficit"), this._late(r, "screen_excess"), this._late(r, "overreach"),
				this._late(r, "happiness") - this._late(r, "baseline"), hungry_rate * Config.get_float("mood.tau_h")]));
		}
	}

	// Difference 4: guideline strength (v1 0.70) with the strength session after or before the rest
	// of the day's activity (daily capacity), with 30 or 60-minute sessions, and with the effective
	// minutes averaged over a week instead of the last 24 hours; and strength day by day.
	_print_difference_4(parity, first, long_sessions, football, weekly) {
		console.log(`\n=== Difference 4: guideline strength at day ${SHORT} (v1 0.70) ===`);
		for (const row of [["30 min after 70 min of cardio (parity)", parity], ["30 min before the cardio", first],
			["60 min after the cardio", long_sessions], ["30 min after 40 cardio + 30 football", football],
			["minutes averaged over a week (168 h)", weekly]]) {
			const r = row[1].guidelines;
			console.log(`  ${pad(row[0], 40)} ` + format("strength %.2f  fitness %.2f  too soon %d of %d  strength minutes beyond the daily capacity %.0f of %.0f", [
				this._day(r, SHORT).strength, this._day(r, SHORT).fitness, r.too_soon, r.strength_sessions,
				r.strength_min_beyond ?? 0, r.strength_min_done ?? 0]));
		}
		console.log(`  Strength on waking, days ${SHORT - LAST_DAYS} to ${SHORT} (strength sessions on days 14, 16 and 18; day 21 = after day 20):`);
		for (const row of [["24 h window", parity], ["168 h window", weekly]]) {
			const values = [];
			for (let day = SHORT - LAST_DAYS; day < SHORT + 1; day++) values.push(format("%.2f", this._day(row[1].guidelines, day).strength));
			console.log(`    ${pad(row[0], 14)} ${values.join("  ")}`);
		}
	}
}

new Parity().run();
