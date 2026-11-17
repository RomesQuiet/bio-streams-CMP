extends RefCounted
## The canteen's foods and plates (Milestone 21, decisions 61 to 64). A plate does not change the
## health model: its healthy foods count as a share of the healthy meal and its bad foods as a
## share of the fast-food meal (data/canteen.json, meal_for). The foods are in data/canteen.json.

const PATH := "res://data/canteen.json"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"meal_for": {}, "foods": {}}
	return _data


## Food ids, healthy ones or bad ones, in the file's order.
static func foods(healthy: bool) -> Array[String]:
	var found: Array[String] = []
	var all: Dictionary = data()["foods"]
	for id: String in all:
		if bool(all[id]["healthy"]) == healthy:
			found.append(id)
	return found


static func food(id: String) -> Dictionary:
	return data()["foods"].get(id, {})


static func is_healthy(id: String) -> bool:
	return bool(food(id).get("healthy", false))


## The meal option (data/activities.json and data/foods.json) a food counts as.
static func meal_for(id: String) -> String:
	return str(data()["meal_for"]["healthy" if is_healthy(id) else "bad"])


## How a plate counts: [[meal option, share of the plate], ...], healthy first, without empty parts.
static func parts(plate: Array) -> Array:
	var healthy := 0
	for id in plate:
		if is_healthy(str(id)):
			healthy += 1
	var result := []
	if plate.is_empty():
		return result
	var bad := plate.size() - healthy
	if healthy > 0:
		result.append([str(data()["meal_for"]["healthy"]), float(healthy) / plate.size()])
	if bad > 0:
		result.append([str(data()["meal_for"]["bad"]), float(bad) / plate.size()])
	return result


## The meal a plate is eaten as (its time, scenery and the avatar's reaction): the larger part;
## a tie is the healthy meal.
static func meal_option(plate: Array) -> String:
	var split := parts(plate)
	if split.is_empty():
		return ""
	if split.size() == 1 or split[0][1] >= split[1][1]:
		return split[0][0]
	return split[1][0]
