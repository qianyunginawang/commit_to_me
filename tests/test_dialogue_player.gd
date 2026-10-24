extends TestCase

var lines: Array = []
var challenges: Array = []
var affection := 0
var done := false


func _make(date_id: String) -> DialoguePlayer:
	var p := DialoguePlayer.new(GameData.get_date(date_id), "Gee")
	p.line_started.connect(func(line): lines.append(line))
	p.challenge_requested.connect(func(id): challenges.append(id))
	p.affection_awarded.connect(func(_c, amount): affection += amount)
	p.finished.connect(func(): done = true)
	return p


func test_happy_path() -> void:
	var p := _make("python_date_1")
	p.start()
	check_eq(lines[-1]["speaker"], "narrator")
	p.advance()
	check(lines[-1]["text"].contains("Gee"), "{player} should be replaced with the name")
	p.advance()
	check(lines[-1].has("choices"), "third line should have choices")
	p.choose(0)          # +5
	p.advance()          # -> challenge
	check_eq(challenges, ["python_hello"])
	p.complete_challenge(true)  # passed line, +10
	check_eq(affection, 15)
	p.advance()
	check(done, "date should be finished")


func test_fail_and_retry() -> void:
	var p := _make("python_date_1")
	p.start()
	p.advance()
	p.advance()
	p.choose(1)  # -3
	p.advance()
	p.complete_challenge(false)
	check(lines[-1].has("choices"), "fail line should offer a retry")
	p.choose(0)  # retry, +1
	check_eq(challenges, ["python_hello", "python_hello"])
	p.complete_challenge(true)  # +10
	check_eq(affection, 8)


func test_missing_node_ends_date() -> void:
	var p := DialoguePlayer.new({"start": "nope", "nodes": {}})
	p.finished.connect(func(): done = true)
	p.start()
	check(done, "missing start node should end the date instead of hanging")
