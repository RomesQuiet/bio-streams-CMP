// What Godot's scene tree did for the screens: one open screen at a time (change_scene), timers
// (create_timer), tweens (create_tween), deferred calls (call_deferred), redrawing the canvases
// that asked for it, and writing every text again when the language changes. All of it runs from
// the engine's frame (process_frame), so the Node tests can drive it frame by frame.
import {Engine} from "../core/engine.js";
import {TranslationServer} from "../core/translation.js";

export const Scene = {
	// The element every screen is built in (the 720 x 1280 game area).
	root: null,
	// Canvas pixels per game pixel: the page's scale times the screen's pixel density.
	pixel_ratio: 1,
	_screens: {},
	_timers: [],
	_tweens: new Set(),
	_deferred: [],
	_canvases: new Set(),

	// Screens register themselves by name: a class whose constructor builds it in a root element.
	register(name, screen_class) {
		Scene._screens[name] = screen_class;
	},

	// Closes the open screen and opens another (Godot's change_scene_to_file, which also waits
	// for the end of the frame).
	change(name) {
		call_deferred(() => Scene.open(name));
	},

	// Opens a screen at once (the tests and the start of the game).
	open(name) {
		Scene.close();
		const screen = new Scene._screens[name](Scene.root);
		Engine.screen = screen;
		screen._ready?.();
		return screen;
	},

	close() {
		const screen = Engine.screen;
		if (screen) {
			screen._exit_tree?.();
			screen.node?.remove();
		}
		Engine.screen = null;
		// Timers and tweens belonged to the closed screen.
		Scene._timers = [];
		for (const tween of Scene._tweens) tween.kill();
		Scene._tweens.clear();
	},

	// Runs after the screen's _process every frame, as in Godot.
	process(delta) {
		Scene.flush_deferred();
		for (const timer of [...Scene._timers]) {
			timer.left -= delta;
			if (timer.left <= 0) {
				Scene._timers.splice(Scene._timers.indexOf(timer), 1);
				timer.timeout.emit();
			}
		}
		for (const tween of [...Scene._tweens]) tween._advance(delta);
		Scene.flush_deferred();
		Scene.redraw();
	},

	flush_deferred() {
		while (Scene._deferred.length > 0) {
			const calls = Scene._deferred;
			Scene._deferred = [];
			for (const call of calls) call();
		}
	},

	// Draws the canvases that asked for it, or whose size changed (shown again, the window
	// resized).
	redraw() {
		for (const canvas of Scene._canvases) {
			if (!canvas.node.isConnected) continue;
			canvas._draw_if_needed();
		}
	},
};

Engine.frame_hooks.push((delta) => Scene.process(delta));
TranslationServer.changed.connect(() => retranslate(Scene.root));

// Godot's call_deferred: runs at the end of this frame.
export function call_deferred(fn) {
	Scene._deferred.push(fn);
}

// Godot's get_tree().create_timer(seconds): its timeout signal fires after that many seconds.
export function create_timer(seconds) {
	const timer = {left: seconds, timeout: new SimpleSignal()};
	Scene._timers.push(timer);
	return timer;
}

class SimpleSignal {
	constructor() {
		this._fns = [];
	}
	connect(fn) {
		this._fns.push(fn);
	}
	emit(...args) {
		for (const fn of [...this._fns]) fn(...args);
	}
}

// Every widget in an element writes its text again in the new language (Godot's automatic
// translation of node texts).
export function retranslate(node) {
	if (!node) return;
	node._widget?.render?.();
	for (const child of [...node.children]) retranslate(child);
	node._widget?._translation_changed?.();
}

// Easing as in Godot: TRANS_LINEAR or TRANS_SINE, with EASE_IN, EASE_OUT or EASE_IN_OUT.
export const Trans = {LINEAR: "linear", SINE: "sine"};
export const Ease = {IN: "in", OUT: "out", IN_OUT: "in_out"};

function eased(t, trans, ease) {
	if (trans !== Trans.SINE) return t;
	if (ease === Ease.IN) return 1 - Math.cos(t * Math.PI / 2);
	if (ease === Ease.OUT) return Math.sin(t * Math.PI / 2);
	return -(Math.cos(Math.PI * t) - 1) / 2;
}

function mix(from, to, t) {
	if (typeof from === "number") return from + (to - from) * t;
	return {x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t};
}

// Godot's Tween, as far as the screens use it: properties of an object move to a value over some
// seconds, one after the other or together (set_parallel), then callbacks, repeated with
// set_loops.
export class Tween {
	constructor() {
		this._groups = [];
		this._parallel = false;
		this._chain_next = false;
		this._loops = 1;
		this._loop = 0;
		this._trans = Trans.LINEAR;
		this._ease = Ease.IN_OUT;
		this._index = 0;
		this._time = 0;
		this._running = true;
		Scene._tweens.add(this);
	}
	set_parallel(parallel = true) {
		this._parallel = parallel;
		return this;
	}
	// 0 repeats for ever.
	set_loops(loops = 0) {
		this._loops = loops;
		return this;
	}
	set_trans(trans) {
		this._trans = trans;
		return this;
	}
	set_ease(ease) {
		this._ease = ease;
		return this;
	}
	chain() {
		this._chain_next = true;
		return this;
	}
	_add(step) {
		const last = this._groups[this._groups.length - 1];
		if (this._parallel && last && !this._chain_next) last.push(step);
		else this._groups.push([step]);
		this._chain_next = false;
		return step;
	}
	tween_property(object, property, to, seconds) {
		const step = {object, property, to, seconds, from: null, trans: this._trans, ease: this._ease};
		step.set_ease = (ease) => {
			step.ease = ease;
			return step;
		};
		step.set_trans = (trans) => {
			step.trans = trans;
			return step;
		};
		return this._add(step);
	}
	tween_callback(fn) {
		return this._add({callback: fn, seconds: 0});
	}
	kill() {
		this._running = false;
		Scene._tweens.delete(this);
	}
	is_running() {
		return this._running;
	}
	_advance(delta) {
		let left = delta;
		while (this._running && this._index < this._groups.length) {
			const group = this._groups[this._index];
			if (this._time === 0) {
				for (const step of group) if (!step.callback) step.from = step.object[step.property];
			}
			const length = Math.max(...group.map((step) => step.seconds));
			const used = Math.min(left, length - this._time);
			this._time += used;
			left -= used;
			for (const step of group) {
				if (step.callback) continue;
				const t = step.seconds > 0 ? Math.min(1, this._time / step.seconds) : 1;
				step.object[step.property] = mix(step.from, step.to, eased(t, step.trans, step.ease));
			}
			if (this._time < length) return;
			for (const step of group) if (step.callback) step.callback();
			this._index += 1;
			this._time = 0;
			if (this._index >= this._groups.length) {
				this._loop += 1;
				if (this._loops === 0 || this._loop < this._loops) {
					this._index = 0;
					// A loop of zero-length steps would never end: wait for the next frame.
					if (length === 0 || left <= 0) return;
				} else {
					this.kill();
				}
			}
		}
	}
}

// Godot's create_tween().
export function create_tween() {
	return new Tween();
}
