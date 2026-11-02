extends TestCase

const GameStateScript := preload("res://scripts/autoload/game_state.gd")


func _make() -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	return gs


func test_affection_is_clamped() -> void:
	var gs := _make()
	gs.add_affection("python", 30)
	check_eq(gs.get_affection("python"), 30)
	gs.add_affection("python", 500)
	check_eq(gs.get_affection("python"), 100, "clamped to max:")
	gs.add_affection("python", -1000)
	check_eq(gs.get_affection("python"), 0, "clamped to min:")
	gs.free()


func test_affection_signal() -> void:
	var gs := _make()
	var seen: Array = []
	gs.affection_changed.connect(func(id, value, delta): seen.append([id, value, delta]))
	gs.add_affection("java", 5)
	gs.add_affection("java", -10)  # 5 -> 0, delta -5
	gs.add_affection("java", -10)  # already 0, no change, no signal
	check_eq(seen, [["java", 5, 5], ["java", 0, -5]])
	gs.free()


func test_levels() -> void:
	check_eq(GameStateScript.level_for(0)["title"], "Stranger")
	check_eq(GameStateScript.level_for(15)["title"], "Classmate")
	check_eq(GameStateScript.level_for(59)["title"], "Study Buddy")
	check_eq(GameStateScript.level_for(100)["title"], "Committed")


func test_save_and_load() -> void:
	var gs := _make()
	gs.new_game("  Gee  ")
	gs.add_affection("cpp", 42)
	gs.mark_date_complete("g01_cpp")
	check(gs.save_game(), "save_game() failed")

	var loaded := _make()
	check(loaded.load_game(), "load_game() failed")
	check_eq(loaded.player_name, "Gee")
	check_eq(loaded.get_affection("cpp"), 42)
	check(loaded.is_date_complete("g01_cpp"), "completed date not loaded")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	gs.free()
	loaded.free()


func test_each_new_game_gets_its_own_save_slot() -> void:
	var gs := _make()
	gs.saves_dir = "user://test_slots"
	gs.save_path = ""
	gs.new_game("First")
	gs.start_new_save()
	gs.save_game()
	var first: String = gs.save_path
	gs.new_game("Second")
	gs.start_new_save()
	gs.advance_time()
	gs.save_game()
	check(gs.save_path != first, "a new game shouldn't overwrite the old save")

	var saves: Array[Dictionary] = gs.list_saves()
	check_eq(saves.size(), 2)
	check_eq(saves[0]["player_name"], "Second", "the most recent save comes first:")
	check_eq(saves[0]["slot"], "night")
	check_eq(saves[1]["player_name"], "First")

	# Playing the older game again moves it to the top.
	var loaded := _make()
	loaded.saves_dir = gs.saves_dir
	check(loaded.load_game(first), "load_game(path) failed")
	check_eq(loaded.player_name, "First")
	loaded.save_game()
	check_eq(loaded.list_saves()[0]["player_name"], "First")

	for save in saves:
		DirAccess.remove_absolute(save["path"])
	DirAccess.remove_absolute(gs.saves_dir)
	check(not gs.has_any_save(), "no saves left")
	gs.free()
	loaded.free()


func test_lesson_affection_follows_balance_rules() -> void:
	check_eq(GameStateScript.lesson_affection(0), 6)
	check_eq(GameStateScript.lesson_affection(1), 4)
	check_eq(GameStateScript.lesson_affection(2), 2)
	check_eq(GameStateScript.lesson_affection(5), 2, "never below the minimum:")


func test_lesson_affection_is_only_given_once() -> void:
	var gs := _make()
	check_eq(gs.complete_lesson("g01_python", "python", 1), 4)
	check_eq(gs.get_affection("python"), 4)
	check(gs.is_date_complete("g01_python"), "lesson should be marked complete")
	check_eq(gs.complete_lesson("g01_python", "python", 0), 0, "replaying gives nothing:")
	check_eq(gs.get_affection("python"), 4)
	gs.free()
