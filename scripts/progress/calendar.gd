class_name Calendar
extends RefCounted
## The semester calendar (see agentcontext/Calendar.md): what's happening at
## the current week, day and slot, and which lessons can happen there.
##
## Events live in data/calendar.json. Each one has:
##   kind        - "recurring" (a character's weekly event), "story" (a one-off
##                 event), or "info" (shown on the calendar, nobody to meet)
##   weeks       - "every", "even", "odd", or a list of week numbers
##   days        - e.g. ["mon", "wed"]
##   slot        - "day" or "night"
##   characters  - who is there. Lessons can only happen with someone who's
##                 at an event right now.
##   takes_no_time (optional) - doing lessons here doesn't move time forward
##                 (the orientation-day campus tour, where you meet all four).
##
## Functions take an optional state and data so tests can pass their own.

const DAY_KEYS := ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
const DAY_NAMES := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MONTH_NAMES := ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]


## The real date for a week (1-14) and day (0 = Monday), like "Monday, August 31".
static func date_for(week: int, day: int, data: Node = null) -> String:
	var start: String = _data(data).calendar.get("start_date", "2026-08-31")
	var unix := Time.get_unix_time_from_datetime_string(start) + ((week - 1) * 7 + day) * 86400
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return "%s, %s %d" % [DAY_NAMES[day], MONTH_NAMES[d["month"] - 1], d["day"]]


## Like "Week 1 · Monday, August 31 · Day".
static func describe_now(state: Node = null, data: Node = null) -> String:
	state = _state(state)
	if state.is_semester_over():
		return "The semester is over"
	return "Week %d · %s · %s" % [state.week, date_for(state.week, state.day, data), String(state.slot).capitalize()]


static func is_event_on(event: Dictionary, week: int, day: int, slot: String) -> bool:
	if event.get("slot", "") != slot or not event.get("days", []).has(DAY_KEYS[day]):
		return false
	var weeks = event.get("weeks", "every")
	match weeks:
		"every":
			return true
		"even":
			return week % 2 == 0
		"odd":
			return week % 2 == 1
	if weeks is Array:
		for w in weeks:
			if int(w) == week:
				return true
	return false


## Every event happening at the player's current week, day and slot. Story
## events come first, so a character at both a story event and their usual
## recurring one shows up at the story event.
static func events_now(state: Node = null, data: Node = null) -> Array[Dictionary]:
	state = _state(state)
	var out: Array[Dictionary] = []
	if state.is_semester_over():
		return out
	for kind in ["story", "recurring", "info"]:
		for event in _data(data).calendar.get("events", []):
			if event.get("kind", "") == kind and is_event_on(event, state.week, state.day, state.slot):
				out.append(event)
	return out


## Whether a lesson can happen in this slot. "any" fits both, "dusk" (Jay's
## in-between time) fits both, and "day" or "night" only fit themselves.
static func lesson_fits_slot(lesson: Dictionary, slot: String) -> bool:
	var lesson_slot: String = lesson.get("slot", "any")
	return lesson_slot == "any" or lesson_slot == "dusk" or lesson_slot == slot


## Where a character is right now and what they can teach there:
##   {event, character, lessons}
## or {} if they aren't at any event right now.
static func opportunity_for(character_id: String, state: Node = null, data: Node = null) -> Dictionary:
	state = _state(state)
	for event in events_now(state, data):
		if event.get("characters", []).has(character_id):
			var lessons: Array[Dictionary] = []
			for lesson in Unlocks.lessons_available(character_id, state, data):
				if lesson_fits_slot(lesson, state.slot):
					lessons.append(lesson)
			return {"event": event, "character": character_id, "lessons": lessons}
	return {}


static func _state(state: Node) -> Node:
	return state if state != null else GameState


static func _data(data: Node) -> Node:
	return data if data != null else GameData
