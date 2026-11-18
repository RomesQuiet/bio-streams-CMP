extends RefCounted
## The canteen's foods (Milestone 21, third version, decisions 65 and 66). The player chooses good
## food or fast food, then builds a plate of that kind. Kinds are not mixed, so a good plate is
## exactly the healthy meal and a fast-food plate exactly the fast-food meal (data/canteen.json,
## meal_for): the health model is unchanged. The foods are in data/canteen.json.

const PATH := "res://data/canteen.json"
const GOOD := "good"
const FAST_FOOD := "fast_food"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"meal_for": {}, "foods": {}}
	return _data


## Food ids of a kind (GOOD or FAST_FOOD), in the file's order.
static func foods(kind: String) -> Array[String]:
	var found: Array[String] = []
	var all: Dictionary = data()["foods"]
	for id: String in all:
		if str(all[id]["kind"]) == kind:
			found.append(id)
	return found


static func food(id: String) -> Dictionary:
	return data()["foods"].get(id, {})


## The meal option (data/activities.json and data/foods.json) of a kind.
static func meal_for(kind: String) -> String:
	return str(data()["meal_for"].get(kind, ""))


## Whether a plate can be eaten: 1 to canteen.plate_max known foods, all of one kind.
static func is_plate(plate: Array) -> bool:
	if plate.is_empty() or plate.size() > Config.get_int("canteen.plate_max"):
		return false
	var kind := str(food(str(plate[0])).get("kind", ""))
	for id in plate:
		if food(str(id)).is_empty() or str(food(str(id))["kind"]) != kind:
			return false
	return true


## The kind of a plate's foods.
static func plate_kind(plate: Array) -> String:
	return str(food(str(plate[0])).get("kind", "")) if not plate.is_empty() else ""
