// The football match of the minigame (Milestone 14, decisions 39 to 51): the idea of classic
// arcade football, seen from above. The avatar's team attacks upwards (y grows). Player 0 is the
// avatar; the others are computer players. This module knows nothing about the screen or health.
// It runs in fixed steps with its own random generator, so a seed always plays the same match.
// Numbers are in Config (group minigame.football).
// A tackle always ends: the tackler wins the ball or fails, and whoever lost is beaten for a moment
// (pushed back, standing still), so two players can never keep taking the ball from each other.
// Blue computer players never tackle or shoot by themselves: they wait for the player's button.
import {Config} from "../core/config.js";
import {Signal} from "../core/util.js";
import {Vector2, RandomNumberGenerator, closest_point_to_segment} from "../core/vector2.js";

const NOBODY = -1;
const Flight = {NONE: 0, PASS: 1, SHOT: 2};

export class FootballMatch {
	static NOBODY = NOBODY;
	static Flight = Flight;

	constructor(seed_value) {
		// What just happened, for the player. Each is a key of translations/strings.csv.
		this.happened = new Signal();
		// A tackle ended. won: the tackler has the ball now.
		this.tackled = new Signal();
		// Every player: the avatar's team first, then the other team.
		this.positions = [];
		this.team_size = 0;
		this.width = 0;
		this.length = 0;
		// Who has the ball, or NOBODY while it flies or is loose.
		this.owner = NOBODY;
		this.ball = Vector2.ZERO;
		this.flight = Flight.NONE;
		this.goals_us = 0;
		this.goals_them = 0;
		// The direction the player wants, length 0 to 1.
		this.stick = Vector2.ZERO;
		// Set from FootballLoad.
		this.avatar_speed = 0;
		this.free_distance = 0;
		this.shot_range = 0;
		// Who made the last tackle the button asked for, or NOBODY.
		this.last_tackler = NOBODY;
		this._rng = new RandomNumberGenerator(seed_value);
		this._values = {};
		this._left = 0;
		this._decide_left = 0;
		this._tackle_left = 0;
		this._own_tackle_left = 0;
		this._receiver = NOBODY;
		this._ball_target = Vector2.ZERO;
		this._ball_speed = 0;
		this._shot_scores = false;
		this._shooter_team = 0;
		// Real seconds left of the stop after a goal or a miss.
		this._pause_left = 0;
		// Real seconds in which a player who just got the ball cannot be tackled.
		this._safe_left = 0;
		// Real seconds each player is still beaten after losing a tackle.
		this._beaten_left = [];
		// Defender -> the attacker it marks, worked out every step.
		this._marks = new Map();
		this.team_size = Config.get_int("minigame.football.team_size");
		this._formation = Config.get_value("minigame.football.formation");
		this.width = this._value("field_width");
		this.length = this._value("field_length");
		this._tick = this._value("tick_seconds");
		this.positions = new Array(this.team_size * 2).fill(null).map(() => Vector2.ZERO);
		this._beaten_left = new Array(this.positions.length).fill(0);
		this.kick_off(true);
	}

	// Everyone back to their places. The team that kicks off has the ball.
	// stop: the match stops for a moment first, so the player can see what happened.
	kick_off(ours, stop = false) {
		this._pause_left = stop ? this._value("restart_seconds") : 0;
		for (let i = 0; i < this.positions.length; i++) {
			this.positions[i] = this._home(i, false);
			this._beaten_left[i] = 0;
		}
		this.owner = ours ? 0 : this.team_size;
		this.ball = this.positions.at(this.owner).copy();
		this.flight = Flight.NONE;
		this._receiver = NOBODY;
		this._decide_left = this._value("cpu_decide_seconds");
		this._tackle_left = this._value("cpu_tackle_seconds");
		this._safe_left = this._value("protect_seconds");
	}

	// Real seconds passed. Runs whole steps, so the frame rate does not change the match.
	advance(seconds) {
		this._left += seconds * this._value("match_pace");
		while (this._left >= this._tick) {
			this._left -= this._tick;
			this._step(this._tick);
		}
	}

	has_ball() {
		return this.owner === 0;
	}

	// An opponent has the ball.
	defending() {
		return this.owner !== NOBODY && this._team(this.owner) === 1;
	}

	can_tackle() {
		return this.defending() && this._own_tackle_left <= 0;
	}

	// The player the button would use to tackle: the avatar if it is close enough, or the nearest
	// blue player who is, or NOBODY.
	tackler_in_reach() {
		if (!this.defending()) return NOBODY;
		const reach = this._value("tackle_reach");
		if (this.positions.at(0).distance_to(this.positions.at(this.owner)) <= reach) return 0;
		const nearest = this._nearest_computer(0, this.positions.at(this.owner));
		return this.positions.at(nearest).distance_to(this.positions.at(this.owner)) <= reach ? nearest : NOBODY;
	}

	in_tackle_reach() {
		return this.tackler_in_reach() !== NOBODY;
	}

	// A player lost a tackle a moment ago.
	is_beaten(player) {
		return this._beaten_left.at(player) > 0;
	}

	// A team-mate has the ball: the player can ask for it.
	team_mate_has_ball() {
		return this.owner > 0 && this.owner < this.team_size;
	}

	// A team-mate has the ball close enough to goal for a good shot.
	team_mate_in_shot_range() {
		return this.team_mate_has_ball() && this.positions.at(this.owner).distance_to(this._goal(0)) <= this.shot_range;
	}

	// An opponent is close to the avatar.
	under_pressure() {
		return this._nearest_distance(0, 1) < this._value("cpu_press_radius");
	}

	// The match is stopped for a moment after a goal or a miss.
	stopped() {
		return this._pause_left > 0;
	}

	// True if no opponent is within free_distance of this player.
	is_free(player) {
		return this._nearest_distance(player, 1 - this._team(player)) >= this.free_distance;
	}

	// True if the avatar is close enough to goal for a good shot.
	in_shot_range() {
		return this.positions.at(0).distance_to(this._goal(0)) <= this.shot_range;
	}

	// The team-mate a pass would go to: the one nearest the stick's direction, or the nearest.
	best_receiver() {
		let best = NOBODY;
		let best_value = -Infinity;
		for (let i = 1; i < this.team_size; i++) {
			const offset = this.positions.at(i).sub(this.positions.at(0));
			const value = this.stick.normalized().dot(offset.normalized()) * this.length - offset.length();
			if (value > best_value) {
				best_value = value;
				best = i;
			}
		}
		return best;
	}

	// The avatar passes. Returns true for a good pass: the team-mate was free.
	pass_ball() {
		if (!this.has_ball()) return false;
		const receiver = this.best_receiver();
		const good = this.is_free(receiver);
		this._pass_to(receiver);
		this.happened.emit(good ? "FOOTBALL_PASS_GOOD" : "FOOTBALL_PASS_MARKED");
		return good;
	}

	// The avatar asks the team-mate with the ball for a pass.
	call_for_ball() {
		if (this.team_mate_has_ball()) this._pass_to(0);
	}

	// The avatar shoots. Returns true for a good shot: it was in range.
	shoot() {
		if (!this.has_ball()) return false;
		const good = this.in_shot_range();
		if (!good) this.happened.emit("FOOTBALL_SHOT_FAR");
		this._shoot(this._shot_chance(0, good ? this._value("goal_chance_good") : this._value("goal_chance_far")));
		return good;
	}

	// The player pressed Shoot while a team-mate has the ball. Returns true for a good shot.
	team_mate_shoot() {
		if (!this.team_mate_has_ball()) return false;
		const good = this.team_mate_in_shot_range();
		if (!good) this.happened.emit("FOOTBALL_SHOT_FAR");
		this._shoot(this._shot_chance(this.owner, good ? this._value("goal_chance_good") : this._value("goal_chance_far")));
		return good;
	}

	// The player pressed Tackle, at most once per tackle time. The avatar tackles if it is close
	// enough, otherwise the nearest blue player who is. Returns true if someone was within reach,
	// a good tackle even if it does not always win the ball.
	tackle() {
		if (!this.can_tackle()) return false;
		this._own_tackle_left = this._value("tackle_seconds");
		this.last_tackler = this.tackler_in_reach();
		if (this.last_tackler === NOBODY) {
			this.happened.emit("FOOTBALL_TACKLE_FAR");
			return false;
		}
		const won = this._resolve_tackle(this.last_tackler, this._value("tackle_chance"));
		this.happened.emit(won ? "FOOTBALL_TACKLE_WON" : "FOOTBALL_TACKLE_MISSED");
		return true;
	}

	_step(seconds) {
		if (this._pause_left > 0) {
			this._pause_left -= seconds;
			return;
		}
		this._own_tackle_left -= seconds;
		this._safe_left -= seconds;
		this._assign_marks();
		const move = this.stick.limit_length(1).mul(this.avatar_speed * seconds);
		this.positions[0] = this._on_field(this.positions.at(0).add(move));
		for (let i = 1; i < this.positions.length; i++) {
			if (this.is_beaten(i)) this._beaten_left[i] -= seconds;
			else this.positions[i] = this._on_field(this.positions.at(i).move_toward(this._target(i), this._value("cpu_speed") * seconds));
		}
		if (this.flight !== Flight.NONE) this._move_ball(seconds);
		else if (this.owner !== NOBODY) this.ball = this.positions.at(this.owner).copy();
		else this._pick_up();
		this._computer_tackle(seconds);
		this._computer_carrier(seconds);
	}

	_move_ball(seconds) {
		if (this.flight === Flight.PASS) {
			this._ball_target = this.positions.at(this._receiver).copy();
			for (let i = 0; i < this.positions.length; i++) {
				if (this._team(i) !== this._team(this._receiver) && !this.is_beaten(i)
						&& this.positions.at(i).distance_to(this.ball) <= this._value("intercept_radius")) {
					if (this._team(i) === 1) this.happened.emit("FOOTBALL_INTERCEPTED");
					this._receive(i);
					return;
				}
			}
		}
		this.ball = this.ball.move_toward(this._ball_target, this._ball_speed * seconds);
		if (!this.ball.is_equal_approx(this._ball_target)) return;
		if (this.flight === Flight.PASS) {
			this._receive(this._receiver);
		} else {
			if (this._shot_scores && this._shooter_team === 0) {
				this.goals_us += 1;
				this.happened.emit("FOOTBALL_GOAL");
			} else if (this._shot_scores) {
				this.goals_them += 1;
				this.happened.emit("FOOTBALL_GOAL_THEM");
			} else {
				this.happened.emit("FOOTBALL_MISSED");
			}
			// After a goal or a miss the other team restarts the game.
			this.kick_off(this._shooter_team === 1, true);
		}
	}

	_receive(player) {
		this.owner = player;
		this.flight = Flight.NONE;
		this._receiver = NOBODY;
		this.ball = this.positions.at(player).copy();
		this._decide_left = this._value("cpu_decide_seconds");
		this._safe_left = this._value("protect_seconds");
	}

	_pick_up() {
		let nearest = this._nearest_of(0, this.ball);
		const other = this._nearest_of(1, this.ball);
		if (this.positions.at(other).distance_to(this.ball) < this.positions.at(nearest).distance_to(this.ball)) nearest = other;
		if (this.positions.at(nearest).distance_to(this.ball) <= this._value("control_radius")) this._receive(nearest);
	}

	_pass_to(receiver) {
		this.owner = NOBODY;
		this.flight = Flight.PASS;
		this._receiver = receiver;
		this._ball_speed = this._value("pass_speed");
	}

	_shoot(chance) {
		this._shooter_team = this._team(this.owner);
		this._ball_target = this._goal(this._shooter_team);
		this.owner = NOBODY;
		this.flight = Flight.SHOT;
		this._ball_speed = this._value("shot_speed");
		this._shot_scores = this._rng.randf() < chance;
	}

	// Who has the ball, or will have it when the pass lands, or NOBODY.
	_holder() {
		return this.owner !== NOBODY ? this.owner : this._receiver;
	}

	// Where a computer player wants to go.
	_target(player) {
		const team = this._team(player);
		if (player === this.owner) return this._carrier_target(player);
		const holder = this._holder();
		if (holder === NOBODY) return player === this._nearest_computer(team, this.ball) ? this.ball.copy() : this._support(player);
		return this._team(holder) === team ? this._support(player) : this._defend(player, holder);
	}

	// With the ball: towards goal, going around an opponent in the way. A blue player stops in
	// shooting distance and waits for the player's button.
	_carrier_target(player) {
		const team = this._team(player);
		const here = this.positions.at(player);
		if (team === 0 && here.distance_to(this._goal(team)) <= this._value("mate_hold_range")) return here.copy();
		let way = here.direction_to(this._goal(team));
		const rival = this.positions.at(this._nearest_of(1 - team, here)).sub(here);
		if (rival.length() < this._value("dodge_radius") && rival.dot(way) > 0) {
			const side = way.orthogonal();
			way = way.add((side.dot(rival) > 0 ? side.neg() : side).mul(this._value("dodge_share"))).normalized();
		}
		return here.add(way.mul(this.length));
	}

	// Attacking without the ball: ahead of the ball, away from the nearest opponent.
	_support(player) {
		const team = this._team(player);
		let spot = this._home(player, true);
		const holder = this._holder();
		// Attackers run ahead of the ball, so a forward pass is possible. The last player stays back.
		if (holder !== NOBODY && this._team(holder) === team && player !== team * this.team_size + this.team_size - 1) {
			const ahead = this.positions.at(holder).y + this._up(team) * this._value("support_push");
			spot = new Vector2(spot.x, team === 0 ? Math.max(spot.y, ahead) : Math.min(spot.y, ahead));
		}
		const away = spot.sub(this.positions.at(this._nearest_of(1 - team, spot)));
		const room = this._value("support_room");
		if (away.length() < room) spot = spot.add(away.normalized().mul(room - away.length()));
		return this._on_field(spot);
	}

	// Defending, blue: the nearest player follows whoever has the ball from behind, close enough for
	// the button to use it to tackle but never in its way. Red defends better: the nearest player goes
	// to the side of its goal, the last player guards the goal, and the others mark the attackers.
	_defend(player, holder) {
		const team = this._team(player);
		const carrier = this.positions.at(holder);
		if (team === 0) {
			const closest = player === this._nearest_computer(team, carrier);
			return closest ? carrier.sub(carrier.direction_to(this._goal(1)).mul(this._value("press_gap"))) : this._home(player, true);
		}
		const own_goal = this._goal(1 - team);
		if (player === this._nearest_computer(team, carrier)) return carrier.add(carrier.direction_to(own_goal).mul(this._value("press_gap")));
		if (player === this._keeper()) return own_goal.add(own_goal.direction_to(this.ball).mul(this._value("keeper_depth")));
		if (this._marks.has(player)) {
			const mark = this.positions.at(this._marks.get(player));
			return mark.add(mark.direction_to(own_goal).mul(this._value("mark_gap")));
		}
		return this._home(player, true);
	}

	// Red's last defender.
	_keeper() {
		return this.team_size + this.team_size - 1;
	}

	// Each free red defender takes the most dangerous blue attacker left: the one nearest its goal.
	_assign_marks() {
		this._marks.clear();
		const holder = this._holder();
		if (holder === NOBODY || this._team(holder) === 1) return;
		const own_goal = this._goal(0);
		const attackers = this._members(0, 0).filter((i) => i !== holder);
		// A stable sort, as Godot's sort_custom keeps equal items in order... nearly: ties are rare.
		attackers.sort((a, b) => this.positions.at(a).distance_to(own_goal) - this.positions.at(b).distance_to(own_goal));
		const presser = this._nearest_computer(1, this.positions.at(holder));
		const spare = this._members(1, 0).filter((i) => i !== presser && i !== this._keeper() && !this.is_beaten(i));
		for (const attacker of attackers) {
			let best = NOBODY;
			for (const defender of spare) {
				if (best === NOBODY || this.positions.at(defender).distance_to(this.positions.at(attacker))
						< this.positions.at(best).distance_to(this.positions.at(attacker))) best = defender;
			}
			if (best !== NOBODY) {
				this._marks.set(best, attacker);
				spare.splice(spare.indexOf(best), 1);
			}
		}
	}

	// A red player tries to take the ball from a close blue player, at most once per tackle time.
	// Blue computer players only tackle when the player presses the button.
	_computer_tackle(seconds) {
		this._tackle_left -= seconds;
		if (this._tackle_left > 0 || this.owner === NOBODY || this._team(this.owner) === 1 || this._safe_left > 0) return;
		const tackler = this._nearest_computer(1, this.positions.at(this.owner));
		if (this.positions.at(tackler).distance_to(this.positions.at(this.owner)) > this._value("cpu_tackle_reach")) return;
		this._tackle_left = this._value("cpu_tackle_seconds");
		const carrier = this.owner;
		if (this._resolve_tackle(tackler, this._value("cpu_tackle_chance")) && carrier === 0) this.happened.emit("FOOTBALL_LOST_BALL");
	}

	// A tackle always ends here: the tackler wins the ball or fails, and the loser is beaten.
	// Returns true if the tackler won.
	_resolve_tackle(tackler, chance) {
		const carrier = this.owner;
		const won = this._rng.randf() < chance;
		this._beat(won ? carrier : tackler, won ? tackler : carrier);
		if (won) this._receive(tackler);
		this.tackled.emit(tackler, carrier, won);
		return won;
	}

	// The loser of a tackle is pushed back and stands still for a moment. The player's avatar always
	// keeps moving, but it cannot tackle back at once.
	_beat(loser, winner) {
		if (loser === 0) {
			this._own_tackle_left = this._value("tackle_seconds");
			return;
		}
		const away = this.positions.at(winner).direction_to(this.positions.at(loser));
		this.positions[loser] = this._on_field(this.positions.at(loser).add((away.is_zero() ? Vector2.RIGHT : away).mul(this._value("knockback"))));
		this._beaten_left[loser] = this._value("beaten_seconds");
	}

	// A computer player with the ball decides from time to time. Red shoots when it has a clear
	// chance and only passes forward, so it keeps attacking. Blue only passes to escape pressure:
	// its shots wait for the player's button.
	_computer_carrier(seconds) {
		if (this.owner === NOBODY || this.owner === 0) return;
		this._decide_left -= seconds;
		if (this._decide_left > 0) return;
		this._decide_left = this._value("cpu_decide_seconds");
		const team = this._team(this.owner);
		if (team === 1 && this._wants_to_shoot(this.owner)) {
			this._shoot(this._shot_chance(this.owner, this._value("cpu_goal_chance")));
			return;
		}
		const mate = this._best_pass(this.owner);
		if (mate === NOBODY) return;
		const pressed = this._nearest_distance(this.owner, 1 - team) < this._value("cpu_press_radius");
		const forward = (this.positions.at(mate).y - this.positions.at(this.owner).y) * this._up(team);
		if (team === 0) {
			if (pressed) this._pass_to(mate);
		} else if ((pressed && forward >= 0) || (forward >= this._value("pass_gain") && this._rng.randf() < this._value("cpu_pass_chance"))) {
			this._pass_to(mate);
		}
	}

	// In range with a clear view of the goal, or so close that it does not matter.
	_wants_to_shoot(player) {
		const distance = this.positions.at(player).distance_to(this._goal(this._team(player)));
		if (distance > this._value("cpu_shot_range")) return false;
		return distance <= this._value("close_range") || !this._shot_blocked(player);
	}

	// The goal chance of a shot, lower when a defender stands in its way.
	_shot_chance(player, chance) {
		return this._shot_blocked(player) ? chance * this._value("block_share") : chance;
	}

	// A defender stands on the line of the shot. Red's last defender does not count: the goal
	// chance already includes a goalkeeper, and it always stands on that line.
	_shot_blocked(player) {
		const team = this._team(player);
		return this._lane_blocked(this.positions.at(player), this._goal(team), 1 - team, this._value("block_radius"), this._keeper());
	}

	// A player of team stands within radius of the line from from to to. A player behind the start
	// (its nearest point on the line is the start itself) is not in the way.
	_lane_blocked(from, to, team, radius, ignored = NOBODY) {
		for (const i of this._members(team, 0)) {
			if (i === ignored || this.is_beaten(i)) continue;
			const closest = closest_point_to_segment(this.positions.at(i), from, to);
			if (!closest.is_equal_approx(from) && closest.distance_to(this.positions.at(i)) <= radius) return true;
		}
		return false;
	}

	// The team-mate worth passing to: free, further forward, and with no opponent in the way.
	_best_pass(player) {
		const team = this._team(player);
		let best = NOBODY;
		let best_value = -Infinity;
		for (const i of this._members(team, 0)) {
			if (i === player || this._lane_blocked(this.positions.at(player), this.positions.at(i), 1 - team, this._value("lane_radius"))) continue;
			const forward = (this.positions.at(i).y - this.positions.at(player).y) * this._up(team);
			const value = this._nearest_distance(i, 1 - team) + forward * this._value("forward_weight");
			if (value > best_value) {
				best_value = value;
				best = i;
			}
		}
		return best;
	}

	// A player's place: from the formation, mirrored for the other team. In play the whole team
	// follows the ball up and down the field.
	_home(player, following) {
		const team = this._team(player);
		const place = this._formation[player - team * this.team_size];
		let y = Number(place[1]) * this.length;
		if (following) y += (this.ball.y / this.length - this._value("field_middle")) * this._value("follow_share") * this.length;
		y = team === 0 ? y : this.length - y;
		return this._on_field(new Vector2(Number(place[0]) * this.width, y));
	}

	_goal(team) {
		return new Vector2(this.width * this._value("field_middle"), team === 0 ? this.length : 0);
	}

	_team(player) {
		return player < this.team_size ? 0 : 1;
	}

	// +1 for the team attacking up the field, -1 for the other.
	_up(team) {
		return team === 0 ? 1 : -1;
	}

	_members(team, first) {
		const members = [];
		for (let i = team * this.team_size + first; i < team * this.team_size + this.team_size; i++) members.push(i);
		return members;
	}

	_on_field(point) {
		return point.clamp(Vector2.ZERO, new Vector2(this.width, this.length));
	}

	_nearest_of(team, point) {
		return this._nearest(team, point, 0);
	}

	// The avatar is left out: the player moves it. For the other team, nobody is left out, because
	// first only skips a player of the avatar's team.
	_nearest_computer(team, point) {
		return this._nearest(team, point, 1 - team);
	}

	// The nearest player who is not beaten.
	_nearest(team, point, first) {
		let best = NOBODY;
		let best_distance = Infinity;
		for (const i of this._members(team, first)) {
			if (!this.is_beaten(i) && this.positions.at(i).distance_to(point) < best_distance) {
				best_distance = this.positions.at(i).distance_to(point);
				best = i;
			}
		}
		return best;
	}

	_nearest_distance(player, team) {
		return this.positions.at(player).distance_to(this.positions.at(this._nearest_of(team, this.positions[player])));
	}

	// Config values are read once per key: the match asks for them many times per step.
	_value(key) {
		if (!(key in this._values)) this._values[key] = Config.get_float("minigame.football." + key);
		return this._values[key];
	}
}
