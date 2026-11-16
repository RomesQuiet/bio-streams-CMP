// Runs the converted game without a browser, for the tests (like Godot's --headless -s).
// Loads the data files from the project folder and starts the autoloads in their order.
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {Data, DATA_FILES, STRINGS_FILE} from "../js/core/data.js";
import {Debug} from "../js/core/debug.js";
import {start_autoloads} from "../js/core/engine.js";

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

export function setup() {
	for (const [name, file] of Object.entries(DATA_FILES)) Data.files[name] = JSON.parse(fs.readFileSync(path.join(ROOT, file), "utf8"));
	Data.strings_csv = fs.readFileSync(path.join(ROOT, STRINGS_FILE), "utf8");
	Debug.forced = false;
	// Warnings from loading test saves are expected; keep the output like Godot's.
	console.warn = () => {};
	start_autoloads();
}

// PASS or FAIL lines and the summary, like the Godot tests.
export class Checks {
	constructor(style = "space") {
		this.failures = 0;
		this.style = style;
	}
	check(label, ok) {
		console.log((ok ? "PASS" : "FAIL") + (this.style === "colon" ? ": " : "  ") + label);
		if (!ok) this.failures += 1;
	}
	finish() {
		console.log(this.failures === 0 ? "ALL PASSED (0 failed)" : `SOME FAILED (${this.failures} failed)`);
		process.exitCode = this.failures > 0 ? 1 : 0;
	}
}
