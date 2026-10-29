extends TestCase
## The unlock rules in scripts/progress/unlocks.gd.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const GameDataScript := preload("res://scripts/autoload/game_data.gd")


func _state() -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	_nodes.append(gs)
	return gs


## A copy of the real content that tests can change freely.
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
	_nodes.append(gd)
	return gd


## Pretends the subject has a Python version written, with its own dialogue.
func _write_python_version(gd: Node, subject_id: String) -> String:
	var dialogue_id := "test_%s_python" % subject_id
	gd.dates[dialogue_id] = {"id": dialogue_id, "character": "python", "start": "c",
		"nodes": {"c": {"challenge": "g01_python", "on_pass": "end", "on_fail": "end"}}}
	gd.lessons[subject_id] = {"id": subject_id, "versions": {"python": {"dialogue": dialogue_id}}}
	return dialogue_id


var _nodes: Array[Node] = []


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()


func _dialogues(lessons: Array) -> Array:
	return lessons.map(func(l): return l["dialogue"])


func test_only_the_first_subject_is_open_at_the_start() -> void:
	var gs := _state()
	check(Unlocks.is_subject_unlocked("g01", gs), "g01 should be open")
	check(not Unlocks.is_subject_unlocked("g02", gs), "g02 should be locked")
	check_eq(_dialogues(Unlocks.lessons_available("python", gs)), ["g01_python"])
	check_eq(_dialogues(Unlocks.lessons_available("javascript", gs)), ["g01_typescript", "g01_javascript"])


func test_each_subject_is_done_once_per_character() -> void:
	var gs := _state()
	gs.complete_lesson("g01_python", "python", 0)
	check(Unlocks.is_subject_done("g01", gs), "g01 done")
	check(Unlocks.is_subject_unlocked("g02", gs), "g02 opens after g01")
	check_eq(_dialogues(Unlocks.lessons_available("python", gs)), [], "Monty has nothing written to offer yet:")
	check_eq(_dialogues(Unlocks.lessons_available("java", gs)), ["g01_java"], "Julian still has g01:")
	gs.complete_lesson("g01_typescript", "javascript", 0)
	check_eq(_dialogues(Unlocks.lessons_available("javascript", gs)), [], "one of Jay's versions is enough:")
	check_eq(Unlocks.characters_done_subject("g01", gs), ["python", "javascript"])


func test_finishing_a_subject_opens_the_next_for_everyone() -> void:
	var gs := _state()
	var gd := _data()
	var g02_python := _write_python_version(gd, "g02")
	var g02_java := "test_g02_java"
	gd.dates[g02_java] = {"id": g02_java, "character": "java", "start": "c",
		"nodes": {"c": {"challenge": "g01_java", "on_pass": "end", "on_fail": "end"}}}
	gd.lessons["g02"]["versions"]["java"] = {"dialogue": g02_java}
	check_eq(_dialogues(Unlocks.generic_lessons_available("java", gs, gd)), ["g01_java"], "only g01 at first:")
	gs.complete_lesson("g01_python", "python", 0)
	check_eq(_dialogues(Unlocks.generic_lessons_available("java", gs, gd)), ["g01_java", g02_java], "Monty's g01 opens g02 for Julian, and Julian can still go back to g01:")
	gs.complete_lesson(g02_python, "python", 0)
	check(not _dialogues(Unlocks.generic_lessons_available("python", gs, gd)).has(g02_python), "Monty has done g02")
	check(_dialogues(Unlocks.generic_lessons_available("java", gs, gd)).has(g02_java), "Julian can still do g02")


func test_chapter_needs_its_subjects_and_the_previous_chapter() -> void:
	var gs := _state()
	var gd := _data()
	check_eq(Unlocks.missing_for_chapter("python_ch1", gs, gd), ["g02", "g03"] as Array[String])
	check_eq(Unlocks.missing_for_chapter("python_ch2", gs, gd), ["g05", "g16", "python_ch1"] as Array[String])

	gs.complete_lesson("g01_python", "python", 0)
	gs.complete_lesson(_write_python_version(gd, "g02"), "python", 0)
	check(not Unlocks.is_chapter_unlocked("python_ch1", gs, gd), "still needs g03")
	gs.complete_lesson(_write_python_version(gd, "g03"), "python", 0)
	check(Unlocks.is_chapter_unlocked("python_ch1", gs, gd), "python_ch1 should open")
	check_eq(Unlocks.lessons_available("python", gs, gd)[0].get("id"), "python_ch1", "special chapter comes first:")

	gs.complete_lesson("python_ch1", "python", 0)
	check(Unlocks.is_chapter_done("python_ch1", gs, gd), "python_ch1 done")
	check_eq(Unlocks.next_special_chapter("python", gs, gd).get("id"), "python_ch2")
	check(not Unlocks.missing_for_chapter("python_ch2", gs, gd).has("python_ch1"), "previous chapter is done")


func test_unwritten_chapters_are_not_offered() -> void:
	var gs := _state()
	var gd := _data()
	gd.routes["cpp"]["chapters"][0]["requires"] = []
	check(Unlocks.is_chapter_unlocked("cpp_ch1", gs, gd), "no requirements left")
	check(not _dialogues(Unlocks.lessons_available("cpp", gs, gd)).has(""), "unwritten chapter shouldn't be offered")
