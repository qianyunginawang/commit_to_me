extends TestCase


func test_all_content_is_valid() -> void:
	var problems: PackedStringArray = GameData.validate()
	check(problems.is_empty(), "content problems:\n            " + "\n            ".join(problems))


func test_four_characters_in_order() -> void:
	check_eq(GameData.character_ids(), ["python", "javascript", "java", "cpp"] as Array[String])


func test_every_character_has_a_date() -> void:
	for id in GameData.character_ids():
		check(not GameData.get_character(id).get("dates", []).is_empty(), "%s has no dates" % id)
