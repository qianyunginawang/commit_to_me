extends TestCase

var lines: Array = []
var challenges: Array = []
var done := false

## A small date with a choice, a challenge and a retry, so these tests don't
## depend on real content.
const DATE := {
	"id": "test_date",
	"character": "python",
	"start": "intro",
	"nodes": {
		"intro": {"speaker": "narrator", "text": "The tutoring center.", "next": "hello"},
		"hello": {"speaker": "python", "text": "Hi {player}!", "next": "ask"},
		"ask": {"speaker": "python", "text": "Ready?", "choices": [
			{"text": "Yes!", "next": "quiz"},
			{"text": "Sure.", "next": "quiz"}]},
		"quiz": {"challenge": "g01_python", "on_pass": "yay", "on_fail": "aww"},
		"yay": {"speaker": "python", "text": "You did it!", "next": "end"},
		"aww": {"speaker": "python", "text": "Try again?", "choices": [
			{"text": "Again.", "next": "quiz"},
			{"text": "Later.", "next": "end"}]},
	},
}


func _make() -> DialoguePlayer:
	var p := DialoguePlayer.new(DATE, "Gee")
	p.line_started.connect(func(line): lines.append(line))
	p.challenge_requested.connect(func(id): challenges.append(id))
	p.finished.connect(func(): done = true)
	return p


func test_happy_path() -> void:
	var p := _make()
	p.start()
	check_eq(lines[-1]["speaker"], "narrator")
	p.advance()
	check(lines[-1]["text"].contains("Gee"), "{player} should be replaced with the name")
	p.advance()
	check(lines[-1].has("choices"), "third line should have choices")
	p.choose(0)
	check_eq(challenges, ["g01_python"])
	p.complete_challenge(true)
	p.advance()
	check(done, "date should be finished")


func test_fail_and_retry() -> void:
	var p := _make()
	p.start()
	p.advance()
	p.advance()
	p.choose(1)
	p.complete_challenge(false)
	check(lines[-1].has("choices"), "fail line should offer a retry")
	p.choose(0)  # retry
	check_eq(challenges, ["g01_python", "g01_python"])
	p.complete_challenge(true)
	check_eq(lines[-1].get("speaker"), "python")


func test_missing_node_ends_date() -> void:
	var p := DialoguePlayer.new({"start": "nope", "nodes": {}})
	p.finished.connect(func(): done = true)
	p.start()
	check(done, "missing start node should end the date instead of hanging")


func test_dialogue_has_no_affection_signal() -> void:
	check(not DialoguePlayer.new().has_signal("affection_awarded"), "affection should only come from lessons")
