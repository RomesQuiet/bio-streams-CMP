// The data files of the game (data/*.json, translations/strings.csv, data/avatar_art.json).
// In the browser they are fetched once at the start; the Node tests read them from disk.

export const DATA_FILES = {
	config: "data/config.json",
	activities: "data/activities.json",
	foods: "data/foods.json",
	who_bmi: "data/who_bmi_for_age.json",
	who_height: "data/who_height_for_age.json",
	avatar_art: "data/avatar_art.json",
};
export const STRINGS_FILE = "translations/strings.csv";

export const Data = {
	files: {},
	strings_csv: "",
};

// Browser: fetches every file relative to base (the folder that holds data/ and translations/).
export async function load_data(base) {
	const entries = await Promise.all(Object.entries(DATA_FILES).map(async ([name, path]) => {
		const response = await fetch(base + path, {cache: "no-cache"});
		return [name, await response.json()];
	}));
	Data.files = Object.fromEntries(entries);
	Data.strings_csv = await (await fetch(base + STRINGS_FILE, {cache: "no-cache"})).text();
}
