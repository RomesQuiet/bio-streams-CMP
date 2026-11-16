// Debug panel (Milestone 3 Task 7; Milestone 10 Task 11: every v1 state). Only exists with ?debug
// in the address (the Godot version: only in debug builds). Shows food, body, training, sleep,
// diet, happiness, measures, target and displayed health. F7 shows or hides it.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Minigame} from "../core/minigame.js";
import {Activities} from "../core/activities.js";
import {Habits} from "../core/habits.js";
import {HealthLog} from "../core/health_log.js";
import {Debug} from "../core/debug.js";
import {format} from "../core/util.js";
import {Hunger} from "../health/hunger.js";
import {Energy} from "../health/energy.js";
import {BodySize} from "../health/body_size.js";
import {Training} from "../health/training.js";
import {SleepModel} from "../health/sleep_model.js";
import {Happiness} from "../health/happiness.js";
import {AvatarStates} from "../health/avatar_states.js";
import {HealthModel} from "../health/health_model.js";
import {Control, Label} from "./widgets.js";

export class DebugPanel extends Control {
	constructor(parent) {
		super(parent, "debug-panel");
		this.info = new Label(this, "DEBUG");
		this.visible = false;
		if (!Debug.allowed()) {
			this.node.remove();
			return;
		}
		this._refresh_fn = () => this._refresh();
		GameState.changed.connect(this._refresh_fn);
		Habits.day_closed.connect(this._refresh_fn);
		this._refresh();
	}

	// The screen closed: stop listening.
	release() {
		if (!this._refresh_fn) return;
		GameState.changed.disconnect(this._refresh_fn);
		Habits.day_closed.disconnect(this._refresh_fn);
	}

	_key_pressed(key, event) {
		if (key === "F7" && event?.shiftKey && this._refresh_fn) {
			// The Godot version wrote the log to a file; in a browser it is downloaded.
			download_text("health_log.csv", HealthLog.text());
			return;
		}
		if (key === "F7" && this._refresh_fn) {
			this.visible = !this.visible;
			this._refresh();
		}
	}

	_refresh() {
		if (!this.visible) return;
		const gs = GameState;
		const lines = [];
		const f = format;
		lines.push(f("DEBUG (F7)  %s, %s, %s", [gs.difficulty, gs.age_group, gs.sex]));
		const portion = Hunger.healthy_portion_kcal();
		lines.push(f("Food  hunger %.0f kcal (%.2f healthy meals of %.0f)  %s", [gs.hunger, gs.hunger / portion, portion,
			Hunger.is_hungry() ? "HUNGRY" : "not hungry"]));
		lines.push(f("  %.1f h since the last meal  weight %.1f kg  body age %.1f y  METy %.2f", [gs.hours_since_meal,
			gs.weight_kg, gs.body_age_months / Config.get_float("units.months_per_year"), Energy.mety_now()]));
		lines.push(f("  height %.1f cm  BMI-for-age z %+.2f (weight score %.2f)  energy deficit U %.2f", [
			gs.height_m * Config.get_float("units.cm_per_m"), gs.weight_z, BodySize.weight_score(gs.weight_z), gs.deficit_u]));
		lines.push(f("  last 24 h: eaten %.0f kcal, spent %.0f kcal", [Energy.window_total("eaten"), Energy.window_total("spent")]));
		lines.push("Body states");
		lines.push(f("  fitness %.3f  strength %.3f  overreaching O %.2f  capacity %.0f min (%.0f used today)", [gs.fitness,
			gs.strength, gs.overreach, Training.capacity_min(), gs.exercise_minutes_today]));
		lines.push(f("  recovery: cardio %.2f  strength %.2f  last strength start %.1f h ago (gap %.0f h)", [gs.cardio_recovery,
			gs.strength_recovery, gs.hours_since_strength, Config.get_float("train.strength_min_gap_h")]));
		if (Minigame.running) {
			const doing = Minigame.waiting ? "waiting" : Minigame.walking ? "walking" : Minigame.resting ? "resting" : Minigame.kind;
			lines.push(f("  minigame: score %.2f (rhythm %.2f, pace %.2f)  reserve %.2f  interval %.2f s  %s", [Minigame.score(),
				Minigame.rhythm, Minigame.pace, Minigame.reserve, Minigame.interval(), doing]));
		}
		lines.push(f("  sleep debt %.2f h  tiredness %.2f  %.1f h awake  last sleep %.1f h (night quality %.2f)", [gs.sleep_debt,
			SleepModel.tiredness(), gs.hours_awake, gs.last_sleep_hours, gs.night_quality]));
		lines.push(f("  calories spent while exercising (record) %.0f kcal%s", [gs.calories_spent,
			gs.strength_too_soon && Activities.is_running() ? "  strength session started too soon" : ""]));
		lines.push(f("Diet  quality Q %.2f  craving C %.2f  habituation A %.2f", [gs.diet_quality, gs.craving, gs.habituation]));
		lines.push(f("Happiness %.3f -> baseline %.3f  fun %.2f  screen excess %.2f", [gs.happiness, gs.happiness_baseline,
			Happiness.fun(), Happiness.screen_excess()]));
		lines.push("Measures");
		lines.push(f("  physical %.3f  happiness %.3f  sleep %.3f", [gs.physical, gs.happiness, gs.sleep]));
		lines.push(f("Health target %.2f  displayed %.2f (level %d)", [gs.target_health, gs.health, gs.health_level]));
		lines.push(f("Failure timers: target health below line %.1f h, happiness below line %.1f h, danger (z below %.0f) %.1f h%s", [
			gs.health_low_hours, gs.happiness_low_hours, Config.get_float("fail.danger_z"), gs.danger_hours,
			gs.is_at_failure() ? f("  FAILURE (%s)", [HealthModel.failure_cause()]) : ""]));
		lines.push(f("Risk index R %.2f  hidden damage %.3f (no disease stages yet)", [gs.risk_index, gs.disease_damage]));
		const states = AvatarStates.current();
		lines.push("Avatar states: " + Object.keys(states).filter((k) => states[k]).join(", "));
		lines.push(f("Scoring day %d  log entries %d  XP %.1f", [Habits.current_day, Habits.entries.length, gs.xp]));
		lines.push("CSV log: " + (HealthLog.enabled ? HealthLog.log_path + " (localStorage; Shift+F7 downloads it)" : "off"));
		this.info.text = lines.join("\n");
	}
}

// Gives the browser a text file to save.
export function download_text(file_name, text, type = "text/csv") {
	const link = document.createElement("a");
	link.href = URL.createObjectURL(new Blob([text], {type}));
	link.download = file_name;
	link.click();
	setTimeout(() => URL.revokeObjectURL(link.href), 1000);
}
