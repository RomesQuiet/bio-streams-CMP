extends Button
## Milestone 40 (documentation/ui_v2/changes.md, change 9): a tile of the exercise and
## entertainment menus: a light rounded face with a thickness of 6, an icon and the option's name.
## A tile only chooses (Start starts); the chosen one is mint with a green thickness and a round
## green badge with a white check at its top right. The Button's own text is the name (translated).

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const DEPTH := 6.0
const RADIUS := 24.0
const ICON_Y := 52.0
const ICON_BOX := 64.0
const NAME_Y := 116.0
const NAME_SIZE := 28
## The badge's centre, from the tile's top-right corner, and its radius.
const BADGE_FROM_RIGHT := Vector2(-18, 18)
const BADGE_RADIUS := 18.0

var icon_kind := ""
var chosen := false:
	set(value):
		if value != chosen:
			chosen = value
			queue_redraw()


func _ready() -> void:
	theme_type_variation = &"ActionButton"
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var height := size.y - DEPTH
	var face := Ui.EXERCISE_COLOR if chosen else Ui.TILE_COLOR
	var base := Ui.MINIGAME_UP_BASE if chosen else Ui.TILE_BASE
	if is_hovered() and not chosen:
		face = face.lightened(0.3)
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(0, DEPTH, size.x, height), RADIUS), base)
	var body := Rect2(Vector2.ZERO, Vector2(size.x, height))
	Ui.draw_gradient_box(self, body, RADIUS, face.lightened(0.05), face)
	if not icon_kind.is_empty():
		Icons.draw(self, icon_kind, Vector2(size.x * 0.5, ICON_Y), ICON_BOX, Ui.INK)
	Ui.draw_centred_text(self, Ui.FONT_BOLD, Vector2(size.x * 0.5, NAME_Y), text, NAME_SIZE, Ui.INK, size.x - 20.0)
	if chosen:
		var centre := Vector2(size.x, 0) + BADGE_FROM_RIGHT
		draw_circle(centre, BADGE_RADIUS, Ui.BADGE_COLOR, true, -1.0, true)
		var check := PackedVector2Array([centre + Vector2(-8, 0), centre + Vector2(-2, 6), centre + Vector2(8, -6)])
		draw_polyline(check, Color.WHITE, 4.0, true)
