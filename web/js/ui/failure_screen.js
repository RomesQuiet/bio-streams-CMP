// The failure screen (user, 7 Nov 2026). There is no death, only failure, and it is final: the
// player starts again with a new avatar (concept). It shows a short phrase for the cause, and
// Details, drawn rather than written (user): the cause in exact words, tiles for the avatar's
// life and body, bars for its last measures, and a gauge for each habit over the last days with
// the recommended zone in green: facts, not advice (concept, "Learning approach"). Every text is
// a translation key; the numbers come from Config and GameState.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Clock} from "../core/clock.js";
import {Habits} from "../core/habits.js";
import {Settings} from "../core/settings.js";
import {tr} from "../core/translation.js";
import {Signal, format, is_equal_approx, roundf} from "../core/util.js";
import {Hunger} from "../health/hunger.js";
import {AvatarStates} from "../health/avatar_states.js";
import {Control, Panel, Box, Label, Button, ProgressBar} from "./widgets.js";
import {AvatarView} from "./avatar_view.js";
import {RequestIcon} from "./request_icon.js";
import {HabitGauge} from "./habit_gauge.js";

// How far each gauge reaches: sleep in hours, activity and screens as multiples of the
// recommendation (display only; the scale grows if the avatar went past it).
const SLEEP_SCALE_H = 14;
const ACTIVITY_SCALE = 2;
const SCREENS_SCALE = 3;
const CAPTION_COLOR = "rgb(191, 196, 209)";
const PHRASES = {
	thinness: "FAILURE_PHRASE_THINNESS",
	health: "FAILURE_PHRASE_HEALTH",
	happiness: "FAILURE_PHRASE_HAPPINESS",
};

export class FailureScreen extends Control {
	constructor(parent = null) {
		super(parent, "overlay failure-overlay");
		this.restart_pressed = new Signal();
		const panel = new Panel(this, "failure-panel");
		const content = new Box(panel, "failure-content", true, 16);
		new Label(content, "FAILURE_TITLE", "failure-title center");
		this.avatar = new AvatarView(content, "failure-avatar", {x: 165, y: 225});
		this.phrase_label = new Label(content, "", "failure-phrase center wrap");
		new Label(content, "FAILURE_END", "failure-end center wrap");
		this.details_box = new Control(content, "failure-details-box");
		this.details_box.visible = false;
		this.details = new Box(this.details_box, "failure-details", true, 10);
		// The gauges of the last Details built, by habit (for tests).
		this.gauges = {};
		const buttons = new Box(content, "failure-buttons", false, 16);
		this.details_button = new Button(buttons, "UI_DETAILS", "grow tall");
		const restart = new Button(buttons, "SETTINGS_NEW_AVATAR", "grow tall");
		this.details_button.pressed.connect(() => this._toggle_details());
		restart.pressed.connect(() => this.restart_pressed.emit());
		this.visible = false;
	}

	_translation_changed() {
		if (this.visible) this._write();
	}

	// Shows the screen for the saved failure, with Details closed.
	open() {
		this.details_box.visible = false;
		const states = AvatarStates.current();
		states.sad = true;
		states.happy = false;
		this.avatar.states = states;
		this.avatar.sheet = `${GameState.age_group}_${GameState.sex}`;
		this._write();
		this.show();
	}

	_toggle_details() {
		this.details_box.visible = !this.details_box.visible;
		this._write();
	}

	_write() {
		const cause = GameState.failure_cause();
		this.phrase_label.text = format(tr(PHRASES[cause] ?? "FAILURE_PHRASE_HEALTH"), [GameState.avatar_name]);
		this.details_button.text = tr(this.details_box.visible ? "UI_HIDE_DETAILS" : "UI_DETAILS");
		this._build_details(cause);
	}

	// Details: what happened, the life and body as tiles, the last measures as bars and each
	// habit as a gauge. Built again when it opens or the language changes.
	_build_details(cause) {
		this.details.clear_children();
		this.gauges = {};
		const gs = GameState;
		this._heading("FAILURE_WHAT_HAPPENED");
		this._caption(this.cause_text(cause), 20, "white");
		this._heading(format(tr("FAILURE_LIFE_TITLE"), [gs.avatar_name]));
		this._tiles([[Settings.number(gs.failed_day, 1), "FAILURE_TILE_DAYS"], [String(gs.level), "FAILURE_TILE_LEVEL"],
			[Settings.number(gs.best_health, 1), "FAILURE_TILE_BEST"]]);
		this._tiles([[Settings.number(gs.weight_kg, 1) + " kg", "FAILURE_TILE_WEIGHT"],
			[Settings.number(gs.weight_z, 2, true), "FAILURE_TILE_Z"], [Settings.number(gs.health, 1), "FAILURE_TILE_HEALTH"]]);
		// A short verdict where a value needs one (user, 7 Nov 2026: "just say too thin, too something").
		this._caption(this.z_explanation(gs.weight_z), 18, CAPTION_COLOR);
		this._heading("FAILURE_END_TITLE");
		for (const [key, amount] of [["MEASURE_PHYSICAL", gs.physical], ["MEASURE_HAPPINESS", gs.happiness], ["MEASURE_SLEEP", gs.sleep]]) {
			this._measure(key, amount);
			this._caption(this.measure_explanation(key, amount), 18, CAPTION_COLOR);
		}
		const habits = habit_numbers();
		if (habits.days <= 0) return;
		const days = habits.days;
		this._heading(format(tr("FAILURE_HABITS_TITLE"), [Settings.number(days, is_equal_approx(days, roundf(days)) ? 0 : 1)]));
		const group = gs.age_group !== "" ? gs.age_group : "child";
		const sleep_min = Config.get_float(`sleep.${group}_min_h`);
		const sleep_max = Config.get_float(`sleep.${group}_max_h`);
		this._habit("sleep", "tired", "FAILURE_HABIT_SLEEP", format(tr("FAILURE_HOURS_A_DAY"), [Settings.number(habits.sleep_h, 1)]),
			format(tr("FAILURE_RECOMMENDED_RANGE"), [Settings.number(sleep_min, 0), Settings.number(sleep_max, 0)]),
			habits.sleep_h, sleep_min, sleep_max, SLEEP_SCALE_H);
		const activity_min = Config.get_float("failure_screen.activity_min_per_day");
		this._habit("activity", "football", "FAILURE_HABIT_ACTIVITY", format(tr("FAILURE_MINUTES_A_DAY"), [roundf(habits.activity_min)]),
			format(tr("FAILURE_RECOMMENDED_AT_LEAST"), [roundf(activity_min)]), habits.activity_min, activity_min, -1,
			activity_min * ACTIVITY_SCALE);
		const screens_max = Config.get_float("mood.fun.screen_max_min") / Clock.MINUTES_PER_HOUR;
		this._habit("screens", "screens", "FAILURE_HABIT_SCREENS", format(tr("FAILURE_HOURS_A_DAY"), [Settings.number(habits.screen_h, 1)]),
			format(tr("FAILURE_RECOMMENDED_AT_MOST"), [Settings.number(screens_max, 0)]), habits.screen_h, 0, screens_max,
			screens_max * SCREENS_SCALE);
		const meals = habits.meals;
		const fast = roundf(habits.fast_food_share * meals);
		const gauge = this._habit("meals", "hungry", "FAILURE_HABIT_MEALS", format(tr("FAILURE_MEALS_COUNT"), [meals - fast, fast]), "",
			0, 0, -1, 1);
		gauge.split = true;
		gauge.healthy = meals - fast;
		gauge.fast_food = fast;
	}

	_heading(key) {
		new Label(this.details, tr(key), "size-24");
	}

	_caption(text, font_size, color) {
		const label = new Label(this.details, text, `wrap size-${font_size}`);
		label.color = color;
		return label;
	}

	// A row of tiles in the style of the level boxes: a large number over a small name.
	_tiles(items) {
		const row = new Box(this.details, "tiles", false, 12);
		for (const [number, key] of items) {
			const tile = new Box(row, "level-box tile grow", true, 0);
			new Label(tile, number, "level-label center size-30");
			new Label(tile, tr(key), "level-label center size-16");
		}
	}

	// BMI-for-age z in a few words: its WHO 2007 band (the same cut-offs as the game).
	z_explanation(z) {
		let band = "FAILURE_EXPLAIN_Z_HEALTHY";
		if (z < Config.get_float("fail.danger_z")) band = "FAILURE_EXPLAIN_Z_SEVERE_THIN";
		else if (z < Config.get_float("avatar_states.thin_below_z")) band = "FAILURE_EXPLAIN_Z_THIN";
		else if (z > Config.get_float("avatar_states.obese_above_z")) band = "FAILURE_EXPLAIN_Z_OBESE";
		else if (z > Config.get_float("avatar_states.overweight_above_z")) band = "FAILURE_EXPLAIN_Z_OVER";
		return format(tr("FAILURE_EXPLAIN_Z"), [tr(band)]);
	}

	// Physical, Happiness or Sleep in a few words: too low, could be better or good
	// (failure_screen.measure_low_below and measure_good_from).
	measure_explanation(_key, amount) {
		let band = "FAILURE_EXPLAIN_MIDDLE";
		if (amount < Config.get_float("failure_screen.measure_low_below")) band = "FAILURE_EXPLAIN_LOW";
		else if (amount >= Config.get_float("failure_screen.measure_good_from")) band = "FAILURE_EXPLAIN_GOOD";
		return tr(band);
	}

	// A measure's name and its bar, as in the measures panel.
	_measure(key, amount) {
		const row = new Box(this.details, "measure-row", false, 4);
		new Label(row, tr(key), "size-20 measure-name");
		const bar = new ProgressBar(row, "grow measure-bar");
		bar.value = amount;
	}

	// A habit: its picture, name and value, the gauge, and the recommendation under it.
	_habit(id, icon, name_key, value_text, recommended, amount, zone_from, zone_to, scale_max) {
		const row = new Box(this.details, "habit-row", false, 10);
		const picture = new RequestIcon(row);
		picture.default_size = {x: 40, y: 40};
		picture.set_class("small-icon", true);
		picture.kind = icon;
		new Label(row, tr(name_key), "grow size-20");
		new Label(row, value_text, "size-20");
		const gauge = new HabitGauge(this.details);
		gauge.value = amount;
		gauge.zone_from = zone_from;
		gauge.zone_to = zone_to;
		gauge.scale_max = Math.max(scale_max, amount * 1.1);
		this.gauges[id] = gauge;
		if (recommended !== "") this._caption(recommended, 16, CAPTION_COLOR);
		return gauge;
	}

	cause_text(cause) {
		if (cause === "thinness") {
			return format(tr("FAILURE_CAUSE_THINNESS"), [Settings.number(Config.get_float("fail.danger_z"), 0, true),
				roundf(Config.get_float("fail.danger_hours")), Settings.number(Config.get_float("fail.danger_failure_z"), 0, true),
				Settings.number(GameState.weight_z, 2, true)]);
		}
		if (cause === "happiness") {
			return format(tr("FAILURE_CAUSE_HAPPINESS"), [Settings.number(Config.get_float("fail.happiness_line"), 2),
				roundf(Config.get_float("fail.happiness_hours"))]);
		}
		return format(tr("FAILURE_CAUSE_HEALTH"), [Settings.number(Config.get_float("fail.health_line"), 1),
			roundf(Config.get_float("fail.health_hours"))]);
	}

	habit_numbers() {
		return habit_numbers();
	}
}

// The avatar's habits over the last failure_screen.summary_days avatar days (fewer if it lived
// less), from the action log: hours slept, minutes of moderate-to-vigorous activity and hours of
// screens a day, and the meals and the share that were fast food.
export function habit_numbers() {
	const hours_per_day = Config.get_float("units.hours_per_day");
	const window = Math.min(Config.get_float("failure_screen.summary_days") * hours_per_day, Habits.avatar_hours_total);
	const result = {days: window / hours_per_day, sleep_h: 0, activity_min: 0, screen_h: 0, meals: 0, fast_food_share: 0};
	if (window <= 0) return result;
	let fast_food = 0;
	for (const entry of Habits.entries) {
		if (Number(entry.start_total) < Habits.avatar_hours_total - window) continue;
		const type = entry.type;
		const hours = Number(entry.hours);
		if (Config.get_value("log.sleep_types").includes(type)) result.sleep_h += hours;
		if (Config.get_value("log.activity_intensities").includes(entry.intensity)) result.activity_min += hours * Clock.MINUTES_PER_HOUR;
		if (Config.get_value("log.screen_types").includes(type)) result.screen_h += hours;
		if (Hunger.is_food(type) && hours > 0) {
			result.meals += 1;
			if (Hunger.food_value(type, "healthy") < 1) fast_food += 1;
		}
	}
	// Per day; an avatar that lived less than a day shows that day's totals.
	for (const key of ["sleep_h", "activity_min", "screen_h"]) result[key] /= Math.max(result.days, 1);
	if (result.meals > 0) result.fast_food_share = fast_food / result.meals;
	return result;
}
