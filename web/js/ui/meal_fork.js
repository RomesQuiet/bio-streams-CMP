// The meal minigame (Milestone 15): a fork with food swings over the avatar's mouth. A zone at
// the mouth shows where a tap is a bite, and turns bright when the fork is inside it. Short
// messages ("Yum!") show above it.
import {CanvasControl} from "./widgets.js";

const FORK_COLOR = [0.85, 0.87, 0.9];
const RING_COLOR = [1.0, 1.0, 1.0, 0.35];
const GOOD_COLOR = [0.5, 1.0, 0.6];
const OUTLINE_COLOR = [0.1, 0.1, 0.15];
const WHITE = [1, 1, 1];
const SWING = 230;
const HEIGHT_ABOVE_MOUTH = 34;
const HANDLE = 110;
const TINE = 22;
const FOOD_RADIUS = 16;
const ZONE_HEIGHT = 150;
const EVENT_FONT = 40;
const EVENT_SECONDS = 1.2;

export class MealFork extends CanvasControl {
	constructor(parent = null) {
		super(parent, "meal-fork");
		// Where the fork is, -1 to 1, and whether it is at the mouth.
		this.fork = 0;
		this.at_mouth = false;
		// How close to the mouth a tap is a bite, as a share of the swing.
		this.hit_share = 0;
		// The avatar's mouth, in this widget's coordinates.
		this.mouth = {x: 0, y: 0};
		this.food_color = [0.4, 0.75, 0.35];
		this._event_text = "";
		this._event_left = 0;
	}
	show_event(text) {
		this._event_text = text;
		this._event_left = EVENT_SECONDS;
	}
	_process(delta) {
		if (this.visible) {
			this._event_left -= delta;
			this.queue_redraw();
		}
	}
	draw(p) {
		const size = this.size;
		const half = this.hit_share * SWING;
		const zone = [this.mouth.x - half, this.mouth.y - ZONE_HEIGHT * 0.75, half * 2, ZONE_HEIGHT];
		p.rect(...zone, [...GOOD_COLOR, this.at_mouth ? 0.35 : 0.12]);
		p.rect(...zone, this.at_mouth ? GOOD_COLOR : RING_COLOR, false, 3);
		const tx = this.mouth.x + this.fork * SWING;
		const ty = this.mouth.y - HEIGHT_ABOVE_MOUTH;
		p.line(tx, ty, tx, ty - HANDLE, FORK_COLOR, 8);
		for (const side of [-1, 0, 1]) p.line(tx + side * 9, ty, tx + side * 9, ty + TINE, FORK_COLOR, 4);
		p.circle(tx, ty + TINE + FOOD_RADIUS * 0.6, FOOD_RADIUS, this.food_color);
		if (this._event_left > 0) {
			const y = this.mouth.y - HANDLE - HEIGHT_ABOVE_MOUTH - 30;
			p.text(0, y, this._event_text, EVENT_FONT, WHITE, "center", size.x, 8, OUTLINE_COLOR);
		}
	}
}
