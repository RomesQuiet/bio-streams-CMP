// WHO growth reference 5 to 19 years (2007): BMI-for-age z-scores and median height.
// Reads data/who_bmi_for_age.json and data/who_height_for_age.json.
// Sex is "male" or "female" (as GameState saves it). Age is in months and may have a
// fraction: values between two months are interpolated in a straight line, and ages
// outside the tables use the first or last month.
import {Config} from "../core/config.js";
import {Data} from "../core/data.js";
import {clampf, lerpf, signf, push_error} from "../core/util.js";

// Columns of a row in both tables (age in months first).
const MONTH = 0, L = 1, M = 2, S = 3;

export const WhoTables = {
	// L, M and S of the BMI-for-age table for this sex and age: {L, M, S}.
	bmi_lms(sex, age_months) {
		const row = _row("who_bmi", sex, age_months);
		return {L: row[L], M: row[M], S: row[S]};
	},

	// WHO BMI-for-age z-score of this BMI (kg/m²). Beyond ±extension_from_z the WHO
	// rule is used: z = 3 + (BMI - SD3) / (SD3 - SD2), and the mirror below -3.
	z_from_bmi(sex, age_months, bmi) {
		const lms = WhoTables.bmi_lms(sex, age_months);
		const z = _lms_z(lms, bmi);
		const edge = Config.get_float("who.extension_from_z");
		if (Math.abs(z) <= edge) return z;
		const side = signf(z);
		const sd_edge = _lms_bmi(lms, side * edge);
		const sd_inner = _lms_bmi(lms, side * (edge - 1));
		return side * edge + (bmi - sd_edge) / Math.abs(sd_edge - sd_inner);
	},

	// BMI (kg/m²) that gives this BMI-for-age z-score. The inverse of z_from_bmi().
	bmi_from_z(sex, age_months, z) {
		const lms = WhoTables.bmi_lms(sex, age_months);
		const edge = Config.get_float("who.extension_from_z");
		if (Math.abs(z) <= edge) return _lms_bmi(lms, z);
		const side = signf(z);
		const sd_edge = _lms_bmi(lms, side * edge);
		const sd_inner = _lms_bmi(lms, side * (edge - 1));
		return sd_edge + (z - side * edge) * Math.abs(sd_edge - sd_inner);
	},

	// WHO median height-for-age, in metres.
	median_height_m(sex, age_months) {
		return _row("who_height", sex, age_months)[M] / Config.get_float("units.cm_per_m");
	},

	// Weight (kg) with this BMI-for-age z-score at the median height for the age.
	weight_from_z(sex, age_months, z) {
		const height = WhoTables.median_height_m(sex, age_months);
		return WhoTables.bmi_from_z(sex, age_months, z) * height * height;
	},

	// Youngest and oldest age in the tables, in months: {x: first, y: last}.
	age_range_months() {
		const rows = _rows("who_bmi", "male");
		return {x: rows[0][MONTH], y: rows[rows.length - 1][MONTH]};
	},
};

// z from the LMS curve: ((BMI / M)^L - 1) / (L x S).
function _lms_z(lms, bmi) {
	return (Math.pow(bmi / lms.M, lms.L) - 1) / (lms.L * lms.S);
}

// BMI from the LMS curve: M x (1 + L x S x z)^(1 / L).
function _lms_bmi(lms, z) {
	return lms.M * Math.pow(1 + lms.L * lms.S * z, 1 / lms.L);
}

// The row for this age, interpolated between the two nearest months.
function _row(table, sex, age_months) {
	const rows = _rows(table, sex);
	const first = rows[0][MONTH];
	const position = clampf(age_months - first, 0, rows.length - 1);
	const below = rows[Math.floor(position)];
	const above = rows[Math.ceil(position)];
	const t = position - Math.floor(position);
	return below.map((value, i) => lerpf(value, above[i], t));
}

function _rows(table, sex) {
	const data = Data.files[table];
	if (!data || !(sex in data)) {
		push_error(`WhoTables: unknown sex '${sex}'`);
		return [];
	}
	return data[sex];
}
