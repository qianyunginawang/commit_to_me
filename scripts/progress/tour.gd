class_name Tour
extends RefCounted
## The orientation-day campus tour (data/tour.json, see Setting.md
## "Orientation tour stops"). Quack walks the player through the stops in
## order. Each stop is one building:
##   building   - the building Quack shows. It's the only one you can pick.
##   lines      - what Quack says about it, one at a time.
##   room, character, room_line (optional) - a love interest is in this room.
##                After the lines Quack points at the room (room_line), and
##                the tour waits until you've done the tour subject with them.
##   slot (optional) - the tour moves time to this slot when it gets here
##                (Ciel's stop is after dark).
## A stop without a love interest is done once you press "Next stop" (it
## sets the flag "tour_seen_<building>"). After the last stop Quack says the
## outro lines, and the tour ends when you close them (flag "tour_done").
##
## The tour starts once the opening scene ("orientation") has been watched.
## Functions take an optional state and data so tests can pass their own.

const OPENING_SCENE := "orientation"
const DONE_FLAG := "tour_done"


static func stops(data: Node = null) -> Array:
	return _data(data).tour.get("stops", [])


## True from the end of the opening scene until the player closes Quack's
## outro. While it's on, the map only lets you pick Quack's building and
## time can't be skipped.
static func is_on(state: Node = null, data: Node = null) -> bool:
	state = _state(state)
	if stops(data).is_empty() or state.has_flag(DONE_FLAG):
		return false
	return state.week == 1 and state.day == 0 and state.is_date_complete(OPENING_SCENE)


## True from the start of a new game until the tour ends, including the
## opening scene. Time can't be skipped until then.
static func blocks_waiting(state: Node = null, data: Node = null) -> bool:
	state = _state(state)
	if stops(data).is_empty() or state.has_flag(DONE_FLAG):
		return false
	return state.week == 1 and state.day == 0


## Index of the stop the tour is at: the first one that isn't done.
## Equal to the number of stops once they're all done (Quack's outro).
static func current_index(state: Node = null, data: Node = null) -> int:
	var all := stops(data)
	for i in all.size():
		if not is_stop_done(all[i], state, data):
			return i
	return all.size()


## The current stop, or {} during the outro.
static func current_stop(state: Node = null, data: Node = null) -> Dictionary:
	var all := stops(data)
	var i := current_index(state, data)
	return all[i] if i < all.size() else {}


static func is_stop_done(stop: Dictionary, state: Node = null, data: Node = null) -> bool:
	state = _state(state)
	var character: String = stop.get("character", "")
	if character != "":
		var subject: String = _data(data).tour.get("subject", "")
		return Unlocks.characters_done_subject(subject, state, data).has(character)
	return state.has_flag(seen_flag(stop))


static func seen_flag(stop: Dictionary) -> String:
	return "tour_seen_" + stop.get("building", "")


## Whether the player can pick this building right now.
static func can_pick(building: String, state: Node = null, data: Node = null) -> bool:
	if not is_on(state, data):
		return true
	return current_stop(state, data).get("building", "") == building


## Moves on from a stop without a love interest (Quack's "Next stop"), or
## ends the tour after the outro. A stop with a love interest moves on by
## itself once its lesson is done. Then, if the new stop happens at another
## time of day, time moves forward to it.
static func next(state: Node = null, data: Node = null) -> void:
	state = _state(state)
	var stop := current_stop(state, data)
	if stop.is_empty():
		state.set_flag(DONE_FLAG)
		return
	if stop.get("character", "") != "":
		return
	state.set_flag(seen_flag(stop))
	catch_up_time(state, data)


## Moves time forward to the current stop's slot (day to night, never back).
static func catch_up_time(state: Node = null, data: Node = null) -> void:
	state = _state(state)
	var slot: String = current_stop(state, data).get("slot", "")
	if slot == "night" and state.slot == "day":
		state.advance_time()


static func _state(state: Node) -> Node:
	return state if state != null else GameState


static func _data(data: Node) -> Node:
	return data if data != null else GameData
