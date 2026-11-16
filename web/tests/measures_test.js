// Tests for the measures, health and failure (Milestone 4 Task 6; Milestone 10 Task 8, v1 Steps
// 8, 11 and 12). Run from the project folder:  node web/tests/measures_test.js
// Plays avatar days with the main screen open and checks, after each sleep, that Physical, the
// target health and the health bar follow the v1 formulas and that the screen shows them. Then
// checks the failure timers and message, the avatar states, the health bar warning of the danger
// state (Milestone 10.5) and the physical values box. Nothing is saved.
import {setup_ui, Checks} from "./harness.js";
import {Config as config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {Clock as clock} from "../js/core/clock.js";
import {Activities as activities} from "../js/core/activities.js";
import {Habits} from "../js/core/habits.js";
import {SaveGame as save_game} from "../js/core/save_game.js";
import {TranslationServer} from "../js/core/translation.js";
import {format, is_equal_approx} from "../js/core/util.js";
import {HealthModel as health_model} from "../js/health/health_model.js";
import {AvatarStates as states_script} from "../js/health/avatar_states.js";
import {DANGER_TEXT, HEALTH_BAR_STYLE, DANGER_BAR_STYLE, FAILURE_TEXTS} from "../js/ui/main_screen.js";

const TOLERANCE = 0.0001;
const STEP_SECONDS = 0.1;
const DAYS = 3;

const Scene = await setup_ui();
const t = new Checks("colon");
save_game.save_key = "test_save";
save_game.auto_save_enabled = false;
TranslationServer.set_locale("en");
activities.reset();
Habits.reset();
gs.reset();
clock.reset();
gs.start_new_avatar("Test", "child", "female", "normal");
const main = Scene.open("main");

test_days();
test_physical_formula();
test_failure();
test_states_and_values();
Scene.close();
t.finish();

function test_days() {
	clock.debug_speed = 600;
	console.log("day  physical happiness sleep  target  health (bar)");
	for (let day = 0; day < DAYS; day++) {
		for (const [activity, option] of [["eat", "healthy_meal"], ["exercise", "cardio"], ["entertainment", "screens"]]) {
			activities.start(activity, option);
			while (activities.is_running()) clock._process(STEP_SECONDS);
		}
		const health_before = gs.health;
		gs.hours_awake = config.get_float("sleep.can_sleep_awake_h");
		activities.start("sleep", "sleep", 10);
		while (clock.phase === clock.Phase.SLEEPING) clock._process(STEP_SECONDS);
		console.log(format("%3d  %.3f    %.3f      %.3f  %.3f   %.3f (%.3f)", [day + 1, gs.physical, gs.happiness, gs.sleep,
			gs.target_health, gs.health, main.health_bar.value]));
		const d = day + 1;
		t.check(`day ${d}: Physical follows the v1 formula`, Math.abs(gs.physical - health_model.physical()) < TOLERANCE);
		t.check(`day ${d}: target = 1 + 4 x the power mean (p 0.5) of the three measures`,
			Math.abs(gs.target_health - (1 + 4 * Math.pow((Math.sqrt(gs.physical) + Math.sqrt(gs.happiness) + Math.sqrt(gs.sleep)) / 3, 2))) < TOLERANCE);
		const expected_health = health_before + config.get_float("health.alpha_bar") * (gs.target_health - health_before);
		t.check(`day ${d}: health += alpha_bar x (target - health)`, Math.abs(gs.health - expected_health) < TOLERANCE);
		t.check(`day ${d}: the health bar and level box show it`, is_equal_approx(main.health_bar.value, gs.health)
			&& main.health_level_button.text === String(gs.health_level));
		t.check(`day ${d}: the measures panel shows the new values`, is_equal_approx(main.physical_bar.value, gs.physical)
			&& is_equal_approx(main.happiness_bar.value, gs.happiness) && is_equal_approx(main.sleep_bar.value, gs.sleep));
		clock.wake_up();
	}
}

// v1 Step 8: Physical = (0.5 sqrt(w) + 0.3 sqrt(fitness) + 0.2 sqrt(strength))^2 x (0.4 + 0.6 Q)
// x (1 - 0.5 U) x (1 - 0.3 O).
function test_physical_formula() {
	gs.weight_z = 0;
	gs.fitness = 0.81;
	gs.strength = 0.64;
	gs.diet_quality = 1;
	gs.deficit_u = 0;
	gs.overreach = 0;
	const body = Math.pow(0.5 * 1 + 0.3 * 0.9 + 0.2 * 0.8, 2);
	t.check("a healthy body with Q 1: Physical = the body mix", Math.abs(health_model.physical() - body) < TOLERANCE);
	gs.diet_quality = 0;
	t.check("fast food at every meal (Q 0): Physical x 0.4", Math.abs(health_model.physical() - body * 0.4) < TOLERANCE);
	gs.diet_quality = 1;
	gs.deficit_u = 1;
	gs.overreach = 1;
	t.check("full deficit and overreaching: Physical x 0.5 x 0.7", Math.abs(health_model.physical() - body * 0.35) < TOLERANCE);
	gs.deficit_u = 0;
	gs.overreach = 0;
}

// Failure (no death): target health below 1.3 for 24 avatar hours (decision 10), or happiness
// below 0.10 for 12 avatar hours. Only a placeholder message is shown.
function test_failure() {
	// A short message from the days above ends after a few real seconds; none pass here.
	main._end_flash();
	t.check("there is no death", config.get_value("health.death_enabled") === false);
	gs.physical = 0;
	gs.sleep = 0;
	gs.happiness = 0.5;
	gs.health = 3;
	gs.health_low_hours = 0;
	gs.happiness_low_hours = 0;
	health_model.step(23, false);
	gs.changed.emit();
	t.check("target health below 1.3 for 23 h is not failure yet", gs.target_health < 1.3
		&& !gs.is_at_failure() && main.speech_label.text !== main.tr(FAILURE_TEXTS.health));
	health_model.step(1, false);
	gs.changed.emit();
	t.check("target health below 1.3 for 24 h is failure, even with the bar at 3", gs.is_at_failure());
	t.check("the failure message is shown", main.speech_label.text === main.tr(FAILURE_TEXTS.health));
	gs.physical = 0.5;
	gs.sleep = 0.5;
	health_model.step(1 / 12, false);
	gs.changed.emit();
	t.check("failure is final: it stays when health rises again (user, 7 Nov 2026)", gs.is_at_failure()
		&& gs.failure_cause() === "health" && main.speech_label.text === main.tr(FAILURE_TEXTS.health));
	gs.failed_cause = "";
	gs.happiness = 0.05;
	health_model.step(12, false);
	t.check("happiness below 0.10 for 12 h is failure too", gs.is_at_failure() && gs.failure_cause() === "happiness");
	gs.failed_cause = "";
	gs.happiness = 0.5;
	health_model.step(1 / 12, false);
	main.failure_screen.hide();
}

// v1 avatar images and the physical values box.
function test_states_and_values() {
	gs.weight_z = 1.5;
	gs.strength = 0.75;
	gs.happiness = 0.2;
	let states = states_script.current();
	t.check("z +1.5: overweight; strength 0.75: muscular (muscular with fat); happiness 0.2: sad",
		states.overweight && states.muscular && states.sad && !states.thin);
	gs.weight_z = -2.5;
	gs.strength = 0.4;
	gs.happiness = 0.8;
	states = states_script.current();
	t.check("z -2.5: thin, not muscular, not sad", states.thin && !states.overweight && !states.muscular && !states.sad);
	gs.changed.emit();
	t.check("the avatar draws these states", same(main.avatar.states, states));
	t.check("the physical box shows weight, height, BMI-for-age z and diet quality as numbers",
		main.weight_label.text.includes("kg") && main.height_label.text.includes("cm")
		&& main.bmi_label.text.includes("z") && main.diet_label.text.includes("Diet quality"));
	t.check("z -2.5: no danger warning on the health bar", main.health_label.text !== DANGER_TEXT && !states.ill);
	// Milestone 10.5: the danger state of severe thinness (z below -3).
	gs.weight_z = -3.5;
	gs.changed.emit();
	states = states_script.current();
	t.check("z -3.5: thin and ill, and the avatar draws it", states.thin && states.ill && same(main.avatar.states, states));
	t.check("...and the health bar warns", main.health_label.text === DANGER_TEXT && main.health_bar.theme_type_variation === DANGER_BAR_STYLE);
	gs.weight_z = -2.5;
	gs.changed.emit();
	t.check("z back at -2.5: the warning goes away", main.health_label.text !== DANGER_TEXT
		&& main.health_bar.theme_type_variation === HEALTH_BAR_STYLE);
}

function same(a, b) {
	return JSON.stringify(Object.entries(a).sort()) === JSON.stringify(Object.entries(b).sort());
}
