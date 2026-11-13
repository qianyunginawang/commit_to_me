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
##   stops (optional) - character id -> room, for an event spread over several
##                 rooms (the campus tour). Characters not listed are at
##                 "location". Scenes always play at "location".
##   cancels_recurring (optional) - nobody's weekly events happen on this
##                 day, day or night (orientation day).
##   requires, scenes (optional) - story conditions and scenes (see Story).
##                 While an event's scene is waiting to be watched, nobody
##                 there teaches lessons yet (so the club fair plays before
##                 its lessons), and watching a scene takes no time.
##
## Functions take an optional state and data so tests can pass their own.

## Weeks run Sunday to Saturday: day 0 is Sunday.
const DAY_KEYS := ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
const DAY_NAMES := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTH_NAMES := ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]


## The real date for a week (1-14) and day (0 = Sunday), like "Sunday, September 1".
static func date_for(week: int, day: int, data: Node = null) -> String:
	var start: String = _data(data).calendar.get("start_date", "2030-09-01")
	var unix := Time.get_unix_time_from_datetime_string(start) + ((week - 1) * 7 + day) * 86400
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return "%s, %s %d" % [DAY_NAMES[day], MONTH_NAMES[d["month"] - 1], d["day"]]


## Like "Week 1 · Sunday, September 1 · Day".
static func describe_now(state: Node = null, data: Node = null) -> String:
	state = _state(state)
	if state.is_semester_over():
		return "The semester is over"
	return "Week %d · %s · %s" % [state.week, date_for(state.week, state.day, data), String(state.slot).capitalize()]


## Where a character is during an event: their tour stop if the event has
## one for them, otherwise the event's location.
static func location_for(event: Dictionary, character_id: String) -> String:
	return event.get("stops", {}).get(character_id, event.get("location", ""))


## Whether an event on this day (either slot) cancels the weekly events.
static func is_recurring_cancelled(week: int, day: int, data: Node = null) -> bool:
	for event in _data(data).calendar.get("events", []):
		if event.get("cancels_recurring", false):
			for slot in ["day", "night"]:
				if is_event_on(event, week, day, slot):
					return true
	return false


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
## recurring one shows up at the story event. On a day with a
## cancels_recurring event (orientation), the weekly events are skipped.
static func events_now(state: Node = null, data: Node = null) -> Array[Dictionary]:
	state = _state(state)
	var out: Array[Dictionary] = []
	if state.is_semester_over():
		return out
	var cancelled := is_recurring_cancelled(state.week, state.day, data)
	for kind in ["story", "recurring", "info"]:
		if kind == "recurring" and cancelled:
			continue
		for event in _data(data).calendar.get("events", []):
			if event.get("kind", "") == kind and is_event_on(event, state.week, state.day, state.slot) \
					and Story.check(event.get("requires", ""), state, data):
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
			# The event's scene comes first (the club fair introductions).
			if Story.scene_for(event, state, data) == "":
				for lesson in Unlocks.lessons_available(character_id, state, data):
					if lesson_fits_slot(lesson, state.slot):
						lessons.append(lesson)
			return {"event": event, "character": character_id, "lessons": lessons}
	return {}


## Whether playing this dialogue at this event uses up the time slot.
## Lessons do, unless the event takes_no_time (the campus tour). Watching
## one of the event's own scenes never does, so the lessons there are still
## open afterwards (the club fair).
static func uses_time(event_id: String, dialogue_id: String, data: Node = null) -> bool:
	for event in _data(data).calendar.get("events", []):
		if event.get("id") != event_id:
			continue
		if event.get("takes_no_time", false):
			return false
		for scene in event.get("scenes", []):
			if scene.get("dialogue", "") == dialogue_id:
				return false
	return true


static func _state(state: Node) -> Node:
	return state if state != null else GameState


static func _data(data: Node) -> Node:
	return data if data != null else GameData
