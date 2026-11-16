// Godot's translation server for the converted game: reads translations/strings.csv (columns
// keys,en,pt), and tr(key) gives the text in the current language (or the key itself when it
// has none, as Godot does). Escapes like \n in the file become line breaks, as in Godot.
import {Data} from "./data.js";
import {Signal} from "./util.js";

export const TranslationServer = {
	// Emitted when the language changes (Godot's NOTIFICATION_TRANSLATION_CHANGED).
	changed: new Signal(),
	locale: "en",
	_table: {},

	load() {
		TranslationServer._table = {};
		const rows = parse_csv(Data.strings_csv);
		const header = rows[0];
		for (const row of rows.slice(1)) {
			if (row.length < 2 || row[0] === "") continue;
			for (let column = 1; column < header.length; column++) {
				const language = header[column];
				TranslationServer._table[language] ??= {};
				TranslationServer._table[language][row[0]] = unescape(row[column] ?? "");
			}
		}
	},

	set_locale(id) {
		TranslationServer.locale = id;
		TranslationServer.changed.emit();
	},

	has_key(key) {
		return key in (TranslationServer._table.en ?? {});
	},
};

// The text of a key in the current language; anything that is not a key comes back as it is.
export function tr(key) {
	const text = TranslationServer._table[TranslationServer.locale]?.[key];
	return text === undefined || text === "" ? String(key) : text;
}

function unescape(text) {
	return text.replace(/\\(n|t|\\|")/g, (whole, code) => ({n: "\n", t: "\t", "\\": "\\", '"': '"'}[code]));
}

// A CSV file as rows of fields (quoted fields may hold commas and doubled quotes).
export function parse_csv(text) {
	const rows = [];
	let row = [];
	let field = "";
	let quoted = false;
	for (let i = 0; i < text.length; i++) {
		const char = text[i];
		if (quoted) {
			if (char === '"' && text[i + 1] === '"') {
				field += '"';
				i++;
			} else if (char === '"') {
				quoted = false;
			} else {
				field += char;
			}
		} else if (char === '"') {
			quoted = true;
		} else if (char === ",") {
			row.push(field);
			field = "";
		} else if (char === "\n" || char === "\r") {
			if (char === "\r" && text[i + 1] === "\n") i++;
			row.push(field);
			rows.push(row);
			row = [];
			field = "";
		} else {
			field += char;
		}
	}
	if (field !== "" || row.length > 0) {
		row.push(field);
		rows.push(row);
	}
	return rows;
}
