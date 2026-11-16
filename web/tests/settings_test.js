// Tests for Settings (Milestone 11, Task 2). Run from the project folder:
//   node web/tests/settings_test.js
// The first-start rule (decision 15), a chosen language surviving a restart, and a new avatar
// leaving it alone. Uses a test key, so the real settings are never touched.
import {setup, Checks} from "./harness.js";
import {Settings} from "../js/core/settings.js";
import {GameState} from "../js/core/game_state.js";
import {Storage} from "../js/core/storage.js";
import {TranslationServer, tr} from "../js/core/translation.js";

const TEST_KEY = "test_settings";
setup();
const t = new Checks("colon");
Settings.storage_key = TEST_KEY;
Storage.remove(TEST_KEY);

t.check("any Portuguese browser gives Portuguese", Settings.language_for_locale("pt") === "pt");
t.check("another browser language gives English", Settings.language_for_locale("fr") === "en" && Settings.language_for_locale("en") === "en");
Settings.load_settings();
t.check("without a saved choice the game follows the system language", Settings.language === Settings.language_for_locale("en"));
t.check("...and nothing is saved", Storage.get(TEST_KEY) === "");

Settings.mark_football_help_seen();
Settings.load_settings();
t.check("the football explanation is remembered", Settings.football_help_seen);
t.check("...and the game still follows the system language", !Storage.get(TEST_KEY).includes("language"));
Storage.remove(TEST_KEY);
Settings.football_help_seen = false;

Settings.set_language("pt");
t.check("a chosen language is used at once", Settings.language === "pt" && TranslationServer.locale === "pt");
t.check("...in the translations too", tr("FORMAT_DECIMAL_MARK") === ",");
t.check("...and it is saved", Storage.get(TEST_KEY) !== "");
Settings.language = "";
Settings.load_settings();
t.check("a chosen language survives a restart", Settings.language === "pt");
Settings.set_language("en");
Settings.load_settings();
t.check("changing it again survives a restart too", Settings.language === "en" && tr("FORMAT_DECIMAL_MARK") === ".");
const quiet = console.error;
console.error = () => {};
Settings.set_language("fr");
console.error = quiet;
t.check("an unknown language is refused", Settings.language === "en");

Settings.set_language("en");
t.check("numbers in English: decimal point", Settings.number(0.849, 2) === "0.85" && Settings.number(36.04, 1) === "36.0");
t.check("...with a sign when asked", Settings.number(1.2, 2, true) === "+1.20" && Settings.number(-1.2, 2, true) === "-1.20");
Settings.set_language("pt");
t.check("numbers in Portuguese: decimal comma", Settings.number(0.849, 2) === "0,85" && Settings.number(1.2, 2, true) === "+1,20");
t.check("...also a number written as text", Settings.decimal_text("0.5") === "0,5");

GameState.reset();
GameState.start_new_avatar("Test", "child", "male", "normal");
t.check("a new avatar does not change the language", Settings.language === "pt");
t.check("the language is not part of the avatar's save", !("language" in GameState.to_dict()));

Storage.remove(TEST_KEY);
t.finish();
