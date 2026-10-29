extends TestCase
## Jay's day/night balance (scripts/progress/jay_balance.gd).

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const GameDataScript := preload("res://scripts/autoload/game_data.gd")

var _nodes: Array[Node] = []


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()


func _state() -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	_nodes.append(gs)
	return gs


## A copy of the real content with Jay's chapters 1-6 "written": chapter 1
## is a night chapter, 2 and 4 are day, 3 and 5 are night, and 6 is dusk.
func _data() -> Node:
	var gd: Node = GameDataScript.new()
	gd.characters = GameData.characters.duplicate(true)
	gd.dates = GameData.dates.duplicate(true)
	gd.challenges = GameData.challenges.duplicate(true)
	gd.languages = GameData.languages
	gd.curriculum = GameData.curriculum.duplicate(true)
	gd.lessons = GameData.lessons.duplicate(true)
	gd.routes = GameData.routes.duplicate(true)
	gd.locations = GameData.locations
	gd.calendar = GameData.calendar
	for chapter in gd.routes["javascript"]["chapters"]:
		chapter["dialogue"] = "test_" + chapter["id"]
	_nodes.append(gd)
	return gd


func test_starts_balanced() -> void:
	var gs := _state()
	check_eq(JayBalance.counts(gs, _data()), {"day": 0, "night": 0})
	check_eq(JayBalance.leaning(gs, _data()), "balanced")


func test_typescript_counts_as_day_and_javascript_as_night() -> void:
	var gs := _state()
	var gd := _data()
	gs.complete_lesson("g01_typescript", "javascript", 0)
	check_eq(JayBalance.counts(gs, gd), {"day": 1, "night": 0})
	gs.complete_lesson("test_javascript_ch1", "javascript", 0)
	check_eq(JayBalance.counts(gs, gd), {"day": 1, "night": 1})
	check_eq(JayBalance.describe(gs, gd), "Day 1 · Night 1")


func test_dusk_counts_as_both() -> void:
	var gs := _state()
	var gd := _data()
	gs.complete_lesson("test_javascript_ch6", "javascript", 0)
	check_eq(JayBalance.counts(gs, gd), {"day": 1, "night": 1})


func test_a_gap_over_two_tips_the_balance() -> void:
	var gs := _state()
	var gd := _data()
	gs.complete_lesson("test_javascript_ch1", "javascript", 0)   # night
	gs.complete_lesson("test_javascript_ch3", "javascript", 0)   # night
	check(JayBalance.is_balanced(gs, gd), "a gap of 2 is still balanced")
	gs.complete_lesson("test_javascript_ch5", "javascript", 0)   # night
	check_eq(JayBalance.gap(gs, gd), 3)
	check(not JayBalance.is_balanced(gs, gd), "a gap of 3 is out of balance")
	check_eq(JayBalance.leaning(gs, gd), "night")
	gs.complete_lesson("test_javascript_ch2", "javascript", 0)   # day
	check_eq(JayBalance.leaning(gs, gd), "balanced")


func test_other_characters_lessons_dont_count() -> void:
	var gs := _state()
	gs.complete_lesson("g01_python", "python", 0)
	check_eq(JayBalance.counts(gs, _data()), {"day": 0, "night": 0})
