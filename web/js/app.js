// Starts the game in the browser: loads the data files, starts the autoloads (as Godot did),
// fits the 720 x 1280 game area in the window, opens the main menu and runs the frames.
import {load_data} from "./core/data.js";
import {start_autoloads, run_loop, key_pressed} from "./core/engine.js";
import {Config} from "./core/config.js";
import {Debug} from "./core/debug.js";
import {Scene} from "./ui/scene.js";
import {Assets} from "./ui/widgets.js";
import {Input} from "./ui/input.js";
import "./ui/menu.js";
import "./ui/creation.js";
import "./ui/main_screen.js";

// The game area (project.godot: viewport 720 x 1280, stretch mode canvas_items, aspect keep).
const WIDTH = 720;
const HEIGHT = 1280;
// The keys the browser would otherwise use (scrolling the page, its own F-key features).
const GAME_KEYS = new Set(["Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"]);
const DEBUG_KEYS = new Set(["F6", "F7", "F8", "F9"]);

async function start() {
	// The folder that holds data/, translations/ and assets/ (index.html says where).
	const base = document.body.dataset.base ?? "./";
	Assets.base = base;
	Config.base_path = base;
	await load_data(base);
	start_autoloads();
	const game = document.getElementById("game");
	Scene.root = game;
	fit(game);
	window.addEventListener("resize", () => fit(game));
	document.addEventListener("keydown", (event) => {
		Input.press(event.code);
		if (GAME_KEYS.has(event.code) || (Debug.allowed() && DEBUG_KEYS.has(event.code))) event.preventDefault();
		key_pressed(event.code, event);
	});
	document.addEventListener("keyup", (event) => Input.release(event.code));
	window.addEventListener("blur", () => Input.release_all());
	Scene.open("menu");
	document.getElementById("loading")?.remove();
	run_loop();
}

// Scales the game area to the largest size that fits the window, centred (Godot's "keep").
function fit(game) {
	const scale = Math.min(window.innerWidth / WIDTH, window.innerHeight / HEIGHT);
	const left = (window.innerWidth - WIDTH * scale) / 2;
	const top = (window.innerHeight - HEIGHT * scale) / 2;
	game.style.transform = `translate(${left}px, ${top}px) scale(${scale})`;
	Scene.pixel_ratio = scale * (window.devicePixelRatio || 1);
}

start().catch((error) => {
	console.error(error);
	const loading = document.getElementById("loading");
	if (loading) loading.textContent = "The game could not start: " + error.message;
});
