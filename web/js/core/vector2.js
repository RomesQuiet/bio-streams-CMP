// A 2D vector with the methods of Godot's Vector2 that the game uses.
import {is_equal_approx, clampf} from "./util.js";

export class Vector2 {
	constructor(x = 0, y = 0) {
		this.x = x;
		this.y = y;
	}
	static get ZERO() { return new Vector2(0, 0); }
	static get RIGHT() { return new Vector2(1, 0); }
	add(other) { return new Vector2(this.x + other.x, this.y + other.y); }
	sub(other) { return new Vector2(this.x - other.x, this.y - other.y); }
	mul(factor) { return new Vector2(this.x * factor, this.y * factor); }
	neg() { return new Vector2(-this.x, -this.y); }
	equals(other) { return this.x === other.x && this.y === other.y; }
	is_zero() { return this.x === 0 && this.y === 0; }
	length() { return Math.sqrt(this.x * this.x + this.y * this.y); }
	length_squared() { return this.x * this.x + this.y * this.y; }
	dot(other) { return this.x * other.x + this.y * other.y; }
	distance_to(other) { return Math.sqrt((this.x - other.x) ** 2 + (this.y - other.y) ** 2); }
	normalized() {
		const size = this.length();
		return size === 0 ? new Vector2(0, 0) : new Vector2(this.x / size, this.y / size);
	}
	limit_length(limit = 1) {
		const size = this.length();
		return size > 0 && limit < size ? this.mul(limit / size) : new Vector2(this.x, this.y);
	}
	direction_to(to) { return to.sub(this).normalized(); }
	// Godot: the vector turned 90 degrees (x, y) -> (y, -x).
	orthogonal() { return new Vector2(this.y, -this.x); }
	move_toward(to, delta) {
		const offset = to.sub(this);
		const size = offset.length();
		return size <= delta || size < 0.00001 ? new Vector2(to.x, to.y) : this.add(offset.mul(delta / size));
	}
	is_equal_approx(other) { return is_equal_approx(this.x, other.x) && is_equal_approx(this.y, other.y); }
	clamp(low, high) { return new Vector2(clampf(this.x, low.x, high.x), clampf(this.y, low.y, high.y)); }
	copy() { return new Vector2(this.x, this.y); }
}

// Godot's Geometry2D.get_closest_point_to_segment.
export function closest_point_to_segment(point, from, to) {
	const p = point.sub(from);
	const n = to.sub(from);
	const l2 = n.length_squared();
	if (l2 < 1e-20) return from.copy();
	const d = n.dot(p) / l2;
	if (d <= 0) return from.copy();
	if (d >= 1) return to.copy();
	return from.add(n.mul(d));
}

// A seeded random generator (a seed always gives the same numbers), like Godot's
// RandomNumberGenerator with a seed.
export class RandomNumberGenerator {
	constructor(seed = Date.now()) {
		this.seed = seed;
	}
	set seed(value) {
		this._state = (Number(value) >>> 0) || 1;
	}
	// A number from 0 to 1 (mulberry32).
	randf() {
		this._state = (this._state + 0x6D2B79F5) >>> 0;
		let t = this._state;
		t = Math.imul(t ^ (t >>> 15), t | 1);
		t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	}
}

export function randi() {
	return Math.floor(Math.random() * 4294967296) >>> 0;
}
