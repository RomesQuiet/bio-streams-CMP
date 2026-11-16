// Helpers that behave like Godot's built-in functions, so the converted game computes exactly
// what the Godot version did (both use 64-bit numbers).

export const CMP_EPSILON = 0.00001;

export function clampf(value, low, high) {
	return Math.min(Math.max(value, low), high);
}

export function lerpf(from, to, weight) {
	return from + (to - from) * weight;
}

// Godot's is_equal_approx: equal, or closer than a small share of the size.
export function is_equal_approx(a, b) {
	if (a === b) return true;
	let tolerance = CMP_EPSILON * Math.abs(a);
	if (tolerance < CMP_EPSILON) tolerance = CMP_EPSILON;
	return Math.abs(a - b) < tolerance;
}

export function is_zero_approx(value) {
	return Math.abs(value) < CMP_EPSILON;
}

// Godot rounds halves away from zero (JavaScript's Math.round rounds them up).
export function roundf(value) {
	return value < 0 ? -Math.round(-value) : Math.round(value);
}

export function fposmod(value, modulus) {
	const result = value % modulus;
	return result < 0 ? result + modulus : result;
}

export function signf(value) {
	return value > 0 ? 1 : value < 0 ? -1 : 0;
}

// dictionary.get(key, default)
export function get(object, key, fallback) {
	return object != null && Object.prototype.hasOwnProperty.call(object, key) && object[key] !== undefined ? object[key] : fallback;
}

export function deep_copy(value) {
	return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Godot's "%" text formatting: %s, %d, %f with a precision (%.2f; "%.*f" takes the decimals
// from the list), a sign (+), a width (%5d) with "-" (left) or "0" padding, and %%.
export function format(text, args) {
	const values = Array.isArray(args) ? [...args] : [args];
	return text.replace(/%([-+0]*)(\d+)?(\.\*|\.\d+)?([sdf%])/g, (whole, flags, width, precision, kind) => {
		if (kind === "%") return "%";
		let decimals = null;
		if (precision === ".*") decimals = values.shift();
		else if (precision) decimals = Number(precision.slice(1));
		const value = values.shift();
		let shown;
		if (kind === "s") {
			shown = String(value);
		} else if (kind === "d") {
			const whole_number = Math.trunc(Number(value));
			shown = (flags.includes("+") && whole_number >= 0 ? "+" : "") + String(whole_number);
		} else {
			// As Godot: the sign comes from the number before rounding, so -0.0001 is "-0.00".
			const number = Number(value);
			const negative = number < 0 || Object.is(number, -0);
			const size = Math.abs(number);
			shown = (negative ? "-" : flags.includes("+") ? "+" : "") + (decimals === null ? size.toFixed(6) : round_to_text(size, decimals));
		}
		return pad(shown, Number(width ?? 0), flags);
	});
}

function pad(text, width, flags) {
	if (text.length >= width) return text;
	if (flags.includes("-")) return text.padEnd(width, " ");
	if (flags.includes("0") && /^[+-]?\d/.test(text)) {
		const sign = /^[+-]/.test(text) ? text[0] : "";
		return sign + text.slice(sign.length).padStart(width - sign.length, "0");
	}
	return text.padStart(width, " ");
}

// Like C's printf rounding (half away from zero on the decimal value), as Godot uses. size is
// never negative.
function round_to_text(size, decimals) {
	const factor = Math.pow(10, decimals);
	return (roundf(size * factor) / factor).toFixed(decimals);
}

// A Godot signal: connect, disconnect and emit.
export class Signal {
	constructor() {
		this._listeners = [];
	}
	connect(listener) {
		if (!this._listeners.includes(listener)) this._listeners.push(listener);
	}
	disconnect(listener) {
		this._listeners = this._listeners.filter((other) => other !== listener);
	}
	is_connected(listener) {
		return this._listeners.includes(listener);
	}
	emit(...args) {
		for (const listener of [...this._listeners]) listener(...args);
	}
}

export function push_error(message) {
	console.error(message);
}

export function push_warning(message) {
	console.warn(message);
}
