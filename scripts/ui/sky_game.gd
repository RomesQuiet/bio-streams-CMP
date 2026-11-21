extends Control
## Milestone 35: the screens minigame on screen, a video game in a screen with a navy frame. A
## dinosaur (simple shapes, not pixels) runs over clouds in a day sky; faint clouds far behind move
## slower. The score and the avatar's best are at the top right. Before a run and after it ends a
## card shows what to do, the score and the best scores of every avatar on this device; while the day
## is paused a banner says so (Jump does nothing then). Only the
## look: the run is scripts/health/sky_run.gd, played through the Minigame autoload.

const Ui := preload("res://scripts/ui/ui_style.gd")
const SkyRun := preload("res://scripts/health/sky_run.gd")

const FRAME := 10.0
const FRAME_RADIUS := 22.0
const SKY_TOP := Color("#59b8f5")
const SKY_BOTTOM := Color("#cdeeff")
const CLOUD := Color(1, 1, 1)
const CLOUD_SHADE := Color("#d6e6f7")
const FAR_CLOUD := Color(1, 1, 1, 0.38)
const SUN := Color("#fff2b0")
const DINO := Color("#3fae62")
const DINO_DARK := Color("#2c8a4b")
const DINO_BELLY := Color("#a6e3a1")
const EYE := Color(1, 1, 1)
const CARD := Color(0.137, 0.165, 0.431, 0.94)
const GOLD := Color("#ffd84a")
## Where the dinosaur's back is, as a share of the screen's width.
const DINO_AT := 0.18
const FAR_SPACING := 520.0
const FAR_PARALLAX := 0.3
const SCORE_FONT := 30
const CARD_TITLE_FONT := 36
const CARD_FONT := 22
const BOARD_FONT := 22
const CARD_WIDTH_SHARE := 0.84
const CARD_PADDING := 22.0
## The card starts under the score line, so the dinosaur on the clouds stays in view.
const CARD_TOP := 64.0
const LINE_GAP := 8.0
const BLINK_HZ := 1.6

## The run to show (Minigame.run), set by the main screen.
var run: RefCounted = null
var _screen: Control
var _last_score := 0
var _last_best := false
var _time := 0.0


func _ready() -> void:
	_screen = Control.new()
	_screen.clip_contents = true
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.offset_left = FRAME
	_screen.offset_top = FRAME
	_screen.offset_right = -FRAME
	_screen.offset_bottom = -FRAME
	add_child(_screen)
	_screen.draw.connect(_draw_screen)


## The run that just ended, for the card (Minigame.sky_run_ended).
func on_run_ended(score: int, best: bool) -> void:
	_last_score = score
	_last_best = best


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()
	_screen.queue_redraw()


## The frame around the screen.
func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_colored_polygon(Ui.rounded_rect_points(outer, FRAME_RADIUS), Ui.PANEL_COLOR)
	Ui.draw_outline(self, Ui.rounded_rect_points(outer.grow(-1.0), FRAME_RADIUS - 1.0), Ui.HUD_LINE, Ui.BORDER_THIN)


func _draw_screen() -> void:
	var area := _screen.size
	_screen.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(area.x, 0), area, Vector2(0, area.y)]),
			PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	if run == null:
		return
	var scale_y := area.y / Config.get_float("minigame.sky.view_height")
	var camera: float = run.x - area.x * DINO_AT / scale_y
	_screen.draw_circle(Vector2(area.x * 0.8, area.y * 0.14), area.y * 0.06, SUN, true, -1.0, true)
	_draw_far_clouds(camera, scale_y)
	for cloud: Dictionary in run.clouds:
		_draw_cloud(Rect2(_screen_x(cloud.x, camera, scale_y), area.y - cloud.top * scale_y, cloud.w * scale_y,
				Config.get_float("minigame.sky.cloud_thickness") * scale_y))
	_draw_dino(camera, scale_y)
	_draw_score()
	if run.state == SkyRun.State.READY or run.state == SkyRun.State.OVER:
		_draw_card()
	elif Clock.paused:
		_draw_paused()


func _screen_x(world_x: float, camera: float, scale_y: float) -> float:
	return (world_x - camera) * scale_y


## Faint clouds far away, always in the same places, moving slower than the near ones.
func _draw_far_clouds(camera: float, scale_y: float) -> void:
	var area := _screen.size
	var far := camera * FAR_PARALLAX
	var first := floori(far / FAR_SPACING) - 1
	for i in range(first, first + ceili(area.x / scale_y / FAR_SPACING) + 3):
		var height := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
		var centre := Vector2((i * FAR_SPACING - far) * scale_y, area.y * (0.25 + 0.45 * height))
		var radius := area.y * (0.035 + 0.02 * height)
		for puff in [Vector2(-1.3, 0.3), Vector2(0, 0), Vector2(1.2, 0.25), Vector2(0.4, 0.45)]:
			_screen.draw_circle(centre + puff * radius, radius, FAR_CLOUD, true, -1.0, true)


## A cloud: a flat top to stand on, puffy sides and a shaded underside.
func _draw_cloud(rect: Rect2) -> void:
	var radius := rect.size.y * 0.5
	var body := Ui.rounded_rect_points(rect, minf(radius, rect.size.x * 0.5))
	_screen.draw_colored_polygon(body, CLOUD_SHADE)
	var upper := Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.62))
	_screen.draw_colored_polygon(Ui.rounded_rect_points(upper, minf(upper.size.y * 0.5, rect.size.x * 0.5)), CLOUD)
	var puffs := maxi(2, roundi(rect.size.x / (radius * 1.6)))
	for i in puffs:
		var t := (i + 0.5) / puffs
		var puff := radius * (0.55 + 0.15 * sin(i * 2.3))
		_screen.draw_circle(Vector2(rect.position.x + rect.size.x * t, rect.position.y + puff * 0.45), puff, CLOUD, true, -1.0, true)


## The dinosaur in its box (back, feet, width, height), drawn from shapes in a 0-1 box (u right,
## v up). Legs move while it runs; crosses for eyes after a crash.
func _draw_dino(camera: float, scale_y: float) -> void:
	var area := _screen.size
	var origin := Vector2(_screen_x(run.x, camera, scale_y), area.y - run.y * scale_y)
	var box := Vector2(Config.get_float("minigame.sky.dino_width"), Config.get_float("minigame.sky.dino_height")) * scale_y
	var at := func(u: float, v: float) -> Vector2: return origin + Vector2(u * box.x, -v * box.y)
	var crashed: bool = run.state == SkyRun.State.FALLING or (run.state == SkyRun.State.OVER and run.run_seconds > 0.0)
	# Tail.
	_screen.draw_colored_polygon(PackedVector2Array([at.call(0.0, 0.62), at.call(0.34, 0.66), at.call(0.34, 0.38)]), DINO)
	# Legs: they swing while running on a cloud.
	var swing := 0.0
	if run.state == SkyRun.State.RUNNING and run.grounded:
		swing = sin(run.distance / Config.get_float("minigame.sky.dino_width") * 2.2) * 0.12
	var leg_width := box.x * 0.13
	Ui.draw_round_line(_screen, at.call(0.4, 0.3), at.call(0.4 + swing, 0.04), DINO_DARK, leg_width)
	Ui.draw_round_line(_screen, at.call(0.58, 0.3), at.call(0.58 - swing, 0.04), DINO_DARK, leg_width)
	# Body and belly.
	_screen.draw_colored_polygon(Ui.ellipse_points(at.call(0.48, 0.47), Vector2(0.27, 0.22) * box), DINO)
	_screen.draw_colored_polygon(Ui.ellipse_points(at.call(0.52, 0.4), Vector2(0.16, 0.1) * box), DINO_BELLY)
	# Neck and head.
	_screen.draw_colored_polygon(PackedVector2Array([at.call(0.58, 0.58), at.call(0.7, 0.86), at.call(0.82, 0.78),
			at.call(0.74, 0.5)]), DINO)
	_screen.draw_colored_polygon(Ui.rounded_rect_points(Rect2(at.call(0.6, 1.0), Vector2(0.4, 0.24) * box), box.y * 0.08), DINO)
	# Arm.
	Ui.draw_round_line(_screen, at.call(0.72, 0.5), at.call(0.84, 0.42), DINO_DARK, box.x * 0.07)
	# Eye and mouth.
	var eye: Vector2 = at.call(0.8, 0.9)
	var eye_radius := box.x * 0.055
	if crashed:
		for d in [Vector2(1, 1), Vector2(1, -1)]:
			_screen.draw_line(eye - d * eye_radius, eye + d * eye_radius, Ui.INK, box.x * 0.03, true)
	else:
		_screen.draw_circle(eye, eye_radius, EYE, true, -1.0, true)
		_screen.draw_circle(eye + Vector2(eye_radius * 0.3, 0), eye_radius * 0.5, Ui.INK, true, -1.0, true)
	_screen.draw_line(at.call(0.84, 0.81), at.call(0.98, 0.81), DINO_DARK, box.x * 0.025, true)


## The score at the top right, and the avatar's best before it.
func _draw_score() -> void:
	var font := Ui.FONT_HEAVY
	var text := "%s %d   %05d" % [tr("SKY_BEST_SHORT"), GameState.sky_best, run.score()]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SCORE_FONT).x
	_screen.draw_string(font, Vector2(_screen.size.x - width - 18.0, 16.0 + font.get_ascent(SCORE_FONT)), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, SCORE_FONT, Ui.INK)


## Before the first jump: what to do. After a run: the score. Both: the device's best scores.
func _draw_card() -> void:
	var lines: Array = []
	if run.state == SkyRun.State.READY:
		lines.append([tr("SKY_TITLE"), CARD_TITLE_FONT, Ui.TEXT_PRIMARY])
		lines.append([tr("SKY_RULES"), CARD_FONT, Ui.TEXT_SECONDARY])
		lines.append([tr("SKY_PAUSED" if Clock.paused else "SKY_START"), CARD_FONT, GOLD])
	else:
		lines.append([tr("SKY_GAME_OVER"), CARD_TITLE_FONT, Ui.TEXT_PRIMARY])
		lines.append([tr("SKY_SCORE") % _last_score, CARD_FONT, Ui.TEXT_PRIMARY])
		if _last_best:
			lines.append([tr("SKY_NEW_BEST"), CARD_FONT, GOLD])
		var blink := fmod(_time * BLINK_HZ, 1.0) < 0.7
		lines.append([tr("SKY_AGAIN") if run.can_restart() and blink else " ", CARD_FONT, GOLD])
	lines.append([tr("SKY_LEADERBOARD"), CARD_FONT, Ui.TEXT_PRIMARY])
	var board: Array = Settings.sky_leaderboard
	if board.is_empty():
		lines.append([tr("SKY_NO_SCORES"), BOARD_FONT, Ui.TEXT_SECONDARY])
	for i in board.size():
		var entry: Dictionary = board[i]
		var own: bool = entry.id == GameState.avatar_id
		lines.append(["%d.  %s  %d" % [i + 1, entry.name, entry.score], BOARD_FONT, GOLD if own else Ui.TEXT_PRIMARY])
	var font := Ui.FONT_HEAVY
	var width := _screen.size.x * CARD_WIDTH_SHARE
	var inner := width - CARD_PADDING * 2.0
	var height := CARD_PADDING * 2.0
	for line in lines:
		height += _text_height(font, line[0], line[1], inner) + LINE_GAP
	var card := Rect2((_screen.size.x - width) * 0.5, CARD_TOP, width, height)
	_screen.draw_colored_polygon(Ui.rounded_rect_points(card, Ui.CORNER_RADIUS), CARD)
	Ui.draw_outline(_screen, Ui.rounded_rect_points(card, Ui.CORNER_RADIUS), Ui.HUD_LINE, Ui.BORDER_THIN)
	var y := card.position.y + CARD_PADDING
	for line in lines:
		var text_height := _text_height(font, line[0], line[1], inner)
		_screen.draw_multiline_string(font, Vector2(card.position.x + CARD_PADDING, y + font.get_ascent(line[1])), line[0],
				HORIZONTAL_ALIGNMENT_CENTER, inner, line[1], -1, line[2])
		y += text_height + LINE_GAP


## A run stops while the day is paused: a banner says how to go on.
func _draw_paused() -> void:
	var font := Ui.FONT_HEAVY
	var width := _screen.size.x * CARD_WIDTH_SHARE
	var height := _text_height(font, tr("SKY_PAUSED"), CARD_FONT, width - CARD_PADDING * 2.0) + CARD_PADDING * 2.0
	var card := Rect2((_screen.size.x - width) * 0.5, CARD_TOP, width, height)
	_screen.draw_colored_polygon(Ui.rounded_rect_points(card, Ui.CORNER_RADIUS), CARD)
	_screen.draw_multiline_string(font, Vector2(card.position.x + CARD_PADDING, card.position.y + CARD_PADDING + font.get_ascent(CARD_FONT)),
			tr("SKY_PAUSED"), HORIZONTAL_ALIGNMENT_CENTER, width - CARD_PADDING * 2.0, CARD_FONT, -1, GOLD)


func _text_height(font: Font, text: String, font_size: int, width: float) -> float:
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size).y
