extends Node
## Loads all of the game's content from res://data/ at startup.
##
## Content lives in plain JSON files so you can add characters, dates and
## coding challenges without touching any code:
##   data/characters/*.json  - one file per dateable language
##   data/dates/*.json       - dialogue for each date (see DialoguePlayer)
##   data/challenges/*.json  - coding exercises used during dates
##   data/languages.json     - how to compile/run each programming language
##
## Lessons (see agentcontext/DatesAndRoutes.md and Balance.md):
##   data/curriculum.json    - the 33 generic subjects, in unlock order
##   data/lessons/*.json     - the written versions of a generic subject, one
##                             per language, e.g. data/lessons/g01.json
##   data/routes/*.json      - each character's special chapters, in order
##   data/locations.json     - campus locations lessons can happen at
##   data/calendar.json      - the semester's events (see Calendar)
##   data/endings/*.json     - each character's endings (see Endings)
##
## A lesson is a dialogue (a file in data/dates/) with one challenge node in
## it. Generic subjects and special chapters can be listed before their
## dialogue is written: a subject with no versions yet, or a chapter with no
## "dialogue", is just not playable yet.
##
## Available everywhere as the `GameData` autoload.

const CHARACTERS_DIR := "res://data/characters"
const DATES_DIR := "res://data/dates"
const CHALLENGES_DIR := "res://data/challenges"
const LANGUAGES_PATH := "res://data/languages.json"
const CURRICULUM_PATH := "res://data/curriculum.json"
const LESSONS_DIR := "res://data/lessons"
const ROUTES_DIR := "res://data/routes"
const LOCATIONS_PATH := "res://data/locations.json"
const CALENDAR_PATH := "res://data/calendar.json"
const ENDINGS_DIR := "res://data/endings"

## Time slots a lesson can happen in. "dusk" is Jay's in-between time and
## counts as both day and night.
const SLOTS := ["any", "day", "night", "dusk"]

var characters: Dictionary = {}
var dates: Dictionary = {}
var challenges: Dictionary = {}
var languages: Dictionary = {}
## Generic subjects in curriculum order: {id, number, title, unit, location}.
var curriculum: Array = []
## Generic subject id -> {"id": ..., "versions": {language id: {"dialogue": ...}}}.
var lessons: Dictionary = {}
## Character id -> {"character": ..., "chapters": [{id, chapter, title, ...}]}.
var routes: Dictionary = {}
## Location id -> {name, area}.
var locations: Dictionary = {}
## {start_date, weeks, events: [...]}. See Calendar.
var calendar: Dictionary = {}
## Character id -> {"character": ..., "endings": [{id, kind, title, summary, dialogue}]}.
var endings: Dictionary = {}

var _warm_up_started := false


func _ready() -> void:
	load_all()


func load_all() -> void:
	characters = load_dir(CHARACTERS_DIR)
	dates = load_dir(DATES_DIR)
	challenges = load_dir(CHALLENGES_DIR)
	var langs = load_json(LANGUAGES_PATH)
	languages = langs if langs is Dictionary else {}
	var curr = load_json(CURRICULUM_PATH)
	curriculum = curr.get("subjects", []) if curr is Dictionary else []
	lessons = load_dir(LESSONS_DIR)
	routes = load_dir(ROUTES_DIR)
	var locs = load_json(LOCATIONS_PATH)
	locations = locs if locs is Dictionary else {}
	var cal = load_json(CALENDAR_PATH)
	calendar = cal if cal is Dictionary else {}
	endings = load_dir(ENDINGS_DIR)
	for problem in validate():
		push_warning("[GameData] " + problem)


## Character ids in display order (each character file has an "order").
func character_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(characters.keys())
	ids.sort_custom(func(a, b): return characters[a].get("order", 99) < characters[b].get("order", 99))
	return ids


func get_character(id: String) -> Dictionary:
	return characters.get(id, {})


func get_date(id: String) -> Dictionary:
	return dates.get(id, {})


func get_challenge(id: String) -> Dictionary:
	return challenges.get(id, {})


## The challenge's hints, in order. Every challenge has two.
static func get_hints(challenge: Dictionary) -> Array:
	return challenge.get("hints", [])


## A generic subject from the curriculum by id ("g01"), or {} if unknown.
func get_subject(subject_id: String) -> Dictionary:
	for subject in curriculum:
		if subject.get("id") == subject_id:
			return subject
	return {}


## The character whose lessons use this language, or "" if none.
## (Jay's lessons use both "typescript" and "javascript".)
func character_for_language(language_id: String) -> String:
	for id in characters:
		if characters[id].get("lesson_languages", {}).has(language_id):
			return id
	return ""


## One written version of a generic subject, filled in with everything the
## game needs to offer it:
##   {kind: "generic", subject, title, language, character, slot, dialogue,
##    challenge, location}
## Returns {} if that version hasn't been written yet.
func get_generic_lesson(subject_id: String, language_id: String) -> Dictionary:
	var version: Dictionary = lessons.get(subject_id, {}).get("versions", {}).get(language_id, {})
	if version.is_empty():
		return {}
	var character_id := character_for_language(language_id)
	var dialogue_id: String = version.get("dialogue", "")
	return {
		"kind": "generic",
		"subject": subject_id,
		"title": get_subject(subject_id).get("title", subject_id),
		"language": language_id,
		"character": character_id,
		"slot": get_character(character_id).get("lesson_languages", {}).get(language_id, "any"),
		"dialogue": dialogue_id,
		"challenge": dialogue_challenge(dialogue_id),
		"location": get_subject(subject_id).get("location", ""),
	}


## Every written version of a generic subject that a character can teach.
## Usually one; two for Jay (TypeScript by day, JavaScript by night).
func generic_lessons_for(subject_id: String, character_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for language_id in get_character(character_id).get("lesson_languages", {}):
		var lesson := get_generic_lesson(subject_id, language_id)
		if not lesson.is_empty():
			out.append(lesson)
	return out


## A character's special chapters, in order.
func special_chapters(character_id: String) -> Array:
	return routes.get(character_id, {}).get("chapters", [])


## A special chapter by id ("python_ch1"), with "kind" ("special"),
## "character" and "challenge" filled in, or {}.
func get_special_chapter(chapter_id: String) -> Dictionary:
	for character_id in routes:
		for chapter in special_chapters(character_id):
			if chapter.get("id") == chapter_id:
				var out: Dictionary = chapter.duplicate()
				out["kind"] = "special"
				out["character"] = character_id
				out["challenge"] = dialogue_challenge(chapter.get("dialogue", ""))
				return out
	return {}


## The id of the first challenge node in a dialogue, or "" if it has none.
func dialogue_challenge(dialogue_id: String) -> String:
	for node in get_date(dialogue_id).get("nodes", {}).values():
		if node.has("challenge"):
			return node["challenge"]
	return ""


## Makes a code runner for a language id from languages.json ("python", "cpp", ...).
func make_runner(language_id: String) -> CodeRunner:
	return ProcessCodeRunner.new(language_id, languages.get(language_id, {}))


## Gets slow first-time setup out of the way in the background, so the
## player's first Run isn't the slow one. Today that's C++: the bundled Zig
## compiler builds the C++ standard library the first time it's used, which
## can take a minute. Safe to call more than once.
func warm_up_runtimes() -> void:
	if _warm_up_started:
		return
	_warm_up_started = true
	for id in languages:
		var code: String = languages[id].get("warm_up_code", "")
		if code.is_empty():
			continue
		var runner := make_runner(id) as ProcessCodeRunner
		if runner and runner.uses_bundled_runtime():
			var result: RunResult = await runner.run(code)
			if not result.is_success():
				push_warning("[GameData] Warm-up for %s failed: %s %s" % [id, result.status_name(), result.stderr])



## Checks that everything points at things that exist. Returns a list of
## problems (empty means all good). The test suite fails if this isn't empty.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in characters:
		for date_id in characters[id].get("dates", []):
			if not dates.has(date_id):
				problems.append("Character '%s' lists unknown date '%s'" % [id, date_id])
	for id in dates:
		var date: Dictionary = dates[id]
		if not characters.has(date.get("character", "")):
			problems.append("Date '%s' has unknown character '%s'" % [id, date.get("character", "")])
		var nodes: Dictionary = date.get("nodes", {})
		if not nodes.has(date.get("start", "start")):
			problems.append("Date '%s' start node '%s' doesn't exist" % [id, date.get("start", "start")])
		for node_id in nodes:
			var node: Dictionary = nodes[node_id]
			var targets: Array = []
			for key in ["next", "on_pass", "on_fail"]:
				if node.has(key):
					targets.append(node[key])
			for choice in node.get("choices", []):
				targets.append(choice.get("next", "end"))
			for t in targets:
				if t != "end" and not nodes.has(t):
					problems.append("Date '%s' node '%s' points to missing node '%s'" % [id, node_id, t])
			if node.has("affection") or node.get("choices", []).any(func(c): return c.has("affection")):
				problems.append("Date '%s' node '%s' sets affection, but affection only comes from passing lessons (see Balance.md)" % [id, node_id])
			if node.has("challenge") and not challenges.has(node["challenge"]):
				problems.append("Date '%s' node '%s' uses unknown challenge '%s'" % [id, node_id, node["challenge"]])
	for id in challenges:
		var lang: String = challenges[id].get("language", "")
		if not languages.has(lang):
			problems.append("Challenge '%s' uses unknown language '%s'" % [id, lang])
		var hints = challenges[id].get("hints")
		if not (hints is Array and hints.size() == 2 and hints.all(func(h): return h is String and not h.strip_edges().is_empty())):
			problems.append("Challenge '%s' needs exactly 2 hints" % id)
	problems.append_array(_validate_lessons())
	problems.append_array(_validate_calendar())
	problems.append_array(_validate_endings())
	return problems


func _validate_endings() -> PackedStringArray:
	var problems: PackedStringArray = []
	for character_id in characters:
		var needed := ["good", "normal_day", "normal_night", "bad"] if character_id == "javascript" else ["good", "normal", "bad"]
		var kinds := []
		for ending in endings.get(character_id, {}).get("endings", []):
			kinds.append(ending.get("kind", ""))
			var dialogue_id: String = ending.get("dialogue", "")
			if not dates.has(dialogue_id):
				problems.append("Ending '%s' uses unknown dialogue '%s'" % [ending.get("id", "?"), dialogue_id])
			elif dates[dialogue_id].get("character", "") != character_id:
				problems.append("Ending '%s': dialogue '%s' belongs to someone else" % [ending.get("id", "?"), dialogue_id])
		for kind in needed:
			if not kinds.has(kind):
				problems.append("Character '%s' has no '%s' ending" % [character_id, kind])
	return problems


func _validate_calendar() -> PackedStringArray:
	var problems: PackedStringArray = []
	var weeks: int = int(calendar.get("weeks", 0))
	if weeks != GameState.SEMESTER_WEEKS:
		problems.append("Calendar has %d weeks, but GameState.SEMESTER_WEEKS is %d" % [weeks, GameState.SEMESTER_WEEKS])
	if Time.get_unix_time_from_datetime_string(calendar.get("start_date", "")) <= 0:
		problems.append("Calendar start_date '%s' isn't a date like 2026-08-31" % calendar.get("start_date", ""))
	var ids := {}
	for event in calendar.get("events", []):
		var id: String = event.get("id", "")
		var where := "Calendar event '%s'" % id
		if ids.has(id):
			problems.append("%s is listed twice" % where)
		ids[id] = true
		if not event.get("kind", "") in ["recurring", "story", "info"]:
			problems.append("%s has unknown kind '%s'" % [where, event.get("kind", "")])
		var event_weeks = event.get("weeks", "every")
		if event_weeks is Array:
			for w in event_weeks:
				if int(w) < 1 or int(w) > weeks:
					problems.append("%s has week %s outside 1-%d" % [where, w, weeks])
		elif not event_weeks in ["every", "even", "odd"]:
			problems.append("%s: weeks should be every, even, odd, or a list" % where)
		if event.get("days", []).is_empty():
			problems.append("%s has no days" % where)
		for d in event.get("days", []):
			if not d in Calendar.DAY_KEYS:
				problems.append("%s has unknown day '%s'" % [where, d])
		if not event.get("slot", "") in ["day", "night"]:
			problems.append("%s: slot should be day or night" % where)
		if not locations.has(event.get("location", "")):
			problems.append("%s has unknown location '%s'" % [where, event.get("location", "")])
		for c in event.get("characters", []):
			if not characters.has(c):
				problems.append("%s has unknown character '%s'" % [where, c])
	return problems


func _validate_lessons() -> PackedStringArray:
	var problems: PackedStringArray = []
	var subject_ids := {}
	for i in curriculum.size():
		var subject: Dictionary = curriculum[i]
		var id: String = subject.get("id", "")
		if subject_ids.has(id):
			problems.append("Curriculum lists subject '%s' twice" % id)
		subject_ids[id] = true
		if int(subject.get("number", 0)) != i + 1:
			problems.append("Curriculum subject '%s' should be number %d" % [id, i + 1])
		if not locations.has(subject.get("location", "")):
			problems.append("Subject '%s' has unknown location '%s'" % [id, subject.get("location", "")])

	for id in characters:
		var lesson_languages = characters[id].get("lesson_languages")
		if not (lesson_languages is Dictionary and not lesson_languages.is_empty()):
			problems.append("Character '%s' has no lesson_languages" % id)
			continue
		for lang in lesson_languages:
			if not languages.has(lang):
				problems.append("Character '%s' teaches unknown language '%s'" % [id, lang])
			if not lesson_languages[lang] in SLOTS:
				problems.append("Character '%s' has unknown slot '%s' for %s" % [id, lesson_languages[lang], lang])

	for subject_id in lessons:
		if not subject_ids.has(subject_id):
			problems.append("Lesson file '%s' isn't a subject in the curriculum" % subject_id)
		for lang in lessons[subject_id].get("versions", {}):
			var where := "Lesson '%s' (%s)" % [subject_id, lang]
			var character_id := character_for_language(lang)
			if character_id == "":
				problems.append("%s: no character teaches %s" % [where, lang])
				continue
			var dialogue_id: String = lessons[subject_id]["versions"][lang].get("dialogue", "")
			problems.append_array(_validate_lesson_dialogue(where, dialogue_id, character_id, lang))

	for character_id in routes:
		if not characters.has(character_id):
			problems.append("Route file '%s' isn't a character" % character_id)
			continue
		var chapters := special_chapters(character_id)
		if chapters.is_empty():
			problems.append("Route '%s' has no chapters" % character_id)
		for i in chapters.size():
			var chapter: Dictionary = chapters[i]
			var where := "Chapter '%s'" % chapter.get("id", "?")
			if int(chapter.get("chapter", 0)) != i + 1:
				problems.append("%s should be chapter %d" % [where, i + 1])
			if chapter.get("final", false) != (i == chapters.size() - 1):
				problems.append("%s: only the last chapter of a route is the final" % where)
			for req in chapter.get("requires", []):
				if not subject_ids.has(req):
					problems.append("%s requires unknown subject '%s'" % [where, req])
			if not locations.has(chapter.get("location", "")):
				problems.append("%s has unknown location '%s'" % [where, chapter.get("location", "")])
			if not chapter.get("slot", "") in SLOTS:
				problems.append("%s has unknown slot '%s'" % [where, chapter.get("slot", "")])
			var lang: String = chapter.get("language", "")
			if not get_character(character_id).get("lesson_languages", {}).has(lang):
				problems.append("%s uses %s, which %s doesn't teach" % [where, lang, character_id])
			if chapter.has("dialogue"):
				problems.append_array(_validate_lesson_dialogue(where, chapter["dialogue"], character_id, lang))
	for character_id in characters:
		if not routes.has(character_id):
			problems.append("Character '%s' has no route file in %s" % [character_id, ROUTES_DIR])
	return problems


## A lesson's dialogue must exist, belong to the right character, and have
## a challenge in the lesson's language.
func _validate_lesson_dialogue(where: String, dialogue_id: String, character_id: String, language_id: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	if not dates.has(dialogue_id):
		problems.append("%s uses unknown dialogue '%s'" % [where, dialogue_id])
		return problems
	if dates[dialogue_id].get("character", "") != character_id:
		problems.append("%s: dialogue '%s' belongs to '%s', not '%s'" % [where, dialogue_id, dates[dialogue_id].get("character", ""), character_id])
	var challenge_id := dialogue_challenge(dialogue_id)
	if challenge_id == "":
		problems.append("%s: dialogue '%s' has no challenge" % [where, dialogue_id])
	elif get_challenge(challenge_id).get("language", "") != language_id:
		problems.append("%s: challenge '%s' isn't in %s" % [where, challenge_id, language_id])
	return problems


## Loads every *.json file in a folder into a Dictionary keyed by its "id"
## (or the file name if it has no id).
static func load_dir(dir_path: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Can't open %s" % dir_path)
		return out
	for file in dir.get_files():
		if file.get_extension() != "json":
			continue
		var data = load_json(dir_path.path_join(file))
		if data is Dictionary:
			out[data.get("id", file.get_basename())] = data
	return out


static func load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Can't read %s" % path)
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("%s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
