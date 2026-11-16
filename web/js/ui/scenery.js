// The place behind the avatar during an activity ("scenery" in data/activities.json; user,
// 7 Nov 2026): "outside" is only the sky and the ground, "room" a wall with windows that show
// the sky (day or night), "bedroom" a grey floor and a bed seen from above: the avatar faces the
// player, so from above it lies on its back, its head on the pillow, and a blanket covers it
// from the chest down. The blanket is drawn by a second Scenery in front of the avatar
// (front = true). The grey ground is a separate element. Placeholder art, drawn with shapes.
import {CanvasControl} from "./widgets.js";

export const OUTSIDE = "outside";
export const ROOM = "room";
export const BEDROOM = "bedroom";

const WALL_COLOR = [0.86, 0.8, 0.68];
const SKIRTING_COLOR = [0.62, 0.55, 0.45];
const FRAME_COLOR = [0.97, 0.97, 0.95];
const STAR_COLOR = [1.0, 1.0, 0.85];
// The bedroom floor: the same grey as the ground, so the whole place is floor.
const FLOOR_COLOR = [0.5, 0.5, 0.52];
const BED_FRAME_COLOR = [0.38, 0.38, 0.41];
const MATTRESS_COLOR = [0.92, 0.92, 0.93];
const PILLOW_COLOR = [1.0, 1.0, 1.0];
const BLANKET_COLOR = [0.7, 0.7, 0.74];
const BLANKET_FOLD_COLOR = [0.84, 0.84, 0.87];
const OUTLINE_COLOR = [0.1, 0.1, 0.12];
// Where the ground line is, from the bottom of this widget (the ground element).
const GROUND_FROM_BOTTOM = 60;
const WINDOW_WIDTH = 130;
const WINDOW_HEIGHT = 230;
const WINDOW_TOP = 440;
const WINDOW_SIDE = 24;
const FRAME = 10;
const SKIRTING = 16;
// The bed around the avatar's picture: how much wider than it, and how far above its top.
const BED_SIDE = 40;
const BED_ABOVE = 36;
const BED_FRAME = 14;
// The pillow is under the head (seen from above): it ends just below the chin, by this share of
// the avatar's height under the mouth, and reaches up to PILLOW_HEIGHT, staying on the mattress.
const PILLOW_WIDTH = 290;
const PILLOW_HEIGHT = 190;
const PILLOW_BELOW_MOUTH = 0.06;
// Where the blanket starts: below the mouth, by this share of the avatar's height.
const CHEST_BELOW_MOUTH = 0.13;
const FOLD = 34;
// The floor also covers the screen's margins and the top bar around this widget.
const FLOOR_BEYOND = 400;
// The stars in the windows at night, as shares of a window.
const STARS = [[0.2, 0.15], [0.7, 0.3], [0.35, 0.6], [0.8, 0.75], [0.15, 0.85]];
const PILLOW_RADIUS = 30;
const PILLOW_BORDER = 3;

export class Scenery extends CanvasControl {
	// front: the second one, in front of the avatar: only the blanket.
	constructor(parent = null, classes = "", front = false) {
		super(parent, "scenery " + classes, {x: 0, y: 0}, front ? 0 : FLOOR_BEYOND);
		this.front = front;
		// The avatar, for where the bed and the blanket go (set by the main screen).
		this.avatar = null;
		this._kind = "";
		this._sky_color = [0, 0, 0, 1];
		this._daylight = 1;
	}
	get kind() {
		return this._kind;
	}
	set kind(value) {
		if (value === this._kind) return;
		this._kind = value;
		this.queue_redraw();
	}
	// The sky seen through the windows, and how much daylight there is (0 night, 1 day).
	get sky_color() {
		return this._sky_color;
	}
	set sky_color(value) {
		if (String(value) === String(this._sky_color)) return;
		this._sky_color = value;
		this.queue_redraw();
	}
	get daylight() {
		return this._daylight;
	}
	set daylight(value) {
		if (value === this._daylight) return;
		this._daylight = value;
		this.queue_redraw();
	}

	draw(p) {
		const size = this.size;
		const ground = size.y - GROUND_FROM_BOTTOM;
		if (this.front) {
			if (this._kind === BEDROOM && this.avatar) this._draw_blanket(p, ground);
			return;
		}
		if (this._kind === ROOM) this._draw_room(p, size, ground);
		else if (this._kind === BEDROOM) this._draw_bedroom(p, size, ground);
	}

	// A wall from the top to the ground, with one window on each side of the avatar.
	_draw_room(p, size, ground) {
		p.rect(0, 0, size.x, ground, WALL_COLOR);
		p.rect(0, ground - SKIRTING, size.x, SKIRTING, SKIRTING_COLOR);
		for (const left of [WINDOW_SIDE, size.x - WINDOW_SIDE - WINDOW_WIDTH]) {
			this._draw_window(p, left, ground - WINDOW_TOP, WINDOW_WIDTH, WINDOW_HEIGHT);
		}
	}

	_draw_window(p, x, y, width, height) {
		p.rect(x, y, width, height, this._sky_color);
		for (const [sx, sy] of STARS) p.circle(x + sx * width, y + sy * height, 2.5, [...STAR_COLOR, 1 - this._daylight]);
		p.rect(x, y, width, height, FRAME_COLOR, false, FRAME);
		const mx = x + width / 2;
		const my = y + height / 2;
		p.line(mx, y, mx, y + height, FRAME_COLOR, FRAME * 0.6);
		p.line(x, my, x + width, my, FRAME_COLOR, FRAME * 0.6);
		const grow = FRAME * 0.5;
		p.rect(x - grow, y - grow, width + grow * 2, height + grow * 2, OUTLINE_COLOR, false, 2);
	}

	// The grey floor and the bed from above, its pillow under the avatar's head.
	_draw_bedroom(p, size, ground) {
		p.rect(-FLOOR_BEYOND, -FLOOR_BEYOND, size.x + FLOOR_BEYOND * 2, size.y + FLOOR_BEYOND * 2, FLOOR_COLOR);
		if (!this.avatar) return;
		const bed = this._bed(ground);
		draw_box(p, bed, BED_FRAME_COLOR);
		draw_box(p, grow(bed, -BED_FRAME), MATTRESS_COLOR);
		const avatar = avatar_rect(this.avatar);
		const bottom = avatar.y + this.avatar.mouth_point().y + avatar.h * PILLOW_BELOW_MOUTH;
		const top = Math.max(bottom - PILLOW_HEIGHT, bed.y + BED_FRAME * 2);
		p.box(bed.x + bed.w / 2 - PILLOW_WIDTH / 2, top, PILLOW_WIDTH, bottom - top, PILLOW_COLOR, PILLOW_RADIUS, PILLOW_BORDER, OUTLINE_COLOR);
	}

	// Over the avatar, from its chest over the foot of the bed (so the feet are covered), with
	// the top folded back.
	_draw_blanket(p, ground) {
		const bed = this._bed(ground);
		const avatar = avatar_rect(this.avatar);
		const top = avatar.y + this.avatar.mouth_point().y + avatar.h * CHEST_BELOW_MOUTH;
		const blanket = {x: bed.x + BED_FRAME, y: top, w: bed.w - BED_FRAME * 2, h: bed.y + bed.h - top};
		draw_box(p, blanket, BLANKET_COLOR);
		draw_box(p, {x: blanket.x, y: blanket.y, w: blanket.w, h: FOLD}, BLANKET_FOLD_COLOR);
	}

	// The bed: around the avatar's picture, from above its head to the ground line.
	_bed(ground) {
		const avatar = avatar_rect(this.avatar);
		const top = avatar.y - BED_ABOVE;
		return {x: avatar.x - BED_SIDE, y: top, w: avatar.w + BED_SIDE * 2, h: ground - top};
	}
}

// Where the avatar is in the stage (Godot's position and size).
function avatar_rect(avatar) {
	const size = avatar.size;
	return {x: avatar.node.offsetLeft || avatar.position?.x || 0, y: avatar.node.offsetTop || avatar.position?.y || 0, w: size.x, h: size.y};
}

function grow(box, by) {
	return {x: box.x - by, y: box.y - by, w: box.w + by * 2, h: box.h + by * 2};
}

function draw_box(p, box, color) {
	p.rect(box.x, box.y, box.w, box.h, color);
	p.rect(box.x, box.y, box.w, box.h, OUTLINE_COLOR, false, 3);
}
