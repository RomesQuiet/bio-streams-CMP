// A sliding window of the last N avatar hours, for sums over the last 24 hours (Milestone 10:
// kcal eaten and spent, effective exercise minutes). It keeps one slot per avatar hour plus
// one: the current hour and the N hours before it. The oldest of those counts only for the
// part of it that is still inside the window (if 20 minutes of the current hour have passed,
// the last 40 minutes of the oldest hour), so the sum is a true sliding N-hour sum when the
// values are spread evenly over each hour.
// A window is an object {hour: newest avatar hour, key: [one value per slot], ...}, so it
// can be saved as it is. Slots of hours that passed are cleared before new values go in.

export const HourWindow = {
	// A window of this many hours with these keys. Every past hour of a key starts at
	// per_slot[key] (0 if missing), as if that value had been added every hour before the start;
	// the current hour (hour 0) starts empty.
	create(hours, per_slot, keys) {
		const window = {hour: 0};
		for (const key of keys) {
			const values = [];
			for (let i = 0; i < hours + 1; i++) values.push(Number(per_slot[key] ?? 0));
			values[0] = 0;
			window[key] = values;
		}
		return window;
	},

	// Adds a value to the slot of this avatar hour (hours since the avatar was created).
	add(window, avatar_hours, key, value) {
		_move_to(window, Math.floor(avatar_hours));
		const slots = window[key].length;
		window[key][Math.floor(avatar_hours) % slots] += value;
	},

	// How many hours (N) the window covers.
	hours(window) {
		for (const key in window) {
			if (key !== "hour") return window[key].length - 1;
		}
		return 0;
	},

	// Sum of a key over the last N hours, as seen at this avatar hour.
	total(window, avatar_hours, key) {
		const hour = Math.floor(avatar_hours);
		_move_to(window, hour);
		const values = window[key];
		const slots = values.length;
		const oldest = (hour + 1) % slots;
		let sum = 0;
		for (let i = 0; i < slots; i++) {
			if (i !== oldest) sum += Number(values[i]);
		}
		return sum + Number(values[oldest]) * (1 - (avatar_hours - hour));
	},
};

// Clears the slots of the hours between the newest slot and this hour.
function _move_to(window, hour) {
	const newest = Math.trunc(Number(window.hour));
	if (hour <= newest) return;
	const keys = Object.keys(window).filter((key) => key !== "hour");
	const slots = window[keys[0]].length;
	for (let h = Math.max(newest + 1, hour - slots + 1); h < hour + 1; h++) {
		for (const key of keys) window[key][h % slots] = 0;
	}
	window.hour = hour;
}
