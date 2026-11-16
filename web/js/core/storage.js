// Where the game keeps saves and settings: the browser's localStorage (written at once, kept
// by the browser for this site). The Godot web version used the same keys, so avatars saved by
// it are found by the converted game. Without a browser (the Node tests) an in-memory store
// takes its place.
const memory = new Map();

function store() {
	try {
		if (typeof window !== "undefined" && window.localStorage) return window.localStorage;
	} catch (error) {
		// Private windows can block localStorage: fall back to memory.
	}
	return null;
}

export const Storage = {
	get(key) {
		const local = store();
		try {
			if (local) return local.getItem(key) ?? "";
		} catch (error) {
			return "";
		}
		return memory.get(key) ?? "";
	},
	set(key, text) {
		const local = store();
		try {
			if (local) {
				local.setItem(key, text);
				return;
			}
		} catch (error) {
			return;
		}
		memory.set(key, text);
	},
	remove(key) {
		const local = store();
		try {
			if (local) {
				local.removeItem(key);
				return;
			}
		} catch (error) {
			return;
		}
		memory.delete(key);
	},
	// Tests: forget everything kept in memory.
	clear_memory() {
		memory.clear();
	},
};
