extends ColorRect
## The explanation of football (Milestone 14, decision 48). It opens the first time someone plays
## on this device, and again from the ? button. The texts are keys of translations/strings.csv.

signal closed

const FootballIcon := preload("res://scripts/ui/football_icon.gd")
const ROWS := [
	["you", "FOOTBALL_HELP_YOU"],
	["goal", "FOOTBALL_HELP_GOAL"],
	["free", "FOOTBALL_HELP_PASS"],
	["other", "FOOTBALL_HELP_TACKLE"],
	["breath", "FOOTBALL_HELP_BREATH"],
]
const ROW_HEIGHT := 72.0
const ICON_WIDTH := 64.0

var _time_label: Label
var _controls: Label
var _play: Button


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 20.0
	panel.offset_top = 60.0
	panel.offset_right = -20.0
	panel.offset_bottom = -60.0
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)
	var title := Label.new()
	title.text = "FOOTBALL_HELP_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	content.add_child(title)
	for row in ROWS:
		content.add_child(_row(row[0], row[1]))
	_time_label = _text("", content)
	_controls = _text("", content)
	_controls.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_play = Button.new()
	_play.text = "FOOTBALL_HELP_PLAY"
	_play.custom_minimum_size = Vector2(0, 76)
	_play.pressed.connect(_on_play)
	content.add_child(_play)


## touch: the player has a touch screen, so the joystick is explained and not the keys.
func open(touch: bool) -> void:
	_time_label.text = tr("FOOTBALL_HELP_TIME") % Config.get_int("minigame.football.time_slowdown")
	_controls.text = "FOOTBALL_HELP_TOUCH" if touch else "FOOTBALL_HELP_KEYS"
	show()
	_play.grab_focus()


func _on_play() -> void:
	hide()
	closed.emit()


func _row(icon_kind: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var icon := FootballIcon.new()
	icon.kind = icon_kind
	icon.custom_minimum_size = Vector2(ICON_WIDTH, ROW_HEIGHT)
	row.add_child(icon)
	var label := _text(key, row)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


func _text(key: String, parent: Control) -> Label:
	var label := Label.new()
	label.text = key
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(200, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
	return label
