extends Node
## The player's progress: their name, how much each character likes them,
## and which dates they've finished. Each game is its own save slot, a file
## in user://saves/ (see list_saves).
##
## Available everywhere as the `GameState` autoload.

signal affection_changed(character_id: String, value: int, delta: int)

const MIN_AFFECTION := 0
const MAX_AFFECTION := 100

## Affection rules (see agentcontext/Balance.md). Affection only comes from
## lessons: passing one is worth LESSON_AFFECTION, minus HINT_COST for each
## of Quack's hints the player used, but never less than MIN_LESSON_AFFECTION.
const LESSON_AFFECTION := 6
const HINT_COST := 2
const MIN_LESSON_AFFECTION := 2

## The semester is this many weeks long (see data/calendar.json).
const SEMESTER_WEEKS := 14

## Relationship titles, from lowest to highest. A character's level is the
## last entry whose "min" is <= their affection.
const LEVELS: Array[Dictionary] = [
	{"min": 0, "title": "Stranger"},
	{"min": 15, "title": "Classmate"},
	{"min": 35, "title": "Study Buddy"},
	{"min": 60, "title": "Crush"},
	{"min": 85, "title": "Committed"},
]

## Every save slot lives in this folder, one JSON file per game.
var saves_dir := "user://saves"
## Saves from before there were slots. Moved into saves_dir on startup.
const LEGACY_SAVE := "user://save.json"
## The current game's save file. Empty until a slot is started or loaded.
var save_path := ""
const DEFAULT_PLAYER_NAME := "Grace"
var player_name: String = DEFAULT_PLAYER_NAME
var affection: Dictionary = {}          # character id -> int
var completed_dates: Array[String] = []
## Where the player is in the semester: week 1-14, day 0-6 (0 = Sunday),
## and "day" or "night". Week SEMESTER_WEEKS + 1 means the semester is over.
var week: int = 1
var day: int = 0
var slot: String = "day"
## The ending the player chose at the end of the semester ("" until then).
var ending_id: String = ""
## Story flags set by dialogue choices (see Story), e.g. {"polyglot": true}.
var flags: Dictionary = {}


func _ready() -> void:
	_move_legacy_save()


func new_game(p_player_name: String) -> void:
	player_name = p_player_name.strip_edges() if not p_player_name.strip_edges().is_empty() else DEFAULT_PLAYER_NAME
	affection.clear()
	completed_dates.clear()
	week = 1
	day = 0
	slot = "day"
	ending_id = ""
	flags.clear()


## Moves to the next slot: day -> night, night -> the next day.
func advance_time() -> void:
	if is_semester_over():
		return
	if slot == "day":
		slot = "night"
		return
	slot = "day"
	day += 1
	if day > 6:
		day = 0
		week += 1


func set_flag(flag: String) -> void:
	flags[flag] = true


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func is_semester_over() -> bool:
	return week > SEMESTER_WEEKS


func get_affection(character_id: String) -> int:
	return affection.get(character_id, 0)


func add_affection(character_id: String, amount: int) -> void:
	var before := get_affection(character_id)
	var after := clampi(before + amount, MIN_AFFECTION, MAX_AFFECTION)
	affection[character_id] = after
	if after != before:
		affection_changed.emit(character_id, after, after - before)


## How much affection passing a lesson is worth after using [param hints_used] hints.
static func lesson_affection(hints_used: int) -> int:
	return maxi(LESSON_AFFECTION - HINT_COST * hints_used, MIN_LESSON_AFFECTION)


## Call when the player passes a lesson's challenge. The first pass marks the
## lesson complete and gives [param character_id] affection. Replaying a
## lesson that's already complete gives nothing. Returns the amount given.
func complete_lesson(lesson_id: String, character_id: String, hints_used: int) -> int:
	if is_date_complete(lesson_id):
		return 0
	mark_date_complete(lesson_id)
	var amount := lesson_affection(hints_used)
	add_affection(character_id, amount)
	return amount


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


# --- Saving ------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 2,
		"player_name": player_name,
		"affection": affection,
		"completed_dates": completed_dates,
		"time": {"week": week, "day": day, "slot": slot},
		"ending": ending_id,
		"flags": flags,
	}


func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", DEFAULT_PLAYER_NAME)
	affection.clear()
	var saved_affection: Dictionary = data.get("affection", {})
	for id in saved_affection:
		affection[id] = int(saved_affection[id])
	completed_dates.assign(data.get("completed_dates", []))
	var time: Dictionary = data.get("time", {})
	week = int(time.get("week", 1))
	day = int(time.get("day", 0))
	slot = time.get("slot", "day")
	ending_id = data.get("ending", "")
	flags = data.get("flags", {}).duplicate()


func has_save() -> bool:
	return save_path != "" and FileAccess.file_exists(save_path)


## Points saving at a brand-new slot file. Call after new_game() so starting
## a new game never overwrites an old one.
func start_new_save() -> void:
	DirAccess.make_dir_recursive_absolute(saves_dir)
	var stamp := int(Time.get_unix_time_from_system() * 1000.0)
	save_path = saves_dir.path_join("save_%d.json" % stamp)
	while FileAccess.file_exists(save_path):
		stamp += 1
		save_path = saves_dir.path_join("save_%d.json" % stamp)


func save_game() -> bool:
	if save_path == "":
		start_new_save()
	var data := to_dict()
	data["saved_at"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Couldn't save: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data, "  "))
	return true


## Loads [param path] (a slot from list_saves) and keeps saving to it.
## With no path, reloads the current slot.
func load_game(path: String = "") -> bool:
	if path != "":
		save_path = path
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		push_error("Save file is corrupted: %s" % save_path)
		return false
	from_dict(data)
	return true


## Every save slot, most recently saved first. Each entry has "path",
## "player_name", "week", "day", "slot", "ending" and "saved_at" (unix time).
func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(saves_dir):
		return saves
	for file in DirAccess.get_files_at(saves_dir):
		if not file.ends_with(".json"):
			continue
		var path := saves_dir.path_join(file)
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary:
			continue
		var time: Dictionary = data.get("time", {})
		saves.append({
			"path": path,
			"player_name": data.get("player_name", DEFAULT_PLAYER_NAME),
			"week": int(time.get("week", 1)),
			"day": int(time.get("day", 0)),
			"slot": time.get("slot", "day"),
			"ending": data.get("ending", ""),
			"saved_at": float(data.get("saved_at", FileAccess.get_modified_time(path))),
		})
	saves.sort_custom(func(a, b): return a["saved_at"] > b["saved_at"])
	return saves


## Deletes a save slot for good. Deleting the current game's slot means the
## next save_game() starts a fresh one.
func delete_save(path: String) -> void:
	if not path.begins_with(saves_dir):
		push_error("Not a save slot: %s" % path)
		return
	DirAccess.remove_absolute(path)
	if path == save_path:
		save_path = ""


func has_any_save() -> bool:
	return not list_saves().is_empty()


func _move_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE):
		return
	DirAccess.make_dir_recursive_absolute(saves_dir)
	DirAccess.rename_absolute(LEGACY_SAVE, saves_dir.path_join("save_0.json"))
