extends RefCounted
## The canteen's dishes (Milestone 21, decisions 61 to 64). The player chooses good food or bad
## food, then one dish from many examples of that kind. A good dish is exactly the healthy meal
## and a bad dish exactly the fast-food meal (data/canteen.json, meal_for), so the health model
## is unchanged. The dishes are in data/canteen.json.

const PATH := "res://data/canteen.json"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"meal_for": {}, "dishes": {}}
	return _data


## Dish ids, good ones or bad ones, in the file's order.
static func dishes(good: bool) -> Array[String]:
	var found: Array[String] = []
	var all: Dictionary = data()["dishes"]
	for id: String in all:
		if bool(all[id]["good"]) == good:
			found.append(id)
	return found


static func dish(id: String) -> Dictionary:
	return data()["dishes"].get(id, {})


static func is_good(id: String) -> bool:
	return bool(dish(id).get("good", false))


## The meal option (data/activities.json and data/foods.json) a dish is.
static func meal_for(id: String) -> String:
	return str(data()["meal_for"]["good" if is_good(id) else "bad"])
