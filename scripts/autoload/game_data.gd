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
## Available everywhere as the `GameData` autoload.

const CHARACTERS_DIR := "res://data/characters"
const DATES_DIR := "res://data/dates"
const CHALLENGES_DIR := "res://data/challenges"
const LANGUAGES_PATH := "res://data/languages.json"

var characters: Dictionary = {}
var dates: Dictionary = {}
var challenges: Dictionary = {}
var languages: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	characters = load_dir(CHARACTERS_DIR)
	dates = load_dir(DATES_DIR)
	challenges = load_dir(CHALLENGES_DIR)
	var langs = load_json(LANGUAGES_PATH)
	languages = langs if langs is Dictionary else {}
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


## Makes a code runner for a language id from languages.json ("python", "cpp", ...).
func make_runner(language_id: String) -> CodeRunner:
	return ProcessCodeRunner.new(language_id, languages.get(language_id, {}))


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
			if node.has("challenge") and not challenges.has(node["challenge"]):
				problems.append("Date '%s' node '%s' uses unknown challenge '%s'" % [id, node_id, node["challenge"]])
	for id in challenges:
		var lang: String = challenges[id].get("language", "")
		if not languages.has(lang):
			problems.append("Challenge '%s' uses unknown language '%s'" % [id, lang])
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
