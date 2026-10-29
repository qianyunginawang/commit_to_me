class_name JayBalance
extends RefCounted
## Jay's day and night sides (see agentcontext/Balance.md).
##
## Jay has one affection meter, plus a balance between the two sides:
## - Lessons in a Day slot (TypeScript, Day Jay) count as day lessons.
## - Lessons in a Night slot (JavaScript, Night Jay) count as night lessons.
## - Dusk chapters, when both sides are there, count as both.
## Jay's good ending needs the two counts within MAX_GAP of each other.
## If they aren't, Jay's normal ending follows the side with more lessons.
##
## Counts come from completed lessons, so nothing extra is saved. Functions
## take an optional state and data so tests can pass their own.

const CHARACTER := "javascript"
## The most the day and night lesson counts can differ for a good ending.
const MAX_GAP := 2


## How many completed lessons count for each side: {"day": n, "night": n}.
static func counts(state: Node = null, data: Node = null) -> Dictionary:
	state = state if state != null else GameState
	data = data if data != null else GameData
	var out := {"day": 0, "night": 0}
	for lesson in _jay_lessons(data):
		if not state.is_date_complete(lesson.get("dialogue", "")):
			continue
		match lesson.get("slot", ""):
			"day":
				out["day"] += 1
			"night":
				out["night"] += 1
			"dusk":
				out["day"] += 1
				out["night"] += 1
	return out


## How far apart the two sides are.
static func gap(state: Node = null, data: Node = null) -> int:
	var c := counts(state, data)
	return absi(c["day"] - c["night"])


## True if the two sides are close enough for Jay's good ending.
static func is_balanced(state: Node = null, data: Node = null) -> bool:
	return gap(state, data) <= MAX_GAP


## "balanced", or the side with more lessons ("day" or "night") when the gap
## is too big. That side decides Jay's normal ending.
static func leaning(state: Node = null, data: Node = null) -> String:
	if is_balanced(state, data):
		return "balanced"
	var c := counts(state, data)
	return "day" if c["day"] > c["night"] else "night"


## Short text for the UI, like "Day 3 · Night 1".
static func describe(state: Node = null, data: Node = null) -> String:
	var c := counts(state, data)
	return "Day %d · Night %d" % [c["day"], c["night"]]


## Every written lesson Jay can teach, generic and special, with its slot.
static func _jay_lessons(data: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject_id in data.lessons:
		out.append_array(data.generic_lessons_for(subject_id, CHARACTER))
	for chapter in data.special_chapters(CHARACTER):
		if chapter.has("dialogue"):
			out.append(chapter)
	return out
