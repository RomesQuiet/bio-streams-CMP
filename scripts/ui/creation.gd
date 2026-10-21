extends Control
## Avatar creation screen, shown when there is no save. The player types a name and
## chooses the age group, sex and difficulty, then Start opens the main screen.
## Game time does not pass on this screen.

const MAIN_SCENE := "res://scenes/main.tscn"

## Choice id (saved in GameState) -> text on the button.
const AGE_GROUPS := {
	"child": "Child\n(6 to 12 years)",
	"teenager": "Teenager\n(13 to 18 years)",
}
const SEXES := {
	"male": "Male",
	"female": "Female",
}
## Placeholder texts. They describe the starting habits only, in neutral words.
const DIFFICULTIES := {
	"easy": {
		"name": "Easy",
		"description": "Starts with healthy habits: enough sleep, regular physical activity and a good mood.",
	},
	"normal": {
		"name": "Normal",
		"description": "Starts with average habits: some physical activity and sleep, with room to improve.",
	},
	"hard": {
		"name": "Hard",
		"description": "Starts with few healthy habits: little physical activity and short sleep. New habits are easy to take on.",
	},
	"very_hard": {
		"name": "Very hard",
		"description": "Starts with very few healthy habits: almost no physical activity, very short sleep and a low mood. Changing habits too fast is hard on the mood.",
	},
}

@onready var name_edit: LineEdit = %NameEdit
@onready var age_buttons: HBoxContainer = %AgeButtons
@onready var sex_buttons: HBoxContainer = %SexButtons
@onready var difficulty_buttons: GridContainer = %DifficultyButtons
@onready var difficulty_info: Label = %DifficultyInfo
@onready var start_button: Button = %StartButton

var _age_group := ""
var _sex := ""
var _difficulty := ""


func _ready() -> void:
	Clock.set_paused(true)
	name_edit.max_length = Config.get_int("creation.name_max_length")
	name_edit.text_changed.connect(_refresh.unbind(1))
	_add_choice_buttons(age_buttons, AGE_GROUPS, func(id: String) -> void: _age_group = id)
	_add_choice_buttons(sex_buttons, SEXES, func(id: String) -> void: _sex = id)
	var difficulty_names := {}
	for id in DIFFICULTIES:
		difficulty_names[id] = DIFFICULTIES[id]["name"]
	_add_choice_buttons(difficulty_buttons, difficulty_names, func(id: String) -> void: _difficulty = id)
	start_button.pressed.connect(_on_start_pressed)
	_refresh()
	name_edit.grab_focus()


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
	difficulty_info.text = DIFFICULTIES[_difficulty]["description"] if _difficulty else "Choose a difficulty."
	start_button.disabled = name_edit.text.strip_edges().is_empty() \
			or _age_group.is_empty() or _sex.is_empty() or _difficulty.is_empty()


func _on_start_pressed() -> void:
	GameState.avatar_name = name_edit.text.strip_edges()
	GameState.age_group = _age_group
	GameState.sex = _sex
	GameState.difficulty = _difficulty
	GameState.changed.emit()
	# Unpausing is a key moment, so the new game is saved here.
	Clock.set_paused(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
