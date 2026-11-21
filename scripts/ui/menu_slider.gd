extends HSlider
## Milestone 40 (documentation/ui_v2/changes.md, change 9): the minutes slider of the exercise and
## entertainment menus: a track 12 high with round ends, a cyan fill up to the value and a white
## handle (radius 16) with a soft shadow 3 px below. The control is 48 high (the touch area); the
## slider's own drawing is hidden and the handle is drawn here where Godot puts its grabber.

const Ui := preload("res://scripts/ui/ui_style.gd")

const TRACK_HEIGHT := 12.0
const HANDLE_RADIUS := 16.0
const SHADOW_DROP := 3.0


func _ready() -> void:
	var empty := StyleBoxEmpty.new()
	for style in ["slider", "grabber_area", "grabber_area_highlight"]:
		add_theme_stylebox_override(style, empty)
	# An invisible grabber as wide as the handle, so Godot drags it at the right place.
	var image := Image.create(int(HANDLE_RADIUS * 2.0), int(HANDLE_RADIUS * 2.0), false, Image.FORMAT_RGBA8)
	var invisible := ImageTexture.create_from_image(image)
	for icon in ["grabber", "grabber_highlight", "grabber_disabled"]:
		add_theme_icon_override(icon, invisible)
	value_changed.connect(queue_redraw.unbind(1))


func _draw() -> void:
	var middle := size.y * 0.5
	var track := Rect2(0.0, middle - TRACK_HEIGHT * 0.5, size.x, TRACK_HEIGHT)
	var radius := TRACK_HEIGHT * 0.5 - 0.5
	draw_colored_polygon(Ui.rounded_rect_points(track, radius), Ui.TRACK)
	var share := 0.0 if is_equal_approx(max_value, min_value) else (value - min_value) / (max_value - min_value)
	var x := HANDLE_RADIUS + share * (size.x - HANDLE_RADIUS * 2.0)
	if x > TRACK_HEIGHT:
		draw_colored_polygon(Ui.rounded_rect_points(Rect2(track.position, Vector2(x, TRACK_HEIGHT)), radius), Ui.XP_COLOR)
	draw_circle(Vector2(x, middle + SHADOW_DROP), HANDLE_RADIUS, Ui.SHADOW_INK, true, -1.0, true)
	draw_circle(Vector2(x, middle), HANDLE_RADIUS, Color.WHITE, true, -1.0, true)
