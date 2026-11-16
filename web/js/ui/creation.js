// Avatar creation screen, opened from the menu. The player types a name and chooses the age
// group, sex and difficulty, then Start opens the main screen.
// Game time does not pass on this screen. Settings cannot be reached from here, so the screen
// has its own language buttons (decision 15); what was typed and chosen stays when they are used.
// The name field is the browser's own text field, so phones and tablets type into it with their
// own keyboards (the Godot version needed a pop-up box for that).
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Clock} from "../core/clock.js";
import {Settings} from "../core/settings.js";
import {tr} from "../core/translation.js";
import {Scene} from "./scene.js";
import {Control, Label, Button, Box} from "./widgets.js";

const MAIN_SCENE = "main";
const MENU_SCENE = "menu";

// Choice id (saved in GameState) -> text on the button. All the texts here are translation keys.
const AGE_GROUPS = {child: "CREATION_CHILD", teenager: "CREATION_TEENAGER"};
const SEXES = {male: "CREATION_MALE", female: "CREATION_FEMALE"};
// Placeholder texts. They describe the starting habits only, in neutral words.
const DIFFICULTIES = {
	easy: {name: "CREATION_EASY", description: "CREATION_EASY_INFO"},
	normal: {name: "CREATION_NORMAL", description: "CREATION_NORMAL_INFO"},
	hard: {name: "CREATION_HARD", description: "CREATION_HARD_INFO"},
	very_hard: {name: "CREATION_VERY_HARD", description: "CREATION_VERY_HARD_INFO"},
};

export class Creation {
	constructor(root) {
		this._age_group = "";
		this._sex = "";
		this._difficulty = "";
		const screen = new Control(root, "screen creation-screen");
		this.node = screen.node;
		screen.node._widget = this;
		const layout = new Box(screen, "creation-layout", true, 16);
		const languages = new Box(layout, "language-row", false, 4);
		this.portuguese_button = new Button(languages, "PT", "language-small");
		this.english_button = new Button(languages, "EN", "language-small");
		new Label(layout, "CREATION_TITLE", "size-40 center");
		new Label(layout, "CREATION_NAME");
		// The name field: Godot's LineEdit (text, placeholder and the longest name allowed).
		this.name_edit = new NameField(layout);
		new Label(layout, "CREATION_AGE");
		this.age_buttons = new Box(layout, "", false, 4);
		new Label(layout, "CREATION_SEX");
		this.sex_buttons = new Box(layout, "", false, 4);
		new Label(layout, "CREATION_DIFFICULTY");
		this.difficulty_buttons = new Control(layout, "difficulty-grid");
		this.difficulty_info = new Label(layout, "", "wrap difficulty-info");
		new Control(layout, "grow");
		this.start_button = new Button(layout, "CREATION_START", "h96");
		this.back_button = new Button(layout, "MENU_BACK", "h64");
	}

	_ready() {
		Clock.set_paused(true);
		this.name_edit.max_length = Config.get_int("creation.name_max_length");
		this.name_edit.text_changed.push(() => this._refresh());
		this._add_choice_buttons(this.age_buttons, AGE_GROUPS, (id) => (this._age_group = id));
		this._add_choice_buttons(this.sex_buttons, SEXES, (id) => (this._sex = id));
		const difficulty_names = {};
		for (const [id, difficulty] of Object.entries(DIFFICULTIES)) difficulty_names[id] = difficulty.name;
		this._add_choice_buttons(this.difficulty_buttons, difficulty_names, (id) => (this._difficulty = id));
		this.start_button.pressed.connect(() => this._on_start_pressed());
		// Back to the main menu (Milestone 18): nothing was saved, so the place stays empty.
		this.back_button.pressed.connect(() => Scene.change(MENU_SCENE));
		for (const [id, button] of [["pt", this.portuguese_button], ["en", this.english_button]]) {
			button.toggle_mode = true;
			button.set_pressed_no_signal(Settings.language === id);
			button.pressed.connect(() => {
				this.portuguese_button.set_pressed_no_signal(id === "pt");
				this.english_button.set_pressed_no_signal(id === "en");
				Settings.set_language(id);
			});
		}
		this._refresh();
		this.name_edit.grab_focus();
	}

	// A name typed outside the field. null (Cancel) keeps the name; spaces at the ends are
	// removed and the name is cut to the longest allowed.
	set_typed_name(answer) {
		if (answer === null || answer === undefined) return;
		let typed = String(answer).trim();
		if (this.name_edit.max_length > 0) typed = typed.slice(0, this.name_edit.max_length);
		this.name_edit.text = typed;
		this._refresh();
	}

	// One toggle button per choice. Only one button of the group can be pressed; pressing it
	// calls on_chosen with the choice id.
	_add_choice_buttons(container, choices, on_chosen) {
		const group = [];
		for (const [id, text] of Object.entries(choices)) {
			const button = new Button(container, text, "grow h88");
			button.toggle_mode = true;
			group.push(button);
			button.pressed.connect(() => {
				for (const other of group) other.set_pressed_no_signal(other === button);
				on_chosen(id);
				this._refresh();
			});
		}
	}

	_refresh() {
		this.difficulty_info.text = this._difficulty ? DIFFICULTIES[this._difficulty].description : "CREATION_CHOOSE_DIFFICULTY";
		this.start_button.disabled = this.name_edit.text.trim() === "" || this._age_group === "" || this._sex === ""
			|| this._difficulty === "";
	}

	_on_start_pressed() {
		GameState.start_new_avatar(this.name_edit.text.trim(), this._age_group, this._sex, this._difficulty);
		// Unpausing is a key moment, so the new game is saved here.
		Clock.set_paused(false);
		Scene.change(MAIN_SCENE);
	}
}

// Godot's LineEdit: a text field with a placeholder (a translation key) and a longest length.
class NameField extends Control {
	constructor(parent) {
		super(parent, "name-field", "input");
		this.node.type = "text";
		this.node.autocomplete = "off";
		this.node.spellcheck = false;
		this.text_changed = [];
		this.placeholder_text = "CREATION_NAME_HINT";
		this._max_length = 0;
		this.node.addEventListener("input", () => {
			for (const fn of this.text_changed) fn(this.node.value);
		});
		// Letters typed here are the name, not the game's keys.
		this.node.addEventListener("keydown", (event) => event.stopPropagation());
		this.render();
	}
	get text() {
		return this.node.value ?? "";
	}
	set text(value) {
		this.node.value = String(value);
	}
	get max_length() {
		return this._max_length;
	}
	set max_length(value) {
		this._max_length = value;
		if (value > 0) this.node.maxLength = value;
	}
	render() {
		super.render();
		this.node.placeholder = tr(this.placeholder_text);
	}
	grab_focus() {
		// On a touch screen focusing would open the keyboard over the screen at once.
		if (typeof window !== "undefined" && !("ontouchstart" in window)) this.node.focus?.();
	}
}

Scene.register("creation", Creation);
