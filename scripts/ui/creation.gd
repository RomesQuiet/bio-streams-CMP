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
	_add_choice_buttons(age_buttons, AGE_GROUPS, func(id: String) -> void: _age_group = id)
	_add_choice_buttons(sex_buttons, SEXES, func(id: String) -> void: _sex = id)
	var difficulty_names := {}
	for id in DIFFICULTIES:
		difficulty_names[id] = DIFFICULTIES[id]["name"]
	_add_choice_buttons(difficulty_buttons, difficulty_names, func(id: String) -> void: _difficulty = id)
	start_button.pressed.connect(_on_start_pressed)
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
		var button := Button.new()
		button.text = choices[id]
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 88)
		button.pressed.connect(func() -> void:
			on_chosen.call(id)
			_refresh())
		container.add_child(button)


func _refresh() -> void:
	difficulty_info.text = DIFFICULTIES[_difficulty]["description"] if _difficulty else "CREATION_CHOOSE_DIFFICULTY"
	start_button.disabled = name_edit.text.strip_edges().is_empty() \
			or _age_group.is_empty() or _sex.is_empty() or _difficulty.is_empty()


func _on_start_pressed() -> void:
	GameState.start_new_avatar(name_edit.text.strip_edges(), _age_group, _sex, _difficulty)
	# Unpausing is a key moment, so the new game is saved here.
	Clock.set_paused(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
