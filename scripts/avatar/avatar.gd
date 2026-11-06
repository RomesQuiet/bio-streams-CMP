@tool
extends Control
## The avatar, filling this control's rect; the bottom of the rect is the ground.
## With a sheet (Milestone 16, data/avatar_art.json) it draws the team's art: one cell per body
## and face. Without one (before the avatar is created, in the editor) it draws the placeholder
## egg.

const ART_PATH := "res://data/avatar_art.json"
## Where the egg's mouth is, as a share of the height.
const EGG_MOUTH_Y := 0.55

@export var body_color := Color(0.98, 0.9, 0.75)
@export var outline_color := Color(0.35, 0.25, 0.2)
@export var eye_color := Color(0.15, 0.12, 0.1)
@export_range(16, 128) var point_count := 64
## Placeholder sleep animation: slow breathing (squash and stretch) in seconds per breath.
@export var breath_seconds := 2.4
@export var breath_squash := Vector2(1.04, 0.96)
## Placeholder hop used by activities without their own animation yet.
@export var hop_seconds := 0.6
@export var hop_height := 24.0
## Placeholder exercise animations: cardio is a fast, high hop; strength is a slow
## squat (squash and stretch).
@export var cardio_seconds := 0.35
@export var cardio_height := 36.0
## One stride of the cardio minigame while walking.
@export var walk_height := 12.0
@export var strength_seconds := 1.4
@export var strength_squash := Vector2(1.08, 0.88)
## Eating: a quick, small squash (chewing).
@export var eat_seconds := 0.5
@export var eat_squash := Vector2(1.03, 0.97)
## Placeholder looks for the avatar states (Milestone 10 Task 8): body width when thin or
## overweight, outline width when muscular, and the mouth.
@export var thin_width := 0.85
@export var overweight_width := 1.2
@export var outline_width := 4.0
@export var muscular_outline_width := 8.0
@export var mouth_width := 0.16
@export var mouth_curve := 0.03
## Placeholder Ill look (Milestone 10.5): a pale, greenish body.
@export var ill_color := Color(0.82, 0.88, 0.7)
## The Ill look on the art: the drawing is tinted with this colour.
@export var ill_tint := Color(0.8, 0.95, 0.65)

## The art sheet: "<age group>_<sex>", a key of "sheets" in data/avatar_art.json, or "" (or a key
## that is not there) for the egg.
var sheet := "":
	set(value):
		if value != sheet:
			sheet = value
			_load_sheet()
			queue_redraw()

static var _art := {}
var _texture: Texture2D
var _mouth_y := EGG_MOUTH_Y

## Avatar states shown by the looks (AvatarStates.current()): "tired", "sad", "happy", "ill",
## "thin", "overweight", "obese", "muscular" (true or false). Muscular with fat is muscular and
## overweight: the art shows the overweight body (user, 6 Nov 2026).
var states: Dictionary = {}:
	set(value):
		if value != states:
			states = value
			queue_redraw()

var eyes_closed := false:
	set(value):
		eyes_closed = value
		queue_redraw()

## How far the avatar is drawn above the ground during hops. Animations change this
## instead of the node's position, so they never fight the screen layout.
var hop_offset := 0.0:
	set(value):
		hop_offset = value
		queue_redraw()

var _animation: Tween


func _ready() -> void:
	resized.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.y)
	queue_redraw()


## Plays a repeating placeholder animation by name (from data/activities.json)
## until stop_animation() is called. Unknown names use a simple hop. The art does not move
## (user, 6 Nov 2026): it only closes its eyes to sleep.
func play_animation(animation_name: String) -> void:
	stop_animation()
	if has_art():
		eyes_closed = animation_name == "sleep"
		return
	_animation = create_tween().set_loops()
	_animation.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match animation_name:
		"sleep":
			eyes_closed = true
			_animation.tween_property(self, "scale", breath_squash, breath_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, breath_seconds * 0.5)
		"cardio":
			_animation.tween_property(self, "hop_offset", cardio_height, cardio_seconds * 0.5)
			_animation.tween_property(self, "hop_offset", 0.0, cardio_seconds * 0.5)
		"strength":
			_animation.tween_property(self, "scale", strength_squash, strength_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, strength_seconds * 0.5)
		"eat":
			_animation.tween_property(self, "scale", eat_squash, eat_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, eat_seconds * 0.5)
		_:
			_animation.tween_property(self, "hop_offset", hop_height, hop_seconds * 0.5)
			_animation.tween_property(self, "hop_offset", 0.0, hop_seconds * 0.5)


## One hop for one stride of the cardio minigame.
func stride(walking: bool) -> void:
	if has_art():
		return
	stop_animation()
	_animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(self, "hop_offset", walk_height if walking else cardio_height, cardio_seconds * 0.5)
	_animation.tween_property(self, "hop_offset", 0.0, cardio_seconds * 0.5)


## Down or up for one press of the strength minigame.
## Meal minigame: the mouth opens when the fork is close.
var mouth_open := false:
	set(value):
		if mouth_open != value:
			mouth_open = value
			queue_redraw()


## Meal minigame: a quick squash for a bite.
func chew() -> void:
	if has_art():
		return
	if _animation:
		_animation.kill()
	_animation = create_tween()
	_animation.tween_property(self, "scale", eat_squash, eat_seconds * 0.5)
	_animation.tween_property(self, "scale", Vector2.ONE, eat_seconds * 0.5)


func squat(down: bool) -> void:
	if has_art():
		return
	if _animation:
		_animation.kill()
	_animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(self, "scale", strength_squash if down else Vector2.ONE, strength_seconds * 0.5)


## Where the mouth is, in this control (the meal fork aims there).
func mouth_point() -> Vector2:
	return Vector2(size.x * 0.5, size.y * _mouth_y)


## The cell of the art for the current states: x is the body column, y the face row
## (data/avatar_art.json). Weight wins over muscles; asleep, tired and sad win over happy.
func frame() -> Vector2i:
	var art := art_data()
	var body := "healthy"
	for state in ["obese", "overweight", "thin", "muscular"]:
		if states.get(state, false):
			body = state
			break
	var face := "neutral"
	if eyes_closed:
		face = "asleep"
	elif states.get("tired", false):
		face = "tired"
	elif states.get("sad", false):
		face = "sad"
	elif states.get("happy", false):
		face = "happy"
	return Vector2i(art["columns"].find(body), art["rows"].find(face))


## Whether the art is drawn (otherwise the egg).
func has_art() -> bool:
	return _texture != null


static func art_data() -> Dictionary:
	if _art.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
		_art = parsed if parsed is Dictionary else {"columns": [], "rows": [], "sheets": {}}
	return _art


func _load_sheet() -> void:
	_texture = null
	_mouth_y = EGG_MOUTH_Y
	var entry: Dictionary = art_data()["sheets"].get(sheet, {})
	if entry.has("path") and ResourceLoader.exists(entry["path"]):
		_texture = load(entry["path"])
		_mouth_y = float(entry["mouth_y"])


func stop_animation() -> void:
	if _animation:
		_animation.kill()
		_animation = null
	hop_offset = 0.0
	scale = Vector2.ONE
	eyes_closed = false


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -hop_offset))
	if _texture:
		_draw_art()
		return
	var points := _egg_points()
	var fill := ill_color if states.get("ill", false) else body_color
	draw_colored_polygon(points, fill)
	points.append(points[0])
	var line_width := muscular_outline_width if states.get("muscular", false) else outline_width
	draw_polyline(points, outline_color, line_width, true)
	var eye_y := size.y * 0.42
	var eye_radius := size.x * 0.05
	for eye_x in [size.x * 0.38, size.x * 0.62]:
		if eyes_closed:
			draw_line(Vector2(eye_x - eye_radius, eye_y), Vector2(eye_x + eye_radius, eye_y), eye_color, 4.0, true)
		else:
			draw_circle(Vector2(eye_x, eye_y), eye_radius, eye_color)
			if states.get("tired", false):
				# Heavy eyelids: the top half of the eye is covered.
				draw_rect(Rect2(eye_x - eye_radius, eye_y - eye_radius, eye_radius * 2.0, eye_radius), fill)
				draw_line(Vector2(eye_x - eye_radius, eye_y), Vector2(eye_x + eye_radius, eye_y), outline_color, 3.0, true)
	if not eyes_closed:
		_draw_mouth(states.get("sad", false))


## The cell of the art for the current states, stretched over this control (the cells have its
## size), and an open mouth for the meal minigame.
func _draw_art() -> void:
	var art := art_data()
	var cell := _texture.get_size() / Vector2(art["columns"].size(), art["rows"].size())
	var region := Rect2(cell * Vector2(frame()), cell)
	draw_texture_rect_region(_texture, Rect2(Vector2.ZERO, size), region, ill_tint if states.get("ill", false) else Color.WHITE)
	if mouth_open and not eyes_closed:
		draw_circle(mouth_point(), size.x * mouth_width * 0.3, outline_color)


## A small smile, or a frown when sad.
func _draw_mouth(sad: bool) -> void:
	var center := mouth_point()
	var half := size.x * mouth_width * 0.5
	if mouth_open:
		draw_circle(center, half * 0.7, outline_color)
		return
	var bend := size.y * mouth_curve * (-1.0 if sad else 1.0)
	var mouth := PackedVector2Array()
	for i in 9:
		var t := i / 8.0 * 2.0 - 1.0
		mouth.append(center + Vector2(t * half, bend * (1.0 - t * t)))
	draw_polyline(mouth, outline_color, 3.0, true)


## Egg outline: an ellipse whose top half is taller and narrower than its bottom half.
func _egg_points() -> PackedVector2Array:
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var top_height := size.y * 0.58
	var bottom_height := size.y * 0.42
	var half_width := size.x * 0.5
	if states.get("thin", false):
		half_width *= thin_width
	elif states.get("overweight", false):
		half_width *= overweight_width
	var points := PackedVector2Array()
	for i in point_count:
		var angle := TAU * i / point_count
		var s := sin(angle)
		var narrowing := 1.0 - 0.15 * maxf(0.0, -s)
		var height := bottom_height if s > 0.0 else top_height
		points.append(center + Vector2(cos(angle) * half_width * narrowing, s * height))
	return points
