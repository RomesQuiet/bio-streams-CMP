// Scenario tests: the v1 "Predicted results" and the "Bases fundamental check" (Milestone 10,
// Task 10; Milestone 10.5, Task 4). Run from the project folder (it takes a few minutes):
//   node web/tests/calibration_test.js
// Converted from tests/calibration_test.gd: the same scenarios, the same simulated player and the
// same rules. Plays the v1 scenarios through the real game loop and the real Eat, exercise,
// entertainment and sleep actions (a boy of 10 on Normal; then a girl of 10 and teenagers of both
// sexes), prints each scenario's row at day 21 next to the v1 prediction (and day 60 for five of
// them), failure and the danger state for every scenario, and PASS or FAIL for every rule of the
// "Bases fundamental check", the danger state, the Very hard checks and XP per real hour.
// The simulated player: every check_hours avatar hours it looks whether the avatar says "I'm
// hungry!" and, if so, eats a whole meal at once (healthy or fast food by the scenario's food
// rule; the severe diet skips 2 hungry moments of every 3). Then it starts the activities planned
// for that time. It does not look during an activity. Nothing is random.
// If a rule fails, no value is changed here: the numbers go to the team.
import {setup} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState} from "../js/core/game_state.js";
import {Clock} from "../js/core/clock.js";
import {Activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {Simulation} from "../js/core/simulation.js";
import {SaveGame} from "../js/core/save_game.js";
import {HealthLog} from "../js/core/health_log.js";
import {Hunger} from "../js/health/hunger.js";
import {HealthModel} from "../js/health/health_model.js";
import {Progress} from "../js/health/progress.js";
import {format, clampf} from "../js/core/util.js";
import {pathToFileURL} from "node:url";

export const SHORT = 21;
export const LONG = 60;
export const TOLERANCE = 0.001;
export const SLEEP_GOOD = 10.5;
// The player stops looking for meals this many avatar hours before the awake period ends (a
// meal takes half an hour), and an activity is cut this long before the end, so nothing runs
// into the 0-hour rule.
export const LAST_CHECK_BEFORE_END_H = 0.5;
const DAY_END_MARGIN_H = 0.01;

// v1 'Predicted results' at day 21 (boy of 10, Normal): kg, z, fitness, strength, Physical,
// Sleep, Happiness, Health. Scenarios marked * start with a fast-food craving of 0.9. null =
// not given. Strength every day is not in v1: its strength and health come from the team
// review's v1 model with the 36-hour gap (Milestone 10.5).
export const V1 = {
	guidelines: [33.2, 0.00, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	couch: [48.6, 2.56, 0.10, 0.10, 0.07, 0.84, 0.53, 2.60],
	fast_food_cardio: [35.6, 0.60, 0.91, 0.57, 0.32, 1.00, 0.74, 3.56],
	severe_diet: [24.0, -3.85, 0.10, 0.10, 0.05, 1.00, 0.53, 2.66],
	short_sleep_extra_cardio: [32.3, -0.27, 0.87, 0.70, 0.83, 0.45, 0.85, 3.79],
	short_sleep: [35.7, 0.63, 0.80, 0.67, 0.87, 0.45, 0.83, 3.81],
	gradual_switch: [34.3, 0.30, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	abrupt_switch: [33.2, 0.00, 0.83, 0.70, 0.88, 1.00, 1.00, 4.80],
	sport_fast_food: [42.4, 1.83, 0.83, 0.70, 0.27, 1.00, 0.75, 3.48],
	cardio_4h: [28.2, -1.73, 0.86, 0.50, 0.63, 1.00, 0.85, 4.23],
	strength_twice: [31.1, -0.63, 0.66, 0.34, 0.52, 1.00, 0.78, 3.97],
	strength_daily: [null, null, null, 0.44, null, null, null, 4.42],
	healthy_no_sport: [39.4, 1.37, 0.10, 0.10, 0.37, 1.00, 0.83, 3.77],
	healthy_no_sport_7h: [40.3, 1.51, 0.10, 0.10, 0.35, 0.66, 0.70, 3.22],
};
export const TITLES = {
	guidelines: "Guidelines: healthy food, 70 min a day, 30 min strength 3 days a week, 1 h screens, 10.5 h sleep",
	couch: "Couch: fast food, 3 h screens, no sport, 8 h sleep",
	fast_food_cardio: "Fast food with 3 h of cardio a day",
	severe_diet: "Severe diet (eats 1 meal in 3), no sport",
	short_sleep_extra_cardio: "Guidelines but 6 h sleep, extra hour of cardio",
	short_sleep: "Guideline activity, 6 h sleep",
	gradual_switch: "Gradual switch to healthy food over a week *",
	abrupt_switch: "Abrupt switch to healthy food *",
	sport_fast_food: "Guideline sport and sleep, fast food only *",
	cardio_4h: "4 h of cardio a day, healthy food",
	strength_twice: "Strength twice a day (v1: 40 min cardio, strength 9 and 12 h after waking)",
	strength_daily: "Guidelines but 1 h strength every day (review)",
	healthy_no_sport: "Healthy food, no sport",
	healthy_no_sport_7h: "Healthy food, no sport, 7 h sleep",
};
// Scenarios played for LONG days (v1 gives the day-60 z of the first four); the others for SHORT.
export const LONG_RUNS = ["guidelines", "couch", "sport_fast_food", "healthy_no_sport", "severe_diet"];
// v1 at day 60: z.
const V1_DAY_60_Z = {guidelines: -0.4, couch: 3.1, sport_fast_food: 2.0, healthy_no_sport: 1.4};

// Text padded on the right to a width (GDScript's "%-Ns").
export function pad(text, width) {
	return String(text).padEnd(width, " ");
}

export class Calibration {
	constructor() {
		// The simulated player looks whether the avatar is hungry every check_hours avatar hours.
		this.check_hours = 0.5;
		// The guideline activity of a day: minutes of cardio and of football, the strength session's
		// minutes (3 non-consecutive days a week), and whether strength comes before the rest.
		this.guideline = {cardio_min: 70, football_min: 0, strength_min: 30, strength_first: false};
		// Hours of screens a day in the two no-sport plans and in the severe diet.
		this.screens = {no_sport_h: 1, severe_diet_h: 1};
		// True: the health bar follows the target health at every step (decision 1 off; parity test).
		this.instant_bar = false;
		this._failures = 0;
	}

	run() {
		this._prepare();
		console.log("\n=== v1 scenarios: boy of 10, Normal (start: %s) ===".replace("%s", this._start_text("male", "child", "normal")));
		console.log(`Player: looks for "I'm hungry!" every ${format("%.0f", this.check_hours * 60)} avatar minutes and eats at once; never during an activity.`);
		const results = {};
		for (const scenario of Object.keys(V1)) {
			const days = LONG_RUNS.includes(scenario) ? LONG : SHORT;
			results[scenario] = this._play(scenario, "male", "child", "normal", days);
		}
		this._print_table(results);
		this._print_failures(results);
		this._check_bases(results);
		this._check_danger(results);
		this._check_variants();
		this._check_very_hard();
		this._finish();
	}

	// Keeps the real save and the CSV log out of the way.
	_prepare() {
		setup();
		SaveGame.save_key = "test_save";
		SaveGame.auto_save_enabled = false;
		HealthLog.enabled = false;
	}

	_finish() {
		console.log(`\n${this._failures === 0 ? "ALL PASSED" : "SOME FAILED"} (${this._failures} failed)`);
		process.exitCode = this._failures > 0 ? 1 : 0;
	}

	// --- Rules ---

	// Every row of the v1 "Bases fundamental check" table.
	_check_bases(r) {
		console.log(`\n=== Bases fundamental check (day ${SHORT}; target health) ===`);
		const g = this._day(r.guidelines, SHORT);
		const start = this._day(r.guidelines, 0);
		this._rule("Exercise within norms raises health", format("guidelines %.2f -> %.2f", [start.target, g.target]),
				g.target > start.target + 1);
		const c4 = this._day(r.cardio_4h, SHORT);
		const s2 = this._day(r.strength_twice, SHORT);
		const sd = this._day(r.strength_daily, SHORT);
		this._rule("Too much or too often does less good", format("4 h cardio %.2f, strength twice %.2f, strength every day %.2f, guidelines %.2f", [
			c4.target, s2.target, sd.target, g.target]),
				c4.target < g.target && s2.target < g.target && sd.target < g.target);
		const couch = this._day(r.couch, SHORT);
		const sport_ff = this._day(r.sport_fast_food, SHORT);
		this._rule("Fast food makes the avatar fatter", format("z +%.2f -> couch %+.2f, sport and sleep with fast food %+.2f", [start.z, couch.z, sport_ff.z]),
				couch.z > start.z && sport_ff.z > start.z);
		const gradual = this._day(r.gradual_switch, SHORT);
		this._rule("Healthy food makes it slimmer", format("z +%.2f -> guidelines %+.2f, gradual switch %+.2f", [start.z, g.z, gradual.z]),
				g.z < start.z && gradual.z < start.z);
		const ff_cardio = this._day(r.fast_food_cardio, SHORT);
		this._rule("Fast food with a lot of exercise: thinner, not healthy", format("z %+.2f, Physical %.2f (guidelines %.2f)", [ff_cardio.z, ff_cardio.physical, g.physical]),
				ff_cardio.z < start.z && ff_cardio.physical < 0.5 * g.physical);
		const severe = this._day(r.severe_diet, SHORT);
		this._rule("Severe diet without exercise: thinner, not healthy (hungry and sad)",
				format("z %+.2f, Physical %.2f, hungry (above 1.2 meals) %.0f%% of awake time (guidelines %.0f%%), lowest happiness %.2f", [severe.z,
					severe.physical, r.severe_diet.hungry_share * 100, r.guidelines.hungry_share * 100, r.severe_diet.lowest_happiness]),
				severe.z < start.z && severe.physical < 0.2 && r.severe_diet.hungry_share > 0.5
				&& r.severe_diet.lowest_happiness < Config.get_float("avatar_states.sad_below"));
		const short = r.short_sleep;
		const g7 = this._day(r.guidelines, 7);
		const s7 = this._day(short, 7);
		const more_food = short.kcal_per_day / r.guidelines.kcal_per_day - 1;
		this._rule("Short sleep: slower fitness gain, more hunger, tired, worse health",
				format("fitness day 7 %.2f vs %.2f; food %+.0f%%; Sleep %.2f; health %.2f vs %.2f; tired %.0f%% of awake time", [s7.fitness, g7.fitness,
					more_food * 100, this._day(short, SHORT).sleep, this._day(short, SHORT).target, g.target, short.tired_share * 100]),
				s7.fitness < g7.fitness && more_food > 0.05 && this._day(short, SHORT).sleep < 0.7
				&& this._day(short, SHORT).target < g.target && short.tired_share > r.guidelines.tired_share);
		const abrupt = r.abrupt_switch;
		this._rule("Refusing wishes lowers happiness; exercise and sleep raise it",
				format("lowest happiness: abrupt %.2f vs gradual %.2f; guidelines happiness %.2f", [abrupt.lowest_happiness,
					r.gradual_switch.lowest_happiness, g.happiness]),
				abrupt.lowest_happiness < r.gradual_switch.lowest_happiness && g.happiness > 0.85);
		this._rule("Healthy and happy together", format("guidelines health %.2f, happiness %.2f", [g.target, g.happiness]),
				g.target >= 4.5 && g.happiness >= 0.85);
		const xp_good = this._xp_per_real_hour(r.guidelines, SHORT);
		const xp_short = this._xp_per_real_hour(short, SHORT);
		this._rule("Short sleep must not pay in real time", format("%.1f XP per real hour with 6 h sleep against %.1f with 10.5 h (v1: 2.6 against 225)", [xp_short, xp_good]),
				xp_short < 0.25 * xp_good);
	}

	// Milestone 10.5 (team review): the severe diet reaches the danger state of severe thinness and
	// then failure, before z -5 (biologically implausible); no other scenario reaches the danger state.
	_check_danger(r) {
		console.log("\n=== Danger state of severe thinness (Milestone 10.5) ===");
		const severe = r.severe_diet;
		this._rule("The severe diet reaches the danger state, then failure before z -5",
				`danger from day ${this._day_text(severe.danger_day)}; failure ${this._failure_text(severe)}`,
				severe.danger_day >= 0 && severe.failure_cause === "thinness" && severe.failure_z > -5);
		const others = Object.keys(r).filter((scenario) => scenario !== "severe_diet" && r[scenario].danger_day >= 0);
		this._rule("No other scenario reaches the danger state", `reached: ${others.length === 0 ? "none" : others.join(", ")}`, others.length === 0);
	}

	// The same pattern for a girl of 10 and teenagers of both sexes (v1: "The same behaviour gives
	// the same pattern"): guidelines raise health and lower z; the couch raises z.
	_check_variants() {
		console.log(`\n=== Variants (day ${SHORT}) ===`);
		for (const variant of [["female", "child"], ["male", "teenager"], ["female", "teenager"]]) {
			const guide = this._play("guidelines", variant[0], variant[1], "normal", SHORT);
			const couch = this._play("couch", variant[0], variant[1], "normal", SHORT);
			const start = this._day(guide, 0);
			const g = this._day(guide, SHORT);
			const c = this._day(couch, SHORT);
			this._rule(`${variant[0]} ${variant[1]}: guidelines raise health and lower z, the couch raises z`,
					format("start %.2f z %+.2f; guidelines %.2f z %+.2f; couch %.2f z %+.2f", [start.target, start.z, g.target, g.z, c.target, c.z]),
					g.target > start.target + 1 && g.z < start.z && c.z > start.z && c.target < g.target);
		}
	}

	// Very hard (happiness 0.30, decision 7): starts with the lowest health, recovers with the
	// guidelines, does not reach failure in the first days with a gradual change, and an abrupt
	// food switch drops happiness lower than a gradual one.
	_check_very_hard() {
		console.log(`\n=== Very hard (start: ${this._start_text("male", "child", "very_hard")}) ===`);
		let lowest_start = Infinity;
		for (const difficulty of ["easy", "normal", "hard"]) lowest_start = Math.min(lowest_start, this._start_health("male", "child", difficulty));
		const vh_start = this._start_health("male", "child", "very_hard");
		this._rule("Very hard starts with the lowest health", format("%.2f (the others: %.2f or more)", [vh_start, lowest_start]), vh_start < lowest_start);
		const gradual = this._play("gradual_switch", "male", "child", "very_hard", SHORT);
		const abrupt = this._play("abrupt_switch", "male", "child", "very_hard", SHORT);
		for (const row of [["gradual switch", gradual, 4.28, "0.15"], ["abrupt switch", abrupt, 4.45, "0.07; 0.13 with 0.30"]]) {
			const d = this._day(row[1], SHORT);
			console.log(`    ${pad(row[0], 15)} ` + format("target %.2f (v1 %.2f; bar %.2f)  happiness %.2f, lowest %.2f (v1 %s)  z %+.2f  failure %s", [
				d.target, row[2], d.health, d.happiness, row[1].lowest_happiness, row[3], d.z, this._failure_text(row[1])]));
		}
		this._rule("Very hard recovers with the guidelines", format("target %.2f -> %.2f", [vh_start, this._day(gradual, SHORT).target]),
				this._day(gradual, SHORT).target >= 3);
		this._rule("Very hard with a gradual change does not reach failure in the first days", `failure ${this._failure_text(gradual)}`,
				gradual.failure_day < 0 || gradual.failure_day > 7);
		this._rule("Very hard: an abrupt food switch drops happiness lower than a gradual one",
				format("lowest %.2f vs %.2f", [abrupt.lowest_happiness, gradual.lowest_happiness]), abrupt.lowest_happiness < gradual.lowest_happiness);
	}

	// --- Playing a scenario ---

	// Plays a scenario for this many avatar days and returns its daily values (index 0 = start)
	// and its counts. Days are avatar days since the start (24 avatar hours each); -1 = never.
	_play(scenario, sex, group, difficulty, days) {
		const gs = this._new_avatar(sex, group, difficulty);
		if (["gradual_switch", "abrupt_switch", "sport_fast_food"].includes(scenario)) gs.craving = Math.max(gs.craving, 0.9);
		const result = {days: [this._snapshot(gs)], lowest_happiness: gs.happiness, hungry_hours: 0, tired_hours: 0,
			kcal_eaten: 0, meals: 0, skipped: 0, awake_hours: 0, asleep_hours: 0, failure_day: -1,
			failure_cause: "", failure_z: 0, danger_day: -1, strength_sessions: 0, too_soon: 0};
		const on_step = (hours, asleep) => this._record_step(result, hours, asleep);
		// Simulation hears an activity start first, so strength_too_soon is already set here.
		const on_started = (_activity_id, option_id) => {
			if (Config.get_value("train.strength_types").includes(option_id)) {
				result.strength_sessions += 1;
				if (gs.strength_too_soon) result.too_soon += 1;
			}
		};
		Simulation.stepped.connect(on_step);
		Activities.started.connect(on_started);
		let hungry_moments = 0;
		for (let day = 0; day < days; day++) {
			const plan = this._day_plan(scenario, day);
			let slot = 0;
			while (slot * this.check_hours < Clock.day_length_hours - LAST_CHECK_BEFORE_END_H) {
				const time = slot * this.check_hours;
				this._idle_until(time);
				if (Hunger.is_hungry()) {
					hungry_moments += 1;
					if (plan.food === "skip_2_of_3" && hungry_moments % 3 !== 0) {
						Hunger.skip();
						result.skipped += 1;
					} else {
						const food = this._food_for(plan, result);
						result.kcal_eaten += Hunger.meal_kcal(food, 1);
						result.meals += 1;
						this._play_activity("eat", food, 1);
					}
				}
				for (const event of plan.events) {
					if (Math.abs(event[0] - time) < this.check_hours * 0.5) this._play_activity(event[1], event[2], event[3]);
				}
				slot += 1;
			}
			this._sleep(plan.sleep);
			result.days.push(this._snapshot(gs));
		}
		Simulation.stepped.disconnect(on_step);
		Activities.started.disconnect(on_started);
		result.hungry_share = result.hungry_hours / Math.max(result.awake_hours, TOLERANCE);
		result.tired_share = result.tired_hours / Math.max(result.awake_hours, TOLERANCE);
		result.kcal_per_day = result.kcal_eaten / days;
		return result;
	}

	// After every 5-minute step of a scenario: the hours awake, asleep, hungry and tired, the
	// lowest happiness, the longest time with happiness below the failure line (does the
	// 12-hour timer fire?), and the first danger state and failure. With instant_bar the health bar
	// jumps to the target (and the change gives or takes XP, as when the bar moves).
	_record_step(result, hours, asleep) {
		const gs = GameState;
		if (this.instant_bar) {
			const change = gs.target_health - gs.health;
			gs.health = gs.target_health;
			Progress.on_health_change(change);
		}
		result.lowest_happiness = Math.min(result.lowest_happiness, gs.happiness);
		if (asleep) {
			result.asleep_hours += hours;
		} else {
			result.awake_hours += hours;
			// Hungry while awake as v1 Step 10 defines it: hunger above 1.2 healthy meals.
			if (gs.hunger > Config.get_float("mood.events.hungry_at_meals") * Hunger.healthy_portion_kcal()) result.hungry_hours += hours;
			if (gs.tired) result.tired_hours += hours;
		}
		result.longest_unhappy_hours = Math.max(result.longest_unhappy_hours ?? 0, gs.happiness_low_hours);
		const day = gs.sim_hours / Config.get_float("units.hours_per_day");
		if (result.danger_day < 0 && HealthModel.in_danger()) result.danger_day = day;
		if (result.failure_day < 0 && gs.is_at_failure()) {
			result.failure_day = day;
			result.failure_cause = HealthModel.failure_cause();
			result.failure_z = gs.weight_z;
		}
	}

	// What the avatar does on one day of a scenario: events [hour after waking, activity, option,
	// share of the option's duration], the food rule and the hours of sleep.
	_day_plan(scenario, day) {
		const sport = this._guideline_sport([0, 2, 4].includes(day % 7), this.guideline.strength_min);
		const screens_1h = this._screens(1);
		const plan = {events: [...sport, ...screens_1h], food: "healthy", sleep: SLEEP_GOOD, day};
		switch (scenario) {
			case "couch":
				plan.events = [[2, "entertainment", "screens", 1], [3, "entertainment", "screens", 1], [4, "entertainment", "screens", 1]];
				plan.food = "fast";
				plan.sleep = 8;
				break;
			case "fast_food_cardio":
				plan.events = [[1, "exercise", "cardio", 1], [2, "exercise", "cardio", 1], [3, "exercise", "cardio", 1], ...screens_1h];
				plan.food = "fast";
				break;
			case "severe_diet":
				plan.events = this._screens(this.screens.severe_diet_h);
				plan.food = "skip_2_of_3";
				break;
			case "short_sleep_extra_cardio":
				plan.events = [...sport, [4.5, "exercise", "cardio", 1], ...screens_1h];
				plan.sleep = 6;
				break;
			case "short_sleep":
				plan.sleep = 6;
				break;
			case "gradual_switch":
				plan.food = "gradual";
				break;
			case "sport_fast_food":
				plan.food = "fast";
				break;
			case "cardio_4h":
				plan.events = [[1, "exercise", "cardio", 1], [2, "exercise", "cardio", 1], [3, "exercise", "cardio", 1],
					[4, "exercise", "cardio", 1], ...screens_1h];
				break;
			case "strength_twice":
				// v1's plan (team review): 40 min of cardio, strength 1 h at 9 and 12 hours after
				// waking, 1 h of screens, no football.
				plan.events = [[1, "exercise", "cardio", 40 / 60], [9, "exercise", "strength", 1],
					[12, "exercise", "strength", 1], ...screens_1h];
				break;
			case "strength_daily":
				plan.events = [...this._guideline_sport(true, 60), ...screens_1h];
				break;
			case "healthy_no_sport":
				plan.events = this._screens(this.screens.no_sport_h);
				break;
			case "healthy_no_sport_7h":
				plan.events = this._screens(this.screens.no_sport_h);
				plan.sleep = 7;
				break;
		}
		return plan;
	}

	// Screens from 6 h after waking, in blocks of at most 1 h, one per hour.
	_screens(hours) {
		const events = [];
		let left = hours;
		let start = 6;
		while (left > TOLERANCE) {
			events.push([start, "entertainment", "screens", Math.min(left, 1)]);
			left -= 1;
			start += 1;
		}
		return events;
	}

	// The guideline activity of one day: guideline.cardio_min of cardio in blocks of at most 1 h,
	// then guideline.football_min of football, one block per hour from 1 h after waking; on a
	// strength day a strength session of strength_min after them (or first, with strength_first).
	_guideline_sport(strength_day, strength_min) {
		const blocks = [];
		let cardio = this.guideline.cardio_min;
		while (cardio > TOLERANCE) {
			blocks.push(["exercise", "cardio", Math.min(cardio, 60) / 60]);
			cardio -= 60;
		}
		if (this.guideline.football_min > 0) blocks.push(["entertainment", "football", this.guideline.football_min / 60]);
		if (strength_day) {
			const session = ["exercise", "strength", strength_min / 60];
			if (this.guideline.strength_first) blocks.unshift(session);
			else blocks.push(session);
		}
		return blocks.map((block, i) => [1 + i, ...block]);
	}

	// Healthy or fast food for the next meal. "gradual": the share of healthy meals grows by a
	// quarter every 7 / 4 days (all healthy after a week).
	_food_for(plan, result) {
		if (plan.food === "fast") return "fast_food_meal";
		if (plan.food === "gradual") {
			const share = clampf(Math.floor(4 * (plan.day + 1) / 7) / 4, 0.25, 1);
			result.gradual_meals = (result.gradual_meals ?? 0) + 1;
			result.healthy_meals = result.healthy_meals ?? 0;
			const healthy = result.healthy_meals < share * result.gradual_meals - TOLERANCE;
			if (healthy) result.healthy_meals += 1;
			return healthy ? "healthy_meal" : "fast_food_meal";
		}
		return "healthy_meal";
	}

	_snapshot(gs) {
		return {kg: gs.weight_kg, z: gs.weight_z, fitness: gs.fitness, strength: gs.strength, physical: gs.physical,
			sleep: gs.sleep, happiness: gs.happiness, target: gs.target_health, health: gs.health, xp: gs.xp};
	}

	_day(result, day) {
		return result.days[Math.min(day, result.days.length - 1)];
	}

	// XP earned per real hour of play over these days (awake: 42 avatar minutes per real minute,
	// asleep: 5; the same conversion as the Clock).
	_xp_per_real_hour(result, days) {
		const ratio = days / (result.days.length - 1);
		const real_seconds = (Clock.avatar_hours_to_real_seconds(result.awake_hours, false)
				+ Clock.avatar_hours_to_real_seconds(result.asleep_hours, true)) * ratio;
		return (this._day(result, days).xp - this._day(result, 0).xp) / (real_seconds / 3600);
	}

	// --- Output ---

	_print_table(results) {
		console.log(`\nRows at day ${SHORT}: ours (v1; - = not given). Health: target (v1) and the displayed bar.`);
		console.log(pad("Scenario", 62) + " " + ["kg", "z", "Fitness", "Strength", "Physical", "Sleep", "Happiness", "Health (bar)"]
				.map((title, i) => pad(title, [14, 15, 11, 11, 11, 11, 11, 18][i])).join(" "));
		for (const scenario of Object.keys(V1)) {
			const d = this._day(results[scenario], SHORT);
			const v = V1[scenario];
			const cells = [this._pair("%.1f", d.kg, v[0]), this._pair("%+.2f", d.z, v[1]), this._pair("%.2f", d.fitness, v[2]),
				this._pair("%.2f", d.strength, v[3]), this._pair("%.2f", d.physical, v[4]), this._pair("%.2f", d.sleep, v[5]),
				this._pair("%.2f", d.happiness, v[6]), this._pair("%.2f", d.target, v[7]) + format(" %.2f", d.health)];
			console.log(pad(TITLES[scenario].slice(0, 62), 62) + " " + cells.map((cell, i) => pad(cell, [14, 15, 11, 11, 11, 11, 11, 18][i])).join(" "));
		}
		console.log(`\nDay ${LONG} (v1 gives z only):`);
		for (const scenario of LONG_RUNS) {
			const d = this._day(results[scenario], LONG);
			console.log(`  ${pad(TITLES[scenario].slice(0, 60), 60)} ` + format("%.1f kg  %s  health %.2f (bar %.2f)", [d.kg,
				this._pair("z %+.2f", d.z, V1_DAY_60_Z[scenario] ?? null), d.target, d.health]));
		}
	}

	// Failure, the danger state and the player's counts for every scenario (team review, Method).
	_print_failures(results) {
		console.log("\nEvery scenario, all days played: failure (day, cause, z), first day in the danger state, lowest happiness and the");
		console.log(format("longest time below the happiness failure line (the timer fires at %.0f h), hungry share of awake time (above 1.2 meals),", Config.get_float("fail.happiness_hours")));
		console.log("meals eaten and skipped and kcal eaten per day, strength sessions too soon.");
		for (const scenario of Object.keys(V1)) {
			const r = results[scenario];
			const days = r.days.length - 1;
			console.log(`  ${pad(TITLES[scenario].slice(0, 44), 44)} failure ${pad(this._failure_text(r), 30)} danger ${pad(this._day_text(r.danger_day), 5)} `
					+ format("lowest %.2f (%s h below)  hungry %s%%  %.2f meals (+%.2f skipped) %s kcal a day  too soon %d of %d", [
						r.lowest_happiness, format("%.1f", r.longest_unhappy_hours).padStart(4), format("%.0f", r.hungry_share * 100).padStart(3),
						r.meals / days, r.skipped / days, format("%.0f", r.kcal_per_day).padStart(4), r.too_soon, r.strength_sessions]));
		}
	}

	// "ours (v1)" with this format; "-" when v1 does not give the value.
	_pair(text_format, ours, v1) {
		return `${format(text_format, ours)} (${v1 === null || v1 === undefined ? "-" : format(text_format, Number(v1))})`;
	}

	_failure_text(result) {
		if (result.failure_day < 0) return "none";
		return format("day %.1f (%s, z %+.2f)", [result.failure_day, result.failure_cause, result.failure_z]);
	}

	_day_text(day) {
		return day < 0 ? "none" : format("%.1f", day);
	}

	_rule(name, numbers, ok) {
		if (!ok) this._failures += 1;
		console.log(`${ok ? "PASS" : "FAIL"}  ${name}\n      ${numbers}`);
	}

	_start_text(sex, group, difficulty) {
		const gs = this._new_avatar(sex, group, difficulty);
		return format("%.1f kg, z %+.1f, Physical %.2f, Sleep %.2f, Happiness %.2f, health %.2f", [gs.weight_kg, gs.weight_z,
			gs.physical, gs.sleep, gs.happiness, gs.health]);
	}

	_start_health(sex, group, difficulty) {
		return this._new_avatar(sex, group, difficulty).health;
	}

	// --- Driving the game ---

	// Plays an activity for this share of its duration, never into the end of the awake period
	// (the 0-hour rule would start a new day).
	_play_activity(activity_id, option_id, share) {
		Clock.debug_speed = 600;
		if (!Activities.start(activity_id, option_id)) return;
		const stop_at = Math.min(Activities.target_hours * share, Clock.day_length_hours - Clock.day_elapsed_hours - DAY_END_MARGIN_H);
		while (Activities.is_running() && Activities.elapsed_hours < stop_at - TOLERANCE) {
			Clock._process(Math.min(0.05, Clock.avatar_hours_to_real_seconds(stop_at - Activities.elapsed_hours, false) / 600 + 1e-6));
		}
		Activities.stop();
		Simulation.flush();
	}

	_idle_until(day_hours) {
		Clock.debug_speed = 600;
		while (Clock.day_elapsed_hours < day_hours && Clock.phase === Clock.Phase.DAY) {
			Clock._process(Math.min(0.1, Clock.avatar_hours_to_real_seconds(day_hours - Clock.day_elapsed_hours, false) / 600 + 1e-6));
		}
	}

	_sleep(hours) {
		this._idle_until(Clock.day_length_hours - 0.01);
		Activities.start("sleep", "sleep", hours);
		while (Clock.phase === Clock.Phase.SLEEPING) Clock._process(0.1);
		Clock.wake_up();
	}

	_new_avatar(sex, group, difficulty) {
		Activities.reset();
		Habits.reset();
		Simulation.reset();
		GameState.reset();
		Clock.reset();
		GameState.start_new_avatar("Test", group, sex, difficulty);
		return GameState;
	}
}

// Run directly (not when the parity test extends it).
if (import.meta.url === pathToFileURL(process.argv[1]).href) new Calibration().run();
