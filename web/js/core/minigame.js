// The minigames (sources in MILESTONE_12.md and MILESTONE_13.md). Training.performance() reads
// score() instead of the fixed minigame.default_score: it mixes rhythm and pace and follows the
// player. The reserve is the fatigue of one session, shown as a bar.
// Cardio (decisions 19 to 30): each tap is one stride. Rhythm: taps at the avatar's interval.
// Pace: strides as frequent as the avatar's running pace. The reserve (Breath) runs down while
// running, faster above the interval, and at 0 the avatar walks until it has partly refilled.
// Strength (decisions 31 to 38): Down then Up is one repetition. Rhythm: the technique, each
// press in turn at a controlled pace. Pace: repetitions done of those planned. The reserve
// (Muscle) falls with each repetition, faster when rushing; a set ends at its repetitions or
// with the reserve empty, and the avatar rests. More sets follow until the time ends.
// Football (decisions 39 to 46): a match (football_match.js) that the player steers. Rhythm: the
// timing of passes, shots and tackles. Pace: the share of recent time the avatar kept moving.
// The reserve (Breath) falls while moving and with each move, and refills a little in quiet
// moments. At 0 the avatar jogs until it has partly refilled. The match stops while it waits.
// Avatar time runs time_slowdown times slower while the avatar plays (decision 47), so a match
// lasts longer on screen. Breath is counted in avatar time, so a move costs that much less.
// Meal (decisions 52 to 55): a fork swings left and right, faster with every bite; a tap with
// the fork at the mouth is a bite, a miss drops the food. Done ends the meal; at full_bites the
// avatar is full. Simulation reads the result when the meal ends (take_meal_result()).
// With no tap or press the avatar stands still and waits, nothing counts, and the activity ends
// after minigame.wait_seconds. The rest between sets is not waiting.
// A session only exists with the main screen open (attach()), at normal speed, for an option
// with "minigame" in data/activities.json. Otherwise nothing changes: the scenario tests have
// no player and keep the fixed score.
// Started before Simulation, so it hears that an activity started before the health system does.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Activities} from "./activities.js";
import {Signal, get, roundf} from "./util.js";
import {Vector2, randi} from "./vector2.js";
import {CardioPace} from "../health/cardio_pace.js";
import {StrengthLoad} from "../health/strength_load.js";
import {FootballLoad} from "../health/football_load.js";
import {FootballMatch} from "../health/football_match.js";

const CARDIO = "cardio";
const STRENGTH = "strength";
const FOOTBALL = "football";
const MEAL = "meal";

export const Minigame = {
	CARDIO, STRENGTH, FOOTBALL, MEAL,
	// A stride or a press was made. on_beat: it came at the right time.
	strode: new Signal(),
	// The first tap or press of a session: the avatar really starts the activity.
	first_stride: new Signal(),
	// The player stopped and the wait ran out.
	gave_up: new Signal(),
	// A session started or ended, the avatar stopped or started moving, or a rest began or ended.
	session_changed: new Signal(),
	// Something happened in the match. key: a key of translations/strings.csv.
	football_event: new Signal(),
	// Something happened in a meal. key: a key of translations/strings.csv.
	meal_event: new Signal(),
	// A football match the player played ended, with this score.
	match_ended: new Signal(),
	// Emitted just before the avatar stops, starts, walks or runs, so Simulation can first run the
	// minutes that belong to what it was doing (like Activities.changing).
	changing: new Signal(),

	running: false,
	// CARDIO, STRENGTH, FOOTBALL or MEAL while a session runs.
	kind: "",
	// True while the avatar stands still, waiting for a tap or press.
	waiting: false,
	// Cardio: true while the avatar walks to get its breath back. Football: while it jogs.
	walking: false,
	// Strength: true during the rest between sets.
	resting: false,
	// The fatigue of the session, 0 to 1: the Breath or Muscle bar.
	reserve: 1,
	// Share of the last strides or presses on the beat, 0 to 1.
	rhythm: 1,
	// Cardio: how close the last strides came to the running pace. Strength: repetitions done of
	// those planned in the sets so far. Football: share of recent time spent moving. 0 to 1.
	pace: 1,
	// Strides (cardio) or repetitions (strength) of the session.
	strides: 0,
	// Real seconds since the last stride or press.
	seconds_since_tap: 0,
	last_on_beat: true,
	// Strength: whether Down is the next press, and the set being done.
	next_down: true,
	sets_started: 0,
	sets_goal: 0,
	reps_in_set: 0,
	set_reps: 0,
	// Football: the match of this session.
	game: null,
	// Football: the seed of the next match. 0 picks a new one.
	match_seed: 0,
	// Meal: bites eaten and food dropped.
	bites: 0,
	misses: 0,

	_player_present: false,
	// The session comes from a save: its values stay when it starts.
	_restored: false,
	_moved: false,
	// Taps judged so far, so the first ones are a plain average.
	_judged: 0,
	_waited: 0,
	// How much faster than the interval the player is going (1 = on the beat).
	_effort: 1,
	// Strength: real seconds of rest left, and the repetitions planned in the finished sets.
	_rest_left: 0,
	_reps_planned: 0,
	// Strength: the next press has no press before it to be timed against.
	_untimed: true,
	// Football: the score restored from a save.
	_goals_us: 0,
	_goals_them: 0,
	// Meal: swings of the fork so far, and the result of the last meal for Simulation.
	_fork_time: 0,
	_meal_result: {},

	_ready() {
		Activities.started.connect(_on_activity_started);
		Activities.ended.connect((activity_id, option_id) => _on_activity_ended(activity_id, option_id));
	},

	_process(delta) {
		if (!Minigame.running) return;
		if (Clock.is_debug_speed_active()) _end_session();
		else if (!Clock.paused) Minigame.advance(delta);
	},

	// The main screen is open: there is a player. A loaded activity goes on as a session.
	attach() {
		Minigame._player_present = true;
		if (Activities.is_running()) _on_activity_started("", Activities.current_option);
	},

	detach() {
		Minigame._player_present = false;
		_end_session();
	},

	// No session (new avatar).
	reset() {
		_end_session();
		_clear();
	},

	to_dict() {
		const m = Minigame;
		if (!m.running) return {};
		return {walking: m.walking, resting: m.resting, reserve: m.reserve, rhythm: m.rhythm, pace: m.pace,
			strides: m.strides, moved: m._moved, judged: m._judged, next_down: m.next_down,
			sets_started: m.sets_started, sets_goal: m.sets_goal, reps_in_set: m.reps_in_set,
			set_reps: m.set_reps, rest_left: m._rest_left, reps_planned: m._reps_planned,
			goals_us: m.game ? m.game.goals_us : 0, goals_them: m.game ? m.game.goals_them : 0,
			bites: m.bites, misses: m.misses, fork_time: m._fork_time};
	},

	// Restores values from to_dict(). Call after Activities.from_dict(); the session itself starts
	// in attach(), waiting for a tap or press, or going on with its rest.
	from_dict(data) {
		const m = Minigame;
		_clear();
		m._restored = Object.keys(data).length > 0;
		m.walking = Boolean(get(data, "walking", m.walking));
		m.resting = Boolean(get(data, "resting", m.resting));
		m.reserve = Number(get(data, "reserve", m.reserve));
		m.rhythm = Number(get(data, "rhythm", m.rhythm));
		m.pace = Number(get(data, "pace", m.pace));
		m.strides = Math.trunc(Number(get(data, "strides", m.strides)));
		m._moved = Boolean(get(data, "moved", m._moved));
		m._judged = Math.trunc(Number(get(data, "judged", m._judged)));
		m.next_down = Boolean(get(data, "next_down", m.next_down));
		m.sets_started = Math.trunc(Number(get(data, "sets_started", m.sets_started)));
		m.sets_goal = Math.trunc(Number(get(data, "sets_goal", m.sets_goal)));
		m.reps_in_set = Math.trunc(Number(get(data, "reps_in_set", m.reps_in_set)));
		m.set_reps = Math.trunc(Number(get(data, "set_reps", m.set_reps)));
		m._rest_left = Number(get(data, "rest_left", m._rest_left));
		m._reps_planned = Math.trunc(Number(get(data, "reps_planned", m._reps_planned)));
		m._goals_us = Math.trunc(Number(get(data, "goals_us", m._goals_us)));
		m._goals_them = Math.trunc(Number(get(data, "goals_them", m._goals_them)));
		m.bites = Math.trunc(Number(get(data, "bites", m.bites)));
		m.misses = Math.trunc(Number(get(data, "misses", m.misses)));
		m._fork_time = Number(get(data, "fork_time", m._fork_time));
	},

	// True while a session is waiting for the player: the avatar is not doing the activity.
	is_waiting() {
		return Minigame.running && Minigame.waiting;
	},

	// True while a session has the avatar walking to get its breath back.
	is_walking() {
		return Minigame.running && Minigame.walking;
	},

	// The score for Training.performance(), 0 to 1.
	score() {
		if (!Minigame.running) return Config.get_float("minigame.default_score");
		const weight = Config.get_float("minigame.rhythm_weight");
		return weight * Minigame.rhythm + (1 - weight) * Minigame.pace;
	},

	// Share of normal speed at which avatar time runs now. Read by the Clock.
	time_share() {
		if (Minigame.running && Minigame.kind === FOOTBALL && !Minigame.waiting) return 1 / Config.get_float("minigame.football.time_slowdown");
		return 1;
	},

	// Real seconds the next tap or press should come after the last one.
	interval() {
		if (Minigame.kind === STRENGTH) return Config.get_float("minigame.press_seconds");
		return Minigame.walking ? CardioPace.walk_interval() : CardioPace.run_interval();
	},

	steps() {
		return Minigame.strides * Config.get_int("minigame.steps_per_tap");
	},

	// The steps of the whole session at the avatar's running pace.
	steps_goal() {
		return roundf(Clock.avatar_hours_to_real_seconds(Activities.target_hours, false) / CardioPace.run_interval()
				* Config.get_float("minigame.steps_per_tap"));
	},

	// Meal: where the fork is, from -1 (left) through 0 (the mouth) to 1 (right).
	fork_position() {
		return Minigame.running && Minigame.kind === MEAL ? Math.sin(2 * Math.PI * Minigame._fork_time) : 0;
	},

	// Meal: the fork is close enough to the mouth for a bite.
	at_mouth() {
		return Math.abs(Minigame.fork_position()) <= _meal_value("hit_share");
	},

	// Meal: the share of the portion eaten so far, and the share at which the avatar is full.
	meal_share() {
		return Minigame.bites / _meal_value("bites");
	},

	full_share() {
		return _meal_value("full_bites") / _meal_value("bites");
	},

	// Meal: the result of the meal that just ended with this option, once, or {}.
	take_meal_result(option_id) {
		if (String(get(Minigame._meal_result, "option", "")) !== option_id) return {};
		const result = Minigame._meal_result;
		Minigame._meal_result = {};
		return result;
	},

	// The player pressed Done (meal).
	done() {
		if (Minigame.running && Minigame.kind === MEAL && !Clock.paused) Activities.stop();
	},

	// The player tapped (cardio), or pressed Bite (meal).
	tap() {
		const m = Minigame;
		if (!m.running || Clock.paused) return;
		if (m.kind === MEAL) {
			_bite();
			return;
		}
		if (m.kind !== CARDIO) return;
		if (m.waiting) {
			_start_moving();
			_stride(true);
			return;
		}
		const wanted = m.interval();
		if (m.seconds_since_tap < wanted * Config.get_float("minigame.min_gap_share")) {
			// Too soon to be a stride: only the rhythm notices.
			_judge(false);
			return;
		}
		_judge(_on_time(wanted));
		m.pace = _averaged(m.pace, Math.min(1, CardioPace.run_interval() / m.seconds_since_tap));
		m._effort = wanted / m.seconds_since_tap;
		_stride(m.last_on_beat);
	},

	// The player pressed Down or Up (strength). Only the expected button moves the avatar.
	press(down) {
		const m = Minigame;
		if (!m.running || m.kind !== STRENGTH || m.resting || Clock.paused) return;
		if (down !== m.next_down) {
			if (!m.waiting) _judge(false);
			return;
		}
		if (m.waiting) _start_moving();
		if (m._untimed) {
			m._untimed = false;
			m.last_on_beat = true;
			m._effort = 1;
		} else {
			const wanted = m.interval();
			_judge(_on_time(wanted));
			m._effort = wanted / Math.max(m.seconds_since_tap, wanted * Config.get_float("minigame.min_gap_share"));
		}
		m.seconds_since_tap = 0;
		m.next_down = !down;
		m.strode.emit(m.last_on_beat);
		if (!down) _finish_repetition();
	},

	// The player moved the joystick (football). Moving starts or wakes the session.
	set_stick(direction) {
		const m = Minigame;
		if (!m.running || m.kind !== FOOTBALL || (Clock.paused && !direction.is_zero())) return;
		m.game.stick = direction;
		if (!direction.is_zero()) _football_input();
	},

	// The player pressed Pass (football), which asks for the ball while a team-mate has it.
	pass_ball() {
		if (!_football_ready()) return;
		const game = Minigame.game;
		if (game.has_ball()) {
			_judge(game.pass_ball());
			_football_move("minigame.football.pass_cost");
		} else {
			game.call_for_ball();
		}
	},

	// The player pressed Shoot, which is Tackle while an opponent has the ball (football). A
	// team-mate with the ball shoots, and a blue player in reach tackles when the avatar is too far.
	shoot_or_tackle() {
		if (!_football_ready()) return;
		const game = Minigame.game;
		if (game.has_ball()) {
			_judge(game.shoot());
			_football_move("minigame.football.shot_cost");
		} else if (game.team_mate_has_ball()) {
			_judge(game.team_mate_shoot());
			_football_move("");
		} else if (game.can_tackle()) {
			_judge(game.tackle());
			_football_move(game.last_tackler < 1 ? "minigame.football.tackle_cost" : "");
		}
	},

	// Real time passed while the game is not paused.
	advance(seconds) {
		const m = Minigame;
		if (!m.running) return;
		if (m.waiting) {
			m._waited += seconds;
			if (m._waited >= Config.get_float("minigame.wait_seconds")) {
				Activities.stop();
				m.gave_up.emit();
			}
			return;
		}
		if (m.resting) {
			_rest(seconds);
			return;
		}
		m.seconds_since_tap = m.kind === FOOTBALL && !m.game.stick.is_zero() ? 0 : m.seconds_since_tap + seconds;
		if (m.seconds_since_tap >= Config.get_float("minigame.stall_seconds")) {
			m.changing.emit();
			m.waiting = true;
			m._waited = 0;
			m.session_changed.emit();
			return;
		}
		const minutes = Clock.real_seconds_to_avatar_hours(seconds * m.time_share(), false) * Config.get_float("units.minutes_per_hour");
		if (m.kind === CARDIO) _update_breath(minutes);
		else if (m.kind === FOOTBALL) _play_football(seconds, minutes);
		else if (m.kind === MEAL) m._fork_time += seconds * _meal_value("fork_hz");
	},
};

function _start_moving() {
	const m = Minigame;
	m.changing.emit();
	m.waiting = false;
	m._effort = 1;
	m._untimed = true;
	m.session_changed.emit();
	if (!m._moved) {
		m._moved = true;
		m.first_stride.emit();
	}
}

function _stride(on_beat) {
	Minigame.seconds_since_tap = 0;
	Minigame.strides += 1;
	Minigame.strode.emit(on_beat);
}

function _update_breath(minutes) {
	const m = Minigame;
	if (m.walking) {
		m.reserve = Math.min(1, m.reserve + minutes / Config.get_float("minigame.walk_recover_min"));
		if (m.reserve >= Config.get_float("minigame.run_again_at")) {
			m.changing.emit();
			m.walking = false;
		}
	} else {
		m.reserve = Math.max(0, m.reserve - minutes / CardioPace.run_minutes() * m._effort);
		if (m.reserve <= 0) {
			m.changing.emit();
			m.walking = true;
		}
	}
}

// A bite with the fork at the mouth fills the Tummy bar; a miss drops the food. The fork swings
// faster after each bite. The meal ends by itself when the portion is eaten.
function _bite() {
	const m = Minigame;
	if (m.waiting) _start_moving();
	m.seconds_since_tap = 0;
	const hit = m.at_mouth();
	_judge(hit);
	if (hit) {
		m.bites += 1;
		m.strides = m.bites;
		const full = _meal_value("full_bites");
		m.meal_event.emit(m.bites === Math.trunc(full) ? "SPEECH_FULL" : (m.bites > full ? "MEAL_TOO_MUCH" : "MEAL_YUM"));
	} else {
		m.misses += 1;
		m.meal_event.emit("MEAL_MISSED");
	}
	m.strode.emit(hit);
	if (m.bites >= Math.trunc(_meal_value("bites"))) Activities.stop();
}

function _meal_value(key) {
	const value = Config.get_float("minigame.meal." + key);
	return key === "fork_hz" ? value + Config.get_float("minigame.meal.fork_hz_gain") * Minigame.bites : value;
}

// Football: true if the session can take a move now. A move starts or wakes the session.
function _football_ready() {
	if (!Minigame.running || Minigame.kind !== FOOTBALL || Clock.paused) return false;
	_football_input();
	return true;
}

function _football_input() {
	Minigame.seconds_since_tap = 0;
	if (Minigame.waiting) _start_moving();
}

function _football_move(cost) {
	Minigame.strides += 1;
	Minigame.strode.emit(Minigame.last_on_beat);
	// A move a team-mate makes costs the avatar no Breath.
	if (cost !== "") _spend_breath(Config.get_float(cost) / Config.get_float("minigame.football.time_slowdown"));
}

function _spend_breath(amount) {
	const m = Minigame;
	m.reserve = Math.max(0, m.reserve - amount);
	if (m.reserve <= 0 && !m.walking) {
		m.changing.emit();
		m.walking = true;
	}
}

function _play_football(seconds, minutes) {
	const m = Minigame;
	const moving = !m.game.stick.is_zero();
	if (m.walking) _update_breath(minutes);
	else if (moving) _spend_breath(minutes / FootballLoad.play_minutes());
	else m.reserve = Math.min(1, m.reserve + minutes / Config.get_float("minigame.football.quiet_recover_min"));
	const share = Math.min(1, seconds / Config.get_float("minigame.football.active_window_seconds"));
	m.pace += ((moving ? 1 : 0) - m.pace) * share;
	_set_body();
	m.game.advance(seconds);
}

// The avatar's body as it is now sets what it can do in the match.
function _set_body() {
	const game = Minigame.game;
	game.avatar_speed = FootballLoad.speed(Minigame.walking);
	game.free_distance = FootballLoad.free_distance();
	game.shot_range = FootballLoad.shot_range();
}

function _new_game() {
	const m = Minigame;
	m.game = new FootballMatch(m.match_seed !== 0 ? m.match_seed : randi());
	m.game.goals_us = m._goals_us;
	m.game.goals_them = m._goals_them;
	m.game.happened.connect((key) => m.football_event.emit(key));
	_set_body();
}

// Up finished a repetition. The set ends at its repetitions or when the muscles are tired: the
// avatar never trains to failure.
function _finish_repetition() {
	const m = Minigame;
	m.strides += 1;
	m.reps_in_set += 1;
	m.reserve = Math.max(0, m.reserve - m._effort / (Config.get_float("minigame.reps_margin") * m.set_reps));
	if (m.reps_in_set >= m.set_reps || m.reserve <= 0) {
		m.resting = true;
		m._rest_left = Config.get_float("minigame.rest_seconds");
		m._reps_planned += m.set_reps;
		m.pace = Math.min(1, m.strides / m._reps_planned);
		m.session_changed.emit();
	}
}

// The rest refills part of the reserve, then the next set starts.
function _rest(seconds) {
	const m = Minigame;
	const share = Math.min(seconds, m._rest_left) / Config.get_float("minigame.rest_seconds");
	m.reserve = Math.min(1, m.reserve + share * Config.get_float("minigame.rest_refill"));
	m._rest_left -= seconds;
	if (m._rest_left <= 0) {
		_start_set();
		m.session_changed.emit();
	}
}

function _start_set() {
	const m = Minigame;
	m.resting = false;
	m.sets_started += 1;
	m.reps_in_set = 0;
	m.set_reps = StrengthLoad.reps_per_set();
	m.next_down = true;
	m.seconds_since_tap = 0;
	m._untimed = true;
}

function _on_time(wanted) {
	return Math.abs(Minigame.seconds_since_tap - wanted) <= wanted * Config.get_float("minigame.on_beat_share");
}

// One more tap or press judged for the rhythm.
function _judge(on_beat) {
	Minigame._judged += 1;
	Minigame.last_on_beat = on_beat;
	Minigame.rhythm = _averaged(Minigame.rhythm, on_beat ? 1 : 0);
}

// The average of about the last score_window_strides values, or a plain average of the first.
function _averaged(value, sample) {
	return value + (sample - value) / Math.min(Minigame._judged, Config.get_float("minigame.score_window_strides"));
}

function _on_activity_started(_activity_id, option_id) {
	const m = Minigame;
	const option_kind = String(get(Activities.find_option(option_id), "minigame", ""));
	if (m.running || !m._player_present || Clock.is_debug_speed_active() || option_kind === "") return;
	m.kind = option_kind;
	if (!m._restored) {
		_clear();
		if (m.kind === STRENGTH) {
			m.reserve = GameState.strength_recovery;
			m.sets_goal = StrengthLoad.sets_goal();
			_start_set();
		} else {
			// Cardio and football share the Breath bar.
			m.reserve = GameState.cardio_recovery;
			m.walking = m.reserve <= 0;
		}
	}
	m._restored = false;
	if (m.kind === FOOTBALL) _new_game();
	m.running = true;
	// A rest goes on by itself after a reload; anything else waits for the player.
	m.waiting = !m.resting;
	m.session_changed.emit();
}

function _on_activity_ended(_activity_id, option_id) {
	const m = Minigame;
	if (m.running && m.kind === FOOTBALL && m._moved) m.match_ended.emit(m.game.goals_us, m.game.goals_them);
	if (m.running && m.kind === MEAL) m._meal_result = {option: option_id, share: m.meal_share(), full_share: m.full_share()};
	_end_session();
}

function _end_session() {
	const m = Minigame;
	if (m.running) {
		m.running = false;
		m.kind = "";
		m.waiting = false;
		m.resting = false;
		m.session_changed.emit();
	}
}

function _clear() {
	const m = Minigame;
	m.waiting = false;
	m.walking = false;
	m.resting = false;
	m.reserve = 1;
	m.rhythm = 1;
	m.pace = 1;
	m.strides = 0;
	m.seconds_since_tap = 0;
	m.last_on_beat = true;
	m.next_down = true;
	m.sets_started = 0;
	m.sets_goal = 0;
	m.reps_in_set = 0;
	m.set_reps = 0;
	m._restored = false;
	m._moved = false;
	m._judged = 0;
	m._waited = 0;
	m._effort = 1;
	m._rest_left = 0;
	m._reps_planned = 0;
	m._untimed = true;
	m._goals_us = 0;
	m._goals_them = 0;
	m.game = null;
	m.bites = 0;
	m.misses = 0;
	m._fork_time = 0;
}

// For the tests (the Godot tests reach into these underscored functions too).
Minigame._end_session = _end_session;
Minigame._on_activity_started = _on_activity_started;
