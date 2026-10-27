extends RefCounted
## A sliding window of the last N avatar hours, for sums over the last 24 hours (Milestone 10:
## kcal eaten and spent, effective exercise minutes). It keeps one slot per avatar hour plus
## one: the current hour and the N hours before it. The oldest of those counts only for the
## part of it that is still inside the window (if 20 minutes of the current hour have passed,
## the last 40 minutes of the oldest hour), so the sum is a true sliding N-hour sum when the
## values are spread evenly over each hour.
## A window is a Dictionary {"hour": newest avatar hour, key: [one value per slot], ...}, so it
## can be saved as it is. Slots of hours that passed are cleared before new values go in.


## A window of this many hours with these keys. Every past hour of a key starts at
## per_slot[key] (0 if missing), as if that value had been added every hour before the start;
## the current hour (hour 0) starts empty.
static func create(hours: int, per_slot: Dictionary, keys: Array) -> Dictionary:
	var window := {"hour": 0}
	for key in keys:
		var values := []
		for i in hours + 1:
			values.append(float(per_slot.get(key, 0.0)))
		values[0] = 0.0
		window[key] = values
	return window


## Adds a value to the slot of this avatar hour (hours since the avatar was created).
static func add(window: Dictionary, avatar_hours: float, key: String, value: float) -> void:
	_move_to(window, floori(avatar_hours))
	var slots: int = window[key].size()
	window[key][floori(avatar_hours) % slots] += value


## How many hours (N) the window covers.
static func hours(window: Dictionary) -> int:
	for key in window:
		if key != "hour":
			return window[key].size() - 1
	return 0


## Sum of a key over the last N hours, as seen at this avatar hour.
static func total(window: Dictionary, avatar_hours: float, key: String) -> float:
	var hour := floori(avatar_hours)
	_move_to(window, hour)
	var values: Array = window[key]
	var slots := values.size()
	var oldest := (hour + 1) % slots
	var sum := 0.0
	for i in slots:
		if i != oldest:
			sum += float(values[i])
	return sum + float(values[oldest]) * (1.0 - (avatar_hours - hour))


## Clears the slots of the hours between the newest slot and this hour.
static func _move_to(window: Dictionary, hour: int) -> void:
	var newest := int(window["hour"])
	if hour <= newest:
		return
	var keys := window.keys().filter(func(k: Variant) -> bool: return k != "hour")
	var slots: int = window[keys[0]].size()
	for h in range(maxi(newest + 1, hour - slots + 1), hour + 1):
		for key in keys:
			window[key][h % slots] = 0.0
	window["hour"] = hour
