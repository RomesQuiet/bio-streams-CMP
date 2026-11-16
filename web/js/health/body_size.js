// Body size and weight status (v1 Step 2, Milestone 10). The body ages with body time
// (body.k), but never past the end of its age group (decision 8). Height is the WHO median
// height for the body age, so a growing child's BMI-for-age can fall without losing weight.
// z is the WHO BMI-for-age z-score of weight / height². All numbers come from Config.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {WhoTables} from "./who_tables.js";
import {lerpf} from "../core/util.js";

export const BodySize = {
	// Step 4 of the update order: body age, height and z.
	step(hours, _asleep) {
		const gs = GameState;
		const group = gs.age_group !== "" ? gs.age_group : Config.get_string("defaults.age_group");
		const months_per_hour = Config.get_float("units.months_per_year") / Config.get_float("units.hours_per_year");
		gs.body_age_months = Math.min(gs.body_age_months + Config.get_float("body.k") * hours * months_per_hour,
				Config.get_float("body.max_age_months." + group));
		gs.height_m = WhoTables.median_height_m(gs.sex_or_default(), gs.body_age_months);
		gs.weight_z = WhoTables.z_from_bmi(gs.sex_or_default(), gs.body_age_months, BodySize.bmi(gs.weight_kg, gs.height_m));
	},

	bmi(weight_kg, height_m) {
		return weight_kg / (height_m * height_m);
	},

	// Weight score w(z), 0 to 1: straight lines between the [z, score] points of
	// health.weight_score_points; 0 outside them.
	weight_score(z) {
		const points = Config.get_value("health.weight_score_points");
		if (z < Number(points[0][0]) || z > Number(points[points.length - 1][0])) return 0;
		for (let i = 0; i < points.length - 1; i++) {
			const a = points[i];
			const b = points[i + 1];
			if (z <= Number(b[0])) {
				return lerpf(Number(a[1]), Number(b[1]), (z - Number(a[0])) / (Number(b[0]) - Number(a[0])));
			}
		}
		return Number(points[points.length - 1][1]);
	},
};
