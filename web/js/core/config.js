// Loads data/config.json and gives the rest of the game its tunable numbers.
// Usage: Config.get_value("time.day_baseline_hours")
// In debug (the game served from this computer), F6 reloads the file while the game runs.
import {Data} from "./data.js";
import {Signal, push_error} from "./util.js";

export const Config = {
	// Emitted after the config file was read again (F6).
	reloaded: new Signal(),
	_data: {},

	load_config() {
		Config._data = Data.files.config;
		return Config._data != null;
	},

	// Returns the value at a dotted path such as "xp.per_level".
	// Placeholder entries ({"value": ..., "placeholder": true}) return their "value".
	get_value(path) {
		let node = Config._data;
		for (const key of path.split(".")) {
			if (node === null || typeof node !== "object" || Array.isArray(node) || !(key in node)) {
				push_error(`Config: missing key '${path}'`);
				return null;
			}
			node = node[key];
		}
		if (node !== null && typeof node === "object" && !Array.isArray(node) && "value" in node) return node.value;
		return node;
	},

	get_float(path) {
		const value = Config.get_value(path);
		return value !== null ? Number(value) : 0;
	},

	get_int(path) {
		const value = Config.get_value(path);
		return value !== null ? Math.trunc(Number(value)) : 0;
	},

	get_string(path) {
		const value = Config.get_value(path);
		return value !== null ? String(value) : "";
	},

	// True if the entry at this path is marked "placeholder": true or "status": "placeholder".
	is_placeholder(path) {
		let node = Config._data;
		for (const key of path.split(".")) {
			if (node === null || typeof node !== "object" || !(key in node)) return false;
			node = node[key];
		}
		return node !== null && typeof node === "object" && (node.placeholder === true || node.status === "placeholder");
	},
};
