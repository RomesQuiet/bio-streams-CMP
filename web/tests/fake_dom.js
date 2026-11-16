// A stand-in for the browser's page, enough for the screens to be built and checked in Node
// (like Godot running a scene headless): elements with classes, styles, children, text and
// events. Canvases draw nothing. Nothing has a size on screen.
class ClassList {
	constructor(element) {
		this._element = element;
		this._names = new Set();
	}
	add(...names) {
		for (const name of names) this._names.add(name);
	}
	remove(...names) {
		for (const name of names) this._names.delete(name);
	}
	toggle(name, force) {
		const on = force === undefined ? !this._names.has(name) : Boolean(force);
		if (on) this._names.add(name);
		else this._names.delete(name);
		return on;
	}
	contains(name) {
		return this._names.has(name);
	}
	toString() {
		return [...this._names].join(" ");
	}
}

// A canvas context that accepts every drawing call and draws nothing.
const NO_CONTEXT = new Proxy({}, {
	get(_target, property) {
		if (property === "measureText") return (text) => ({width: String(text).length * 10});
		if (property === "getTransform") return () => ({});
		return () => {};
	},
	set() {
		return true;
	},
});

class FakeElement {
	constructor(tag) {
		this.tagName = String(tag).toUpperCase();
		this.children = [];
		this.parentNode = null;
		this.classList = new ClassList(this);
		this.style = {setProperty: (name, value) => (this.style[name] = value)};
		this.dataset = {};
		this._listeners = {};
		this._text = "";
		this.title = "";
		this.disabled = false;
		this.value = "";
		this.offsetWidth = 0;
		this.offsetHeight = 0;
		this.offsetLeft = 0;
		this.offsetTop = 0;
	}
	get className() {
		return this.classList.toString();
	}
	set className(text) {
		this.classList = new ClassList(this);
		for (const name of String(text).split(/\s+/)) if (name) this.classList.add(name);
	}
	get isConnected() {
		let node = this;
		while (node.parentNode) node = node.parentNode;
		return node === document.body;
	}
	appendChild(child) {
		child.parentNode?.removeChild(child);
		this.children.push(child);
		child.parentNode = this;
		return child;
	}
	insertBefore(child, before) {
		child.parentNode?.removeChild(child);
		const index = before ? this.children.indexOf(before) : -1;
		if (index < 0) this.children.push(child);
		else this.children.splice(index, 0, child);
		child.parentNode = this;
		return child;
	}
	removeChild(child) {
		const index = this.children.indexOf(child);
		if (index >= 0) this.children.splice(index, 1);
		child.parentNode = null;
		return child;
	}
	remove() {
		this.parentNode?.removeChild(this);
	}
	replaceChildren(...nodes) {
		for (const child of [...this.children]) this.removeChild(child);
		for (const node of nodes) this.appendChild(node);
	}
	get textContent() {
		return this._text + this.children.map((child) => child.textContent).join("");
	}
	set textContent(text) {
		this.replaceChildren();
		this._text = String(text);
	}
	addEventListener(type, listener) {
		(this._listeners[type] ??= []).push(listener);
	}
	removeEventListener(type, listener) {
		this._listeners[type] = (this._listeners[type] ?? []).filter((other) => other !== listener);
	}
	dispatchEvent(event) {
		for (const listener of [...(this._listeners[event.type] ?? [])]) listener(event);
		return true;
	}
	click() {
		if (!this.disabled) this.dispatchEvent({type: "click", button: 0});
	}
	focus() {}
	blur() {}
	setPointerCapture() {}
	getBoundingClientRect() {
		return {left: 0, top: 0, width: this.offsetWidth, height: this.offsetHeight};
	}
	getContext() {
		return NO_CONTEXT;
	}
	// Only ".class" selectors.
	closest(selector) {
		let node = this;
		while (node) {
			if (node.classList?.contains(selector.replace(/^\./, ""))) return node;
			node = node.parentNode;
		}
		return null;
	}
}

export function install_fake_dom() {
	const body = new FakeElement("body");
	globalThis.document = {
		body,
		createElement: (tag) => new FakeElement(tag),
	};
	return body;
}

// Every text shown inside an element, one per line (labels and buttons).
export function texts(node) {
	let found = "";
	for (const child of node.children) {
		if (child._text) found += child._text + "\n";
		found += texts(child);
	}
	return found;
}
