// A small placeholder picture of the avatar's request in the speech bubble (Milestone 16):
// a bed, a burger, an apple, a fork, a screen or a ball. Hidden when there is no request.
import {CanvasControl} from "./widgets.js";

const LINE = [0.95, 0.95, 0.9];
const BED_COLOR = [0.55, 0.65, 0.95];
const BUN_COLOR = [0.9, 0.62, 0.3];
const MEAT_COLOR = [0.45, 0.25, 0.15];
const LETTUCE_COLOR = [0.45, 0.8, 0.35];
const APPLE_COLOR = [0.85, 0.2, 0.2];
const LEAF_COLOR = [0.35, 0.75, 0.3];
const SCREEN_COLOR = [0.35, 0.75, 0.95];
const BALL_DARK = [0.1, 0.1, 0.12];
// The pictures are drawn for a 44-pixel box, then scaled to fit the real one.
const DRAWN_SIZE = 44;
const ICON_SIZE = {x: 60, y: 60};

export class RequestIcon extends CanvasControl {
	constructor(parent = null) {
		super(parent, "request-icon", ICON_SIZE);
		this._kind = "";
		this.visible = false;
	}
	// A request of health/requests.js ("tired", "fast_food", ...) or "" for none.
	get kind() {
		return this._kind;
	}
	set kind(value) {
		this._kind = value;
		this.visible = value !== "";
		this.queue_redraw();
	}
	draw(p) {
		const size = this.size;
		p.set_transform(size.x * 0.5, size.y * 0.5, Math.min(size.x, size.y) / DRAWN_SIZE);
		switch (this._kind) {
			case "tired":
				p.rect(-18, 0, 36, 8, BED_COLOR);
				p.rect(-18, -8, 4, 22, BED_COLOR);
				p.rect(-13, -6, 10, 6, LINE);
				p.text(2, -6, "z", 14, LINE);
				p.text(9, -13, "z", 11, LINE);
				break;
			case "fast_food":
				p.circle(0, -2, 16, BUN_COLOR);
				p.rect(-17, 2, 34, 4, LETTUCE_COLOR);
				p.rect(-17, 6, 34, 5, MEAT_COLOR);
				p.rect(-16, 11, 32, 5, BUN_COLOR);
				break;
			case "healthy":
				p.circle(-5, 3, 11, APPLE_COLOR);
				p.circle(5, 3, 11, APPLE_COLOR);
				p.line(0, -6, 2, -14, MEAT_COLOR, 3);
				p.circle(7, -13, 4, LEAF_COLOR);
				break;
			case "hungry":
				p.line(-6, -16, -6, 16, LINE, 3);
				for (const x of [-11, -6, -1]) p.line(x, -16, x, -6, LINE, 2);
				p.line(-11, -6, -1, -6, LINE, 2);
				p.line(8, -16, 8, 16, LINE, 3);
				p.circle(8, -9, 4, LINE);
				break;
			case "screens":
				p.rect(-18, -13, 36, 24, LINE, false, 3);
				p.rect(-15, -10, 30, 18, SCREEN_COLOR);
				p.line(-8, 16, 8, 16, LINE, 3);
				break;
			case "football":
				p.circle(0, 0, 15, LINE);
				p.circle(0, 0, 5, BALL_DARK);
				for (let i = 0; i < 5; i++) {
					const angle = (Math.PI * 2 * i) / 5 - Math.PI / 2;
					p.circle(Math.cos(angle) * 12, Math.sin(angle) * 12, 3, BALL_DARK);
				}
				break;
		}
	}
}
