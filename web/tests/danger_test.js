// Tests for the danger state of severe thinness (Milestone 10.5, Task 3; team review of 27 Oct
// 2026 and decision 11). Run from the project folder:  node web/tests/danger_test.js
// Below BMI-for-age z fail.danger_z (-3, WHO severe thinness) the avatar is in a danger state:
// it looks thin and ill and the health bar warns. The state ends only when z is back at -3 or
// above. Failure when it lasts fail.danger_hours (72 avatar hours) or when z reaches
// fail.danger_failure_z (-4). The risk index gets a thinness term that mirrors the obesity
// term. Nothing is saved.
import {setup, Checks} from "./harness.js";
import {Config} from "../js/core/config.js";
import {GameState as gs} from "../js/core/game_state.js";
import {SaveGame} from "../js/core/save_game.js";
import {HealthModel as health_model} from "../js/health/health_model.js";
import {Risk as risk} from "../js/health/risk.js";
import {AvatarStates as avatar_states} from "../js/health/avatar_states.js";
import {is_zero_approx, roundf} from "../js/core/util.js";

const TOLERANCE = 0.0001;
setup();
const t = new Checks();
SaveGame.save_key = "test_save";
SaveGame.auto_save_enabled = false;

// The danger state starts below -3 and ends only when z is back at -3 or above (decision 11).
{
	const line = Config.get_float("fail.danger_z");
	new_avatar();
	t.check("a new Normal avatar (z +1.2) is not in danger", !health_model.in_danger() && is_zero_approx(gs.danger_hours));
	gs.weight_z = line + 0.1;
	steps(5);
	let states = avatar_states.current();
	t.check("z -2.9: thin, but not in danger and not ill", states.thin && !states.ill && is_zero_approx(gs.danger_hours));
	gs.weight_z = line - 0.1;
	steps(10);
	states = avatar_states.current();
	t.check("z -3.1: in danger, thin and ill", health_model.in_danger() && states.thin && states.ill);
	t.check("...and the danger hours count up (10 h)", Math.abs(gs.danger_hours - 10) < TOLERANCE);
	gs.weight_z = line - 0.05;
	steps(1);
	t.check("gaining weight but still below -3: the danger state goes on (11 h)", Math.abs(gs.danger_hours - 11) < TOLERANCE);
	gs.weight_z = line;
	steps(1);
	t.check("back at z -3: the danger state ends", !health_model.in_danger() && is_zero_approx(gs.danger_hours) && !avatar_states.current().ill);
}

// Failure after 72 hours in danger, or at once when z reaches -4.
{
	const hours = Config.get_float("fail.danger_hours");
	new_avatar();
	gs.weight_z = Config.get_float("fail.danger_z") - 0.5;
	steps(hours - 1);
	t.check("71 hours in danger: no failure yet", !gs.is_at_failure() && health_model.failure_cause() === "");
	steps(1);
	t.check("72 hours in danger: failure, because of severe thinness", gs.is_at_failure() && health_model.failure_cause() === "thinness");
	gs.weight_z = Config.get_float("fail.danger_z") + 0.1;
	steps(1);
	t.check("z back above -3: the danger state ends, the failure stays (it is final; user, 7 Nov 2026)",
			gs.is_at_failure() && gs.failure_cause() === "thinness" && is_zero_approx(gs.danger_hours));
	new_avatar();
	gs.weight_z = Config.get_float("fail.danger_failure_z");
	steps(1);
	t.check("z -4: failure at once (1 hour in danger)", gs.is_at_failure() && health_model.failure_cause() === "thinness");
	new_avatar();
	t.check("a new avatar has no failure cause", health_model.failure_cause() === "");
}

// R gets thin_weight x clamp((thin_from - z) / thin_range): 0 at z -2, 0.2 at -3, 0.4 at -4
// and below. The obesity term still starts at z +1.
{
	new_avatar();
	const at = (z) => {
		gs.weight_z = z;
		return risk.index();
	};
	const base = at(-2);
	t.check("no thinness risk at z -2 or above (z 0 gives the same R)", Math.abs(at(0) - base) < TOLERANCE);
	t.check("z -3: +0.20", Math.abs(at(-3) - base - 0.2) < TOLERANCE);
	t.check("z -4: +0.40 (the full thinness weight)", Math.abs(at(-4) - base - Config.get_float("risk.thin_weight")) < TOLERANCE);
	t.check("z -5: still +0.40 (clamped)", Math.abs(at(-5) - base - 0.4) < TOLERANCE);
	t.check("the obesity term mirrors it: z +3 adds 0.40 over z +1", Math.abs(at(3) - at(1) - 0.4) < TOLERANCE);
}
t.finish();

// Runs the failure timers for this many avatar hours, in 1-hour steps (z is set by the test).
function steps(hours) {
	for (let i = 0; i < roundf(hours); i++) health_model.step(1, false);
}

function new_avatar() {
	gs.reset();
	gs.start_new_avatar("Test", "child", "male", "normal");
}
