extends Control
## The football field of the minigame (Milestone 14), drawn from above with placeholder shapes.
## The field explains the match by itself: arrows show the way to attack, the shot zone shows
## where a good shot starts, a line shows where a pass would go, rings show who is free and who
## can be tackled, a small map shows the whole field, and a line of text says what to do next.

const GRASS_COLOR := Color(0.2, 0.48, 0.28)
const STRIPE_COLOR := Color(0.23, 0.52, 0.31)
const LINE_COLOR := Color(0.9, 0.95, 0.9, 0.8)
const TEAM_COLOR := Color(0.25, 0.5, 0.95)
const YOU_COLOR := Color(1.0, 0.85, 0.3)
const OTHER_COLOR := Color(0.9, 0.3, 0.3)
const BALL_COLOR := Color.WHITE
const GOOD_COLOR := Color(0.5, 1.0, 0.6)
const WARN_COLOR := Color(1.0, 0.7, 0.3)
const OUTLINE_COLOR := Color(0.1, 0.1, 0.15)
const BANNER_COLOR := Color(0.05, 0.07, 0.1, 0.75)

const PLAYER_RADIUS := 17.0
const YOU_RADIUS := 22.0
const BALL_RADIUS := 8.0
const LINE_WIDTH := 3.0
## Field units the ball is drawn ahead of the player who has it.
const BALL_LEAD := 1.2
const GOAL_WIDTH := 10.0
const GOAL_DEPTH := 14.0
const STRIPES := 6
## Share of the view below the avatar.
const VIEW_BELOW := 0.4
## Screen pixels kept around the field at each end.
const VIEW_MARGIN := 24.0
const CAMERA_SPEED := 5.0
## Share of the way from the avatar to the ball that the view looks at.
const CAMERA_TO_BALL := 0.3
const MAP_SIZE := Vector2(84, 126)
const MAP_MARGIN := 8.0
const HINT_HEIGHT := 44.0
const HINT_FONT := 24
const EVENT_FONT := 44
const EVENT_SECONDS := 1.6
const NAME_FONT := 18

var game: RefCounted = null
## What the player should do now, already translated.
var hint := ""
## The label over the avatar, already translated.
var you_text := ""

var _camera := -1.0
var _pulse := 0.0
var _event_text := ""
var _event_left := 0.0


## Shows a short message in the middle of the field.
func show_event(text: String) -> void:
	_event_text = text
	_event_left = EVENT_SECONDS


func _process(delta: float) -> void:
	if not visible or game == null:
		return
	_pulse += delta
	_event_left -= delta
	var wanted: float = lerpf(game.positions[0].y, game.ball.y, CAMERA_TO_BALL)
	_camera = wanted if _camera < 0.0 else lerpf(_camera, wanted, minf(1.0, delta * CAMERA_SPEED))
	queue_redraw()


## An egg seen from above. Also used by the first-time explanation.
static func draw_egg(canvas: CanvasItem, centre: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(centre + Vector2(cos(angle) * radius, sin(angle) * radius * 1.2))
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, OUTLINE_COLOR, 2.0, true)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GRASS_COLOR)
	if game == null:
		return
	var scale_x: float = size.x / game.width
	var ground := _ground_y(scale_x)
	_draw_grass(scale_x, ground)
	_draw_lines(scale_x, ground)
	_draw_shot_zone(scale_x, ground)
	_draw_pass_line(scale_x, ground)
	_draw_players(scale_x, ground)
	_draw_ball(scale_x, ground)
	_draw_map()
	_draw_banner()


func _draw_grass(scale_x: float, ground: float) -> void:
	var stripe: float = game.length / STRIPES * scale_x
	for i in range(0, STRIPES, 2):
		draw_rect(Rect2(0.0, ground - stripe * (i + 1), size.x, stripe), STRIPE_COLOR)
	# Arrows up the field: this is the way to attack.
	for share in [0.3, 0.5, 0.7]:
		var tip := _screen(Vector2(game.width * 0.5, game.length * share), scale_x, ground)
		var arrow := Color(1.0, 1.0, 1.0, 0.16)
		draw_polyline(PackedVector2Array([tip + Vector2(-46, 30), tip, tip + Vector2(46, 30)]), arrow, 12.0)


func _draw_lines(scale_x: float, ground: float) -> void:
	var middle := _screen(Vector2(0.0, game.length * 0.5), scale_x, ground).y
	draw_line(Vector2(0.0, middle), Vector2(size.x, middle), LINE_COLOR, LINE_WIDTH)
	draw_arc(Vector2(size.x * 0.5, middle), size.x * 0.15, 0.0, TAU, 48, LINE_COLOR, LINE_WIDTH)
	_draw_goal(_screen(Vector2(game.width * 0.5, game.length), scale_x, ground), scale_x, OTHER_COLOR, -1.0)
	_draw_goal(_screen(Vector2(game.width * 0.5, 0.0), scale_x, ground), scale_x, TEAM_COLOR, 1.0)


## side: -1 for the goal at the top of the screen, 1 for the one at the bottom.
func _draw_goal(centre: Vector2, scale_x: float, color: Color, side: float) -> void:
	draw_line(Vector2(0.0, centre.y), Vector2(size.x, centre.y), LINE_COLOR, LINE_WIDTH)
	var half := GOAL_WIDTH * scale_x * 0.5
	var top := centre.y if side > 0.0 else centre.y - GOAL_DEPTH
	draw_rect(Rect2(centre.x - half, top, half * 2.0, GOAL_DEPTH), color)
	draw_rect(Rect2(centre.x - half, top, half * 2.0, GOAL_DEPTH), LINE_COLOR, false, LINE_WIDTH)


## The area where a shot is good, on the other team's side.
func _draw_shot_zone(scale_x: float, ground: float) -> void:
	var goal := _screen(Vector2(game.width * 0.5, game.length), scale_x, ground)
	var radius: float = game.shot_range * scale_x
	var inside: bool = game.has_ball() and game.in_shot_range()
	var points := PackedVector2Array([goal])
	for i in 33:
		var angle := PI * i / 32.0
		points.append(goal + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(GOOD_COLOR, 0.32 if inside else 0.12))
	draw_arc(goal, radius, 0.0, PI, 48, Color(GOOD_COLOR, 0.8), LINE_WIDTH)


## With the ball: a line to the team-mate who would get a pass.
func _draw_pass_line(scale_x: float, ground: float) -> void:
	if not game.has_ball():
		return
	var receiver: int = game.best_receiver()
	var from := _screen(game.positions[0], scale_x, ground)
	var to := _screen(game.positions[receiver], scale_x, ground)
	draw_dashed_line(from, to, GOOD_COLOR if game.is_free(receiver) else WARN_COLOR, LINE_WIDTH, 14.0)


func _draw_players(scale_x: float, ground: float) -> void:
	# Backwards, so the avatar (player 0) is drawn on top.
	for i in range(game.positions.size() - 1, 0, -1):
		var point := _screen(game.positions[i], scale_x, ground)
		var ours: bool = i < game.team_size
		_draw_egg(point, PLAYER_RADIUS, TEAM_COLOR if ours else OTHER_COLOR)
		if ours and game.is_free(i):
			draw_arc(point, PLAYER_RADIUS * 1.6, 0.0, TAU, 32, GOOD_COLOR, LINE_WIDTH)
		if i == game.owner and not ours:
			var color: Color = GOOD_COLOR if game.in_tackle_reach() else WARN_COLOR
			draw_arc(point, PLAYER_RADIUS * 1.6, 0.0, TAU, 32, color, LINE_WIDTH + 2.0)
	var you := _screen(game.positions[0], scale_x, ground)
	_draw_egg(you, YOU_RADIUS, YOU_COLOR)
	# A bouncing marker and a name, so the player finds the avatar at once.
	var top := you.y - YOU_RADIUS * 1.2 - 10.0 - absf(sin(_pulse * 4.0)) * 8.0
	draw_colored_polygon(PackedVector2Array([Vector2(you.x, top), Vector2(you.x - 11.0, top - 15.0), Vector2(you.x + 11.0, top - 15.0)]), YOU_COLOR)
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(you.x - 60.0, top - 20.0), you_text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, NAME_FONT, 5, OUTLINE_COLOR)
	draw_string(font, Vector2(you.x - 60.0, top - 20.0), you_text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, NAME_FONT, YOU_COLOR)


func _draw_egg(point: Vector2, radius: float, color: Color) -> void:
	draw_egg(self, point, radius, color)


func _draw_ball(scale_x: float, ground: float) -> void:
	var at: Vector2 = game.ball
	if game.owner != -1:
		at.y += BALL_LEAD if game.owner < game.team_size else -BALL_LEAD
	var point := _screen(at, scale_x, ground)
	draw_circle(point, BALL_RADIUS, BALL_COLOR)
	draw_arc(point, BALL_RADIUS, 0.0, TAU, 20, OUTLINE_COLOR, 2.0)


## The whole field, small, in a corner: the view only shows part of it.
func _draw_map() -> void:
	var corner := Vector2(MAP_MARGIN, MAP_MARGIN)
	draw_rect(Rect2(corner, MAP_SIZE), Color(GRASS_COLOR, 0.85))
	draw_rect(Rect2(corner, MAP_SIZE), LINE_COLOR, false, 2.0)
	var half_goal: float = MAP_SIZE.x * GOAL_WIDTH / game.width * 0.5
	var middle := corner.x + MAP_SIZE.x * 0.5
	draw_line(Vector2(middle - half_goal, corner.y), Vector2(middle + half_goal, corner.y), OTHER_COLOR, 5.0)
	draw_line(Vector2(middle - half_goal, corner.y + MAP_SIZE.y), Vector2(middle + half_goal, corner.y + MAP_SIZE.y), TEAM_COLOR, 5.0)
	for i in range(game.positions.size() - 1, 0, -1):
		draw_circle(_on_map(game.positions[i], corner), 4.0, TEAM_COLOR if i < game.team_size else OTHER_COLOR)
	draw_circle(_on_map(game.positions[0], corner), 6.0, YOU_COLOR)
	draw_circle(_on_map(game.ball, corner), 3.0, BALL_COLOR)


func _on_map(point: Vector2, corner: Vector2) -> Vector2:
	return corner + Vector2(point.x / game.width * MAP_SIZE.x, (1.0 - point.y / game.length) * MAP_SIZE.y)


func _draw_banner() -> void:
	var font := get_theme_default_font()
	if not hint.is_empty():
		draw_rect(Rect2(0.0, size.y - HINT_HEIGHT, size.x, HINT_HEIGHT), BANNER_COLOR)
		draw_string(font, Vector2(0.0, size.y - 13.0), hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, HINT_FONT, Color.WHITE)
	if _event_left > 0.0:
		var y := size.y * 0.45
		draw_string_outline(font, Vector2(0.0, y), _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, 8, OUTLINE_COLOR)
		draw_string(font, Vector2(0.0, y), _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, Color.WHITE)


## Screen y of field y = 0: the view looks at the camera and keeps the field on screen.
func _ground_y(scale_x: float) -> float:
	var total: float = game.length * scale_x
	var lowest := size.y - VIEW_MARGIN
	var highest := VIEW_MARGIN + GOAL_DEPTH + total
	var wanted := size.y * (1.0 - VIEW_BELOW) + maxf(_camera, 0.0) * scale_x
	return clampf(wanted, lowest, maxf(lowest, highest))


func _screen(point: Vector2, scale_x: float, ground: float) -> Vector2:
	return Vector2(point.x * scale_x, ground - point.y * scale_x)
