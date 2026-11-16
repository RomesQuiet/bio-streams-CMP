// Holds the avatar's current state. All numbers come from Config.
// Time (Clock) and saving (SaveGame) live in their own modules.
import {Config} from "./config.js";
import {Signal, deep_copy, get, roundf, push_error} from "./util.js";
import {WhoTables} from "../health/who_tables.js";
import {Energy} from "../health/energy.js";
import {Training} from "../health/training.js";
import {SleepModel} from "../health/sleep_model.js";
import {Happiness} from "../health/happiness.js";
import {HealthModel} from "../health/health_model.js";

// Values that always stay between 0 and 1.
const MEASURES_0_TO_1 = ["physical", "happiness", "sleep", "strength", "fitness"];
// The player's choices on the avatar creation screen. Empty means not chosen yet.
const CHOICE_KEYS = ["avatar_name", "age_group", "sex", "difficulty"];

// Every value that is saved, in the order of to_dict().
const NUMBER_KEYS = ["physical", "happiness", "happiness_baseline", "diet_quality", "craving", "habituation",
	"screen_minutes_today", "hours_without_screens", "sleep", "health", "hunger", "hours_since_meal", "weight_kg",
	"body_age_months", "height_m", "deficit_u", "sim_hours", "cardio_recovery", "strength_recovery",
	"hours_since_strength", "exercise_minutes_today", "overreach_minutes", "overreach", "strength",
	"calories_spent", "fitness", "sleep_debt", "night_quality", "last_sleep_hours", "weight_z", "hours_awake",
	"health_low_hours", "happiness_low_hours", "danger_hours", "failed_day", "best_health", "risk_index",
	"disease_damage", "xp", "high_health_hours"];
const WINDOW_KEYS = ["fun_window", "energy_window", "training_window"];

export const GameState = {
	MEASURES_0_TO_1,
	CHOICE_KEYS,
	changed: new Signal(),
	// Emitted when XP reaches a new level.
	leveled_up: new Signal(),
	// XP really changed by this much (0 is never sent: at 0 XP a loss changes nothing). The main
	// screen shows it over the XP bar (user, 7 Nov 2026).
	xp_changed: new Signal(),
	// Emitted when the model counts a wish as refused (Milestone 16): "screens" after
	// mood.events.no_screens_after_h awake hours without screens. Only the speech bubble listens.
	wish_refused: new Signal(),
	// Emitted once, when the avatar reaches failure (cause: "thinness", "health" or "happiness").
	// Failure is final (user, 7 Nov 2026): the main screen shows the failure screen.
	failed: new Signal(),

	// Measures (see the Godot comments in each health module): physical, happiness and sleep
	// 0 to 1; health is the displayed health (decision 1).
	physical: 0, happiness: 0, happiness_baseline: 0, diet_quality: 0, craving: 0, habituation: 0,
	fun_window: {}, screen_minutes_today: 0, hours_without_screens: 0, sleep: 0, health: 0,
	hunger: 0, hours_since_meal: 0, weight_kg: 0, body_age_months: 0, height_m: 0, deficit_u: 0,
	energy_window: {}, sim_hours: 0, cardio_recovery: 0, strength_recovery: 0, strength_too_soon: false,
	hours_since_strength: 0, exercise_minutes_today: 0, overreach_minutes: 0, overreach: 0,
	training_window: {}, night_quality: 0, last_sleep_hours: 0,
	// Minutes beyond the daily capacity and kcal spent in the last step (not saved).
	beyond_capacity_minutes_step: 0, energy_spent_step: 0,
	strength: 0, calories_spent: 0, fitness: 0, sleep_debt: 0, weight_z: 0, tired: false, hours_awake: 0,
	health_low_hours: 0, happiness_low_hours: 0, danger_hours: 0,
	// Failure is final (user, 7 Nov 2026): its cause ("" before failure) and the avatar day it came.
	failed_cause: "", failed_day: 0,
	// The highest displayed health the avatar reached (the failure screen shows it).
	best_health: 0,
	risk_index: 0, disease_damage: 0, xp: 0, high_health_hours: 0,
	avatar_name: "", age_group: "", sex: "", difficulty: "",

	// Health the displayed health moves toward: the health formula of the current measures.
	get target_health() {
		return GameState.calculate_health();
	},

	// Health as a whole number from 1 to 5 (health rounded). Shown in the health level box.
	get health_level() {
		return roundf(GameState.health);
	},

	// Level shown next to the XP bar. Starts at 0.
	get level() {
		return Math.floor(GameState.xp / _xp_per_level());
	},

	// How full the XP bar is inside the current level (0 to 1).
	get level_progress() {
		return (GameState.xp % _xp_per_level()) / _xp_per_level();
	},

	// Sets every value to its start value from Config (new avatar). Until the player
	// chooses a difficulty, the default difficulty's starting values are used.
	reset() {
		const gs = GameState;
		gs.calories_spent = Config.get_float("measures.calories_spent_start");
		gs.tired = false;
		gs.hours_awake = 0;
		gs.xp = Config.get_float("xp.start");
		gs.high_health_hours = 0;
		gs.avatar_name = Config.get_string("defaults.avatar_name");
		gs.age_group = "";
		gs.sex = "";
		gs.difficulty = "";
		_apply_body_start();
		gs.health = gs.calculate_health();
		gs.best_health = gs.health;
		gs.changed.emit();
	},

	// Everything that must be saved. Used by SaveGame (and later, maybe a server).
	to_dict() {
		const gs = GameState;
		const data = {};
		for (const key of NUMBER_KEYS) data[key] = gs[key];
		for (const key of WINDOW_KEYS) data[key] = deep_copy(gs[key]);
		data.strength_too_soon = gs.strength_too_soon;
		data.tired = gs.tired;
		data.failed_cause = gs.failed_cause;
		for (const key of CHOICE_KEYS) data[key] = gs[key];
		return data;
	},

	// Restores values from to_dict(). Missing keys keep their current value.
	from_dict(data) {
		const gs = GameState;
		for (const key of NUMBER_KEYS) {
			// These start from 0 when missing (as in the Godot version).
			const fallback = ["hours_awake", "health_low_hours", "happiness_low_hours", "danger_hours", "failed_day",
				"risk_index", "disease_damage"].includes(key) ? 0 : gs[key];
			if (key !== "best_health") gs[key] = Number(get(data, key, fallback));
		}
		for (const key of WINDOW_KEYS) {
			const window = data[key];
			if (window !== null && typeof window === "object" && !Array.isArray(window)) {
				gs[key] = deep_copy(window);
				// The hour is a whole number.
				gs[key].hour = Math.trunc(Number(get(gs[key], "hour", -1)));
			}
		}
		gs.strength_too_soon = Boolean(get(data, "strength_too_soon", gs.strength_too_soon));
		gs.tired = Boolean(get(data, "tired", gs.tired));
		gs.failed_cause = String(get(data, "failed_cause", ""));
		for (const key of CHOICE_KEYS) gs[key] = String(get(data, key, gs[key]));
		gs.best_health = Math.max(Number(get(data, "best_health", gs.health)), gs.health);
		gs.changed.emit();
	},

	// Called by the creation screen's Start button: stores the choices and sets the
	// starting values of the chosen difficulty. Starting health is calculated from them.
	start_new_avatar(new_name, new_age_group, new_sex, new_difficulty) {
		const gs = GameState;
		gs.avatar_name = new_name;
		gs.age_group = new_age_group;
		gs.sex = new_sex;
		gs.difficulty = new_difficulty;
		_apply_body_start();
		gs.health = gs.calculate_health();
		gs.best_health = gs.health;
		gs.changed.emit();
	},

	// The chosen sex, or the default one before the player chooses.
	sex_or_default() {
		return GameState.sex !== "" ? GameState.sex : Config.get_string("defaults.sex");
	},

	// Once per avatar day, when a sleep ends (Habits calls this): the displayed health moves
	// part of the way to the target (decision 1). Everything else changes in Simulation's steps
	// and events.
	daily_update() {
		HealthModel.daily_step();
		GameState.changed.emit();
	},

	// Failure (there is no death): target health or happiness has stayed below its failure line
	// for long enough, or severe thinness has (fail group in config). Final once reached (user,
	// 7 Nov 2026): it stays even if the values recover.
	is_at_failure() {
		return GameState.failed_cause !== "" || HealthModel.is_at_failure();
	},

	// The cause of the failure: the one saved when it came, or the timers' cause now ("" if none).
	failure_cause() {
		return GameState.failed_cause !== "" ? GameState.failed_cause : HealthModel.failure_cause();
	},

	// True once the avatar has been created (name, age group, sex and difficulty chosen).
	is_created() {
		return GameState.has_all_choices(GameState.to_dict());
	},

	// True if saved GameState data (from to_dict()) holds all the creation choices.
	// Saves from before the creation screen do not.
	has_all_choices(data) {
		return CHOICE_KEYS.every((key) => String(get(data, key, "")).trim() !== "");
	},

	// Target health from the current measures (v1 Step 11).
	calculate_health() {
		return HealthModel.target_health(GameState.physical, GameState.happiness, GameState.sleep);
	},

	// Adds activity effects: {"value name": change per avatar hour} for this many hours.
	// Called by Activities. Unknown names are reported and skipped. Health does not change
	// here; it moves once per avatar day.
	apply_effects(effects_per_hour, hours) {
		const gs = GameState;
		for (const key of Object.keys(effects_per_hour)) {
			if (!(key in gs)) {
				push_error(`GameState: unknown effect '${key}'`);
				continue;
			}
			let value = gs[key] + Number(effects_per_hour[key]) * hours;
			if (MEASURES_0_TO_1.includes(key)) value = Math.min(Math.max(value, 0), 1);
			gs[key] = value;
		}
		gs.changed.emit();
	},

	// Adds (or, if negative, removes) XP. XP never goes below 0.
	add_xp(amount) {
		const gs = GameState;
		const old_level = gs.level;
		const old_xp = gs.xp;
		gs.xp = Math.max(0, gs.xp + amount);
		if (gs.xp !== old_xp) gs.xp_changed.emit(gs.xp - old_xp);
		if (gs.level > old_level) gs.leveled_up.emit(gs.level);
		gs.changed.emit();
	},
};

function _xp_per_level() {
	return Math.max(1, Config.get_float("xp.per_level"));
}

function _age_group_or_default(group) {
	return group !== "" ? group : Config.get_string("defaults.age_group");
}

// Starting body (Milestone 10): body age from the age group, the starting z of the
// difficulty (health.difficulties), weight from that z at the WHO median height for the age,
// an energy window in balance, and hunger of a new avatar (ready for breakfast).
function _apply_body_start() {
	const gs = GameState;
	const difficulty_id = gs.difficulty !== "" ? gs.difficulty : Config.get_string("defaults.difficulty");
	gs.body_age_months = Config.get_float("body.start_age_months." + _age_group_or_default(gs.age_group));
	gs.weight_z = Config.get_float(`health.difficulties.${difficulty_id}.z`);
	gs.height_m = WhoTables.median_height_m(gs.sex_or_default(), gs.body_age_months);
	gs.weight_kg = WhoTables.weight_from_z(gs.sex_or_default(), gs.body_age_months, gs.weight_z);
	gs.sim_hours = 0;
	gs.energy_window = Energy.balanced_window(gs.sex_or_default(), gs.body_age_months);
	gs.deficit_u = 0;
	// Training starts rested, from the v1 starting fitness and strength of the difficulty.
	gs.fitness = Config.get_float(`health.difficulties.${difficulty_id}.fitness`);
	gs.strength = Config.get_float(`health.difficulties.${difficulty_id}.strength`);
	gs.training_window = Training.starting_window(gs.fitness, gs.strength);
	gs.cardio_recovery = 1;
	// Sleep (v1 Step 9): the starting debt of the difficulty gives the starting Sleep measure.
	gs.sleep_debt = Config.get_float(`health.difficulties.${difficulty_id}.sleep_debt`);
	gs.sleep = SleepModel.sleep_measure(gs.sleep_debt, 0);
	gs.night_quality = 1;
	gs.last_sleep_hours = 0;
	SleepModel.update_tired();
	gs.strength_recovery = 1;
	gs.strength_too_soon = false;
	// Long enough ago that the first strength session is never too soon.
	gs.hours_since_strength = Config.get_float("train.strength_min_gap_h");
	gs.exercise_minutes_today = 0;
	gs.overreach_minutes = 0;
	gs.overreach = 0;
	gs.hunger = Config.get_float("meals.start_hunger_meals") * Energy.healthy_portion_kcal(gs.sex_or_default(), gs.body_age_months);
	gs.hours_since_meal = Config.get_float("meals.min_gap_h");
	// Happiness and diet (v1 Steps 7 and 10).
	const path = `health.difficulties.${difficulty_id}.`;
	gs.happiness = Config.get_float(path + "happiness");
	gs.diet_quality = Config.get_float(path + "Q");
	gs.craving = Config.get_float(path + "C");
	gs.habituation = Config.get_float(path + "A");
	gs.fun_window = Happiness.starting_window();
	gs.screen_minutes_today = 0;
	gs.hours_without_screens = 0;
	// The measures and failure from those starting states (v1 Steps 8 and 12).
	gs.physical = HealthModel.physical();
	gs.health_low_hours = 0;
	gs.happiness_low_hours = 0;
	gs.danger_hours = 0;
	gs.failed_cause = "";
	gs.failed_day = 0;
	gs.risk_index = 0;
	gs.disease_damage = 0;
	gs.happiness_baseline = Happiness.baseline();
}
