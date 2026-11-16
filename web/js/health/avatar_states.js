// Avatar states for the speech bubble and the placeholder looks (v1 "Avatar images", Milestone
// 10 Task 8). States are separate and can combine (CLAUDE.md, Interface). All numbers come from
// Config (group avatar_states). "Ill" is the danger state of severe thinness for now (Milestone
// 10.5); disease stages will show it too once they exist (decision 9).
import {Config} from "../core/config.js";
import {GameState} from "../core/game_state.js";
import {Hunger} from "./hunger.js";
import {HealthModel} from "./health_model.js";

export const AvatarStates = {
	// {hungry, tired, sad, happy, ill, thin, overweight, obese, muscular}: true or false.
	// Muscular with fat = muscular and overweight together. Obese is overweight too.
	current() {
		const gs = GameState;
		const path = "avatar_states.";
		return {
			hungry: Hunger.is_hungry(),
			tired: gs.tired,
			sad: gs.happiness < Config.get_float(path + "sad_below"),
			happy: gs.happiness >= Config.get_float(path + "happy_from"),
			ill: HealthModel.in_danger(),
			thin: gs.weight_z < Config.get_float(path + "thin_below_z"),
			overweight: gs.weight_z > Config.get_float(path + "overweight_above_z"),
			obese: gs.weight_z > Config.get_float(path + "obese_above_z"),
			muscular: gs.strength >= Config.get_float(path + "muscular_strength"),
		};
	},
};
