// The main menu (Milestone 18, user, 7 Nov 2026): the first screen. Continue (the avatar played
// last), New avatar, Avatars (save.slots places: play, back up, delete), Load a backup, About
// and the language. The lobby's look: the sky, the grey ground and the last avatar standing; the
// team's pictures of the creation process and the music come later (placeholders).
// Every text is a translation key.
import {Config} from "../core/config.js";
import {Settings} from "../core/settings.js";
import {SaveGame} from "../core/save_game.js";
import {tr} from "../core/translation.js";
import {format} from "../core/util.js";
import {Scene} from "./scene.js";
import {Control, Label, Button, Panel, Box} from "./widgets.js";
import {AvatarView} from "./avatar_view.js";
import {download_text} from "./debug_panel.js";

const MAIN_SCENE = "main";
const CREATION_SCENE = "creation";
const FAILED_COLOR = "rgb(255, 128, 115)";

export class Menu {
	constructor(root) {
		// The place whose Delete is waiting for its second press (-1: none).
		this._confirm_delete = -1;
		this._build(root);
	}

	_ready() {
		// The menu never plays: the game is emptied and time stands still.
		SaveGame.unload();
		this._refresh();
		if (SaveGame.menu_request === "new_avatar") {
			SaveGame.menu_request = "";
			this._new_avatar();
		}
	}

	_translation_changed() {
		this._refresh();
	}

	// --- Layout --------------------------------------------------------------------------------

	_build(root) {
		const screen = new Control(root, "screen menu-screen");
		this.node = screen.node;
		screen.node._widget = this;
		new Control(screen, "menu-ground");
		new Label(screen, "MENU_TITLE", "menu-title center");
		new Label(screen, "MENU_SUBTITLE", "menu-subtitle center");
		this._avatar = new AvatarView(screen, "menu-avatar");
		this._home = new Box(screen, "menu-home", true, 14);
		this._continue_button = this._button(this._home, "", () => this._continue(), "h96");
		const row = new Box(this._home, "", false, 14);
		this._button(row, "MENU_NEW_AVATAR", () => this._new_avatar(), "h76 grow");
		this._button(row, "MENU_AVATARS", () => this._open_avatars(), "h76 grow");
		const row2 = new Box(this._home, "", false, 14);
		this._button(row2, "MENU_LOAD_BACKUP", () => this._load_backup(), "h76 grow");
		this._button(row2, "MENU_ABOUT", () => this._open_about(), "h76 grow");
		const languages = new Box(this._home, "", false, 14);
		this._language_buttons = {};
		for (const id of ["pt", "en"]) {
			const language = this._button(languages, id === "pt" ? "Português" : "English", () => this._choose_language(id), "h64 grow");
			language.toggle_mode = true;
			language.set_pressed_no_signal(Settings.language === id);
			this._language_buttons[id] = language;
		}
		this._avatars_page = this._page(screen, "MENU_AVATARS");
		const content = this._avatars_page.content;
		this._message = new Label(content, "", "size-20 wrap center");
		this._cards = new Box(content, "", true, 12);
		this._button(content, "MENU_BACK", () => this._close_pages(), "h64");
		this._about_page = this._page(screen, "MENU_ABOUT");
		const about = this._about_page.content;
		const scroll = new Control(about, "about-scroll");
		new Label(scroll, "MENU_ABOUT_TEXT", "size-20 wrap");
		this._button(about, "MENU_BACK", () => this._close_pages(), "h64");
	}

	// A page over the menu in the settings panel's style; its content box is page.content.
	_page(screen, title_key) {
		const dim = new Control(screen, "overlay menu-page");
		dim.visible = false;
		const panel = new Panel(dim, "menu-page-panel");
		dim.content = new Box(panel, "", true, 16);
		new Label(dim.content, title_key, "size-32 center");
		return dim;
	}

	_button(parent, text, on_pressed, classes) {
		const button = new Button(parent, text, classes);
		button.pressed.connect(on_pressed);
		return button;
	}

	_choose_language(id) {
		for (const [other, button] of Object.entries(this._language_buttons)) button.set_pressed_no_signal(other === id);
		Settings.set_language(id);
	}

	// --- What the menu shows -------------------------------------------------------------------

	_refresh() {
		const last = Settings.last_slot < SaveGame.slot_count() ? Settings.last_slot : 0;
		const avatar = SaveGame.slot_summary(last);
		const empty = Object.keys(avatar).length === 0;
		this._continue_button.visible = !empty;
		if (!empty) this._continue_button.text = `${tr("MENU_CONTINUE")}\n${this.summary_text(avatar)}`;
		this._show_avatar(this._avatar, avatar);
		if (this._avatars_page.visible) this._build_cards();
	}

	// One line about an avatar: its name, level, health and days, or that it failed.
	summary_text(avatar) {
		const days = Settings.number(Number(avatar.sim_hours ?? 0) / Config.get_float("units.hours_per_day"), 1);
		if (String(avatar.failed_cause ?? "") !== "") return format(tr("MENU_SUMMARY_FAILED"), [avatar.avatar_name ?? "", days]);
		const level = Math.floor(Number(avatar.xp ?? 0) / Math.max(1, Config.get_float("xp.per_level")));
		return format(tr("MENU_SUMMARY"), [avatar.avatar_name ?? "", level, Settings.number(Number(avatar.health ?? 0), 1), days]);
	}

	// The avatar's picture from its saved values (the egg when there is none).
	_show_avatar(picture, avatar) {
		if (Object.keys(avatar).length === 0) {
			picture.sheet = "";
			picture.states = {};
			return;
		}
		const z = Number(avatar.weight_z ?? 0);
		const happiness = Number(avatar.happiness ?? 0);
		picture.states = {
			thin: z < Config.get_float("avatar_states.thin_below_z"),
			overweight: z > Config.get_float("avatar_states.overweight_above_z"),
			obese: z > Config.get_float("avatar_states.obese_above_z"),
			muscular: Number(avatar.strength ?? 0) >= Config.get_float("avatar_states.muscular_strength"),
			happy: happiness >= Config.get_float("avatar_states.happy_from"),
			sad: happiness < Config.get_float("avatar_states.sad_below") || String(avatar.failed_cause ?? "") !== "",
		};
		picture.sheet = `${avatar.age_group ?? ""}_${avatar.sex ?? ""}`;
	}

	// The avatars page: one card per place, with Play, Backup and Delete, or New avatar.
	_build_cards() {
		this._cards.clear_children();
		for (let place = 0; place < SaveGame.slot_count(); place++) {
			const avatar = SaveGame.slot_summary(place);
			const empty = Object.keys(avatar).length === 0;
			const card = new Panel(this._cards, "card");
			const row = new Box(card, "", false, 12);
			const picture = new AvatarView(row, "card-avatar", {x: 88, y: 120});
			this._show_avatar(picture, avatar);
			const column = new Box(row, "grow", true, 6);
			const line = new Label(column, empty ? tr("MENU_EMPTY_PLACE") : this.summary_text(avatar), "size-20 wrap");
			if (String(avatar.failed_cause ?? "") !== "") line.color = FAILED_COLOR;
			const buttons = new Box(column, "", false, 8);
			if (empty) {
				this._button(buttons, "MENU_NEW_AVATAR", () => this._start_in(place), "h56 grow");
			} else if (this._confirm_delete === place) {
				line.text = format(tr("MENU_DELETE_QUESTION"), [avatar.avatar_name ?? ""]);
				this._button(buttons, "UI_CANCEL", () => this._ask_delete(-1), "h56 grow");
				this._button(buttons, "MENU_DELETE_YES", () => this._delete(place), "h56 grow");
			} else {
				this._button(buttons, "MENU_PLAY", () => this._play(place), "h56 grow");
				this._button(buttons, "MENU_BACKUP", () => this._download_backup(place), "h56 grow");
				this._button(buttons, "MENU_DELETE", () => this._ask_delete(place), "h56 grow");
			}
		}
	}

	// --- Actions -------------------------------------------------------------------------------

	_continue() {
		this._play(Settings.last_slot < SaveGame.slot_count() ? Settings.last_slot : 0);
	}

	_play(place) {
		if (SaveGame.play_slot(place)) Scene.change(MAIN_SCENE);
	}

	// A new avatar in the first free place; when all are taken, the avatars page says so.
	_new_avatar() {
		const place = SaveGame.first_free_slot();
		if (place < 0) {
			this._open_avatars("MENU_FULL");
			return;
		}
		this._start_in(place);
	}

	_start_in(place) {
		SaveGame.start_slot(place);
		Scene.change(CREATION_SCENE);
	}

	_open_avatars(message = "") {
		this._confirm_delete = -1;
		this._message.text = message;
		this._message.visible = message !== "";
		this._build_cards();
		this._about_page.hide();
		this._avatars_page.show();
	}

	_open_about() {
		this._avatars_page.hide();
		this._about_page.show();
	}

	_close_pages() {
		this._avatars_page.hide();
		this._about_page.hide();
		this._refresh();
	}

	_ask_delete(place) {
		this._confirm_delete = place;
		this._build_cards();
	}

	_delete(place) {
		SaveGame.delete_slot(place);
		this._confirm_delete = -1;
		this._message.visible = false;
		this._build_cards();
		this._refresh();
	}

	// --- Backups -------------------------------------------------------------------------------

	_download_backup(place) {
		const text = SaveGame.backup_text(place);
		if (text === "") return;
		const file_name = `${validate_filename(String(SaveGame.slot_summary(place).avatar_name ?? "avatar"))}-backup.json`;
		download_text(file_name, text, "application/json");
		this._show_message("MENU_BACKUP_DONE");
	}

	// Loads a backup file into the first free place.
	_load_backup() {
		if (SaveGame.first_free_slot() < 0) {
			this._open_avatars("MENU_FULL");
			return;
		}
		const input = document.createElement("input");
		input.type = "file";
		input.accept = ".json,application/json";
		input.onchange = () => {
			const file = input.files[0];
			if (!file) return;
			const reader = new FileReader();
			reader.onload = () => this.restore(String(reader.result));
			reader.readAsText(file);
		};
		input.click();
	}

	// The text of a backup file: into the first free place, or a message why not.
	restore(text) {
		const place = SaveGame.first_free_slot();
		if (place < 0) this._open_avatars("MENU_FULL");
		else if (SaveGame.restore_backup(text, place)) this._open_avatars("MENU_BACKUP_LOADED");
		else this._open_avatars("MENU_BACKUP_INVALID");
		this._refresh();
	}

	_show_message(key) {
		this._message.text = key;
		this._message.visible = true;
	}
}

// Godot's String.validate_filename(): characters a file name cannot have become "_".
function validate_filename(text) {
	return text.replace(/[:/\\?*"|%<>]/g, "_");
}

Scene.register("menu", Menu);
