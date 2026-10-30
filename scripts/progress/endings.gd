class_name Endings
extends RefCounted
## Which ending a route gets (see agentcontext/Balance.md):
## - Good: affection GOOD_AFFECTION+ and the route's final chapter passed.
##   Jay also needs their day and night sides balanced (JayBalance).
## - Normal: affection NORMAL_AFFECTION+ (or 80+ without the good ending's
##   other requirements). Jay has two: "normal_day" and "normal_night",
##   picked by the side with more lessons (day on a tie).
## - Bad: anything lower.
##
## Ending scenes live in data/endings/<character>.json, each pointing at a
## dialogue in data/dates/. Functions take an optional state and data so
## tests can pass their own.

const GOOD_AFFECTION := 80
const NORMAL_AFFECTION := 50


## "good", "normal", "normal_day", "normal_night" or "bad".
static func ending_kind(character_id: String, state: Node = null, data: Node = null) -> String:
	state = state if state != null else GameState
	data = data if data != null else GameData
	var affection: int = state.get_affection(character_id)
	var is_jay := character_id == JayBalance.CHARACTER
	if affection >= GOOD_AFFECTION and final_passed(character_id, state, data) \
			and (not is_jay or JayBalance.is_balanced(state, data)):
		return "good"
	if affection >= NORMAL_AFFECTION:
		if is_jay:
			var counts := JayBalance.counts(state, data)
			return "normal_night" if counts["night"] > counts["day"] else "normal_day"
		return "normal"
	return "bad"


## Whose ending the player gets: the character with the most affection.
## Returns every character tied for the top, so the player can pick between
## them (usually just one).
static func route_characters(state: Node = null, data: Node = null) -> Array[String]:
	state = state if state != null else GameState
	data = data if data != null else GameData
	var best := -1
	var out: Array[String] = []
	for id in data.character_ids():
		var value: int = state.get_affection(id)
		if value > best:
			best = value
			out = [id]
		elif value == best:
			out.append(id)
	return out


## True once the character's final special chapter is done.
static func final_passed(character_id: String, state: Node = null, data: Node = null) -> bool:
	data = data if data != null else GameData
	var chapters: Array = data.special_chapters(character_id)
	return not chapters.is_empty() and Unlocks.is_chapter_done(chapters[-1]["id"], state, data)


## The ending this route gets right now: {id, character, kind, title, summary, dialogue}.
static func ending_for(character_id: String, state: Node = null, data: Node = null) -> Dictionary:
	return get_ending(character_id, ending_kind(character_id, state, data), data)


## The Polyglot route's ending: "good" (the Polyglot ending) if Story says
## so, otherwise "bad" (the merge conflict ending).
static func polyglot_ending(state: Node = null, data: Node = null) -> Dictionary:
	return get_ending("polyglot", "good" if Story.is_polyglot_good(state, data) else "bad", data)


## An ending by character and kind, or {} if it isn't in the data.
static func get_ending(character_id: String, kind: String, data: Node = null) -> Dictionary:
	data = data if data != null else GameData
	for ending in data.endings.get(character_id, {}).get("endings", []):
		if ending.get("kind") == kind:
			return ending
	return {}


## An ending by id ("python_ending_good"), or {}.
static func find(ending_id: String, data: Node = null) -> Dictionary:
	data = data if data != null else GameData
	for character_id in data.endings:
		for ending in data.endings[character_id].get("endings", []):
			if ending.get("id") == ending_id:
				return ending
	return {}
