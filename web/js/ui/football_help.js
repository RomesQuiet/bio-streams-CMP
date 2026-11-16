// The explanation of football (Milestone 14, decision 48). It opens the first time someone plays
// on this device, and again from the ? button. The texts are keys of translations/strings.csv.
import {Config} from "../core/config.js";
import {tr} from "../core/translation.js";
import {format, Signal} from "../core/util.js";
import {Control, Panel, Box, Label, Button, CanvasControl} from "./widgets.js";
import {draw_egg, YOU_COLOR, OTHER_COLOR, GOOD_COLOR, TEAM_COLOR, BALL_COLOR, OUTLINE_COLOR} from "./football_field.js";

const ROWS = [
	["you", "FOOTBALL_HELP_YOU"],
	["goal", "FOOTBALL_HELP_GOAL"],
	["free", "FOOTBALL_HELP_PASS"],
	["other", "FOOTBALL_HELP_TACKLE"],
	["breath", "FOOTBALL_HELP_BREATH"],
];
const ROW_HEIGHT = 72;
const ICON_WIDTH = 64;

export class FootballHelp extends Control {
	constructor(parent = null) {
		super(parent, "overlay football-help");
		this.closed = new Signal();
		const panel = new Panel(this, "help-panel");
		const content = new Box(panel, "help-content", true, 14);
		new Label(content, "FOOTBALL_HELP_TITLE", "title");
		for (const [kind, key] of ROWS) {
			const row = new Box(content, "help-row", false, 14);
			new FootballIcon(row, kind);
			text_label(row, key);
		}
		this._time_label = text_label(content, "");
		this._controls = text_label(content, "");
		this._controls.color = "rgb(255, 217, 77)";
		this._play = new Button(content, "FOOTBALL_HELP_PLAY", "help-play");
		this._play.pressed.connect(() => this._on_play());
		this.visible = false;
	}

	// touch: the player has a touch screen, so the joystick is explained and not the keys.
	open(touch) {
		this._time_label.text = format(tr("FOOTBALL_HELP_TIME"), [Config.get_int("minigame.football.time_slowdown")]);
		this._controls.text = touch ? "FOOTBALL_HELP_TOUCH" : "FOOTBALL_HELP_KEYS";
		this.show();
	}

	_on_play() {
		this.hide();
		this.closed.emit();
	}
}

function text_label(parent, key) {
	return new Label(parent, key, "wrap help-text");
}

// A small picture for the explanation, in the colours of the field.
class FootballIcon extends CanvasControl {
	constructor(parent, kind) {
		super(parent, "help-icon", {x: ICON_WIDTH, y: ROW_HEIGHT});
		// "you", "goal", "free", "other" or "breath".
		this.kind = kind;
	}
	draw(p) {
		const size = this.size;
		const c = {x: size.x * 0.5, y: size.y * 0.5};
		switch (this.kind) {
			case "you":
				draw_egg(p, c, 18, YOU_COLOR);
				break;
			case "goal":
				p.rect(c.x - 24, c.y - 18, 48, 12, OTHER_COLOR);
				p.arc(c.x, c.y - 6, 26, 0, Math.PI, GOOD_COLOR, 3);
				break;
			case "free":
				draw_egg(p, c, 14, TEAM_COLOR);
				p.ring(c.x, c.y, 23, GOOD_COLOR, 3);
				break;
			case "other":
				draw_egg(p, c, 14, OTHER_COLOR);
				p.circle(c.x, c.y + 18, 6, BALL_COLOR);
				break;
			case "breath":
				p.rect(c.x - 26, c.y - 8, 52, 16, OUTLINE_COLOR);
				p.rect(c.x - 24, c.y - 6, 32, 12, GOOD_COLOR);
				break;
		}
	}
}
