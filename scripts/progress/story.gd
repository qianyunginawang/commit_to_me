class_name Story
extends RefCounted
## Story flags and conditions, used by calendar events and their scenes.
##
## A calendar event can have:
##   "requires": a condition. The event only happens if it's true.
##   "scenes":   [{"if": condition, "dialogue": id}, ...]. The first scene
##               whose condition is true plays (no "if" means always). Scenes
##               are dialogues in data/dates/ with no character ("character": "").
## A dialogue choice can have "set_flag": "<flag>" to set a story flag.
##
## Conditions:
##   polyglot         - the player picked the Polyglot route
##   polyglot_choice  - the hidden Polyglot choice can appear: not on it yet,
##                      a good ending seen before (Profile), and all four
##                      characters at POLYGLOT_CHOICE_AFFECTION or more
##   not_polyglot     - the opposite of polyglot

const FLAGS := ["polyglot"]
const CONDITIONS := ["", "polyglot", "polyglot_choice", "not_polyglot"]
## Everyone needs at least this much affection in week 4 for the Polyglot choice.
const POLYGLOT_CHOICE_AFFECTION := 20


static func check(condition: String, state: Node = null, data: Node = null, profile: Node = null) -> bool:
	state = state if state != null else GameState
	data = data if data != null else GameData
	profile = profile if profile != null else Profile
	match condition:
		"":
			return true
		"polyglot":
			return state.has_flag("polyglot")
		"not_polyglot":
			return not state.has_flag("polyglot")
		"polyglot_choice":
			if state.has_flag("polyglot") or not profile.is_polyglot_unlocked(data):
				return false
			for id in data.character_ids():
				if state.get_affection(id) < POLYGLOT_CHOICE_AFFECTION:
					return false
			return true
	push_warning("Unknown story condition '%s'" % condition)
	return false


## The dialogue an event plays right now, or "" if it has no scene (or the
## player has already seen it).
static func scene_for(event: Dictionary, state: Node = null, data: Node = null, profile: Node = null) -> String:
	state = state if state != null else GameState
	for scene in event.get("scenes", []):
		if check(scene.get("if", ""), state, data, profile):
			var dialogue_id: String = scene.get("dialogue", "")
			return "" if state.is_date_complete(dialogue_id) else dialogue_id
	return ""


## The Polyglot ending's good version needs everyone at Endings.GOOD_AFFECTION
## or more, every route's final chapter passed, and Jay balanced.
static func is_polyglot_good(state: Node = null, data: Node = null) -> bool:
	state = state if state != null else GameState
	data = data if data != null else GameData
	for id in data.character_ids():
		if state.get_affection(id) < Endings.GOOD_AFFECTION or not Endings.final_passed(id, state, data):
			return false
	return JayBalance.is_balanced(state, data)
