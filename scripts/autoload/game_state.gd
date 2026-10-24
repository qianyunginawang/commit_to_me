extends Node
## The player's progress: their name, how much each character likes them,
## and which dates they've finished. Saved to user://save.json.
##
## Available everywhere as the `GameState` autoload.

signal affection_changed(character_id: String, value: int, delta: int)

const MIN_AFFECTION := 0
const MAX_AFFECTION := 100

## Relationship titles, from lowest to highest. A character's level is the
## last entry whose "min" is <= their affection.
const LEVELS: Array[Dictionary] = [
	{"min": 0, "title": "Stranger"},
	{"min": 15, "title": "Classmate"},
	{"min": 35, "title": "Study Buddy"},
	{"min": 60, "title": "Crush"},
	{"min": 85, "title": "Committed"},
]

var save_path := "user://save.json"
var player_name: String = "You"
var affection: Dictionary = {}          # character id -> int
var completed_dates: Array[String] = []


func new_game(p_player_name: String) -> void:
	player_name = p_player_name.strip_edges() if not p_player_name.strip_edges().is_empty() else "You"
	affection.clear()
	completed_dates.clear()


func get_affection(character_id: String) -> int:
	return affection.get(character_id, 0)


func add_affection(character_id: String, amount: int) -> void:
	var before := get_affection(character_id)
	var after := clampi(before + amount, MIN_AFFECTION, MAX_AFFECTION)
	affection[character_id] = after
	if after != before:
		affection_changed.emit(character_id, after, after - before)


func get_level(character_id: String) -> Dictionary:
	return level_for(get_affection(character_id))


static func level_for(value: int) -> Dictionary:
	var level: Dictionary = LEVELS[0]
	for l in LEVELS:
		if value >= l["min"]:
			level = l
	return level


func mark_date_complete(date_id: String) -> void:
	if not completed_dates.has(date_id):
		completed_dates.append(date_id)


func is_date_complete(date_id: String) -> bool:
	return completed_dates.has(date_id)


## The first date in [param date_ids] the player hasn't done yet,
## or "" if they've done them all.
func next_date(date_ids: Array) -> String:
	for id in date_ids:
		if not is_date_complete(id):
			return id
	return ""


# --- Saving ------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"player_name": player_name,
		"affection": affection,
		"completed_dates": completed_dates,
	}


func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", "You")
	affection.clear()
	var saved_affection: Dictionary = data.get("affection", {})
	for id in saved_affection:
		affection[id] = int(saved_affection[id])
	completed_dates.assign(data.get("completed_dates", []))


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> bool:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Couldn't save: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(to_dict(), "  "))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		push_error("Save file is corrupted: %s" % save_path)
		return false
	from_dict(data)
	return true
