// The avatar, filling this widget; the bottom of the widget is the ground.
// With a sheet (Milestone 16, data/avatar_art.json) it draws the team's art: one picture per body
// and face. Without one (before the avatar is created) it draws the placeholder egg.
import {Data} from "../core/data.js";
import {CanvasControl, Assets} from "./widgets.js";
import {create_tween, Trans, Ease} from "./scene.js";

// Where the egg's mouth is, as a share of the height.
const EGG_MOUTH_Y = 0.55;
// The avatar's size on screen (scenes/avatar/avatar.tscn).
export const AVATAR_SIZE = {x: 330, y: 450};

const LOOKS = {
	body_color: [0.98, 0.9, 0.75],
	outline_color: [0.35, 0.25, 0.2],
	eye_color: [0.15, 0.12, 0.1],
	point_count: 64,
	// Placeholder sleep animation: slow breathing (squash and stretch) in seconds per breath.
	breath_seconds: 2.4,
	breath_squash: {x: 1.04, y: 0.96},
	// Placeholder hop used by activities without their own animation yet.
	hop_seconds: 0.6,
	hop_height: 24,
	// Placeholder exercise animations: cardio is a fast, high hop; strength is a slow squat.
	cardio_seconds: 0.35,
	cardio_height: 36,
	// One stride of the cardio minigame while walking.
	walk_height: 12,
	strength_seconds: 1.4,
	strength_squash: {x: 1.08, y: 0.88},
	// Eating: a quick, small squash (chewing).
	eat_seconds: 0.5,
	eat_squash: {x: 1.03, y: 0.97},
	// Placeholder looks for the avatar states (Milestone 10 Task 8).
	thin_width: 0.85,
	overweight_width: 1.2,
	outline_width: 4,
	muscular_outline_width: 8,
	mouth_width: 0.16,
	mouth_curve: 0.03,
	// Placeholder Ill look (Milestone 10.5): a pale, greenish body.
	ill_color: [0.82, 0.88, 0.7],
	// The Ill look on the art: the drawing is tinted with this colour.
	ill_tint: [0.8, 0.95, 0.65],
};

export class AvatarView extends CanvasControl {
	constructor(parent = null, classes = "", size = AVATAR_SIZE) {
		super(parent, "avatar " + classes, size);
		this.looks = LOOKS;
		this._sheet = "";
		// The folder of the current sheet's pictures, or "" for the egg.
		this._folder = "";
		this._picture = null;
		this._mouth_y = EGG_MOUTH_Y;
		this._states = {};
		this._eyes_closed = false;
		this._hop_offset = 0;
		this._scale = {x: 1, y: 1};
		this._mouth_open = false;
		this._animation = null;
	}

	// The art sheet: "<age group>_<sex>", a key of "sheets" in data/avatar_art.json, or "" (or a
	// key that is not there) for the egg.
	get sheet() {
		return this._sheet;
	}
	set sheet(value) {
		if (value === this._sheet) return;
		this._sheet = value;
		this._load_sheet();
		this._load_picture();
		this.queue_redraw();
	}

	// Avatar states shown by the looks (AvatarStates.current()): "tired", "sad", "happy", "ill",
	// "thin", "overweight", "obese", "muscular". Muscular with fat shows the overweight body.
	get states() {
		return this._states;
	}
	set states(value) {
		if (same(value, this._states)) return;
		this._states = {...value};
		this._load_picture();
		this.queue_redraw();
	}

	get eyes_closed() {
		return this._eyes_closed;
	}
	set eyes_closed(value) {
		this._eyes_closed = value;
		this._load_picture();
		this.queue_redraw();
	}

	// How far the avatar is drawn above the ground during hops.
	get hop_offset() {
		return this._hop_offset;
	}
	set hop_offset(value) {
		this._hop_offset = value;
		this.queue_redraw();
	}

	// Godot's scale, around the middle of the feet.
	get scale() {
		return this._scale;
	}
	set scale(value) {
		this._scale = {x: value.x, y: value.y};
		this.queue_redraw();
	}

	// Meal minigame: the mouth opens when the fork is close.
	get mouth_open() {
		return this._mouth_open;
	}
	set mouth_open(value) {
		if (this._mouth_open === value) return;
		this._mouth_open = value;
		this.queue_redraw();
	}

	// Plays a repeating placeholder animation by name (from data/activities.json) until
	// stop_animation(). The art does not move (user, 6 Nov 2026): it only closes its eyes to sleep.
	play_animation(animation_name) {
		this.stop_animation();
		if (this.has_art()) {
			this.eyes_closed = animation_name === "sleep";
			return;
		}
		const l = this.looks;
		const tween = create_tween().set_loops().set_trans(Trans.SINE).set_ease(Ease.IN_OUT);
		this._animation = tween;
		const pair = (property, value, rest, seconds) => {
			tween.tween_property(this, property, value, seconds * 0.5);
			tween.tween_property(this, property, rest, seconds * 0.5);
		};
		const one = {x: 1, y: 1};
		if (animation_name === "sleep") {
			this.eyes_closed = true;
			pair("scale", l.breath_squash, one, l.breath_seconds);
		} else if (animation_name === "cardio") {
			pair("hop_offset", l.cardio_height, 0, l.cardio_seconds);
		} else if (animation_name === "strength") {
			pair("scale", l.strength_squash, one, l.strength_seconds);
		} else if (animation_name === "eat") {
			pair("scale", l.eat_squash, one, l.eat_seconds);
		} else {
			pair("hop_offset", l.hop_height, 0, l.hop_seconds);
		}
	}

	// One hop for one stride of the cardio minigame.
	stride(walking) {
		if (this.has_art()) return;
		this.stop_animation();
		const l = this.looks;
		this._animation = create_tween().set_trans(Trans.SINE).set_ease(Ease.IN_OUT);
		this._animation.tween_property(this, "hop_offset", walking ? l.walk_height : l.cardio_height, l.cardio_seconds * 0.5);
		this._animation.tween_property(this, "hop_offset", 0, l.cardio_seconds * 0.5);
	}

	// Meal minigame: a quick squash for a bite.
	chew() {
		if (this.has_art()) return;
		this._animation?.kill();
		const l = this.looks;
		this._animation = create_tween();
		this._animation.tween_property(this, "scale", l.eat_squash, l.eat_seconds * 0.5);
		this._animation.tween_property(this, "scale", {x: 1, y: 1}, l.eat_seconds * 0.5);
	}

	// Down or up for one press of the strength minigame.
	squat(down) {
		if (this.has_art()) return;
		this._animation?.kill();
		const l = this.looks;
		this._animation = create_tween().set_trans(Trans.SINE).set_ease(Ease.IN_OUT);
		this._animation.tween_property(this, "scale", down ? l.strength_squash : {x: 1, y: 1}, l.strength_seconds * 0.5);
	}

	stop_animation() {
		this._animation?.kill();
		this._animation = null;
		this.hop_offset = 0;
		this.scale = {x: 1, y: 1};
		this.eyes_closed = false;
	}

	// Where the mouth is, in this widget (the meal fork aims there).
	mouth_point() {
		const size = this.size;
		return {x: size.x * 0.5, y: size.y * this._mouth_y};
	}

	// The picture for the current states: x is the body column, y the face row
	// (data/avatar_art.json). Weight wins over muscles; asleep, tired and sad win over happy.
	frame() {
		const art = art_data();
		let body = "healthy";
		for (const state of ["obese", "overweight", "thin", "muscular"]) {
			if (this._states[state]) {
				body = state;
				break;
			}
		}
		let face = "neutral";
		if (this._eyes_closed) face = "asleep";
		else if (this._states.tired) face = "tired";
		else if (this._states.sad) face = "sad";
		else if (this._states.happy) face = "happy";
		return {x: art.columns.indexOf(body), y: art.rows.indexOf(face)};
	}

	// Whether the art is drawn (otherwise the egg).
	has_art() {
		return this._folder !== "";
	}

	// The picture of a body and face of the current sheet.
	picture_path(cell) {
		const art = art_data();
		return `${this._folder}/${art.columns[cell.x]}_${art.rows[cell.y]}.png`;
	}

	_load_sheet() {
		this._folder = "";
		this._mouth_y = EGG_MOUTH_Y;
		const entry = art_data().sheets[this._sheet];
		if (entry?.folder) {
			this._folder = entry.folder;
			this._mouth_y = Number(entry.mouth_y);
		}
	}

	_load_picture() {
		this._picture = this.has_art() ? Assets.image(this.picture_path(this.frame()), () => this.queue_redraw()) : null;
	}

	draw(p) {
		const size = this.size;
		// The scale is around the middle of the feet (Godot's pivot_offset).
		const sx = this._scale.x;
		const sy = this._scale.y;
		p.set_transform(size.x * 0.5 * (1 - sx), size.y * (1 - sy) - this._hop_offset * sy, sx, sy);
		if (this.has_art()) {
			this._draw_art(p, size);
			return;
		}
		const l = this.looks;
		const points = this._egg_points(size);
		const fill = this._states.ill ? l.ill_color : l.body_color;
		p.polygon(points, fill);
		p.polyline([...points, points[0]], l.outline_color, this._states.muscular ? l.muscular_outline_width : l.outline_width);
		const eye_y = size.y * 0.42;
		const eye_radius = size.x * 0.05;
		for (const eye_x of [size.x * 0.38, size.x * 0.62]) {
			if (this._eyes_closed) {
				p.line(eye_x - eye_radius, eye_y, eye_x + eye_radius, eye_y, l.eye_color, 4);
			} else {
				p.circle(eye_x, eye_y, eye_radius, l.eye_color);
				if (this._states.tired) {
					// Heavy eyelids: the top half of the eye is covered.
					p.rect(eye_x - eye_radius, eye_y - eye_radius, eye_radius * 2, eye_radius, fill);
					p.line(eye_x - eye_radius, eye_y, eye_x + eye_radius, eye_y, l.outline_color, 3);
				}
			}
		}
		if (!this._eyes_closed) this._draw_mouth(p, size, Boolean(this._states.sad));
	}

	// The picture for the current states, stretched over this widget, and an open mouth for the
	// meal minigame.
	_draw_art(p, size) {
		p.image(this._picture, 0, 0, size.x, size.y, this._states.ill ? this.looks.ill_tint : null);
		if (this._mouth_open && !this._eyes_closed) {
			const mouth = this.mouth_point();
			p.circle(mouth.x, mouth.y, size.x * this.looks.mouth_width * 0.3, this.looks.outline_color);
		}
	}

	// A small smile, or a frown when sad.
	_draw_mouth(p, size, sad) {
		const l = this.looks;
		const center = this.mouth_point();
		const half = size.x * l.mouth_width * 0.5;
		if (this._mouth_open) {
			p.circle(center.x, center.y, half * 0.7, l.outline_color);
			return;
		}
		const bend = size.y * l.mouth_curve * (sad ? -1 : 1);
		const mouth = [];
		for (let i = 0; i < 9; i++) {
			const t = (i / 8) * 2 - 1;
			mouth.push([center.x + t * half, center.y + bend * (1 - t * t)]);
		}
		p.polyline(mouth, l.outline_color, 3);
	}

	// Egg outline: an ellipse whose top half is taller and narrower than its bottom half.
	_egg_points(size) {
		const l = this.looks;
		const cx = size.x * 0.5;
		const cy = size.y * 0.58;
		const top_height = size.y * 0.58;
		const bottom_height = size.y * 0.42;
		let half_width = size.x * 0.5;
		if (this._states.thin) half_width *= l.thin_width;
		else if (this._states.overweight) half_width *= l.overweight_width;
		const points = [];
		for (let i = 0; i < l.point_count; i++) {
			const angle = (Math.PI * 2 * i) / l.point_count;
			const s = Math.sin(angle);
			const narrowing = 1 - 0.15 * Math.max(0, -s);
			const height = s > 0 ? bottom_height : top_height;
			points.push([cx + Math.cos(angle) * half_width * narrowing, cy + s * height]);
		}
		return points;
	}
}

// data/avatar_art.json.
export function art_data() {
	return Data.files.avatar_art ?? {columns: [], rows: [], sheets: {}};
}

function same(a, b) {
	const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
	for (const key of keys) if (a[key] !== b[key]) return false;
	return true;
}
