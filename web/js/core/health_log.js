// Debug CSV log (Milestone 4 Task 8; Milestone 10 Task 11). With ?debug in the address, keeps one
// line per avatar hour with every state of the v1 health system, so the team can compare the
// game with its spreadsheet simulation (decided in Milestone 10 Task 0). The debug panel saves
// it as a file (health_log.csv). Never in the published game unless ?debug is used, and not in
// the tests unless they turn it on. If the log has another header (an older version), it starts
// again.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Activities} from "./activities.js";
import {Simulation} from "./simulation.js";
import {Storage} from "./storage.js";
import {Debug} from "./debug.js";
import {format} from "./util.js";
import {Energy} from "../health/energy.js";
import {Training} from "../health/training.js";
import {SleepModel} from "../health/sleep_model.js";
import {Happiness} from "../health/happiness.js";
import {BodySize} from "../health/body_size.js";

const LOG_KEY = "plasticine_tamagotchi_health_log";
const SEPARATOR = ",";

export const HealthLog = {
	SEPARATOR,
	// Where the log is kept. Tests change it.
	log_path: LOG_KEY,
	enabled: false,
	// The last avatar hour written (hours since the avatar was created); -1 = none yet.
	_last_hour: -1,

	_ready() {
		HealthLog.enabled = Debug.allowed();
		Simulation.stepped.connect(_on_stepped);
	},

	// The column names, in order.
	header() {
		return ["avatar_hour", "clock_day", "time", "asleep", "activity",
			"difficulty", "age_group", "sex",
			"body_age_months", "height_cm", "weight_kg", "z", "weight_score",
			"hunger_kcal", "hours_since_meal", "kcal_eaten_24h", "kcal_spent_24h", "deficit_u", "calories_spent",
			"fitness", "strength", "cardio_recovery", "strength_recovery", "hours_since_strength", "exercise_min_today",
			"capacity_min", "overreach", "sleep_debt", "tiredness", "hours_awake", "night_quality",
			"diet_quality", "craving", "habituation", "fun", "screen_excess", "happiness_baseline",
			"physical", "happiness", "sleep", "target_health", "health", "health_level", "xp",
			"health_low_hours", "happiness_low_hours", "danger_hours", "risk_index", "disease_damage"];
	},

	// The values now, in the order of header().
	row() {
		const gs = GameState;
		const values = [String(Math.floor(gs.sim_hours)), String(Clock.day_number), Clock.clock_text(),
			String(Clock.phase === Clock.Phase.SLEEPING), Activities.current_option, gs.difficulty, gs.age_group, gs.sex];
		for (const value of [gs.body_age_months, gs.height_m * Config.get_float("units.cm_per_m"), gs.weight_kg, gs.weight_z,
			BodySize.weight_score(gs.weight_z),
			gs.hunger, gs.hours_since_meal, Energy.window_total("eaten"), Energy.window_total("spent"), gs.deficit_u, gs.calories_spent,
			gs.fitness, gs.strength, gs.cardio_recovery, gs.strength_recovery, gs.hours_since_strength, gs.exercise_minutes_today,
			Training.capacity_min(), gs.overreach,
			gs.sleep_debt, SleepModel.tiredness(), gs.hours_awake, gs.night_quality,
			gs.diet_quality, gs.craving, gs.habituation, Happiness.fun(), Happiness.screen_excess(), gs.happiness_baseline,
			gs.physical, gs.happiness, gs.sleep, gs.target_health, gs.health]) values.push(_number(value));
		values.push(String(gs.health_level), _number(gs.xp));
		for (const value of [gs.health_low_hours, gs.happiness_low_hours, gs.danger_hours, gs.risk_index, gs.disease_damage]) {
			values.push(_number(value));
		}
		return values;
	},

	// Writes the current values as one line (and the header first, in a new log).
	write_line() {
		const header = HealthLog.header().join(SEPARATOR);
		let text = Storage.get(HealthLog.log_path);
		if (text === "" || text.split("\n")[0] !== header) text = header + "\n";
		Storage.set(HealthLog.log_path, text + HealthLog.row().join(SEPARATOR) + "\n");
	},

	// The whole log as text (the debug panel saves it as a file).
	text() {
		return Storage.get(HealthLog.log_path);
	},
};

// After every step: one line each time a new avatar hour is complete.
function _on_stepped(_hours, _asleep) {
	if (!HealthLog.enabled || !GameState.is_created()) return;
	const hour = Math.floor(GameState.sim_hours);
	if (hour < HealthLog._last_hour) HealthLog._last_hour = -1; // A new avatar: its hours start again from 0.
	if (hour > HealthLog._last_hour) {
		HealthLog._last_hour = hour;
		HealthLog.write_line();
	}
}

function _number(value) {
	return format("%.4f", value);
}
