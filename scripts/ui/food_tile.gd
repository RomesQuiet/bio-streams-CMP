extends Button
## A food of the canteen (Milestone 21). Milestone 40 (documentation/ui_v2/changes.md, change 11):
## the team's picture (assets/art/food/<id>.png, loaded when the food is set, never while drawing)
## and its name, in two looks:
## - a tile of the grid (slot false): a light rounded tile, the picture 100 x 83 and the name under
##   it (Bold 20, two lines at most); on the plate already (chosen): mint with a green badge;
## - a place on the plate (slot true): the picture 120 x 100, or, when empty, a dashed outline.
## A food without a picture yet keeps the placeholder: a coloured tile with its first letter.
## A flat button: the canteen reacts to its press.

const Canteen := preload("res://scripts/health/canteen.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")
const PICTURES := "res://assets/art/food/%s.png"
const RADIUS := 20.0
const PICTURE_SIZE := Vector2(100, 83)
const PICTURE_Y := 58.0
const NAME_TOP := 110.0
const NAME_BOTTOM := 170.0
const NAME_SIZE := 20
const NAME_LINE := 24.0
const BADGE_FROM_RIGHT := Vector2(-14, 14)
const BADGE_RADIUS := 16.0
const SLOT_RADIUS := 20.0
const DASH := 10.0
const GAP := 8.0
const LETTER_FONT := 36

## True for a place on the plate.
var slot := false
var chosen := false:
	set(value):
		if value != chosen:
			chosen = value
			queue_redraw()
var food_id := "":
	set(value):
		if value != food_id:
			food_id = value
			var path := PICTURES % food_id
			_picture = load(path) if not food_id.is_empty() and ResourceLoader.exists(path) else null
			queue_redraw()
var _picture: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	theme_type_variation = &"ActionButton"


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	self_modulate.a = Ui.DISABLED_ALPHA if disabled and not chosen and not slot else 1.0
	if slot:
		if food_id.is_empty():
			_dashed(Ui.rounded_rect_points(Rect2(Vector2.ONE, size - Vector2(2, 2)), SLOT_RADIUS))
		else:
			_draw_picture(Rect2(Vector2.ZERO, size))
		return
	var face := Ui.EXERCISE_COLOR if chosen else Ui.TILE_COLOR
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(Vector2.ZERO, size), RADIUS), face)
	_draw_picture(Rect2(Vector2(size.x * 0.5, PICTURE_Y) - PICTURE_SIZE * 0.5, PICTURE_SIZE))
	_draw_name(tr(str(Canteen.food(food_id).get("name", food_id))))
	if chosen:
		var centre := Vector2(size.x, 0) + BADGE_FROM_RIGHT
		draw_circle(centre, BADGE_RADIUS, Ui.BADGE_COLOR, true, -1.0, true)
		draw_polyline(PackedVector2Array([centre + Vector2(-7, 0), centre + Vector2(-2, 5), centre + Vector2(7, -5)]), Color.WHITE, 3.5, true)


## The team's picture in rect, or the placeholder (a coloured tile with the first letter).
func _draw_picture(rect: Rect2) -> void:
	if _picture:
		draw_texture_rect(_picture, rect, false)
		return
	var food := Canteen.food(food_id)
	var side := minf(rect.size.x, rect.size.y)
	var tile := Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	draw_colored_polygon(Ui.rounded_rect_points(tile, 16.0), Color.html(str(food.get("color", "#888888"))))
	var letter := tr(str(food.get("name", food_id))).left(1).to_upper()
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, tile.get_center(), letter, LETTER_FONT, Color.WHITE)


## The name centred in x 4 to width - 4 and y 110 to 170, on two lines at most.
func _draw_name(line: String) -> void:
	var width := size.x - 8.0
	var font := Ui.FONT_BOLD
	var lines: Array[String] = [line]
	if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x > width:
		var words := line.split(" ")
		var first := words[0]
		var split := 1
		for i in range(1, words.size()):
			var attempt := first + " " + words[i]
			if font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x > width:
				break
			first = attempt
			split = i + 1
		lines = [first]
		if split < words.size():
			lines.append(" ".join(words.slice(split)))
	var middle := (NAME_TOP + NAME_BOTTOM) * 0.5
	var top := middle - NAME_LINE * (lines.size() - 1) * 0.5
	for i in lines.size():
		var fitted := maxi(Ui.fit_font_size(font, lines[i], NAME_SIZE, width), int(NAME_SIZE * 0.7))
		Ui.draw_centred_text(self, font, Vector2(size.x * 0.5, top + NAME_LINE * i), lines[i], fitted, Ui.INK)


## A dashed closed outline (dash 10, gap 8, 2 px, SLOT_LINE).
func _dashed(points: PackedVector2Array) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	var drawing := true
	var left := DASH
	for i in closed.size() - 1:
		var a := closed[i]
		var b := closed[i + 1]
		var length := a.distance_to(b)
		var done := 0.0
		while done < length:
			var step := minf(left, length - done)
			var from := a.lerp(b, done / length)
			var to := a.lerp(b, (done + step) / length)
			if drawing:
				draw_line(from, to, Ui.SLOT_LINE, 2.0, true)
			done += step
			left -= step
			if left <= 0.0:
				drawing = not drawing
				left = DASH if drawing else GAP
