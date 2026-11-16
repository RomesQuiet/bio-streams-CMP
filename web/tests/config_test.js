// Tests for the config (Milestone 4, Task 1). Run from the project folder:
//   node web/tests/config_test.js
// Checks the health block, that no health number is left in the health code, and that
// reloading a changed config changes the next day's calculation. data/config.json is never
// changed.
import fs from "node:fs";
import path from "node:path";
import {setup, Checks, ROOT} from "./harness.js";
import {Config as config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Activities as activities} from "../js/core/activities.js";
import {SaveGame} from "../js/core/save_game.js";
import {BodySize as body_size} from "../js/health/body_size.js";
import {deep_copy, format, is_equal_approx} from "../js/core/util.js";

// The health code that must not hold any game number (and every file in HEALTH_FOLDER).
const HEALTH_SCRIPTS = ["web/js/core/game_state.js", "web/js/core/habits.js", "web/js/core/simulation.js"];
const HEALTH_FOLDER = "web/js/health/";
// The Milestone 10 (v1) groups: every value in them needs value, status and owner.
const V1_GROUPS = ["body", "energy", "appetite", "meals", "deficit", "train", "minigame", "diet", "sleep",
	"mood", "health", "fail", "risk", "progress", "avatar_states", "who"];
// Keys v1 needs (a sample from every step), as dotted paths from the top of the config.
const V1_KEYS = ["body.k", "body.kcal_per_kg", "body.max_age_months.child", "body.max_age_months.teenager",
	"energy.pal_ref", "energy.mety_idle", "appetite.habit_share", "meals.hungry_trigger", "meals.min_gap_h",
	"deficit.start", "deficit.full", "train.capacity_base_min", "train.fitness_tau_days",
	"train.strength_recovery_h", "minigame.default_score", "diet.quality_tau_days", "diet.habituation_tau_days",
	"sleep.child_min_h", "sleep.teenager_target_h", "sleep.debt_recovery_tau_days", "sleep.can_sleep_debt_h",
	"mood.tau_h", "mood.baseline.physical", "mood.fun.football", "mood.events.football_per_h",
	"health.combine.p", "health.combine.weights.happiness", "health.physical_mix.weight", "health.alpha_bar",
	"health.weight_score_points", "fail.health_line", "fail.happiness_hours", "risk.z_weight",
	"progress.per_health_point", "avatar_states.sad_below", "who.extension_from_z", "time.step_avatar_min"];

setup();
const t = new Checks("colon");
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;

// Milestone 10 Task 1: the v1 groups. Every value has value, status and owner (the Schofield
// rows have per_kg and base instead of value), and the user's decisions are in.
{
	const missing = V1_KEYS.filter((key) => config.get_value(key) === null);
	if (missing.length > 0) console.log("  missing: " + missing);
	t.check("the v1 keys are in the config", missing.length === 0);
	const incomplete = [];
	for (const group of V1_GROUPS) collect_incomplete(config._data[group], group, incomplete);
	if (incomplete.length > 0) console.log("  without value, status or owner: " + incomplete);
	t.check("every v1 value has value, status and owner", incomplete.length === 0);
	t.check("k is 10 (team decision, 25 Oct 2026)", config.get_float("body.k") === 10 && !config.is_placeholder("body.k"));
	t.check("health p is 0.5 (v1 Step 11)", config.get_float("health.combine.p") === 0.5);
	t.check("the Milestone 4 health block and old XP rules are gone (Task 8)", !("health_m4" in config._data)
			&& !("thresholds" in config._data) && !("gain_per_avatar_hour" in config._data.xp));
	t.check("a placeholder status counts as a placeholder", config.is_placeholder("sleep.debt_ref_h") && !config.is_placeholder("body.k"));
	t.check("METy: cardio 7.0, muscle strength 5.0 (Milestone 10, replaces kcal_per_hour)",
			activities.option_value(activities.get_option("exercise", "cardio"), "mety") === 7
			&& activities.option_value(activities.get_option("exercise", "strength"), "mety") === 5);
	t.check("alpha_bar is kept at 0.37 (decision 1)", is_equal_approx(config.get_float("health.alpha_bar"), 0.37));
	t.check("there is no death", config.get_value("health.death_enabled") === false);
	t.check("Very hard starting happiness is 0.30 (decision 7)", config.get_float("health.difficulties.very_hard.happiness") === 0.3);
	t.check("minigame default score is 1 (decision 5)", config.get_float("minigame.default_score") === 1);
	t.check("the body stops at 12 y 11 m (child) and 18 y 11 m (teenager) (decision 8)",
			config.get_int("body.max_age_months.child") === 155 && config.get_int("body.max_age_months.teenager") === 227);
	let weights = 0;
	for (const measure of ["physical", "happiness", "sleep"]) weights += config.get_float("health.combine.weights." + measure);
	t.check("the health weights add up to 1", is_equal_approx(weights, 1));
	const difficulty_keys = ["z", "fitness", "strength", "Q", "C", "A", "happiness", "sleep_debt", "status", "owner"];
	let difficulties_ok = true;
	for (const difficulty of ["easy", "normal", "hard", "very_hard"]) {
		difficulties_ok = difficulties_ok && difficulty_keys.every((key) => key in config._data.health.difficulties[difficulty]);
	}
	t.check("each difficulty has every v1 starting value, status and owner", difficulties_ok);
}

// Any number other than 0 and 1 outside comments and strings is reported.
{
	const number = /(?<![\w.])\d+(\.\d+)?(?![\w.])/g;
	const text_in_quotes = /"[^"]*"|`[^`]*`/g;
	const found = [];
	const files = [...HEALTH_SCRIPTS];
	for (const file of fs.readdirSync(path.join(ROOT, HEALTH_FOLDER))) if (file.endsWith(".js")) files.push(HEALTH_FOLDER + file);
	for (const file of files) {
		const lines = fs.readFileSync(path.join(ROOT, file), "utf8").split("\n");
		lines.forEach((line, i) => {
			const code = line.split("//")[0].replace(text_in_quotes, "\"\"");
			for (const match of code.matchAll(number)) {
				if (!["0", "1", "0.0", "1.0"].includes(match[0])) found.push(`${path.basename(file)}:${i + 1} ${match[0]}`);
			}
		});
	}
	if (found.length > 0) console.log("  numbers found: " + found);
	t.check("no game number in the health code", found.length === 0);
}

// Changing k in the config and reloading changes the next day's calculation.
{
	gs.start_new_avatar("Test", "child", "female", "normal");
	const start = gs.body_age_months;
	body_size.step(24, false);
	const growth_k10 = gs.body_age_months - start;
	const original = config._data;
	const data = deep_copy(original);
	data.body.k.value = 1;
	const reloaded = [false];
	config.reloaded.connect(() => reloaded[0] = true);
	const quiet = console.log;
	console.log = () => {};
	config.reload(data);
	console.log = quiet;
	t.check("reload reads the changed file", reloaded[0] && config.get_float("body.k") === 1);
	gs.start_new_avatar("Test", "child", "female", "normal");
	body_size.step(24, false);
	const growth_k1 = gs.body_age_months - start;
	console.log(format("  body age growth in one avatar day: k = 10 -> %.4f months, k = 1 -> %.4f months", [growth_k10, growth_k1]));
	t.check("with k = 1 after reload, the body changes 10 times less", is_equal_approx(growth_k1 * 10, growth_k10));
	console.log = () => {};
	config.reload(original);
	console.log = quiet;
	t.check("the real config is back (k = 10)", config.get_float("body.k") === 10);
}
t.finish();

// Adds to found the path of every value in node without value, status and owner.
// Comments, the difficulty rows and the Schofield rows are checked elsewhere or skipped.
function collect_incomplete(node, at, found) {
	if (node === null || typeof node !== "object" || Array.isArray(node)) {
		found.push(at);
		return;
	}
	if ("status" in node) {
		if (!("owner" in node) || !("value" in node || "per_kg" in node || "z" in node)) found.push(at);
		return;
	}
	for (const key of Object.keys(node)) if (!key.startsWith("_")) collect_incomplete(node[key], `${at}.${key}`, found);
}
