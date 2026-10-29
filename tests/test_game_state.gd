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


func test_next_date() -> void:
	var gs := _make()
	check_eq(gs.next_date(["a", "b"]), "a")
	gs.mark_date_complete("a")
	check_eq(gs.next_date(["a", "b"]), "b")
	gs.mark_date_complete("b")
	check_eq(gs.next_date(["a", "b"]), "")
	gs.free()


func test_save_and_load() -> void:
	var gs := _make()
	gs.new_game("  Gee  ")
	gs.add_affection("cpp", 42)
	gs.mark_date_complete("cpp_date_1")
	check(gs.save_game(), "save_game() failed")

	var loaded := _make()
	check(loaded.load_game(), "load_game() failed")
	check_eq(loaded.player_name, "Gee")
	check_eq(loaded.get_affection("cpp"), 42)
	check(loaded.is_date_complete("cpp_date_1"), "completed date not loaded")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
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
