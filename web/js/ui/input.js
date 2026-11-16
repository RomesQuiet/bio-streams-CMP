// Which keys are held down (Godot's Input.is_physical_key_pressed), by their place on the
// keyboard (KeyboardEvent.code), so WASD also works on other layouts.
export const Input = {
	_held: new Set(),
	press(code) {
		Input._held.add(code);
	},
	release(code) {
		Input._held.delete(code);
	},
	// The page lost the keyboard: nothing is held any more.
	release_all() {
		Input._held.clear();
	},
	is_pressed(code) {
		return Input._held.has(code);
	},
	// 1 when any of these keys is held, otherwise 0.
	strength(...codes) {
		return codes.some((code) => Input._held.has(code)) ? 1 : 0;
	},
};
