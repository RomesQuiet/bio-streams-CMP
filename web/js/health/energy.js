// Energy and weight (v1 Steps 3 and 5, Milestone 10). Energy per avatar hour = BMR / 24 x METy
// of what the avatar is doing. BMR is the Schofield equation for the sex and the body age band
// (energy.bmr in config). Sleep never changes the metabolic rate. Weight changes by
// body.k x (kcal eaten - kcal spent) / body.kcal_per_kg; because BMR depends on weight, weight
// settles where intake and spending meet. The energy deficit penalty U comes from the kcal
// eaten and spent in the last deficit.window_h avatar hours. All numbers come from Config.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Activities} from "../core/activities.js";
import {Minigame} from "../core/minigame.js";
import {WhoTables} from "./who_tables.js";
import {HourWindow} from "./hour_window.js";
import {clampf} from "../core/util.js";

export const Energy = {
	// Basal metabolic rate in kcal per day.
	bmr(sex, age_months, weight_kg) {
		const band = age_months >= Config.get_float("energy.bmr_band_from_months") ? "from_10" : "below_10";
		const path = `energy.bmr.${sex}.${band}.`;
		return Config.get_float(path + "per_kg") * weight_kg + Config.get_float(path + "base");
	},

	// Weight (kg) at the WHO median BMI (z 0) and median height for the age.
	healthy_weight_kg(sex, age_months) {
		return WhoTables.weight_from_z(sex, age_months, 0);
	},

	// Reference appetite in kcal per day: BMR at the healthy weight x energy.pal_ref, the energy
	// needs of an active child of healthy weight (v1 Step 4).
	reference_kcal_per_day(sex, age_months) {
		return Energy.bmr(sex, age_months, Energy.healthy_weight_kg(sex, age_months)) * Config.get_float("energy.pal_ref");
	},

	// One healthy portion in kcal: the reference / meals.per_day_ref.
	healthy_portion_kcal(sex, age_months) {
		return Energy.reference_kcal_per_day(sex, age_months) / Config.get_float("meals.per_day_ref");
	},

	// METy of what the avatar is doing now: the running activity's mety (data/activities.json),
	// minigame.walk_mety while the minigame has it walking, or energy.mety_idle when it is doing
	// nothing (no activity, or the minigame waits for a tap).
	mety_now() {
		const idle = Config.get_float("energy.mety_idle");
		if (Activities.doing_option() === "") return idle;
		if (Minigame.is_walking()) return Config.get_float("minigame.walk_mety");
		return Number(Activities.option_value(Activities.current_option_data(), "mety", idle));
	},

	// kcal spent per avatar hour with this METy.
	kcal_per_hour(sex, age_months, weight_kg, mety) {
		return Energy.bmr(sex, age_months, weight_kg) / Config.get_float("units.hours_per_day") * mety;
	},

	// Step 2 of the update order: the kcal spent in this step. They go into the energy window,
	// take weight off, and (during exercise) add to the calories-spent record.
	step(hours, _asleep) {
		const gs = GameState;
		gs.energy_spent_step = Energy.kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, Energy.mety_now()) * hours;
		_add_to_window("spent", gs.energy_spent_step);
		_change_weight(-gs.energy_spent_step);
		if (Activities.doing_option() !== "") {
			const intensity = String(Activities.option_value(Activities.current_option_data(), "activity_intensity", ""));
			if (Config.get_value("energy.record_intensities").includes(intensity)) gs.calories_spent += gs.energy_spent_step;
		}
	},

	// A meal's kcal: into the energy window, and onto the weight.
	add_eaten(kcal) {
		_add_to_window("eaten", kcal);
		_change_weight(kcal);
	},

	// Step 5 of the update order: U = 0 below a deficit of deficit.start, rising in a straight
	// line to 1 at deficit.full. deficit = 1 - kcal eaten / kcal spent in the window.
	update_deficit() {
		GameState.deficit_u = Energy.deficit_penalty(Energy.window_total("eaten"), Energy.window_total("spent"));
	},

	deficit_penalty(eaten, spent) {
		if (spent <= 0) return 0;
		const deficit = 1 - eaten / spent;
		const start = Config.get_float("deficit.start");
		return clampf((deficit - start) / (Config.get_float("deficit.full") - start), 0, 1);
	},

	// Sum of kcal "eaten" or "spent" in the window.
	window_total(kind) {
		return HourWindow.total(GameState.energy_window, GameState.sim_hours, kind);
	},

	// A window as if the avatar had eaten what it spent, at the reference appetite, so a new
	// avatar does not start with a deficit.
	balanced_window(sex, age_months) {
		const per_hour = Energy.reference_kcal_per_day(sex, age_months) / Config.get_float("units.hours_per_day");
		return HourWindow.create(Config.get_int("deficit.window_h"), {eaten: per_hour, spent: per_hour}, ["eaten", "spent"]);
	},
};

// Weight change: body.k x kcal / body.kcal_per_kg (k is body time).
function _change_weight(kcal) {
	GameState.weight_kg += Config.get_float("body.k") * kcal / Config.get_float("body.kcal_per_kg");
}

// Adds kcal to the slot of the current avatar hour.
function _add_to_window(kind, kcal) {
	HourWindow.add(GameState.energy_window, GameState.sim_hours, kind, kcal);
}
