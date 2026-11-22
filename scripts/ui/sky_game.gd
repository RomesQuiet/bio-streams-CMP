extends Control
## Milestone 35: the screens minigame on screen, a video game in a screen with a navy frame. A
## dinosaur runs over clouds in a day sky; faint clouds far behind move slower. The team's updated
## zip (22 Nov 2026): the dinosaur, the clouds and the flat sky colour are the team's pictures
## (assets/art/videogame/, loaded once in _ready, never while drawing); a cloud of any width is
## the small cloud's left end, its middle hump once or more, and its right end. The score and the avatar's best are at the top right. Before a run and after it ends a
## card shows what to do, the score and the best scores of every avatar on this device; while the day
## is paused a banner says so (Jump does nothing then). Only the
## look: the run is scripts/health/sky_run.gd, played through the Minigame autoload.

const Ui := preload("res://scripts/ui/ui_style.gd")
const SkyRun := preload("res://scripts/health/sky_run.gd")

const FRAME := 10.0
const FRAME_RADIUS := 22.0
## The team's sky (videogame/cenario/ceu.png is this one flat colour).
const SKY := Color("#3aa8fd")
const FAR_CLOUD := Color(1, 1, 1, 0.38)
const SUN := Color("#fff2b0")
const PICTURES := "res://assets/art/videogame/%s.png"
## The four dinosaur pictures share one canvas: the standing feet are at DINO_ANCHOR (a share of
## the picture's size), and standing it is DINO_STAND_SHARE of the picture's height tall (the
## run's dino_height).
const DINO_FRAMES := ["dino_idle", "dino_run_1", "dino_run_2", "dino_jump"]
const DINO_ANCHOR := Vector2(0.5016, 0.9677)
const DINO_STAND_SHARE := 0.9287
## Running, the picture changes every this share of dino_width.
const DINO_STRIDE := 0.6
## The small cloud, cut in three where its top dips beside the middle hump (shares of the
## picture's width); the dips are the cloud's top (where the dinosaur stands), the picture's
## bottom is the cloud's underside (cloud_thickness below the top).
const CLOUD_CUTS := Vector2(0.2716, 0.7257)
const CLOUD_TOP_SHARE := 0.3172
## The far clouds: the team's medium and large clouds, this tall (a share of the screen).
const FAR_HEIGHT := Vector2(0.06, 0.1)
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
var _dino: Array[Texture2D] = []
var _cloud: Texture2D
var _far: Array[Texture2D] = []


func _ready() -> void:
	for name in DINO_FRAMES:
		_dino.append(load(PICTURES % name))
	_cloud = load(PICTURES % "cloud_small")
	_far = [load(PICTURES % "cloud_medium"), load(PICTURES % "cloud_large")]
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
	_screen.draw_rect(Rect2(Vector2.ZERO, area), SKY)
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
		var texture: Texture2D = _far[posmod(i, _far.size())]
		var tall := area.y * lerpf(FAR_HEIGHT.x, FAR_HEIGHT.y, height)
		var wide := tall * texture.get_width() / texture.get_height()
		_screen.draw_texture_rect(texture, Rect2(centre - Vector2(wide, tall) * 0.5, Vector2(wide, tall)), false, FAR_CLOUD)


## A cloud: rect is its collision box (the top to stand on, cloud_thickness tall). The picture
## is as tall as makes its dips the top and its bottom the underside; the left end and the right
## end keep their shape, the middle hump is repeated to fill the width, a little wider or narrower.
func _draw_cloud(rect: Rect2) -> void:
	var size_px := Vector2(_cloud.get_width(), _cloud.get_height())
	var tall := rect.size.y / (1.0 - CLOUD_TOP_SHARE)
	var top := rect.position.y - tall * CLOUD_TOP_SHARE
	var per_px := tall / size_px.y
	var left := CLOUD_CUTS.x * size_px.x
	var right := (1.0 - CLOUD_CUTS.y) * size_px.x
	var middle := size_px.x - left - right
	var room := maxf(rect.size.x - (left + right) * per_px, 0.0)
	var humps := maxi(1, roundi(room / (middle * per_px)))
	var hump := room / humps if room > 0.0 else middle * per_px
	# A cloud narrower than its two ends: everything is narrowed alike.
	var squeeze := minf(1.0, rect.size.x / ((left + right) * per_px + hump * humps))
	var x := rect.position.x
	_screen.draw_texture_rect_region(_cloud, Rect2(x, top, left * per_px * squeeze, tall), Rect2(0, 0, left, size_px.y))
	x += left * per_px * squeeze
	for i in humps:
		_screen.draw_texture_rect_region(_cloud, Rect2(x, top, hump * squeeze, tall), Rect2(left, 0, middle, size_px.y))
		x += hump * squeeze
	_screen.draw_texture_rect_region(_cloud, Rect2(x, top, right * per_px * squeeze, tall), Rect2(left + middle, 0, right, size_px.y))


## The dinosaur in its box (back, feet, width, height): the team's pictures, standing before the
## first jump, its two running steps in turn on a cloud, the jump in the air (and falling).
func _draw_dino(camera: float, scale_y: float) -> void:
	var area := _screen.size
	var feet := Vector2(_screen_x(run.x + Config.get_float("minigame.sky.dino_width") * 0.5, camera, scale_y),
			area.y - run.y * scale_y)
	var which := 0
	if run.state == SkyRun.State.RUNNING and run.grounded:
		var stride := Config.get_float("minigame.sky.dino_width") * DINO_STRIDE
		which = 1 + posmod(floori(run.distance / stride), 2)
	elif run.state != SkyRun.State.READY and not run.grounded:
		which = 3
	var texture: Texture2D = _dino[which]
	var tall := Config.get_float("minigame.sky.dino_height") * scale_y / DINO_STAND_SHARE
	var picture := Vector2(tall * texture.get_width() / texture.get_height(), tall)
	_screen.draw_texture_rect(texture, Rect2(feet - picture * DINO_ANCHOR, picture), false)


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
