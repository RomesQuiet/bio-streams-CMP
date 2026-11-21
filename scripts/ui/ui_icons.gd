extends RefCounted
## Milestone 25: the interface's icons, drawn with shapes (documentation/ui_specification_v1.md,
## sections 9 and 10): the heart, the gear, pause and play, the four buttons' runner, bed, apple and
## game controller, and the pictures of the avatar's requests. Each icon is drawn in a box of
## 100 x 100 units centred on `centre`, scaled to `box` pixels. Only the look.

const Ui := preload("res://scripts/ui/ui_style.gd")

const BUN := Color("#f4b54f")
const BUN_DARK := Color("#d98a2b")
const LETTUCE := Color("#5fd068")
const PATTY := Color("#7a3e1d")
const SCREEN := Color("#53c8f2")
const LIGHT := Color("#ffe7a0")


## Draws the icon `kind` ("heart", "gear", "pause", "play", "exercise", "sleep", "eat",
## "entertainment", "jump" (an arrow up, the sky-jump button, Milestone 35), "controller" (the game controller in one colour), the main menu's "person_add", "people", "upload" and "info", the exercises "squat", "pushup" and "situp", "fork", "footprints", and football's "pass" and "goal" (Milestone 40, 100 wide and about 58 high), or a request: "tired", "hungry", "fast_food", "healthy", "screens", "football").
## color is used by the one-colour icons (gear, pause, play, runner, bed, cutlery, screen).
static func draw(canvas: CanvasItem, kind: String, centre: Vector2, box: float, color := Ui.ICON_INK) -> void:
	canvas.draw_set_transform(centre, 0.0, Vector2.ONE * box / 100.0)
	match kind:
		"heart":
			_heart(canvas, Ui.HEALTH_COLOR.lightened(0.18), Ui.HEALTH_COLOR_DARK)
		"heart_flash":
			_heart(canvas, Ui.HEALTH_FLASH, Ui.HEALTH_COLOR)
		"gear":
			_gear(canvas, color)
		"pause":
			_pause(canvas, color)
		"play":
			_play(canvas, color)
		"exercise":
			_runner(canvas, color)
		"sleep", "tired":
			_bed(canvas, color)
		"eat", "healthy":
			_apple(canvas)
		"entertainment":
			_controller(canvas, Ui.CONTROLLER_BROWN)
		"controller":
			_controller(canvas, color)
		"hungry", "starving":
			_cutlery(canvas, color)
		"fast_food":
			_burger(canvas)
		"screens":
			_screen(canvas, color)
		"football":
			_ball(canvas)
		"jump":
			_jump_arrow(canvas, color)
		"person_add":
			_person_add(canvas, color)
		"people":
			_people(canvas, color)
		"upload":
			_upload(canvas, color)
		"info":
			_info(canvas, color)
		"squat":
			_squat(canvas, color)
		"pushup":
			_pushup(canvas, color)
		"situp":
			_situp(canvas, color)
		"fork":
			_fork(canvas, color)
		"footprints":
			_footprints(canvas, color)
		"pass":
			_pass(canvas, color)
		"goal":
			_goal(canvas, color)
	canvas.draw_set_transform(Vector2.ZERO)


## A filled polygon with a smooth (antialiased) edge.
static func fill(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)
	Ui.draw_outline(canvas, points, color, 1.2)


static func _circle(canvas: CanvasItem, centre: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(centre, radius, color, true, -1.0, true)


static func _box(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	fill(canvas, Ui.rounded_rect_points(rect, radius, 5), color)


static func _heart(canvas: CanvasItem, top: Color, bottom: Color) -> void:
	var points := PackedVector2Array()
	for i in 72:
		var t := TAU * i / 72.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(Vector2(x, y - 2.5) * 2.9)
	Ui.fill_vertical_gradient(canvas, points, -40.0, 45.0, top, bottom)
	var highlight := Ui.ellipse_points(Vector2(-22, -22), Vector2(9, 6), 20)
	fill(canvas, highlight, Color(1, 1, 1, 0.35))


static func _gear(canvas: CanvasItem, color: Color) -> void:
	canvas.draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 48, color, 17.0, true)
	for i in 8:
		var angle := TAU * i / 8.0
		var along := Vector2.from_angle(angle)
		var across := along.orthogonal()
		var tooth := PackedVector2Array([
			along * 30.0 - across * 9.5, along * 46.0 - across * 7.0,
			along * 46.0 + across * 7.0, along * 30.0 + across * 9.5])
		fill(canvas, tooth, color)


## Milestone 35: an arrow up over a short line, for the Jump button of the video game.
static func _jump_arrow(canvas: CanvasItem, color: Color) -> void:
	var head := PackedVector2Array([Vector2(0, -40), Vector2(32, -2), Vector2(-32, -2)])
	fill(canvas, head, color)
	for i in 3:
		Ui.draw_round_line(canvas, head[i], head[(i + 1) % 3], color, 8.0)
	_box(canvas, Rect2(-12, -6, 24, 30), 5.0, color)
	_box(canvas, Rect2(-34, 32, 68, 10), 5.0, color)


static func _pause(canvas: CanvasItem, color: Color) -> void:
	_box(canvas, Rect2(-25, -32, 17, 64), 6.0, color)
	_box(canvas, Rect2(8, -32, 17, 64), 6.0, color)


static func _play(canvas: CanvasItem, color: Color) -> void:
	var corners := PackedVector2Array([Vector2(-18, -28), Vector2(30, 0), Vector2(-18, 28)])
	fill(canvas, corners, color)
	for i in 3:
		Ui.draw_round_line(canvas, corners[i], corners[(i + 1) % 3], color, 10.0)


static func _runner(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(16, -38), 11.0, color)
	var limbs := [
		[Vector2(8, -22), Vector2(-4, 6)],
		[Vector2(6, -18), Vector2(22, -6), Vector2(36, -16)],
		[Vector2(4, -18), Vector2(-12, -10), Vector2(-26, -2)],
		[Vector2(-4, 6), Vector2(16, 18), Vector2(12, 40), Vector2(24, 40)],
		[Vector2(-4, 6), Vector2(-16, 24), Vector2(-38, 24)],
	]
	for limb in limbs:
		for i in limb.size() - 1:
			Ui.draw_round_line(canvas, limb[i], limb[i + 1], color, 12.0 if i == 0 and limb.size() == 2 else 10.0)


static func _bed(canvas: CanvasItem, color: Color) -> void:
	_box(canvas, Rect2(-46, -16, 11, 48), 4.0, color)
	_box(canvas, Rect2(-46, 10, 92, 12), 4.0, color)
	_box(canvas, Rect2(35, 10, 11, 22), 4.0, color)
	_circle(canvas, Vector2(-22, 0), 9.0, color)
	_box(canvas, Rect2(-10, -6, 56, 14), 6.0, color)
	_z(canvas, Vector2(8, -30), 13.0, color)
	_z(canvas, Vector2(28, -44), 17.0, color)


## The letter Z as a line, so no font is needed.
static func _z(canvas: CanvasItem, at: Vector2, height: float, color: Color) -> void:
	var w := height * 0.8
	var points := [at + Vector2(-w * 0.5, -height * 0.5), at + Vector2(w * 0.5, -height * 0.5),
			at + Vector2(-w * 0.5, height * 0.5), at + Vector2(w * 0.5, height * 0.5)]
	for i in 3:
		Ui.draw_round_line(canvas, points[i], points[i + 1], color, height * 0.28)


static func _apple(canvas: CanvasItem) -> void:
	var red := Ui.APPLE_RED
	_circle(canvas, Vector2(-12, 8), 27.0, red)
	_circle(canvas, Vector2(12, 8), 27.0, red)
	_circle(canvas, Vector2(0, 18), 26.0, red.darkened(0.06))
	_circle(canvas, Vector2(-16, -2), 9.0, Color(1, 1, 1, 0.3))
	Ui.draw_round_line(canvas, Vector2(0, -16), Vector2(4, -32), Ui.CONTROLLER_BROWN, 6.0)
	fill(canvas, Transform2D(-0.6, Vector2(17, -31)) * Ui.ellipse_points(Vector2.ZERO, Vector2(13, 7), 20), Ui.LEAF_GREEN)


static func _controller(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-28, 14), 19.0, color)
	_circle(canvas, Vector2(28, 14), 19.0, color)
	_box(canvas, Rect2(-46, -24, 92, 42), 20.0, color)
	_box(canvas, Rect2(-34, -5, 22, 7), 2.0, LIGHT)
	_box(canvas, Rect2(-26.5, -12.5, 7, 22), 2.0, LIGHT)
	for dot in [Vector2(22, -10), Vector2(31, -1), Vector2(22, 8), Vector2(13, -1)]:
		_circle(canvas, dot, 4.2, LIGHT)


static func _cutlery(canvas: CanvasItem, color: Color) -> void:
	# A fork on the left, a knife on the right.
	for x in [-26.0, -16.0, -6.0]:
		Ui.draw_round_line(canvas, Vector2(x, -40), Vector2(x, -18), color, 6.0)
	_box(canvas, Rect2(-30, -20, 28, 10), 5.0, color)
	Ui.draw_round_line(canvas, Vector2(-16, -12), Vector2(-16, 40), color, 9.0)
	fill(canvas, PackedVector2Array([Vector2(12, -40), Vector2(26, -24), Vector2(26, 2), Vector2(14, 2)]), color)
	Ui.draw_round_line(canvas, Vector2(18, 0), Vector2(18, 40), color, 9.0)


static func _burger(canvas: CanvasItem) -> void:
	var top := PackedVector2Array()
	for i in 21:
		top.append(Vector2.from_angle(PI + PI * i / 20.0) * Vector2(40, 32) + Vector2(0, -2))
	Ui.fill_vertical_gradient(canvas, top, -34.0, -2.0, BUN.lightened(0.15), BUN_DARK)
	_box(canvas, Rect2(-44, -2, 88, 10), 5.0, LETTUCE)
	_box(canvas, Rect2(-40, 8, 80, 13), 6.0, PATTY)
	_box(canvas, Rect2(-40, 21, 80, 14), 7.0, BUN_DARK)
	for seed in [Vector2(-16, -20), Vector2(0, -26), Vector2(16, -18), Vector2(4, -12)]:
		_circle(canvas, seed, 2.6, Color(1, 1, 1, 0.85))


static func _screen(canvas: CanvasItem, color: Color) -> void:
	_box(canvas, Rect2(-44, -34, 88, 58), 9.0, color)
	_box(canvas, Rect2(-36, -26, 72, 42), 5.0, SCREEN)
	Ui.draw_round_line(canvas, Vector2(0, 24), Vector2(0, 34), color, 8.0)
	Ui.draw_round_line(canvas, Vector2(-18, 38), Vector2(18, 38), color, 8.0)


static func _ball(canvas: CanvasItem) -> void:
	_circle(canvas, Vector2.ZERO, 40.0, Ui.INK)
	_circle(canvas, Vector2.ZERO, 36.0, Color.WHITE)
	var patch := PackedVector2Array()
	for i in 5:
		patch.append(Vector2.from_angle(TAU * i / 5.0 - PI * 0.5) * 12.0)
	fill(canvas, patch, Ui.INK)
	for i in 5:
		var out := Vector2.from_angle(TAU * i / 5.0 - PI * 0.5)
		Ui.draw_round_line(canvas, out * 12.0, out * 26.0, Ui.INK, 4.0)
		var side := PackedVector2Array()
		for j in 5:
			side.append(out * 30.0 + Vector2.from_angle(TAU * j / 5.0 + out.angle()) * 6.0)
		fill(canvas, side, Ui.INK)


# --- The main menu's icons (Milestone 40, the team's splash screen) ----------------------------

## A person with a plus: New avatar.
static func _person_add(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-14, -20), 17.0, color)
	_box(canvas, Rect2(-46, 2, 64, 38), 18.0, color)
	_box(canvas, Rect2(18, -22, 34, 9), 4.0, color)
	_box(canvas, Rect2(30.5, -34, 9, 34), 4.0, color)


## Three people: the avatars.
static func _people(canvas: CanvasItem, color: Color) -> void:
	for side in [-1.0, 1.0]:
		_circle(canvas, Vector2(34 * side, -12), 12.0, color)
		_box(canvas, Rect2(34 * side - 19, 4, 38, 30), 13.0, color)
	_circle(canvas, Vector2(0, -18), 16.0, color)
	_box(canvas, Rect2(-27, 2, 54, 38), 17.0, color)


## A cloud with an arrow up: Load a backup.
static func _upload(canvas: CanvasItem, color: Color) -> void:
	var width := 8.0
	canvas.draw_arc(Vector2(-26, 10), 18.0, PI * 0.5, PI * 1.55, 16, color, width, true)
	canvas.draw_arc(Vector2(0, -6), 26.0, PI * 1.12, PI * 1.95, 18, color, width, true)
	canvas.draw_arc(Vector2(28, 10), 18.0, PI * 1.45, PI * 2.5, 16, color, width, true)
	Ui.draw_round_line(canvas, Vector2(-26, 28), Vector2(-12, 28), color, width)
	Ui.draw_round_line(canvas, Vector2(12, 28), Vector2(28, 28), color, width)
	Ui.draw_round_line(canvas, Vector2(0, 42), Vector2(0, 2), color, width)
	Ui.draw_round_line(canvas, Vector2(0, 0), Vector2(-13, 13), color, width)
	Ui.draw_round_line(canvas, Vector2(0, 0), Vector2(13, 13), color, width)


## An "i" in a circle: About.
static func _info(canvas: CanvasItem, color: Color) -> void:
	canvas.draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 48, color, 7.0, true)
	_circle(canvas, Vector2(0, -20), 6.5, color)
	Ui.draw_round_line(canvas, Vector2(0, -3), Vector2(0, 22), color, 10.0)


# --- The activity dock's icons (Milestone 40) --------------------------------------------------

## A figure squatting, seen from the side.
static func _squat(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-6, -36), 12.0, color)
	var lines := [
		[Vector2(-8, -22), Vector2(-14, 6)],
		[Vector2(-10, -16), Vector2(16, -14), Vector2(36, -14)],
		[Vector2(-14, 6), Vector2(14, 8), Vector2(8, 38)],
		[Vector2(8, 38), Vector2(20, 38)],
	]
	for line in lines:
		for i in line.size() - 1:
			Ui.draw_round_line(canvas, line[i], line[i + 1], color, 12.0 if i == 0 and line.size() == 2 else 10.0)


## A figure in a push-up, lying face down on straight arms.
static func _pushup(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-34, -16), 11.0, color)
	Ui.draw_round_line(canvas, Vector2(-22, -8), Vector2(38, 12), color, 12.0)
	Ui.draw_round_line(canvas, Vector2(-20, -6), Vector2(-20, 24), color, 9.0)
	Ui.draw_round_line(canvas, Vector2(38, 12), Vector2(44, 24), color, 9.0)
	Ui.draw_round_line(canvas, Vector2(-46, 30), Vector2(48, 30), color, 6.0)


## A figure doing a sit-up: lying, knees up, the chest rising.
static func _situp(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-30, -20), 11.0, color)
	Ui.draw_round_line(canvas, Vector2(-24, -8), Vector2(-4, 18), color, 12.0)
	Ui.draw_round_line(canvas, Vector2(-4, 18), Vector2(20, -6), color, 10.0)
	Ui.draw_round_line(canvas, Vector2(20, -6), Vector2(36, 18), color, 10.0)
	Ui.draw_round_line(canvas, Vector2(-20, -2), Vector2(4, -6), color, 8.0)
	Ui.draw_round_line(canvas, Vector2(-46, 26), Vector2(48, 26), color, 6.0)


## A fork, upright (it fits a box 64 wide and 100 high).
static func _fork(canvas: CanvasItem, color: Color) -> void:
	for x in [-18.0, -6.0, 6.0, 18.0]:
		Ui.draw_round_line(canvas, Vector2(x, -46), Vector2(x, -18), color, 6.0)
	_box(canvas, Rect2(-22, -22, 44, 16), 7.5, color)
	_box(canvas, Rect2(-7, -10, 14, 58), 6.5, color)


## Two footprints, one ahead of the other (the cardio Tap button).
static func _footprints(canvas: CanvasItem, color: Color) -> void:
	for foot in [[Vector2(-16, 14), -0.25], [Vector2(16, -14), 0.25]]:
		var centre: Vector2 = foot[0]
		var turn: float = foot[1]
		var sole := Ui.ellipse_points(Vector2.ZERO, Vector2(11, 20), 24)
		var heel := Ui.ellipse_points(Vector2(0, 26), Vector2(9, 8), 16)
		var placed := PackedVector2Array()
		for point in sole:
			placed.append(centre + point.rotated(turn))
		fill(canvas, placed, color)
		placed = PackedVector2Array()
		for point in heel:
			placed.append(centre + point.rotated(turn))
		fill(canvas, placed, color)
		for i in 4:
			var toe := Vector2(-9 + 6 * i, -27 + absf(i - 1.5) * 2.5)
			_circle(canvas, centre + toe.rotated(turn), 3.6 if i > 0 else 4.6, color)


## A runner kicking a ball (football's Pass), about 100 x 58.
static func _pass(canvas: CanvasItem, color: Color) -> void:
	_circle(canvas, Vector2(-20, -22), 8.0, color)
	var limbs := [
		[Vector2(-22, -12), Vector2(-28, 8)],
		[Vector2(-22, -10), Vector2(-8, -4), Vector2(2, -12)],
		[Vector2(-24, -8), Vector2(-38, -2)],
		[Vector2(-28, 8), Vector2(-16, 16), Vector2(-2, 18)],
		[Vector2(-28, 8), Vector2(-38, 22), Vector2(-48, 22)],
	]
	for limb in limbs:
		for i in limb.size() - 1:
			Ui.draw_round_line(canvas, limb[i], limb[i + 1], color, 8.0)
	canvas.draw_arc(Vector2(24, 12), 13.0, 0.0, TAU, 28, color, 5.0, true)
	_circle(canvas, Vector2(24, 12), 4.5, color)
	for i in 3:
		Ui.draw_round_line(canvas, Vector2(6 + 7 * i, -14 + 4 * i), Vector2(14 + 7 * i, -10 + 4 * i), color, 3.0)


## A goal with its net (football's Shoot), about 100 x 58.
static func _goal(canvas: CanvasItem, color: Color) -> void:
	var frame := PackedVector2Array([Vector2(-44, 28), Vector2(-44, -26), Vector2(44, -26), Vector2(44, 28)])
	canvas.draw_polyline(frame, color, 7.0, true)
	for x in [-26.0, -8.0, 10.0, 28.0]:
		canvas.draw_line(Vector2(x, -22), Vector2(x, 26), Color(color, 0.7), 2.5, true)
	for y in [-10.0, 6.0, 20.0]:
		canvas.draw_line(Vector2(-40, y), Vector2(40, y), Color(color, 0.7), 2.5, true)
	Ui.draw_round_line(canvas, Vector2(-50, 28), Vector2(50, 28), color, 5.0)
