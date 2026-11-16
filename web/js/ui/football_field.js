// The football field of the minigame (Milestone 14), drawn from above with placeholder shapes.
// The field explains the match by itself: arrows show the way to attack, the shot zone shows
// where a good shot starts, a line shows where a pass would go, rings show who is free and who
// can be tackled, a small map shows the whole field, and a line of text says what to do next.
import {CanvasControl} from "./widgets.js";

export const GRASS_COLOR = [0.2, 0.48, 0.28];
const STRIPE_COLOR = [0.23, 0.52, 0.31];
const LINE_COLOR = [0.9, 0.95, 0.9, 0.8];
export const TEAM_COLOR = [0.25, 0.5, 0.95];
export const YOU_COLOR = [1.0, 0.85, 0.3];
export const OTHER_COLOR = [0.9, 0.3, 0.3];
export const BALL_COLOR = [1, 1, 1];
export const GOOD_COLOR = [0.5, 1.0, 0.6];
const WARN_COLOR = [1.0, 0.7, 0.3];
export const OUTLINE_COLOR = [0.1, 0.1, 0.15];
const BANNER_COLOR = [0.05, 0.07, 0.1, 0.75];
const GRAY = [0.75, 0.75, 0.75];
const WHITE = [1, 1, 1];

const PLAYER_RADIUS = 17;
const YOU_RADIUS = 22;
const BALL_RADIUS = 8;
const LINE_WIDTH = 3;
// Field units the ball is drawn ahead of the player who has it.
const BALL_LEAD = 1.2;
const GOAL_WIDTH = 10;
const GOAL_DEPTH = 14;
const STRIPES = 6;
// Share of the view below the avatar.
const VIEW_BELOW = 0.4;
// Screen pixels kept around the field at each end.
const VIEW_MARGIN = 24;
const CAMERA_SPEED = 5;
// Share of the way from the avatar to the ball that the view looks at.
const CAMERA_TO_BALL = 0.3;
const MAP_SIZE = {x: 84, y: 126};
const MAP_MARGIN = 8;
const HINT_HEIGHT = 44;
const HINT_FONT = 24;
const EVENT_FONT = 44;
const EVENT_SECONDS = 1.6;
const NAME_FONT = 18;
const TAU = Math.PI * 2;

export class FootballField extends CanvasControl {
	constructor(parent = null) {
		super(parent, "football-field");
		this.game = null;
		// What the player should do now, already translated.
		this.hint = "";
		// The label over the avatar, already translated.
		this.you_text = "";
		this._camera = -1;
		this._pulse = 0;
		this._event_text = "";
		this._event_left = 0;
	}

	// Shows a short message in the middle of the field.
	show_event(text) {
		this._event_text = text;
		this._event_left = EVENT_SECONDS;
	}

	_process(delta) {
		if (!this.visible || this.game === null) return;
		this._pulse += delta;
		this._event_left -= delta;
		const wanted = lerp(this.game.positions[0].y, this.game.ball.y, CAMERA_TO_BALL);
		this._camera = this._camera < 0 ? wanted : lerp(this._camera, wanted, Math.min(1, delta * CAMERA_SPEED));
		this.queue_redraw();
	}

	draw(p) {
		const size = this.size;
		p.rect(0, 0, size.x, size.y, GRASS_COLOR);
		if (this.game === null) return;
		const scale_x = size.x / this.game.width;
		const ground = this._ground_y(scale_x, size);
		this._draw_grass(p, size, scale_x, ground);
		this._draw_lines(p, size, scale_x, ground);
		this._draw_shot_zone(p, scale_x, ground);
		this._draw_pass_line(p, scale_x, ground);
		this._draw_players(p, scale_x, ground);
		this._draw_ball(p, scale_x, ground);
		this._draw_map(p);
		this._draw_banner(p, size);
	}

	_draw_grass(p, size, scale_x, ground) {
		const stripe = (this.game.length / STRIPES) * scale_x;
		for (let i = 0; i < STRIPES; i += 2) p.rect(0, ground - stripe * (i + 1), size.x, stripe, STRIPE_COLOR);
		// Arrows up the field: this is the way to attack.
		for (const share of [0.3, 0.5, 0.7]) {
			const tip = this._screen({x: this.game.width * 0.5, y: this.game.length * share}, scale_x, ground);
			p.polyline([[tip.x - 46, tip.y + 30], [tip.x, tip.y], [tip.x + 46, tip.y + 30]], [1, 1, 1, 0.16], 12);
		}
	}

	_draw_lines(p, size, scale_x, ground) {
		const middle = this._screen({x: 0, y: this.game.length * 0.5}, scale_x, ground).y;
		p.line(0, middle, size.x, middle, LINE_COLOR, LINE_WIDTH);
		p.ring(size.x * 0.5, middle, size.x * 0.15, LINE_COLOR, LINE_WIDTH);
		this._draw_goal(p, size, this._screen({x: this.game.width * 0.5, y: this.game.length}, scale_x, ground), scale_x, OTHER_COLOR, -1);
		this._draw_goal(p, size, this._screen({x: this.game.width * 0.5, y: 0}, scale_x, ground), scale_x, TEAM_COLOR, 1);
	}

	// side: -1 for the goal at the top of the screen, 1 for the one at the bottom.
	_draw_goal(p, size, centre, scale_x, color, side) {
		p.line(0, centre.y, size.x, centre.y, LINE_COLOR, LINE_WIDTH);
		const half = GOAL_WIDTH * scale_x * 0.5;
		const top = side > 0 ? centre.y : centre.y - GOAL_DEPTH;
		p.rect(centre.x - half, top, half * 2, GOAL_DEPTH, color);
		p.rect(centre.x - half, top, half * 2, GOAL_DEPTH, LINE_COLOR, false, LINE_WIDTH);
	}

	// The area where a shot is good, on the other team's side.
	_draw_shot_zone(p, scale_x, ground) {
		const game = this.game;
		const goal = this._screen({x: game.width * 0.5, y: game.length}, scale_x, ground);
		const radius = game.shot_range * scale_x;
		const inside = (game.has_ball() && game.in_shot_range()) || game.team_mate_in_shot_range();
		const points = [[goal.x, goal.y]];
		for (let i = 0; i < 33; i++) {
			const angle = (Math.PI * i) / 32;
			points.push([goal.x + Math.cos(angle) * radius, goal.y + Math.sin(angle) * radius]);
		}
		p.polygon(points, [...GOOD_COLOR, inside ? 0.32 : 0.12]);
		p.arc(goal.x, goal.y, radius, 0, Math.PI, [...GOOD_COLOR, 0.8], LINE_WIDTH);
	}

	// With the ball: a line to the team-mate who would get a pass.
	_draw_pass_line(p, scale_x, ground) {
		const game = this.game;
		if (!game.has_ball()) return;
		const receiver = game.best_receiver();
		const from = this._screen(game.positions[0], scale_x, ground);
		const to = this._screen(game.positions[receiver], scale_x, ground);
		p.dashed_line(from.x, from.y, to.x, to.y, game.is_free(receiver) ? GOOD_COLOR : WARN_COLOR, LINE_WIDTH, 14);
	}

	_draw_players(p, scale_x, ground) {
		const game = this.game;
		// Backwards, so the avatar (player 0) is drawn on top.
		for (let i = game.positions.length - 1; i > 0; i--) {
			const point = this._screen(game.positions[i], scale_x, ground);
			const ours = i < game.team_size;
			const color = ours ? TEAM_COLOR : OTHER_COLOR;
			// A player who lost a tackle looks faded until it can move again.
			draw_egg(p, point, PLAYER_RADIUS, game.is_beaten(i) ? mix(color, GRAY, 0.6) : color);
			if (ours && game.is_free(i)) p.ring(point.x, point.y, PLAYER_RADIUS * 1.6, GOOD_COLOR, LINE_WIDTH);
			if (i === game.owner && !ours) {
				p.ring(point.x, point.y, PLAYER_RADIUS * 1.6, game.in_tackle_reach() ? GOOD_COLOR : WARN_COLOR, LINE_WIDTH + 2);
			}
		}
		const you = this._screen(game.positions[0], scale_x, ground);
		draw_egg(p, you, YOU_RADIUS, YOU_COLOR);
		// A bouncing marker and a name, so the player finds the avatar at once.
		const top = you.y - YOU_RADIUS * 1.2 - 10 - Math.abs(Math.sin(this._pulse * 4)) * 8;
		p.polygon([[you.x, top], [you.x - 11, top - 15], [you.x + 11, top - 15]], YOU_COLOR);
		p.text(you.x - 60, top - 20, this.you_text, NAME_FONT, YOU_COLOR, "center", 120, 5, OUTLINE_COLOR);
	}

	_draw_ball(p, scale_x, ground) {
		const game = this.game;
		const at = {x: game.ball.x, y: game.ball.y};
		if (game.owner !== -1) at.y += game.owner < game.team_size ? BALL_LEAD : -BALL_LEAD;
		const point = this._screen(at, scale_x, ground);
		p.circle(point.x, point.y, BALL_RADIUS, BALL_COLOR);
		p.ring(point.x, point.y, BALL_RADIUS, OUTLINE_COLOR, 2);
	}

	// The whole field, small, in a corner: the view only shows part of it.
	_draw_map(p) {
		const game = this.game;
		const corner = {x: MAP_MARGIN, y: MAP_MARGIN};
		p.rect(corner.x, corner.y, MAP_SIZE.x, MAP_SIZE.y, [...GRASS_COLOR, 0.85]);
		p.rect(corner.x, corner.y, MAP_SIZE.x, MAP_SIZE.y, LINE_COLOR, false, 2);
		const half_goal = ((MAP_SIZE.x * GOAL_WIDTH) / game.width) * 0.5;
		const middle = corner.x + MAP_SIZE.x * 0.5;
		p.line(middle - half_goal, corner.y, middle + half_goal, corner.y, OTHER_COLOR, 5);
		p.line(middle - half_goal, corner.y + MAP_SIZE.y, middle + half_goal, corner.y + MAP_SIZE.y, TEAM_COLOR, 5);
		for (let i = game.positions.length - 1; i > 0; i--) {
			const point = this._on_map(game.positions[i], corner);
			p.circle(point.x, point.y, 4, i < game.team_size ? TEAM_COLOR : OTHER_COLOR);
		}
		const you = this._on_map(game.positions[0], corner);
		p.circle(you.x, you.y, 6, YOU_COLOR);
		const ball = this._on_map(game.ball, corner);
		p.circle(ball.x, ball.y, 3, BALL_COLOR);
	}

	_on_map(point, corner) {
		return {x: corner.x + (point.x / this.game.width) * MAP_SIZE.x, y: corner.y + (1 - point.y / this.game.length) * MAP_SIZE.y};
	}

	_draw_banner(p, size) {
		if (this.hint !== "") {
			p.rect(0, size.y - HINT_HEIGHT, size.x, HINT_HEIGHT, BANNER_COLOR);
			p.text(0, size.y - 13, this.hint, HINT_FONT, WHITE, "center", size.x);
		}
		if (this._event_left > 0) p.text(0, size.y * 0.45, this._event_text, EVENT_FONT, WHITE, "center", size.x, 8, OUTLINE_COLOR);
	}

	// Screen y of field y = 0: the view looks at the camera and keeps the field on screen.
	_ground_y(scale_x, size) {
		const total = this.game.length * scale_x;
		const lowest = size.y - VIEW_MARGIN;
		const highest = VIEW_MARGIN + GOAL_DEPTH + total;
		const wanted = size.y * (1 - VIEW_BELOW) + Math.max(this._camera, 0) * scale_x;
		return Math.min(Math.max(wanted, lowest), Math.max(lowest, highest));
	}

	_screen(point, scale_x, ground) {
		return {x: point.x * scale_x, y: ground - point.y * scale_x};
	}
}

// An egg seen from above. Also used by the first-time explanation.
export function draw_egg(p, centre, radius, color) {
	const points = [];
	for (let i = 0; i < 24; i++) {
		const angle = (TAU * i) / 24;
		points.push([centre.x + Math.cos(angle) * radius, centre.y + Math.sin(angle) * radius * 1.2]);
	}
	p.polygon(points, color);
	p.polyline([...points, points[0]], OUTLINE_COLOR, 2);
}

function lerp(from, to, weight) {
	return from + (to - from) * weight;
}

function mix(a, b, weight) {
	return [0, 1, 2].map((i) => lerp(a[i], b[i], weight));
}
