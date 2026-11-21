extends Control
## Milestone 40: the main menu's language switch, as in the team's splash screen: a see-through
## capsule with a thin light line, "PT" on the left and "EN" on the right; the chosen half is a
## light pill with a cyan line and navy letters. A tap on a half chooses that language.

const Ui := preload("res://scripts/ui/ui_style.gd")

const LANGUAGES := ["pt", "en"]
const LABELS := ["PT", "EN"]
const FONT_SIZE := 27


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		choose(LANGUAGES[0] if event.position.x < size.x * 0.5 else LANGUAGES[1])
		accept_event()


func choose(id: String) -> void:
	Settings.set_language(id)
	queue_redraw()


func _draw() -> void:
	var radius := size.y * 0.5 - 0.5
	var track := Rect2(Vector2.ZERO, size)
	Ui.draw_gradient_box(self, track, radius, Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.1))
	Ui.draw_outline(self, Ui.rounded_rect_points(track.grow(-1.0), radius - 1.0), Color(1, 1, 1, 0.4), Ui.BORDER_THIN)
	var chosen := LANGUAGES.find(Settings.language)
	var half := size.x * 0.5
	if chosen >= 0:
		var pill := Rect2(half * chosen, 0.0, half, size.y)
		Ui.draw_gradient_box(self, pill, radius, Ui.MENU_TOGGLE_ON, Ui.MENU_TOGGLE_ON)
		Ui.draw_outline(self, Ui.rounded_rect_points(pill.grow(-1.5), radius - 1.5), Ui.XP_COLOR, Ui.BORDER_MEDIUM)
	for i in LANGUAGES.size():
		var color := Ui.INK if i == chosen else Color(1, 1, 1, 0.8)
		Ui.draw_centred_text(self, Ui.FONT_HEAVY, Vector2(half * (i + 0.5), size.y * 0.5), LABELS[i], FONT_SIZE, color)
