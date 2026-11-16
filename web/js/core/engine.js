// What Godot's engine did for the game: starts the autoloads in the order of project.godot
// (Config, Settings, GameState, Clock, Minigame, Simulation, Activities, Habits, HealthLog,
// SaveGame), so their signal connections run in the same order, and then calls _process every
// frame, autoloads first and the open screen last, as Godot's scene tree does.
import {Config} from "./config.js";
import {Settings} from "./settings.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Minigame} from "./minigame.js";
import {Simulation} from "./simulation.js";
import {Activities} from "./activities.js";
import {Habits} from "./habits.js";
import {HealthLog} from "./health_log.js";
import {SaveGame} from "./save_game.js";
import {TranslationServer} from "./translation.js";

export const AUTOLOADS = [Config, Settings, GameState, Clock, Minigame, Simulation, Activities, Habits, HealthLog, SaveGame];

export const Engine = {
	started: false,
	// The open screen: an object with optional _process(delta), _key_pressed(key) and close().
	screen: null,
	_last_time: null,
};

// Starts everything, after the data files are in Data (load_data() or the tests).
export function start_autoloads() {
	Config.load_config();
	TranslationServer.load();
	Activities._init();
	// Godot runs _ready in the order of the autoload list.
	Settings._ready();
	GameState.reset();
	Clock._ready();
	Minigame._ready();
	Simulation._ready();
	Activities._ready();
	Habits._ready();
	HealthLog._ready();
	SaveGame._ready();
	Engine.started = true;
}

// One frame: every autoload's _process, then the open screen's.
export function process_frame(delta) {
	Clock._process(delta);
	Minigame._process(delta);
	SaveGame._process(delta);
	if (Engine.screen && Engine.screen._process) Engine.screen._process(delta);
}

// The browser's frame loop.
export function run_loop() {
	const frame = (time) => {
		const delta = Engine._last_time === null ? 0 : (time - Engine._last_time) / 1000;
		Engine._last_time = time;
		process_frame(delta);
		requestAnimationFrame(frame);
	};
	requestAnimationFrame(frame);
}

// Debug keys (F6, F8, F9) and the screen's own keys.
export function key_pressed(key, event) {
	if (key === "F6" && typeof location !== "undefined" && new URLSearchParams(location.search).has("debug")) {
		Config.reload_from_server?.();
	}
	Clock._key_pressed(key);
	SaveGame._key_pressed(key);
	if (Engine.screen && Engine.screen._key_pressed) Engine.screen._key_pressed(key, event);
}
