// The pieces the screens are built from, behaving like the Godot nodes they replace: Label,
// Button, ProgressBar, HSlider, PanelContainer and a canvas for drawn things (Godot's _draw()).
// Texts are kept as written (often a key of translations/strings.csv) and shown translated, so
// they follow the language by themselves, as Godot's node texts do.
import {tr} from "../core/translation.js";
import {Signal} from "../core/util.js";
import {Scene} from "./scene.js";

// A new element with CSS classes, added to parent (an element or a widget) when given.
export function el(tag, classes = "", parent = null) {
	const node = document.createElement(tag);
	if (classes) node.className = classes;
	if (parent) (parent.node ?? parent).appendChild(node);
	return node;
}

export class Control {
	constructor(parent = null, classes = "", tag = "div") {
		this.node = el(tag, classes, parent);
		this.node._widget = this;
		this._visible = true;
		this._alpha = 1;
	}
	get visible() {
		return this._visible;
	}
	set visible(value) {
		this._visible = Boolean(value);
		this.node.style.display = this._visible ? "" : "none";
	}
	show() {
		this.visible = true;
	}
	hide() {
		this.visible = false;
	}
	// Godot's modulate.a.
	get alpha() {
		return this._alpha;
	}
	set alpha(value) {
		this._alpha = value;
		this.node.style.opacity = String(value);
	}
	// Godot's tooltip_text.
	set tooltip(key) {
		this._tooltip = key;
		this.render();
	}
	render() {
		if (this._tooltip) this.node.title = tr(this._tooltip);
	}
	// Godot's get_index(): the place among its parent's children.
	get_index() {
		return [...this.node.parentNode.children].indexOf(this.node);
	}
	// The widgets inside, in order (Godot's get_children()).
	get_children() {
		return [...this.node.children].map((node) => node._widget ?? node);
	}
	clear_children() {
		this.node.replaceChildren();
	}
	set_class(name, on) {
		this.node.classList.toggle(name, Boolean(on));
	}
	// The size on screen in game pixels (fallback: the size it is meant to have).
	get size() {
		const width = this.node.offsetWidth || this.default_size?.x || 0;
		const height = this.node.offsetHeight || this.default_size?.y || 0;
		return {x: width, y: height};
	}
}

// A text. wrap: Godot's autowrap; otherwise the text stays on its lines.
export class Label extends Control {
	constructor(parent = null, text = "", classes = "") {
		super(parent, "label " + classes);
		this._text = "";
		this.text = text;
	}
	get text() {
		return this._text;
	}
	set text(value) {
		this._text = String(value);
		this.render();
	}
	render() {
		super.render();
		this.node.textContent = tr(this._text);
	}
	// Godot's font_color override.
	set color(css) {
		this._color = css;
		this.node.style.color = css;
	}
	get color() {
		return this._color;
	}
}

export class Button extends Control {
	constructor(parent = null, text = "", classes = "") {
		super(parent, "btn " + classes, "button");
		this.node.type = "button";
		// Emitted on a click (Godot's pressed) and as soon as it is pressed down (button_down).
		this.pressed = new Signal();
		this.button_down = new Signal();
		this.toggle_mode = false;
		this._button_pressed = false;
		this._disabled = false;
		this._text = "";
		this._label = el("span", "btn-text", this.node);
		this.text = text;
		this.node.addEventListener("click", () => this._click());
		this.node.addEventListener("pointerdown", (event) => {
			if (!this._disabled && event.button === 0) this.button_down.emit();
		});
		// A button never keeps the keyboard: Space and the arrow keys belong to the game.
		this.node.addEventListener("focus", () => this.node.blur());
	}
	_click() {
		if (this._disabled) return;
		if (this.toggle_mode) this.button_pressed = !this._button_pressed;
		this.pressed.emit();
	}
	get text() {
		return this._text;
	}
	set text(value) {
		this._text = String(value);
		this.render();
	}
	render() {
		super.render();
		this._label.textContent = tr(this._text);
	}
	get disabled() {
		return this._disabled;
	}
	set disabled(value) {
		this._disabled = Boolean(value);
		this.node.disabled = this._disabled;
	}
	get button_pressed() {
		return this._button_pressed;
	}
	set button_pressed(value) {
		this._button_pressed = Boolean(value);
		this.set_class("pressed", this._button_pressed);
	}
	set_pressed_no_signal(value) {
		this.button_pressed = value;
	}
	// An icon drawn in the text colour (assets/art/ui/*.svg as a mask).
	set icon(url) {
		const icon = el("span", "btn-icon", this.node);
		icon.style.maskImage = `url("${url}")`;
		icon.style.webkitMaskImage = `url("${url}")`;
		this.node.insertBefore(icon, this._label);
	}
}

// Godot's ProgressBar: a fill from min_value to max_value. variation: "" (grey), "xp", "health"
// or "danger" (Godot's theme type variations).
export class ProgressBar extends Control {
	constructor(parent = null, classes = "", min_value = 0, max_value = 1) {
		super(parent, "bar " + classes);
		el("div", "bar-empty", this.node);
		this._fill = el("div", "bar-fill", this.node);
		this.min_value = min_value;
		this.max_value = max_value;
		this._variation = "";
		this._value = min_value;
		this.value = min_value;
	}
	get value() {
		return this._value;
	}
	set value(value) {
		this._value = Math.min(Math.max(value, this.min_value), this.max_value);
		const ratio = this.max_value > this.min_value ? (this._value - this.min_value) / (this.max_value - this.min_value) : 0;
		// As Godot draws it: nothing when empty, otherwise at least the border.
		this._fill.style.display = ratio > 0 ? "" : "none";
		this._fill.style.width = `calc(var(--bar-border) * 2 + ${ratio} * (100% - var(--bar-border) * 2))`;
	}
	get theme_type_variation() {
		return this._variation;
	}
	set theme_type_variation(name) {
		if (this._variation) this.node.classList.remove("bar-" + this._variation);
		this._variation = name;
		if (name) this.node.classList.add("bar-" + name);
	}
}

// Godot's HSlider (a Range): the value stays between min_value and max_value, on the step, and
// value_changed is emitted when it changes, also when a script sets it.
export class HSlider extends Control {
	constructor(parent = null, classes = "") {
		super(parent, "slider " + classes, "input");
		this.node.type = "range";
		this.value_changed = new Signal();
		this._min = 0;
		this._max = 100;
		this._step = 1;
		this._value = 0;
		this.node.addEventListener("input", () => {
			this.value = Number(this.node.value);
		});
		this.node.addEventListener("focus", () => this.node.blur());
		this._update_node();
	}
	get min_value() {
		return this._min;
	}
	set min_value(value) {
		this._min = value;
		this._update_node();
		this.value = this._value;
	}
	get max_value() {
		return this._max;
	}
	set max_value(value) {
		this._max = value;
		this._update_node();
		this.value = this._value;
	}
	get step() {
		return this._step;
	}
	set step(value) {
		this._step = value;
		this._update_node();
		this.value = this._value;
	}
	get value() {
		return this._value;
	}
	set value(value) {
		let fixed = value;
		if (this._step > 0) fixed = Math.round((fixed - this._min) / this._step) * this._step + this._min;
		fixed = Math.min(Math.max(fixed, this._min), this._max);
		this.node.value = String(fixed);
		if (fixed === this._value) return;
		this._value = fixed;
		this.value_changed.emit(fixed);
	}
	_update_node() {
		this.node.min = String(this._min);
		this.node.max = String(this._max);
		this.node.step = this._step > 0 ? String(this._step) : "any";
	}
}

// Godot's PanelContainer: the dark rounded panel.
export class Panel extends Control {
	constructor(parent = null, classes = "") {
		super(parent, "panel " + classes);
	}
}

// A box of widgets in a column (VBoxContainer) or a row (HBoxContainer), with a gap.
export class Box extends Control {
	constructor(parent = null, classes = "", vertical = true, gap = 4) {
		super(parent, (vertical ? "vbox " : "hbox ") + classes);
		this.node.style.gap = gap + "px";
	}
}

// A drawn thing (Godot's _draw()): a canvas the size of this widget. draw(painter) draws it in
// game pixels; queue_redraw() asks for it at the end of the frame. bleed: how far drawing may go
// beyond the widget on every side (the bedroom's floor).
export class CanvasControl extends Control {
	constructor(parent = null, classes = "", default_size = {x: 0, y: 0}, bleed = 0) {
		super(parent, "canvas-control " + classes);
		this.default_size = default_size;
		this.bleed = bleed;
		this.canvas = el("canvas", "", this.node);
		if (bleed > 0) {
			this.canvas.style.left = -bleed + "px";
			this.canvas.style.top = -bleed + "px";
		}
		this._dirty = true;
		this._drawn = "";
		Scene._canvases.add(this);
	}
	queue_redraw() {
		this._dirty = true;
	}
	draw(_painter) {}
	_draw_if_needed() {
		if (!this._visible) return;
		const size = this.size;
		const ratio = Scene.pixel_ratio;
		const key = `${size.x}x${size.y}@${ratio}`;
		if (!this._dirty && key === this._drawn) return;
		this._dirty = false;
		this._drawn = key;
		const width = size.x + this.bleed * 2;
		const height = size.y + this.bleed * 2;
		this.canvas.width = Math.max(1, Math.round(width * ratio));
		this.canvas.height = Math.max(1, Math.round(height * ratio));
		this.canvas.style.width = width + "px";
		this.canvas.style.height = height + "px";
		const context = this.canvas.getContext("2d");
		if (!context) return;
		context.setTransform(ratio, 0, 0, ratio, this.bleed * ratio, this.bleed * ratio);
		context.clearRect(-this.bleed, -this.bleed, width, height);
		this.draw(new Painter(context, size));
	}
}

// Godot's Color as an array [r, g, b, a] of 0 to 1, written for the canvas.
export function css(color, alpha = 1) {
	const [r, g, b, a = 1] = color;
	return `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${a * alpha})`;
}

// The game's font, as on the rest of the page.
export const FONT = '"Open Sans", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
// Line height as a share of the font size (as in style.css).
export const LINE_HEIGHT = 1.36;

// Godot's drawing functions on a canvas, in game pixels.
export class Painter {
	constructor(context, size) {
		this.ctx = context;
		this.size = size;
		this._base = context.getTransform();
	}
	// Godot's draw_set_transform(position, rotation, scale).
	set_transform(x, y, scale_x = 1, scale_y = scale_x) {
		this.ctx.setTransform(this._base);
		this.ctx.translate(x, y);
		this.ctx.scale(scale_x, scale_y);
	}
	rect(x, y, width, height, color, filled = true, line_width = 1) {
		if (filled) {
			this.ctx.fillStyle = css(color);
			this.ctx.fillRect(x, y, width, height);
			return;
		}
		this.ctx.strokeStyle = css(color);
		this.ctx.lineWidth = line_width;
		this.ctx.strokeRect(x, y, width, height);
	}
	circle(x, y, radius, color) {
		this.ctx.fillStyle = css(color);
		this.ctx.beginPath();
		this.ctx.arc(x, y, radius, 0, Math.PI * 2);
		this.ctx.fill();
	}
	// An outline circle (Godot's draw_arc over a whole turn).
	ring(x, y, radius, color, line_width) {
		this.ctx.strokeStyle = css(color);
		this.ctx.lineWidth = line_width;
		this.ctx.beginPath();
		this.ctx.arc(x, y, radius, 0, Math.PI * 2);
		this.ctx.stroke();
	}
	// Godot's draw_arc: part of a circle's outline, from one angle to another (radians).
	arc(x, y, radius, start, end, color, line_width = 1) {
		this.ctx.strokeStyle = css(color);
		this.ctx.lineWidth = line_width;
		this.ctx.beginPath();
		this.ctx.arc(x, y, radius, start, end);
		this.ctx.stroke();
	}
	// Godot's draw_dashed_line: dashes and gaps of dash pixels.
	dashed_line(x1, y1, x2, y2, color, line_width, dash) {
		this.ctx.setLineDash([dash, dash]);
		this.line(x1, y1, x2, y2, color, line_width);
		this.ctx.setLineDash([]);
	}
	// Godot's draw_multiline_string: lines break at line breaks and at words within width.
	multiline_text(x, y, text, width, font_size, color) {
		this.ctx.font = `600 ${font_size}px ${FONT}`;
		const line_height = Math.round(font_size * LINE_HEIGHT);
		let at = y;
		for (const paragraph of String(text).split("\n")) {
			let line = "";
			for (const word of paragraph.split(" ")) {
				const next = line === "" ? word : line + " " + word;
				if (line !== "" && this.ctx.measureText(next).width > width) {
					this.text(x, at, line, font_size, color);
					at += line_height;
					line = word;
				} else {
					line = next;
				}
			}
			this.text(x, at, line, font_size, color);
			at += line_height;
		}
	}
	line(x1, y1, x2, y2, color, line_width = 1) {
		this.ctx.strokeStyle = css(color);
		this.ctx.lineWidth = line_width;
		this.ctx.lineCap = "butt";
		this.ctx.beginPath();
		this.ctx.moveTo(x1, y1);
		this.ctx.lineTo(x2, y2);
		this.ctx.stroke();
	}
	// points: [[x, y], ...]
	polyline(points, color, line_width = 1) {
		this.ctx.strokeStyle = css(color);
		this.ctx.lineWidth = line_width;
		this.ctx.lineJoin = "round";
		this.ctx.beginPath();
		points.forEach(([x, y], i) => (i === 0 ? this.ctx.moveTo(x, y) : this.ctx.lineTo(x, y)));
		this.ctx.stroke();
	}
	polygon(points, color) {
		this.ctx.fillStyle = css(color);
		this.ctx.beginPath();
		points.forEach(([x, y], i) => (i === 0 ? this.ctx.moveTo(x, y) : this.ctx.lineTo(x, y)));
		this.ctx.closePath();
		this.ctx.fill();
	}
	// Godot's draw_string: x, y is the start of the baseline. align: "left", "center" or "right"
	// within width (or at x when width is -1).
	text(x, y, text, font_size, color, align = "left", width = -1, outline = 0, outline_color = [0, 0, 0, 1]) {
		this.ctx.font = `600 ${font_size}px ${FONT}`;
		this.ctx.textBaseline = "alphabetic";
		let at = x;
		if (width >= 0 && align === "center") at = x + width / 2;
		if (width >= 0 && align === "right") at = x + width;
		this.ctx.textAlign = align;
		if (outline > 0) {
			this.ctx.strokeStyle = css(outline_color);
			this.ctx.lineWidth = outline;
			this.ctx.lineJoin = "round";
			this.ctx.strokeText(text, at, y);
		}
		this.ctx.fillStyle = css(color);
		this.ctx.fillText(text, at, y);
	}
	text_width(text, font_size) {
		this.ctx.font = `600 ${font_size}px ${FONT}`;
		return this.ctx.measureText(text).width;
	}
	// Godot's draw_texture_rect, with modulate as a tint (multiplied, as Godot does).
	image(image, x, y, width, height, tint = null) {
		if (!image || !image.complete || image.naturalWidth === 0) return;
		this.ctx.imageSmoothingQuality = "high";
		this.ctx.drawImage(tint ? tinted(image, tint) : image, x, y, width, height);
	}
	// A StyleBoxFlat: a rounded box with a border.
	box(x, y, width, height, fill, radius = 0, border = 0, border_color = [0, 0, 0, 1]) {
		const r = Math.min(radius, width / 2, height / 2);
		const path = () => {
			this.ctx.beginPath();
			if (this.ctx.roundRect) this.ctx.roundRect(x, y, width, height, r);
			else this.ctx.rect(x, y, width, height);
		};
		path();
		this.ctx.fillStyle = css(fill);
		this.ctx.fill();
		if (border > 0) {
			const half = border / 2;
			this.ctx.beginPath();
			if (this.ctx.roundRect) this.ctx.roundRect(x + half, y + half, width - border, height - border, Math.max(0, r - half));
			else this.ctx.rect(x + half, y + half, width - border, height - border);
			this.ctx.strokeStyle = css(border_color);
			this.ctx.lineWidth = border;
			this.ctx.stroke();
		}
	}
}

// A picture multiplied by a colour (Godot's modulate), made once per picture and colour.
const _tinted = new Map();
function tinted(image, tint) {
	const key = image.src + css(tint);
	if (_tinted.has(key)) return _tinted.get(key);
	const canvas = document.createElement("canvas");
	canvas.width = image.naturalWidth;
	canvas.height = image.naturalHeight;
	const context = canvas.getContext("2d");
	context.drawImage(image, 0, 0);
	context.globalCompositeOperation = "multiply";
	context.fillStyle = css(tint);
	context.fillRect(0, 0, canvas.width, canvas.height);
	context.globalCompositeOperation = "destination-in";
	context.drawImage(image, 0, 0);
	_tinted.set(key, canvas);
	return canvas;
}

// Pictures of the game (res:// paths of the Godot project), loaded once. Without a browser (the
// tests) there are none.
export const Assets = {
	// The folder that holds assets/ (set by app.js).
	base: "../",
	_images: new Map(),
	url(path) {
		return String(path).replace("res://", Assets.base);
	},
	// The picture, loading; on_load runs when it is ready (to draw it).
	image(path, on_load = null) {
		if (typeof Image === "undefined") return null;
		const url = Assets.url(path);
		let image = Assets._images.get(url);
		if (!image) {
			image = new Image();
			image.decoding = "async";
			image.src = url;
			Assets._images.set(url, image);
		}
		if (on_load && !image.complete) image.addEventListener("load", on_load, {once: true});
		return image;
	},
};
