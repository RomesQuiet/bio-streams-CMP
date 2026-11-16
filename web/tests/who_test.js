// Tests for the WHO tables (Milestone 10, Task 1). Run from the project folder:
//   node web/tests/who_test.js
// Checks the v1 example row, the z-score round trip (also beyond ±3), the median height
// and the starting weights. Nothing is saved.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {WhoTables as who} from "../js/health/who_tables.js";
import {format, is_equal_approx} from "../js/core/util.js";

setup();
const t = new Checks("colon");

// v1 Step 2: boy of 10 years 0 months: L = -1.7407, M = 16.4433, S = 0.10566.
// v1 Normal start for that boy: z +1.2 gives 36.0 kg.
const lms = who.bmi_lms("male", 120);
t.check("boy 10 y 0 m: L -1.7407, M 16.4433, S 0.10566", is_equal_approx(lms.L, -1.7407)
		&& is_equal_approx(lms.M, 16.4433) && is_equal_approx(lms.S, 0.10566));
const weight = who.weight_from_z("male", 120, 1.2);
console.log(format("  boy 10 y, z +1.2: %.2f kg (v1: 36.0)", weight));
t.check("boy 10 y with z +1.2 weighs about 36.0 kg", Math.abs(weight - 36.0) < 0.1);
t.check("the median BMI has z 0", Math.abs(who.z_from_bmi("male", 120, lms.M)) < 1e-6);

// z -> BMI -> z gives the same z, for both sexes, several ages and z beyond ±3.
let worst = 0;
for (const sex of ["male", "female"]) {
	for (const age of [61, 120, 155, 168, 227, 140.5]) {
		for (const z of [-4.5, -3.5, -3.0, -2.0, 0.0, 1.2, 2.4, 3.0, 3.2, 4.5]) {
			const bmi = who.bmi_from_z(sex, age, z);
			worst = Math.max(worst, Math.abs(who.z_from_bmi(sex, age, bmi) - z));
		}
	}
}
console.log(`  largest round-trip error: ${worst}`);
t.check("z -> BMI -> z round trip (both sexes, 5 to 19 years, z -4.5 to +4.5)", worst < 1e-6);

// Beyond +3 the WHO rule is a straight line: each extra z adds SD3 - SD2 of BMI.
// Also checks that z keeps rising with BMI across +3 and -3 (no jump).
const sd2 = who.bmi_from_z("female", 120, 2);
const sd3 = who.bmi_from_z("female", 120, 3);
const sd4 = who.bmi_from_z("female", 120, 4);
t.check("above +3: SD4 - SD3 = SD3 - SD2", is_equal_approx(sd4 - sd3, sd3 - sd2));
t.check("girl 10 y: BMI at z +2 and +3 match the WHO table (22.57 and 28.378)", Math.abs(sd2 - 22.57) < 0.01 && Math.abs(sd3 - 28.378) < 0.01);
const sdm2 = who.bmi_from_z("female", 120, -2);
const sdm3 = who.bmi_from_z("female", 120, -3);
const sdm4 = who.bmi_from_z("female", 120, -4);
t.check("below -3: SD-3 - SD-4 = SD-2 - SD-3", is_equal_approx(sdm3 - sdm4, sdm2 - sdm3));
let rising = true;
let last = -Infinity;
for (let i = 0; i < 81; i++) {
	const z = who.z_from_bmi("male", 150, 8 + i * 0.5);
	rising = rising && z > last;
	last = z;
}
t.check("z rises with BMI from 8 to 48 kg/m² (no jump at ±3)", rising);

t.check("boy 10 y median height 137.78 cm", Math.abs(who.median_height_m("male", 120) - 1.377795) < 1e-5);
const h120 = who.median_height_m("female", 120);
const h121 = who.median_height_m("female", 121);
const half = who.median_height_m("female", 120.5);
t.check("120.5 months is halfway between 120 and 121", is_equal_approx(half, (h120 + h121) / 2));
const ages = who.age_range_months();
t.check("tables go from 61 to 228 months", ages.x === 61 && ages.y === 228);
t.check("ages outside the tables use the first or last month",
		who.median_height_m("male", 300) === who.median_height_m("male", 228) && who.median_height_m("male", 10) === who.median_height_m("male", 61));
t.check("the age caps fit inside the tables (decision 8)",
		Config.get_float("body.max_age_months.teenager") <= ages.y && Config.get_float("body.start_age_months.child") >= ages.x);

// Starting weight and height of each difficulty, for the team (no pass or fail).
console.log("  Starting weight from z (kg, at the median height):");
for (const group of ["child", "teenager"]) {
	const age = Config.get_float("body.start_age_months." + group);
	for (const sex of ["male", "female"]) {
		let line = `    ${group.padEnd(8)} ${sex.padEnd(6)} ${format("%.0f", who.median_height_m(sex, age) * 100)} cm:`;
		for (const difficulty of ["easy", "normal", "hard", "very_hard"]) {
			const z = Config.get_float(`health.difficulties.${difficulty}.z`);
			line += `  ${difficulty} ${format("%.1f", who.weight_from_z(sex, age, z))}`;
		}
		console.log(line);
	}
}
t.finish();
