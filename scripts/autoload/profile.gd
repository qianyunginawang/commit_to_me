extends Node
## Progress that carries over between playthroughs, saved separately from
## the current game in user://profile.json. Starting a new game doesn't
## touch it.
##
## Today it records which endings the player has seen, which unlocks:
## - the hidden Polyglot choice in week 4, after at least one good ending
## - the secret Ferris (Rust) route, after all four good endings
## (see agentcontext/StoryBeats.md). The gallery can use it later too.
##
## Available everywhere as the `Profile` autoload.

var profile_path := "user://profile.json"
## Ending ids, in the order they were first seen.
var endings_seen: Array[String] = []


func _ready() -> void:
	load_profile()


## Call when an ending plays. Saves straight away.
func record_ending(ending_id: String) -> void:
	if ending_id == "" or endings_seen.has(ending_id):
		return
	endings_seen.append(ending_id)
	save_profile()


func has_seen(ending_id: String) -> bool:
	return endings_seen.has(ending_id)


## Characters whose good ending the player has seen.
func good_endings_seen(data: Node = null) -> Array[String]:
	var out: Array[String] = []
	for id in endings_seen:
		var ending := Endings.find(id, data)
		if ending.get("kind") == "good" and not out.has(ending["character"]):
			out.append(ending["character"])
	return out


## The hidden Polyglot choice can appear once any good ending has been seen.
func is_polyglot_unlocked(data: Node = null) -> bool:
	return not good_endings_seen(data).is_empty()


## Ferris's secret route opens once every character's good ending has been seen.
func is_secret_route_unlocked(data: Node = null) -> bool:
	data = data if data != null else GameData
	var seen := good_endings_seen(data)
	for id in data.character_ids():
		if not seen.has(id):
			return false
	return true


## How many of all the endings in the game have been seen: {seen, total}.
func ending_count(data: Node = null) -> Dictionary:
	data = data if data != null else GameData
	var total := 0
	for character_id in data.endings:
		total += data.endings[character_id].get("endings", []).size()
	return {"seen": endings_seen.size(), "total": total}


func save_profile() -> bool:
	var f := FileAccess.open(profile_path, FileAccess.WRITE)
	if f == null:
		push_error("Couldn't save the profile: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify({"version": 1, "endings_seen": endings_seen}, "  "))
	return true


func load_profile() -> void:
	endings_seen.clear()
	if not FileAccess.file_exists(profile_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
	if not data is Dictionary:
		push_error("Profile is corrupted: %s" % profile_path)
		return
	endings_seen.assign(data.get("endings_seen", []))
