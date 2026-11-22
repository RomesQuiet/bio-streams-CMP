extends Control
## Avatar creation screen, shown when there is no save. The player types a name and
## chooses the age group, sex and difficulty, then Start opens the main screen.
## Game time does not pass on this screen. Settings cannot be reached from here, so the screen
## has its own language buttons (decision 15); what was typed and chosen stays when they are used.
## Phones and tablets in a browser: Godot's web text input only understands real key presses,
## and their on-screen keyboards do not send them (Android sends "Unidentified" keys), so the
## letters never reach the name field. There the field only shows the name, and a tap on it
## opens the browser's own text box, which those keyboards type into normally.

const MAIN_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/ui/menu.tscn"
## The question in the browser's text box, and the field's hint when it opens that box.
const NAME_QUESTION := "CREATION_NAME_QUESTION"
const TAP_HINT := "CREATION_TAP_HINT"

## Choice id (saved in GameState) -> text on the button. All the texts here are translation keys
## (translations/strings.csv); the buttons and labels translate them by themselves, also when
## the language changes.
const AGE_GROUPS := {
	"child": "CREATION_CHILD",
	"teenager": "CREATION_TEENAGER",
}
const SEXES := {
	"male": "CREATION_MALE",
	"female": "CREATION_FEMALE",
}
## Placeholder texts. They describe the starting habits only, in neutral words.
const DIFFICULTIES := {
	"easy": {
		"name": "CREATION_EASY",
		"description": "CREATION_EASY_INFO",
	},
	"normal": {
		"name": "CREATION_NORMAL",
		"description": "CREATION_NORMAL_INFO",
	},
	"hard": {
		"name": "CREATION_HARD",
		"description": "CREATION_HARD_INFO",
	},
	"very_hard": {
		"name": "CREATION_VERY_HARD",
		"description": "CREATION_VERY_HARD_INFO",
	},
}

## The look of the team's picture (21 Nov 2026): each choice's colour and icon (the chosen one has
## a check), read from the picture's pixels.
const ChoiceButton := preload("res://scripts/ui/choice_button.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")
const CHOICE_LOOKS := {
	"child": ["#7efcfd", "child"], "teenager": ["#d2cbfe", "teen"],
	"male": ["#fec864", "male"], "female": ["#afc7ad", "female"],
	"easy": ["#84fb87", ""], "normal": ["#fede57", ""], "hard": ["#ff6d5e", ""], "very_hard": ["#b0234e", ""],
}
## Faces with white text.
const LIGHT_TEXT := ["very_hard"]
const NAME_BORDER := Color("#7dfaf9")
const LANGUAGE_ON := Color("#5efbdc")
const LANGUAGE_OFF := Color("#dcdffb")
const START_FACE := Color("#4afcda")
const LABEL_COLOR := Color("#f4f2fc")

@onready var name_edit: LineEdit = %NameEdit
@onready var age_buttons: HBoxContainer = %AgeButtons
@onready var sex_buttons: HBoxContainer = %SexButtons
@onready var difficulty_buttons: GridContainer = %DifficultyButtons
@onready var difficulty_info: Label = %DifficultyInfo
@onready var start_button: Button = %StartButton
@onready var portuguese_button: Button = %PortugueseButton
@onready var english_button: Button = %EnglishButton

var _age_group := ""
var _sex := ""
var _difficulty := ""


func _ready() -> void:
	Clock.set_paused(true)
	name_edit.max_length = Config.get_int("creation.name_max_length")
	name_edit.text_changed.connect(_refresh.unbind(1))
	var browser_box := OS.has_feature("web") and DisplayServer.is_touchscreen_available()
	if browser_box:
		use_browser_name_box()
	_style_screen()
	_add_choice_buttons(age_buttons, AGE_GROUPS, func(id: String) -> void: _age_group = id)
	_add_choice_buttons(sex_buttons, SEXES, func(id: String) -> void: _sex = id)
	var difficulty_names := {}
	for id in DIFFICULTIES:
		difficulty_names[id] = DIFFICULTIES[id]["name"]
	_add_choice_buttons(difficulty_buttons, difficulty_names, func(id: String) -> void: _difficulty = id)
	start_button.pressed.connect(_on_start_pressed)
	# Back to the main menu (Milestone 18): nothing was saved, so the place stays empty.
	%BackButton.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	var languages := ButtonGroup.new()
	portuguese_button.button_group = languages
	english_button.button_group = languages
	portuguese_button.set_pressed_no_signal(Settings.language == "pt")
	english_button.set_pressed_no_signal(Settings.language == "en")
	portuguese_button.pressed.connect(Settings.set_language.bind("pt"))
	english_button.pressed.connect(Settings.set_language.bind("en"))
	_refresh()
	if not browser_box:
		name_edit.grab_focus()


## The title, labels, name field, language pills, Start and Back in the picture's look.
func _style_screen() -> void:
	var title: Label = %Title
	title.add_theme_font_override("font", Ui.FONT_HEAVY)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(Ui.INK, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", maxi(Ui.fit_font_size(Ui.FONT_HEAVY, tr(title.text), 60, 660.0), 42))
	for label: Label in [$NameLabel, $AgeLabel, $SexLabel, $DifficultyLabel]:
		label.add_theme_font_override("font", Ui.FONT_HEAVY)
		label.add_theme_color_override("font_color", LABEL_COLOR)
	difficulty_info.add_theme_color_override("font_color", LABEL_COLOR)
	var field := StyleBoxFlat.new()
	field.bg_color = Color.WHITE
	field.border_color = NAME_BORDER
	field.set_border_width_all(4)
	field.set_corner_radius_all(24)
	field.content_margin_left = 22.0
	field.content_margin_right = 22.0
	for style in ["normal", "focus", "read_only"]:
		name_edit.add_theme_stylebox_override(style, field)
	name_edit.add_theme_font_override("font", Ui.FONT_HEAVY)
	name_edit.add_theme_font_size_override("font_size", 29)
	name_edit.add_theme_color_override("font_color", Ui.INK)
	name_edit.add_theme_color_override("font_placeholder_color", Color(Ui.INK, 0.45))
	name_edit.add_theme_color_override("caret_color", Ui.INK)
	for button: Button in [portuguese_button, english_button]:
		button.face = LANGUAGE_OFF
		button.chosen_face = LANGUAGE_ON
		button.show_check = false
		button.font_size = 26
	start_button.face = START_FACE
	start_button.base = START_FACE.darkened(0.3)
	start_button.radius = 30.0
	start_button.word_size = 44
	start_button.word_centred = true
	start_button.word_x = start_button.size.x * 0.5
	start_button.word_y = (start_button.size.y - 8.0) * 0.5
	start_button.prefix = "play"
	var back: Button = %BackButton
	back.face = Ui.SLEEP_COLOR
	back.base = Ui.SLEEP_BASE
	back.radius = 28.0
	back.word_size = 32
	back.word_centred = true
	back.word_x = back.size.x * 0.5
	back.word_y = (back.size.y - 8.0) * 0.5
	back.prefix = "back"


## Touch screens in a browser: the name field never takes focus (so Godot does not open its
## own keyboard box), and a tap on it asks for the name in the browser's text box.
func use_browser_name_box() -> void:
	name_edit.focus_mode = Control.FOCUS_NONE
	name_edit.placeholder_text = TAP_HINT
	name_edit.gui_input.connect(_on_name_tapped)


func _on_name_tapped(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	# The field itself must not react (it would try to start editing).
	name_edit.accept_event()
	var tap := event as InputEventMouseButton
	if tap and tap.button_index == MOUSE_BUTTON_LEFT and not tap.pressed:
		set_typed_name(JavaScriptBridge.eval("window.prompt(%s, %s)" % [JSON.stringify(tr(NAME_QUESTION)),
				JSON.stringify(name_edit.text)]))


## A name typed outside the field (in the browser's text box). null (Cancel) keeps the name;
## spaces at the ends are removed and the name is cut to the longest allowed.
func set_typed_name(answer: Variant) -> void:
	if answer == null:
		return
	var typed := str(answer).strip_edges()
	if name_edit.max_length > 0:
		typed = typed.left(name_edit.max_length)
	name_edit.text = typed
	_refresh()


## One toggle button per choice. Only one button of the group can be pressed;
## pressing it calls on_chosen with the choice id.
func _add_choice_buttons(container: Container, choices: Dictionary, on_chosen: Callable) -> void:
	var group := ButtonGroup.new()
	for id in choices:
		var button: Button = ChoiceButton.new()
		button.text = choices[id]
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var look: Array = CHOICE_LOOKS.get(id, ["#eef1fb", ""])
		button.face = Color(look[0])
		button.icon_kind = look[1]
		button.ink = Color.WHITE if id in LIGHT_TEXT else Ui.INK
		button.font_size = 35 if container == difficulty_buttons else 32
		button.icon_box = 80.0 if container == age_buttons else 56.0
		button.custom_minimum_size = Vector2(0, 100 if container == difficulty_buttons else 0)
		button.pressed.connect(func() -> void:
			on_chosen.call(id)
			_refresh())
		container.add_child(button)


func _refresh() -> void:
	difficulty_info.text = DIFFICULTIES[_difficulty]["description"] if _difficulty else "CREATION_CHOOSE_DIFFICULTY"
	for button in [portuguese_button, english_button, start_button]:
		button.queue_redraw()
	start_button.disabled = name_edit.text.strip_edges().is_empty() \
			or _age_group.is_empty() or _sex.is_empty() or _difficulty.is_empty()


func _on_start_pressed() -> void:
	GameState.start_new_avatar(name_edit.text.strip_edges(), _age_group, _sex, _difficulty)
	# Unpausing is a key moment, so the new game is saved here.
	Clock.set_paused(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
