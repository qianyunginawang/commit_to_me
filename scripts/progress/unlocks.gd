class_name Unlocks
extends RefCounted
## Which lessons the player can do right now (see agentcontext/StoryBeats.md).
##
## - Generic subjects unlock in curriculum order: a subject opens once the
##   one before it is done. Each subject is done once per playthrough, with
##   whichever character the player picks. A subject marked "every_character"
##   in the curriculum (Printing to the console, on the campus tour) is done
##   once with each character instead.
## - A special chapter unlocks once all of its "requires" subjects are done
##   and the character's previous chapter is done.
## - A lesson is done when its dialogue is in GameState.completed_dates
##   (GameState.complete_lesson puts it there when the challenge is passed).
##
## Every function takes an optional state and data so tests can pass their
## own. They default to the GameState and GameData autoloads.


## True once the subject has been done with any character.
static func is_subject_done(subject_id: String, state: Node = null, data: Node = null) -> bool:
	return not characters_done_subject(subject_id, state, data).is_empty()


## The characters the player has done this subject with.
static func characters_done_subject(subject_id: String, state: Node = null, data: Node = null) -> Array[String]:
	state = _state(state)
	data = _data(data)
	var out: Array[String] = []
	for language_id in data.lessons.get(subject_id, {}).get("versions", {}):
		var lesson: Dictionary = data.get_generic_lesson(subject_id, language_id)
		if state.is_date_complete(lesson["dialogue"]) and not out.has(lesson["character"]):
			out.append(lesson["character"])
	return out


## True if the subject is open: it's the first one, or the one before it is done.
static func is_subject_unlocked(subject_id: String, state: Node = null, data: Node = null) -> bool:
	data = _data(data)
	var number: int = int(data.get_subject(subject_id).get("number", 0))
	if number <= 0:
		return false
	if number == 1:
		return true
	return is_subject_done(data.curriculum[number - 2]["id"], state, data)


## Generic lessons this character can teach right now. Usually zero or one;
## Jay can have two (TypeScript by day, JavaScript by night).
static func generic_lessons_available(character_id: String, state: Node = null, data: Node = null) -> Array[Dictionary]:
	state = _state(state)
	data = _data(data)
	var out: Array[Dictionary] = []
	for subject in data.curriculum:
		var subject_id: String = subject["id"]
		if not is_subject_unlocked(subject_id, state, data):
			break
		var done_with := characters_done_subject(subject_id, state, data)
		var open: bool = done_with.is_empty() or (subject.get("every_character", false) and not done_with.has(character_id))
		if open:
			out.append_array(data.generic_lessons_for(subject_id, character_id))
	return out


## True once the chapter's dialogue has been completed.
static func is_chapter_done(chapter_id: String, state: Node = null, data: Node = null) -> bool:
	var dialogue_id: String = _data(data).get_special_chapter(chapter_id).get("dialogue", "")
	return dialogue_id != "" and _state(state).is_date_complete(dialogue_id)


## What still has to be done before this chapter opens: subject ids from its
## "requires", plus the previous chapter's id if that isn't done yet.
static func missing_for_chapter(chapter_id: String, state: Node = null, data: Node = null) -> Array[String]:
	state = _state(state)
	data = _data(data)
	var chapter: Dictionary = data.get_special_chapter(chapter_id)
	var missing: Array[String] = []
	for subject_id in chapter.get("requires", []):
		if not is_subject_done(subject_id, state, data):
			missing.append(subject_id)
	var number: int = int(chapter.get("chapter", 0))
	if number > 1:
		var previous: String = data.special_chapters(chapter.get("character", ""))[number - 2]["id"]
		if not is_chapter_done(previous, state, data):
			missing.append(previous)
	return missing


static func is_chapter_unlocked(chapter_id: String, state: Node = null, data: Node = null) -> bool:
	if _data(data).get_special_chapter(chapter_id).is_empty():
		return false
	return missing_for_chapter(chapter_id, state, data).is_empty()


## The character's first special chapter that isn't done yet, unlocked or
## not, or {} if the whole route is done.
static func next_special_chapter(character_id: String, state: Node = null, data: Node = null) -> Dictionary:
	data = _data(data)
	for chapter in data.special_chapters(character_id):
		if not is_chapter_done(chapter["id"], state, data):
			return data.get_special_chapter(chapter["id"])
	return {}


## Everything this character can do with the player right now, special
## chapter first. Chapters whose dialogue isn't written yet are left out.
static func lessons_available(character_id: String, state: Node = null, data: Node = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var chapter := next_special_chapter(character_id, state, data)
	if chapter.has("dialogue") and is_chapter_unlocked(chapter["id"], state, data):
		out.append(chapter)
	out.append_array(generic_lessons_available(character_id, state, data))
	return out


static func _state(state: Node) -> Node:
	return state if state != null else GameState


static func _data(data: Node) -> Node:
	return data if data != null else GameData
