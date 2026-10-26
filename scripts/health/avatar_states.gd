extends RefCounted
## Avatar states for the speech bubble and the placeholder looks (v1 "Avatar images", Milestone
## 10 Task 8). States are separate and can combine (CLAUDE.md, Interface). All numbers come from
## Config (group avatar_states). "Ill" is not used until disease stages exist (decision 9).

const Hunger := preload("res://scripts/health/hunger.gd")


## {"hungry", "tired", "sad", "thin", "overweight", "muscular"}: true or false.
## Muscular with fat = muscular and overweight together.
static func current() -> Dictionary:
	var gs := GameState
	var path := "avatar_states."
	return {
		"hungry": Hunger.is_hungry(),
		"tired": gs.tired,
		"sad": gs.happiness < Config.get_float(path + "sad_below"),
		"thin": gs.weight_z < Config.get_float(path + "thin_below_z"),
		"overweight": gs.weight_z > Config.get_float(path + "overweight_above_z"),
		"muscular": gs.strength >= Config.get_float(path + "muscular_strength"),
	}
