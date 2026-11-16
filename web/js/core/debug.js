// Debug features (the speed key, the debug panel, the health log) exist only when the address
// has ?debug, like the Godot version's "running from the editor", so they are never on in the
// published game by accident. Tests set Debug.forced.
export const Debug = {
	forced: null,
	allowed() {
		if (Debug.forced !== null) return Debug.forced;
		return typeof location !== "undefined" && new URLSearchParams(location.search).has("debug");
	},
};
