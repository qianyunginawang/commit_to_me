extends Node
## The player's progress: their name, how much each character likes them,
## and which dates they've finished. Saved to user://save.json.
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

var save_path := "user://save.json"
const DEFAULT_PLAYER_NAME := "Grace"
var player_name: String = DEFAULT_PLAYER_NAME
var affection: Dictionary = {}          # character id -> int
var completed_dates: Array[String] = []
## Where the player is in the semester: week 1-14, day 0-6 (0 = Monday),
## and "day" or "night". Week SEMESTER_WEEKS + 1 means the semester is over.
var week: int = 1
var day: int = 0
var slot: String = "day"


func new_game(p_player_name: String) -> void:
	player_name = p_player_name.strip_edges() if not p_player_name.strip_edges().is_empty() else DEFAULT_PLAYER_NAME
	affection.clear()
	completed_dates.clear()
	week = 1
	day = 0
	slot = "day"


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
		"version": 2,
		"player_name": player_name,
		"affection": affection,
		"completed_dates": completed_dates,
		"time": {"week": week, "day": day, "slot": slot},
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
