extends Control
## The football field of the minigame (Milestone 14), drawn from above with placeholder shapes.
## The avatar's team attacks up the screen, and the view follows the avatar. Team-mates a pass
## would reach free have a ring, and the goal shows the range of a good shot.

@export var grass_color := Color(0.2, 0.48, 0.28)
@export var line_color := Color(0.9, 0.95, 0.9, 0.8)
@export var team_color := Color(0.25, 0.5, 0.95)
@export var avatar_color := Color(1.0, 0.85, 0.3)
@export var other_color := Color(0.9, 0.3, 0.3)
@export var ball_color := Color.WHITE
@export var free_color := Color(0.5, 1.0, 0.6)
@export var player_radius := 18.0
@export var ball_radius := 8.0
@export var line_width := 3.0
## Share of the view below the avatar.
@export var view_below := 0.35
@export var goal_width := 10.0

var game: RefCounted = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), grass_color)
	if game == null:
		return
	var scale_x: float = size.x / game.width
	var offset := _view_offset(scale_x)
	_draw_lines(scale_x, offset)
	# Backwards, so the avatar (player 0) is drawn on top.
	for i in range(game.positions.size() - 1, -1, -1):
		var point: Vector2 = _screen(game.positions[i], scale_x, offset)
		var ours: bool = i < game.team_size
		draw_circle(point, player_radius, avatar_color if i == 0 else (team_color if ours else other_color))
		if ours and i > 0 and game.has_ball() and game.is_free(i):
			draw_arc(point, player_radius * 1.4, 0.0, TAU, 32, free_color, line_width)
	draw_circle(_screen(game.ball, scale_x, offset), ball_radius, ball_color)
	if game.has_ball() and game.in_shot_range():
		var goal: Vector2 = _screen(Vector2(game.width * 0.5, game.length), scale_x, offset)
		draw_line(goal - Vector2(goal_width * scale_x * 0.5, 0.0), goal + Vector2(goal_width * scale_x * 0.5, 0.0), free_color, line_width * 3.0)


func _draw_lines(scale_x: float, offset: float) -> void:
	var middle := _screen(Vector2(0.0, game.length * 0.5), scale_x, offset).y
	draw_line(Vector2(0.0, middle), Vector2(size.x, middle), line_color, line_width)
	draw_arc(Vector2(size.x * 0.5, middle), size.x * 0.15, 0.0, TAU, 48, line_color, line_width)
	for y in [0.0, game.length]:
		var end := _screen(Vector2(game.width * 0.5, y), scale_x, offset)
		draw_line(Vector2(0.0, end.y), Vector2(size.x, end.y), line_color, line_width)
		draw_rect(Rect2(end.x - goal_width * scale_x * 0.5, end.y - 6.0, goal_width * scale_x, 12.0), line_color)


## Screen y of field y = 0, keeping the avatar in view and the field on screen.
func _view_offset(scale_x: float) -> float:
	var total: float = game.length * scale_x
	if total <= size.y:
		return size.y - (size.y - total) * 0.5
	var wanted: float = size.y * (1.0 - view_below) + game.positions[0].y * scale_x
	return clampf(wanted, size.y, total)


func _screen(point: Vector2, scale_x: float, offset: float) -> Vector2:
	return Vector2(point.x * scale_x, offset - point.y * scale_x)
