// A gauge for the failure screen's Details (user, 7 Nov 2026): a bar in the bars' style with
// the recommended zone in green and a marker where the avatar was. With split set, it is a
// bar of healthy (green) and fast-food (orange) meals instead.
import {CanvasControl} from "./widgets.js";

const ZONE_COLOR = [0.3, 0.75, 0.35, 0.6];
const HEALTHY_COLOR = [0.3, 0.75, 0.35];
const FAST_FOOD_COLOR = [0.9, 0.55, 0.25];
const MARKER_COLOR = [1, 1, 1];
const MARKER_LINE = [0.1, 0.1, 0.12];
const MARKER_RADIUS = 11;
// The bar's border (as the bars' style), kept clear of the zone and the meal colours.
const INSET = 4;
// The bars' empty part and border (style.css: .bar-empty), by day and at night.
const BAR_EMPTY = [0.22, 0.24, 0.29];
const BAR_BORDER = 3;
const BAR_RADIUS = 18;

export class HabitGauge extends CanvasControl {
	constructor(parent = null) {
		super(parent, "habit-gauge", {x: 556, y: 30});
		// The avatar's value, the recommended zone (zone_to < 0: no upper end) and the end of the scale.
		this.value = 0;
		this.zone_from = 0;
		this.zone_to = -1;
		this.scale_max = 1;
		// Meals instead: healthy and fast-food meals (split = true).
		this.split = false;
		this.healthy = 0;
		this.fast_food = 0;
	}

	draw(p) {
		const size = this.size;
		const night = Boolean(this.node.closest?.(".night"));
		p.box(0, 0, size.x, size.y, BAR_EMPTY, BAR_RADIUS, BAR_BORDER, night ? [1, 1, 1] : [0, 0, 0]);
		const inner = {x: INSET, y: INSET, w: size.x - INSET * 2, h: size.y - INSET * 2};
		if (this.split) {
			const meals = this.healthy + this.fast_food;
			if (meals > 0) {
				const healthy_width = (inner.w * this.healthy) / meals;
				p.rect(inner.x, inner.y, healthy_width, inner.h, HEALTHY_COLOR);
				p.rect(inner.x + healthy_width, inner.y, inner.w - healthy_width, inner.h, FAST_FOOD_COLOR);
			}
			return;
		}
		const share = (amount) => Math.min(Math.max(amount / this.scale_max, 0), 1);
		const top = this.zone_to >= 0 ? this.zone_to : this.scale_max;
		const left = inner.x + inner.w * share(this.zone_from);
		const right = inner.x + inner.w * share(top);
		p.rect(left, inner.y, right - left, inner.h, ZONE_COLOR);
		const x = inner.x + inner.w * share(this.value);
		p.circle(x, size.y * 0.5, MARKER_RADIUS, MARKER_COLOR);
		p.ring(x, size.y * 0.5, MARKER_RADIUS, MARKER_LINE, 3);
	}
}
