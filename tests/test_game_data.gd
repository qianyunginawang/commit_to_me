extends TestCase


func test_all_content_is_valid() -> void:
	var problems: PackedStringArray = GameData.validate()
	check(problems.is_empty(), "content problems:\n            " + "\n            ".join(problems))


func test_four_characters_in_order() -> void:
	check_eq(GameData.character_ids(), ["python", "javascript", "java", "cpp"] as Array[String])


func test_every_character_has_a_date() -> void:
	for id in GameData.character_ids():
		check(not GameData.get_character(id).get("dates", []).is_empty(), "%s has no dates" % id)


func test_curriculum_has_33_subjects_in_order() -> void:
	check_eq(GameData.curriculum.size(), 33)
	check_eq(GameData.curriculum[0].get("title"), "Printing to the console")
	check_eq(GameData.curriculum[32].get("title"), "Dynamic programming")
	check_eq(GameData.get_subject("g08").get("title"), "Debugging")


func test_every_character_has_a_route_ending_in_a_final() -> void:
	var expected := {"python": 6, "javascript": 7, "java": 6, "cpp": 6}
	for id in GameData.character_ids():
		var chapters := GameData.special_chapters(id)
		check_eq(chapters.size(), expected[id], "%s chapter count" % id)
		if not chapters.is_empty():
			check(chapters[-1].get("final", false), "%s's last chapter should be the final" % id)


func test_printing_is_written_in_all_five_languages() -> void:
	for lang in ["python", "typescript", "javascript", "java", "cpp"]:
		check(not GameData.get_generic_lesson("g01", lang).is_empty(), "g01 has no %s version" % lang)
	check_eq(GameData.get_generic_lesson("g01", "python").get("character"), "python")
	check_eq(GameData.get_generic_lesson("g01", "python").get("location"), "main_quad")


func test_jay_teaches_typescript_by_day_and_javascript_by_night() -> void:
	var lessons := GameData.generic_lessons_for("g01", "javascript")
	check_eq(lessons.size(), 2)
	var slots := {}
	for lesson in lessons:
		slots[lesson["language"]] = lesson["slot"]
	check_eq(slots, {"typescript": "day", "javascript": "night"})


func test_unwritten_lessons_are_empty() -> void:
	check(GameData.get_generic_lesson("g33", "python").is_empty(), "g33 isn't written yet")
	check(not GameData.get_special_chapter("javascript_ch3").has("dialogue"), "javascript_ch3 isn't written yet")
	var zen := GameData.get_special_chapter("python_ch1")
	check_eq(zen.get("character"), "python")
	check_eq(zen.get("challenge"), "python_ch1")


func test_validate_catches_broken_lessons() -> void:
	var gd = load("res://scripts/autoload/game_data.gd").new()
	gd.characters = GameData.characters.duplicate(true)
	gd.dates = GameData.dates.duplicate(true)
	gd.challenges = GameData.challenges.duplicate(true)
	gd.languages = GameData.languages
	gd.curriculum = GameData.curriculum.duplicate(true)
	gd.lessons = GameData.lessons.duplicate(true)
	gd.routes = GameData.routes.duplicate(true)
	gd.locations = GameData.locations
	check(gd.validate().is_empty(), "the copy should start out valid")

	gd.lessons["g01"]["versions"]["python"]["dialogue"] = "g01_java"   # wrong character
	gd.routes["cpp"]["chapters"][0]["requires"] = ["g99"]               # unknown subject
	gd.challenges["g01_cpp"]["hints"] = ["only one"]                     # needs 2 hints
	var problems: String = "\n".join(gd.validate())
	check("belongs to 'java', not 'python'" in problems, "wrong character not caught:\n" + problems)
	check("requires unknown subject 'g99'" in problems, "unknown subject not caught:\n" + problems)
	check("'g01_cpp' needs exactly 2 hints" in problems, "missing hint not caught:\n" + problems)
	gd.free()
