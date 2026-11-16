// Sleep (v1 Step 9, Milestone 10 Task 6). All numbers come from Config (group sleep).
// At each new avatar day (when any sleep ends, or by the 0-hour rule, which counts as 0 h):
// - debt = debt x e^(-(slept / target) x 24 / (debt_recovery_tau_days x 24 / k)) + max(0,
//   minimum - slept). The recovery time constant is body time (k applies; team, 25 Oct 2026):
//   with k = 10 a full night repays 86% of the debt, and no sleep repays nothing.
// - Sleep measure = (1 - min(1, debt / debt_ref_h)) x (1 - min(oversleep_cut_max,
//   oversleep_cut_per_h x hours above the maximum)).
// - Night quality = (slept / minimum)^night_quality_power when short, 1 in the range, and
//   1 - oversleep_cut_per_h per hour above it (at least 1 - oversleep_cut_max).
// The recommended range and target come from the age group (child or teenager).
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {clampf} from "../core/util.js";

export const SleepModel = {
	// Minimum, maximum and target sleep (hours) for the age group: {min, max, target}.
	recommended(age_group) {
		const group = age_group !== "" ? age_group : Config.get_string("defaults.age_group");
		const path = `sleep.${group}_`;
		return {min: Config.get_float(path + "min_h"), max: Config.get_float(path + "max_h"),
				target: Config.get_float(path + "target_h")};
	},

	// A new avatar day after sleeping this many hours: sleep debt, Sleep measure and night quality.
	new_day(slept) {
		const gs = GameState;
		gs.sleep_debt = SleepModel.debt_after(gs.sleep_debt, slept, gs.age_group);
		gs.sleep = SleepModel.sleep_measure(gs.sleep_debt, SleepModel.oversleep(slept, gs.age_group));
		gs.night_quality = SleepModel.night_quality(slept, gs.age_group);
		gs.last_sleep_hours = slept;
		SleepModel.update_tired();
	},

	// Sleep debt after a sleep of this many hours.
	debt_after(debt, slept, age_group) {
		const range_h = SleepModel.recommended(age_group);
		const tau_hours = Config.get_float("sleep.debt_recovery_tau_days") * Config.get_float("units.hours_per_day")
				/ Config.get_float("body.k");
		const repaid = Math.exp(-(slept / range_h.target) * Config.get_float("units.hours_per_day") / tau_hours);
		return debt * repaid + Math.max(0, range_h.min - slept);
	},

	// Hours slept above the top of the recommended range.
	oversleep(slept, age_group) {
		return Math.max(0, slept - SleepModel.recommended(age_group).max);
	},

	sleep_measure(debt, oversleep_hours) {
		return (1 - Math.min(1, debt / Config.get_float("sleep.debt_ref_h")))
				* (1 - Math.min(Config.get_float("sleep.oversleep_cut_max"), Config.get_float("sleep.oversleep_cut_per_h") * oversleep_hours));
	},

	night_quality(slept, age_group) {
		const range_h = SleepModel.recommended(age_group);
		if (slept < range_h.min) return Math.pow(slept / range_h.min, Config.get_float("sleep.night_quality_power"));
		return 1 - Math.min(Config.get_float("sleep.oversleep_cut_max"), Config.get_float("sleep.oversleep_cut_per_h") * SleepModel.oversleep(slept, age_group));
	},

	// Sleep debt factor d = min(1, debt / sleep.debt_ref_h), from 0 to 1.
	debt_factor() {
		return clampf(GameState.sleep_debt / Config.get_float("sleep.debt_ref_h"), 0, 1);
	},

	// Tiredness, 0 to 1 (v1 Step 9): the larger of d and (hours awake - sleep.tired_awake_from_h)
	// / sleep.tired_awake_range_h.
	tiredness() {
		const awake = (GameState.hours_awake - Config.get_float("sleep.tired_awake_from_h"))
				/ Config.get_float("sleep.tired_awake_range_h");
		return clampf(Math.max(SleepModel.debt_factor(), awake), 0, 1);
	},

	// "I'm tired" (GameState.tired) when tiredness is at least avatar_states.tired_at.
	update_tired() {
		GameState.tired = SleepModel.tiredness() >= Config.get_float("avatar_states.tired_at");
	},
};
