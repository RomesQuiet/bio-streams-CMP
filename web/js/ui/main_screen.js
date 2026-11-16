// Main game screen. Shows GameState, Clock and Activities on screen and handles the buttons.
// Eat opens the meals (Milestone 10, Task 3) and, when the avatar is hungry, Skip meal.
// Built like scenes/main.tscn of the Godot version: the layout is in style.css.
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Clock} from "../core/clock.js";
import {Activities} from "../core/activities.js";
import {Minigame} from "../core/minigame.js";
import {Simulation} from "../core/simulation.js";
import {Settings} from "../core/settings.js";
import {SaveGame} from "../core/save_game.js";
import {tr} from "../core/translation.js";
import {format, roundf} from "../core/util.js";
import {Vector2} from "../core/vector2.js";
import {Hunger} from "../health/hunger.js";
import {AvatarStates} from "../health/avatar_states.js";
import {HealthModel} from "../health/health_model.js";
import {Training} from "../health/training.js";
import {Requests} from "../health/requests.js";
import {Scene, call_deferred, create_timer, create_tween, Ease} from "./scene.js";
import {Control, Label, Button, ProgressBar, HSlider, Panel, Box, css, Assets} from "./widgets.js";
import {Input} from "./input.js";
import {AvatarView} from "./avatar_view.js";
import {Scenery} from "./scenery.js";
import {RequestIcon} from "./request_icon.js";
import {BeatBar} from "./beat_bar.js";
import {MealFork} from "./meal_fork.js";
import {FootballField} from "./football_field.js";
import {FootballPad} from "./football_pad.js";
import {FootballHelp} from "./football_help.js";
import {FailureScreen} from "./failure_screen.js";
import {DebugPanel} from "./debug_panel.js";

const CREATION_SCENE = "creation";
const MENU_SCENE = "menu";
// Height of the minigame panel, and of the football controls on a touch screen and on a computer.
const MINIGAME_PANEL_HEIGHT = 256;
const FOOTBALL_PAD_TOUCH = 170;
const FOOTBALL_PAD_KEYS = 104;
// The food on the fork in the meal minigame.
const MEAL_HEALTHY_COLOR = [0.4, 0.75, 0.35];
const MEAL_FAST_FOOD_COLOR = [0.85, 0.55, 0.25];
// Placeholder failure messages by cause (HealthModel.failure_cause()). Translation keys, like
// every text on this screen.
export const FAILURE_TEXTS = {
	thinness: "FAILURE_THINNESS",
	health: "FAILURE_HEALTH",
	happiness: "FAILURE_HAPPINESS",
};
// Placeholder health bar warning in the danger state of severe thinness (Milestone 10.5).
export const DANGER_TEXT = "MEASURE_HEALTH_DANGER";
export const HEALTH_TEXT = "MEASURE_HEALTH";
// The health bar's fill: green, or red in the danger state (style.css: .bar-health, .bar-danger).
export const HEALTH_BAR_STYLE = "health";
export const DANGER_BAR_STYLE = "danger";

export class MainScreen {
	constructor(root) {
		// Sky colours. The sky follows the clock (daylight hours in config), not whether the
		// avatar is awake or asleep.
		this.day_sky_color = [0.3, 0.45, 0.62];
		this.night_sky_color = [0.06, 0.07, 0.14];
		// An activity without a "scenery" (data/activities.json) shows its background colour
		// behind the avatar, see-through, so day or night stays visible.
		this.activity_backdrop_alpha = 0.6;
		this.backdrop_fade_seconds = 0.8;
		// How long the "Level up!" message stays in the speech bubble (real seconds).
		this.level_up_message_seconds = 3;
		// XP changes shown over the XP bar (user, 7 Nov 2026): added up and shown at most once per
		// xp_change_seconds (real seconds), as a whole number, rising and fading.
		this.xp_change_seconds = 1.5;
		this.xp_change_rise = 24;
		this.xp_gain_color = "rgb(140, 255, 140)";
		this.xp_loss_color = "rgb(255, 128, 115)";
		// Buttons are black at night (style.css: .night).
		this.night = false;

		this._backdrop_tween = null;
		// XP gained or lost and not shown yet, and the change being shown.
		this._xp_pending = 0;
		this._xp_tween = null;
		this._scenery_tween = null;
		// A short message (such as "Level up!") shown instead of the normal speech for a moment:
		// its translation key and the values for its format.
		this._flash_key = "";
		this._flash_args = [];
		// The activity whose options are in the options panel.
		this._options_activity = "";
		// Whether opening the settings paused the day, so closing them starts it again.
		this._paused_by_settings = false;
		// The joystick's direction, on screen.
		this._pad_stick = Vector2.ZERO;
		this._connections = [];
		this._build(root);
	}

	// The widgets, as in scenes/main.tscn.
	_build(root) {
		const main = new Control(root, "screen main-screen");
		this.node = main.node;
		// The screen hears the language change (retranslate() in scene.js).
		main.node._widget = this;
		this.main = main;
		this.sky = main.node;
		const margin = new Control(main, "main-margin");
		const stage = new Control(margin, "stage");
		this.stage = stage;
		this.activity_backdrop = new Control(stage, "activity-backdrop");
		this.activity_backdrop.alpha = 0;
		this.scenery = new Scenery(stage, "fill");
		this.scenery.alpha = 0;
		new Control(stage, "ground");
		this.avatar = new AvatarView(stage, "stage-avatar");
		// The bedroom's blanket, in front of the avatar.
		this.blanket = new Scenery(stage, "fill", true);
		this.blanket.alpha = 0;
		this.football_field = new FootballField(stage);
		this.football_field.set_class("fill", true);
		this.football_field.visible = false;
		this.meal_fork = new MealFork(stage);
		this.meal_fork.set_class("fill", true);
		this.meal_fork.visible = false;
		this.speech_bubble = new Panel(stage, "speech-bubble");
		const speech_row = new Box(this.speech_bubble, "speech-row", false, 8);
		this.request_icon = new RequestIcon(speech_row);
		this.speech_label = new Label(speech_row, "", "speech-label wrap center");

		const stop_slot = new Control(margin, "stop-slot");
		this.stop_button = new Button(stop_slot, "UI_STOP", "fill");
		this.stop_button.visible = false;

		this.action_grid = new Control(margin, "action-grid");
		this.exercise_button = new Button(this.action_grid, "UI_EXERCISE", "action");
		this.sleep_button = new Button(this.action_grid, "UI_SLEEP", "action");
		this.eat_button = new Button(this.action_grid, "UI_EAT", "action");
		this.entertainment_button = new Button(this.action_grid, "UI_ENTERTAINMENT", "action");
		this.action_buttons = [this.exercise_button, this.sleep_button, this.eat_button, this.entertainment_button];

		this.minigame_panel = new Box(margin, "minigame-panel", true, 8);
		this.minigame_panel.visible = false;
		const info_row = new Box(this.minigame_panel, "info-row", false, 4);
		this.minigame_status = new Label(info_row, "", "size-22 grow");
		this.help_button = new Button(info_row, "?", "help-button");
		this.help_button.visible = false;
		this.minigame_steps = new Label(info_row, "", "size-22");
		this.reserve_row = new Box(this.minigame_panel, "reserve-row", false, 12);
		this.reserve_label = new Label(this.reserve_row, "", "size-22");
		this.reserve_bar = new ProgressBar(this.reserve_row, "grow reserve-bar");
		this.beat_bar = new BeatBar(this.minigame_panel);
		this.tap_button = new Button(this.minigame_panel, "MINIGAME_TAP", "big grow");
		this.football_pad = new FootballPad(this.minigame_panel);
		this.football_pad.set_class("grow", true);
		this.football_pad.visible = false;
		this.meal_buttons = new Box(this.minigame_panel, "grow", false, 16);
		this.meal_buttons.visible = false;
		this.bite_button = new Button(this.meal_buttons, "MINIGAME_BITE", "big grow-2");
		this.done_button = new Button(this.meal_buttons, "MINIGAME_DONE", "big grow");
		this.strength_buttons = new Box(this.minigame_panel, "grow", false, 16);
		this.strength_buttons.visible = false;
		this.down_button = new Button(this.strength_buttons, "MINIGAME_DOWN", "big grow");
		this.up_button = new Button(this.strength_buttons, "MINIGAME_UP", "big grow");

		// The top bar.
		this.health_level_button = new Button(main, "4", "health-level");
		this.health_level_button.tooltip = "UI_HEALTH_LEVEL_TIP";
		this.health_bar_button = new Button(main, "", "flat health-bar-button");
		this.health_bar_button.tooltip = "UI_HEALTH_BAR_TIP";
		this.health_bar = new ProgressBar(this.health_bar_button, "fill", Config.get_float("measures.health_min"),
			Config.get_float("measures.health_max"));
		this.health_bar.theme_type_variation = HEALTH_BAR_STYLE;
		this.health_label = new Label(this.health_bar_button, HEALTH_TEXT, "fill bar-text center");
		this.xp_bar = new ProgressBar(main, "xp-bar");
		this.xp_bar.theme_type_variation = "xp";
		this.xp_label = new Label(this.xp_bar, "", "fill bar-text center");
		this.xp_change_label = new Label(this.xp_bar, "", "xp-change center");
		this.xp_change_label.alpha = 0;
		// The label's top, moved by the rising animation (Godot's position.y).
		Object.defineProperty(this.xp_change_label, "position_y", {
			get: () => this._xp_change_y,
			set: (value) => {
				this._xp_change_y = value;
				this.xp_change_label.node.style.top = value + "px";
			},
		});
		this.xp_change_label.position_y = 44;

		const right = new Box(main, "right-column", true, 8);
		this.level_box = new Box(right, "level-box", true, 0);
		this.level_box.tooltip = "UI_XP_LEVEL_TIP";
		this.level_label = new Label(this.level_box, "", "level-label center");
		this.clock_label = new Label(right, "07:00", "clock-label center");
		this.pause_button = new Button(right, "", "icon-button");
		this.pause_button.toggle_mode = true;
		this.pause_button.icon = Assets.url("res://assets/art/ui/pause.svg");
		this.pause_button.tooltip = "UI_PAUSE_TIP";
		this.settings_button = new Button(right, "", "icon-button");
		this.settings_button.icon = Assets.url("res://assets/art/ui/settings.svg");
		this.settings_button.tooltip = "SETTINGS_TITLE";
		this.wake_button = new Button(right, "UI_WAKE", "wake-button");
		this.wake_button.tooltip = "UI_WAKE_TIP";
		this.wake_button.disabled = true;

		// The measures panel and the physical values.
		this.health_panel = new Panel(main, "health-panel");
		const measures = new Box(this.health_panel, "", true, 6);
		new Label(measures, "MEASURE_PHYSICAL", "size-22");
		this.physical_button = new Button(measures, "", "flat measure-button");
		this.physical_button.tooltip = "UI_PHYSICAL_TIP";
		this.physical_bar = new ProgressBar(this.physical_button, "fill");
		new Label(measures, "MEASURE_HAPPINESS", "size-22");
		this.happiness_bar = new ProgressBar(measures, "measure-bar");
		new Label(measures, "MEASURE_SLEEP", "size-22");
		this.sleep_bar = new ProgressBar(measures, "measure-bar");
		this.values_panel = new Panel(main, "values-panel");
		const values = new Box(this.values_panel, "", true, 10);
		const value_label = () => new Label(values, "", "size-20");
		this.calories_label = value_label();
		this.muscle_label = value_label();
		this.fitness_label = value_label();
		this.weight_label = value_label();
		this.height_label = value_label();
		this.bmi_label = value_label();
		this.diet_label = value_label();

		// The options of an activity, with the minutes slider.
		this.options_panel = new Panel(main, "dialog options-panel");
		const options = new Box(this.options_panel, "", true, 16);
		this.options_title = new Label(options, "", "center");
		this.minutes_box = new Box(options, "", true, 4);
		this.minutes_label = new Label(this.minutes_box, "", "center");
		this.minutes_slider = new HSlider(this.minutes_box);
		this.option_buttons = new Box(options, "", true, 12);
		this.options_cancel_button = new Button(options, "UI_CANCEL", "h64");

		// Sleep: a slider for the hours.
		this.sleep_panel = new Panel(main, "dialog sleep-panel");
		const sleep = new Box(this.sleep_panel, "", true, 16);
		new Label(sleep, "UI_SLEEP_QUESTION", "center");
		this.sleep_slider = new HSlider(sleep);
		this.sleep_info_label = new Label(sleep, "", "center wrap");
		const sleep_buttons = new Box(sleep, "", false, 16);
		this.sleep_cancel_button = new Button(sleep_buttons, "UI_CANCEL", "grow h64");
		this.sleep_start_button = new Button(sleep_buttons, "UI_SLEEP", "grow h64");

		// The settings (Milestone 11).
		this.settings_overlay = new Control(main, "overlay settings-overlay");
		const settings = new Box(new Panel(this.settings_overlay, "settings-panel"), "", true, 16);
		new Label(settings, "SETTINGS_TITLE", "center");
		new Label(settings, "SETTINGS_LANGUAGE");
		const languages = new Box(settings, "", false, 16);
		this.portuguese_button = new Button(languages, "Português", "grow h72");
		this.english_button = new Button(languages, "English", "grow h72");
		for (const button of [this.portuguese_button, this.english_button]) button.toggle_mode = true;
		this.new_avatar_button = new Button(settings, "SETTINGS_NEW_AVATAR", "h72");
		this.confirm_box = new Box(settings, "", true, 12);
		this.confirm_box.visible = false;
		new Label(this.confirm_box, "SETTINGS_NEW_AVATAR_WARNING", "center wrap");
		const confirm_buttons = new Box(this.confirm_box, "", false, 16);
		this.confirm_cancel_button = new Button(confirm_buttons, "UI_CANCEL", "grow h72");
		this.confirm_new_avatar_button = new Button(confirm_buttons, "SETTINGS_NEW_AVATAR_CONFIRM", "grow h72");
		this.main_menu_button = new Button(settings, "SETTINGS_MAIN_MENU", "h64");
		this.settings_close_button = new Button(settings, "SETTINGS_CLOSE", "h64");

		this.football_help = new FootballHelp(main);
		this.failure_screen = new FailureScreen(main);
		this.debug_panel = new DebugPanel(main);
	}

	// Connects to an autoload's signal; the connection ends with the screen (Godot disconnects a
	// freed node's signals by itself).
	_listen(signal, fn) {
		signal.connect(fn);
		this._connections.push([signal, fn]);
	}

	_ready() {
		// A new game (no save) starts on the avatar creation screen.
		if (!GameState.is_created()) {
			Scene.change(CREATION_SCENE);
			return;
		}
		this.sleep_slider.min_value = Config.get_float("sleep_activity.slider_min_hours");
		this.sleep_slider.max_value = Config.get_float("time.max_sleep_hours");
		this.sleep_slider.step = Config.get_float("sleep_activity.slider_step_hours");
		this.sleep_slider.value = Config.get_float("sleep_activity.slider_default_hours");
		this.minutes_slider.min_value = Config.get_float("activity_slider.min_minutes");
		this.minutes_slider.max_value = Config.get_float("activity_slider.max_minutes");
		this.minutes_slider.step = Config.get_float("activity_slider.step_minutes");
		this.health_panel.visible = false;
		this.values_panel.visible = false;
		this.sleep_panel.visible = false;
		this.options_panel.visible = false;
		this.settings_overlay.visible = false;

		this.health_level_button.pressed.connect(() => this._toggle_health_panel());
		this.health_bar_button.pressed.connect(() => this._toggle_health_panel());
		this.physical_button.pressed.connect(() => this._toggle_values_panel());
		this.pause_button.pressed.connect(() => Clock.toggle_pause());
		this.settings_button.pressed.connect(() => this._open_settings());
		this.settings_close_button.pressed.connect(() => this._close_settings());
		// One language button is always pressed (Godot's ButtonGroup).
		this.portuguese_button.pressed.connect(() => this._choose_language("pt"));
		this.english_button.pressed.connect(() => this._choose_language("en"));
		this.new_avatar_button.pressed.connect(() => this._show_new_avatar_confirmation(true));
		this.confirm_cancel_button.pressed.connect(() => this._show_new_avatar_confirmation(false));
		this.confirm_new_avatar_button.pressed.connect(() => this._start_new_avatar());
		this.wake_button.pressed.connect(() => Clock.wake_up());
		this.sleep_button.pressed.connect(() => this._on_sleep_button_pressed());
		this.exercise_button.pressed.connect(() => this._open_options("exercise"));
		this.entertainment_button.pressed.connect(() => this._open_options("entertainment"));
		this.eat_button.pressed.connect(() => this._open_options("eat"));
		this.options_cancel_button.pressed.connect(() => this.options_panel.hide());
		this.stop_button.pressed.connect(() => Activities.stop());
		this.sleep_slider.value_changed.connect(() => this._refresh_sleep_info());
		this.minutes_slider.value_changed.connect(() => this._refresh_minutes());
		this.sleep_cancel_button.pressed.connect(() => this.sleep_panel.hide());
		this.sleep_start_button.pressed.connect(() => this._on_sleep_start_pressed());
		this._listen(GameState.changed, () => this._refresh());
		this._listen(GameState.leveled_up, (new_level) => this._on_leveled_up(new_level));
		this._listen(GameState.xp_changed, (amount) => this._on_xp_changed(amount));
		// Failure is final (user, 7 Nov 2026). Shown after the step that reached it has finished.
		this._listen(GameState.failed, () => call_deferred(() => this._show_failure()));
		// After failure, a new avatar in a free place; the failed one stays in the menu's list.
		this.failure_screen.restart_pressed.connect(() => {
			SaveGame.menu_request = "new_avatar";
			this._go_to_menu();
		});
		this.main_menu_button.pressed.connect(() => this._go_to_menu());
		this._listen(Clock.time_changed, () => this._refresh_clock());
		this._listen(Clock.phase_changed, () => this._on_phase_changed());
		this._listen(Clock.paused_changed, () => this._refresh_phase());
		this._listen(Clock.day_started, () => this._refresh_phase());
		this._listen(Activities.started, () => this._refresh_activity());
		this._listen(Activities.ended, () => this._refresh_activity());
		this._listen(Activities.progressed, () => this._refresh_activity_speech());
		this._listen(Activities.started, () => this._warn_if_too_soon());
		this._listen(Activities.started, (_activity_id, option_id) => this._on_meal_started(option_id));
		this._listen(Minigame.first_stride, () => this._on_first_stride());
		this._listen(GameState.wish_refused, (wish) => this._on_wish_refused(wish));
		this.tap_button.button_down.connect(() => Minigame.tap());
		this.down_button.button_down.connect(() => Minigame.press(true));
		this.up_button.button_down.connect(() => Minigame.press(false));
		this._listen(Minigame.strode, () => this._on_stride());
		this._listen(Minigame.session_changed, () => this._on_session_changed());
		this._listen(Minigame.gave_up, () => this._flash("SPEECH_GAVE_UP"));
		this._listen(Minigame.match_ended, (goals_us, goals_them) => this._on_match_ended(goals_us, goals_them));
		this.football_pad.stick_moved.connect((direction) => this._on_pad_stick(direction));
		this.football_pad.pass_pressed.connect(() => Minigame.pass_ball());
		this.football_pad.shoot_pressed.connect(() => Minigame.shoot_or_tackle());
		this.football_pad.touch_seen.connect(() => this._refresh_minigame());
		this._listen(Minigame.football_event, (key) => this._on_football_event(key));
		this.help_button.pressed.connect(() => this._open_football_help());
		this.bite_button.button_down.connect(() => Minigame.tap());
		this.done_button.pressed.connect(() => Minigame.done());
		this._listen(Minigame.meal_event, (key) => this.meal_fork.show_event(tr(key)));
		this.football_help.closed.connect(() => this._close_football_help());
		this._listen(Activities.started, () => this._open_football_help_first_time());
		// A game loaded in the middle of cardio goes on as a session.
		Minigame.attach();
		this._open_football_help_first_time();

		// The game may have been loaded mid-activity, so show it at once.
		this._refresh_activity(true);
		this._refresh();
		this._refresh_clock();
		this._refresh_sleep_info();
		// A saved failure: the failure screen again (it cannot be escaped by reloading).
		if (GameState.failed_cause !== "") this._show_failure();
	}

	// The failure screen over everything. Time stops for good; an activity ends, except a sleep,
	// which only stops with the clock (ending it would start a new avatar day after the failure).
	_show_failure() {
		Clock.halted = true;
		if (Activities.is_running() && Activities.current_activity !== "sleep") Activities.stop();
		for (const panel of [this.options_panel, this.sleep_panel, this.settings_overlay, this.health_panel, this.values_panel]) panel.hide();
		if (this.football_help.visible) this.football_help.hide();
		this.failure_screen.open();
	}

	_exit_tree() {
		Minigame.detach();
		for (const [signal, fn] of this._connections) signal.disconnect(fn);
		this._connections = [];
		this.debug_panel.release();
	}

	_process(delta) {
		if (Minigame.running) {
			this._send_stick();
			this._refresh_minigame();
		}
		// Godot calls _process on every node; these are the ones that have it.
		this.meal_fork._process(delta);
		this.football_field._process(delta);
	}

	// The joystick, or the arrow keys or WASD on a computer. The screen's y goes down, the
	// field's goes up. WASD reads the key's place on the keyboard, so it also works on other
	// layouts.
	_send_stick() {
		if (Minigame.kind !== Minigame.FOOTBALL) return;
		const keys = new Vector2(
			Input.strength("ArrowRight", "KeyD") - Input.strength("ArrowLeft", "KeyA"),
			Input.strength("ArrowDown", "KeyS") - Input.strength("ArrowUp", "KeyW"),
		).normalized();
		const direction = !this._pad_stick.is_zero() ? this._pad_stick : keys;
		const wanted = new Vector2(direction.x, -direction.y);
		if (!wanted.equals(Minigame.game.stick)) Minigame.set_stick(wanted);
	}

	_on_pad_stick(direction) {
		this._pad_stick = new Vector2(direction.x, direction.y);
	}

	_on_match_ended(goals_us, goals_them) {
		this._flash("SPEECH_MATCH_RESULT", [goals_us, goals_them]);
	}

	_on_football_event(key) {
		this.football_field.show_event(tr(key));
	}

	// The first time someone plays football on this device.
	_open_football_help_first_time() {
		if (Minigame.kind === Minigame.FOOTBALL && !Settings.football_help_seen) this._open_football_help();
	}

	// The day pauses while the explanation is open, as with the settings.
	_open_football_help() {
		if (this.football_help.visible) return;
		this.football_help.open(this.football_pad.touch_mode);
		if (Clock.phase === Clock.Phase.DAY && !Clock.paused) {
			this._paused_by_settings = true;
			Clock.set_paused(true);
		}
	}

	_close_football_help() {
		Settings.mark_football_help_seen();
		if (this._paused_by_settings) {
			this._paused_by_settings = false;
			Clock.set_paused(false);
		}
	}

	// On a computer Space plays cardio, the arrow keys Down and Up play strength, and in football
	// arrow keys or WASD move, Z or J passes, X, K or Space shoots or tackles, P pauses and H
	// helps. In a meal Space bites and D is Done. key: the key's place (KeyboardEvent.code).
	_key_pressed(key, event) {
		this.debug_panel._key_pressed(key, event);
		if (!Minigame.running || event?.repeat) return;
		if (Minigame.kind === Minigame.FOOTBALL) this._on_football_key(key);
		if (Minigame.kind === Minigame.MEAL && key === "KeyD") Minigame.done();
		if (key === "Space" || key === "Enter" || key === "NumpadEnter") {
			Minigame.tap();
			Minigame.shoot_or_tackle();
		} else if (key === "ArrowDown") {
			Minigame.press(true);
		} else if (key === "ArrowUp") {
			Minigame.press(false);
		}
	}

	_on_football_key(key) {
		if (key === "KeyZ" || key === "KeyJ") Minigame.pass_ball();
		else if (key === "KeyX" || key === "KeyK") Minigame.shoot_or_tackle();
		else if (key === "KeyP") Clock.toggle_pause();
		else if (key === "KeyH") this._open_football_help();
	}

	// Clicking the health level or the health bar shows or hides the three measures.
	_toggle_health_panel() {
		this.health_panel.visible = !this.health_panel.visible;
		if (!this.health_panel.visible) this.values_panel.visible = false;
	}

	// Clicking the physical bar shows or hides its values as numbers: calories spent, strength,
	// fitness, weight, height, BMI-for-age z and diet quality.
	_toggle_values_panel() {
		this.values_panel.visible = !this.values_panel.visible;
	}

	// The language changed: every text written here is written again. Text that holds a key
	// follows by itself.
	_translation_changed() {
		this._refresh();
		this._refresh_sleep_info();
		this._refresh_minutes();
		if (this.options_panel.visible) this._build_options(this._options_activity);
		if (this._flash_key !== "") this._show_flash();
	}

	_choose_language(id) {
		this.portuguese_button.set_pressed_no_signal(id === "pt");
		this.english_button.set_pressed_no_signal(id === "en");
		Settings.set_language(id);
	}

	// The settings open at any moment, even during an activity. They cover the screen, so
	// nothing else can be pressed. The day pauses while they are open; sleep keeps running.
	_open_settings() {
		this.portuguese_button.set_pressed_no_signal(Settings.language === "pt");
		this.english_button.set_pressed_no_signal(Settings.language === "en");
		this.settings_overlay.show();
		if (Clock.phase === Clock.Phase.DAY && !Clock.paused) {
			this._paused_by_settings = true;
			Clock.set_paused(true);
		}
	}

	// Back to how the game was before the settings opened.
	_close_settings() {
		this.settings_overlay.hide();
		this._show_new_avatar_confirmation(false);
		if (this._paused_by_settings) {
			this._paused_by_settings = false;
			Clock.set_paused(false);
		}
	}

	// "Start a new avatar" only shows the warning; nothing happens without the second press.
	_show_new_avatar_confirmation(show_it) {
		this.confirm_box.visible = show_it;
		this.new_avatar_button.visible = !show_it;
	}

	// Back to the main menu (Milestone 18): the avatar is saved, then the menu empties the game.
	_go_to_menu() {
		if (Activities.is_running() && Activities.current_activity !== "sleep") Activities.stop();
		SaveGame.save_game();
		Scene.change(MENU_SCENE);
	}

	// The avatar is deleted for good and the creation screen opens. The language stays: it is
	// in Settings, not in the avatar's save.
	_start_new_avatar() {
		Activities.stop();
		SaveGame.delete_save();
		Scene.change(CREATION_SCENE);
	}

	// XP changes come in small amounts (every 5 avatar minutes at high health) or at once (the
	// health bar's step after a sleep). They are added up; a loading save shows nothing.
	_on_xp_changed(amount) {
		if (Simulation.loading) return;
		this._xp_pending += amount;
		if (this._xp_tween === null || !this._xp_tween.is_running()) this._show_xp_change();
	}

	// Shows the whole XP added up since the last one, keeping the rest for later; a change
	// smaller than 1 XP waits.
	_show_xp_change() {
		const shown = roundf(this._xp_pending);
		if (shown === 0) return;
		this._xp_pending -= shown;
		const label = this.xp_change_label;
		label.text = format(tr(shown > 0 ? "UI_XP_GAIN" : "UI_XP_LOSS"), [Math.abs(shown)]);
		label.color = shown > 0 ? this.xp_gain_color : this.xp_loss_color;
		const bar_height = this.xp_bar.size.y || XP_BAR_HEIGHT;
		label.position_y = bar_height + this.xp_change_rise;
		label.alpha = 1;
		this._xp_tween = create_tween().set_parallel();
		this._xp_tween.tween_property(label, "position_y", bar_height, this.xp_change_seconds);
		this._xp_tween.tween_property(label, "alpha", 0, this.xp_change_seconds).set_ease(Ease.IN);
		this._xp_tween.chain().tween_callback(() => this._show_xp_change());
	}

	_on_leveled_up(new_level) {
		this._flash("SPEECH_LEVEL_UP", [new_level]);
	}

	// Shows a short message in the speech bubble for level_up_message_seconds.
	_flash(key, args = []) {
		this._flash_key = key;
		this._flash_args = args;
		this._show_flash();
		create_timer(this.level_up_message_seconds).timeout.connect(() => this._end_flash());
	}

	_show_flash() {
		this.speech_label.text = format(tr(this._flash_key), this._flash_args);
		this.request_icon.kind = "";
	}

	_end_flash() {
		this._flash_key = "";
		this._refresh_phase();
	}

	// Writes to the speech bubble, unless a short message is being shown. request: the picture
	// of a request (Requests), or "" for none.
	_set_speech(text, request = "") {
		if (this._flash_key === "") {
			this.speech_label.text = text;
			this.request_icon.kind = request;
		}
	}

	// The avatar's reactions (Milestone 16): each shows an effect the model already has.
	// A meal: from the craving before it. The meal minigame shows it over the fork.
	_on_meal_started(option_id) {
		if (Simulation.loading) return;
		const key = Requests.meal_reaction(option_id);
		if (key === "") return;
		if (Minigame.running && Minigame.kind === Minigame.MEAL) this.meal_fork.show_event(tr(key));
		else this._flash(key);
	}

	// Exercise really starts at the first tap or press, with its happiness cost.
	_on_first_stride() {
		const key = Requests.exercise_reaction(Activities.current_option);
		if (key !== "") this._flash(key);
	}

	// A wish the model counted as refused. Not over the football field or the fork.
	_on_wish_refused(wish) {
		const covered = Minigame.running && [Minigame.FOOTBALL, Minigame.MEAL].includes(Minigame.kind);
		if (wish === Requests.SCREENS && !covered) this._flash("SPEECH_NO_SCREENS");
	}

	// The avatar can sleep only when it is sleepy (Clock.is_sleepy()); otherwise it says so.
	// The slider stops at the longest sleep allowed now.
	_on_sleep_button_pressed() {
		if (!Clock.is_sleepy()) {
			this._flash("SPEECH_NOT_SLEEPY");
			return;
		}
		this.sleep_slider.max_value = Clock.max_sleep_hours();
		this._refresh_sleep_info();
		this.sleep_panel.show();
	}

	// Opens the list of options of an activity (cardio and muscle strength for exercise), built
	// from data/activities.json. The player first chooses the minutes on the slider, then clicks
	// the option; meals have no slider because their portions are fixed.
	_open_options(activity_id) {
		const definition = Activities.definitions[activity_id] ?? {};
		this.minutes_box.visible = definition.minutes_slider ?? false;
		if (this.minutes_box.visible) {
			const first_option = Object.values(definition.options ?? {})[0];
			this.minutes_slider.value = Number(first_option.duration_hours) * Clock.MINUTES_PER_HOUR;
			this._refresh_minutes();
		}
		this._build_options(activity_id);
		this.options_panel.show();
	}

	_refresh_minutes() {
		this.minutes_label.text = format(tr("UI_MINUTES"), [roundf(this.minutes_slider.value)]);
	}

	_build_options(activity_id) {
		this.option_buttons.clear_children();
		const definition = Activities.definitions[activity_id] ?? {};
		const options = definition.options ?? {};
		this._options_activity = activity_id;
		this.options_title.text = String(definition.name ?? activity_id);
		for (const [option_id, option] of Object.entries(options)) {
			const name = tr(option.name ?? option_id);
			const text = this.minutes_box.visible ? name
				: format(tr("UI_OPTION"), [name, Settings.decimal_text(godot_number_text(option.duration_hours ?? "?"))]);
			const button = new Button(this.option_buttons, text, "h72");
			button.pressed.connect(() => this._on_option_chosen(activity_id, option_id));
		}
		// A hungry avatar can also skip the meal: hunger stays, the 2-hour gap starts again.
		if (activity_id === "eat" && Hunger.is_hungry()) {
			const skip = new Button(this.option_buttons, "UI_SKIP_MEAL", "h72");
			skip.pressed.connect(() => this._on_skip_meal());
		}
	}

	_on_skip_meal() {
		this.options_panel.hide();
		Hunger.skip();
	}

	_on_option_chosen(activity_id, option_id) {
		this.options_panel.hide();
		Activities.start(activity_id, option_id, this.minutes_box.visible ? this.minutes_slider.value / Clock.MINUTES_PER_HOUR : -1);
	}

	_on_sleep_start_pressed() {
		this.sleep_panel.hide();
		Activities.start("sleep", "sleep", this.sleep_slider.value);
	}

	_on_phase_changed() {
		this._refresh_activity();
	}

	// Animation and background of the running activity (or none): its scenery (outside, a room
	// with windows, a bedroom; scenery.js), or else its see-through background colour.
	_refresh_activity(instant = false) {
		const option = Activities.current_option_data();
		let place = "";
		let alpha = 0;
		if (Activities.is_running()) {
			place = String(option.scenery ?? "");
			if (place === "") {
				this.activity_backdrop.node.style.backgroundColor = String(option.background_color ?? "#000000");
				alpha = this.activity_backdrop_alpha;
			}
		}
		this._refresh_animation();
		this._refresh_minigame();
		this._backdrop_tween = this._fade([this.activity_backdrop], this._backdrop_tween, alpha, instant);
		// A new place fades in from nothing; when the activity ends the last one fades out.
		if (place !== "" && place !== this.scenery.kind) {
			for (const layer of [this.scenery, this.blanket]) {
				layer.avatar = this.avatar;
				layer.kind = place;
				layer.alpha = 0;
			}
		}
		this._scenery_tween = this._fade([this.scenery, this.blanket], this._scenery_tween, place === "" ? 0 : 1, instant);
		this._refresh_phase();
	}

	_fade(nodes, tween, alpha, instant) {
		tween?.kill();
		if (instant) {
			for (const node of nodes) node.alpha = alpha;
			return null;
		}
		tween = create_tween().set_parallel();
		for (const node of nodes) tween.tween_property(node, "alpha", alpha, this.backdrop_fade_seconds);
		return tween;
	}

	// The running activity's repeating animation. In a minigame the avatar moves only with the
	// player, and stands still while it waits. At the start of a rest it finishes its last move.
	_refresh_animation() {
		if (Activities.is_running() && !Minigame.running) {
			this.avatar.play_animation(String(Activities.current_option_data().animation ?? ""));
		} else if (!Minigame.resting) {
			this.avatar.stop_animation();
		}
	}

	_on_session_changed() {
		this._refresh_animation();
		this._refresh_minigame();
	}

	_on_stride() {
		if (Minigame.kind === Minigame.STRENGTH) this.avatar.squat(!Minigame.next_down);
		else if (Minigame.kind === Minigame.CARDIO) this.avatar.stride(Minigame.walking);
		else if (Minigame.kind === Minigame.MEAL && Minigame.last_on_beat) this.avatar.chew();
	}

	// The avatar says so, and the player can still train (decision 35).
	_warn_if_too_soon() {
		if (Minigame.kind === Minigame.STRENGTH && Training.strength_too_soon()) this._flash("SPEECH_TOO_SOON");
	}

	// The minigame takes the place of the four buttons while a session runs.
	_refresh_minigame() {
		this.minigame_panel.visible = Minigame.running;
		this.action_grid.visible = !Minigame.running;
		const football = Minigame.running && Minigame.kind === Minigame.FOOTBALL;
		this.football_field.visible = football;
		this.avatar.visible = !football;
		// The bubble would cover the match or the fork: it only comes back for a short message.
		const meal = Minigame.running && Minigame.kind === Minigame.MEAL;
		this.speech_bubble.visible = !(football || meal) || this._flash_key !== "";
		// Before the return below: after a meal the fork and its zone must go (they stayed during
		// the sleep that followed; user, 7 Nov 2026).
		this.meal_fork.visible = meal;
		if (!meal) this.avatar.mouth_open = false;
		if (!Minigame.running) return;
		const strength = Minigame.kind === Minigame.STRENGTH;
		this.tap_button.visible = Minigame.kind === Minigame.CARDIO;
		this.help_button.visible = football;
		this.meal_buttons.visible = meal;
		this.reserve_row.visible = !meal;
		this.strength_buttons.visible = strength;
		this.football_pad.visible = football;
		this.beat_bar.visible = !football;
		// On a computer the keys need less room, so the field is larger.
		const small_pad = football && !this.football_pad.touch_mode;
		this.football_pad.node.style.minHeight = (small_pad ? FOOTBALL_PAD_KEYS : FOOTBALL_PAD_TOUCH) + "px";
		this.football_pad.default_size = {x: this.football_pad.default_size.x, y: small_pad ? FOOTBALL_PAD_KEYS : FOOTBALL_PAD_TOUCH};
		this.minigame_panel.node.style.minHeight = (small_pad ? 0 : MINIGAME_PANEL_HEIGHT) + "px";
		this.reserve_label.text = tr(strength ? "MINIGAME_MUSCLE" : "MINIGAME_BREATH");
		this.reserve_bar.value = Minigame.reserve;
		if (football) {
			this._refresh_football();
			return;
		}
		if (meal) {
			this._refresh_meal();
			return;
		}
		if (strength) {
			this._refresh_strength();
		} else {
			const status = Minigame.waiting ? "MINIGAME_WAITING" : Minigame.walking ? "MINIGAME_WALKING" : "MINIGAME_RUNNING";
			this.minigame_status.text = tr(status);
			this.minigame_steps.text = format(tr("MINIGAME_STEPS"), [Minigame.steps(), Minigame.steps_goal()]);
		}
		const stopped = Minigame.waiting || Minigame.resting;
		const elapsed = stopped ? 0 : Minigame.seconds_since_tap / Minigame.interval();
		this.beat_bar.show_time(elapsed, Config.get_float("minigame.on_beat_share"), Minigame.last_on_beat);
	}

	_refresh_football() {
		const game = Minigame.game;
		const status = Minigame.waiting ? "MINIGAME_PLAY_WAITING" : Minigame.walking ? "MINIGAME_JOGGING" : "MINIGAME_PLAYING";
		this.minigame_status.text = format(tr("SPEECH_PROGRESS_MINUTES"), [tr(status),
			roundf(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR), roundf(Activities.target_hours * Clock.MINUTES_PER_HOUR)]);
		this.minigame_steps.text = format(tr("MINIGAME_SCORE"), [game.goals_us, game.goals_them]);
		const field = this.football_field;
		field.game = game;
		field.you_text = tr("FOOTBALL_YOU");
		field.hint = tr(this._football_hint());
		const pad = this.football_pad;
		const keys = !pad.touch_mode;
		const ask = game.team_mate_has_ball();
		pad.pass_text = this._with_key(ask ? "MINIGAME_ASK" : "MINIGAME_PASS", "Z", keys);
		pad.shoot_text = this._with_key(game.defending() ? "MINIGAME_TACKLE" : "MINIGAME_SHOOT", "X", keys);
		pad.pass_enabled = game.has_ball() || ask;
		pad.shoot_enabled = game.has_ball() || ask || game.in_tackle_reach();
		pad.keys_text = tr("FOOTBALL_KEYS");
		pad.queue_redraw();
	}

	// The meal minigame (Milestone 15): the fork, the mouth, the Tummy bar and the buttons.
	_refresh_meal() {
		const full = Minigame.bites >= roundf(Minigame.full_share() * Config.get_float("minigame.meal.bites"));
		const status = Minigame.waiting ? "MEAL_WAITING" : full ? "MEAL_FULL" : "MEAL_EATING";
		this.minigame_status.text = tr(status);
		this.minigame_steps.text = format(tr("MEAL_TUMMY"), [Minigame.bites, Config.get_int("minigame.meal.bites")]);
		this.beat_bar.show_level(Minigame.meal_share(), Minigame.full_share(), 1);
		const keys = !this.football_pad.touch_mode;
		this.bite_button.text = this._with_key("MINIGAME_BITE", "Space", keys);
		this.done_button.text = this._with_key("MINIGAME_DONE", "D", keys);
		this.avatar.mouth_open = Minigame.at_mouth();
		const fork = this.meal_fork;
		fork.fork = Minigame.fork_position();
		fork.at_mouth = Minigame.at_mouth();
		fork.hit_share = Config.get_float("minigame.meal.hit_share");
		fork.mouth = this._avatar_mouth_in_stage();
		fork.food_color = Activities.current_option === "healthy_meal" ? MEAL_HEALTHY_COLOR : MEAL_FAST_FOOD_COLOR;
		fork.queue_redraw();
	}

	// The avatar's mouth in the stage (where the fork is), with the avatar's scale around its
	// feet (Godot's global transforms).
	_avatar_mouth_in_stage() {
		const avatar = this.avatar;
		const size = avatar.size;
		const stage = this.stage.size;
		const left = avatar.node.offsetLeft || (stage.x - size.x) / 2;
		const top = avatar.node.offsetTop || stage.y - AVATAR_FEET_FROM_BOTTOM - size.y;
		const mouth = avatar.mouth_point();
		const pivot = {x: size.x * 0.5, y: size.y};
		return {
			x: left + pivot.x + (mouth.x - pivot.x) * avatar.scale.x,
			y: top + pivot.y + (mouth.y - pivot.y) * avatar.scale.y - avatar.hop_offset * avatar.scale.y,
		};
	}

	_with_key(key, keyboard_key, keys) {
		return keys ? `${tr(key)}  [${keyboard_key}]` : tr(key);
	}

	// What the player should do now.
	_football_hint() {
		const game = Minigame.game;
		if (Clock.paused) return "FOOTBALL_PAUSED";
		if (Minigame.waiting) return this.football_pad.touch_mode ? "FOOTBALL_HINT_START_TOUCH" : "FOOTBALL_HINT_START_KEYS";
		if (game.stopped()) return "";
		if (Minigame.walking) return "FOOTBALL_HINT_JOG";
		if (game.has_ball()) {
			if (game.in_shot_range()) return "FOOTBALL_HINT_SHOOT";
			return game.under_pressure() ? "FOOTBALL_HINT_PASS" : "FOOTBALL_HINT_RUN";
		}
		if (game.team_mate_has_ball()) return game.team_mate_in_shot_range() ? "FOOTBALL_HINT_MATE_SHOOT" : "FOOTBALL_HINT_ASK";
		if (game.defending()) return game.in_tackle_reach() ? "FOOTBALL_HINT_TACKLE" : "FOOTBALL_HINT_CHASE";
		return "FOOTBALL_HINT_BALL";
	}

	_refresh_strength() {
		if (Minigame.waiting) this.minigame_status.text = tr("MINIGAME_WAITING");
		else if (Minigame.resting) this.minigame_status.text = tr("MINIGAME_RESTING");
		else if (Minigame.sets_started <= Minigame.sets_goal) {
			this.minigame_status.text = format(tr("MINIGAME_SET"), [Minigame.sets_started, Minigame.sets_goal]);
		} else {
			this.minigame_status.text = format(tr("MINIGAME_SET_EXTRA"), [Minigame.sets_started - Minigame.sets_goal]);
		}
		this.minigame_steps.text = format(tr("MINIGAME_REPS"), [Minigame.reps_in_set, Minigame.set_reps]);
		this.down_button.disabled = Minigame.resting || !Minigame.next_down;
		this.up_button.disabled = Minigame.resting || Minigame.next_down;
	}

	// The sky follows the clock, and so do the windows of the room and the buttons: black ones
	// while the sky is more night than day.
	_refresh_sky() {
		const daylight = Clock.daylight_amount();
		const sky = this.night_sky_color.map((night, i) => night + (this.day_sky_color[i] - night) * daylight);
		this.sky_color = sky;
		this.sky.style.backgroundColor = css(sky);
		this.scenery.sky_color = sky;
		this.scenery.daylight = daylight;
		const night = daylight < 0.5;
		if (night !== this.night) {
			this.night = night;
			this.main.set_class("night", night);
			// The gauges draw the bars' border in the theme's colour.
			for (const gauge of Object.values(this.failure_screen.gauges)) gauge.queue_redraw();
		}
	}

	_refresh() {
		const gs = GameState;
		this.health_level_button.text = String(gs.health_level);
		this.health_bar.value = gs.health;
		// The danger state of severe thinness, or a failure timer running: failure may come soon.
		const danger = HealthModel.in_danger() || HealthModel.failure_near();
		this.health_bar.theme_type_variation = danger ? DANGER_BAR_STYLE : HEALTH_BAR_STYLE;
		this.health_label.text = danger ? DANGER_TEXT : HEALTH_TEXT;
		this.physical_bar.value = gs.physical;
		this.happiness_bar.value = gs.happiness;
		this.sleep_bar.value = gs.sleep;
		this.calories_label.text = format(tr("MEASURE_CALORIES"), [roundf(gs.calories_spent)]);
		this.muscle_label.text = format(tr("MEASURE_STRENGTH"), [Settings.number(gs.strength, 2)]);
		this.fitness_label.text = format(tr("MEASURE_FITNESS"), [Settings.number(gs.fitness, 2)]);
		this.weight_label.text = format(tr("MEASURE_WEIGHT"), [Settings.number(gs.weight_kg, 1)]);
		this.height_label.text = format(tr("MEASURE_HEIGHT"), [gs.height_m * Config.get_float("units.cm_per_m")]);
		this.bmi_label.text = format(tr("MEASURE_BMI"), [Settings.number(gs.weight_z, 2, true)]);
		this.diet_label.text = format(tr("MEASURE_DIET"), [Settings.number(gs.diet_quality, 2)]);
		this.avatar.states = AvatarStates.current();
		this.avatar.sheet = `${gs.age_group}_${gs.sex}`;
		this.level_label.text = format(tr("UI_LEVEL"), [gs.level]);
		this.xp_bar.value = gs.level_progress;
		const per_level = Config.get_float("xp.per_level");
		this.xp_label.text = format(tr("UI_XP"), [Math.floor(gs.level_progress * per_level), roundf(per_level)]);
		this._refresh_phase();
	}

	_refresh_clock() {
		let text = Clock.clock_text();
		if (Clock.is_debug_speed_active()) text += format("\nx%d", [Clock.debug_speed]);
		this.clock_label.text = text;
		this._refresh_sky();
	}

	_refresh_activity_speech() {
		if (!Activities.is_running()) return;
		if (Activities.current_activity === "sleep") {
			this._set_speech(format(tr("SPEECH_PROGRESS"), ["Zzz...", Settings.number(Activities.elapsed_hours, 1),
				Settings.number(Activities.target_hours, 1)]));
			return;
		}
		this._set_speech(format(tr("SPEECH_PROGRESS_MINUTES"), [`${tr(Activities.current_option_data().name ?? "")}...`,
			roundf(Activities.elapsed_hours * Clock.MINUTES_PER_HOUR), roundf(Activities.target_hours * Clock.MINUTES_PER_HOUR)]));
	}

	_refresh_phase() {
		const phase = Clock.phase;
		const running = Activities.is_running();
		this.pause_button.disabled = phase !== Clock.Phase.DAY;
		this.pause_button.set_pressed_no_signal(Clock.paused);
		this.wake_button.disabled = phase !== Clock.Phase.SLEEP_OVER;
		this.stop_button.visible = running;
		for (const button of this.action_buttons) button.disabled = running;
		// Enabled while awake even when the avatar is not sleepy, so it can say so.
		this.sleep_button.disabled = running || phase !== Clock.Phase.DAY;
		this.exercise_button.disabled = !Activities.can_start("exercise");
		this.entertainment_button.disabled = !Activities.can_start("entertainment");
		this.eat_button.disabled = !Activities.can_start("eat");
		if (running) {
			this._refresh_activity_speech();
			return;
		}
		if (phase === Clock.Phase.DAY) {
			if (GameState.is_at_failure()) {
				this._set_speech(this.failure_text());
			} else if (Requests.current() !== "") {
				// A request stays until the avatar gets what it wants (tired: until it sleeps).
				const request = Requests.current();
				this._set_speech(tr(Requests.text_key(request)), request);
			} else if (AvatarStates.current().sad) {
				this._set_speech(tr("SPEECH_SAD"));
			} else {
				this._set_speech(Clock.paused ? tr("SPEECH_PAUSED") : tr("SPEECH_HELLO"));
			}
		} else if (phase === Clock.Phase.SLEEP_OVER) {
			let text = format(tr("SPEECH_SLEPT"), [Settings.number(Clock.sleep_elapsed_hours, 1)]);
			if (GameState.is_at_failure()) text = this.failure_text() + "\n" + text;
			this._set_speech(text);
		}
	}

	// The placeholder failure message for the current cause ("" when there is no failure).
	failure_text() {
		return tr(FAILURE_TEXTS[GameState.failure_cause()] ?? "");
	}

	// Shows what the chosen hours mean: real sleep time and the length of the next day.
	_refresh_sleep_info() {
		const hours = this.sleep_slider.value;
		const day_hours = Clock.day_hours_after_sleep(hours);
		let text = format(tr("SLEEP_INFO"), [
			Settings.number(hours, 1),
			roundf(Clock.avatar_hours_to_real_seconds(hours, true) / 60),
			Settings.number(day_hours, 1),
			Settings.number(Clock.avatar_hours_to_real_seconds(day_hours, false) / 60, 1),
		]);
		text += "\n" + format(tr("SLEEP_AT_MOST"), [Settings.number(Clock.max_sleep_hours(), 1)]);
		if (Clock.phase === Clock.Phase.DAY) text += "\n" + tr("SLEEP_ENDS_DAY");
		this.sleep_info_label.text = text;
	}

	tr(key) {
		return tr(key);
	}
}

// The XP bar's height (style.css), for the rising XP text before the page has a layout.
const XP_BAR_HEIGHT = 40;
// Where the avatar's feet are, from the bottom of the stage (style.css: .stage-avatar).
const AVATAR_FEET_FROM_BOTTOM = 60;

// How Godot writes a number from a JSON file: always with a decimal point (0.5, 1.0).
function godot_number_text(value) {
	if (typeof value !== "number") return String(value);
	return Number.isInteger(value) ? value.toFixed(1) : String(value);
}

Scene.register("main", MainScreen);
