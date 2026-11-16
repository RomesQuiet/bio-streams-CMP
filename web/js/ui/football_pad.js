// The football controls (Milestone 14): a joystick on the left and two buttons on the right. It
// reads touches itself, so a player can keep one finger on the joystick and another on a button
// at the same time.
// On a computer there is no joystick: the left side lists the keys, and the buttons show theirs.
// The first touch on a screen with a keyboard too brings the joystick back.
import {Signal} from "../core/util.js";
import {CanvasControl} from "./widgets.js";

const NO_FINGER = -1;
const MOUSE_FINGER = -2;
const STICK_COLOR = [0.11, 0.13, 0.18, 0.9];
const KNOB_COLOR = [0.85, 0.87, 0.9];
const PASS_COLOR = [0.25, 0.5, 0.95];
const SHOOT_COLOR = [0.9, 0.3, 0.3];
const DISABLED_COLOR = [0.3, 0.32, 0.36];
const TEXT_COLOR = [1, 1, 1];
const FONT_SIZE = 24;
const KEYS_FONT_SIZE = 20;
// Moves smaller than this share of the joystick do nothing.
const DEAD_ZONE = 0.15;
// Share of the width for the joystick.
const STICK_SHARE = 0.45;

export class FootballPad extends CanvasControl {
	constructor(parent = null) {
		super(parent, "football-pad", {x: 672, y: 170});
		this.stick_moved = new Signal();
		this.pass_pressed = new Signal();
		this.shoot_pressed = new Signal();
		// The first touch on a device that started as a computer.
		this.touch_seen = new Signal();
		this.pass_text = "";
		this.shoot_text = "";
		this.pass_enabled = true;
		this.shoot_enabled = true;
		// True on a touch screen: the joystick is shown.
		this.touch_mode = typeof window !== "undefined" && "ontouchstart" in window;
		// The list of keys, already translated.
		this.keys_text = "";
		this._finger = NO_FINGER;
		this._direction = {x: 0, y: 0};
		this.node.addEventListener("pointerdown", (event) => this._pointer(event, true));
		this.node.addEventListener("pointermove", (event) => {
			if (this._finger === finger_of(event)) this._aim(this._local(event));
		});
		for (const name of ["pointerup", "pointercancel"]) {
			this.node.addEventListener(name, (event) => this._on_touch(finger_of(event), false, this._local(event)));
		}
	}

	set visible(value) {
		super.visible = value;
		if (!value) this._let_go();
	}
	get visible() {
		return super.visible;
	}

	_pointer(event, pressed) {
		event.preventDefault();
		this.node.setPointerCapture?.(event.pointerId);
		this._on_touch(finger_of(event), pressed, this._local(event));
	}

	// Where the pointer is on this widget, in game pixels.
	_local(event) {
		const box = this.node.getBoundingClientRect();
		const size = this.size;
		return {x: ((event.clientX - box.left) * size.x) / box.width, y: ((event.clientY - box.top) * size.y) / box.height};
	}

	_on_touch(finger, pressed, point) {
		if (!pressed) {
			if (finger === this._finger) this._let_go();
			return;
		}
		const size = this.size;
		if (point.x < 0 || point.y < 0 || point.x > size.x || point.y > size.y) return;
		if (finger !== MOUSE_FINGER && !this.touch_mode) {
			this.touch_mode = true;
			this.touch_seen.emit();
		}
		if (point.x < size.x * STICK_SHARE) {
			if (!this.touch_mode) return;
			this._finger = finger;
			this._aim(point);
		} else if (point.y < size.y * 0.5) {
			this.pass_pressed.emit();
		} else {
			this.shoot_pressed.emit();
		}
	}

	_aim(point) {
		const centre = this._stick_centre();
		const radius = this._stick_radius();
		let x = (point.x - centre.x) / radius;
		let y = (point.y - centre.y) / radius;
		const length = Math.hypot(x, y);
		if (length < DEAD_ZONE) {
			x = 0;
			y = 0;
		} else if (length > 1) {
			x /= length;
			y /= length;
		}
		this._direction = {x, y};
		this.stick_moved.emit(this._direction);
		this.queue_redraw();
	}

	_let_go() {
		if (this._finger === NO_FINGER) return;
		this._finger = NO_FINGER;
		this._direction = {x: 0, y: 0};
		this.stick_moved.emit(this._direction);
		this.queue_redraw();
	}

	_stick_centre() {
		const size = this.size;
		return {x: size.x * STICK_SHARE * 0.5, y: size.y * 0.5};
	}

	_stick_radius() {
		const size = this.size;
		return Math.min(size.x * STICK_SHARE, size.y) * 0.5;
	}

	draw(p) {
		const size = this.size;
		if (this.touch_mode) {
			const centre = this._stick_centre();
			const radius = this._stick_radius();
			p.circle(centre.x, centre.y, radius, STICK_COLOR);
			p.circle(centre.x + this._direction.x * radius * 0.6, centre.y + this._direction.y * radius * 0.6, radius * 0.4, KNOB_COLOR);
		} else {
			p.multiline_text(0, 30, this.keys_text, size.x * STICK_SHARE, KEYS_FONT_SIZE, TEXT_COLOR);
		}
		const left = size.x * STICK_SHARE;
		const half = size.y * 0.5;
		draw_button(p, left + 8, 0, size.x - left - 8, half - 4, this.pass_text, this.pass_enabled ? PASS_COLOR : DISABLED_COLOR);
		draw_button(p, left + 8, half + 4, size.x - left - 8, half - 4, this.shoot_text, this.shoot_enabled ? SHOOT_COLOR : DISABLED_COLOR);
	}
}

// The mouse is one finger; each touch is its own.
function finger_of(event) {
	return event.pointerType === "mouse" ? MOUSE_FINGER : event.pointerId;
}

function draw_button(p, x, y, width, height, text, color) {
	p.rect(x, y, width, height, color);
	// The baseline that puts the letters in the middle.
	p.text(x, y + height * 0.5 + FONT_SIZE * 0.36, text, FONT_SIZE, TEXT_COLOR, "center", width);
}
