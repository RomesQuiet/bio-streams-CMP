// The Beat bar of the cardio minigame (Milestone 12). A marker runs along the bar from the last
// tap, and the player taps when it is in the green zone. It turns red after a tap off the beat.
// Meal (Milestone 15): the Tummy bar, with its green zone.
import {CanvasControl} from "./widgets.js";

const BACKGROUND_COLOR = [0.11, 0.13, 0.18];
const ZONE_COLOR = [0.3, 0.7, 0.4];
const MARKER_COLOR = [0.95, 0.95, 0.9];
const MISS_COLOR = [0.95, 0.5, 0.4];
const LEVEL_COLOR = [0.95, 0.65, 0.3];
const MARKER_WIDTH = 8;
// How many intervals the whole bar shows, so the green zone is not at the very end.
const SPAN = 1.5;

export class BeatBar extends CanvasControl {
	constructor(parent = null) {
		super(parent, "beat-bar", {x: 672, y: 36});
		// Time since the last tap, as a share of the interval.
		this._elapsed = 0;
		// Half the width of the green zone, as a share of the interval.
		this._zone = 0;
		this._on_beat = true;
		// Meal: the level, and the green zone from zone_from to zone_to, as shares of the bar.
		this._level = -1;
		this._zone_from = 0;
		this._zone_to = 0;
	}
	show_level(level, zone_from, zone_to) {
		this._level = level;
		this._zone_from = zone_from;
		this._zone_to = zone_to;
		this.queue_redraw();
	}
	show_time(elapsed, zone, on_beat) {
		this._level = -1;
		this._elapsed = elapsed;
		this._zone = zone;
		this._on_beat = on_beat;
		this.queue_redraw();
	}
	draw(p) {
		const size = this.size;
		p.rect(0, 0, size.x, size.y, BACKGROUND_COLOR);
		if (this._level >= 0) {
			p.rect(this._zone_from * size.x, 0, (this._zone_to - this._zone_from) * size.x, size.y, ZONE_COLOR);
			p.rect(0, size.y * 0.25, Math.min(this._level, 1) * size.x, size.y * 0.5, LEVEL_COLOR);
			return;
		}
		p.rect(((1 - this._zone) / SPAN) * size.x, 0, ((2 * this._zone) / SPAN) * size.x, size.y, ZONE_COLOR);
		const x = Math.min(this._elapsed / SPAN, 1) * size.x;
		p.rect(x - MARKER_WIDTH * 0.5, 0, MARKER_WIDTH, size.y, this._on_beat ? MARKER_COLOR : MISS_COLOR);
	}
}
