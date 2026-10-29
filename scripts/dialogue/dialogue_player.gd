class_name DialoguePlayer
extends RefCounted
## Steps through one date's dialogue file. Has no UI of its own: the
## dialogue scene listens to the signals below and draws things.
##
## A dialogue file (res://data/dates/*.json) looks like:
## {
##   "id": "python_date_1",
##   "character": "python",
##   "start": "hello",
##   "nodes": {
##     "hello":  {"speaker": "python", "text": "Hi {player}!", "next": "ask"},
##     "ask":    {"speaker": "python", "text": "Want to code?",
##                "choices": [
##                  {"text": "Yes!", "next": "quiz"},
##                  {"text": "Nah.", "next": "end"}]},
##     "quiz":   {"challenge": "python_hello", "on_pass": "yay", "on_fail": "aww"},
##     "yay":    {"speaker": "python", "text": "You did it!", "next": "end"},
##     "aww":    {"speaker": "python", "text": "We'll try again.", "next": "end"}
##   }
## }
##
## Node kinds:
##   line      - has "text". Optional "speaker" (character id, "player", or
##               "narrator"), "mood", and either "next" or "choices".
##   challenge - has "challenge" (a challenge id) plus "on_pass" / "on_fail".
## A "next" of "end" (or missing) ends the date.
##
## Dialogue never changes affection. Affection comes from passing the
## challenge (see GameState.complete_lesson).

## A line of dialogue should be shown. [param line] is the node with
## "{player}" already replaced in its text and choices.
signal line_started(line: Dictionary)
## The game should open the code challenge with this id, then call
## complete_challenge() with the result.
signal challenge_requested(challenge_id: String)
## The date is over.
signal finished

const END := "end"

var dialogue: Dictionary = {}
var character_id: String = ""
var player_name: String = "You"
var current_id: String = ""
var is_finished: bool = false


func _init(p_dialogue: Dictionary = {}, p_player_name: String = "You") -> void:
	dialogue = p_dialogue
	character_id = dialogue.get("character", "")
	player_name = p_player_name


func start() -> void:
	is_finished = false
	_go(dialogue.get("start", "start"))


func current_node() -> Dictionary:
	return dialogue.get("nodes", {}).get(current_id, {})


## Continue past a line that has no choices.
func advance() -> void:
	var node := current_node()
	if node.has("choices"):
		push_warning("advance() called on a line with choices; use choose().")
		return
	_go(node.get("next", END))


## Pick choice number [param index] on the current line.
func choose(index: int) -> void:
	var choices: Array = current_node().get("choices", [])
	if index < 0 or index >= choices.size():
		push_error("Choice %d doesn't exist on node '%s'" % [index, current_id])
		return
	var choice: Dictionary = choices[index]
	_go(choice.get("next", END))


## Report how the code challenge went.
func complete_challenge(passed: bool) -> void:
	var node := current_node()
	_go(node.get("on_pass" if passed else "on_fail", END))


func _go(node_id) -> void:
	if node_id == null or String(node_id) == "" or String(node_id) == END:
		_finish()
		return
	var nodes: Dictionary = dialogue.get("nodes", {})
	if not nodes.has(node_id):
		push_error("Dialogue '%s' has no node called '%s'" % [dialogue.get("id", "?"), node_id])
		_finish()
		return

	current_id = node_id
	var node: Dictionary = nodes[node_id]

	if node.has("challenge"):
		challenge_requested.emit(node["challenge"])
		return

	var line := node.duplicate(true)
	line["text"] = _fill(line.get("text", ""))
	for choice in line.get("choices", []):
		choice["text"] = _fill(choice.get("text", ""))
	line_started.emit(line)


func _fill(text: String) -> String:
	return text.format({"player": player_name})


func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	current_id = ""
	finished.emit()
